test part1 {
    const example =
        \\.......S.......
        \\...............
        \\.......^.......
        \\...............
        \\......^.^......
        \\...............
        \\.....^.^.^.....
        \\...............
        \\....^.^...^....
        \\...............
        \\...^.^...^.^...
        \\...............
        \\..^...^.....^..
        \\...............
        \\.^.^.^.^.^...^.
        \\...............
        \\
    ;
    const answer = 21;
    try testing.expectEqual(answer, part1(example));
}

pub fn part1(input: []const u8) !u16 {
    var beam_mask_array: [beam_mask_len]u8 = @splat(0);
    //var line_limit_mask_array: [beam_mask_len]u8 = @splat(0);

    const line_len: u16 = first_line: {
        var i: u16 = 0;
        var saw_s: if (debug_build) u8 else void = if (debug_build) 0 else {};
        while (input[i] != '\n') : (i += 1) {
            if (i > beam_mask_len-1) return error.LineLengthOverflow;
            //line_limit_mask_array[i] = 1;
            if (input[i] == 'S') {
                if (debug_build) saw_s += 1;
                // We needed it to be an array first so we could access by index
                beam_mask_array[i] = 1;
            } else {
                assert(input[i] == '.');
            }
        }
        if (debug_build) {
            if (saw_s == 0) {
                std.log.warn("encountered no \'S\' char on the first line", .{});
                return 0;
            } else if (saw_s != 1) {
                std.log.warn("encountered {d} \'S\' chars on the first line", .{saw_s});
            }
        }
        break :first_line i;
    };

    var beam_mask: BeamMask = beam_mask_array;
    //const line_limit_mask: BeamMask = line_limit_mask_array;

    // The way that this while loop iterates through the lines currently assumes this.
    assert(input[input.len-1] == '\n');

    var split_total: u16 = 0;

    var rem_lines = input[line_len+1..];
    var line_buf: [beam_mask_len]u8 = undefined;
    while (rem_lines.len >= line_len) : (rem_lines = rem_lines[line_len+1..]) {
        line_buf = @splat('.');
        @memcpy(line_buf[0..line_len], rem_lines[0..line_len]);
        const splitters: BeamMask = @intFromBool(@as(BeamMask, line_buf) == @as(BeamMask, @splat('^')));
        const hits = splitters & beam_mask;
        split_total += @reduce(.Add, hits);
        beam_mask = (beam_mask - hits) | split(hits, .combine);
    }
    assert(rem_lines.len == 0);

    //beam_mask &= line_limit_mask;

    return split_total;
}

test part2 {
    const example =
        \\.......S.......
        \\...............
        \\.......^.......
        \\...............
        \\......^.^......
        \\...............
        \\.....^.^.^.....
        \\...............
        \\....^.^...^....
        \\...............
        \\...^.^...^.^...
        \\...............
        \\..^...^.....^..
        \\...............
        \\.^.^.^.^.^...^.
        \\...............
        \\
    ;
    const answer = 40;
    try testing.expectEqual(answer, part2(example));
}

// We can track the number of active timelines
// by incrementing a column when a new timeline begins on it.
// This is the main difference from part 1, that is,
// we can think of it as the same problem, but beams on the same column
// are added instead of combined into `1`.
pub fn part2(input: []const u8) !u64 {
    var beam_mask_array: [beam_mask_len]WideBeam = @splat(0);
    var line_limit_mask_array: [beam_mask_len]WideBeam = @splat(0);

    const line_len: u16 = first_line: {
        var i: u16 = 0;
        var saw_s: if (debug_build) u8 else void = if (debug_build) 0 else {};
        while (input[i] != '\n') : (i += 1) {
            if (i > beam_mask_len-1) return error.LineLengthOverflow;
            line_limit_mask_array[i] = math.maxInt(WideBeam);
            if (input[i] == 'S') {
                if (debug_build) saw_s += 1;
                // We needed it to be an array first so we could access by index
                beam_mask_array[i] = 1;
            } else {
                assert(input[i] == '.');
            }
        }
        if (debug_build) {
            if (saw_s == 0) {
                std.log.warn("encountered no \'S\' char on the first line", .{});
                return 0;
            } else if (saw_s != 1) {
                std.log.warn("encountered {d} \'S\' chars on the first line", .{saw_s});
            }
        }
        break :first_line i;
    };

    var beam_mask: BeamMaskWide = beam_mask_array;
    const line_limit_mask: BeamMaskWide = line_limit_mask_array;

    // The way that this while loop iterates through the lines currently assumes this.
    assert(input[input.len-1] == '\n');

    var rem_lines = input[line_len+1..];
    var line_buf: [beam_mask_len]WideBeam = undefined;
    while (rem_lines.len >= line_len) : (rem_lines = rem_lines[line_len+1..]) {
        line_buf = @splat('.');
        // We have to widen the beam mask, because
        // many beam paths now have much more than 255 timelines.
        // Unfortunately this means we can't just @memcpy
        for (line_buf[0..line_len], rem_lines[0..line_len]) |*dest, src| dest.* = src;
        // We need to keep all timelines, not just the one encoded in the first bit
        const splitters: BeamMaskWide = @as(BeamMaskWide, @splat(math.maxInt(WideBeam))) *
            @intFromBool(@as(BeamMaskWide, line_buf) == @as(BeamMaskWide, @splat('^')));
        const hits = splitters & beam_mask;
        beam_mask = (beam_mask - hits) + split(hits, .add);
    }
    assert(rem_lines.len == 0);

    return @reduce(.Add, beam_mask & line_limit_mask);
}

const beam_mask_len = 256;
// This would have been bool, but the compiler says bool vector > 8 bytes is unimplemented
const BeamMask = @Vector(beam_mask_len, u8);

// Part 2 overflows a u8 on individual beam columns.
// In fact it also overflows u16 and u32
const WideBeam = u64;
const BeamMaskWide = @Vector(beam_mask_len, WideBeam);

const Split = enum { combine, add };

fn split(beam_mask: anytype, comptime op: Split) @TypeOf(beam_mask) {
    const Mask = @TypeOf(beam_mask);
    const Component = switch (@typeInfo(Mask)) {
        .vector => |vector| vector.child,
        else => @compileError("unsupported beam mask type " ++ @typeName(BeamMask)),
    };
    const ShuffleMask = @Vector(beam_mask_len, i32);
    const shift: ShuffleMask = @splat(1);
    const iota = std.simd.iota(i32, beam_mask_len);
    const right = iota - shift;
    comptime var left = iota + shift;
    left[beam_mask_len-1] = -1;
    const outer = @Vector(1, Component){ 0 };

    const split_left = @shuffle(Component, beam_mask, outer, left);
    const split_right = @shuffle(Component, beam_mask, outer, right);
    return switch (op) {
        .combine => split_left | split_right,
        .add => split_left + split_right,
    };
}

const assert = std.debug.assert;
const debug_build = @import("builtin").mode == .Debug;
const math = std.math;
const mem = std.mem;
const testing = std.testing;
const std = @import("std");
