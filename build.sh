#!/bin/bash

for arg in "$@"; do

    if [[ "$arg" == "clean" ]]; then

        rm tile-game
    
    elif [[ "$arg" == "build" ]]; then

        odin build .
    
    elif [[ "$arg" == "run" ]]; then

        ./tile-game

    fi

done
