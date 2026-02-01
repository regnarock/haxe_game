# Supercritical

Arcade tower defense game where "danger is fuel." Built with Haxe and Heaps (JavaScript/WebGL target).

## Core Mechanic

Enemies generate energy while alive. Entropy constantly drains energy. Players balance spawn points (danger source) against towers (enemy elimination) to stay in the supercritical zone. Game ends when energy reaches zero.

## Architecture

### Entry Point

`src/Main.hx` extends `hxd.App`. The Heaps framework handles the game loop:
- `init()` - One-time setup, create scene graph
- `update(dt)` - Game logic, called every frame
- Rendering is automatic via Heaps scene graph

### Hex Grid System

Uses cube coordinates (q, r, s where q+r+s=0) for all game logic. Pixel positions are derived only for rendering.

| Concept | Implementation |
|---------|----------------|
| Coordinate type | `HexCoord` (cube q, r, s) |
| Grid storage | `HexGrid` tracks obstacles |
| Math utilities | `HexMath` for distance, neighbors, conversions |
| Pathfinding | A* with hex distance heuristic |

### Entity System

All game objects (Tower, Enemy, SpawnPoint, Base) extend `Entity` and register with `Game` for lifecycle management.

Entity lists use add/remove queues to prevent modification during iteration. Entities have an `alive` flag; dead entities are skipped during processing but remain in arrays until queue flush.

## Key Invariants

1. **Coordinates**: All game logic uses `HexCoord`. Pixel positions exist only at render time.
2. **Grid invariant**: Every non-obstacle hex must have a valid path to base (0,0,0). Prevents softlock placements.
3. **Entity lifecycle**: Never modify entity lists during iteration; queue changes.
4. **Energy bounds**: energy >= 0 triggers game over; energy capped at ENERGY_MAX.
5. **Pathfinding cache**: Enemy paths invalidated on any obstacle change.

## Game Mechanics

### Towers
- Placed on hex cells by the player (costs 20 energy)
- Have range measured in hex distance (2 hexes)
- Target first enemy in range (FIFO)
- Kill enemies instantly after 1 second lock-on
- Block pathfinding (enemies route around)

### Enemies
- Spawned from SpawnPoints
- Follow A* pathfinding to base at (0,0,0)
- Generate 0.5 energy/sec while alive
- Deduct 10 energy if they reach base

### SpawnPoints
- Player-placed spawners (cost 15 energy)
- Spawn enemies every 3 seconds
- Permanent until natural expiration (cannot be destroyed)
- Expire after 5 enemies spawned OR 30 seconds elapsed
- Block pathfinding (enemies route around)

### Energy Economy
- Start with 50 energy
- Entropy drains 1.0/sec initially, grows 0.1 per 10 seconds
- Energy formula: delta = (alive enemies * 0.5) - entropy
- Hard cap at 100 energy (forces active play vs hoarding)

## Debugging

Browser DevTools (F12):
- Console: `trace()` output
- Sources: Breakpoints in generated JS
- Performance: Frame profiling
- Network: Asset loading issues
