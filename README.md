# Halcyon Expanse — Godot 4.3 3D Top-Down RPG

A 3D top-down action RPG built in Godot 4.3, transpiled from the original Python Xandria engine.

## Features

- **9 Star Systems** with procedural generation and biome-specific tiles
- **7 Resonance Types** with distance-based ability cost multipliers
- **Real-time Combat** — melee attacks, 7 lattice abilities, shields
- **6 Enemy Types** with behavior state machines (phase cycle, stealth ambush, swarm split, etc.)
- **Hollowed Zones** — anti-magic areas that nullify lattice charge
- **Faction System** — 5 factions + Ashborn with reputation tracking
- **Dual Currency Economy** — Compact Scrip / Ledger Mark with floating exchange
- **Bestiary & Codex** — discover enemies and unlock lore entries
- **3D Top-Down Camera** — orthographic follow cam with dynamic lighting

## Controls

| Input | Action |
|-------|--------|
| WASD / Arrow Keys | Move |
| Space | Melee Attack |
| 1-7 | Cast Lattice Abilities |
| E | Interact |
| Esc | Pause |

## Building

### Desktop
```bash
godot --path . --editor
```

### Android APK (via GitHub Actions)
Push to `main` branch. The workflow builds and releases the APK automatically.

### Android APK (local)
1. Install Android SDK and export templates in Godot
2. Set up signing keystore in Editor Settings
3. Export → Android → Export Project

## Project Structure

```
src/
  core/          — EventBus, GameState, Engine
  entities/      — Entity, Actor, Enemy
  systems/       — Abilities, Star Systems, Factions, Economy, etc.
  world/         — TileData, WorldGenerator, TileMesh
  combat/        — CombatSystem
  player/        — PlayerController
  ui/            — HUD
scenes/
  main.tscn      — Root scene
  player.tscn    — Player character
  enemy.tscn     — Enemy base
  tile.tscn      — World tile
```

## License

MIT — Built by Taylor C. Mattheisen (Skit / Dogbytes)
