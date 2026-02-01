# Grid System

Hexagonal grid using cube coordinates with A* pathfinding and grid invariant validation.

## Coordinate System

Cube coordinates (q, r, s) where q + r + s = 0, pointy-top orientation.

**Why cube over axial:** GDD specifies cube coordinates. Cube provides symmetric neighbor/distance math. Axial would require deriving s for distance calculations. Tradeoff: 33% more storage (3 ints vs 2) for cleaner math. Acceptable for 200 hexes.

**Distance calculation:** Manhattan distance in cube space divided by 2 yields hex grid distance. Symmetric across all 6 directions.

**Neighbor calculation:** Add 6 direction vectors to current coordinate. Each direction is a unit vector in cube space maintaining q+r+s=0 invariant.

## Pathfinding

A* implementation with hex distance heuristic. Heuristic is admissible (never overestimates), guaranteeing optimal paths.

**Priority queue as sorted array:** 200-hex grid has max ~200 A* nodes. O(n) insert on sorted array is ~200 ops worst case. Acceptable for vertical slice. Binary heap adds complexity without performance benefit at this scale. Defer optimization until profiling shows need.

**coordToKey() in HexMath:** Both HexGrid and Pathfinding need string serialization for Map keys. Defining in HexMath (public static) eliminates duplication. Single source of truth for coordinate serialization format. Both modules already import HexMath for distance/neighbor calculations. No new dependency.

## Grid Invariant

Every non-obstacle hex must have valid path to origin (0,0,0). Prevents softlock trap strategies where players block their own path.

**Validation via DFS from origin:** Mark all reachable hexes from origin, then verify all non-obstacle hexes are marked. O(V+E) single pass. More efficient than BFS-from-edges which is O(E*V). Simpler implementation.

**Try-finally pattern in validatePlacement:** Temporarily places obstacle, tests invariant, always removes obstacle even if validation throws. Ensures grid state consistency.

## Design Decisions

**HexCoord as abstract type:** Cube coordinates are immutable value type. Abstract provides compile-time type safety without class overhead. Implicit conversion from {q,r,s} anonymous structure improves API ergonomics. No inheritance needed for coordinate type. Abstract is idiomatic for Haxe value types.

**HEX_SIZE = 32 pixels:** Balances grid visibility with playable area on 1920x1080. Smaller (24px) obscures grid lines at distance. Larger (48px) reduces strategic overview and hex count visible. 32px tested as readable minimum.
