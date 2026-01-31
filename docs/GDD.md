# SUPERCRITICAL — Game Design Document & Vertical Slice Plan

## 1. Core Concept

**Supercritical** is an arcade tower defense where danger is fuel. You manage a reactor core that loses energy over time (entropy). Enemies roaming nearby generate energy—but if they reach your core, you lose energy catastrophically. Build towers to protect the core, but too many towers kill enemies too fast, starving your energy supply.

**The Question:** Can you stay in the supercritical zone—just enough danger to power your reactor, not so much that you melt down?

---

## 2. Core Loop (30 seconds)

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   PLACE SPAWN POINT ──→ ENEMIES SPAWN ──→ ENERGY RISES │
│         ↑                                      │        │
│         │                                      ↓        │
│   NEED MORE ENERGY              HAVE ENOUGH ENERGY      │
│         ↑                                      │        │
│         │                                      ↓        │
│   ENERGY FALLS ←── ENEMIES DIE ←── BUILD TOWER         │
│                                                         │
└─────────────────────────────────────────────────────────┘
                         ↓
              ENTROPY DRAINS ENERGY CONSTANTLY
              (forces the loop to accelerate)
```

**Feel:** Surfing a wave. Accelerate by adding spawns, brake by adding towers. Fall off = death.

---

## 3. Systems

### 3.1 Energy System

| Parameter | Description | Starting Value |
|-----------|-------------|----------------|
| `ENERGY_MAX` | Cap (for UI display) | 100 |
| `ENERGY_START` | Initial energy | 50 |
| `ENTROPY_BASE` | Passive drain per second | 1.0 |
| `ENTROPY_GROWTH` | Entropy increase per 10 seconds | 0.1 |
| `ENEMY_ENERGY_VALUE` | Energy per enemy alive (per second) | 0.5 |
| `BASE_HIT_PENALTY` | Energy lost when enemy reaches core | 10 |

**Energy Formula (per frame):**
```
delta_energy = (alive_enemies * ENEMY_ENERGY_VALUE) - ENTROPY
current_energy += delta_energy * dt
if current_energy <= 0: GAME OVER
```

*Note: Tower costs are one-time placement costs only (20 energy). Deferred: tower upkeep as entropy augmentation.*

### 3.2 Entities

#### Base (Core)
- Center of screen, center of hex grid
- Visual: Pulsing reactor core (glow intensity = energy level)
- No gameplay interaction—just the target

#### Spawn Point
- Placed by player on any empty hex **that has a valid path to base**
- Cost: `SPAWN_COST = 15` energy
- Spawns one enemy every `SPAWN_INTERVAL = 3` seconds
- **Destroyable:** Can be destroyed by placing a tower on it. Returns `SPAWN_RECLAIM = 5` energy.
- **Path Blocking:** Spawn points count as obstacles for pathfinding validation (cannot place if it would block the only path)
- Visual: Neon orange ring, pulses when spawning
- Shape: **Hexagon outline** (matches grid)

#### Enemy
- Spawns at spawn points, pathfinds to base
- On reaching base: removed, player loses `BASE_HIT_PENALTY` energy
- While alive: contributes `ENEMY_ENERGY_VALUE` per second
- Speed: `ENEMY_SPEED = 1` hex per second
- Visual: Bright magenta moving dot with trail
- Shape: **Circle** (distinct from hexagons)

#### Tower
- Placed by player on any empty hex (or on spawn point to destroy it)
- Cost: `TOWER_COST = 20` energy (one-time, no upkeep)
- Attacks enemies within `TOWER_RANGE = 2` hexes
- **Targeting:** FIFO (first enemy to enter range). Deferred: per-tower-type targeting, configurable behavior.
- Damage: Kills enemy in `TOWER_KILL_TIME = 1` second (single target, continuous attack until dead or exits range)
- Visual: Cyan sharp geometric shape, muzzle flash on attack
- Shape: **Triangle** (aggressive, distinct)

### 3.3 Pathfinding

- A* on hex grid
- Towers AND spawn points are obstacles (enemies path around)
- **Grid Invariant:** Every hex must have a valid path to the base at all times
- **Placement Validation:** Neither towers nor spawn points can be placed if they would violate the grid invariant. During placement, show preview of affected paths. If placement would block any hex's path to base, show red X and prevent placement.
- Recalculate paths when towers/spawns placed/removed

**Coordinate System:**
- Cube coordinates (q, r, s where q + r + s = 0)
- Pointy-top hex orientation
- Base at origin (0, 0, 0), grid extends outward

---

## 4. Visual Design Language

**Aesthetic:** Neon-on-dark (dark background, bright entities)

| Element | Color | Meaning |
|---------|-------|---------|
| Background | Near-black (#0a0a12) | Void, emptiness |
| Hex grid lines | Dim cyan (#1a3a4a) | Structure, barely visible |
| Base core | White/yellow pulsing | Life, energy source |
| Enemies | Bright magenta (#ff00ff) | Danger AND fuel (dual nature) |
| Towers | Cyan (#00ffff) | Control, technology |
| Spawn points | Orange (#ff8800) | Investment, potential |
| Energy bar | Gradient green→yellow→red | Health bar metaphor |

### Visual Inversion (Important)
Unlike typical games where brightness signals danger, Supercritical uses brightness to signal energy/safety:
- **Bright screen** (many enemies) = High energy = Healthy but risky
- **Dim screen** (few enemies) = Low energy = DANGER

This inversion supports the "danger is fuel" theme. Consider early-game tooltip: *"Enemies are your fuel—keep them alive!"*

---

## 5. UI Elements

### 5.1 Energy Bar
- Horizontal bar, top of screen
- Shows current energy / max
- Color shifts: green (healthy) → yellow (warning) → red (critical)
- Numeric display of energy value

### 5.2 Energy Flow Indicator
- Shows income vs. outgo in real-time
- Format: Large, color-coded with explicit labels:
  ```
  ENEMIES: +3.5 ▲ | ENTROPY: -2.1 ▼ | NET: +1.4/s
  ```
- **Visual feedback:**
  - NET positive: Pulsing green text
  - NET negative: Pulsing red text
- Critical for player to understand their situation

### 5.3 Input Controls
- **Right-click:** Toggle tower placement mode. Right-click on hex to place tower. Left-click to cancel.
- **Left-click:** Toggle spawn point placement mode. Left-click on hex to place spawn. Right-click to cancel.
- **Placement preview:** Show ghost of entity on hovered hex. Red X if invalid placement.
- **Cost display:** Show cost near cursor during placement mode. Grey out if insufficient energy.

### 5.4 Warning System
- **At 0 enemies for 3+ seconds:** Display "NO FUEL!" warning above energy bar (highest priority)
- At 25% energy: Screen edge vignette pulses red
- At 10% energy: Warning tone plays, energy bar flashes
- At 5% energy: Screen shake, urgent alarm
- Below 5%: Continuous alarm until recovery or death

### 5.5 Death Pop Feedback
- When enemy dies, display "+X Energy" rising from death location
- **X = total energy harvested** during enemy's lifetime (not a death bonus)
- Color: Green (matches energy gain)
- Duration: 0.8 seconds, fades out
- Aggregate nearby pops after 0.3s to prevent clutter (cap at 3 simultaneous)
- **Purpose:** Shows total energy harvested from this enemy before tower eliminated it
- **Deferred enhancement:** Multiply by proximity bonus (closer kills = higher multiplier)

### 5.6 Game Over
- Display survival time prominently
- "MELTDOWN" text
- **Recovery tip:** "Tip: More enemies = more power. Place spawn points early!"
- Restart button

### 5.7 First-Play Message (Required)
On first session only, display centered text before gameplay:
```
YOUR REACTOR NEEDS DANGER TO SURVIVE.
Enemies generate power. Towers protect you.
Balance both—or melt down.

