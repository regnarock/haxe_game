# Hex Tower Defense

Real-time 2D hexagonal grid tower defense game built with Haxe and Heaps (JavaScript/WebGL target).

## Architecture

### Entry Point

`src/Main.hx` extends `hxd.App`. The Heaps framework handles the game loop:
- `init()` - One-time setup, create scene graph
- `update(dt)` - Game logic, called every frame
- Rendering is automatic via Heaps scene graph

### Hex Grid System

Uses axial coordinates (q, r) for all game logic. Pixel positions are derived only for rendering.

| Concept | Implementation |
|---------|----------------|
| Coordinate type | `HexCoord` (axial q, r) |
| Grid storage | `HexGrid` maps coordinates to cells |
| Math utilities | `HexMath` for distance, neighbors, conversions |

### Entity System

All game objects (Tower, Enemy, Nest, Projectile) extend a base `Entity` class and register with `Game` for lifecycle management.

Entity lists use add/remove queues to prevent modification during iteration.

### Data-Driven Design

Tower stats, enemy stats, and nest definitions live in JSON files under `res/data/`. Haxe code loads and parses these at runtime. This allows tuning without recompilation.

## Key Invariants

1. **Coordinates**: All game logic uses `HexCoord`. Pixel positions exist only at render time.
2. **Asset access**: Use `Res.sprites.tower` (compile-time checked), never string paths.
3. **Entity lifecycle**: Never modify entity lists during iteration; queue changes.
4. **Separation**: Game logic in `update(dt)`, never in render callbacks.
5. **Data files**: Tower/enemy/nest stats in JSON, not hardcoded.

## Game Mechanics

### Towers
- Placed on hex cells by the player
- Have range measured in hex distance
- Fire projectiles at enemies within range

### Enemies
- Spawned from nests
- Follow A* pathfinding to goal
- Have HP and movement speed

### Nests
- Player-placed spawners
- Spawn enemies at a configured rate
- Expire after duration/spawn count reached
- Properties: spawn rate, enemy type, lifetime, spawn count

## Debugging

Browser DevTools (F12):
- Console: `trace()` output
- Sources: Breakpoints in generated JS
- Performance: Frame profiling
- Network: Asset loading issues
