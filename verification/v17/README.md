# v17 verified results

Godot 4.6.3, X11 and OpenGL Compatibility with Mesa software rendering.

- Editor import: no script errors.
- v17 deterministic functional tests: 47/47 pass (movement, normalized speed, boundaries, keyboard/waypoint interaction, attack cooldowns, repair, death/revival, 15% threshold and overkill protection, ordered runes, interrupted charge, dead-hero gating, once-only win, defeat).
- v16 legacy regression: 13/13 pass. Legacy Battle.tscn is preserved separately from the new HeroBattle.tscn.
- Original artwork geometry checks: 27/27 pass.
- Hero window tests: 62/62 pass across 800x600, 640x480, 1280x720, 1280x800, 1600x900, 1100x760. Includes hero/rune visibility and right-click event coordinates after stretch/letterboxing, not only screenshots.
- Rendered playthrough: 19/19 checks pass. Real physics/towers/animations were left enabled. No health edits or teleports; the driver used movement input, right-click waypoints and E repair, then walked onto runes 1, 2 and 3. Combat lasted 26.77 simulated seconds before ritual; sampled 2,108 physics frames including ritual walking. Boss held at 180 HP; wall had 410 HP at victory. R restarted the hero scene and reset hero/ritual state.
- Captured start, rune transitions and victory; inspected rendered start, ritual, victory and resized scene screenshots.

The hero uses temporary procedural art. Existing boss cutout seams and Bone2D leaf warnings remain. The GUI tests use synthetic input events, not a human playtest; controller input, exports and Steam Deck have not been validated. No campaign persistence, buildable towers or four-direction waves are implemented in this slice.
