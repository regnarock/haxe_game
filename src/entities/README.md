# Entity System

Queue-based entity lifecycle management with alive flag semantics.

## Entity Lifecycle

Entities are added and removed via queues to prevent concurrent modification during iteration.

**Add/remove queues:** Iterating entities during update prevents direct list modification. Queue changes and process after iteration completes. Prevents concurrent modification errors.

**Entity.destroy() semantics:** Sets alive=false immediately and queues for removal. Entity remains in array until queue processing but is ignored by game logic. Provides early-out optimization. All entity systems (Tower targeting, enemy iteration) MUST check alive flag and skip dead entities.

**Why immediate alive=false:** Prevents wasted computation on dead entities. Tower targeting skips dead enemies immediately without waiting for queue processing. Enemy movement stops immediately when destroyed.

## Entity Types

**Base:** Home base at origin (0,0,0). Pulsing glow indicates core objective.

**Enemy:** Walks along path to base. Per-enemy path cache simplifies invalidation on obstacle changes. When obstacle placed, Game iterates enemies array calling Pathfinding.findPath() to recalculate each enemy's path field. No deduplication but acceptable at 200-hex scale with <50 enemies.

**BASE_HIT_PENALTY = 10 energy:** Each base hit must be recoverable. 10 energy at starting 50 allows 5 hits before death. Creates tension without instant loss. Penalty scales with later entropy increase.

**Tower:** FIFO targeting (first-enemy-in-range). Simpler and more predictable than nearest/weakest targeting. Consistent player expectations. Advanced targeting deferred.

**SpawnPoint:** Spawns enemies at intervals until count or time limit reached. Permanent until natural expiration (cannot be destroyed by player or tower).

**Spawn point permanence:** Cannot be removed by tower or player. Forces commitment to placement decisions. Creates strategic tension around spawn positioning. Removal mechanic adds complexity without enhancing core loop.

**Execution order in SpawnPoint.update:** (1) increment lifetime by dt; (2) check lifetime >= timeLimit OR spawnCount >= countLimit, if true destroy and return; (3) decrement spawnTimer by dt; (4) if timer <= 0 spawn enemy, increment count, reset timer. This ensures count limit is strictly enforced even if timer expires simultaneously with 5th spawn. Prevents spawning 6th enemy.

## Design Decisions

**Separate typed arrays:** enemies:Array<Enemy>, towers:Array<Tower>, spawns:Array<SpawnPoint> enable efficient per-system iteration. Game.hx maintains all arrays. Type-specific logic (targeting, path recalculation) iterates only relevant array.

**Per-enemy path cache:** Each Enemy stores its own path array. When obstacle placed, Game iterates enemies array and recalculates each path. No global Map cache with deduplication. Simpler invalidation. Acceptable at 200-hex scale with <50 enemies.
