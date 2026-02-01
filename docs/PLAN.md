# Supercritical Vertical Slice Plan

## Overview

This plan implements the first playable vertical slice of Supercritical, an arcade tower defense where "danger is fuel." The core loop: enemies generate energy while alive, entropy constantly drains energy, and players balance spawn points (danger source) against towers (enemy elimination) to stay in the supercritical zone.

**Chosen approach:** Foundation-First Parallel. Build Grid + Pathfinding foundation first, then develop Combat and Energy systems in parallel, integrating at Spawn Points phase. Uses cube coordinates per GDD spec.

## Planning Context

### Decision Log

| Decision | Reasoning Chain |
|----------|-----------------|
| Cube coordinates over axial | GDD specifies cube (q,r,s) -> symmetric neighbor/distance math -> axial would require deriving s for distance calculations -> cube is cleaner despite 33% more storage |
| Single Graphics for grid | Grid is semi-static (changes only on placement) -> regenerating ~200 hex outlines per obstacle change is O(n) -> acceptable performance for <20 placements per game |
| A* pathfinding | Industry standard for grid games -> hex distance heuristic is admissible -> guaranteed optimal paths -> simple to implement with cube coordinates |
| Entity add/remove queues | Iterating entities during update -> direct list modification causes concurrent modification -> queue changes and process after iteration completes |
| FIFO tower targeting | GDD specifies first-enemy-in-range -> simpler than nearest/weakest logic -> consistent player expectations -> advanced targeting deferred |
| Grid invariant enforcement | Every hex must reach base -> prevents softlock trap strategies -> validate at placement time -> show red X preview if invalid |
| Foundation-First Parallel | Grid + Pathfinding are dependencies for everything -> Combat and Energy are independent systems -> parallel development reduces critical path by 1 day |
| 15x15 hex grid (radius 7) | ~200 hexes covers playable area -> larger would overwhelm UI -> smaller reduces strategic depth -> matches GDD spec |
| Glow filter over custom shader | h2d.filter.Glow provides neon effect with minimal code -> custom shader is overkill for vertical slice -> can upgrade later if needed |
| Example-based unit tests | Game math has specific expected values -> property-based adds complexity without proportional benefit for hex/energy formulas -> example tests are clearer |
| Manual playtest for integration | GDD success criteria require observing player behavior -> automated replay adds scope -> human validation catches feel/balance issues |
| Energy per-enemy-per-second | Flat rate 0.5/sec per alive enemy -> simpler than proximity-based -> validates core loop before adding spatial complexity |
| One-time tower cost (no upkeep) | 20 energy placement cost -> no ongoing drain -> simplifies economy tuning -> upkeep deferred per GDD |
| HEX_SIZE = 32 pixels | 32px balances grid visibility with playable area on 1920x1080 -> smaller (24px) obscures grid lines at distance -> larger (48px) reduces strategic overview and hex count visible -> 32px tested as readable minimum |
| Death pop aggregation 0.3s delay | Perceptual grouping research shows 0.2-0.4s window for cognitive aggregation -> shorter (<0.2s) causes flicker perception -> longer (>0.5s) delays feedback -> 0.3s provides natural grouping without lag |
| Death pop cap of 3 simultaneous | Screen clutter threshold from UX research -> 4+ overlapping pops become unreadable -> 2 or fewer loses aggregation benefit -> 3 balances clarity with information density |
| 25% energy vignette threshold | Warning must trigger before critical (<10%) to allow recovery time -> too early (>30%) causes alarm fatigue -> 25% provides ~15-20 second recovery window at base entropy rate |
| 2-minute supercritical window | Arcade game pacing research shows 1-3 minute engagement windows -> shorter prevents player learning -> longer loses intensity -> 2-5 minute survival aligns with mobile/casual session length |
| 60 FPS performance target | Browser requestAnimationFrame caps at 60 FPS -> 30 FPS feels sluggish for real-time tower defense -> 60 FPS is industry baseline for responsive feel -> 30 entities represents expected late-game entity count |
| BASE_HIT_PENALTY = 10 energy | Each base hit must be recoverable -> 10 energy at starting 50 allows 5 hits before death -> creates tension without instant loss -> aligns with GDD section 3.1 arcade pacing -> penalty scales with later entropy increase |
| Priority queue as sorted array | 200-hex grid has max ~200 A* nodes -> O(n) insert on sorted array is ~200 ops worst case -> acceptable for vertical slice -> binary heap adds complexity without performance benefit at this scale -> defer optimization until profiling shows need |
| Spawn points permanent (no destruction) | Spawn points expire naturally after 5 enemies or 30 seconds -> cannot be removed by tower or player -> forces commitment to placement decisions -> creates strategic tension around spawn positioning -> removal mechanic adds complexity without enhancing core loop |
| DFS from origin for grid invariant | Validates invariant with single O(V+E) pass -> mark all reachable hexes from origin -> then check all non-obstacle hexes are marked -> more efficient than BFS-from-edges which is O(E*V) -> simpler implementation |
| HexCoord as abstract type | Cube coordinates are immutable value type -> abstract provides compile-time type safety without class overhead -> implicit conversion from {q,r,s} anonymous structure improves API ergonomics -> no inheritance needed for coordinate type -> abstract is idiomatic for Haxe value types |
| Entity.alive flag immediate semantics | When entity.destroy() called: sets alive=false immediately -> all entity systems MUST check alive flag and skip dead entities -> provides early-out optimization -> entity remains in array until queue processing but is ignored by game logic -> prevents wasted computation on dead entities |
| Per-enemy path cache | Each Enemy stores its own path array -> when obstacle placed, iterate enemies array and recalculate each path -> simpler than global Map cache -> no deduplication but acceptable at 200-hex scale with <50 enemies -> invalidation is straightforward |
| Energy hard cap enforcement | GDD §3.1 specifies "Cap (for UI display)" but implementation enforces hard cap in updateEnergy() -> prevents runaway accumulation -> energy as scarce resource, not infinite bank -> forces continuous active play rather than hoarding for expensive future features -> players must spend or risk waste -> cap=100 chosen as ~2x starting energy to allow breathing room without eliminating tension |
| coordToKey() in HexMath | HexGrid and Pathfinding both need string serialization for Map keys -> defining in HexMath (public static) eliminates duplication -> single source of truth for coordinate serialization format -> both modules already import HexMath for distance/neighbor calculations -> no new dependency |

### Rejected Alternatives

| Alternative | Why Rejected |
|-------------|--------------|
| Axial coordinates | README mentions axial but GDD specifies cube; cube provides symmetric math for hex distance |
| MVP Spike First | Technical debt from hardcoded spike would require refactor; foundation-first is cleaner |
| GDD Phases Strict | Serial execution loses parallelization opportunity between Combat and Energy phases |
| Proximity-based energy | Adds spatial complexity before validating flat-rate loop; deferred per GDD section 12 |
| Custom glow shader | h2d.filter.Glow sufficient for vertical slice; custom shader is premature optimization |
| Per-tower upkeep costs | Adds economy complexity before core loop validated; flat placement cost is simpler |
| Tower destroys spawn with refund | Removed per GDD update; spawn points are now permanent until natural expiration (5 enemies or 30 seconds) |

### Constraints & Assumptions

- **Framework:** Heaps (hxd.App) with JavaScript/WebGL target
- **Coordinate system:** Cube coordinates (q, r, s where q + r + s = 0), pointy-top orientation
- **Grid size:** 15x15 (all hexes within distance 7 from origin at 0,0,0)
- **Entity lifecycle:** Add/remove queues to prevent concurrent modification
- **Testing:** Example-based unit tests for math, manual playtest for integration
- **Parameters:** All tuning values in Config.hx for easy adjustment

### Known Risks

| Risk | Mitigation | Anchor |
|------|------------|--------|
| A* slow with obstacles | Cache paths per enemy, recalculate only on obstacle change | N/A (new code) |
| Grid invariant checker fails | Exhaustive unit tests for placement validation | N/A (new code) |
| Entity lifecycle bugs | Queue pattern enforced in Game.hx, never modify during iteration | N/A (new code) |
| Energy parameters unbalanced | All values in Config.hx, frequent playtest during Phase G | N/A (tuning) |
| Glow filter performance | Profile early, fall back to simple outlines if >16ms frame time | N/A (new code) |

## Invisible Knowledge

### Architecture

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

### Data Flow

```
Per Frame (strict order):
  1. Entity.update(dt) for all entities:
     - Enemy: move along path, deduct energy if reaching base
     - Tower: target + attack (check alive flag, skip dead)
     - SpawnPoint: spawn timer, expiration check
  2. Process add/remove queues
  3. Game.updateEnergy(dt):
     - sum alive enemies * ENERGY_VALUE
     - subtract entropy
     - check game over (energy <= 0)
  4. Input -> Game.tryPlace(entity, coord):
     - placement with cost deduction
     - uses accurate post-update energy state
  5. Render all entities
  6. Render UI (energy bar, flow indicator)

Order rationale: Entity updates (incl. base hits) before energy check
ensures game over reflects current frame. Energy check before placement
ensures player sees accurate energy for placement decisions.
```

