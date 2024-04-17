#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Please Enter correct service name"
else
    main_folder="$PWD/$1"
    mkdir "$main_folder"
    mkdir -p "$main_folder/data" "$main_folder/in" "$main_folder/out" "$main_folder/service"

    # Make main.go
    cat <<EOF >"$main_folder/main.go"
package main

import (
    "fmt"
)

func main() {
    fmt.Println("Hello from $service!")
}
EOF

    echo "Completed make file! $1"
fi
