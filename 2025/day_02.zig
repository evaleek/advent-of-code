pub fn part1(input: []const u8) u64 {
    var total: u64 = 0;

    var input_iter = Iterator{
        .buffer = input,
        .index = 0,
        .delimiter = ',',
    };

    var buf: [64]u8 = undefined;

    while (input_iter.next()) |range_string| {
        var iter = mem.SplitIterator(u8, .any){
            .buffer = range_string,
            .index = 0,
            .delimiter = &.{ '-', '\n' },
        };
        const first_string = iter.first();
        const last_string = iter.next().?;
        // cutScalar is only on master
        //const first_string, const last_string = mem.cutScalar(u8, range_string, '-').?;
        const first = fmt.parseInt(u64, first_string, 10) catch unreachable;
        const second = fmt.parseInt(u64, last_string, 10) catch return total;

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

const Iterator = mem.SplitIterator(u8, .scalar);

const fmt = std.fmt;
const mem = std.mem;
const std = @import("std");
