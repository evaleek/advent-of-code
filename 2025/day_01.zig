test part1 {
    const example_input =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;
    const example_solution = 3;
    try testing.expectEqual(example_solution, part1(example_input));
}

pub fn part1(input: []const u8) u16 {
    var at_zero_count: u16 = 0;
    var dial: Dial = 50;

    var iter: mem.TokenIterator(u8, .any) = .{
        .buffer = input,
        .delimiter = &std.ascii.whitespace,
        .index = 0,
    };

    while (iter.next()) |token| {
        if (rotation(token)) |rot| {
            dial = @mod(dial+rot, dial_click_count);
            if (dial == 0) at_zero_count += 1;
        } else |err| {
            log.err("{t} for token \'{s}\'", .{ err, token });
        }
    }

    return at_zero_count;
}

fn rotation(token: []const u8) !Dial {
    if (token.len < 2) return error.InvalidInput;
    const scalar: Dial = fmt.parseInt(u15, token[1..], 10) catch return error.InvalidInput;
    return switch (token[0]) {
        'L' => -scalar,
        'R' => scalar,
        else => error.InvalidInput,
    };
}

const Dial = i16;
const dial_click_count: Dial = 100;

const testing = std.testing;
const fmt = std.fmt;
const mem = std.mem;
const log = std.log;

const std = @import("std");
