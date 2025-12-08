const rl = @import("raylib");
const constants = @import("constants");

const ui = constants.ui;

pub const MysteryShip = struct {
    image1: rl.Texture2D,
    image2: rl.Texture2D,
    position: rl.Vector2,
    speed: f32 = 0,
    is_alive: bool = false,
    id_ship: u8 = 0,

    pub fn init() !MysteryShip {
        return MysteryShip{
            .image1 = try rl.loadTexture("assets/textures/mystery_1_1.png"),
            .image2 = try rl.loadTexture("assets/textures/mystery_1_2.png"),
            .position = rl.Vector2.zero(),
        };
    }

    pub fn deinit(self: *MysteryShip) void {
        rl.unloadTexture(self.image1);
        rl.unloadTexture(self.image2);
    }

    pub fn spawn(self: *MysteryShip) void {
        self.position.y = 90;
        const side = rl.getRandomValue(0, 1);

        if (side == 0) {
            self.position.x = @divFloor(ui.offset, 2);
            self.speed = 3;
        } else {
            self.position.x = @floatFromInt(rl.getScreenWidth() - self.image1.width - @divFloor(ui.offset, 2));
            self.speed = -3;
        }

        self.is_alive = true;
    }

    pub fn update(self: *MysteryShip) void {
        if (!self.is_alive) {
            return;
        }

        self.position.x += self.speed;
        const offset = @divFloor(ui.offset, 2);

        if (self.position.x > @as(f32, @floatFromInt(rl.getScreenWidth() - self.image1.width - offset)) or self.position.x < offset) {
            self.is_alive = false;
        }

        //alterna a MysteryShip
        self.id_ship += 1;

        if (self.id_ship > 16) {
            self.id_ship = 0;
        }
    }

    pub fn draw(self: MysteryShip) void {
        if (!self.is_alive) {
            return;
        }

        if (self.id_ship < 8) {
            rl.drawTextureV(self.image1, self.position, rl.Color.white);
        } else if (self.id_ship < 16) {
            rl.drawTextureV(self.image2, self.position, rl.Color.white);
        }
    }

    pub fn getRect(self: MysteryShip) rl.Rectangle {
        return rl.Rectangle.init(
            self.position.x,
            self.position.y,
            if (self.is_alive) @floatFromInt(self.image1.width) else 0,
            if (self.is_alive) @floatFromInt(self.image1.height) else 0,
        );
    }
};
