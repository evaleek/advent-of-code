test part1 {
    const example =
        \\123 328  51 64 
        \\ 45 64  387 23 
        \\  6 98  215 314
        \\*   +   *   +  
        \\
    ;
    const answer = 4277556;
    try testing.expectEqual(answer, part1(example));
}

const Number = u64;

var buffer: [1024][2]Number = undefined;

/// Keep a sum and product for every column, and discard one at the end.
pub fn part1(input: []const u8) !Number {
    buffer = undefined;
    var list: std.ArrayList([2]Number) = .{
        .items = buffer[0..0],
        .capacity = buffer.len,
    };

    var line_iter = mem.splitScalar(u8, input, '\n');

    {
        // On the first line, grow the list to size
        const line = line_iter.first();
        assert(line.len != 0);
        var iter = mem.tokenizeScalar(u8, line, ' ');
        while (iter.next()) |token| {
            const num: Number = fmt.parseUnsigned(Number, token, 10)
                catch return error.ParseFailure;
            try list.appendBounded(@splat(num));
        }
    }

    // Hacky way to jump back to the start of the line once we encounter the operators
    var last_index: usize = line_iter.index.?;

    while (line_iter.next()) |line| {
        assert(line.len != 0);
        var iter = mem.tokenizeScalar(u8, line, ' ');

        switch (iter.peek().?[0]) {
            '0'...'9' => {
                last_index = line_iter.index.?;
            },
            '+', '*' => {
                line_iter.index = last_index;
                break;
            },
            else => unreachable,
        }

        var i: usize = 0;
        while (iter.next()) |token| : (i+=1) {
            const num: Number = fmt.parseUnsigned(Number, token, 10)
                catch return error.ParseFailure;
            list.items[i][0] += num;
            list.items[i][1] *= num;
        }
        assert(i==list.items.len);
    }

    var grand_total: Number = 0;

    {
        const line = line_iter.next().?;
        assert(line.len != 0);
        var iter = mem.tokenizeScalar(u8, line, ' ');
        var i: usize = 0;
        while (iter.next()) |token| : (i+=1) {
            assert(token.len==1);
            grand_total += switch (token[0]) {
                '+' => list.items[i][0],
                '*' => list.items[i][1],
                else => unreachable,
            };
        }
        assert(i==list.items.len);
    }

    return grand_total;
}

const assert = std.debug.assert;
const testing = std.testing;
const fmt = std.fmt;
const mem = std.mem;
const std = @import("std");
