# Input System

Input handling for placement UI with mode toggling and preview validation.

## Input Scheme

**Left-click:**
- If in TOWER mode: place tower at hovered hex (if valid)
- If in NONE mode: toggle to SPAWN mode

**Right-click:**
- If in SPAWN mode: place spawn at hovered hex (if valid)
- If in NONE mode: toggle to TOWER mode

**Hover:** Shows placement preview at hovered hex with validation color (green = valid, red = invalid).

## Placement Validation

**Invalid placement conditions:**
- Not enough energy to afford cost
- Would violate grid invariant (block any hex from reaching origin)
- Tower placement blocked if spawn point exists at hex
- Spawn placement blocked if tower exists at hex

**Red X overlay:** Shown on hover when placement would be invalid. Prevents player from attempting invalid placements.

**Cost display:** Shows near cursor during placement mode. Color changes to red if player cannot afford.

## Design Decisions

**Mode toggling on opposite button:** Clicking opposite mouse button while in a mode cancels current mode and switches to opposite mode. Provides quick mode switching without requiring explicit cancel action.

**Placement preview on hover:** Ghost entity shown at hovered hex before placement. Provides immediate feedback on placement location and validity. Reduces placement errors.
