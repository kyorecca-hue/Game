# Qiongqi Boss v13 — Godot 4 battle prototype

## Open
Open `project.godot` in Godot 4.x and run `Battle.tscn` (configured as main scene).

## Inputs
- Left click wing (red ring): damage wing and Boss; body click: minor damage.
- A: fire an additional tower projectile.
- D: dive strike (airborne only); J: claw strike.
- Hold F after wing break: seal Boss.
- R: reload battle.

## New in v13
- `BossBody` and `Weakpoint` are separate `Area2D` targets, each with `CollisionShape2D`.
- `WallHitbox` is an `Area2D` with a rectangle collision shape.
- `DiveHitbox` and `ClawHitbox` are activated for the strike window, with overlap-driven wall damage.
- Projectile uses physics area signals and emits a typed target (`wing`, `body`), with single-hit protection.
- Signals: `boss_damaged`, `wing_destroyed`, `wall_damaged`, `boss_died`, `boss_sealed`, `battle_lost`.

## QA limitations
- The Godot executable was not available in the authoring environment; runtime/physics behavior is **not** verified in-engine.
- The v7/v9 rigid sprites and their visible seams are unchanged.
- Dive strike hitbox is positioned at the wall at animation impact for a deterministic mechanics prototype; it is not yet tied to an actual swept aerial trajectory.
- Collision masks: body 2, wing 4, wall 8, dive 16, claw 32, projectile 64.
- For production, test Area2D signal ordering, hitbox placement, sprite bounds, projectile targeting and battle balance in Godot.
