test part1 {
    const example =
        \\aaa: you hhh
        \\you: bbb ccc
        \\bbb: ddd eee
        \\ccc: ddd eee fff
        \\ddd: ggg
        \\eee: out
        \\fff: out
        \\ggg: out
        \\hhh: ccc fff iii
        \\iii: out
        \\
    ;
    const answer = 5;
    try testing.expectEqual(answer, try part1(example));
}

/// This is a directed graph traversal problem.
/// It says nothing about if the graph is cyclical,
/// so let's first try simply recursively walking each possible path to its end.
///
/// Fortunately, all labels are three characters wide,
/// so we can just use them directly as keys to a hash map,
/// giving constant lookup time to the next node of the graph.
pub fn part1(input: []const u8) !u16 {
    map_buffer = undefined;
    const start_key: Label = .{ 'y', 'o', 'u' };
    const end_key: Label = .{ 'o', 'u', 't' };

    var fba: std.heap.FixedBufferAllocator = .init(&map_buffer);
    const allocator = fba.allocator();

    const path_map = try parse(input, allocator);

    return pathsToLabel(path_map, start_key, end_key);
}

/// Recursive hash map traversal.
/// If the graph is cyclic, this might continue endlessly
fn pathsToLabel(map: PathMap, from: Label, to: Label) u16 {
    if (labelEql(from, to)) {
        return 1;
    } else if (map.get(from)) |from_outputs| {
        var total: u16 = 0;
        for (from_outputs) |output_label|
            total += pathsToLabel(map, output_label, to);
        return total;
    } else {
        return 0;
    }
}

test part2 {
    const example =
        \\svr: aaa bbb
        \\aaa: fft
        \\fft: ccc
        \\bbb: tty
        \\tty: ccc
        \\ccc: ddd eee
        \\ddd: hub
        \\hub: fff
        \\eee: dac
        \\dac: fff
        \\fff: ggg hhh
        \\ggg: out
        \\hhh: out
        \\
    ;
    const answer = 2;
    try testing.expectEqual(answer, try part2(example));
}

pub fn part2(input: []const u8) !u16 {
    map_buffer = undefined;
    const start_key: Label = .{ 's', 'v', 'r' };
    const end_key: Label = .{ 'o', 'u', 't' };

    var fba: std.heap.FixedBufferAllocator = .init(&map_buffer);
    const allocator = fba.allocator();

    const path_map = try parse(input, allocator);
    var path_traversal: PathTraversal = .empty;
    var resolved_paths: PathTraversalMemoization = .empty;

    const contains_result = try pathsToLabelContaining(
        allocator,
        path_map,
        &path_traversal,
        &resolved_paths,
        start_key,
        end_key,
        .{ .{ 'd', 'a', 'c' }, .{ 'f', 'f', 't' } },
    );

    assert(path_traversal.count() == 0);

    return contains_result.both;
}

/// Currently does not work.
fn pathsToLabelContaining(
    allocator: mem.Allocator,
    map: PathMap,
    current_path: *PathTraversal,
    path_dp: *PathTraversalMemoization,
    from: Label,
    to: Label,
    contains: [2]Label,
) mem.Allocator.Error!ContainsResult {
    //for (current_path.keys()) |key| std.debug.print("{s}->", .{key});
    //std.debug.print("{s}\n", .{from});

    const contains_1 = current_path.contains(contains[0]);
    const contains_2 = current_path.contains(contains[1]);

    if (labelEql(from, to)) {
        return .{
            .none = @intFromBool(   !contains_1 and !contains_2 ),
            .first = @intFromBool(   contains_1 and !contains_2 ),
            .second = @intFromBool( !contains_1 and  contains_2 ),
            .both = @intFromBool(    contains_1 and  contains_2 ),
        };
    } else {
        if (!current_path.contains(from)) {
            const outputs: []const Label = map.get(from) orelse return .empty;

            try current_path.putNoClobber(allocator, from, {});

            const total = if (path_dp.get(from)) |dp| dp else recurse: {
                var t: ContainsResult = .empty;
                for (outputs) |output| t = t.add(try pathsToLabelContaining(
                    allocator,
                    map,
                    current_path,
                    path_dp,
                    output,
                    to,
                    contains,
                ));
                try path_dp.putNoClobber(allocator, from, t);
                break :recurse t;
            };

            const pop = current_path.pop();
            assert(pop != null and labelEql(pop.?.key, from));

            return total.prefixed(contains_1, contains_2);
        } else {
            return .empty;
        }
    }
}

