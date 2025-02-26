package tile_game;

import "core:fmt"
import "core:math"
import "core:math/linalg"

import rl "vendor:raylib"

import ecs "ecs"

// window constants defined right here
WINDOW_WIDTH : i32 : 600
WINDOW_HEIGHT : i32 : 600

// grid constants defined right here
GRID_SIZE_X : i32 : 50
GRID_SIZE_Y : i32 : 50

// cell constants defined right here
CELL_SIZE_X : i32 : WINDOW_WIDTH / GRID_SIZE_X
CELL_SIZE_Y : i32 : WINDOW_HEIGHT / GRID_SIZE_Y

// the time between frames
delta_time: f32

// meant to be mostly the player input but can be used for other entities
Input :: struct
{
    left: rl.KeyboardKey,   
    up: rl.KeyboardKey,   
    right: rl.KeyboardKey,   
    down: rl.KeyboardKey,   
}

player:       ecs.Entity // the player entity stored globally
player_input: Input // the player input stored globally
player_speed: f32 // the player speed stored globally

// represents the position of the entity as x, y
Position :: struct
{
    data: [2]f32,
}

// represents the size of the entity as width, height
Size :: struct
{
    data: [2]i32,
}

// represents the color of the entity as rgba
Color :: struct
{
    data: [4]u8
}

// represents the type of tile that should be rendered or polled for collision testing
TileType :: enum
{
    AIR = 0,
    WALL = 1,
}

// represents the tile data for an entity thats used for a tile base
Tiles :: struct
{
    data: [GRID_SIZE_X][GRID_SIZE_Y]TileType
}

// the render system which is supposed to render the entities with render components to the screen
render_system :: proc(layer: ^ecs.Registry)
{
    fmt.println("Rendering")

    for entity, index in layer.entities
    {
        pos := ecs.get_component(layer, entity, Position)
        size := ecs.get_component(layer, entity, Size)
        color := ecs.get_component(layer, entity, Color)
        tilset := ecs.get_component(layer, entity, Tiles)

        if tilset != nil
        {
            fmt.println("has tiles")

            tiledata := tilset.data
            tile_color : rl.Color

            for x, x_index in tiledata
            {
                for y, y_index in x
                {
                    #partial switch y
                    {
                        case .AIR:
                            tile_color = {10, 10, 30, 255}
                            break
                        case .WALL:
                            tile_color = {75, 75, 75, 255}
                            break           
                    }
                    rl.DrawRectangle(i32(x_index) * CELL_SIZE_X, i32(y_index) * CELL_SIZE_Y, CELL_SIZE_X, CELL_SIZE_Y, tile_color)
                }
            }
        }
        else if pos != nil && size != nil && color != nil
        {
            rl.DrawRectangle(
                i32(pos.data[0]), 
                i32(pos.data[1]), 
                size.data[0], 
                size.data[1], 
                {color.data[0], color.data[1], color.data[2], color.data[3]})
        }
    }
}

// updates the player on the layer that its on
player_update_system :: proc(layer: ^ecs.Registry) 
{
    dir : [2]f32

    if rl.IsKeyDown(player_input.left)
    {
        dir.x = -1
    }
    if rl.IsKeyDown(player_input.right)
    {
        dir.x = 1
    }
    if rl.IsKeyDown(player_input.up)
    {
        dir.y = -1
    }
    if rl.IsKeyDown(player_input.down)
    {
        dir.y = 1
    }

    // normalize the player input direction
    dir_normal := linalg.normalize(dir)

    // get the position component and add the direction to it
    position := ecs.get_component(layer, player, Position).data
    position += dir * (player_speed * delta_time)

    // sets the position component for the player
    ecs.add_component(layer, player, Position{{position.x, position.y}})
}

main :: proc() 
{
    // inits the window 
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Tile Game Test Window")
    defer rl.CloseWindow()

    // initlaizes the ecs registery
    layer1 : ecs.Registry
    ecs.registry_init(&layer1);defer ecs.registry_destroy(&layer1)

    // assigns WASD input to the player
    player_input = {
        left  = rl.KeyboardKey.A,
        up    = rl.KeyboardKey.W,
        right = rl.KeyboardKey.D,
        down  = rl.KeyboardKey.S,
    }

    // sets the player speed to 50
    player_speed = 100

    tiles : Tiles
    for x in 0..<GRID_SIZE_X
    {
        for y in 0..<GRID_SIZE_Y
        {
            if x == 0 || y == 0 || x == GRID_SIZE_X - 1 || y == GRID_SIZE_Y - 1
            {
                tiles.data[x][y] = .WALL
            }
            else 
            {
                tiles.data[x][y] = .AIR
            }
        }
    }

    tile_layer_1 := ecs.create_entity(&layer1)
    ecs.add_component(&layer1, tile_layer_1, tiles)

    // creates the player and added some components to it
    player = ecs.create_entity(&layer1)
    ecs.add_component(&layer1, player, Position{{f32(WINDOW_WIDTH / 2), f32(WINDOW_HEIGHT / 2)}})
    ecs.add_component(&layer1, player, Size{{CELL_SIZE_X, CELL_SIZE_Y}})
    ecs.add_component(&layer1, player, Color{{255, 0, 0, 255}})

    // the main loop
    for !rl.WindowShouldClose()
    {
        // gets the current time bwteen frames
        delta_time = rl.GetFrameTime()

        // updates the player based off of the input assined to the player_input struct
        player_update_system(&layer1)

        // begins drawing and clears the background
        rl.BeginDrawing();defer rl.EndDrawing()
        rl.ClearBackground({20, 20, 30, 255})
        
        // calls the render system
        render_system(&layer1)
    }
}
