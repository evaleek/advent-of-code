pub const part1 = part1InPlace;

test part1 {
    const example_input =
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
        \\
    ;
    var input_mut: [example_input.len]u8 = example_input.*;
    const example_answer = 13;
    // part1Double is a working solution
    try testing.expectEqual(example_answer, try part1Double(example_input));
    try testing.expectEqual(part1Double(example_input), try part1(&input_mut));
}

/// Solution by keeping a second buffer to track adjacency counts.
pub fn part1Double(input: []const u8) !u16 {
    const init_adjacency: i8 = 4;
    // Input is runtime-known, but we don't want to do heap allocations
    var adjacency_buffer: [32768]i8 = @splat(init_adjacency);
    if (input.len > adjacency_buffer.len) return error.InputOverflow;

    const adjacencies: []i8 = adjacency_buffer[0..input.len];
    assert(input[0] != '\n');
    const line_diff = ( mem.findScalarPos(u8, input, 0, '\n')
        orelse return error.InputInvalid ) + 1;

    for (input, 0..) |input_char, index| { switch (input_char) {
        else => {
            // Now this cell's adjacency count will never make it into the total,
            // and we don't have to check for it later.
            adjacencies[index] = -1;
        },

        '@' => {
            // Decrement the previous and next cells of this line.
            if (index != 0) adjacencies[index-1] -= 1;
            adjacencies[index+1] -= 1;

            // If this is not the first line,
            // decrement the three cells of the previous line.
            if (math.sub(usize, index, line_diff)) |index_prev_line| {
                if (index_prev_line != 0) adjacencies[index_prev_line-1] -= 1;
                adjacencies[index_prev_line] -= 1;
                adjacencies[index_prev_line+1] -= 1;
            } else |_| {}

            // Do the same for the next line, if this is not the last.
            const index_next_line = index + line_diff;
            if (index_next_line < input.len) {
                adjacencies[index_next_line-1] -= 1;
                adjacencies[index_next_line] -= 1;
                adjacencies[index_next_line+1] -= 1;
            }
        },
    }}

    var total: u16 = 0;
    for (adjacencies) |adjacency| total += @intFromBool( adjacency > 0 );

    return total;
}

pub fn part1InPlace(input: []u8) !u16 {
    assert(input[0] != '\n');
    const adjacencies: []i8 = inputToAdjacencies(
        input,
        ( mem.findScalarPos(u8, input, 0, '\n') orelse return error.InputInvalid ) + 1,
        math.maxInt(i8),
    );
    var total: u16 = 0;
    for (adjacencies) |a| total += @intFromBool(a<4);
    return total;
}

test part2 {
    const example_input =
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
        \\
    ;
    var input_mut: [example_input.len]u8 = example_input.*;
    const example_answer = 43;
    try testing.expectEqual(example_answer, try part2(&input_mut));
}

pub fn part2(input: []u8) !u16 {
    assert(input[0] != '\n');
    const line_diff: usize = ( mem.findScalarPos(u8, input, 0, '\n') orelse return error.InputInvalid ) + 1;
    const not_a_roll: i8 = math.maxInt(i8);
    const adjacencies: []i8 = inputToAdjacencies(input, line_diff, not_a_roll);
    assert(adjacencies[adjacencies.len-1] == not_a_roll);

    var removed_count: u16 = 0;

    var cont: bool = true;
    while (cont) {
        cont = false;

        // Avoid the final byte to skip an additional test within the loop
        for (adjacencies[0..adjacencies.len-1], 0..) |*a, i| {
            if (a.* < 4) {
                a.* = not_a_roll;
                removed_count += 1;

                if (math.sub(usize, i, line_diff)) |i_prev| {
                    if (i_prev!=0) adjacencies[i_prev-1] -= 1;
                    adjacencies[i_prev] -= 1;
                    adjacencies[i_prev+1] -= 1;
                } else |_| {}

                if (i!=0) adjacencies[i-1] -= 1;
                adjacencies[i+1] -= 1;

                const i_next = i+line_diff;
                if (i_next < adjacencies.len) {
                    adjacencies[i_next-1] -= 1;
                    adjacencies[i_next] -= 1;
                    // Here we would have to test (i_next+1 < adjacencies.len) if we did not reslice
                    adjacencies[i_next+1] -= 1;
                }

                cont = true;
            }
        }
    }

    return removed_count;
}

