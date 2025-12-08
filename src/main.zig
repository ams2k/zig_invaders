const std = @import("std");
const rl = @import("raylib");
const constants = @import("constants");
const entities = @import("entities");

const colors = constants.colors;
const ui = constants.ui;

pub fn main() !void {
    var exit_game: bool = false;

    rl.initWindow(750 + ui.offset, 700 + 2 * ui.offset, "Zpace invaders");
    defer rl.closeWindow();

    rl.initAudioDevice();
    defer rl.closeAudioDevice();

    const font = try rl.loadFontEx("assets/fonts/monogram.ttf", 64, null);
    defer rl.unloadFont(font);

    const font_digital = try rl.loadFontEx("assets/fonts/digital.ttf", 64, null);
    defer rl.unloadFont(font_digital);

    rl.setTargetFPS(60);
    rl.setExitKey(rl.KeyboardKey.null);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var game = try entities.Game.init(allocator);
    defer game.deinit();

    rl.playMusicStream(game.music);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.updateMusicStream(game.music);

        try game.handleInput(exit_game);

        rl.clearBackground(colors.grey);
        rl.drawRectangleRoundedLinesEx(rl.Rectangle.init(10, 10, 780, 780), 0.18, 20, 2, colors.yellow);
        rl.drawLineEx(rl.Vector2.init(25, 730), rl.Vector2.init(775, 730), 3, colors.yellow);

        if (game.is_running) {
            rl.drawTextEx(font, "LEVEL 01", rl.Vector2.init(570, 740), 34, 2, colors.yellow);
        } else {
            rl.drawTextEx(font, "<ENTER> to new game, <ESC> to exit", rl.Vector2.init(100, 745), 24, 2, colors.white);

            if (game.lives > 0) {
                rl.drawTextEx(font, "YOU WIN!", rl.Vector2.init(570, 740), 34, 2, colors.green);
            } else {
                rl.drawTextEx(font_digital, "GAME OVER", rl.Vector2.init(570, 740), 34, 2, colors.red);
            }
        }

        var life_icon_offset: f32 = 50;
        for (0..game.lives) |_| {
            rl.drawTextureV(game.spaceship.image, rl.Vector2.init(life_icon_offset, 745), rl.Color.white);
            life_icon_offset += 50;
        }

        rl.drawTextEx(font, "SCORE", rl.Vector2.init(50, 15), 34, 2, colors.yellow);
        const score = try formatScoreWithLeadingZeros(allocator, game.score, 5);
        defer allocator.free(score);
        rl.drawTextEx(font, score, rl.Vector2.init(50, 40), 34, 2, colors.yellow);

        rl.drawTextEx(font, "F3 = EXIT", rl.Vector2.init(260, 15), 34, 2, colors.green);

        rl.drawTextEx(font, "HIGH-SCORE", rl.Vector2.init(570, 15), 34, 2, colors.yellow);
        const high_score = try formatScoreWithLeadingZeros(allocator, game.high_score, 5);
        defer allocator.free(high_score);
        rl.drawTextEx(font, high_score, rl.Vector2.init(650, 40), 34, 2, colors.yellow);

        game.draw();

        if (rl.isKeyDown(rl.KeyboardKey.f3)) {
            //pressionou a tecla F3
            exit_game = true;
        }

        if (!exit_game) {
            try game.update();
        } else {
            //pressionou F3 para sair
            const x = 200;
            const y = 200;
            const width = 410;
            const height = 200;

            rl.drawRectangle(
                x,
                y,
                width,
                height,
                rl.Color.gray,
            );

            rl.drawRectangleLinesEx(
                .{
                    .x = @floatFromInt(x + 2),
                    .y = @floatFromInt(y + 2),
                    .width = @floatFromInt(width - 3),
                    .height = @floatFromInt(height - 3),
                },
                1,
                rl.Color.red,
            );

            rl.drawText("SAIR DO JOGO", x + 70, y + 20, 40, rl.Color.red);
            rl.drawText("ENTER para jogar ou ESC para sair", x + 20, y + 160, 20, rl.Color.green);

            if (rl.isKeyPressed(rl.KeyboardKey.escape)) {
                break;
            } else if (rl.isKeyPressed(rl.KeyboardKey.enter)) {
                exit_game = false;
            }
            continue; //vai para inicio do loop principal
        } //if exit_game
    } //while
} // main

fn formatScoreWithLeadingZeros(allocator: std.mem.Allocator, number: i32, width: usize) ![:0]u8 {
    const score = rl.textFormat("%d", .{number});

    //const leading_zeros = width - std.mem.len(score);
    const leading_zeros = width - score.len;

    const zero_text = try allocator.alloc(u8, width);
    defer allocator.free(zero_text);

    @memset(zero_text, '0');
    std.mem.copyForwards(u8, zero_text[leading_zeros..], score);

    const final_text = try allocator.dupeZ(u8, zero_text);
    return final_text;
}
