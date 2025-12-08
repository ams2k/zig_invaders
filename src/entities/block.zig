const rl = @import("raylib");
const colors = @import("constants").colors;

pub const Block = struct {
    position: rl.Vector2,

    pub fn init(position: rl.Vector2) Block {
        return Block{
            .position = position,
        };
    }

    pub fn draw(self: Block) void {
        rl.drawRectangle(
            @intFromFloat(self.position.x),
            @intFromFloat(self.position.y),
            3,
            3,
            rl.Color.purple,
        );
    }

    pub fn getRect(self: Block) rl.Rectangle {
        return rl.Rectangle.init(self.position.x, self.position.y, 3, 3);
    }
};