test inputToAdjacencies {
    const input_literal =
        \\..@@.
        \\@@@.@
        \\@@@@@
        \\@.@@@
        \\@@.@@
        \\
    ;
    var input: [input_literal.len]u8 = input_literal.*;
    const nar: i8 = 127;
    const expected = [6*5]i8{
        nar, nar,   3,   3, nar, nar,
          3,   6,   6, nar,   3, nar,
          4,   7,   6,   7,   4, nar,
          4, nar,   6,   7,   5, nar,
          2,   3, nar,   4,   3, nar,
    };
    try testing.expectEqualSlices(i8, &expected, inputToAdjacencies(&input, 6, nar));
}

const roll: u8 = '@';
const roll_as_adj: i8 = @bitCast(roll);

// Assert that the input characters do not overlap with the signed ints we use
comptime {
    const CastTo = i8;
    for ([_]u8{ '@', '.', '\n' }) |char| switch (@as(CastTo, @bitCast(char))) {
        else => {},
        0...8 => |int| @compileError(std.fmt.comptimePrint(
            "valid input char \'{c}\' bitcasts to {d} as {s}",
            .{ char, int, @typeName(CastTo) },
        )),
    };
}

/// Mutate the input in-place to an adjacency count buffer.
///
/// I'm realizing after finishing my solution that
/// it is probably not necessary to bitcast to signed,
/// because saturating subtraction exists,
/// but the solution still works.
/// This way potentially avoids the test for saturation?
fn inputToAdjacencies(input: []u8, line_diff: usize, comptime nar: i8) []i8 {
    comptime { switch (@as(u8, @bitCast(nar))) {
        '@', '.', '\n' => |c| @compileError(std.fmt.comptimePrint(
            "not-a-roll {s} value {d} conflicts with valid input char \'{c}\'",
            .{ @typeName(@TypeOf(nar)), nar, c },
        )),
        else => {},
    }}
    assert(input[input.len-1] == '\n');
    const adj: []i8 = @ptrCast(input);
    for (adj[0..adj.len-1], 0..) |*a, i| if (a.* == roll_as_adj) {
        var count: i8 = 0;

        if (math.sub(usize, i, line_diff)) |i_prev| {
            if (i_prev!=0) count += @intFromBool(isRollDuringCast(adj[i_prev-1], nar));
            count += @intFromBool(isRollDuringCast(adj[i_prev], nar));
            count += @intFromBool(isRollDuringCast(adj[i_prev+1], nar));
        } else |_| {}

        if (i!=0) count += @intFromBool(isRollDuringCast(adj[i-1], nar));
        count += @intFromBool(isRollDuringCast(adj[i+1], nar));

        const i_next = i+line_diff;
        if (i_next < adj.len) {
            count += @intFromBool(isRollDuringCast(adj[i_next-1], nar));
            count += @intFromBool(isRollDuringCast(adj[i_next], nar));
            count += @intFromBool(isRollDuringCast(adj[i_next+1], nar));
        }

        a.* = count;
    } else { a.* = nar; };
    adj[adj.len-1] = nar; // avoid awkward check for final byte
    return adj;
}

/// Check if a byte is a roll ('@')
/// or a roll that we have already cast to an adjacency count
fn isRollDuringCast(adj: i8, comptime nar: i8) bool {
    return switch (adj) {
        roll_as_adj, 0...8 => true,
        nar,
        @as(i8, @bitCast(@as(u8, '.'))),
        @as(i8, @bitCast(@as(u8, '\n'))) => false,
        else => unreachable,
    };
}

test "line diff is line length plus one" {
    const example =
        \\fou
        \\bar
        \\
    ;

    const line_len = 3;
    const line_diff = line_len + 1;

    const a_index = mem.findScalarPos(u8, example, 0, 'a') orelse return error.IndexNotFound;
    const o_index = mem.findScalarPos(u8, example, 0, 'o') orelse return error.IndexNotFound;
    const f_index = mem.findScalarPos(u8, example, 0, 'f') orelse return error.IndexNotFound;

    try testing.expectEqual(o_index, a_index - line_diff);
    try testing.expectEqual(f_index, a_index - line_diff - 1);
    try testing.expectEqual(a_index, o_index + line_diff);
}

const assert = std.debug.assert;
const testing = std.testing;
const math = std.math;
const mem = std.mem;
const std = @import("std");
