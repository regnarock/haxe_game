# src/

Haxe source code for the game.

## Files

| File | What | When to Read |
|------|------|--------------|
| `README.md` | Architecture diagram, data flow, invariants, design decisions | Understanding system structure, entity lifecycle, pathfinding |
| `Main.hx` | App entry point, Heaps initialization, input hookup | Modifying initialization, adding event handlers |
| `Game.hx` | Central state hub, entity arrays, add/remove queues, energy system | Adding game features, understanding entity management |
| `Config.hx` | All game tuning parameters | Adjusting balance values, understanding game constants |

## Directories

| Directory | What | When to Read |
|-----------|------|--------------|
| `grid/` | Hex coordinate system, pathfinding, grid invariant | Working with hex math, placement validation, A* pathfinding |
| `entities/` | Entity base class, Enemy, Tower, SpawnPoint, Base | Implementing entity behavior, understanding lifecycle |
| `render/` | Hex grid rendering, entity rendering, UI, effects | Modifying visual presentation, adding visual feedback |
| `input/` | Placement controller, mouse handling | Modifying input handling, adding placement modes |
