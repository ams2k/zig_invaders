const std = @import("std");
const rl = @import("raylib");
const laser = @import("laser.zig");
const constants = @import("constants");

const ui = constants.ui;

pub const Spaceship = struct {
    image: rl.Texture2D,
    position: rl.Vector2,
    lasers: std.ArrayList(laser.Laser),
    last_fire_time: f64,
    laser_sound: rl.Sound,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Spaceship {
        const image = try rl.loadTexture("assets/textures/spaceship.png");
        const position_x = @divFloor(rl.getScreenWidth() - image.width, 2);
        const position_y = rl.getScreenHeight() - image.height - 2 * ui.offset;

        return Spaceship{
            .image = image,
            .position = rl.Vector2{ .x = @floatFromInt(position_x), .y = @floatFromInt(position_y) },
            .lasers = std.ArrayList(laser.Laser).empty, //.init(allocator),
            .last_fire_time = rl.getTime(),
            .laser_sound = try rl.loadSound("assets/audio/laser.ogg"),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Spaceship) void {
        rl.unloadTexture(self.image);
        rl.unloadSound(self.laser_sound);
        self.lasers.deinit(self.allocator);
    }

    pub fn draw(self: Spaceship) void {
        rl.drawTextureV(self.image, self.position, rl.Color.white);
    }

    pub fn moveLeft(self: *Spaceship) void {
        self.position.x -= 7;

        const constraint = @divFloor(ui.offset, 2);
        if (self.position.x < constraint) {
            self.position.x = constraint;
        }
    }

    pub fn moveRight(self: *Spaceship) void {
        self.position.x += 7;

        const right_boundary: f32 = @floatFromInt(rl.getScreenWidth() - self.image.width - @divFloor(ui.offset, 2));
        if (self.position.x > right_boundary) {
            self.position.x = right_boundary;
        }
    }

    pub fn fireLaser(self: *Spaceship) !void {
        const curr_time = rl.getTime();
        if (curr_time - self.last_fire_time < 0.35) {
            return;
        }
        self.last_fire_time = curr_time;

        const position = rl.Vector2{
            .x = self.position.x + @as(f32, @floatFromInt(@divFloor(self.image.width, 2))) - 2,
            .y = self.position.y,
        };
        try self.lasers.append(self.allocator, laser.Laser.init(position, -6, rl.Color.green));

        rl.playSound(self.laser_sound);
    }

    pub fn getRect(self: Spaceship) rl.Rectangle {
        return rl.Rectangle.init(
            self.position.x,
            self.position.y,
            @floatFromInt(self.image.width),
            @floatFromInt(self.image.height),
        );
    }
};
