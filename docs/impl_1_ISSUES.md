# Implementation 1 Issues

Issues discovered during first playtest of the vertical slice.

## Issue 1: Game Renders at Wrong Scale

**Status:** Fixed

**Symptom:**
Game appears very small in browser window - the entire hex grid is visible but compressed to approximately 15% of intended size. Grid is centered, not offset.

**Root Cause:**
The canvas element in `build/index.html` has no explicit dimensions, causing the browser to assign default dimensions (~300x150 pixels). The Heaps engine then scales the 1920x1080 scene coordinate system to fit this small canvas, compressing the entire game.

**Causal Chain:**
1. Canvas element has no width/height attributes (`build/index.html:12`)
2. Browser assigns default canvas dimensions (~300x150 pixels)
3. Heaps scene uses default "Resize" scaleMode
4. Scene coordinate system (1920x1080) scales to fit tiny canvas
5. Game renders centered but at ~15% scale

**Evidence:**
| Location | Finding |
|----------|---------|
| `build/index.html:12` | `<canvas id="webgl"></canvas>` - no width/height attributes |
| `Main.hx:16` | `s2d.setFixedSize(1920, 1080)` - deprecated API, sets internal coords only |
| Heaps API | Default scaleMode is "Resize" which matches scene to canvas size |

**Solution Options:**
1. Set canvas dimensions in HTML: `<canvas id="webgl" width="1920" height="1080"></canvas>`
2. Replace deprecated `setFixedSize()` with `s2d.scaleMode = Stretch(1920, 1080)`
3. Use CSS to size canvas: `canvas { width: 100vw; height: 100vh; }`
4. Combination: CSS for responsive sizing + scaleMode for internal coordinates

**Considerations:**
- Option 1 gives fixed pixel size (may not fill window on larger displays)
- Option 2 uses modern Heaps API and handles scaling internally
- Option 3 makes canvas fill viewport but may cause aspect ratio issues
- Option 4 provides best balance of responsive layout and correct internal coordinates

---

## Issue 2: Deprecation Warning (setFixedSize)

**Status:** Fixed

**Symptom:**
Compiler warning: `setFixedSize is deprecated, use scaleMode = Stretch(w, h) instead`

**Location:** `Main.hx:16`

**Impact:** Part of Issue 1's root cause. The deprecated API doesn't properly control canvas/scene sizing.

**Solution:** Replace `s2d.setFixedSize(1920, 1080)` with `s2d.scaleMode = Stretch(1920, 1080)`

---

## Fix Applied

**Changes made:**

1. `build/index.html`:
   - Added `width="1920" height="1080"` to canvas element
   - Added CSS `width: 100vw; height: 100vh` for responsive sizing
   - Added `overflow: hidden` to body to prevent scrollbars

2. `src/Main.hx`:
   - Replaced `s2d.setFixedSize(1920, 1080)` with `s2d.scaleMode = Stretch(1920, 1080)`

Both issues resolved - game now renders at full viewport size with correct scaling.

---

## Issue 3: Hexes Render as Flat-Top Instead of Pointy-Top

**Status:** Fixed

**Symptom:**
Hexes display with horizontal edges at top and bottom (flat-top orientation) instead of vertices at top and bottom (pointy-top orientation) as specified in the design.

**Root Cause:**
The hex vertex drawing loop calculates vertex angles starting at 0° (`a = angle * i`), placing the first vertex on the horizontal axis (rightmost point). This produces flat-top hexes. Pointy-top requires starting at 30° (π/6).

**Causal Chain:**
1. Vertex angle calculation starts at 0° (`HexRenderer.hx:34`, `EntityRenderer.hx:40`)
2. First vertex placed at rightmost point of hex (angle 0°)
3. Top and bottom of each hex are flat horizontal edges
4. Hexes render in flat-top orientation instead of pointy-top

**Evidence:**
| Location | Finding |
|----------|---------|
| `HexRenderer.hx:31-34` | `var angle = Math.PI / 3; var a = angle * i;` - starts at 0° |
| `HexRenderer.hx:39` | Closes loop at `pos.x + size, pos.y` (angle 0°) |
| `EntityRenderer.hx:39-45` | Same pattern in spawn point drawing |
| `HexMath.hx:22-26` | cubeToPixel uses correct pointy-top formula (not the issue) |