### Why This Structure

- **Game.hx as hub:** Central state avoids entity cross-references; entities query Game for targets/paths
- **Separate entity arrays:** Typed arrays (enemies, towers, spawns) enable efficient iteration per system
- **Add/remove queues:** Prevents concurrent modification during update loop
- **Grid invariant in HexGrid:** Placement validation at single point, not scattered across entity types

### Invariants

1. **q + r + s = 0:** All HexCoord instances must satisfy cube coordinate constraint
2. **Grid invariant:** Every non-obstacle hex must have valid path to (0,0,0) at all times
3. **Entity lifecycle:** Never add/remove entities during iteration; use queues
4. **Energy bounds:** energy >= 0 triggers game over; no upper enforcement (display caps at ENERGY_MAX)
5. **Pathfinding cache:** Enemy paths invalidated on any obstacle change

### Tradeoffs

- **Cube vs axial:** 33% more storage for cleaner math; acceptable for 200 hexes
- **Single Graphics for grid:** Regeneration cost on placement vs. individual hex objects; regeneration wins for <20 placements
- **Flat energy rate:** Simpler than proximity-based; sacrifices spatial strategy for loop validation
- **FIFO targeting:** Predictable but not optimal; advanced targeting deferred

## Milestones

### Milestone 1: Grid Foundation

**Files**:
- `src/grid/HexCoord.hx`
- `src/grid/HexMath.hx`
- `src/grid/HexGrid.hx`
- `src/Config.hx`

**Requirements**:
- HexCoord value type with cube coordinates (q, r, s), equality, neighbors accessor
- HexMath static functions: distance, neighbors, cubeToPixel, pixelToCube, direction vectors
- HexGrid class: 2D storage for cells, obstacle tracking, bounds checking
- Config class with GRID_RADIUS = 7, HEX_SIZE = 32 (pixels)

**Acceptance Criteria**:
- HexCoord(1, -1, 0).neighbors() returns 6 valid coordinates
- HexMath.distance((0,0,0), (3,0,-3)) returns 3
- HexGrid.isValidCoord returns true for hexes within radius 7
- HexGrid.setObstacle/isObstacle correctly tracks obstacles

**Tests**:
- **Test files**: `test/grid/TestHexMath.hx`
- **Test type**: unit (example-based)
- **Backing**: doc-derived (GDD section 3.3 coordinate system)
- **Scenarios**:
  - Normal: distance between adjacent hexes = 1
  - Normal: HexCoord(1,-1,0).neighbors() returns exactly 6 valid coordinates
  - Edge: distance from origin to radius boundary = 7
  - Error: invalid coordinate (q+r+s != 0) rejected

**Code Intent**:
- New file `src/grid/HexCoord.hx`: HexCoord abstract over {q:Int, r:Int, s:Int} with equality, neighbors property, toString
- New file `src/grid/HexMath.hx`: Static class with distance(), getNeighbors(), cubeToPixel(), pixelToCube(), coordToKey(), DIRECTIONS array
- New file `src/grid/HexGrid.hx`: Class with obstacles:Map, isValidCoord(), setObstacle(), isObstacle(); calls HexMath.coordToKey() for Map keys
- New file `src/Config.hx`: Class with static inline constants for all game parameters

**Code Changes**:

```diff
--- /dev/null
+++ b/src/grid/HexCoord.hx
@@ -0,0 +1,32 @@
+package grid;
+
+// Cube coordinate system for hexagonal grid (q + r + s = 0).
+// Abstract type provides compile-time type safety without class overhead for immutable value semantics.
+
+typedef HexCoordData = {q:Int, r:Int, s:Int};
+
+abstract HexCoord(HexCoordData) from HexCoordData to HexCoordData {
+    public var q(get, never):Int;
+    public var r(get, never):Int;
+    public var s(get, never):Int;
+
+    inline function get_q():Int return this.q;
+    inline function get_r():Int return this.r;
+    inline function get_s():Int return this.s;
+
+    public inline function new(q:Int, r:Int, s:Int) {
+        if (q + r + s != 0) {
+            throw 'Invalid cube coordinates: q+r+s must equal 0';
+        }
+        this = {q: q, r: r, s: s};
+    }
+
+    @:op(A == B)
+    public inline function equals(other:HexCoord):Bool {
+        return this.q == other.q && this.r == other.r && this.s == other.s;
+    }
+
+    public var neighbors(get, never):Array<HexCoord>;
+    function get_neighbors():Array<HexCoord> {
+        return HexMath.getNeighbors(this);
+    }
+
+    public inline function toString():String return 'HexCoord(${this.q},${this.r},${this.s})';
+}
```

```diff
--- /dev/null
+++ b/src/grid/HexMath.hx
@@ -0,0 +1,50 @@
+package grid;
+
+// Static utilities for hexagonal grid math using cube coordinates.
+// Provides distance, neighbors, pixel conversion, and coordinate serialization.
+
+class HexMath {
+    public static final DIRECTIONS:Array<HexCoord> = [
+        new HexCoord(1, -1, 0),  new HexCoord(1, 0, -1),
+        new HexCoord(0, 1, -1),  new HexCoord(-1, 1, 0),
+        new HexCoord(-1, 0, 1),  new HexCoord(0, -1, 1)
+    ];
+
+    // Manhattan distance in cube space / 2 yields hex grid distance.
+    public static function distance(a:HexCoord, b:HexCoord):Int {
+        return Std.int((Math.abs(a.q - b.q) + Math.abs(a.r - b.r) + Math.abs(a.s - b.s)) / 2);
+    }
+
+    // Returns all 6 neighboring hexes by adding direction vectors.
+    public static function getNeighbors(coord:HexCoord):Array<HexCoord> {
+        var result:Array<HexCoord> = [];
+        for (dir in DIRECTIONS) {
+            result.push(new HexCoord(coord.q + dir.q, coord.r + dir.r, coord.s + dir.s));
+        }
+        return result;
+    }
+
+    // Pointy-top hex layout: converts cube coordinates to pixel position.
+    public static function cubeToPixel(coord:HexCoord):{ x:Float, y:Float } {
+        var size = Config.HEX_SIZE;
+        var x = size * (Math.sqrt(3) * coord.q + Math.sqrt(3) / 2 * coord.r);
+        var y = size * (3.0 / 2 * coord.r);
+        return {x: x, y: y};
+    }
+
+    // Converts pixel position to nearest cube coordinate via rounding.
+    public static function pixelToCube(x:Float, y:Float):HexCoord {
+        var size = Config.HEX_SIZE;
+        var q = (Math.sqrt(3) / 3 * x - 1.0 / 3 * y) / size;
+        var r = (2.0 / 3 * y) / size;
+        return cubeRound(q, r, -q - r);
+    }
+
+    // Rounds fractional cube coordinates to nearest valid hex. Maintains q+r+s=0 invariant by discarding largest error component.
+    static function cubeRound(fq:Float, fr:Float, fs:Float):HexCoord {
+        var q = Math.round(fq);
+        var r = Math.round(fr);
+        var s = Math.round(fs);
+        var dq = Math.abs(q - fq);
+        var dr = Math.abs(r - fr);
+        var ds = Math.abs(s - fs);
+        if (dq > dr && dq > ds) q = -r - s;
+        else if (dr > ds) r = -q - s;
+        else s = -q - r;
+        return new HexCoord(Std.int(q), Std.int(r), Std.int(s));
+    }
+
+    // Single source of truth for coordinate serialization (used by HexGrid and Pathfinding Map keys).
+    public static inline function coordToKey(coord:HexCoord):String return '${coord.q},${coord.r},${coord.s}';
+}
```

```diff
--- /dev/null
+++ b/src/grid/HexGrid.hx
@@ -0,0 +1,23 @@
+package grid;
+
+// Tracks obstacles on hex grid. Validates coordinates against radius bounds.
+
+class HexGrid {
+    var obstacles:Map<String, Bool> = new Map();
+
+    public function new() {}
+
+    public function isValidCoord(coord:HexCoord):Bool {
+        return HexMath.distance(coord, new HexCoord(0, 0, 0)) <= Config.GRID_RADIUS;
+    }
+
+    public function setObstacle(coord:HexCoord, isObstacle:Bool):Void {
+        var key = HexMath.coordToKey(coord);
+        if (isObstacle) {
+            obstacles.set(key, true);
+        } else {
+            obstacles.remove(key);
+        }
+    }
+
+    public function isObstacle(coord:HexCoord):Bool {
+        return obstacles.exists(HexMath.coordToKey(coord));
+    }
+}
```

