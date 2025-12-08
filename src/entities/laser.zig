const rl = @import("raylib");
const colors = @import("constants").colors;
const constants = @import("constants");

const ui = constants.ui;

pub const Laser = struct {
    position: rl.Vector2,
    speed: i32,
    is_active: bool = true,
    color: rl.Color,

    pub fn init(position: rl.Vector2, speed: i32, color: rl.Color) Laser {
        return Laser{
            .position = position,
            .speed = speed,
            .color = color,
        };
    }

    pub fn draw(self: Laser) void {
        if (!self.is_active) {
            return;
        }

        rl.drawRectangle(
            @intFromFloat(self.position.x),
            @intFromFloat(self.position.y),
            4,
            15,
            self.color,
        );
    }

    pub fn update(self: *Laser) void {
        if (!self.is_active) {
            return;
        }

        self.position.y += @floatFromInt(self.speed);
        if (self.position.y < @divFloor(ui.offset, 2) or self.position.y > @as(f32, @floatFromInt(rl.getScreenHeight() - 2 * ui.offset))) {
            self.is_active = false;
        }
    }

    pub fn getRect(self: Laser) rl.Rectangle {
        return rl.Rectangle.init(self.position.x, self.position.y, 8, 15);
    }
};
