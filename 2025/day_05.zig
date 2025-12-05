test part1 {
    const input =
        \\3-5
        \\10-14
        \\16-20
        \\12-18
        \\
        \\1
        \\5
        \\8
        \\11
        \\17
        \\32
        \\
    ;
    const answer = 3;
    try testing.expectEqual(answer, try part1(input));
}

var range_buffer: [512][2]u64 = undefined;

pub fn part1(input: []const u8) !u16 {
    range_buffer = undefined;
    var range_list: std.ArrayList([2]u64) = .{
        .items = range_buffer[0..0],
        .capacity = range_buffer.len,
    };

    var line_iter = mem.splitScalar(u8, input, '\n');

    while (line_iter.next()) |line| {
        // The two halves of the input are separated by a double newline.
        // We would not see this if using TokenIterator versus SplitIterator.
        if (line.len == 0) break;

        const new_range: [2]u64 = parse_range: {
            const left, const right = mem.cutScalar(u8, line, '-')
                orelse return error.ParseFailure;
            break :parse_range [2]u64{
                fmt.parseUnsigned(u64, left, 10) catch return error.ParseFailure,
                fmt.parseUnsigned(u64, right, 10) catch return error.ParseFailure,
            };
        };

        if (new_range[0] > new_range[1]) return error.ParseFailure;

        // We need the list of ranges to be sorted
        // so that we can add or merge new ranges as we parse them,
        // and efficiently search it in the second half.
        // We're building the list as we parse it,
        // so we might as well insertion sort.
        var list_iter = mem.reverseIterator(range_list.items);
        while (list_iter.nextPtr()) |range_ptr| {
            if ( new_range[0] >= range_ptr[0] ) {
                const i = list_iter.index;
                // The new range starts after the current range start,
                if ( new_range[0] <= range_ptr[1]+1 ) {
                    // and before this current range end
                    // -> merge the new range into the current range
                    range_ptr[1] = @max(new_range[1], range_ptr[1]);
                    // We have potentially invalidated everything after this index
                    while ( i+1 < range_list.items.len and range_ptr[1]+1 >= range_list.items[i+1][0] ) {
                        range_ptr[1] = @max(range_list.items[i+1][1], range_ptr[1]);
                        _ = range_list.orderedRemove(i+1);
                    }
                } else {
                    if ( i+1 < range_list.items.len ) {
                        // and after the current range end
                        // (but before the start of the next range),
                        if ( new_range[1]+1 >= range_list.items[i+1][0] ) {
                            // and it overlaps with the next range
                            // -> merge the new range into the next range
                            range_list.items[i+1][0] = new_range[0];
                            range_list.items[i+1][1] = @max(new_range[1], range_list.items[i+1][1]);
                            while ( i+2 < range_list.items.len and range_list.items[i+1][1]+1 >= range_list.items[i+2][0] ) {
                                range_list.items[i+1][1] = @max(range_list.items[i+2][1], range_list.items[i+1][1]);
                                _ = range_list.orderedRemove(i+2);
                            }
                        } else {
                            // and it ends before the start of the next range
                            try range_list.insertBounded(i+1, new_range);
                        }
                    } else {
                        try range_list.appendBounded(new_range);
                    }
                }
                break;
            }
        } else {
            if ( range_list.items.len != 0 and new_range[1]+1 >= range_list.items[0][0] ) {
                // The range start is less than all current range starts,
                // but the range end is mergeable with the bottom range
                range_list.items[0][0] = new_range[0];
                range_list.items[0][1] = @max(new_range[1], range_list.items[0][1]);
                while ( range_list.items.len > 1 and range_list.items[0][1]+1 >= range_list.items[1][0] ) {
                    range_list.items[0][1] = @max(range_list.items[1][1], range_list.items[0][1]);
                    _ = range_list.orderedRemove(1);
                }
            } else {
                try range_list.insertBounded(0, new_range);
            }
        }
    }

    // for (range_list.items) |range| std.debug.print("[{d}, {d}]\n", .{ range[0], range[1] });

    // We did something wrong if it is not now sorted and merged
    if (range_list.items.len > 0) for (
        range_list.items[0..range_list.items.len-1],
        range_list.items[1..],
    ) |prev, next| {
        assert(prev[0] <= prev[1]);
        assert(next[0] <= next[1]);
        assert(next[0] > prev[1]);
    };

    var count: u16 = 0;

    while (line_iter.next()) |line| {
        if (line.len == 0) continue;

        const ingredient: u64 = fmt.parseUnsigned(u64, line, 10)
            catch return error.ParseFailure;

        // The list is sorted and merged, so we can binary search.
        var low: usize = 0;
        var high: usize = range_list.items.len-1;
        const found: bool = while (low <= high) {
            const mid: usize = @divTrunc(low+high, 2);
            const range = range_list.items[mid];
            if ( ingredient >= range[0] ) {
                if ( ingredient <= range[1] ) break true;
                if ( mid == range_list.items.len-1 ) break false;
                if ( ingredient < range_list.items[mid+1][0] ) break false;
                low = mid+1;
            } else {
                if ( mid == 0 ) break false;
                if ( ingredient > range_list.items[mid-1][1] ) break false;
                high = mid;
            }
        } else false;

        count += @intFromBool(found);
    }

    return count;
}

const assert = std.debug.assert;
const testing = std.testing;
const fmt = std.fmt;
const mem = std.mem;
const std = @import("std");