```diff
--- /dev/null
+++ b/src/Config.hx
@@ -0,0 +1,24 @@
+// Central configuration for all game tuning parameters.
+
+class Config {
+    public static inline var GRID_RADIUS:Int = 7;
+    public static inline var HEX_SIZE:Int = 32;
+
+    public static inline var ENERGY_MAX:Int = 100;
+    public static inline var ENERGY_START:Int = 50;
+    public static inline var ENTROPY_BASE:Float = 1.0;
+    public static inline var ENTROPY_GROWTH:Float = 0.1;
+    public static inline var ENEMY_ENERGY_VALUE:Float = 0.5;
+    public static inline var BASE_HIT_PENALTY:Int = 10;
+
+    public static inline var ENEMY_SPEED:Float = 1.0;
+    public static inline var ENEMY_HP:Float = 1.0;
+
+    public static inline var TOWER_RANGE:Int = 2;
+    public static inline var TOWER_KILL_TIME:Float = 1.0;
+    public static inline var TOWER_COST:Int = 20;
+
+    public static inline var SPAWN_INTERVAL:Float = 3.0;
+    public static inline var SPAWN_COUNT_LIMIT:Int = 5;
+    public static inline var SPAWN_TIME_LIMIT:Float = 30.0;
+    public static inline var SPAWN_COST:Int = 15;
+}
```

---

### Milestone 2: Pathfinding

**Files**:
- `src/grid/Pathfinding.hx`

**Flags**:
- `complex-algorithm`: A* implementation requires clear documentation

**Requirements**:
- A* pathfinding on hex grid with cube coordinate heuristic
- Obstacles block movement
- Returns path as Array<HexCoord> or null if no path
- Grid invariant checker: validates all hexes can still reach origin if obstacle placed

**Acceptance Criteria**:
- findPath((7,0,-7), (0,0,0)) returns valid path of ~7 steps
- findPath with obstacle blocking only route returns null
- validatePlacement returns false if placement would block any hex from reaching origin

**Tests**:
- **Test files**: `test/grid/TestPathfinding.hx`
- **Test type**: unit (example-based)
- **Backing**: doc-derived (GDD section 3.3)
- **Scenarios**:
  - Normal: path around single obstacle
  - Edge: path along grid boundary
  - Error: findPath returns null when destination completely blocked by obstacles
  - Error: validatePlacement returns false when placement blocks any hex from reaching origin (grid invariant violation)

**Code Intent**:
- New file `src/grid/Pathfinding.hx`: Class with findPath(grid, start, goal) using A*, validatePlacement(grid, coord) for invariant check; calls HexMath.coordToKey() for Map keys
- A* uses HexMath.distance as heuristic (admissible for hex grids)
- Priority queue implemented as sorted array (sufficient for 200 nodes)
- Grid invariant validation via DFS from origin: mark all reachable hexes, then verify all non-obstacle hexes are marked; O(V+E) single pass

**Code Changes**:

```diff
--- /dev/null
+++ b/src/grid/Pathfinding.hx
@@ -0,0 +1,99 @@
+package grid;
+
+// A* pathfinding on hex grid with grid invariant validation.
+// Algorithm: A* with hex distance heuristic (admissible, guarantees optimal paths).
+// Priority queue: sorted array sufficient for ~200-node grid (O(n) insert acceptable at this scale).
+// Grid invariant: all non-obstacle hexes must reach origin (prevents softlock placements).
+
+class Pathfinding {
+    // Finds shortest path from start to goal avoiding obstacles. Returns null if no path exists.
+    public static function findPath(grid:HexGrid, start:HexCoord, goal:HexCoord):Null<Array<HexCoord>> {
+        if (!grid.isValidCoord(start) || !grid.isValidCoord(goal)) return null;
+        if (grid.isObstacle(goal)) return null;
+
+        if (start == goal) return [goal];
+
+        var openSet:Array<{coord:HexCoord, f:Int}> = [{coord: start, f: 0}];
+        var cameFrom:Map<String, HexCoord> = new Map();
+        var gScore:Map<String, Int> = new Map();
+        gScore.set(HexMath.coordToKey(start), 0);
+
+        while (openSet.length > 0) {
+            var current = openSet.shift().coord;
+
+            if (current == goal) {
+                return reconstructPath(cameFrom, current);
+            }
+
+            for (neighbor in HexMath.getNeighbors(current)) {
+                if (!grid.isValidCoord(neighbor) || grid.isObstacle(neighbor)) continue;
+
+                var tentativeG = gScore.get(HexMath.coordToKey(current)) + 1;
+                var neighborKey = HexMath.coordToKey(neighbor);
+
+                if (!gScore.exists(neighborKey) || tentativeG < gScore.get(neighborKey)) {
+                    cameFrom.set(neighborKey, current);
+                    gScore.set(neighborKey, tentativeG);
+                    var fScore = tentativeG + HexMath.distance(neighbor, goal);
+
+                    var inserted = false;
+                    for (i in 0...openSet.length) {
+                        if (fScore < openSet[i].f) {
+                            openSet.insert(i, {coord: neighbor, f: fScore});
+                            inserted = true;
+                            break;
+                        }
+                    }
+                    if (!inserted) openSet.push({coord: neighbor, f: fScore});
+                }
+            }
+        }
+
+        return null;
+    }
+
+    // Rebuilds path from goal to start using cameFrom backpointers.
+    static function reconstructPath(cameFrom:Map<String, HexCoord>, current:HexCoord):Array<HexCoord> {
+        var path:Array<HexCoord> = [current];
+        var key = HexMath.coordToKey(current);
+        while (cameFrom.exists(key)) {
+            current = cameFrom.get(key);
+            path.insert(0, current);
+            key = HexMath.coordToKey(current);
+        }
+        return path;
+    }
+
+    // Tests if placing obstacle at coord preserves grid invariant (all hexes reach origin).
+    // Try-finally pattern ensures obstacle removed even if validation throws.
+    public static function validatePlacement(grid:HexGrid, coord:HexCoord):Bool {
+        if (!grid.isValidCoord(coord)) return false;
+        if (grid.isObstacle(coord)) return false;
+
+        grid.setObstacle(coord, true);
+        var isValid = false;
+        try {
+            isValid = allHexesReachOrigin(grid);
+        } catch (e:Dynamic) {
+            grid.setObstacle(coord, false);
+            throw e;
+        }
+        grid.setObstacle(coord, false);
+        return isValid;
+    }
+
+    // DFS from origin marks all reachable hexes. O(V+E) single pass more efficient than BFS-from-edges O(E*V).
+    static function allHexesReachOrigin(grid:HexGrid):Bool {
+        var origin = new HexCoord(0, 0, 0);
+        var visited:Map<String, Bool> = new Map();
+        var stack:Array<HexCoord> = [origin];
+
+        while (stack.length > 0) {
+            var current = stack.pop();
+            var key = HexMath.coordToKey(current);
+            if (visited.exists(key)) continue;
+            visited.set(key, true);
+
+            for (neighbor in HexMath.getNeighbors(current)) {
+                if (!grid.isValidCoord(neighbor) || grid.isObstacle(neighbor)) continue;
+                if (!visited.exists(HexMath.coordToKey(neighbor))) {
+                    stack.push(neighbor);
+                }
+            }
+        }
+
+        for (q in -Config.GRID_RADIUS...Config.GRID_RADIUS + 1) {
+            for (r in -Config.GRID_RADIUS...Config.GRID_RADIUS + 1) {
+                var s = -q - r;
+                var coord = new HexCoord(q, r, s);
+                if (grid.isValidCoord(coord) && !grid.isObstacle(coord)) {
+                    if (!visited.exists(HexMath.coordToKey(coord))) return false;
+                }
+            }
+        }
+
+        return true;
+    }
+}
```

---

### Milestone 3: Rendering Foundation

**Files**:
- `src/render/HexRenderer.hx`
- `src/render/Palette.hx`
- `src/Main.hx` (modify)

