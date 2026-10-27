# Qiongqi v11 — Tower-defense encounter prototype

Open `project.godot` in Godot 4, run `Battle.tscn`.

## Added in v11
- Boss moves through five waypoint positions.
- Wing target follows the boss position.
- Bastion damage checks an attack radius for claw attacks; dive impacts retain event-based damage.
- 50% HP triggers enraged phase with higher attack damage.
- Hold F (or click the seal circle to add progress) after breaking the wings; 2.5 s to seal.
- Win on seal or boss defeat; lose if bastion HP reaches zero. R restarts.

## Controls
- Left click: hit moving wing weakpoint (65 damage)
- A: manually fire a tower shot
- D: trigger dive animation
- Hold F: seal after wing break
- R: restart

## Limitations
- No physics-based Area2D collision shapes: gameplay uses distance tests.
- The v9 layered art is reused, without newly repainted seams.
- Godot engine was not available for runtime validation.
- `Battle.tscn` is a gameplay prototype, not a production level.