**Solution Options:**
1. Add 30° (π/6) offset to angle calculation: `var a = angle * i + Math.PI / 6`
2. Update loop closing coordinate to match new starting angle

**Files Requiring Changes:**
- `src/render/HexRenderer.hx` - lines 34, 39
- `src/render/EntityRenderer.hx` - lines 40, 45

**Considerations:**
- The coordinate system (`cubeToPixel`) is already correct for pointy-top orientation
- Only the visual vertex drawing needs adjustment
- Mouse coordinate conversion will remain correct after fix

**Fix Applied:**

1. `src/render/HexRenderer.hx`:
   - Line 34: Changed `var a = angle * i;` to `var a = angle * i + Math.PI / 6;`
   - Lines 39-41: Updated closing lineTo to use calculated position at 30° instead of hardcoded (size, 0)

2. `src/render/EntityRenderer.hx`:
   - Line 40: Changed `var angle = Math.PI / 3 * i;` to `var angle = Math.PI / 3 * i + Math.PI / 6;`
   - Lines 45-47: Updated closing lineTo to use calculated position at 30° instead of hardcoded (size, 0)

Both hex grid outlines and spawn point hexagons now render with pointy-top orientation.

---

## Issue 4: `make clean` Deletes Static index.html

**Status:** Fixed

**Symptom:**
Running `make clean` followed by `make run` fails because `index.html` no longer exists. The static HTML file was stored in `build/` and got deleted along with generated artifacts.

**Root Cause:**
The `index.html` file is stored directly in `build/` alongside generated artifacts (`game.js`), and the `clean` target uses `rm -rf build/` which treats all files in that directory as disposable build outputs.

**Causal Chain:**
1. `index.html` stored in `build/` directory (same location as `game.js`)
2. `clean` target runs `rm -rf build/` (`Makefile:18`)
3. `index.html` deleted along with `game.js`
4. `make run` fails because `index.html` doesn't exist

**Evidence:**
| Location | Finding |
|----------|---------|
| `Makefile:18` | `rm -rf build/` - deletes entire directory |
| `build/` | Contains both generated `game.js` and static `index.html` |

**Fix Applied:**

1. Moved `index.html` from `build/` to project root
2. Updated `Makefile`:
   - Added `build` to `.PHONY` declaration
   - `build` target now runs `mkdir -p build` and `cp index.html build/`
   - `clean` target changed from `rm -rf build/` to `rm -f build/game.js`

Static files are now source-controlled in project root and copied to `build/` during build. Clean only removes generated artifacts.

---

## Issue 5: Grid Renders in Top-Left Corner Instead of Center

**Status:** Fixed

**Symptom:**
The hex grid appears in the top-left corner of the screen with hexes partially clipped off the left and top edges. The grid should be centered on the screen.

**Root Cause:**
`cubeToPixel()` maps hex (0,0,0) to pixel (0,0) with no screen center offset. Since the grid extends from negative to positive coordinates around the origin, and the origin is at pixel (0,0) (top-left corner), half the grid renders off-screen.

**Causal Chain:**
1. `cubeToPixel()` returns (0,0) for hex (0,0,0) (`HexMath.hx:22-26`)
2. Grid with radius 7 extends from approximately (-400,-336) to (+400,+336) in pixel space
3. Pixels with negative coordinates are clipped by the viewport
4. Only the positive-coordinate portion of the grid is visible (top-left quadrant)

**Evidence:**
| Location | Finding |
|----------|---------|
| `HexMath.hx:22-26` | `cubeToPixel()` returns raw hex-to-pixel conversion with no offset |
| `HexMath.hx:29-33` | `pixelToCube()` also has no offset, so mouse input would need matching fix |
| Screenshot | Grid visible in top-left, "NO FUEL" text centered at (960, ~400) |

**Fix Applied:**

1. `src/Config.hx`:
   - Added `SCREEN_WIDTH = 1920`, `SCREEN_HEIGHT = 1080`
   - Added `SCREEN_CENTER_X = 960`, `SCREEN_CENTER_Y = 540`

2. `src/grid/HexMath.hx`:
   - `cubeToPixel()`: Added `+ Config.SCREEN_CENTER_X/Y` to output coordinates
   - `pixelToCube()`: Subtracted screen center before converting to hex coordinates

