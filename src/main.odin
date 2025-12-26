package main

import "core:math/rand"
import "core:strconv"
import "core:os"
import "core:fmt"
import "vendor:raylib"

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 600
CAMERA_VELOCITY :: 8
STEP :: 10

Walker :: struct {
    pos: raylib.Vector2,
    color: raylib.Color,
}

update_walker :: proc(walker: ^Walker) -> raylib.Vector2 {
    direction: raylib.Vector2 = {}

    switch n := rand.uint32() % 4; n {
    case 0: direction = {1, 0}
    case 1: direction = {-1, 0}
    case 2: direction = {0, 1}
    case 3: direction = {0, -1}
    case:
        fmt.eprintln("Impossible direction %i.", direction)

        os.exit(-1)
    }

    old_pos := walker.pos
    walker.pos += direction * STEP

    return old_pos
}

draw_walker_movement :: proc(new_pos, old_pos: raylib.Vector2, color: raylib.Color) {
    raylib.DrawLineEx(old_pos, new_pos, 2, color)
}

update :: proc(texture: raylib.RenderTexture2D, walkers: []Walker) {
    raylib.BeginTextureMode(texture)

    for &walker in walkers {
        old_pos := update_walker(&walker)

        draw_walker_movement(walker.pos, old_pos, walker.color)
    }

    raylib.EndTextureMode()
}

main :: proc() {
    if len(os.args) != 2 {
        fmt.eprintln("You should provide exactly one integer argument that is the number of walkers.")

        os.exit(-1)
    }

    number_of_walkers, ok := strconv.parse_u64(os.args[1])

    if !ok {
        fmt.eprintln("The argument needs to be an integer.")

        os.exit(-1)
    }

    raylib.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Random walk")

    raylib.SetTargetFPS(60)

    monitor := raylib.GetCurrentMonitor()
    max_monitor_width := raylib.GetMonitorWidth(monitor)
    max_monitor_height := raylib.GetMonitorHeight(monitor)

    screen_center: raylib.Vector2 = {f32(max_monitor_width), f32(max_monitor_height)} / 2

    camera := raylib.Camera2D {
        target = screen_center - {SCREEN_WIDTH, SCREEN_HEIGHT} / 2,
        zoom = 1,
    }

    default_walker := Walker {
        pos = screen_center,
    }

    walkers := make([]Walker, number_of_walkers)
    defer delete(walkers)

    for &walker in walkers {
        saturation, value: f32 = 1.0, 1.0
        hue := rand.float32() * 361

        color := raylib.ColorFromHSV(hue, saturation, value)

        walker = Walker {
            pos = default_walker.pos,
            color = color,
        }
    }

    texture := raylib.LoadRenderTexture(
        max_monitor_width,
        max_monitor_height,
    )

    for !raylib.WindowShouldClose() {
        update(texture, walkers)

        if raylib.IsKeyDown(raylib.KeyboardKey.W) {
            camera.target.y = max(camera.target.y - CAMERA_VELOCITY, 0);
        }

        if raylib.IsKeyDown(raylib.KeyboardKey.A) {
            camera.target.x = max(camera.target.x - CAMERA_VELOCITY, 0);
        }

        if raylib.IsKeyDown(raylib.KeyboardKey.S) {
            camera.target.y = min(
                camera.target.y + CAMERA_VELOCITY,
                f32(max_monitor_height - SCREEN_HEIGHT),
            )
        }

        if raylib.IsKeyDown(raylib.KeyboardKey.D) {
            camera.target.x = min(
                camera.target.x + CAMERA_VELOCITY,
                f32(max_monitor_width - SCREEN_WIDTH),
            )
        }
        
        raylib.BeginDrawing()

        raylib.BeginMode2D(camera)

        raylib.ClearBackground(raylib.BLACK)

        raylib.DrawTexture(
            texture.texture,
            0,
            0,
            raylib.WHITE,
        )

        raylib.EndMode2D()

        raylib.EndDrawing()
    }

    raylib.CloseWindow()
}