[Click anywhere to begin]
```
This message is **mandatory** for the vertical slice. The inverted mechanic requires explicit framing to overcome genre conditioning.

---

## 6. Win/Lose Conditions

**Lose:** Energy reaches 0. Game over screen shows survival time.

**Win:** There is no win. Arcade game—goal is high score (survival time).

**Scoring:** Time survived, displayed prominently during play and on game over.

---

## 7. Vertical Slice Specification

### 7.1 IN (Must Have)

| System | Minimum Spec |
|--------|--------------|
| Hex grid | 15x15 hex grid, cube coordinates, pointy-top, base at origin |
| Base | Center hex (0,0,0), pulsing glow |
| Energy | Working economy with all parameters (no tower upkeep) |
| Spawn Point | One type, player placeable, requires valid path, counts as obstacle |
| Enemy | One type, pathfinds to base, contributes energy while alive |
| Tower | One type, FIFO targeting, kills enemies in range |
| Pathfinding | A* on hex grid with tower AND spawn obstacles, grid invariant enforced |
| UI | Energy bar, flow indicator, warning system, death pops (shows lifetime harvest) |
| Input | Direct click: right-click=tower mode, left-click=spawn mode, opposite click cancels |
| First-play message | Mandatory onboarding text explaining inverted mechanic |
| Game over tip | "More enemies = more power" recovery hint |
| Telemetry | Log action sequences for validation metrics |

### 7.2 OUT (Deferred)

| Feature | Rationale |
|---------|-----------|
| Multiple tower types | One type proves the loop |
| Multiple enemy types | One type proves the loop |
| Sound/music | Polish, not core loop |
| Advanced particle effects | Glow shaders sufficient |
| Save/load | Arcade game, sessions are short |
| Menus/title screen | Start directly into gameplay |
| Full tutorial | First-play message + death tip is sufficient for vertical slice |
| Pause | Not needed for initial testing |
| Proximity-based energy | Validate flat-rate loop first (see §12) |
| Scaled base hit penalties | Depends on proximity system |
| Enemy aura visualization | Enhancement for proximity feedback |
| Build buttons UI | Direct-click input is more efficient |
| Tower upkeep costs | Flat placement cost for vertical slice |
| Advanced tower targeting | FIFO is sufficient; per-type targeting is enhancement |
| Movement-gated energy | Grid invariant prevents trapping instead |

### 7.3 Success Criteria

The vertical slice is successful when:
1. Player can place spawn points and towers
2. Enemies spawn, walk toward base, get killed by towers
3. Energy rises/falls based on enemy count and entropy
4. Player demonstrates understanding of inversion by intentionally placing spawn point after observing energy decline (testable via action sequence: energy drops → player places spawn → energy recovers)
5. Game ends when energy hits 0
6. Time survived is displayed

**Validation metrics to track:**
- Time to first spawn point placement (target: <15 seconds after first-play message)
- Deaths before mechanic understanding (target: ≤2 deaths before recovery attempt)

---

## 8. Technical Implementation

### 8.1 File Structure

```
src/
├── Main.hx              # Entry point, game loop
├── Game.hx              # Game state, energy system
├── Config.hx            # All tuning parameters
├── grid/
│   ├── HexCoord.hx      # Cube coordinates (q, r, s)
│   ├── HexMath.hx       # Conversions, neighbors, distance
│   ├── HexGrid.hx       # Grid data structure, invariant enforcement
│   └── Pathfinding.hx   # A* implementation
├── entities/
│   ├── Entity.hx        # Base class
│   ├── Base.hx          # Player's core
│   ├── SpawnPoint.hx    # Enemy spawner
│   ├── Enemy.hx         # Walking entity
│   └── Tower.hx         # Defensive structure
├── render/
│   ├── HexRenderer.hx   # Single Graphics for grid (dark + dim lines)
│   ├── EntityRenderer.hx # Renders all entities (shapes + glow)
│   └── UIRenderer.hx    # Energy bar, buttons, warnings
└── shaders/
    └── GlowShader.hx    # Neon glow effect for entities
