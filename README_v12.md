# Qiongqi Boss v12 — Godot 4 gameplay prototype

This version adds a real Area2D wing weakpoint and moving Area2D tower projectiles with collision shapes and collision-layer filtering. It retains the v9 rig, six animation states, boss path, seal input, phase change, and victory/defeat flags.

## Run
Open `project.godot` with Godot 4, run `Battle.tscn`. Click the red weakpoint, A to fire an extra tower shot, D to dive, hold F after wing destruction to seal, R to restart.

## Scope and known limitations
- This package is an **engineering prototype**, not production-ready art.
- Projectile collisions currently register against the wing Area2D only; the grounded body target does not yet have its own hitbox, so shots after wing destruction can miss and despawn.
- The dive damage remains a timed animation event rather than collision-based impact.
- The wall Area2D is present for future interactions, but the boss claw still uses distance-based damage.
- The project has **not been run inside Godot** in this environment. Validate scene parsing, animation signals, and actual hit detection locally.
- The original v9 art has unresolved seams/occlusions.
