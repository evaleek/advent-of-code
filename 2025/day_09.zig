test part1 {
    const example =
        \\7,1
        \\11,1
        \\11,7
        \\9,7
        \\9,5
        \\2,5
        \\2,3
        \\7,3
        \\
    ;
    const answer = 50;
    try testing.expectEqual(answer, try part1(example));
}

pub const part1 = part1Naive;

const max_tiles = 512;
var tiles_buffer: [max_tiles]RedTile = undefined;

// Similar to yesterday's problem,
// I am just doing an O(n^2) solution that requires us to
// build a list of all tiles and then iterate over it for each combination.
pub fn part1Naive(input: []const u8) !u64 {
    var tiles_list = emptyListFromBuffer(&tiles_buffer);
    var line_iter = mem.splitScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        if (line.len == 0) continue;

        const lhs, const rhs = mem.cutScalar(u8, line, ',') orelse return raiseParseError(line);
        const tile: RedTile = .{
            fmt.parseUnsigned(u32, lhs, 10) catch return raiseParseError(line),
            fmt.parseUnsigned(u32, rhs, 10) catch return raiseParseError(line),
        };

        try tiles_list.appendBounded(tile);
    }
    const tiles: []const RedTile = tiles_list.items;

    var max_area: u64 = 0;
    for (tiles) |tile_a| {
        for (tiles) |tile_b| {
            max_area = @max(max_area, area(.{ tile_a, tile_b }));
        }
    }

    return max_area;
}

fn area(rect: Rectangle) u64 {
    const diff = @abs( rect[1] - rect[0] ) + @Vector(2, u64){ 1, 1 };
    const a = @reduce(.Mul, diff);
    return a;
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

fn raiseParseError(line: []const u8) error{InvalidInput} {
    if (debug_build)
        std.log.err("failed to parse line \'{s}\' into a coordinate pair", .{ line });
    return error.InvalidInput;
}

const RedTile = @Vector(2, i64);
const Rectangle = [2]RedTile;

const debug_build = @import("builtin").mode == .Debug;
const assert = std.debug.assert;
const testing = std.testing;
const math = std.math;
const fmt = std.fmt;
const mem = std.mem;
const std = @import("std");
