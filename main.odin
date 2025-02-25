package tile_game;

import "core:fmt"
import "core:math"
import "core:math/linalg"

import rl "vendor:raylib"

import ecs "ecs"

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

// the render system which is supposed to render the entities with render components to the screen
render_system :: proc(layer: ^ecs.Registry)
{
    for entity, index in layer.entities
    {
        pos := ecs.get_component(layer, entity, Position).data
        size := ecs.get_component(layer, entity, Size).data
        color := ecs.get_component(layer, entity, Color).data

        rl.DrawRectangle(i32(pos[0]), i32(pos[1]), size[0], size[1], {color[0], color[1], color[2], color[3]})
    }
}

// updates the player on the layer that its on
player_update :: proc(layer: ^ecs.Registry) 
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
    rl.InitWindow(800, 450, "Tile Game Test Window")
    defer rl.CloseWindow()

    // initlaizes the ecs registery
    layer1 : ecs.Registry
    ecs.registry_init(&layer1);defer ecs.registry_destroy(&layer1)

    // creates the player and added some components to it
    player = ecs.create_entity(&layer1)
    ecs.add_component(&layer1, player, Position{{0, 0}})
    ecs.add_component(&layer1, player, Size{{100, 100}})
    ecs.add_component(&layer1, player, Color{{255, 0, 0, 255}})

    // assigns WASD input to the player
    player_input = {
        left  = rl.KeyboardKey.A,
        up    = rl.KeyboardKey.W,
        right = rl.KeyboardKey.D,
        down  = rl.KeyboardKey.S,
    }

    // sets the player speed to 5
    player_speed = 10

    // the main loop
    for !rl.WindowShouldClose()
    {
        // gets the current time bwteen frames
        delta_time = rl.GetFrameTime()

        // updates the player based off of the input assined to the player_input struct
        player_update(&layer1)

        // begins drawing and clears the background
        rl.BeginDrawing();defer rl.EndDrawing()
        rl.ClearBackground({20, 20, 30, 255})
        
        // calls the render system
        render_system(&layer1)
    }
}
