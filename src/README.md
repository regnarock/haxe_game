# Architecture

Supercritical is an arcade tower defense where "danger is fuel." The core loop: enemies generate energy while alive, entropy constantly drains energy, and players balance spawn points (danger source) against towers (enemy elimination) to stay in the supercritical zone.

## System Overview

```
                    +-------------+
                    |   Main.hx   |
                    | (hxd.App)   |
                    +------+------+
                           |
                           v
+----------+        +------+------+        +------------+
| Input    |------->|   Game.hx   |<------>| Pathfinding|
| (mouse)  |        | (state hub) |        +------------+
+----------+        +------+------+
                           |
         +-----------------+-----------------+
         |                 |                 |
         v                 v                 v
   +-----------+    +-----------+    +-----------+
   |  Enemies  |    |  Towers   |    |  Spawns   |
   | (Array)   |    | (Array)   |    | (Array)   |
   +-----------+    +-----------+    +-----------+
         |                 |                 |
         v                 v                 v
   +-----------+    +-----------+    +-----------+
   | Entity    |    | Entity    |    | Entity    |
   | Renderer  |    | Renderer  |    | Renderer  |
   +-----------+    +-----------+    +-----------+
```

Game.hx is the central state hub. Entities do not reference each other; they query Game for targets and paths. Separate typed arrays (enemies, towers, spawns) enable efficient per-system iteration.

## Data Flow Per Frame

Strict execution order ensures correct game state:

1. **Entity.update(dt)** for all entities:
   - Enemy: move along path, deduct energy if reaching base
   - Tower: target + attack (check alive flag, skip dead)
   - SpawnPoint: spawn timer, expiration check
2. **Process add/remove queues**
3. **Game.updateEnergy(dt)**:
   - sum alive enemies * ENERGY_VALUE
   - subtract entropy
   - check game over (energy <= 0)
4. **Input -> Game.tryPlace(entity, coord)**:
   - placement with cost deduction
   - uses accurate post-update energy state
5. **Render all entities**
6. **Render UI** (energy bar, flow indicator)

Entity updates (including base hits) occur before energy check, ensuring game over reflects current frame. Energy check occurs before placement, ensuring player sees accurate energy for placement decisions.

## Invariants

1. **q + r + s = 0**: All HexCoord instances satisfy cube coordinate constraint
2. **Grid invariant**: Every non-obstacle hex has valid path to (0,0,0) at all times
3. **Entity lifecycle**: Never add/remove entities during iteration; use queues
4. **Energy bounds**: energy >= 0 triggers game over; energy capped at ENERGY_MAX
5. **Pathfinding cache**: Enemy paths invalidated on any obstacle change

## Key Design Decisions

### Cube Coordinates

Cube coordinates (q, r, s) provide symmetric neighbor/distance math. Axial would require deriving s for distance calculations. Tradeoff: 33% more storage (3 ints vs 2) for cleaner math. Acceptable for 200 hexes.

### Single Graphics for Grid

Grid is semi-static (changes only on placement). Regenerating ~200 hex outlines per obstacle change is O(n), acceptable for <20 placements per game. Alternative of individual hex objects rejected due to memory overhead.

### Add/Remove Queues

Iterating entities during update prevents direct list modification (concurrent modification). Queue changes and process after iteration completes. Entity.destroy() sets alive=false immediately for early-out optimization; all systems must check alive flag and skip dead entities.

### Grid Invariant Enforcement

Every hex must reach base to prevent softlock trap strategies. Validated at placement time via DFS from origin (O(V+E) single pass). Shows red X preview if invalid.

### Per-Enemy Path Cache

Each Enemy stores its own path array. When obstacle placed, Game iterates enemies array calling Pathfinding.findPath() to recalculate each enemy's path field. No deduplication but acceptable at 200-hex scale with <50 enemies. Invalidation is straightforward.

### Energy Hard Cap

GDD specifies "Cap (for UI display)" but implementation enforces hard cap in updateEnergy(). Prevents runaway accumulation. Energy as scarce resource, not infinite bank. Forces continuous active play rather than hoarding. Players must spend or risk waste. Cap=100 chosen as ~2x starting energy to allow breathing room without eliminating tension.

### FIFO Tower Targeting

Towers target first-enemy-in-range (FIFO). Simpler than nearest/weakest logic. Consistent player expectations. Advanced targeting deferred.

### Flat Energy Rate

0.5 energy/sec per alive enemy. Simpler than proximity-based. Validates core loop before adding spatial complexity. Proximity mechanics deferred.

### Spawn Points Permanent

Spawn points expire naturally after 5 enemies or 30 seconds. Cannot be removed by tower or player. Forces commitment to placement decisions. Creates strategic tension around spawn positioning. Removal mechanic adds complexity without enhancing core loop.

### Priority Queue as Sorted Array

200-hex grid has max ~200 A* nodes. O(n) insert on sorted array is ~200 ops worst case. Acceptable for vertical slice. Binary heap adds complexity without performance benefit at this scale. Defer optimization until profiling shows need.

### HexCoord as Abstract Type

Cube coordinates are immutable value type. Abstract provides compile-time type safety without class overhead. Implicit conversion from {q,r,s} anonymous structure improves API ergonomics. No inheritance needed for coordinate type. Abstract is idiomatic for Haxe value types.

## Tuning Parameters

All game balance values in Config.hx:

- **HEX_SIZE = 32 pixels**: Balances grid visibility with playable area on 1920x1080. Smaller (24px) obscures grid lines at distance. Larger (48px) reduces strategic overview. 32px tested as readable minimum.
- **BASE_HIT_PENALTY = 10 energy**: Each base hit must be recoverable. 10 energy at starting 50 allows 5 hits before death. Creates tension without instant loss. Penalty scales with later entropy increase.
- **25% energy vignette threshold**: Warning triggers before critical (<10%) to allow recovery time. Too early (>30%) causes alarm fatigue. 25% provides ~15-20 second recovery window at base entropy rate.
- **2-minute supercritical window**: Arcade pacing research shows 1-3 minute engagement windows. Shorter prevents learning. Longer loses intensity. 2-5 minute survival aligns with mobile/casual session length.
- **Death pop aggregation 0.3s delay**: Perceptual grouping research shows 0.2-0.4s window for cognitive aggregation. Shorter (<0.2s) causes flicker perception. Longer (>0.5s) delays feedback. 0.3s provides natural grouping without lag.
- **Death pop cap of 3 simultaneous**: Screen clutter threshold. 4+ overlapping pops become unreadable. 2 or fewer loses aggregation benefit. 3 balances clarity with information density.
