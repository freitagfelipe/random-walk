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

App :: struct {
    draw_texture: raylib.RenderTexture2D,
    camera: raylib.Camera2D,
    monitor_width: i32,
    monitor_height: i32,
    walkers: []Walker,
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

update :: proc(app: ^App) {
    raylib.BeginTextureMode(app.draw_texture)

    for &walker in app.walkers {
        old_pos := update_walker(&walker)

        raylib.DrawLineEx(old_pos, walker.pos, 2, walker.color)
    }

    raylib.EndTextureMode()
}

handle_keyboard_input :: proc(app: ^App) {
    if raylib.IsKeyDown(raylib.KeyboardKey.W) {
        app.camera.target.y = max(
            app.camera.target.y - CAMERA_VELOCITY,
            0
        )
    }

    if raylib.IsKeyDown(raylib.KeyboardKey.A) {
        app.camera.target.x = max(
            app.camera.target.x - CAMERA_VELOCITY,
            0
        )
    }

    if raylib.IsKeyDown(raylib.KeyboardKey.S) {
        app.camera.target.y = min(
            app.camera.target.y + CAMERA_VELOCITY,
            f32(app.monitor_height - SCREEN_HEIGHT),
        )
    }

    if raylib.IsKeyDown(raylib.KeyboardKey.D) {
        app.camera.target.x = min(
            app.camera.target.x + CAMERA_VELOCITY,
            f32(app.monitor_width - SCREEN_WIDTH),
        )
    }
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
    monitor_width := raylib.GetMonitorWidth(monitor)
    monitor_height := raylib.GetMonitorHeight(monitor)

    screen_center: raylib.Vector2 = {f32(monitor_width), f32(monitor_height)} / 2

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
        hue := f32(rand.int31() % 361)

        color := raylib.ColorFromHSV(hue, 1.0, 1.0)

        walker = Walker {
            pos = default_walker.pos,
            color = color,
        }
    }

    texture := raylib.LoadRenderTexture(
        monitor_width,
        monitor_height,
    )

    app := App {
        draw_texture = texture,
        camera = camera,
        monitor_width = monitor_width,
        monitor_height = monitor_height,
        walkers = walkers,
    }

    for !raylib.WindowShouldClose() {
        handle_keyboard_input(&app)

        update(&app)
        
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

    raylib.UnloadRenderTexture(app.draw_texture)

    raylib.CloseWindow()
}
