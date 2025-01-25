# Extrude Tilesheet Tool

This repository contains a script for Aseprite that helps you extrude tiles in a tilesheet. This is particularly useful for game development, where you need to avoid texture bleeding.

This script is a direct port of the [Tileset Extruder by sergiss](https://github.com/sergiss/tileset-extruder/tree/master)'s Javascript web app to Lua for Aseprite.

## Features

- Extrudes tiles in a tilesheet to prevent texture bleeding.
- Easy to use with Aseprite.
- Customizable extrusion size.

## Requirements

- Aseprite v1.2.10 or later.

## Installation

1. Download the `extrude-tilesheet.lua` script.
2. Open Aseprite.
3. Go to `File > Scripts > Open Script Folder`.
4. Copy the `extrude-tilesheet.lua` script into the folder.
5. Restart Aseprite.

## Usage

1. Open your tilesheet in Aseprite.
2. Go to `File > Scripts > extrude-tilesheet`.
3. Enter the amount of columns and rows.
4. Enter the desired extrusion size in pixels.
5. Run the script to extrude your tiles.

## Known issues:

- After generating the extruded tilesheet, the color palette of the generated "sprite" will be entirely filled with black.
  - **Workaround**: `Palette Options > New palette from sprite` will re-generate a new palette from the sprite.

## Contributing

Contributions and feedback are welcome! Please open an issue or submit a pull request.
