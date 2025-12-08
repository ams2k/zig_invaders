const std = @import("std");
const rl = @import("raylib");
const obstacle = @import("obstacle.zig");
const alien = @import("alien.zig");
const Spaceship = @import("spaceship.zig").Spaceship;
const Laser = @import("laser.zig").Laser;
const MysteryShip = @import("mystery_ship.zig").MysteryShip;
const constants = @import("constants");

const ui = constants.ui;

pub const Game = struct {
    spaceship: Spaceship,
    aliens: std.ArrayList(alien.Alien),
    alien_lasers: std.ArrayList(Laser),
    obstacles: [4]obstacle.Obstacle,
    mystery_ship: MysteryShip,
    time_last_alien_fired: f64,
    aliens_direction: f32 = 1,
    alien_laser_interval: f64 = 0.35,
    mystery_ship_spawn_interval: f64,
    time_last_spawn: f64,
    lives: usize = 3,
    is_running: bool = true,
    score: i32 = 0,
    high_score: i32,
    allocator: std.mem.Allocator,
    music: rl.Music,
    explosion_sound: rl.Sound,

    pub fn init(allocator: std.mem.Allocator) !Game {
        const curr_time = rl.getTime();

        return Game{
            .spaceship = try Spaceship.init(allocator),
            .obstacles = try createObstacles(allocator),
            .aliens = try createAliens(allocator),
            .alien_lasers = std.ArrayList(Laser).empty, // .init(allocator),
            .time_last_alien_fired = curr_time,
            .mystery_ship = try MysteryShip.init(),
            .time_last_spawn = curr_time,
            .mystery_ship_spawn_interval = @floatFromInt(rl.getRandomValue(10, 20)),
            .allocator = allocator,
            .high_score = loadHighScoreFromFile(allocator) catch 0,
            .music = try rl.loadMusicStream("assets/audio/music.ogg"),
            .explosion_sound = try rl.loadSound("assets/audio/explosion.ogg"),
        };
    }

    pub fn deinit(self: *Game) void {
        alien.Alien.unloadIamges();
        rl.unloadMusicStream(self.music);
        rl.unloadSound(self.explosion_sound);
        self.deinitNonMedia();
    }

    pub fn deinitNonMedia(self: *Game) void {
        self.spaceship.deinit();
        self.mystery_ship.deinit();

        self.aliens.deinit(self.allocator);
        self.alien_lasers.deinit(self.allocator);

        for (&self.obstacles) |*o| {
            o.deinit();
        }
    }

    pub fn draw(self: Game) void {
        self.spaceship.draw();

        for (self.spaceship.lasers.items) |laser| {
            laser.draw();
        }

        for (self.alien_lasers.items) |laser| {
            laser.draw();
        }

        for (self.obstacles) |o| {
            o.draw();
        }

        for (self.aliens.items) |a| {
            a.draw();
        }

        self.mystery_ship.draw();
    }

    pub fn update(self: *Game) !void {
        if (!self.is_running) {
            if (rl.isKeyPressed(rl.KeyboardKey.enter)) {
                try self.reset();
            }
            return;
        }

        const curr_time = rl.getTime();
        if (curr_time - self.time_last_spawn > self.mystery_ship_spawn_interval) {
            self.mystery_ship.spawn();
            self.time_last_spawn = curr_time;
            self.mystery_ship_spawn_interval = @floatFromInt(rl.getRandomValue(10, 20));
        }

        for (self.spaceship.lasers.items) |*laser| {
            laser.update();
        }

        self.moveAliens();

        try self.alienShootLaser();
        for (self.alien_lasers.items) |*laser| {
            laser.update();
        }
        self.mystery_ship.update();

        try self.checkForCollisions();
        self.deleteInactiveLasers();
    }

    pub fn handleInput(self: *Game, exit_game: bool) !void {
        if (!self.is_running or exit_game) {
            return;
        }

        if (rl.isKeyDown(rl.KeyboardKey.d) or rl.isKeyDown(rl.KeyboardKey.right)) {
            self.spaceship.moveRight();
        } else if (rl.isKeyDown(rl.KeyboardKey.a) or rl.isKeyDown(rl.KeyboardKey.left)) {
            self.spaceship.moveLeft();
        }

        if (rl.isKeyDown(rl.KeyboardKey.space)) {
            try self.spaceship.fireLaser();
        }
    }

    pub fn moveAliens(self: *Game) void {
        for (self.aliens.items) |*a| {
            const id: usize = @intFromEnum(a.alien_type);
            const constraint_offset = @divFloor(ui.offset, 2);

            if (alien.alien_images[id] != null and @as(c_int, @intFromFloat(a.position.x)) + alien.alien_images[id].?.width > rl.getScreenWidth() - constraint_offset) {
                self.aliens_direction = -1;
                self.moveDownAliens(4);
            } else if (a.position.x < constraint_offset) {
                self.aliens_direction = 1;
                self.moveDownAliens(4);
            }

            a.update(self.aliens_direction, self.is_running);
        }
    }

    fn moveDownAliens(self: *Game, distance: f32) void {
        for (self.aliens.items) |*a| {
            a.position.y += distance;
        }
    }

    fn alienShootLaser(self: *Game) !void {
        const curr_time = rl.getTime();
        if (curr_time - self.time_last_alien_fired < self.alien_laser_interval or self.aliens.items.len == 0) {
            return;
        }
        self.time_last_alien_fired = curr_time;

        const index: usize = @intCast(rl.getRandomValue(0, @intCast(self.aliens.items.len - 1)));
        const al = self.aliens.items[index];
        const id: usize = @intFromEnum(al.alien_type);
        const image = alien.alien_images[id];
        if (image == null) {
            return;
        }

        const position = rl.Vector2{
            .x = al.position.x + @as(f32, @floatFromInt(image.?.width)) / 2,
            .y = al.position.y + @as(f32, @floatFromInt(image.?.height)),
        };
        const laser = Laser.init(position, 6, rl.Color.red);

        try self.alien_lasers.append(self.allocator, laser);
    }

    fn deleteInactiveLasers(self: *Game) void {
        var i: usize = 0;
        while (i < self.spaceship.lasers.items.len) {
            if (!self.spaceship.lasers.items[i].is_active) {
                _ = self.spaceship.lasers.swapRemove(i);
            } else {
                i += 1;
            }
        }

        i = 0;
        while (i < self.alien_lasers.items.len) {
            if (!self.alien_lasers.items[i].is_active) {
                _ = self.alien_lasers.swapRemove(i);
            } else {
                i += 1;
            }
        }
    }

    fn createObstacles(allocator: std.mem.Allocator) ![4]obstacle.Obstacle {
        const obstacle_width = obstacle.grid[0].len * 3;
        const gap = (@as(f32, @floatFromInt(rl.getScreenWidth())) - @as(f32, @floatFromInt(4 * obstacle_width))) / 5;

        var obstacles: [4]obstacle.Obstacle = [_]obstacle.Obstacle{undefined} ** 4;
        for (0..4) |i| {
            const offset_x = @as(f32, @floatFromInt(i + 1)) * gap + @as(f32, @floatFromInt(i * obstacle_width));
            obstacles[i] = try obstacle.Obstacle.init(
                allocator,
                rl.Vector2{ .x = offset_x, .y = @floatFromInt(rl.getScreenHeight() - 100 - 2 * ui.offset) },
            );
        }

        return obstacles;
    }

    fn createAliens(allocator: std.mem.Allocator) !std.ArrayList(alien.Alien) {
        var aliens = std.ArrayList(alien.Alien).empty; // .init(allocator);

        for (0..5) |row| {
            for (0..11) |column| {
                const x: f32 = @floatFromInt(column * 55 + 75);
                const y: f32 = @floatFromInt(row * 55 + 110);
                const alien_type: alien.AlienType = switch (row) {
                    0 => .Type5_1,
                    1 => .Type4_1,
                    2 => .Type3_1,
                    3 => .Type2_1,
                    else => .Type1_1,
                };
                try aliens.append(allocator, try alien.Alien.init(alien_type, rl.Vector2{ .x = x, .y = y }));
            }
        }

        return aliens;
    }

    fn checkForCollisions(self: *Game) !void {
        // Spaceship lasers
        outer: for (self.spaceship.lasers.items) |*laser| {
            const laser_rect = laser.getRect();

            var i: usize = 0;
            while (i < self.aliens.items.len) {
                if (rl.checkCollisionRecs(laser_rect, self.aliens.items[i].getRect())) {
                    const hit_alien = self.aliens.swapRemove(i);

                    self.score += switch (hit_alien.alien_type) {
                        .Type1_1 => 100,
                        .Type2_1 => 200,
                        .Type3_1 => 300,
                        .Type4_1 => 350,
                        .Type5_1 => 380,
                        else => 0,
                    };
                    try self.checkForHighScore();

                    laser.is_active = false;
                    rl.playSound(self.explosion_sound);
                    break :outer;
                } else {
                    i += 1;
                }
            }

            for (&self.obstacles) |*o| {
                var j: usize = 0;
                while (j < o.blocks.items.len) {
                    if (rl.checkCollisionRecs(laser_rect, o.blocks.items[j].getRect())) {
                        _ = o.blocks.swapRemove(j);
                        laser.is_active = false;
                    } else {
                        j += 1;
                    }
                }
            }

            if (rl.checkCollisionRecs(laser_rect, self.mystery_ship.getRect())) {
                self.mystery_ship.is_alive = false;
                laser.is_active = false;
                self.score += 500;
                try self.checkForHighScore();
                rl.playSound(self.explosion_sound);
                break;
            }
        }

        // Alien lasers
        const spaceship_rect = self.spaceship.getRect();
        for (self.alien_lasers.items) |*laser| {
            const laser_rect = laser.getRect();

            if (rl.checkCollisionRecs(laser_rect, spaceship_rect)) {
                laser.is_active = false;
                self.lives -= 1;
                if (self.lives == 0) {
                    self.endGame();
                }
                break;
            }

            for (&self.obstacles) |*o| {
                var j: usize = 0;
                while (j < o.blocks.items.len) {
                    if (rl.checkCollisionRecs(laser_rect, o.blocks.items[j].getRect())) {
                        _ = o.blocks.swapRemove(j);
                        laser.is_active = false;
                    } else {
                        j += 1;
                    }
                }
            }
        }

        // Alien collision with an obstacle
        for (self.aliens.items) |a| {
            const alien_rect = a.getRect();

            for (&self.obstacles) |*o| {
                var i: usize = 0;
                while (i < o.blocks.items.len) {
                    if (rl.checkCollisionRecs(alien_rect, o.blocks.items[i].getRect())) {
                        _ = o.blocks.swapRemove(i);
                    } else {
                        i += 1;
                    }
                }
            }

            if (rl.checkCollisionRecs(alien_rect, spaceship_rect)) {
                self.endGame();
            }
        }
    }

    fn checkForHighScore(self: *Game) !void {
        if (self.score > self.high_score) {
            self.high_score = self.score;
            try self.saveHighScoreToFile();
        }
    }

    fn endGame(self: *Game) void {
        self.is_running = false;
    }

    fn reset(self: *Game) !void {
        self.deinitNonMedia();
        try self.reinit();
    }

    fn reinit(self: *Game) !void {
        const curr_time = rl.getTime();

        self.spaceship = try Spaceship.init(self.allocator);
        self.aliens = try createAliens(self.allocator);
        self.alien_lasers = std.ArrayList(Laser).empty; // .init(self.allocator);
        self.obstacles = try createObstacles(self.allocator);
        self.mystery_ship = try MysteryShip.init();
        self.time_last_alien_fired = curr_time;
        self.aliens_direction = 1;
        self.alien_laser_interval = 0.35;
        self.mystery_ship_spawn_interval = @floatFromInt(rl.getRandomValue(10, 20));
        self.time_last_spawn = curr_time;
        self.lives = 3;
        self.is_running = true;
        self.score = 0;
    }

    fn saveHighScoreToFile(self: Game) !void {
        const file = try std.fs.cwd().createFile("highscore.txt", .{});
        defer file.close();

        //try file.writer().print("{d}", .{self.high_score});

        var buf: [64]u8 = undefined;
        const texto = try std.fmt.bufPrint(&buf, "{}", .{self.high_score});
        // texto = []u8 contendo "1234"
        try file.writeAll(texto);
    }

    fn loadHighScoreFromFile(allocator: std.mem.Allocator) !i32 {
        const file = std.fs.cwd().openFile("highscore.txt", .{}) catch |err| {
            std.log.err("Failed to open file: {s}", .{@errorName(err)});
            return 0;
        };
        defer file.close();

        const read_bytes = file.readToEndAlloc(allocator, 16) catch |err| {
            std.log.err("Failed to read file: {s}", .{@errorName(err)});
            return 0;
        };
        defer allocator.free(read_bytes);

        return try std.fmt.parseInt(i32, read_bytes, 10);
    }
};
