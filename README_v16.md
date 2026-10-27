# 《神獸紀元》窮奇 Boss v16 — compatibility and regression candidate

## Included
- v15 art, rig, scene and gameplay assets preserved.
- `Battle.tscn` now references `battle_controller_v16.gd`.
- Projectile hit detection computes **first contact time** for body and wing swept circles, prioritizing wing only on exact ties, preventing body/wing double damage.
- Grounded boss can continue claw attack cycle; attack scheduling falls back to an available attack.
- Rig no longer handles `R`, avoiding competing scene reloads. Battle controller owns reset.
- `tests/run_tests_v16.gd` tests hit geometry, weakpoint damage, wing break, seal, dive, death/loss once-only signals, grounded attack.

## How to run (Godot 4.x)
1. Extract the ZIP and open `project.godot` in Godot 4.
2. Press F6 with `Battle.tscn` open, or F5 to launch main scene.
3. Controls: left click wing/body; A shoot; D dive; J claw; hold F to seal after breaking wing; R reset.
4. From a terminal in the extracted project folder:
   `godot --headless --path . --script res://tests/run_tests_v16.gd`
5. Confirm `V16 TEST RESULTS` shows `"passed":true` and exit code 0; results saved in Godot user data folder (`user://v16_test_results.json`).
6. For parser-only validation: `godot --headless --path . --editor --quit`.

## Acceptance criteria
- Project imports with zero parser errors and scene loads.
- 12 automated checks pass (count may change with tests).
- Projectiles hit exactly one target per projectile, with first-contact resolution.
- Wing destruction permits sealing; death/loss event emitted once.
- Dive reaches wall and applies damage only once.
- After grounded, boss still selects claw attacks.

## Verification disclosure
This package was assembled and statically checked, but Godot is not installed in the authoring environment. **Engine tests were NOT executed**; see `QA_v16_report.json`. Do not treat as certified stable until the above commands pass on a Godot 4 installation.
