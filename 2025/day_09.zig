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

test part2 {
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
    const answer = 24;
    try testing.expectEqual(answer, try part2(example));
}

var horizontal_edge_buffer: [max_tiles]Edge = undefined;
var vertical_edge_buffer: [max_tiles]Edge = undefined;

// The constraints of the problem describe a rectilinear polygon,
// where each red tile is a vertex, and we have to find the greatest-area
// rectangle of any two vertices that is contained by the polygon.
//
// Make the same O(n^2) iteration as before, but each candidate rectangle
// needs to be checked for intersections with the polygon bounds,
// which can be sorted and binary searched.
//
// Unoptimal.
pub fn part2(input: []const u8) !u64 {
    var tiles_list = emptyListFromBuffer(&tiles_buffer);
    var horizontal_edge_list = emptyListFromBuffer(&horizontal_edge_buffer);
    var vertical_edge_list = emptyListFromBuffer(&vertical_edge_buffer);

    var line_iter = mem.splitScalar(u8, input, '\n');

    const first_tile: RedTile = first_line: {
        const line = line_iter.first();
        const lhs, const rhs = mem.cutScalar(u8, line, ',') orelse return raiseParseError(line);
        const tile: RedTile = .{
            fmt.parseUnsigned(u32, lhs, 10) catch return raiseParseError(line),
            fmt.parseUnsigned(u32, rhs, 10) catch return raiseParseError(line),
        };
        try tiles_list.appendBounded(tile);
        break :first_line tile;
    };

    while (line_iter.next()) |line| {
        if (line.len == 0) continue;
        const lhs, const rhs = mem.cutScalar(u8, line, ',') orelse return raiseParseError(line);
        const tile: RedTile = .{
            fmt.parseUnsigned(u32, lhs, 10) catch return raiseParseError(line),
            fmt.parseUnsigned(u32, rhs, 10) catch return raiseParseError(line),
        };
        const last_tile: RedTile = tiles_list.items[tiles_list.items.len-1];
        try tiles_list.appendBounded(tile);
        try appendEdge(&horizontal_edge_list, &vertical_edge_list, last_tile, tile);
    }

    try appendEdge(
        &horizontal_edge_list,
        &vertical_edge_list,
        tiles_list.items[tiles_list.items.len-1],
        first_tile,
    );

    const tiles: []const RedTile = tiles_list.items;

    std.mem.sort(Edge, horizontal_edge_list.items, {}, Edge.lessThan);
    std.mem.sort(Edge, vertical_edge_list.items, {}, Edge.lessThan);

    var max_area: u64 = 0;
    for (tiles, 0..) |tile_a, i| { for (tiles, 0..) |tile_b, j| { if (i!=j) {
        const rect: Rectangle = .{ tile_a, tile_b };
        const rect_lower_y: u32 = @min(@as(u32, @intCast(rect[0][1])), @as(u32, @intCast(rect[1][1])));
        const rect_upper_y: u32 = @max(@as(u32, @intCast(rect[0][1])), @as(u32, @intCast(rect[1][1])));
        const rect_lower_x: u32 = @min(@as(u32, @intCast(rect[0][0])), @as(u32, @intCast(rect[1][0])));
        const rect_upper_x: u32 = @max(@as(u32, @intCast(rect[0][0])), @as(u32, @intCast(rect[1][0])));
        const within: bool = check_edges: {
            for (allEdgesWithinAxes(horizontal_edge_list.items, rect_lower_y+1, rect_upper_y-1)) |edge| {
                if (edge.intersects(.horizontal, rect, true)) break :check_edges false;
            }
            for (allEdgesWithinAxes(vertical_edge_list.items, rect_lower_x+1, rect_upper_x-1)) |edge| {
                if (edge.intersects(.vertical, rect, true)) break :check_edges false;
            }
            break :check_edges true;
        };
        // The area, or 0 if there was an intersection
        max_area = @max(max_area, @intFromBool(within) * area(rect));
    }}}

    return max_area;
}