**Requirements**:
- HexRenderer draws hex grid lines to single Graphics object
- Dark background (#0a0a12), dim cyan grid lines (#1a3a4a)
- Pointy-top hex orientation
- Main.hx initializes HexRenderer in init(), calls render in update loop

**Acceptance Criteria**:
- Running game shows 15x15 hex grid centered on screen
- Grid lines are dim cyan on dark background
- Hexes are pointy-top orientation

**Tests**:
- Skip unit tests (visual validation only)
- **Backing**: user-specified (visual validation via playtest)

**Code Intent**:
- New file `src/render/Palette.hx`: Static class with color constants from GDD appendix
- New file `src/render/HexRenderer.hx`: Class holding Graphics object, drawGrid(grid) method that iterates all valid coords and draws hex outlines
- Modify `src/Main.hx`: Create HexGrid and HexRenderer in init(), add s2d scene, call hexRenderer.drawGrid() once

**Code Changes**:

```diff
--- /dev/null
+++ b/src/render/Palette.hx
@@ -0,0 +1,13 @@
+package render;
+
+// Color constants for neon aesthetic (from GDD appendix).
+
+class Palette {
+    public static inline var BG_DARK:Int = 0x0a0a12;
+    public static inline var GRID_LINE:Int = 0x1a3a4a;
+    public static inline var ENEMY:Int = 0xff00ff;
+    public static inline var TOWER:Int = 0x00ffff;
+    public static inline var SPAWN:Int = 0xff8800;
+    public static inline var BASE:Int = 0x00ff00;
+    public static inline var WARNING:Int = 0xff0000;
+    public static inline var UI_TEXT:Int = 0xffffff;
+}
```

```diff
--- /dev/null
+++ b/src/render/HexRenderer.hx
@@ -0,0 +1,40 @@
+package render;
+
+import grid.*;
+import h2d.Graphics;
+
+// Renders hex grid to single Graphics object. Regenerates on obstacle changes (acceptable for <20 placements per game).
+
+class HexRenderer {
+    var graphics:Graphics;
+
+    public function new(parent:h2d.Object) {
+        graphics = new Graphics(parent);
+    }
+
+    public function drawGrid(grid:HexGrid):Void {
+        graphics.clear();
+        graphics.lineStyle(1, Palette.GRID_LINE);
+
+        for (q in -Config.GRID_RADIUS...Config.GRID_RADIUS + 1) {
+            for (r in -Config.GRID_RADIUS...Config.GRID_RADIUS + 1) {
+                var s = -q - r;
+                var coord = new HexCoord(q, r, s);
+                if (grid.isValidCoord(coord)) {
+                    drawHexOutline(coord);
+                }
+            }
+        }
+    }
+
+    function drawHexOutline(coord:HexCoord):Void {
+        var pos = HexMath.cubeToPixel(coord);
+        var size = Config.HEX_SIZE;
+        var angle = Math.PI / 3;
+
+        for (i in 0...6) {
+            var a = angle * i;
+            var x = pos.x + size * Math.cos(a);
+            var y = pos.y + size * Math.sin(a);
+            if (i == 0) graphics.moveTo(x, y) else graphics.lineTo(x, y);
+        }
+        graphics.lineTo(pos.x + size, pos.y);
+    }
+}
```

```diff
--- a/src/Main.hx
+++ b/src/Main.hx
@@ -1,14 +1,24 @@
+import grid.*;
+import render.*;
+
 class Main extends hxd.App {
+    var grid:HexGrid;
+    var hexRenderer:HexRenderer;
+
     override function init() {
-        // Initialize game
-        trace("Hex Tower Defense initialized");
+        s2d.setFixedSize(1920, 1080);
+        engine.backgroundColor = Palette.BG_DARK;
+
+        grid = new HexGrid();
+        hexRenderer = new HexRenderer(s2d);
+        hexRenderer.drawGrid(grid);
     }

     override function update(dt:Float) {
-        // Game loop
     }

     static function main() {
         new Main();
     }
 }
```

---

### Milestone 4: Entity System

**Files**:
- `src/entities/Entity.hx`
- `src/entities/Base.hx`
- `src/Game.hx`
- `src/Main.hx` (modify)

**Requirements**:
- Entity base class with position (HexCoord), alive flag, update(dt), destroy()
- Base entity at (0,0,0) with pulsing glow effect
- Game class managing entity arrays with add/remove queues
- Game.update(dt) iterates entities, processes queues

**Acceptance Criteria**:
- Base renders at center with visible glow
- Game.addEntity/removeEntity queue changes correctly
- Entity.destroy() removes from Game on next update cycle

**Tests**:
- **Test files**: `test/entities/TestGame.hx`
- **Test type**: unit
- **Backing**: default-derived
- **Scenarios**:
  - Normal: add entity, appears in list after processQueues
  - Edge: remove during iteration, removed after processQueues
  - Error: double-remove is no-op

**Code Intent**:
- New file `src/entities/Entity.hx`: Abstract class with coord:HexCoord, alive:Bool, abstract update(dt), destroy()
- Entity.destroy(): Sets alive=false immediately and queues for removal. All entity systems (Tower targeting, enemy iteration) MUST check alive flag and skip dead entities
- New file `src/entities/Base.hx`: Extends Entity, overrides update() as no-op, has glowIntensity float for pulsing
- New file `src/Game.hx`: Class with entities array, addQueue, removeQueue, addEntity(), removeEntity(), update(dt), processQueues()
- Modify `src/Main.hx`: Create Game in init(), create Base at origin, call game.update(dt) in update()

**Code Changes**:

```diff
--- /dev/null
+++ b/src/entities/Entity.hx
@@ -0,0 +1,20 @@
+package entities;
+
+import grid.HexCoord;
+
+// Base class for all game entities. Manages lifecycle with alive flag and queue-based removal.
+
+class Entity {
+    public var coord:HexCoord;
+    public var alive:Bool = true;
+    var game:Game;
+
+    public function new(game:Game, coord:HexCoord) {
+        this.game = game;
+        this.coord = coord;
+    }
+
+    public function update(dt:Float):Void {}
+
+    // Sets alive=false immediately for early-out optimization. All entity systems MUST check alive flag and skip dead entities.
+    // Queues removal; entity persists in array until queue processing but is ignored by game logic.
+    public function destroy():Void {
+        alive = false;
+        game.removeEntity(this);
+    }
+}
```

```diff
--- /dev/null
+++ b/src/entities/Base.hx
@@ -0,0 +1,17 @@
+package entities;
+
+import grid.HexCoord;
+
+// Home base at origin (0,0,0). Pulsing glow indicates core objective.
+
+class Base extends Entity {
+    public var glowIntensity:Float = 0.0;
+
+    public function new(game:Game) {
+        super(game, new HexCoord(0, 0, 0));
+    }
+
+    override public function update(dt:Float):Void {
+        glowIntensity = 0.5 + 0.5 * Math.sin(haxe.Timer.stamp() * 2);
+    }
+}
```

```diff
--- /dev/null
+++ b/src/Game.hx
@@ -0,0 +1,35 @@
+import entities.*;
+
+// Central game state hub. Manages entities with add/remove queues to prevent concurrent modification during iteration.
+
+class Game {
+    public var entities:Array<Entity> = [];
+    var addQueue:Array<Entity> = [];
+    var removeQueue:Array<Entity> = [];
+
+    public function new() {}
+
+    public function addEntity(entity:Entity):Void {
+        addQueue.push(entity);
+    }
+
+    public function removeEntity(entity:Entity):Void {
+        removeQueue.push(entity);
+    }
+
+    public function update(dt:Float):Void {
+        for (entity in entities) {
+            if (entity.alive) {
+                entity.update(dt);
+            }
+        }
+        processQueues();
+    }
+
+    // Applies queued add/remove operations after entity update loop completes. Prevents concurrent modification.
+    function processQueues():Void {
+        for (entity in addQueue) {
+            entities.push(entity);
+        }
+        for (entity in removeQueue) {
+            entities.remove(entity);
+        }
+        addQueue = [];
+        removeQueue = [];
+    }
+}
```

```diff
--- a/src/Main.hx
+++ b/src/Main.hx
@@ -1,10 +1,13 @@
 import grid.*;
 import render.*;
+import entities.*;

 class Main extends hxd.App {
     var grid:HexGrid;
     var hexRenderer:HexRenderer;
+    var game:Game;

     override function init() {
         s2d.setFixedSize(1920, 1080);
@@ -12,10 +15,15 @@ class Main extends hxd.App {

         grid = new HexGrid();
         hexRenderer = new HexRenderer(s2d);
         hexRenderer.drawGrid(grid);
+
+        game = new Game();
+        var base = new Base(game);
+        game.addEntity(base);
     }

     override function update(dt:Float) {
+        game.update(dt);
     }

     static function main() {
```

---

### Milestone 5: Enemy Movement

**Files**:
- `src/entities/Enemy.hx`
- `src/render/EntityRenderer.hx`
- `src/Game.hx` (modify)

**Requirements**:
- Enemy entity with path (Array<HexCoord>), speed (1 hex/sec), position interpolation
- Enemy pathfinds from spawn position to base
- On reaching base at (0,0,0): enemy removed and Game.energy reduced by BASE_HIT_PENALTY (10 energy)
- EntityRenderer draws enemies as magenta circles with optional trail

**Acceptance Criteria**:
- Spawning enemy at (7,0,-7) walks to center over ~7 seconds
- Enemy reaching (0,0,0) disappears and deducts 10 energy from Game.energy
- Multiple enemies pathfind independently

**Tests**:
- **Test files**: `test/entities/TestEnemy.hx`
- **Test type**: unit
- **Backing**: doc-derived (GDD section 3.2)
- **Scenarios**:
  - Normal: enemy moves 1 hex per second
  - Edge: enemy reaching (0,0,0) triggers onReachBase, enemy.alive becomes false, Game.energy reduced by BASE_HIT_PENALTY (10)
  - Error: enemy with no valid path stays at spawn

**Code Intent**:
- New file `src/entities/Enemy.hx`: Extends Entity, has path:Array<HexCoord>, pathIndex:Int, progress:Float, speed from Config
- Enemy.update(dt): increment progress, when >= 1.0 advance pathIndex, if at end call onReachBase()
- Enemy.path stores individual path array (per-enemy cache). When obstacle placed, Game iterates enemies array calling Pathfinding.findPath() to recalculate each enemy's path field
- New file `src/render/EntityRenderer.hx`: Class with drawEnemy(enemy), drawTower(tower), drawSpawn(spawn) methods using h2d.Graphics
- Modify `src/Game.hx`: Add enemies:Array<Enemy>, spawnEnemy(coord) creates enemy with path from Pathfinding

**Code Changes**:

```diff
--- /dev/null
+++ b/src/entities/Enemy.hx
@@ -0,0 +1,42 @@
+package entities;
+
+import grid.*;
+
+// Enemy walks along path to base. Per-enemy path cache simplifies invalidation on obstacle changes.
+
+class Enemy extends Entity {
+    public var path:Array<HexCoord>;
+    public var pathIndex:Int = 0;
+    public var progress:Float = 0.0;
+    public var hp:Float;
+
+    public function new(game:Game, startCoord:HexCoord, path:Array<HexCoord>) {
+        super(game, startCoord);
+        this.path = path;
+        this.hp = Config.ENEMY_HP;
+    }
+
+    override public function update(dt:Float):Void {
+        if (path == null || path.length == 0) return;
+
+        progress += Config.ENEMY_SPEED * dt;
+
+        while (progress >= 1.0 && pathIndex < path.length - 1) {
+            progress -= 1.0;
+            pathIndex++;
+            coord = path[pathIndex];
+        }
+
+        if (pathIndex >= path.length - 1 && coord == new HexCoord(0, 0, 0)) {
+            onReachBase();
+        }
+    }
+
+    // BASE_HIT_PENALTY = 10 energy allows 5 hits before death at 50 starting energy (recovery tension without instant loss).
+    function onReachBase():Void {
+        game.energy -= Config.BASE_HIT_PENALTY;
+        destroy();
+    }
+
+    public function takeDamage(amount:Float):Void {
+        hp -= amount;
+        if (hp <= 0) destroy();
+    }
+}
```

```diff
--- /dev/null
+++ b/src/render/EntityRenderer.hx
@@ -0,0 +1,45 @@
+package render;
+
+import entities.*;
+import grid.HexMath;
+import h2d.Graphics;
+
+// Renders entities (enemies, towers, spawn points) to Graphics object. Cleared and redrawn each frame.
+
+class EntityRenderer {
+    var graphics:Graphics;
+
+    public function new(parent:h2d.Object) {
+        graphics = new Graphics(parent);
+    }
+
+    public function clear():Void {
+        graphics.clear();
+    }
+
+    public function drawEnemy(enemy:Enemy):Void {
+        var pos = HexMath.cubeToPixel(enemy.coord);
+        graphics.beginFill(Palette.ENEMY);
+        graphics.drawCircle(pos.x, pos.y, 8);
+        graphics.endFill();
+    }
+
+    public function drawTower(tower:Tower):Void {
+        var pos = HexMath.cubeToPixel(tower.coord);
+        graphics.beginFill(Palette.TOWER);
+        graphics.moveTo(pos.x, pos.y - 10);
+        graphics.lineTo(pos.x - 8, pos.y + 8);
+        graphics.lineTo(pos.x + 8, pos.y + 8);
+        graphics.lineTo(pos.x, pos.y - 10);
+        graphics.endFill();
+    }
+
+    public function drawSpawn(spawn:SpawnPoint):Void {
+        var pos = HexMath.cubeToPixel(spawn.coord);
+        graphics.lineStyle(2, Palette.SPAWN);
+        var size = Config.HEX_SIZE * 0.8;
+        for (i in 0...6) {
+            var angle = Math.PI / 3 * i;
+            var x = pos.x + size * Math.cos(angle);
+            var y = pos.y + size * Math.sin(angle);
+            if (i == 0) graphics.moveTo(x, y) else graphics.lineTo(x, y);
+        }
+        graphics.lineTo(pos.x + size, pos.y);
+    }
+}
```

```diff
--- a/src/Game.hx
+++ b/src/Game.hx
@@ -1,8 +1,11 @@
 import entities.*;
+import grid.*;

 class Game {
     public var entities:Array<Entity> = [];
+    public var enemies:Array<Enemy> = [];
+    public var grid:HexGrid;
+    public var energy:Float;
     var addQueue:Array<Entity> = [];
     var removeQueue:Array<Entity> = [];

-    public function new() {}
+    public function new(grid:HexGrid) {
+        this.grid = grid;
+        this.energy = Config.ENERGY_START;
+    }

     public function addEntity(entity:Entity):Void {
         addQueue.push(entity);
+        if (Std.isOfType(entity, Enemy)) {
+            enemies.push(cast entity);
+        }
     }

     public function removeEntity(entity:Entity):Void {
         removeQueue.push(entity);
+        if (Std.isOfType(entity, Enemy)) {
+            enemies.remove(cast entity);
+        }
     }

+    public function spawnEnemy(coord:HexCoord):Void {
+        var goal = new HexCoord(0, 0, 0);
+        var path = Pathfinding.findPath(grid, coord, goal);
+        if (path != null) {
+            var enemy = new Enemy(this, coord, path);
+            addEntity(enemy);
+        }
+    }
+
     public function update(dt:Float):Void {
```

---

### Milestone 6: Tower Combat

**Files**:
- `src/entities/Tower.hx`
- `src/Game.hx` (modify)
- `src/render/EntityRenderer.hx` (modify)

**Requirements**:
- Tower entity with range (2 hexes), targeting (FIFO), attack state
- Tower.update(dt): find first enemy in range, deal damage until dead or exits
- Enemy HP = 1.0, Tower kills in TOWER_KILL_TIME (1 second)
- Towers are obstacles for pathfinding

**Acceptance Criteria**:
- Placing tower recalculates enemy paths around it
- Tower targets first enemy to enter range
- Enemy dies after 1 second in tower range

**Tests**:
- **Test files**: `test/entities/TestTower.hx`
- **Test type**: unit
- **Backing**: doc-derived (GDD section 3.2)
- **Scenarios**:
  - Normal: tower kills enemy in 1 second
  - Edge: enemy exits range, tower retargets next enemy
  - Error: no enemies in range, tower idles

**Code Intent**:
- New file `src/entities/Tower.hx`: Extends Entity, has range:Int, target:Enemy, attackProgress:Float
- Tower.update(dt): if no target, find first enemy within HexMath.distance <= range; if target, increment attackProgress, kill at 1.0
- Modify `src/Game.hx`: Add towers:Array<Tower>, placeTower(coord) adds obstacle to grid, recalculates all enemy paths
- Modify `src/render/EntityRenderer.hx`: Add drawTower() as cyan triangle

**Code Changes**:

```diff
--- /dev/null
+++ b/src/entities/Tower.hx
@@ -0,0 +1,42 @@
+package entities;
+
+import grid.*;
+
+// Tower with FIFO targeting (first-enemy-in-range). Simpler and more predictable than nearest/weakest targeting.
+
+class Tower extends Entity {
+    public var range:Int;
+    public var target:Enemy = null;
+    public var attackProgress:Float = 0.0;
+
+    public function new(game:Game, coord:HexCoord) {
+        super(game, coord);
+        this.range = Config.TOWER_RANGE;
+    }
+
+    override public function update(dt:Float):Void {
+        if (target == null || !target.alive || HexMath.distance(coord, target.coord) > range) {
+            target = acquireTarget();
+            attackProgress = 0.0;
+        }
+
+        if (target != null && target.alive) {
+            attackProgress += dt;
+            if (attackProgress >= Config.TOWER_KILL_TIME) {
+                target.takeDamage(Config.ENEMY_HP);
+                target = null;
+                attackProgress = 0.0;
+            }
+        }
+    }
+
+    // FIFO targeting: returns first alive enemy within range. Consistent player expectations; advanced targeting deferred.
+    function acquireTarget():Null<Enemy> {
+        for (enemy in game.enemies) {
+            if (!enemy.alive) continue;
+            if (HexMath.distance(coord, enemy.coord) <= range) {
+                return enemy;
+            }
+        }
+        return null;
+    }
+}
```

```diff
--- a/src/Game.hx
+++ b/src/Game.hx
@@ -4,6 +4,7 @@ import grid.*;
 class Game {
     public var entities:Array<Entity> = [];
     public var enemies:Array<Enemy> = [];
+    public var towers:Array<Tower> = [];
     public var grid:HexGrid;
     public var energy:Float;
     var addQueue:Array<Entity> = [];
@@ -18,6 +19,9 @@ class Game {
         addQueue.push(entity);
         if (Std.isOfType(entity, Enemy)) {
             enemies.push(cast entity);
+        }
+        if (Std.isOfType(entity, Tower)) {
+            towers.push(cast entity);
         }
     }

@@ -25,6 +29,9 @@ class Game {
         removeQueue.push(entity);
         if (Std.isOfType(entity, Enemy)) {
             enemies.remove(cast entity);
+        }
+        if (Std.isOfType(entity, Tower)) {
+            towers.remove(cast entity);
         }
     }

@@ -37,6 +44,19 @@ class Game {
         }
     }

+    public function placeTower(coord:HexCoord):Bool {
+        if (energy < Config.TOWER_COST) return false;
+        if (!Pathfinding.validatePlacement(grid, coord)) return false;
+
+        energy -= Config.TOWER_COST;
+        grid.setObstacle(coord, true);
+        var tower = new Tower(this, coord);
+        addEntity(tower);
+
+        recalculateEnemyPaths();
+        return true;
+    }
+
+    // Iterates enemies and recalculates individual paths. No global cache deduplication (acceptable at 200-hex scale with <50 enemies).
+    function recalculateEnemyPaths():Void {
+        var goal = new HexCoord(0, 0, 0);
+        for (enemy in enemies) {
+            if (!enemy.alive) continue;
+            enemy.path = Pathfinding.findPath(grid, enemy.coord, goal);
+            enemy.pathIndex = 0;
+        }
+    }
+
     public function update(dt:Float):Void {
```

---

### Milestone 7: Energy Economy

**Files**:
- `src/Config.hx` (modify)
- `src/Game.hx` (modify)
- `src/render/UIRenderer.hx`

**Requirements**:
- Energy state: current, max (100), start (50)
- Entropy: base drain (1.0/sec), growth (0.1 per 10 seconds)
- Energy formula: delta = (aliveEnemies * 0.5) - entropy
- Game over when energy <= 0

**Acceptance Criteria**:
- With 0 enemies, energy drops ~1/sec
- With 3 enemies, energy rises (1.5 - entropy)
- Game.gameOver flag triggers when energy hits 0

**Tests**:
- **Test files**: `test/TestEnergySystem.hx`
- **Test type**: unit
- **Backing**: doc-derived (GDD section 3.1)
- **Scenarios**:
  - Normal: 2 enemies, entropy 1.0 -> net 0/sec
  - Edge: 0 enemies -> negative drain
  - Error: energy at 0 triggers gameOver flag

**Code Intent**:
- Modify `src/Config.hx`: Add ENERGY_MAX, ENERGY_START, ENTROPY_BASE, ENTROPY_GROWTH, ENEMY_ENERGY_VALUE, BASE_HIT_PENALTY
- Modify `src/Game.hx`: Add energy:Float, entropy:Float, elapsedTime:Float, gameOver:Bool, updateEnergy(dt) method
- New file `src/render/UIRenderer.hx`: Class with drawEnergyBar(energy, max), drawGameOver(survivalTime)

**Code Changes**:

Config.hx already has all required constants from Milestone 1.

```diff
--- a/src/Game.hx
+++ b/src/Game.hx
@@ -7,11 +7,14 @@ class Game {
     public var towers:Array<Tower> = [];
     public var grid:HexGrid;
     public var energy:Float;
+    public var entropy:Float;
+    public var elapsedTime:Float = 0.0;
+    public var gameOver:Bool = false;
     var addQueue:Array<Entity> = [];
     var removeQueue:Array<Entity> = [];

     public function new(grid:HexGrid) {
         this.grid = grid;
         this.energy = Config.ENERGY_START;
+        this.entropy = Config.ENTROPY_BASE;
     }

@@ -67,6 +70,22 @@ class Game {
     }

     public function update(dt:Float):Void {
+        elapsedTime += dt;
+        entropy = Config.ENTROPY_BASE + (elapsedTime / 10.0) * Config.ENTROPY_GROWTH;
+
         for (entity in entities) {
             if (entity.alive) {
                 entity.update(dt);
             }
         }
         processQueues();
+
+        updateEnergy(dt);
+    }
+
+    // Counts enemies with alive flag set (includes queued-for-removal but not yet processed).
+    function countAliveEnemies():Int {
+        var count = 0;
+        for (enemy in enemies) {
+            if (enemy.alive) count++;
+        }
+        return count;
+    }
+
+    // Energy formula: delta = (aliveEnemies * 0.5) - entropy. Hard cap at ENERGY_MAX prevents runaway accumulation (forces active play).
+    function updateEnergy(dt:Float):Void {
+        var aliveEnemies = countAliveEnemies();
+        var delta = (aliveEnemies * Config.ENEMY_ENERGY_VALUE) - entropy;
+        energy += delta * dt;
+
+        if (energy <= 0) {
+            energy = 0;
+            gameOver = true;
+        }
+        // Hard cap (not just display cap) forces spending rather than hoarding energy. Players risk waste if cap reached.
+        if (energy > Config.ENERGY_MAX) {
+            energy = Config.ENERGY_MAX;
+        }
+    }
```

```diff
--- /dev/null
+++ b/src/render/UIRenderer.hx
@@ -0,0 +1,38 @@
+package render;
+
+import h2d.Text;
+import h2d.Graphics;
+
+// Renders UI elements: energy bar, game over screen, flow indicator, warnings.
+
+class UIRenderer {
+    var graphics:Graphics;
+    var text:Text;
+
+    public function new(parent:h2d.Object) {
+        graphics = new Graphics(parent);
+        text = new Text(hxd.res.DefaultFont.get(), parent);
+        text.textColor = Palette.UI_TEXT;
+    }
+
+    public function drawEnergyBar(energy:Float, max:Float):Void {
+        graphics.clear();
+        graphics.lineStyle(2, Palette.UI_TEXT);
+        graphics.drawRect(10, 10, 200, 20);
+
+        var fillWidth = (energy / max) * 200;
+        graphics.beginFill(0x00ff00);
+        graphics.drawRect(10, 10, fillWidth, 20);
+        graphics.endFill();
+
+        text.text = 'Energy: ${Math.floor(energy)}/${max}';
+        text.x = 10;
+        text.y = 35;
+    }
+
+    public function drawGameOver(survivalTime:Float):Void {
+        text.text = 'GAME OVER\nSurvival: ${Math.floor(survivalTime)}s';
+        text.x = 800;
+        text.y = 500;
+        text.textAlign = Center;
+    }
+}
```

---

### Milestone 8: Spawn Points

**Files**:
- `src/entities/SpawnPoint.hx`
- `src/Game.hx` (modify)
- `src/render/EntityRenderer.hx` (modify)

**Requirements**:
- SpawnPoint entity with spawn timer (3 seconds), spawn count limit (5), time limit (30 seconds)
- Player places spawn points, costs 15 energy
- Spawn points are obstacles (enemies path around)
- Spawn points are permanent until natural expiration (cannot be removed by player or tower)
- Tower cannot be placed on spawn point (placement blocked)
- Spawn point expires after 5 enemies spawned OR 30 seconds elapsed (whichever first)

**Acceptance Criteria**:
- Placing spawn point deducts 15 energy
- Enemy spawns every 3 seconds from each spawn point
- Spawn point expires and disappears after spawning 5 enemies
- Tower placement blocked on hex containing spawn point
- Cannot place spawn if would block all paths

**Tests**:
- **Test files**: `test/entities/TestSpawnPoint.hx`
- **Test type**: unit
- **Backing**: doc-derived (GDD section 3.2)
- **Scenarios**:
  - Normal: spawn timer triggers every 3 seconds
  - Edge: spawn expires after 5 enemies spawned
  - Edge: spawn expires after 30 seconds even if fewer than 5 enemies spawned
  - Error: cannot place spawn if would block any hex from reaching origin
  - Error: cannot place tower on hex containing spawn point

**Code Intent**:
- New file `src/entities/SpawnPoint.hx`: Extends Entity, has spawnTimer:Float, spawnCount:Int, lifetime:Float, interval/countLimit/timeLimit from Config
- SpawnPoint.update(dt) execution order: (1) increment lifetime by dt; (2) check lifetime >= timeLimit OR spawnCount >= countLimit, if true set alive=false and return; (3) decrement spawnTimer by dt; (4) if timer <= 0 spawn enemy, increment count, reset timer. This ensures count limit is strictly enforced even if timer expires simultaneously
- Modify `src/Game.hx`: Add spawns:Array<SpawnPoint>, placeSpawn(coord) with cost deduction, grid invariant check; placeTower blocks if spawn exists at coord
- Modify `src/render/EntityRenderer.hx`: Add drawSpawn() as orange hexagon outline with remaining count indicator

**Code Changes**:

```diff
--- /dev/null
+++ b/src/entities/SpawnPoint.hx
@@ -0,0 +1,35 @@
+package entities;
+
+import grid.HexCoord;
+
+// Spawns enemies at intervals until count or time limit reached. Permanent until natural expiration (cannot be destroyed by player/tower).
+
+class SpawnPoint extends Entity {
+    public var spawnTimer:Float;
+    public var spawnCount:Int = 0;
+    public var lifetime:Float = 0.0;
+
+    public function new(game:Game, coord:HexCoord) {
+        super(game, coord);
+        this.spawnTimer = Config.SPAWN_INTERVAL;
+    }
+
+    // Execution order ensures count limit strictly enforced: (1) check expiration before spawning; (2) spawn increments count; (3) count checked next frame.
+    // This prevents spawning 6th enemy if timer expires simultaneously with 5th spawn.
+    override public function update(dt:Float):Void {
+        lifetime += dt;
+
+        if (lifetime >= Config.SPAWN_TIME_LIMIT || spawnCount >= Config.SPAWN_COUNT_LIMIT) {
+            destroy();
+            return;
+        }
+
+        spawnTimer -= dt;
+
+        if (spawnTimer <= 0) {
+            game.spawnEnemy(coord);
+            spawnCount++;
+            spawnTimer = Config.SPAWN_INTERVAL;
+        }
+    }
+}
```

```diff
--- a/src/Game.hx
+++ b/src/Game.hx
@@ -6,6 +6,7 @@ class Game {
     public var enemies:Array<Enemy> = [];
     public var towers:Array<Tower> = [];
+    public var spawns:Array<SpawnPoint> = [];
     public var grid:HexGrid;
     public var energy:Float;
     public var entropy:Float;
@@ -24,6 +25,9 @@ class Game {
         if (Std.isOfType(entity, Tower)) {
             towers.push(cast entity);
         }
+        if (Std.isOfType(entity, SpawnPoint)) {
+            spawns.push(cast entity);
+        }
     }

     public function removeEntity(entity:Entity):Void {
@@ -33,6 +37,9 @@ class Game {
         }
         if (Std.isOfType(entity, Tower)) {
             towers.remove(cast entity);
+        }
+        if (Std.isOfType(entity, SpawnPoint)) {
+            spawns.remove(cast entity);
         }
     }

@@ -47,6 +54,10 @@ class Game {

     public function placeTower(coord:HexCoord):Bool {
         if (energy < Config.TOWER_COST) return false;
+        for (spawn in spawns) {
+            if (spawn.coord == coord && spawn.alive) return false;
+        }
         if (!Pathfinding.validatePlacement(grid, coord)) return false;

         energy -= Config.TOWER_COST;
@@ -58,6 +69,22 @@ class Game {
         return true;
     }

+    public function placeSpawn(coord:HexCoord):Bool {
+        if (energy < Config.SPAWN_COST) return false;
+        for (tower in towers) {
+            if (tower.coord == coord && tower.alive) return false;
+        }
+        if (!Pathfinding.validatePlacement(grid, coord)) return false;
+
+        energy -= Config.SPAWN_COST;
+        grid.setObstacle(coord, true);
+        var spawn = new SpawnPoint(this, coord);
+        addEntity(spawn);
+
+        recalculateEnemyPaths();
+        return true;
+    }
+
     function recalculateEnemyPaths():Void {
```

EntityRenderer.drawSpawn() was already added in Milestone 5.

---

### Milestone 9: Input & Placement UI

**Files**:
- `src/input/PlacementController.hx`
- `src/render/UIRenderer.hx` (modify)
- `src/Main.hx` (modify)

**Requirements**:
- Right-click toggles tower placement mode, left-click to place
- Left-click toggles spawn placement mode, right-click to place
- Placement preview: ghost entity on hovered hex
- Red X if placement invalid (not enough energy, blocks paths)
- Cost display near cursor during placement mode

**Acceptance Criteria**:
- Right-click enters tower mode, shows cyan ghost on hover
- Left-click in tower mode places tower if valid
- Invalid placement shows red X overlay
- Clicking opposite button cancels current mode

**Tests**:
- Skip unit tests (input is visual/behavioral)
- **Backing**: user-specified (manual playtest)

**Code Intent**:
- New file `src/input/PlacementController.hx`: Class with mode:PlacementMode (NONE, TOWER, SPAWN), hoveredCoord:HexCoord
- PlacementController handles hxd.Window mouse events, calls Game.placeTower/placeSpawn on valid clicks
- Modify `src/render/UIRenderer.hx`: Add drawPlacementPreview(coord, mode, valid), drawPlacementCost(cost, canAfford)
- Modify `src/Main.hx`: Create PlacementController, connect to mouse events

**Code Changes**:

```diff
--- /dev/null
+++ b/src/input/PlacementController.hx
@@ -0,0 +1,47 @@
+package input;
+
+import grid.*;
+
+enum PlacementMode {
+    NONE;
+    TOWER;
+    SPAWN;
+}
+
+// Handles placement UI: mode toggling, hover preview, click-to-place validation.
+
+class PlacementController {
+    public var mode:PlacementMode = NONE;
+    public var hoveredCoord:Null<HexCoord> = null;
+    var game:Game;
+    var grid:HexGrid;
+
+    public function new(game:Game, grid:HexGrid) {
+        this.game = game;
+        this.grid = grid;
+    }
+
+    public function onMouseMove(x:Float, y:Float):Void {
+        hoveredCoord = HexMath.pixelToCube(x, y);
+        if (!grid.isValidCoord(hoveredCoord)) {
+            hoveredCoord = null;
+        }
+    }
+
+    public function onLeftClick():Void {
+        if (mode == TOWER && hoveredCoord != null) {
+            if (game.placeTower(hoveredCoord)) {
+                mode = NONE;
+            }
+        } else if (mode == NONE) {
+            mode = SPAWN;
+        }
+    }
+
+    public function onRightClick():Void {
+        if (mode == SPAWN && hoveredCoord != null) {
+            if (game.placeSpawn(hoveredCoord)) {
+                mode = NONE;
+            }
+        } else if (mode == NONE) {
+            mode = TOWER;
+        }
+    }
+}
```

```diff
--- a/src/render/UIRenderer.hx
+++ b/src/render/UIRenderer.hx
@@ -2,10 +2,14 @@ package render;

 import h2d.Text;
 import h2d.Graphics;
+import grid.*;
+import input.PlacementMode;

 class UIRenderer {
     var graphics:Graphics;
     var text:Text;

     public function new(parent:h2d.Object) {
         graphics = new Graphics(parent);
@@ -35,4 +39,31 @@ class UIRenderer {
         text.textAlign = Center;
     }
+
+    public function drawPlacementPreview(coord:HexCoord, mode:PlacementMode, valid:Bool):Void {
+        var pos = HexMath.cubeToPixel(coord);
+        graphics.lineStyle(2, valid ? 0x00ff00 : 0xff0000);
+
+        switch (mode) {
+            case TOWER:
+                graphics.drawCircle(pos.x, pos.y, 10);
+            case SPAWN:
+                graphics.drawRect(pos.x - 10, pos.y - 10, 20, 20);
+            case NONE:
+        }
+
+        if (!valid) {
+            graphics.lineStyle(3, Palette.WARNING);
+            graphics.moveTo(pos.x - 10, pos.y - 10);
+            graphics.lineTo(pos.x + 10, pos.y + 10);
+            graphics.moveTo(pos.x + 10, pos.y - 10);
+            graphics.lineTo(pos.x - 10, pos.y + 10);
+        }
+    }
+
+    public function drawPlacementCost(cost:Int, canAfford:Bool):Void {
+        text.textColor = canAfford ? Palette.UI_TEXT : Palette.WARNING;
+        text.text = 'Cost: $cost';
+        text.x = hxd.Window.getInstance().mouseX + 20;
+        text.y = hxd.Window.getInstance().mouseY;
+    }
 }
```

```diff
--- a/src/Main.hx
+++ b/src/Main.hx
@@ -1,12 +1,15 @@
 import grid.*;
 import render.*;
 import entities.*;
+import input.*;

 class Main extends hxd.App {
     var grid:HexGrid;
     var hexRenderer:HexRenderer;
     var game:Game;
+    var placementController:PlacementController;

     override function init() {
         s2d.setFixedSize(1920, 1080);
@@ -14,11 +17,18 @@ class Main extends hxd.App {

         grid = new HexGrid();
         hexRenderer = new HexRenderer(s2d);
         hexRenderer.drawGrid(grid);

-        game = new Game();
+        game = new Game(grid);
         var base = new Base(game);
         game.addEntity(base);
+
+        placementController = new PlacementController(game, grid);
+
+        s2d.addEventListener(onEvent);
     }

+    function onEvent(event:hxd.Event):Void {
+        placementController.onMouseMove(event.relX, event.relY);
+        if (event.kind == EPush && event.button == 0) placementController.onLeftClick();
+        if (event.kind == EPush && event.button == 1) placementController.onRightClick();
+    }
+
     override function update(dt:Float) {
```

---

### Milestone 10: UI Polish & Feedback

**Files**:
- `src/render/UIRenderer.hx` (modify)
- `src/render/EffectsRenderer.hx`
- `src/Game.hx` (modify)

**Flags**:
- `needs-rationale`: Warning thresholds need justification from GDD

**Requirements**:
- Energy flow indicator: "ENEMIES: +X.X | ENTROPY: -Y.Y | NET: +Z.Z/s"
- Warning system: "NO FUEL!" at 0 enemies, vignette at 25% energy
- Death pop: "+X energy" rising text when enemy dies
- First-play message explaining "danger is fuel" mechanic

**Acceptance Criteria**:
- Flow indicator updates every frame with current rates
- NO FUEL warning appears within 3 seconds of 0 enemies
- Death pop shows total energy harvested from enemy
- First-play message visible on fresh session, clickable to dismiss
- Game over screen displays when Game.gameOver flag is true

**Tests**:
- Skip unit tests (visual validation)
- **Backing**: user-specified (manual playtest)

**Code Intent**:
- Modify `src/render/UIRenderer.hx`: Add drawFlowIndicator(enemyRate, entropyRate), drawWarnings(energy, enemyCount), drawFirstPlayMessage()
- New file `src/render/EffectsRenderer.hx`: Class managing death pops with position, value, lifetime, aggregation. Death pops aggregate within 0.3s window AND same hex position. Enemies dying at different positions show separate pops even if within time window. Aggregation shows sum of energy values at shared position. Cap of 3 simultaneous pops enforced
- Modify `src/Game.hx`: Track zeroEnemyTimer for NO FUEL warning, firstPlay:Bool flag, enemy energy accumulator for death pops

**Code Changes**:

```diff
--- a/src/render/UIRenderer.hx
+++ b/src/render/UIRenderer.hx
@@ -66,4 +66,30 @@ class UIRenderer {
         text.x = hxd.Window.getInstance().mouseX + 20;
         text.y = hxd.Window.getInstance().mouseY;
     }
+
+    public function drawFlowIndicator(enemyRate:Float, entropyRate:Float):Void {
+        var net = enemyRate - entropyRate;
+        text.text = 'ENEMIES: +${enemyRate.toFixed(1)} | ENTROPY: -${entropyRate.toFixed(1)} | NET: ${net.toFixed(1)}/s';
+        text.x = 10;
+        text.y = 60;
+        text.textColor = Palette.UI_TEXT;
+    }
+
+    // Warning thresholds: 3.0s delay prevents flicker on brief zero-enemy moments; 25% vignette provides ~15-20s recovery window at base entropy.
+    public function drawWarnings(energy:Float, enemyCount:Int, zeroEnemyTime:Float):Void {
+        if (enemyCount == 0 && zeroEnemyTime >= 3.0) {
+            text.text = 'NO FUEL!';
+            text.x = 800;
+            text.y = 400;
+            text.textColor = Palette.WARNING;
+        }
+
+        // 25% threshold triggers before critical (<10%) to allow recovery time. Too early (>30%) causes alarm fatigue.
+        if (energy / Config.ENERGY_MAX <= 0.25) {
+            graphics.beginFill(0xff0000, 0.2);
+            graphics.drawRect(0, 0, 1920, 1080);
+            graphics.endFill();
+        }
+    }
+
+    public function drawFirstPlayMessage():Void {
+        text.text = 'Danger is fuel! Place spawn points to generate energy.\nClick to dismiss.';
+        text.x = 600;
+        text.y = 300;
+        text.textColor = Palette.UI_TEXT;
+    }
 }
```

```diff
--- /dev/null
+++ b/src/render/EffectsRenderer.hx
@@ -0,0 +1,62 @@
+package render;
+
+import grid.*;
+import h2d.Text;
+
+typedef DeathPop = {
+    coord:HexCoord,
+    value:Float,
+    lifetime:Float,
+    timestamp:Float,
+    text:Text
+}
+
+// Death pop aggregation: 0.3s window (perceptual grouping research: 0.2-0.4s cognitive aggregation), cap 3 simultaneous (readability threshold).
+// Enemies at different positions show separate pops even if within time window.
+
+class EffectsRenderer {
+    var pops:Array<DeathPop> = [];
+    var font:h2d.Font;
+    var parent:h2d.Object;
+
+    public function new(parent:h2d.Object) {
+        this.parent = parent;
+        this.font = hxd.res.DefaultFont.get();
+    }
+
+    // 0.3s aggregation window: shorter (<0.2s) causes flicker perception, longer (>0.5s) delays feedback.
+    public function addDeathPop(coord:HexCoord, energyValue:Float):Void {
+        var now = haxe.Timer.stamp();
+        var aggregated = false;
+
+        for (pop in pops) {
+            if (pop.coord == coord && (now - pop.timestamp) < 0.3) {
+                pop.value += energyValue;
+                pop.timestamp = now;
+                aggregated = true;
+                break;
+            }
+        }
+
+        // Cap of 3 simultaneous pops: 4+ overlapping become unreadable, 2 or fewer loses aggregation benefit.
+        if (!aggregated) {
+            if (pops.length >= 3) {
+                var oldest = pops.shift();
+                oldest.text.remove();
+            }
+            var text = new Text(font, parent);
+            text.visible = false;
+            pops.push({
+                coord: coord,
+                value: energyValue,
+                lifetime: 0.0,
+                timestamp: now,
+                text: text
+            });
+        }
+    }
+
+    public function update(dt:Float):Void {
+        for (pop in pops.copy()) {
+            pop.lifetime += dt;
+            if (pop.lifetime > 2.0) {
+                pop.text.remove();
+                pops.remove(pop);
+            }
+        }
+    }
+
+    public function render():Void {
+        for (pop in pops) {
+            var pos = HexMath.cubeToPixel(pop.coord);
+            pop.text.text = '+${pop.value.toFixed(1)}';
+            pop.text.x = pos.x;
+            pop.text.y = pos.y - (pop.lifetime * 20);
+            pop.text.textColor = 0x00ff00;
+            pop.text.visible = true;
+        }
+    }
+}
```

```diff
--- a/src/Game.hx
+++ b/src/Game.hx
@@ -11,6 +11,8 @@ class Game {
     public var entropy:Float;
     public var elapsedTime:Float = 0.0;
     public var gameOver:Bool = false;
+    public var zeroEnemyTimer:Float = 0.0;
+    public var firstPlay:Bool = true;
     var addQueue:Array<Entity> = [];
     var removeQueue:Array<Entity> = [];

@@ -106,6 +108,13 @@ class Game {
         processQueues();

         updateEnergy(dt);
+
+        var aliveCount = countAliveEnemies();
+        if (aliveCount == 0) zeroEnemyTimer += dt;
+        else zeroEnemyTimer = 0.0;
     }

     function updateEnergy(dt:Float):Void {
```

---

### Milestone 11: Tuning & Validation

**Files**:
- `src/Config.hx` (modify)

**Requirements**:
- Playtest and adjust all parameters
- Target: supercritical state reachable in 2 minutes
- Target: typical survival 2-5 minutes
- Performance: stable 60 FPS with 30 entities

**Acceptance Criteria**:
- Player can demonstrate mechanic understanding: energy drops -> places spawn -> recovers
- Entropy growth creates escalating pressure over time
- Frame time stays under 16ms with 30 entities

**Tests**:
- **Test type**: manual playtest (5 runs minimum)
- **Backing**: user-specified
- **Scenarios**:
  - Measure time-to-first-spawn (target: <15 seconds)
  - Measure deaths-before-understanding (target: <=2)
  - Profile frame time with 30 entities

**Code Intent**:
- Modify `src/Config.hx`: Adjust parameter values based on playtest feedback
- No structural changes; tuning only

**Code Changes**:

Skip reason: tuning-only milestone, no structural code changes.

---

### Milestone 12: Documentation

**Delegated to**: @agent-technical-writer (mode: post-implementation)

**Source**: `## Invisible Knowledge` section of this plan

**Files**:
- `src/CLAUDE.md` (update)
- `src/README.md` (new)
- `src/grid/CLAUDE.md` (new)
- `src/entities/CLAUDE.md` (new)
- `src/render/CLAUDE.md` (new)

**Requirements**:
- Update CLAUDE.md files with implemented file index
- Create README.md with architecture diagram and invariants
- Document grid coordinate system and pathfinding approach
- Document entity lifecycle and add/remove queue pattern

**Acceptance Criteria**:
- CLAUDE.md is tabular index only (no prose)
- README.md captures invisible knowledge from plan
- New developer can understand architecture from reading README.md

Documentation milestone - no code changes.

## Milestone Dependencies

```
M1 (Grid) ──────┬──> M2 (Pathfinding) ───┐
                │                         │
                └──> M3 (Rendering) ──────┤
                                          │
                                          v
                                    M4 (Entity) ──────┬──> M5 (Enemy)
                                                      │
                                                      └──> M7 (Energy)
                                                             │
M5 (Enemy) ───> M6 (Tower) ───────────────────────────────────┤
                                                              │
                                                              v
                                                        M8 (Spawn) ──> M9 (Input) ──> M10 (UI) ──> M11 (Tuning)
                                                                                                        │
                                                                                                        v
                                                                                                  M12 (Docs)
```

**Parallel opportunities:**
- M2 and M3 can run in parallel after M1
- M5 and M7 can run in parallel after M4
- M6 depends on M5, M8 depends on M6+M7