fn parse(input: []const u8, allocator: mem.Allocator) !PathMap {
    var path_map: PathMap = .empty;

    var line_iter = mem.splitScalar(u8, input, '\n');
    while (line_iter.next()) |line| { if (line.len != 0) {
        var token_iter = mem.splitScalar(u8, line, ' ');
        const label: Label = first_line: {
            const first = token_iter.first();
            if (first.len == 4 and first[3] == ':') {
                break :first_line first[0..3].*;
            } else {
                std.log.err("invalid first token of line: \'{s}\'", .{ first });
                return error.InvalidInput;
            }
        };
        const get_or_put = try path_map.getOrPut(allocator, label);
        if (get_or_put.found_existing) {
            std.log.err("label \'{s}\' appears more than once", .{ label });
            return error.InvalidInput;
        }
        assert(labelEql(get_or_put.key_ptr.*, label));
        var outputs_buf: [32]Label = undefined;
        var outputs_idx: u5 = 0;
        while (token_iter.next()) |token| {
            if (token.len == 3) {
                outputs_buf[outputs_idx] = token[0..3].*;
                outputs_idx += 1;
            } else {
                std.log.err("invalid token \'{s}\'", .{ token });
                return error.InvalidInput;
            }
        }
        const outputs = try allocator.alloc(Label, outputs_idx);
        @memcpy(outputs, outputs_buf[0..outputs_idx]);
        get_or_put.value_ptr.* = outputs;
    }}

    return path_map;
}

fn labelEql(lhs: Label, rhs: Label) bool {
    return @as(u24, @bitCast(lhs)) == @as(u24, @bitCast(rhs));
}

// Hash maps are big, it turns out
var map_buffer: [131072]u8 = undefined;

const Label = [3]u8;
const PathMap = std.hash_map.AutoHashMapUnmanaged(Label, []const Label);
const PathTraversal = std.array_hash_map.AutoArrayHashMapUnmanaged(Label, void);
const PathTraversalMemoization = std.hash_map.AutoHashMapUnmanaged(Label, ContainsResult);
const ContainsResult = struct {
    none: u16,
    first: u16,
    second: u16,
    both: u16,

    const empty: ContainsResult = .{
        .none = 0,
        .first = 0,
        .second = 0,
        .both = 0,
    };

    fn prefixed(contains: ContainsResult, has_first: bool, has_second: bool) ContainsResult {
        if (has_first and has_second) {
            return .{
                .none = 0,
                .first = 0,
                .second = 0,
                .both = contains.none + contains.first + contains.second + contains.both,
            };
        } else if (has_first) { // but not second
            return .{
                .none = 0,
                .first = contains.first + contains.none,
                .second = 0,
                .both = contains.both + contains.second,
            };
        } else if (has_second) { // but not first
            return .{
                .none = 0,
                .first = 0,
                .second = contains.second + contains.none,
                .both = contains.both + contains.first,
            };
        } else {
            return contains;
        }

        //return .{
        //    .none = contains.none * @intFromBool(!(has_first or has_second)),
        //    .first = contains.first * @intFromBool(!has_second)
        //        + contains.none * @intFromBool(has_first and !has_second),
        //    .second = contains.second * @intFromBool(!has_first)
        //        + contains.none * @intFromBool(has_second and !has_first),
        //    .both = contains.both
        //        + @intFromBool(has_second) * contains.first
        //        + @intFromBool(has_first) * contains.second,
        //};
    }

    fn add(lhs: ContainsResult, rhs: ContainsResult) ContainsResult {
        return .{
            .none = lhs.none + rhs.none,
            .first = lhs.first + rhs.first,
            .second = lhs.second + rhs.second,
            .both = lhs.both + rhs.both,
        };
    }
};

const assert = std.debug.assert;
const testing = std.testing;
const mem = std.mem;
const std = @import("std");
