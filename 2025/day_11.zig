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
var map_buffer: [65536]u8 = undefined;

const Label = [3]u8;
const PathMap = std.hash_map.AutoHashMapUnmanaged(Label, []const Label);

const assert = std.debug.assert;
const testing = std.testing;
const mem = std.mem;
const std = @import("std");
