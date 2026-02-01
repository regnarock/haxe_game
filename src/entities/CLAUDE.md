# entities/

Game entities with queue-based lifecycle management.

## Files

| File | What | When to Read |
|------|------|--------------|
| `README.md` | Entity lifecycle pattern, alive flag semantics, queue behavior | Understanding add/remove queues, implementing new entity types |
| `Entity.hx` | Base class with coord, alive flag, destroy() method | Understanding entity lifecycle, implementing new entity types |
| `Base.hx` | Home base at origin with pulsing glow | Modifying base behavior, visual effects |
| `Enemy.hx` | Pathfinding movement, base hit penalty, damage system | Understanding enemy behavior, path following |
| `Tower.hx` | FIFO targeting, attack progress, range checking | Understanding combat system, targeting logic |
| `SpawnPoint.hx` | Timed enemy spawning with count/time limits | Understanding spawn mechanics, expiration logic |