Grid now renders centered on the screen, and mouse input correctly maps to centered grid.

---

## Issue 6: Spawn Points Should Be Free (Design Change)

**Status:** Fixed

**Type:** Design change (not a bug)

**Original Spec:**
GDD specified `SPAWN_COST = 15` energy for placing spawn points.

**Change Requested:**
Spawn points should cost nothing to place.

**Rationale:**
Lowering the barrier to placing spawn points encourages the "danger is fuel" mechanic - players should freely experiment with spawning enemies to generate energy.

**Fix Applied:**

`src/Config.hx`:
- Changed `SPAWN_COST` from `15` to `0`

---

## Issue 7: Enemies Teleport Between Hexes Instead of Moving Smoothly

**Status:** Fixed

**Symptom:**
Enemies appear to teleport instantly from one hex to the next instead of smoothly moving between hex positions.

**Root Cause:**
`EntityRenderer.drawEnemy()` renders enemies at their discrete hex coordinate (`enemy.coord`) without using the `progress` field to interpolate between current and next hex positions.

**Causal Chain:**
1. `Enemy.progress` accumulates movement progress (0.0 to 1.0) between hexes
2. `Enemy.coord` only updates when `progress >= 1.0` (discrete jump)
3. `drawEnemy()` uses `enemy.coord` directly for pixel position
4. Enemy visually jumps from hex to hex with no interpolation

**Evidence:**
| Location | Finding |
|----------|---------|
| `Enemy.hx:10` | `progress:Float = 0.0` - interpolation factor exists |
| `Enemy.hx:22` | `progress += Config.ENEMY_SPEED * dt` - progress accumulates |
| `EntityRenderer.hx:19` | `HexMath.cubeToPixel(enemy.coord)` - uses discrete coord only |

**Fix Applied:**

`src/render/EntityRenderer.hx`:
- Modified `drawEnemy()` to interpolate pixel position between current hex and next hex using `enemy.progress`
- If enemy has a valid path and isn't at the last hex, lerp between `path[pathIndex]` and `path[pathIndex + 1]`

---

## Issue 8: UI Font Too Small to Read

**Status:** Fixed

**Symptom:**
UI text (first-play message, energy display, warnings) is displayed in a very small, thin font that is difficult to read at 1920x1080 resolution.

**Root Cause:**
`UIRenderer` uses `hxd.res.DefaultFont.get()` which is Heaps' built-in bitmap font (~12px). No scaling is applied, making the text too small for comfortable reading.

**Evidence:**
| Location | Finding |
|----------|---------|
| `UIRenderer.hx:14` | `new Text(hxd.res.DefaultFont.get(), parent)` - uses tiny default font |
| Screenshot | "Danger is fuel!" message barely legible |

**Fix Applied:**

`src/render/UIRenderer.hx`:
- Added `text.setScale(2)` in constructor to double the font size
- Added `text.smooth = false` to use nearest-neighbor filtering instead of bilinear, fixing irregular letter widths when scaled

---

## Issue 9: Placement Click Controls Reversed

**Status:** Fixed

**Symptom:**
Click controls are inconsistent - right-click enters tower mode but left-click places the tower. User expects same button for both selecting mode and placing.

**Expected Behavior:**
- Left-click → tower mode → left-click to place tower (primary action, player reflex)
- Right-click → spawn mode → right-click to place spawn

**Actual Behavior (before fix):**
- Clicks were inconsistent - mode selection and placement used different buttons

**Root Cause:**
The `attemptMode` and `toggleMode` parameters were swapped between `onLeftClick()` and `onRightClick()` in `PlacementController.hx`.

**Evidence:**
| Location | Finding |
|----------|---------|
| `PlacementController.hx:30` | `onLeftClick` had `attemptMode=TOWER` (should be SPAWN) |
| `PlacementController.hx:34` | `onRightClick` had `attemptMode=SPAWN` (should be TOWER) |

**Fix Applied:**

`src/input/PlacementController.hx`:
- `onLeftClick()`: `handlePlacementClick(TOWER, SPAWN)` - left-click for towers
- `onRightClick()`: `handlePlacementClick(SPAWN, TOWER)` - right-click for spawns
- Line 46: Changed `mode = toggleMode` to `mode = attemptMode` so clicking enters the same mode that the click will place

