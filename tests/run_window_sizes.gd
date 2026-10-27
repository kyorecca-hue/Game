extends SceneTree
## Run with a graphical display; checks actual window resize/stretch transforms.
var failures: Array[String] = []
var checks := 0
func _initialize() -> void:
    call_deferred("run")
func check(value: bool, label: String) -> void:
    checks += 1
    if not value: failures.append(label)
func run() -> void:
    var hero_mode := "--hero" in OS.get_cmdline_user_args()
    var b = load("res://HeroBattle.tscn" if hero_mode else "res://Battle.tscn").instantiate()
    root.add_child(b)
    b.set_physics_process(false)
    b.boss.set_process(false)
    b.auto_attacks_enabled = false
    var alignment = load("res://tests/run_visual_alignment.gd").new()
    var sprites: Array[Node] = b.boss.find_children("*", "Sprite2D", true, false)
    b._begin_dive()
    for i in range(50): b._advance_dive(0.02)
    b._break_wing()
    if hero_mode: b._damage_boss(2000.0)
    b._update_hud()
    b.queue_redraw()
    check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS, "canvas scaling enabled")
    check(root.content_scale_size == Vector2i(1100,760), "logical canvas preserved")
    var player: AnimationPlayer = b.boss.get_node("QiongqiRig/AnimationPlayer")
    player.pause()
    for size in [Vector2i(800,600), Vector2i(640,480), Vector2i(1280,720), Vector2i(1280,800), Vector2i(1600,900), Vector2i(1100,760)]:
        root.size = size
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        var screen := Rect2(Vector2.ZERO, Vector2(root.size))
        var transform := root.get_final_transform()
        var bounds := Rect2()
        var first := true
        for item in sprites:
            var sprite := item as Sprite2D
            var used: Rect2i = alignment.visible_pixels(sprite.texture)
            if not used.has_area(): continue
            var rect := Rect2(Vector2(used.position) - sprite.texture.get_size()*0.5 + sprite.offset, Vector2(used.size))
            for point in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:
                var pixel: Vector2 = transform * sprite.to_global(point)
                if first:
                    bounds = Rect2(pixel,Vector2.ZERO)
                    first = false
                else: bounds = bounds.expand(pixel)
        check(screen.encloses(bounds), str(size) + " artwork visible")
        check(screen.has_point(transform * Vector2(1090,755)), str(size) + " bottom controls visible")
        check(screen.has_point(transform * Vector2(365,665)), str(size) + " wall visible")
        if hero_mode:
            check(screen.has_point(transform * (b.hero.position + Vector2(30,38))), str(size) + " hero visible")
            for point in b.RUNE_POSITIONS:
                check(screen.has_point(transform * (point + Vector2(46,46))) and screen.has_point(transform * (point - Vector2(46,57))), str(size) + " rune visible")
            var target: Vector2 = b.RUNE_POSITIONS[0]
            var mouse := InputEventMouseButton.new()
            mouse.button_index = MOUSE_BUTTON_RIGHT
            mouse.pressed = true
            mouse.position = transform * target
            mouse.global_position = mouse.position
            root.warp_mouse(mouse.position)
            root.push_input(mouse, false)
            mouse = InputEventMouseButton.new()
            mouse.button_index = MOUSE_BUTTON_RIGHT
            mouse.position = transform * target
            mouse.global_position = mouse.position
            root.push_input(mouse, false)
            await process_frame
            check(b.hero.destination.distance_to(target) < 2.0, str(size) + " right click maps to rune in world space")
        # Letterbox dimensions are rounded to integer pixels by Godot.
        check(absf(transform.x.length() - transform.y.length()) * 760.0 <= 1.0,
            str(size) + " uniform scale within one pixel of rounding")
        print("WINDOW ", size, " artwork bounds ", bounds, " transform ", transform)
        var image := root.get_texture().get_image()
        check(image.save_png("user://window_%dx%d.png" % [size.x,size.y]) == OK, str(size) + " screenshot saved")
    alignment.free()
    b.queue_free()
    await process_frame
    var report := {"checks":checks,"failures":failures,"passed":failures.is_empty()}
    var file := FileAccess.open("user://window_test_results.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    print("WINDOW RESULTS: ",JSON.stringify(report))
    quit(0 if failures.is_empty() else 1)
