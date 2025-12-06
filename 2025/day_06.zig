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

var buffer: [1024][2]u64 = undefined;

/// Keep a sum and product for every column, and discard one at the end.
pub fn part1(input: []const u8) !u64 {
    buffer = undefined;
    var list: std.ArrayList([2]u64) = .{
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
            const num: u64 = fmt.parseUnsigned(u64, token, 10)
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
            const num: u64 = fmt.parseUnsigned(u64, token, 10)
                catch return error.ParseFailure;
            list.items[i][0] += num;
            list.items[i][1] *= num;
        }
        assert(i==list.items.len);
    }

    var grand_total: u64 = 0;

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

test part2 {
    const example =
        \\123 328  51 64 
        \\ 45 64  387 23 
        \\  6 98  215 314
        \\*   +   *   +  
        \\
    ;
    const answer = 3263827;
    try testing.expectEqual(answer, part2(example));
}

var problem_buffer: [1024]Problem = undefined;

/// The tricky part of this problem is aligning the digits as we parse them,
/// because the columns are variable width.
pub fn part2(input: []const u8) !u64 {
    problem_buffer = undefined;
    var problem_list: std.ArrayList(Problem) = .{
        .items = problem_buffer[0..0],
        .capacity = problem_buffer.len,
    };

    var line_iter = mem.splitScalar(u8, input, '\n');

    {
        const line = line_iter.first();
        assert(line.len != 0);

        var i: u16 = 0;
        while (i < line.len-1) {
            while (line[i]==' ') : (i+=1) {}
            const start = i;
            while (i<line.len and line[i]!=' ') : (i+=1) {}
            const len = i-start;
            assert(len >= 1 and len <= 4);
            assert(line[start] > '0' and line[start] <= '9');
            if (len >= 2) assert(line[start+1] > '0' and line[start+1] <= '9');
            if (len >= 3) assert(line[start+2] > '0' and line[start+2] <= '9');
            if (len == 4) assert(line[start+3] > '0' and line[start+3] <= '9');
            try problem_list.appendBounded(.{
                .column = start,
                .digits = .{
                    line[start]-'0',
                    if (len>=2) line[start+1]-'0' else 0,
                    if (len>=3) line[start+2]-'0' else 0,
                    if (len==4) line[start+3]-'0' else 0,
                },
            });
        }
    }

    const problems = problem_list.items;

    var last_index: usize = line_iter.index.?;

    while (line_iter.next()) |line| {
        assert(line.len != 0);

        const first_non_space: u8 = find: {
            var i: usize = 0;
            while (i<line.len) : (i+=1) if (line[i]!=' ') break :find line[i];
            unreachable;
        };
        switch (first_non_space) {
            '1'...'9' => {
                last_index = line_iter.index.?;
            },
            '+', '*' => {
                line_iter.index = last_index;
                break;
            },
            else => unreachable,
        }

        var i: u16 = 0;
        var col: u16 = 0;
        while (col < line.len-1) : (i+=1) {
            while (col<line.len and line[col]==' ') : (col+=1) {}
            const start = col;
            while (col<line.len and line[col]!=' ') : (col+=1) {}
            const len = col-start;
            if (len==0) continue;
            assert(len >= 1 and len <= 4);
            assert(line[start] > '0' and line[start] <= '9');
            if (len >= 2) assert(line[start+1] > '0' and line[start+1] <= '9');
            if (len >= 3) assert(line[start+2] > '0' and line[start+2] <= '9');
            if (len == 4) assert(line[start+3] > '0' and line[start+3] <= '9');

            const new_digits: @Vector(4, u64) = .{
                line[start]-'0',
                if (len>=2) line[start+1]-'0' else 0,
                if (len>=3) line[start+2]-'0' else 0,
                if (len==4) line[start+3]-'0' else 0,
            };

            // If the new digits start on a column before the current leftmost,
            // realign the working digits to the new leftmost column
            const top_shift = problems[i].column -| start;
            assert(top_shift >= 0 and top_shift <= 3);
            problems[i].column -= top_shift;
            problems[i].digits = shiftRight(problems[i].digits, @intCast(top_shift));

            // If the new digits start on a column after the current leftmost,
            // shuffle the new digits to align with the working digits
            const bot_shift = start -| problems[i].column;
            assert(bot_shift >= 0 and bot_shift <= 3);
            assert(bot_shift <= 4-len);
            const new_digits_aligned = shiftRight(new_digits, @intCast(bot_shift));

            // Incorporate new lines as we read them
            // by promoting the current working digits to the next decimal place
            // and adding in the new digits in the ones place.
            // This assumes there are no 0s in the input
            // (which has been asserted above).

            // Only promote digits if the new row is not blank
            const promote = @select(
                u64,
                new_digits_aligned > @Vector(4, u64){ 0, 0, 0, 0 },
                @Vector(4, u64){ 10, 10, 10, 10 },
                @Vector(4, u64){ 1, 1, 1, 1 },
            );

            problems[i].digits = promote * problems[i].digits + new_digits_aligned;
        }
    }

    var grand_total: u64 = 0;

    {
        const line = line_iter.next().?;
        assert(line.len != 0);
        var i: usize = 0;
        for (line) |char| { if (char!=' ') {
            grand_total += problems[i].solve(char);
            i += 1;
        }}
        assert(i == problem_list.items.len);
    }

    return grand_total;
}

const Problem = struct {
    digits: @Vector(4, u64) align(64),
    /// The leftmost column index (by character)
    /// that the working digit total of this problem column appears in.
    column: u16,

    pub inline fn solve(problem: Problem, op_char: u8) u64 {
        return switch (op_char) {
            '+' => @reduce(.Add, problem.digits),
            // Annoyingly, in the Mul reduce case,
            // we need the blank columns (until now kept as 0)
            // to be 1 for a valid product
            '*' => @reduce(.Mul, @select(
                u64,
                problem.digits != @Vector(4, u64){ 0, 0, 0, 0 },
                problem.digits,
                @Vector(4, u64){ 1, 1, 1, 1 },
            )),
            else => unreachable,
        };
    }
};

test shiftRight {
    const vec: @Vector(4, u64) = .{ 1, 2, 3, 4 };
    const shift: i32 = 2;
    const expected: @Vector(4, u64) = .{ 0, 0, 1, 2 };
    try testing.expectEqual(expected, shiftRight(vec, shift));
}

inline fn shiftRight(digits: @Vector(4, u64), right_shift: u2) @Vector(4, u64) {
    //return @shuffle(
    //    u64,
    //    digits,
    //    @Vector(4, u64){ 0, 0, 0, 0 },
    //    @Vector(4, i32){ 0, 1, 2, 3 } - @as(@Vector(4, i32), @splat(right_shift)),
    //);
    // I thought I was being clever but it turns out the mask is a comptime param.
    return switch (right_shift) {
        inline 0...3 => |shift| @shuffle(
            u64,
            digits,
            @Vector(4, u64){ 0, 0, 0, 0 },
            @Vector(4, i32){ 0, 1, 2, 3 } - @as(@Vector(4, i32), @splat(shift)),
        ),
    };
}

const assert = std.debug.assert;
const testing = std.testing;
const fmt = std.fmt;
const mem = std.mem;
const std = @import("std");
