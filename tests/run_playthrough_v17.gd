extends SceneTree
## Real rendered gameplay: no health edits, teleports, or disabled simulation.
var failures: Array[String] = []
var checks := 0
var captured: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
    checks += 1
    if not value: failures.append(label)
func key(code: Key) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    root.push_input(event,true)
    event = InputEventKey.new()
    event.keycode = code
    event.pressed = false
    root.push_input(event,true)
func move_click(point: Vector2) -> void:
    root.warp_mouse(point)
    var event := InputEventMouseButton.new()
    event.button_index = MOUSE_BUTTON_RIGHT
    event.position = point
    event.global_position = point
    event.pressed = true
    root.push_input(event,true)
    event = InputEventMouseButton.new()
    event.button_index = MOUSE_BUTTON_RIGHT
    event.position = point
    event.global_position = point
    event.pressed = false
    root.push_input(event,true)
func capture(label: String) -> void:
    if captured.has(label): return
    await process_frame
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png("user://v17_"+label+".png") == OK,label+" capture")
    captured.append(label)
func run() -> void:
    root.size = Vector2i(1100,760)
    var b = load("res://HeroBattle.tscn").instantiate()
    root.add_child(b)
    current_scene = b
    await process_frame
    await capture("start")
    Input.action_press("hero_up")
    for i in range(20): await physics_frame
    Input.action_release("hero_up")
    check(b.hero.position.y < 680,"W input moves hero in live scene")
    move_click(Vector2(550,680))
    await process_frame
    check(b.hero.destination.distance_to(Vector2(550,680)) < 2,"right click uses correct world coordinates")
    var commanded_rune := -1
    var samples := 0
    var aligned := true
    var hero_visible := true
    var started_sealing := false
    for i in range(4800):
        await physics_frame
        samples += 1
        var pivot: Node2D = b.boss.get_node("QiongqiRig/Skeleton2D/Body")
        if pivot.global_position.distance_to(b.body.global_position) > 0.01: aligned = false
        if not Rect2(0,0,1100,760).has_point(b.hero.position): hero_visible = false
        if b.wall_hp < 450 and b.repair_left <= 0 and b.phase != "sealing": key(KEY_E)
        if b.phase == "sealing":
            started_sealing = true
            if commanded_rune != b.rune_index:
                await capture("rune_%d" % (b.rune_index+1))
                commanded_rune = b.rune_index
                move_click(b.RUNE_POSITIONS[b.rune_index])
                await process_frame
                check(b.hero.destination.distance_to(b.RUNE_POSITIONS[b.rune_index]) < 2,"right click targets rune %d" % (b.rune_index+1))
        if b._finished(): break
    await capture("result")
    check(started_sealing,"natural battle reaches ritual without forced damage")
    check(b.phase == "sealed" and b.rune_index == 3,"walked through all three runes to win")
    check(b.hp == 180 and b.wall_hp > 0,"boss kept at 15 percent and wall survived")
    check(b.event_log.has("hero_repair"),"E input repaired wall")
    check(b.event_log.has("hero_attack"),"hero auto attack occurred")
    check(b.event_log.count("sealed") == 1,"one capture event")
    check(aligned and hero_visible,"hero and boss positions stayed valid throughout battle")
    var battle_seconds: float = b.battle_time
    var wall_health: float = b.wall_hp
    var events: Array = b.event_log.duplicate()
    key(KEY_R)
    await process_frame
    await process_frame
    await process_frame
    var restarted = current_scene
    check(is_instance_valid(restarted) and restarted != b,"R reloads main hero scene")
    check(restarted.hp == 1200 and restarted.rune_index == 0 and restarted.hero.health == 180,"restart resets hero and ritual state")
    var report := {"version":"v17","checks":checks,"failures":failures,"passed":failures.is_empty(),"physics_samples":samples,"combat_seconds":battle_seconds,"wall_hp_at_win":wall_health,"events":events,"captures":captured}
    var file := FileAccess.open("user://v17_playthrough_results.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    print("V17 PLAYTHROUGH: ",JSON.stringify(report))
    quit(0 if failures.is_empty() else 1)
