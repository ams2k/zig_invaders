const std = @import("std");
const rl = @import("raylib");
const block = @import("block.zig");

pub const grid: [13][23]bool = .{
    .{ false, false, false, false, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, false, false, false, false },
    .{ false, false, false, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, false, false, false },
    .{ false, false, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, false, false },
    .{ false, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, false },
    .{ true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true },
    .{ true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true },
    .{ true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true },
    .{ true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true },
    .{ true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true },
    .{ true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true },
    .{ true, true, true, true, true, true, false, false, false, false, false, false, false, false, false, false, false, true, true, true, true, true, true },
    .{ true, true, true, true, true, false, false, false, false, false, false, false, false, false, false, false, false, false, true, true, true, true, true },
    .{ true, true, true, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, true, true, true, true },
};

pub const Obstacle = struct {
    position: rl.Vector2,
    blocks: std.ArrayList(block.Block),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, position: rl.Vector2) !Obstacle {
        var blocks = std.ArrayList(block.Block).empty; // .init(allocator);
        for (grid, 0..) |row, i| {
            for (row, 0..) |cell, j| {
                if (cell) {
                    const pos_x: f32 = position.x + @as(f32, @floatFromInt(j * 3));
                    const pos_y: f32 = position.y + @as(f32, @floatFromInt(i * 3));
                    try blocks.append(allocator, block.Block.init(rl.Vector2{ .x = pos_x, .y = pos_y }));
                }
            }
        }

        return Obstacle{
            .position = position,
            .blocks = blocks,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Obstacle) void {
        self.blocks.deinit(self.allocator);
    }

    pub fn draw(self: Obstacle) void {
        for (self.blocks.items) |bl| {
            bl.draw();
        }
    }
};
