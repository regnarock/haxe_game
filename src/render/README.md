# Rendering System

Rendering systems for grid, entities, UI, and visual effects using Heaps Graphics objects.

## Rendering Approach

**Single Graphics object for grid:** Grid is semi-static (changes only on placement). Regenerating ~200 hex outlines per obstacle change is O(n), acceptable for <20 placements per game. Alternative of individual hex objects rejected due to memory overhead.

**EntityRenderer cleared each frame:** Separate Graphics object cleared and redrawn each frame. Entities move frequently (enemies along path), so persistent Graphics would require per-entity objects. Clearing and redrawing is simpler.

**UI overlay rendered last:** UIRenderer draws on top of grid and entities. Energy bar, flow indicator, warnings, and placement preview composited last.

## Visual Feedback

**Death pop aggregation:** Enemies dying at same hex position within 0.3s window show single aggregated pop with summed energy value. Enemies at different positions show separate pops even if within time window.

**0.3s aggregation window:** Perceptual grouping research shows 0.2-0.4s window for cognitive aggregation. Shorter (<0.2s) causes flicker perception. Longer (>0.5s) delays feedback. 0.3s provides natural grouping without lag.

**Cap of 3 simultaneous pops:** Screen clutter threshold. 4+ overlapping pops become unreadable. 2 or fewer loses aggregation benefit. 3 balances clarity with information density.

**Warning thresholds:**
- NO FUEL warning at 0 enemies with 3.0s delay: Prevents flicker on brief zero-enemy moments.
- 25% energy vignette: Triggers before critical (<10%) to allow recovery time. Too early (>30%) causes alarm fatigue. Provides ~15-20 second recovery window at base entropy rate.

## Design Decisions

**Glow filter over custom shader:** h2d.filter.Glow provides neon effect with minimal code. Custom shader is overkill for vertical slice. Can upgrade later if needed.

**Palette.hx color constants:** Centralizes neon aesthetic colors. All rendering modules import Palette for consistent visual style.
