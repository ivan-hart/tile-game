package tile_game;

import "core:fmt"
import "core:math"
import "core:math/linalg"

import rl "vendor:raylib"

WINDOW_WIDTH : i32 : 500
WINDOW_HEIGHT : i32 : 500

GRID_SIZE_X : i32 : 20
GRID_SIZE_Y : i32 : 20

CELL_SIZE_X : i32 : WINDOW_WIDTH / GRID_SIZE_X
CELL_SIZE_Y : i32 : WINDOW_HEIGHT / GRID_SIZE_Y

PlayerInput :: struct
{
    left  : rl.KeyboardKey,
    up    : rl.KeyboardKey,
    right : rl.KeyboardKey,
    down  : rl.KeyboardKey,
}

TileType :: enum
{
    EMPTY,
    WALL,
    ENEMY,
    PLAYER,
}

TileSet :: struct
{
    tiles : [GRID_SIZE_X][GRID_SIZE_Y]TileType
}

aabb :: proc() -> bool
{
    return false
}

update_player :: proc(tileset: ^ TileSet, player_input: PlayerInput) -> bool
{
    should_tick := false

    dir := [2]i32 { 0, 0 }

    if rl.IsKeyDown(player_input.up)
    {
        dir.y = -1
        should_tick = true
    }
    else if rl.IsKeyDown(player_input.down)
    {
        dir.y = 1
        should_tick = true
    }
    else if rl.IsKeyDown(player_input.left)
    {
        dir.x = -1
        should_tick = true
    }
    else if rl.IsKeyDown(player_input.right)
    {
        dir.x = 1
        should_tick = true
    }

    player_pos : [2]i32 = {-1, -1}

    for x in 0..<len(tileset.tiles)
    {
        for y in 0..<len(tileset.tiles)
        {
            if tileset.tiles[x][y] == .PLAYER
            {
                player_pos = {i32(x), i32(y)}
            }
        }
    }

    if player_pos.x < 0 && player_pos.y < 0 && should_tick
    {
        fmt.println("No player found")
    }

    future_pos : [2]i32 = { player_pos.x + dir.x, player_pos.y + dir.y }

    if future_pos.x >= 0 && future_pos.y >= 0
    {
        tile := tileset.tiles[future_pos.x][future_pos.y]

        if tile != .WALL
        {
            tileset.tiles[player_pos.x][player_pos.y] = .EMPTY
            tileset.tiles[future_pos.x][future_pos.y] = .PLAYER

            fmt.println(future_pos)
        }
    }

    return should_tick
}

render_tile_set :: proc(tileset: TileSet)
{
    for column, x in tileset.tiles
    {
        for tile, y in column
        {
            color: rl.Color

            #partial switch tile
            {
                case .EMPTY:
                    color = rl.Color {20, 20, 20, 255}
                    break
                case .WALL:
                    color = rl.Color {50, 50, 50, 255}
                    break
                case .PLAYER:
                    color = rl.Color {100, 100, 255, 255}
                    break
                case .ENEMY:
                    color = rl.Color {255, 100, 100, 255}
            }

            pos_x := i32(x) * CELL_SIZE_X
            pos_y := i32(y) * CELL_SIZE_Y

            rl.DrawRectangle(pos_x, pos_y, CELL_SIZE_X, CELL_SIZE_Y, color)
        }
    }
}

main :: proc()
{
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Tile Game Test Window");
    defer rl.CloseWindow();

    rl.SetTargetFPS(30)

    tileset : TileSet

    for x in 0..<GRID_SIZE_X
    {
        for y in 0..<GRID_SIZE_Y
        {
            if x == 0 || y == 0 || x == GRID_SIZE_X - 1 || y == GRID_SIZE_Y - 1
            {
                tileset.tiles[x][y] = .WALL
            }
            else if x == GRID_SIZE_X / 2 && y == GRID_SIZE_Y / 2 {
                tileset.tiles[x][y] = .PLAYER
            }
            else
            {
                tileset.tiles[x][y] = .EMPTY
            }
        }
    }

    player_input : PlayerInput = {
        left = rl.KeyboardKey.A,
        up = rl.KeyboardKey.W,
        right = rl.KeyboardKey.D,
        down = rl.KeyboardKey.S,
    }

    time : f32

    for !rl.WindowShouldClose()
    {
        dt := rl.GetFrameTime()
        should_tick := false

        time += dt

        if time > 0.2
        {
            should_tick = update_player(&tileset, player_input)

            if should_tick
            {
                time = 0.0
            }
        }

        rl.BeginDrawing()
        defer rl.EndDrawing()
        rl.ClearBackground({0, 0, 0, 255})

        render_tile_set(tileset)
    }
}
