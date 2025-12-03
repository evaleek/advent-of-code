test part1 {
    const example_input =
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
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
        if (char == '\n') {
            // Instead of a nested 'for line, for char' loop,
            // reset after each newline.
            // Start in the else block.

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
        } else {
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
    // The compiler already precomputes as much as it can,
    // but we can explicitly guarantee it like this.
    return char - (comptime '1'-1);
}

const assert = std.debug.assert;
const testing = std.testing;
const mem = std.mem;
const std = @import("std");