Final controls:
- **Left-click:** enter tower mode / place tower / cancel spawn mode
- **Right-click:** enter spawn mode / place spawn / cancel tower mode

---

## Issue 10: Death Pop Text Hard to Read

**Status:** Fixed

**Symptom:**
The "+1" text that appears when killing an enemy is too small and sometimes not fully visible or readable.

**Root Cause:**
`EffectsRenderer` creates death pop text using the default font without scaling, and positions it directly at the enemy location which can overlap with other elements.

**Evidence:**
| Location | Finding |
|----------|---------|
| `EffectsRenderer.hx:42` | `new Text(font, parent)` - no scaling applied |
| `EffectsRenderer.hx:69` | `pos.y - (pop.lifetime * 20)` - starts at enemy position, may overlap |

**Fix Applied:**

`src/render/EffectsRenderer.hx`:
- Added `text.setScale(2)` for larger, readable text
- Added `text.smooth = false` for pixel-perfect rendering
- Added `text.textAlign = Center` to center text on position
- Changed y offset from `pos.y - (pop.lifetime * 20)` to `pos.y - 20 - (pop.lifetime * 30)` to start higher and move faster

---

## Issue 11: Enemies Stutter/Backtrack When Obstacles Placed

**Status:** Fixed

**Symptom:**
When placing a tower or spawn point, enemies visually stutter or backtrack briefly before continuing on their path.

**Root Cause:**
`recalculateEnemyPaths()` resets `enemy.progress = 0.0` when recalculating paths. This causes enemies to visually snap back to the center of their current hex, losing any partial interpolation progress toward the next hex.

**Example:**
- Enemy at coord A, progress = 0.7 (70% toward coord B)
- Tower placed → path recalculated
- `progress = 0.0` → enemy visually jumps back to center of A (loses 70% progress)

**Evidence:**
| Location | Finding |
|----------|---------|
| `Game.hx:96` | `enemy.progress = 0.0` resets visual interpolation |

**Fix Applied:**

`src/Game.hx`:
- Removed `enemy.progress = 0.0` from `recalculateEnemyPaths()`
- Enemies now preserve their visual interpolation position when paths are recalculated

---

## Issue 12: Starting Energy Too Low (Design Change)

**Status:** Fixed

**Type:** Balance tuning

**Original Value:**
`ENERGY_START = 50` (50% of max)

**Issue:**
Starting energy of 50 doesn't give players enough buffer to place towers and experiment in the early game.

**Fix Applied:**

`src/Config.hx`:
- Changed `ENERGY_START` from `50` to `80` (80% of max)

---

## Issue 13: Stats Disappear When In Placement Mode

**Status:** Fixed

**Symptom:**
The flow indicator stats (ENEMIES/ENTROPY/NET) below the energy bar disappear when entering tower or spawn placement mode.

**Root Cause:**
`UIRenderer` used a single `text` object for ALL text rendering. When `drawPlacementCost()` was called during placement mode, it overwrote the flow indicator text with "Cost: X".

**Evidence:**
| Location | Finding |
|----------|---------|
| `UIRenderer.hx:10` | Single `var text:Text` used for everything |
| `UIRenderer.hx:44` | `drawFlowIndicator` sets `text.text` |
| `UIRenderer.hx:95` | `drawPlacementCost` overwrites `text.text` |

**Fix Applied:**

`src/render/UIRenderer.hx`:
- Created separate Text objects: `energyText`, `flowText`, `messageText`, `costText`
- Each UI element now uses its own dedicated text object
- `costText` visibility toggled based on placement mode

---

## Issue 14: Remove NO FUEL Warning (Design Change)

**Status:** Fixed

**Type:** Design change

**Original Behavior:**
The game displayed a "NO FUEL!" warning message after 3 seconds of having zero enemies alive. This was tracked via `zeroEnemyTimer` in `Game.hx` and displayed in `UIRenderer.drawWarnings()`.

**Change Requested:**
Remove the "NO FUEL!" warning feature entirely. The low energy red screen overlay is sufficient feedback.

**Fix Applied:**

