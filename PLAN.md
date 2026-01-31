# Plan: Haxe Tower Defense Project Setup

## Overview

Set up the backbone for a real-time 2D hexagonal grid tower defense game using **Heaps + JavaScript/WebGL** for fast iteration with full browser debugging on ARM Mac.

## Files to Create

### 1. `CLAUDE.md` - AI Assistant Context

```markdown
# Hex Tower Defense

Real-time 2D hexagonal grid tower defense game built with Haxe and Heaps (JavaScript/WebGL target).

## Build Commands

| Command | Purpose |
|---------|---------|
| `make run` | Build and open in browser |
| `make watch` | Build + auto-reload on changes |
| `make setup` | Install dependencies |

## Project Structure

- `src/` - Haxe source code
  - `Main.hx` - Entry point, game initialization
  - `Game.hx` - Main game state, scene management
  - `entities/` - Game objects (Tower, Enemy, Nest, Projectile)
  - `systems/` - Game logic (NestSpawner, Pathfinding, Combat)
  - `grid/` - Hex grid utilities (HexGrid, HexCoord, HexMath)
  - `data/` - Static definitions (TowerDefs, EnemyDefs, NestDefs)
  - `ui/` - HUD, menus, tower selection
- `res/` - Runtime assets
  - `sprites/` - PNG images
  - `audio/` - Sound effects, music
  - `data/` - JSON configs (tower stats, nest definitions)
- `build/` - Output (gitignored)

## Conventions

- Entry point: `src/Main.hx` extends `hxd.App`
- One class per file, filename matches class name
- Hex coordinates: use `HexCoord` (axial q,r), not pixel positions
- Assets: lowercase_underscore.png, accessed via `Res.*`
- Game loop: logic in `update(dt)`, rendering handled by Heaps scene graph

## Key Patterns

- **Hex Grid**: Axial coordinates (q, r). Use `HexMath` for conversions.
- **Entity System**: Towers/Enemies/Nests extend base `Entity`, registered with `Game`
- **Nest System**: Player places Nests that spawn enemies over time, then expire
- **Pathfinding**: A* on hex grid, cached per-frame

## Anti-Patterns (AVOID)

- DO NOT use string paths for assets; use `Res.sprites.tower` (compile-time checked)
- DO NOT put game logic in render callbacks
- DO NOT store pixel positions; use `HexCoord` and convert only for rendering
- DO NOT modify entity lists while iterating; use add/remove queues
- DO NOT hardcode tower/enemy stats; put in `data/` JSON files

## Game Mechanics

- **Towers**: placed on hex cells, have range (hex distance), fire projectiles
- **Enemies**: spawned from nests, follow path to goal, have HP and speed
- **Nests**: player-placed, spawn enemies for a duration, then expire
- Nest properties: spawn rate, enemy type, lifetime, spawn count

## Debugging

Use browser DevTools (F12):
- Console for trace() output
- Sources tab for breakpoints
- Performance tab for profiling
- Network tab for asset loading

## Editor

Zed editor with Haxe language support.
```

### 2. `build.hxml` - Build Configuration

```hxml
-cp src
-main Main
-lib heaps
-lib heaps-webgl
-js build/game.js
-D js-es=6
```

### 3. `Makefile` - Build Commands

```makefile
.PHONY: run watch setup clean

run: build
	open build/index.html

build:
	haxe build.hxml

watch:
	@echo "Watching for changes... (Ctrl+C to stop)"
	@fswatch -o src/ res/ | xargs -n1 -I{} make build

setup:
	haxelib install heaps
	haxelib install heaps-webgl
	@echo "Optional: brew install fswatch (for make watch)"

clean:
	rm -rf build/
```

### 4. `build/index.html` - HTML Wrapper

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Hex Tower Defense</title>
    <style>
        body { margin: 0; overflow: hidden; background: #1a1a2e; }
        canvas { display: block; }
    </style>
</head>
<body>
    <canvas id="webgl"></canvas>
    <script src="game.js"></script>
</body>
</html>
```

### 5. `.gitignore`

```gitignore
# Build output
build/game.js
build/game.js.map

# Haxe cache
dump/
.haxelib/

# IDE
.zed/
.idea/

# OS
.DS_Store
Thumbs.db

# Dependencies
node_modules/
```

### 6. `src/Main.hx` - Entry Point

```haxe
class Main extends hxd.App {
    override function init() {
        // Initialize game
        trace("Hex Tower Defense initialized");
    }

    override function update(dt:Float) {
        // Game loop
    }

    static function main() {
        new Main();
    }
}
```

### 7. Directory Structure

```
haxe_game/
├── src/
│   ├── Main.hx
│   ├── entities/           # (empty, add as needed)
│   ├── systems/            # (empty, add as needed)
│   ├── grid/               # (empty, add as needed)
│   ├── data/               # (empty, add as needed)
│   └── ui/                 # (empty, add as needed)
├── res/
│   ├── sprites/
│   ├── audio/
│   └── data/
├── build/
│   └── index.html          # HTML wrapper (committed)
├── build.hxml
├── Makefile
├── .gitignore
└── CLAUDE.md
```

## Verification

After setup, verify with:

```bash
make setup      # Install Heaps and dependencies
make run        # Should open browser with blank canvas
```

Expected: Browser opens with dark canvas. Console shows "Hex Tower Defense initialized". This confirms:
- Haxe compiler works
- Heaps library installed correctly
- WebGL rendering functional

## Development Workflow

1. Edit code in Zed
2. Run `make run` to build and view
3. Use browser DevTools (F12) for debugging
4. Optional: Run `make watch` for auto-rebuild on save

## Native Build (Later)

When ready for desktop release, add `build-native.hxml`:

```hxml
-cp src
-main Main
-lib heaps
-lib hlsdl
-lib hlopenal
-hl build/game.hl
```

Then compile with HashLink/C for native binary.

## Growth Path

As the project grows, add:

1. **10+ files**: Add `Game.hx` to manage scene, move entities to `entities/`
2. **Hex grid**: Create `grid/HexCoord.hx`, `grid/HexMath.hx`, `grid/HexGrid.hx`
3. **First tower**: `entities/Tower.hx`, `data/TowerDefs.hx`
4. **Nest system**: `entities/Nest.hx`, `systems/NestSpawner.hx`, `data/NestDefs.hx`
5. **Enemies**: `entities/Enemy.hx`, `systems/Pathfinding.hx`
