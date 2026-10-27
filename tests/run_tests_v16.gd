extends SceneTree
var failures: Array[String] = []
var checks := 0
func _initialize() -> void:
    call_deferred("run_all")
func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition: failures.append(label)
func make_battle() -> Node:
    var packed: PackedScene = load("res://Battle.tscn")
    var battle = packed.instantiate()
    root.add_child(battle)
    battle.set_physics_process(false)
    battle.auto_attacks_enabled = false
    return battle
func run_all() -> void:
    var b = make_battle()
    check(b.hp == 1200.0 and b.wing_hp == 300.0 and b.wall_hp == 500.0, "initial stats")
    check(b._segment_circle_time(Vector2(-10, 0), Vector2(10, 0), Vector2.ZERO, 2.0) < INF, "swept hit")
    check(b._segment_circle_time(Vector2(-10, 10), Vector2(10, 10), Vector2.ZERO, 2.0) == INF, "swept miss")
    var target: Vector2 = b.wing.global_position
    check(b.resolve_projectile_segment(target, target, 7.0, 24.0), "weakpoint direct hit")
    check(b.wing_hp == 276.0 and b.hp == 1176.0, "single weakpoint damage")
    b.wing_hp = 10.0
    b.resolve_projectile_segment(target, target, 7.0, 24.0)
    check(not b.airborne and b.phase == "grounded", "wing break")
    b._seal()
    check(b.phase == "sealed" and b.event_log.count("sealed") == 1, "seal win once")
    b.queue_free()
    var d = make_battle()
    d._begin_dive()
    check(d.dive_active and d.dive_cooldown > 0.0, "dive start")
    for i in range(50): d._advance_dive(0.02)
    check(not d.dive_active and d.wall_hp < 500.0, "dive completes with collision")
    var wall_after: float = d.wall_hp
    d._advance_dive(0.02)
    check(d.wall_hp == wall_after, "dive no duplicate damage")
    d.queue_free()
    var e = make_battle()
    e._damage_boss(1200.0)
    e._damage_boss(1200.0)
    check(e.phase == "defeated" and e.event_log.count("boss_died") == 1, "death event once")
    e.queue_free()
    var f = make_battle()
    f._hit_wall(500.0, "test")
    f._hit_wall(500.0, "test")
    check(f.phase == "lost" and f.event_log.count("battle_lost") == 1, "loss event once")
    f.queue_free()
    var g = make_battle()
    g.airborne = false
    g._choose_attack()
    check(g.attack_sequence == 1 and g.event_log.has("claw_started"), "grounded boss attacks")
    g.queue_free()
    var report = {"version":"v16", "checks":checks,"failures":failures,"passed":failures.is_empty()}
    var output = FileAccess.open("user://v16_test_results.json", FileAccess.WRITE)
    if output: output.store_string(JSON.stringify(report, "  "))
    print("V16 TEST RESULTS: ", JSON.stringify(report))
    quit(0 if failures.is_empty() else 1)
