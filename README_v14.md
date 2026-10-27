# Qiongqi Boss v14 — Godot 4 combat integration prototype

## What changed from v13
- Replaced overlapping `Area2D.area_entered` projectile callbacks with one **swept segment** collision resolver, using deterministic **wing > body > wall** priority; one projectile deals damage once.
- Dive now moves the boss along a smooth 0.75-second arc towards the wall. Damage occurs only when the traveling dive hitbox overlaps the wall, not by teleporting the hitbox at animation impact time.
- Claw strike uses one-time contact detection at the attack animation event.
- Added guards for terminal states, dead boss, destroyed wing, and duplicate hits.
- Preserved existing v9 six-animation skeleton scene, seal controls, tower shooting and win/loss flow.

## Open & test
1. Unzip and open `project.godot` in **Godot 4.x**.
2. Run `Battle.tscn` (main scene).
3. Press **A** to spawn an extra projectile; watch it travel into the boss. Repeat with the wing intact, then after the wing is destroyed.
4. Press **D** while airborne and not locked; observe the boss physically travel toward the wall and verify the wall takes damage **at most once per dive**.
5. Press **J** to trigger a claw attack; wall damage occurs only if the claw hitbox intersects the wall at the impact event.
6. Click the red wing weakpoint until broken; then hold **F** for 2.5 seconds to seal.
7. Press **R** to reset. Lower boss HP by repeated attacks to check enraged phase and defeat state.

## Test matrix (manual, not claimed passed)
- [ ] Wing/body overlap: wing hit gets priority and only one damage event.
- [ ] Projectile crossing a target between frames still hits (swept segment).
- [ ] Projectile hitting wall does not damage boss.
- [ ] Dive hits wall at most once; if the trajectory misses, no damage.
- [ ] Attack misses when claw is out of range; hit only when intersecting wall.
- [ ] Death/seal/loss stops further damage.
- [ ] Repeated reset returns health and animation state to initial values.
- [ ] Godot editor import has no parser errors.

## Limitations
- No Godot binary was available in the authoring environment: **engine execution and parser validation have not been performed**.
- `Skeleton2D` uses rigid layered sprites; visual joint seams and art occlusions remain.
- Combat hit shapes are simplified circles/rectangle, not per-pixel collision.
- The demo's animation controller still has independent debug key bindings; gameplay keys take precedence where handled, but this needs editor testing.