```

### 8.2 Technical Decisions (from Prior Analysis)

| Decision | Application |
|----------|-------------|
| Single Graphics instance | `HexRenderer` owns one Graphics for entire grid |
| Hybrid shader approach | `addShader()` for entity tints; `filter.Glow` for base pulse |
| Shape differentiation | Hexagon=spawn, Circle=enemy, Triangle=tower |
| Neon on dark | Background #0a0a12, bright entity colors, Glow filter |

### 8.3 Rendering Layers (Z-Order)

1. **Background** (z=0): Dark fill
2. **Grid lines** (z=1): Dim cyan hex outlines
3. **Spawn points** (z=2): Orange hexagon outlines
4. **Enemies** (z=3): Magenta circles with trails
5. **Towers** (z=4): Cyan triangles
6. **Base** (z=5): White/yellow glow at center
7. **UI** (z=10): Energy bar, buttons, warnings

---

## 9. Development Sequence

### Phase A: Grid + Pathfinding (Days 1-2)
**Build:**
- `HexCoord`, `HexMath`, `HexGrid`
- A* pathfinding on hex grid
- `HexRenderer` with dark background + dim grid lines

**Validate:** Click any hex, show path from clicked hex to center

**Files:** `grid/*.hx`, `render/HexRenderer.hx`

---

### Phase B: Entities + Movement (Days 3-4)
**Build:**
- `Entity` base class with position, render
- `Enemy` with movement along path
- `Base` (static at center)
- `EntityRenderer` for basic shape rendering

**Validate:** Spawn enemy at edge, watch it walk to center, disappear

**Files:** `entities/Entity.hx`, `entities/Enemy.hx`, `entities/Base.hx`, `render/EntityRenderer.hx`

---

### Phase C: Towers + Combat (Day 5)
*Can run parallel with Phase D*

**Build:**
- `Tower` entity with range detection
- Tower attack logic (kills enemy over time)
- Path recalculation on tower placement
- Path blocking validation

**Validate:** Place tower, enemies path around, tower kills in range

**Files:** `entities/Tower.hx`, update `Pathfinding.hx`

---

### Phase D: Energy Economy (Day 6)
*Can run parallel with Phase C*

**Build:**
- Energy state in `Game.hx`
- Entropy drain (increases over time)
- Enemy energy generation (per alive enemy)
- Base hit penalty
- `Config.hx` with all parameters

**Validate:** Energy bar moves based on game state, hits 0 = game over

**Files:** `Game.hx`, `Config.hx`

---

### Phase E: Spawn Points + Placement (Day 7)
**Build:**
- `SpawnPoint` entity with spawn timer
- Placement mode (click to place spawn/tower)
- Spawn point destruction (tower placed on spawn)
- Cost deduction from energy

**Validate:** Place spawn → enemies appear → place tower → kills enemies → energy fluctuates

**Files:** `entities/SpawnPoint.hx`, update `Game.hx`

---

### Phase F: UI + Polish (Days 8-9)
**Build:**
- `UIRenderer` with energy bar, flow indicator
- Build buttons with cost display
- Warning system (vignette, shake)
- Game over screen
- `GlowShader` for neon effects

**Validate:** Complete playable loop with feedback

**Files:** `render/UIRenderer.hx`, `shaders/GlowShader.hx`

---

### Phase G: Tuning + Testing (Day 10)
**Activities:**
- Playtest and adjust parameters in `Config.hx`
- Balance entropy rate vs enemy generation
- Tune costs for meaningful decisions
- Fix bugs

**Validate:** Game is "fun" (subjective but achievable)

---

## 10. Tuning Guide

After vertical slice is playable, tune these parameters to find fun:

| Parameter | If too low... | If too high... |
|-----------|---------------|----------------|
| `ENTROPY_BASE` | Game too easy, no pressure | Death spiral too fast |
| `ENTROPY_GROWTH` | No escalation, gets boring | Unwinnable after 2 minutes |
| `ENEMY_ENERGY_VALUE` | Need many enemies to survive | Few enemies = safe |
| `SPAWN_COST` | Spam spawn points | Never place spawn points |
| `TOWER_COST` | Spam towers | Never place towers |
| `BASE_HIT_PENALTY` | Enemy hits don't matter | One hit = death spiral |
| `TOWER_KILL_TIME` | Towers too strong | Towers useless |
| `SPAWN_INTERVAL` | Slow escalation | Overwhelming immediately |

---

## 11. Post-Vertical-Slice Roadmap

After the vertical slice is validated, consider these expansions in priority order:

1. **Sound design** — Critical for game feel
2. **Proximity-based energy** — Adds spatial strategy (see §12)
3. **Multiple tower types** — Variety in strategy
4. **Multiple enemy types** — Variety in challenge
5. **Upgrade system** — Depth
6. **Achievements/unlocks** — Retention

---

## 12. Planned Enhancement: Proximity-Based Energy

**Status:** Deferred until core loop validated. Documented here for future implementation.

**Rationale:** Adding spatial complexity before validating "danger is fuel" risks scope creep. Validate flat-rate first, then add proximity if playtesting reveals "all nest positions feel equivalent."

### 12.1 Energy Formula (When Implemented)

```
E(d) = 0.5 × (1 + k/(d+1))
```

Where:
- `d` = hex distance from base
- `k` = tuning parameter (start with k=1, yields 1.33x ratio)

| Distance | Rate (k=1) | Enemy Lifetime | Total Energy |
|----------|------------|----------------|--------------|
| d=1      | 0.75/sec   | 1 sec          | 0.75         |
| d=4      | 0.60/sec   | 4 sec          | 2.40         |
| d=7      | 0.56/sec   | 7 sec          | 3.94         |

**Note:** Rate calculated based on enemy's CURRENT distance (updated per tick), not spawn distance.

### 12.2 Scaled Base Hit Penalties (When Implemented)

| Spawn Distance | Penalty | Rationale |
|----------------|---------|-----------|
| d=1-2 (close)  | 12      | 20% above base — risky but viable at 95% kill rate |
| d=3-4 (mid)    | 10      | Standard penalty |
| d=5+ (far)     | 8       | 20% below base — safer, less rewarding |

### 12.3 Movement-Gated Energy

**Rule:** Enemies only generate energy while actively moving toward base (velocity > 0). Blocked enemies generate nothing.

**Rationale:** Prevents trap/maze exploits where enemies are held at profitable distances.

### 12.4 Visual Feedback Enhancements

**Three-layer system (when implemented):**

| Layer | Element | Details |
|-------|---------|---------|
| Ambient | Enemy aura | Color gradient: blue (far) → yellow → orange (close); size varies for colorblind |
| Event | Death pop | Already in vertical slice (§5.5) |
| Placement | Penalty zones | Concentric rings during hover: red (d≤2), yellow (d=3-4), green (d≥5) |

### 12.5 Input Model Alternative

**Deferred option:** Direct-click (right=tower, left-hold-300ms=nest)

**Why deferred:** Two-step flow (build buttons → placement mode) is more discoverable. Test current flow first; simplify only if discovery isn't an issue.

### 12.6 Implementation Trigger

Add proximity-based energy IF playtesting reveals:
- "All nest positions feel equivalent" feedback
- Players don't engage with spatial strategy
- Core loop is validated as fun but lacks depth

---

## Appendix: Color Palette (Hex Values)

```haxe
class Palette {
    // Background
    public static inline var BACKGROUND = 0x0a0a12;

    // Grid
    public static inline var GRID_LINE = 0x1a3a4a;

    // Entities
    public static inline var BASE_GLOW = 0xffffaa;
    public static inline var ENEMY = 0xff00ff;
    public static inline var TOWER = 0x00ffff;
    public static inline var SPAWN_POINT = 0xff8800;

    // UI
    public static inline var ENERGY_HEALTHY = 0x00ff88;
    public static inline var ENERGY_WARNING = 0xffff00;
    public static inline var ENERGY_CRITICAL = 0xff0044;
    public static inline var UI_TEXT = 0xffffff;
}
```
