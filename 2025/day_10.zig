test part1 {
    const example =
        \\[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
        \\[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
        \\[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
        \\
    ;
    const answer = 7;
    try testing.expectEqual(answer, try part1(example));
}

/// Some observations that help:
/// - We can think of each button as a mask of 0s and 1s, for example:
///   for a machine with four lights, a "(0,1)" button would be { 1, 1, 0, 0 },
/// - We can combine sets of button masks
///   to get the light state after pressing all of those buttons,
///   where the final sum at index *i* indicates an active light if odd
///   ({1,1,0,0} + {0,1,1,0} = {1,2,1,0} =>
///   first light is on, second light is off, third light is on, fourth light is off)
/// - Sum mod 2 is equivalent to using bitmasks combined with XOR
/// - Commutativity of addition:
///   the problem space is not ordered sequences of button presses,
///   just unordered combinations of buttons
/// - Solutions will never have the same button pressed more than once,
///   because pressing it an even number of times is an identity,
///   and pressing it an odd number of times is idempotent
/// - So, the possible solutions map to the possible subsets of the set of buttons,
///   and we want to visit them all in order of smallest to largest
///   until we find one that combines to the target light mask
pub fn part1(input: []const u8) !u16 {
    button_buffer = undefined;
    var button_list = emptyListFromBuffer(&button_buffer);

    var total_presses: u16 = 0;

    var line_iter = mem.splitScalar(u8, input, '\n');
    next_machine: while (line_iter.next()) |line| : (button_list.clearRetainingCapacity()) {
        if (line.len == 0) continue;

        // There is TokenIterator,
        // but the input lines always delimit tokens with single spaces
        var token_iter = mem.splitScalar(u8, line, ' ');

        const lights_token = token_iter.first();
        assert(lights_token[0] == '[');
        assert(lights_token[lights_token.len-1] == ']');
        const lights_no_brackets = lights_token[1..lights_token.len-1];
        const lights_target: ButtonMask = make_target_mask: {
            if (lights_no_brackets.len > button_mask_size) return error.ButtonMaskOverflow;
            var mask: ButtonMask = .initEmpty();
            for (lights_no_brackets, 0..) |c, i| { switch (c) {
                '#' => mask.set(i),
                '.' => {},
                else => unreachable,
            }}
            break :make_target_mask mask;
        };

        while (token_iter.next()) |token| {
            if (token.len == 0) continue;
            if (token[0] == '{') {
                assert(token[token.len-1] == '}');
                continue;
            } else {
                assert(token[0] == '(');
                assert(token[token.len-1] == ')');
                var seq_iter = mem.splitScalar(u8, token[1..token.len-1], ',');
                var button: ButtonMask = .initEmpty();
                while (seq_iter.next()) |num_string| {
                    if (num_string.len == 0) continue;
                    const num = try fmt.parseUnsigned(u8, num_string, 10);
                    if (num >= button_mask_size) return error.ButtonMaskOverflow;
                    assert(!button.isSet(num));
                    button.set(num);
                }
                if (lights_target.eql(button)) {
                    total_presses += 1;
                    continue :next_machine;
                }
                try button_list.appendBounded(button);
            }
        }

        if (button_list.items.len > max_n) return error.ButtonCountOverflow;
        var buttons: [max_n]ButtonMaskInt = @splat(0);
        @memcpy(
            buttons[0..button_list.items.len],
            @as([]const ButtonMaskInt, @ptrCast(button_list.items)),
        );
        total_presses += smallestMatchingCombinationSize(
            @bitCast(lights_target),
            buttons,
            @intCast(button_list.items.len),
        ) orelse return error.NoMatchingCombination;
    }

    return total_presses;
}

const button_mask_size = 16;
var button_buffer: [button_mask_size]ButtonMask = undefined;

const ButtonMask = std.bit_set.IntegerBitSet(button_mask_size);
const ButtonMaskInt = ButtonMask.MaskInt;

const max_n = 16;
/// Assumes singleton sets were already checked (start at k=2)
fn smallestMatchingCombinationSize(target: ButtonMaskInt, buttons: @Vector(max_n, ButtonMaskInt), n: u8) ?u16 {
    assert(n > 1);
    assert(n <= max_n);

    var index_vec_buffer: [max_n]u8 = undefined;

    for (2..n) |k| {
        const index_vec = index_vec_buffer[0..k];
        @memset(index_vec, undefined);
        for (index_vec, 0..) |*idx, i| idx.* = @intCast(i);

        index_vec_inc: while (true) {
            if (buttonCombination(buttons, index_vec) == target) return @intCast(k);
            // Find the rightmost element that we can increment,
            // or stop the loop if there are no more
            var i: u8 = @intCast(index_vec.len);
            while (i != 0) {
                i -= 1;
                if (index_vec[i] != i + (n - k)) {
                    index_vec[i] += 1;
                    for (i+1..index_vec.len) |j| index_vec[j] = index_vec[j-1] + 1;
                    continue :index_vec_inc;
                }
            }
            break :index_vec_inc;
        }
    }

    return if ( @reduce(.Xor, buttons) == target ) n else null;
}

fn buttonCombination(buttons: @Vector(max_n, ButtonMaskInt), indices: []const u8) ButtonMaskInt {
    assert(indices.len <= max_n);

    var select_arr: [max_n]ButtonMaskInt = @splat(0);
    for (indices) |idx| select_arr[idx] = math.maxInt(ButtonMaskInt);
    const select_mask: @Vector(max_n, ButtonMaskInt) = select_arr;

    // Each element of select_mask is either 0b0..0, or 0b1..1 for indices in the combination.
    // Bitwise & of the buttons with select_mask zeroes out buttons not in the combination,
    // and we can then XOR the non-zero elements to get the button combination result

    return @reduce(.Xor, buttons & select_mask);
}

fn emptyListFromBuffer(buffer: anytype) ListFromBuffer(@TypeOf(buffer)) {
    buffer.* = undefined;
    return .{
        .items = buffer[0..0],
        .capacity = buffer.len,
    };
}

fn ListFromBuffer(Buffer: type) type {
    switch (@typeInfo(Buffer)) {
        .pointer => |pointer| {
            if (pointer.size != .one or pointer.is_const or @typeInfo(pointer.child) != .array) {
                @compileError("unsupported list backing buffer type: " ++ @typeName(Buffer));
            } else {
                return std.ArrayList(@typeInfo(pointer.child).array.child);
            }
        },
        else => @compileError("unsupported list backing buffer type: " ++ @typeName(Buffer)),
    }
}

const assert = std.debug.assert;
const testing = std.testing;
const math = std.math;
const fmt = std.fmt;
const mem = std.mem;
const std = @import("std");
