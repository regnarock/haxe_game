# src/

Haxe source code for the game.

## Files

| File | What | When to Read |
|------|------|--------------|
| `Main.hx` | App entry point, game loop | Modifying initialization, understanding Heaps lifecycle |

## Directories

| Directory | What | When to Read |
|-----------|------|--------------|
| `data/` | Static data definitions (TowerDefs, EnemyDefs, NestDefs) | Adding/modifying tower or enemy types |
| `entities/` | Game objects (Tower, Enemy, Nest, Projectile) | Implementing entity behavior |
| `grid/` | Hex grid utilities (HexGrid, HexCoord, HexMath) | Working with hex coordinates or pathfinding |
| `systems/` | Game logic (NestSpawner, Pathfinding, Combat) | Modifying spawning, targeting, or combat |
| `ui/` | HUD, menus, tower selection | Implementing UI components |

Note: Subdirectories are stub directories (contain only `.gitkeep`). CLAUDE.md files will be added when code is implemented.
