extends SceneTree
var failures: Array[String] = []
var checks := 0
func _initialize() -> void:
    call_deferred("run_all")
func check(condition: bool, description: String) -> void:
    checks += 1
    if not condition:
        failures.append(description)
func fresh_battle() -> Node:
    var scene = load("res://Battle.tscn")
    var battle = scene.instantiate()
    root.add_child(battle)
    battle.set_physics_process(false)
    battle.auto_attacks_enabled = false
    return battle
func run_all() -> void:
    var b = fresh_battle()
    check(b.hp == 1200.0, "initial HP")
    check(b.wing_hp == 300.0, "initial wing HP")
    check(b.wall_hp == 500.0, "initial wall HP")
    check(b._segment_circle(Vector2(-10,0),Vector2(10,0),Vector2.ZERO,2), "swept circle intersection")
    check(not b._segment_circle(Vector2(-10,10),Vector2(10,10),Vector2.ZERO,2), "swept circle miss")
    var origin = b.wing.global_position
    check(b.resolve_projectile_segment(origin-Vector2(70,0),origin+Vector2(70,0),7.0,24.0), "projectile wing hit")
    check(b.wing_hp == 276.0 and b.hp == 1176.0, "wing hit damage exactly once")
    b.wing_hp = 10.0
    b.resolve_projectile_segment(origin-Vector2(70,0),origin+Vector2(70,0),7.0,24.0)
    check(not b.airborne and b.phase == "grounded", "wing break grounds boss")
    b._seal()
    check(b.phase == "sealed" and b.result.begins_with("VICTORY"), "seal victory")
    b.queue_free()
    var d = fresh_battle()
    d.auto_attacks_enabled = false
    d._begin_dive()
    check(d.dive_active and d.dive_cooldown > 0.0, "dive begins")
    for i in range(50):
        d._advance_dive(0.02)
    check(not d.dive_active, "dive terminates")
    check(d.wall_hp < 500.0, "dive hits wall")
    var hp_after = d.wall_hp
    d._advance_dive(0.02)
    check(d.wall_hp == hp_after, "dive single-hit")
    d.queue_free()
    var e = fresh_battle()
    e._damage_boss(1200.0)
    check(e.phase == "defeated" and e.event_log.count("boss_died") == 1, "death once")
    e.queue_free()
    var f = fresh_battle()
    f._hit_wall(500.0,"test")
    check(f.phase == "lost" and f.event_log.count("battle_lost") == 1, "wall defeat once")
    f.queue_free()
    var report = {"checks": checks, "failures": failures, "passed": failures.is_empty()}
    var out = FileAccess.open("user://v15_test_results.json", FileAccess.WRITE)
    if out: out.store_string(JSON.stringify(report,"  "))
    print("V15 TEST RESULTS: ", JSON.stringify(report))
    quit(0 if failures.is_empty() else 1)
