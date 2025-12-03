test part1 {
    const example_input =
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
        \\
    ;
    const example_solution = 357;

    try testing.expectEqual(example_solution, part1(example_input));
}

pub fn part1(input: []const u8) u16 {
    var total: u16 = 0;

    // Keeping three values allows traversing the sequence only once.
    var before_greatest: u8 = 0;
    var greatest: u8 = 0;
    var after_greatest: u8 = 0;

    for (input) |char| {
        if (char != '\n') {
            if (char < '1' or char > '9') {
                std.debug.print("unexpected character '\'{c}\' in input", .{ char });
                unreachable;
            }

            const d = intFromChar(char);
            if (d > greatest) {
                after_greatest = 0;
                before_greatest = greatest;
                greatest = d;
            } else if (d > after_greatest) {
                after_greatest = d;
            }

        } else {
            // Instead of a nested 'for line, for char' loop,
            // reset after each newline.

            assert(greatest > 0);

            // If `after_greatest` ended on 0,
            // then the greatest digit was the final digit,
            // and we need to use the previous greatest in the tens place.
            // Otherwise, the greatest joltage will always be
            // the greatest single digit in the sequence in the tens place,
            // with the greatest digit following it in the ones place.
            total +=
                if (after_greatest == 0) 10 * before_greatest + greatest
                else 10 * greatest + after_greatest
            ;

            before_greatest = 0;
            greatest = 0;
            after_greatest = 0;
        }
    }

    return total;
}

test part2 {
    const example_input =
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
        \\
    ;
    const example_solution = 3121910778619;

    try testing.expectEqual(example_solution, part2(example_input));
}

pub fn part2(input: []const u8) u64 {
    var total: u64 = 0;

    // It's helpful now to know the line length.
    var line_iter: mem.SplitIterator(u8, .scalar) = .{
        .buffer = input,
        .index = 0,
        .delimiter = '\n',
    };

    while (line_iter.next()) |line| {
        if (line.len == 0) continue;

        var digits: [12]u8 = @splat(0);
        var end: u8 = 0;

        for (line, 0..) |char, line_index| {
            const bat = intFromChar(char);

            for (digits[0..end], 0..) |*digit, i| {
                if (bat > digit.* and ( digits.len-i + line_index <= line.len or i == digits.len-1 )) {
                    digit.* = bat;
                    @memset(digits[i+1..], 0);
                    break;
                }
            } else if (end != digits.len) {
                digits[end] = bat;
                end += 1;
            }
        }

        //std.debug.print("{s}\n-> ", .{line});
        //for (digits) |digit| std.debug.print("{d}", .{digit});
        //std.debug.print("\n", .{});

        for (digits, 1..) |digit, p| {
            assert(digit != 0 and digit <= 9);
            total += digit * (math.powi(u64, 10, digits.len-p) catch unreachable);
        }
    }

    return total;
}

test intFromChar {
    try testing.expectEqual(1, intFromChar('1'));
    try testing.expectEqual(2, intFromChar('2'));
    try testing.expectEqual(3, intFromChar('3'));
    try testing.expectEqual(4, intFromChar('4'));
    try testing.expectEqual(5, intFromChar('5'));

    try testing.expectEqual(6, intFromChar('6'));
    try testing.expectEqual(7, intFromChar('7'));
    try testing.expectEqual(8, intFromChar('8'));
    try testing.expectEqual(9, intFromChar('9'));
}

/// Parse a single-digit integer from a numeral character code.
fn intFromChar(char: u8) u8 {
    // The input is constrained to 1-9.
    assert(char >= '1' and char <= '9');
    // Take advantage of the fact that the numeral ASCII character codes
    // are in contiguous ascending order.
    return char - '0';
}

const assert = std.debug.assert;
const testing = std.testing;
const math = std.math;
const mem = std.mem;
const std = @import("std");
