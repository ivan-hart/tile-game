package tile_game;

import "core:fmt"

import rl "vendor:raylib"

import ecs "ecs"

main :: proc() 
{
    rl.InitWindow(800, 450, "Tile Game Test Window")
    defer rl.CloseWindow()
}
