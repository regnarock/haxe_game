# grid/

Hexagonal grid system using cube coordinates with pathfinding and placement validation.

## Files

| File | What | When to Read |
|------|------|--------------|
| `README.md` | Cube coordinate system, pathfinding approach, grid invariant | Understanding coordinate math, DFS validation, design decisions |
| `HexCoord.hx` | Cube coordinate value type (q,r,s), neighbors property | Working with hex positions, understanding coordinate system |
| `HexMath.hx` | Distance, neighbors, pixel conversion, coordinate serialization | Implementing hex-based features, converting screen to grid coords |
| `HexGrid.hx` | Obstacle tracking, coordinate validation | Managing obstacles, checking grid bounds |
| `Pathfinding.hx` | A* pathfinding, grid invariant validation (DFS) | Understanding pathfinding logic, placement validation |
