# Hex Tower Defense

Haxe/Heaps hexagonal tower defense game targeting JavaScript/WebGL.

## Build Commands

| Command | Purpose |
|---------|---------|
| `make run` | Build and open in browser |
| `make watch` | Build with auto-reload on file changes |
| `make setup` | Install Haxe dependencies |
| `make clean` | Remove build artifacts |

## Files

| File | What | When to Read |
|------|------|--------------|
| `README.md` | Architecture, core mechanic, energy economy, game mechanics | Understanding Supercritical's "danger is fuel" system, hex grid, entity lifecycle |
| `Makefile` | Build targets, watch mode, setup | Modifying build process, adding new targets |
| `build.hxml` | Haxe compiler config, output path, libs | Adding libraries, changing compile flags |
| `.gitignore` | Ignored paths for git | Adding new build artifacts or temp files |

## Directories

| Directory | What | When to Read |
|-----------|------|--------------|
| `src/` | Haxe source code | Implementing game features |
| `res/` | Runtime assets (sprites, audio, data) | Adding or modifying game assets |
| `docs/` | Design documentation | Understanding game design, vertical slice scope |
| `.haxelib/` | Vendored Haxe libraries | (Skip: vendored dependencies) |

## Design Documents

| File | What | When to Read |
|------|------|--------------|
| `docs/GDD.md` | Game Design Document for Supercritical | Understanding core loop, energy economy, entity specs, development phases |
| `docs/PLAN.md` | Vertical slice implementation plan | Understanding milestones, code diffs, architectural decisions |