const Edge = struct {
    const Axis = enum { horizontal, vertical };

    axis: u32,
    lower: u32,
    upper: u32,

    pub fn lessThan(_: void, lhs: Edge, rhs: Edge) bool {
        return lhs.axis < rhs.axis;
    }

    pub fn eql(lhs: Edge, rhs: Edge) bool {
        return lhs.axis == rhs.axis;
    }

    pub inline fn intersects(edge: Edge, axis: Axis, rect: Rectangle, assume_axis_in_rect: bool) bool {
        const rect_lower_y: u32 = @min(@as(u32, @intCast(rect[0][1])), @as(u32, @intCast(rect[1][1])));
        const rect_upper_y: u32 = @max(@as(u32, @intCast(rect[0][1])), @as(u32, @intCast(rect[1][1])));
        const rect_lower_x: u32 = @min(@as(u32, @intCast(rect[0][0])), @as(u32, @intCast(rect[1][0])));
        const rect_upper_x: u32 = @max(@as(u32, @intCast(rect[0][0])), @as(u32, @intCast(rect[1][0])));
        return switch (axis) {
            .horizontal =>
                ( assume_axis_in_rect or edge.axis > rect_lower_y or edge.axis < rect_upper_y ) and
                ( edge.lower < rect_upper_x and edge.upper > rect_lower_x ),
            .vertical =>
                ( assume_axis_in_rect or edge.axis > rect_lower_x or edge.axis < rect_upper_x ) and
                ( edge.lower < rect_upper_y and edge.upper > rect_lower_y ),
        };
    }
};

fn area(rect: Rectangle) u64 {
    const diff = @abs( rect[1] - rect[0] ) + @Vector(2, u64){ 1, 1 };
    const a = @reduce(.Mul, diff);
    return a;
}

fn appendEdge(
    horizontal_edge_list: *std.ArrayList(Edge),
    vertical_edge_list: *std.ArrayList(Edge),
    tile_a: RedTile,
    tile_b: RedTile,
) !void {
    if (tile_a[0] == tile_b[0]) {
        assert(tile_a[1] != tile_b[1]);
        // Same x, different y -> vertical edge
        try vertical_edge_list.appendBounded(.{
            .axis = @intCast(tile_a[0]),
            .lower = @min(@as(u32, @intCast(tile_a[1])), @as(u32, @intCast(tile_b[1]))),
            .upper = @max(@as(u32, @intCast(tile_a[1])), @as(u32, @intCast(tile_b[1]))),
        });
    } else if (tile_a[1] == tile_b[1]) {
        assert(tile_a[0] != tile_b[0]);
        // Same y, different x -> horizontal edge
        try horizontal_edge_list.appendBounded(.{
            .axis = @intCast(tile_a[1]),
            .lower = @min(@as(u32, @intCast(tile_a[0])), @as(u32, @intCast(tile_b[0]))),
            .upper = @max(@as(u32, @intCast(tile_a[0])), @as(u32, @intCast(tile_b[0]))),
        });
    } else {
        // The input specification guarantees either a horizontal or vertical edge
        unreachable;
    }
}

/// Linear search a sorted edge list for all edges which fall within the range
fn allEdgesWithinAxes(edges: []const Edge, min_axis: u32, max_axis: u32) []const Edge {
    if (max_axis < min_axis) {
        return &.{};
    } else {
        const start = for (edges, 0..) |edge, i| {
            if (edge.axis >= min_axis) break i;
        } else return &.{};
        if (max_axis == min_axis) {
            const stop = for (edges[start+1..], 1..) |edge, i| {
                if (edge.axis != min_axis) break start+i;
            } else edges.len;
            return edges[start..stop];
        } else {
            var iter = mem.reverseIterator(edges);
            const stop = while (iter.next()) |edge| {
                if (edge.axis <= max_axis) break iter.index+1;
            } else unreachable;
            return edges[start..stop];
        }
    }
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