1. `src/render/UIRenderer.hx`:
   - Removed `enemyCount` and `zeroEnemyTime` parameters from `drawWarnings()`
   - Removed "NO FUEL!" text display logic
   - Kept low energy red screen overlay (energy <= 25% of max)

2. `src/Game.hx`:
   - Removed `zeroEnemyTimer:Float` field declaration
   - Removed timer tracking code in `update()`

3. `src/Main.hx`:
   - Updated `drawWarnings()` call to pass only `game.energy`

---

## Issue 15: Placement Mode Should Stay Active After Placing

**Status:** Fixed

**Type:** Design change

**Original Behavior:**
After successfully placing a tower or spawn, the placement mode reset to NONE. Player had to click again to re-enter placement mode for each placement.

**Expected Behavior:**
Placement mode stays active after placing, allowing multiple placements in a row. Click opposite button to cancel/exit mode.

**Root Cause:**
Line 41 in `PlacementController.hx` reset `mode = NONE` after successful placement.

**Fix Applied:**

`src/input/PlacementController.hx`:
- Removed `mode = NONE` after successful placement
- Mode now stays active until player clicks opposite button to cancel

---

## Issue 16: Timer Continues After Game Over

**Status:** Fixed

**Symptom:**
When the game ends (energy reaches 0), the survival timer on the game over screen continues counting up instead of freezing at the final time.

**Root Cause:**
`Game.update()` increments `elapsedTime` without checking if `gameOver` is true. All game logic continued running after game over.

**Evidence:**
| Location | Finding |
|----------|---------|
| `Game.hx:100` | `elapsedTime += dt` runs unconditionally |
| `Game.hx:139` | `gameOver = true` set but not checked in update loop |

**Fix Applied:**

`src/Game.hx`:
- Added `if (gameOver) return;` at start of `update()` method
- All game logic now freezes when game is over

---

## Issue 17: Cost Text Too Far From Cursor

**Status:** Fixed

**Symptom:**
The "Cost: X" tooltip during placement mode appears far to the right of the cursor instead of near it.

**Root Cause:**
`drawPlacementCost()` used `hxd.Window.getInstance().mouseX/Y` which returns raw window coordinates, not scene coordinates. With the scene using `scaleMode = Stretch(1920, 1080)`, the coordinate systems don't match, causing misalignment.

**Evidence:**
| Location | Finding |
|----------|---------|
| `UIRenderer.hx:112` | Used window mouse coords + 20 offset |

**Fix Applied:**

1. `src/render/UIRenderer.hx`:
   - Changed `drawPlacementCost()` to accept hex position parameter
   - Position text relative to hovered hex (+25, -30) instead of mouse cursor

2. `src/Main.hx`:
   - Pass `HexMath.cubeToPixel(hoveredCoord)` to `drawPlacementCost()`

---

## Issue 18: Restart Text Goes Off Right Side of Screen

**Status:** Fixed

**Symptom:**
The "Press R to restart" text on the game over screen extends past the right edge of the screen.

**Root Cause:**
Text was positioned at `x = 1920 - 200` with left alignment, causing it to extend rightward off screen.

**Fix Applied:**

`src/render/UIRenderer.hx`:
- Changed `restartText.textAlign` to `Right`
- Positioned at `x = 1920 - 20` (20px padding from right edge)
- Text now anchors from right side and stays on screen

---

## Issue 19: First Play Message Doesn't Disappear on Click

**Status:** Fixed

**Symptom:**
The "Danger is fuel!" first-play message stays visible after clicking, even though `game.firstPlay` is set to false.

**Root Cause:**
When `game.firstPlay` becomes false, we stop calling `drawFirstPlayMessage()`, but the `messageText` object still displays its previous content. The text content persists because nothing clears or hides it.

**Evidence:**
| Location | Finding |
|----------|---------|
| `Main.hx:92-94` | Only calls `drawFirstPlayMessage()` when `firstPlay` is true |
| `UIRenderer.hx:95-100` | Sets text content but no visibility control |

**Fix Applied:**

1. `src/render/UIRenderer.hx`:
   - Added `messageText.visible = true` in `drawFirstPlayMessage()`
   - Added new `hideFirstPlayMessage()` method that sets `messageText.visible = false`

2. `src/Main.hx`:
   - Added else branch to call `uiRenderer.hideFirstPlayMessage()` when `firstPlay` is false
