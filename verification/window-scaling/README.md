# v16.2 window scaling validation

Reproduced on the previous version: resizing the window to 800x600 crops the boss, wall and bottom controls. The previous tests forced 1100x760 and did not cover this scenario. This is an independent confirmed defect; it does not prove which version or window configuration the user ran.

Fix: canvas_items stretch with keep aspect preserves the 1100x760 logical play area, letterboxing other aspect ratios. The window title and battle HUD identify v16.2 to distinguish it from older extracted copies.

Godot 4.6.3 with actual X11/OpenGL Compatibility rendering: 32/32 checks pass across 800x600, 640x480, 1280x720, 1280x800, 1600x900 and return to 1100x760 in one process. Checks cover artwork alpha bounds, bottom controls, wall, aspect scaling within one pixel of integer rounding and screenshot saves. The test uses a controlled grounded pose after a dive. Also passed original 13 combat checks, 27 alignment checks, and editor import with no script errors. Original leaf Bone2D warnings and cutout seams remain.

Run with a graphical display: `godot --path . --script res://tests/run_window_sizes.gd`. Screenshots and JSON are saved in user://. Screenshot images contain the rendered viewport; OS letterbox margins may be excluded.
