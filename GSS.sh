#!/bin/sh
echo -ne '\033c\033]0;Godot Shaders Sketchbook\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/GSS.x86_64" "$@"
