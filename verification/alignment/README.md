# Artwork alignment fix

The source skeleton uses image-space pivots with Body at (257, 384), while Preview positions the rig at the gameplay body anchor. Subtracting the body pivot at Skeleton2D prevents applying that offset twice. Bone rest poses, textures, animations, and combat logic are unchanged.

Godot 4.6.3 validation:
- Existing combat regression: 13/13 passed.
- New alignment checks: 27/27 geometry checks plus 4 saved screenshots, 31/31 passed with X11 and OpenGL Compatibility (Mesa software rendering).
- The same 27 geometry assertions fail on the previous rig, reproducing the reported displacement.
- Inspected screenshots for fly, dive, hurt and death. The character remains visible; existing cutout seams and leaf Bone2D warnings remain. Screenshot poses are set by the test and do not represent a complete manual playthrough.

Run `godot --headless --path . --script res://tests/run_visual_alignment.gd` for geometry checks. With a graphical display, omit `--headless` and append `-- --capture` to save screenshots in user://. Original v16 logs elsewhere describe the preceding type fix.
