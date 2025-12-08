const rl = @import("raylib");

pub const AlienType = enum {
    Type1_1,
    Type2_1,
    Type3_1,
    Type4_1,
    Type5_1,
    Type1_2,
    Type2_2,
    Type3_2,
    Type4_2,
    Type5_2,
};

pub var alien_images = [10]?rl.Texture2D{ null, null, null, null, null, null, null, null, null, null };

pub const Alien = struct {
    alien_type: AlienType,
    position: rl.Vector2,
    id_alien: usize = 0,
    id_alien_change: u32 = 0,

    pub fn init(alien_type: AlienType, position: rl.Vector2) !Alien {
        const id: usize = @intFromEnum(alien_type);

        if (alien_images[id] == null) {
            switch (alien_type) {
                .Type1_1 => {
                    alien_images[id] = try rl.loadTexture("assets/textures/alien_1_1.png");
                    alien_images[id + 5] = try rl.loadTexture("assets/textures/alien_1_2.png");
                },
                .Type2_1 => {
                    alien_images[id] = try rl.loadTexture("assets/textures/alien_2_1.png");
                    alien_images[id + 5] = try rl.loadTexture("assets/textures/alien_2_2.png");
                },
                .Type3_1 => {
                    alien_images[id] = try rl.loadTexture("assets/textures/alien_3_1.png");
                    alien_images[id + 5] = try rl.loadTexture("assets/textures/alien_3_2.png");
                },
                .Type4_1 => {
                    alien_images[id] = try rl.loadTexture("assets/textures/alien_4_1.png");
                    alien_images[id + 5] = try rl.loadTexture("assets/textures/alien_4_2.png");
                },
                .Type5_1 => {
                    alien_images[id] = try rl.loadTexture("assets/textures/alien_5_1.png");
                    alien_images[id + 5] = try rl.loadTexture("assets/textures/alien_5_2.png");
                },
                else => {},
            }
        }

        return Alien{
            .alien_type = alien_type,
            .position = position,
            .id_alien = 0,
            .id_alien_change = 0,
        };
    }

    pub fn deinit(_: *Alien) void {
        unloadIamges();
    }

    pub fn draw(self: Alien) void {
        const id: usize = @intFromEnum(self.alien_type) + self.id_alien;

        rl.drawTextureV(alien_images[id].?, self.position, rl.Color.white);
    }

    pub fn update(self: *Alien, direction: f32, is_running: bool) void {
        self.position.x += direction;

        if (is_running) {
            //animando o alien
            self.id_alien_change += 1;

            if (self.id_alien_change >= 80) {
                self.id_alien_change = 0;
            }

            if (self.id_alien_change < 40) {
                self.id_alien = 0;
            } else if (self.id_alien_change < 80) {
                self.id_alien = 5;
            }
        }
    }

    pub fn unloadIamges() void {
        for (&alien_images) |*image| {
            if (image.* != null) {
                rl.unloadTexture(image.*.?);
            }
        }
    }

    pub fn getRect(self: Alien) rl.Rectangle {
        const id: usize = @intFromEnum(self.alien_type);
        const image = alien_images[id];

        return rl.Rectangle.init(
            self.position.x,
            self.position.y,
            if (image != null) @floatFromInt(image.?.width) else 0,
            if (image != null) @floatFromInt(image.?.height) else 0,
        );
    }
};
