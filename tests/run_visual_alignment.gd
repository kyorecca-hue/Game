extends SceneTree
## Regression for the artwork drifting below/right of the gameplay hitboxes.
var failures: Array[String] = []
var checks := 0
var alpha_bounds: Dictionary = {}

func _initialize() -> void:
    call_deferred("run_all")

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)

func run_all() -> void:
    root.size = Vector2i(1100, 760)
    var battle = load("res://Battle.tscn").instantiate()
    root.add_child(battle)
    battle.set_physics_process(false)
    battle.auto_attacks_enabled = false
    var rig: Node2D = battle.boss.get_node("QiongqiRig")
    var anchor: Bone2D = rig.get_node("Skeleton2D/Body")
    var player: AnimationPlayer = rig.get_node("AnimationPlayer")
    battle.boss.set_process(false)
    for point in battle.ROUTE:
        battle.boss.position = point
        battle._sync_hitboxes()
        check(anchor.global_position.distance_to(battle.body.global_position) < 0.01,
            "body artwork follows hitbox at route " + str(point))
    battle.boss.position = battle.ROUTE[0]
    battle._sync_hitboxes()
    await inspect_pose(battle, player, "fly", 0.3)
    battle._begin_dive()
    for i in range(15):
        battle._advance_dive(0.05)
        check(anchor.global_position.distance_to(battle.body.global_position) < 0.01,
            "body artwork follows dive step " + str(i))
    await inspect_pose(battle, player, "dive", 0.5)
    battle._break_wing()
    await inspect_pose(battle, player, "hurt", 0.3)
    battle._defeat()
    await inspect_pose(battle, player, "death", 1.4)
    battle.queue_free()
    await process_frame
    print("VISUAL ALIGNMENT RESULTS: ", JSON.stringify({"checks":checks,"failures":failures,"passed":failures.is_empty()}))
    quit(0 if failures.is_empty() else 1)

func inspect_pose(battle: Node2D, player: AnimationPlayer, pose: String, time: float) -> void:
    player.play(pose)
    player.advance(time)
    await process_frame
    var body_art: Sprite2D = battle.boss.get_node("QiongqiRig/Skeleton2D/Body/Art")
    var pixels := visible_pixels(body_art.texture)
    var local_center := Vector2(pixels.position) + Vector2(pixels.size) * 0.5 - body_art.texture.get_size() * 0.5 + body_art.offset
    check(body_art.to_global(local_center).distance_to(battle.body.global_position) < 90.0,
        pose + " visible body pixels overlap body hitbox")
    var bounds := Rect2()
    var first := true
    for node in battle.boss.find_children("*", "Sprite2D", true, false):
        var sprite := node as Sprite2D
        var used := visible_pixels(sprite.texture)
        if not used.has_area():
            continue
        var pos := Vector2(used.position) - sprite.texture.get_size() * 0.5 + sprite.offset
        var rect := Rect2(pos, Vector2(used.size))
        for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
            var world := sprite.to_global(corner)
            if first:
                bounds = Rect2(world, Vector2.ZERO)
                first = false
            else:
                bounds = bounds.expand(world)
    print(pose, " artwork bounds: ", bounds)
    check(Rect2(0, 0, 1100, 760).encloses(bounds), pose + " all artwork stays on screen")
    battle.queue_redraw()
    if "--capture" in OS.get_cmdline_user_args():
        await process_frame
        await RenderingServer.frame_post_draw
        var image := root.get_texture().get_image()
        check(image.save_png("user://alignment_" + pose + ".png") == OK, pose + " screenshot saved")

func visible_pixels(texture: Texture2D) -> Rect2i:
    if alpha_bounds.has(texture):
        return alpha_bounds[texture]
    var image := texture.get_image()
    var low := image.get_size()
    var high := Vector2i(-1, -1)
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            if image.get_pixel(x, y).a > 0.0:
                low.x = mini(low.x, x)
                low.y = mini(low.y, y)
                high.x = maxi(high.x, x)
                high.y = maxi(high.y, y)
    var rect := Rect2i(low, high - low + Vector2i.ONE) if high.x >= 0 else Rect2i()
    alpha_bounds[texture] = rect
    return rect
