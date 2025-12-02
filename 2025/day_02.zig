pub const part1 = part1Ints;
pub const part2 = part2Strings;

pub fn part1Ints(input: []const u8) usize {
    var total: usize = 0;

    var input_iter = Iterator{
        .buffer = if (input[input.len-1] == '\n') input[0..input.len-1] else input,
        .index = 0,
        .delimiter = ',',
    };

    while (input_iter.next()) |range_string| {
        const first_string, const last_string = mem.cutScalar(u8, range_string, '-').?;
        const first = fmt.parseUnsigned(usize, first_string, 10) catch unreachable;
        const second = fmt.parseUnsigned(usize, last_string, 10) catch unreachable;
        for (first..second+1) |id| total += id * @intFromBool(isDouble(id) catch unreachable);
    }

    return total;
}

pub fn part1Strings(input: []const u8) u64 {
    var total: u64 = 0;

    var input_iter = Iterator{
        .buffer = if (input[input.len-1] == '\n') input[0..input.len-1] else input,
        .index = 0,
        .delimiter = ',',
    };

    var buf: [64]u8 = undefined;

    while (input_iter.next()) |range_string| {
        const first_string, const last_string = mem.cutScalar(u8, range_string, '-').?;
        const first = fmt.parseUnsigned(u64, first_string, 10) catch unreachable;
        const second = fmt.parseUnsigned(u64, last_string, 10) catch unreachable;

        for (first..second+1) |id| {
            const id_string = fmt.bufPrint(&buf, "{d}", .{id}) catch unreachable;
            if (id_string.len%2==0) {
                const half_len = @divExact(id_string.len, 2);
                if (mem.eql(u8,
                        id_string[0..half_len],
                        id_string[half_len..][0..half_len],
                    )
                ) total += id;
            }
        }
    }

    return total;
}

pub fn part2Strings(input: []const u8) u64 {
    var total: u64 = 0;

    var input_iter = Iterator{
        .buffer = if (input[input.len-1] == '\n') input[0..input.len-1] else input,
        .index = 0,
        .delimiter = ',',
    };

    var buf: [64]u8 = undefined;

    while (input_iter.next()) |range_string| {
        const first_string, const last_string = mem.cutScalar(u8, range_string, '-').?;
        const first = fmt.parseUnsigned(u64, first_string, 10) catch unreachable;
        const second = fmt.parseUnsigned(u64, last_string, 10) catch unreachable;

        for (first..second+1) |id| {
            const id_string = fmt.bufPrint(&buf, "{d}", .{id}) catch unreachable;
            total += sub: for (1..(@divTrunc(id_string.len, 2)+1)) |sub_len| {
                if (id_string.len%sub_len == 0) {
                    const substring = id_string[0..sub_len];
                    var start: usize = sub_len;
                    var all_equal: bool = true;
                    while (start+sub_len <= id_string.len) : (start += sub_len) {
                        const window = id_string[start..][0..sub_len];
                        if (!mem.eql(u8, substring, window)) all_equal = false;
                    }
                    if (all_equal) break :sub id;
                }
            } else 0;
        }
    }

    return total;
}

fn isDouble(id: usize) !bool {
    // 321123 -> 1000, 1212 -> 100, 12345 -> 100
    const half_mag = try math.powi(usize, 10, @divTrunc(digits(id), 2));
    // 321123 -> 321, 1212 -> 12, 12345 -> 123
    const upper = @divTrunc(id, half_mag);
    // 321123 -> 321123-321000=123, 12345 -> 12345-12300=45
    const lower = id - half_mag*upper;
    return upper == lower;
}

test digits {
    const R = math.Log2Int(usize);
    try testing.expectEqual(@as(R, 1), digits(@as(usize, 0)));
    try testing.expectEqual(@as(R, 1), digits(@as(usize, 1)));
    try testing.expectEqual(@as(R, 1), digits(@as(usize, 5)));
    try testing.expectEqual(@as(R, 1), digits(@as(usize, 9)));
    try testing.expectEqual(@as(R, 2), digits(@as(usize, 10)));
    try testing.expectEqual(@as(R, 2), digits(@as(usize, 16)));
    try testing.expectEqual(@as(R, 2), digits(@as(usize, 18)));
    try testing.expectEqual(@as(R, 2), digits(@as(usize, 20)));
    try testing.expectEqual(@as(R, 2), digits(@as(usize, 49)));
    try testing.expectEqual(@as(R, 3), digits(@as(usize, 100)));
    try testing.expectEqual(@as(R, 3), digits(@as(usize, 212)));
}

fn digits(int: anytype) math.Log2Int(@TypeOf(int)) {
    if (int > 0) {
        @branchHint(.likely);
        return math.log10_int(int)+1;
    } else {
        return 0+1;
    }
}

test incrementString {
    var buf: [4]u8 = "9898".*;

    try incrementString(&buf);
    try testing.expectEqualSlices(u8, "9899", &buf);

    try incrementString(&buf);
    try testing.expectEqualSlices(u8, "9900", &buf);

    buf = "9999".*;

    try testing.expectError(error.Overflow, incrementString(&buf));
}

/// Asserts that `string` is a sequence of numeral characters,
/// and increments it like it was an integer.
fn incrementString(string: []u8) !void {
    var i: usize = string.len-1;
    while (i >= 0) : (i -= 1) {
        assert(string[i] >= '0' and string[i] <= '9');
        if (string[i] == '9') {
            if (i == 0) {
                @branchHint(.cold);
                return error.Overflow;
            } else {
                string[i] = '0';
            }
        } else {
            string[i] += 1;
            break;
        }
    }
}

const Iterator = mem.SplitIterator(u8, .scalar);
const assert = std.debug.assert;

const math = std.math;
const testing = std.testing;
const fmt = std.fmt;
const mem = std.mem;
const std = @import("std");
