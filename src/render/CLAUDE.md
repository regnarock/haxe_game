# render/

Rendering systems for grid, entities, UI, and visual effects.

## Files

| File | What | When to Read |
|------|------|--------------|
| `README.md` | Rendering approach, Graphics object strategy, frame order | Understanding render architecture, Graphics regeneration pattern |
| `Palette.hx` | Color constants for neon aesthetic | Adding new visual elements, understanding color scheme |
| `HexRenderer.hx` | Grid line rendering to single Graphics object | Modifying grid appearance, understanding hex drawing |
| `EntityRenderer.hx` | Enemy, Tower, SpawnPoint rendering | Customizing entity visuals, adding new entity types |
| `UIRenderer.hx` | Energy bar, flow indicator, warnings, placement preview | Modifying UI elements, understanding feedback systems |
| `EffectsRenderer.hx` | Death pop aggregation (0.3s window, 3 cap) | Understanding visual feedback, modifying effect behavior |
