extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
    checks += 1
    if not value: failures.append(label)
func make_battle() -> Node:
    var b = load("res://HeroBattle.tscn").instantiate()
    root.add_child(b)
    b.set_physics_process(false)
    b.auto_attacks_enabled = false
    b.boss.set_process(false)
    b.boss.get_node("QiongqiRig/AnimationPlayer").pause()
    return b
func key(b: Node, code: Key) -> void:
    var e := InputEventKey.new()
    e.keycode = code
    e.pressed = true
    b._unhandled_input(e)
func run() -> void:
    var b = make_battle()
    var h = b.hero
    check(h.health == 180.0 and h.position == Vector2(550,680),"hero initial state")
    h.position = Vector2(400,400)
    h.advance(0.2,Vector2.RIGHT)
    check(h.position.is_equal_approx(Vector2(445,400)),"keyboard movement speed")
    h.position = Vector2(400,400)
    h.advance(0.2,Vector2.ONE)
    check(is_equal_approx(h.position.distance_to(Vector2(400,400)),45.0),"diagonal speed normalized")
    h.advance(10.0,Vector2.ONE)
    check(h.position == h.ARENA.end,"hero constrained inside play area")
    h.position = Vector2(400,400)
    h.set_destination(Vector2(500,400))
    h.advance(1.0,Vector2.ZERO)
    check(h.position == Vector2(500,400) and not h.moving_to_destination,"waypoint reaches without overshooting")
    h.set_destination(Vector2(900,400))
    h.advance(0.1,Vector2.LEFT)
    check(not h.moving_to_destination and h.position.x < 500,"keyboard cancels right click movement")
    h.set_destination(Vector2(-500,2000))
    check(h.destination == Vector2(35,685),"right click outside arena clamps")
    key(b,KEY_A)
    key(b,KEY_D)
    check(b.shot_count == 0 and not b.dive_active,"WASD no longer invokes debug attacks")
    check(not b.boss.is_processing_unhandled_key_input(),"rig debug key handler disabled")
    Input.action_press("hero_right")
    h.position = Vector2(400,400)
    b._advance_hero(0.2)
    Input.action_release("hero_right")
    check(h.position.x > 400,"input action drives hero")
    var health_before: float = b.hp
    h.position = b.body.position
    b._advance_hero(0.1)
    check(b.hp == health_before,"melee cannot hit airborne boss")
    check(not b._hero_sweep(),"sweep cannot hit airborne boss")
    b._break_wing()
    b._advance_hero(0.1)
    check(b.hp == health_before-28.0 and b.event_log.has("hero_attack"),"grounded auto melee damages boss")
    check(h.health < 180,"close combat damages hero")
    var after: float = b.hp
    b._advance_hero(0.1)
    check(b.hp == after,"auto melee respects cooldown")
    check(b._hero_sweep() and b.hp == after-90,"sweep damages grounded boss")
    check(not b._hero_sweep(),"sweep cannot bypass cooldown")
    h.position = Vector2(40,200)
    b.wall_hp = 300
    check(not b._hero_repair(),"repair requires proximity")
    h.position = Vector2(550,680)
    check(b._hero_repair() and b.wall_hp == 355,"nearby repair restores wall")
    check(not b._hero_repair(),"repair cooldown enforced")
    b.repair_left = 0
    b.wall_hp = 490
    check(b._hero_repair() and b.wall_hp == 500,"repair cannot exceed max wall health")
    h.invulnerable_left = 0
    h.take_damage(500)
    var dead_position: Vector2 = h.position
    h.advance(9.0,Vector2.RIGHT)
    check(not h.is_alive() and h.position == dead_position,"fallen hero cannot move before respawn")
    h.advance(1.0,Vector2.ZERO)
    check(h.is_alive() and h.health == 180 and h.position == h.SPAWN,"ten second revival at castle")
    check(not h.take_damage(20),"revival invulnerability")
    b.free()

    b = make_battle()
    b._damage_boss(1019)
    check(b.hp == 181 and b.phase != "sealing","above 15 percent does not activate ritual")
    b._seal()
    check(b.phase != "sealed","cannot seal early through old F shortcut")
    b._damage_boss(10000)
    check(b.hp == 180 and b.phase == "sealing","overkill stops at 15 percent and starts ritual")
    check(not b.airborne and not b.dive_active and not b.auto_attacks_enabled,"ritual suspends boss attacks")
    b._break_wing()
    check(b.phase == "sealing","late wing damage cannot replace ritual phase")
    b._damage_boss(500)
    check(b.hp == 180,"boss invulnerable during ritual")
    var wall_before: float = b.wall_hp
    b._hit_wall(500,"test")
    check(b.wall_hp == wall_before,"wall safe during ritual")
    b._fire_tower()
    check(b.shot_count == 0,"towers stop during ritual")
    check(b.resolve_projectile_segment(Vector2.ZERO,Vector2.ONE,7,24) and b.hp == 180,"in flight projectiles expire without killing seal target")
    b.hero.position = b.RUNE_POSITIONS[1]
    b._advance_seal(2)
    check(b.rune_index == 0,"out of order rune rejected")
    b.hero.position = b.RUNE_POSITIONS[0]
    b._advance_seal(0.5)
    check(b.rune_index == 0 and b.rune_charge == 0.5,"rune requires sustained presence")
    b.hero.position = Vector2(50,200)
    b._advance_seal(0.1)
    check(b.rune_charge == 0,"leaving rune resets partial charge")
    b.hero.position = b.RUNE_POSITIONS[0]
    b.hero.take_damage(500)
    b._advance_seal(2)
    check(b.rune_index == 0,"fallen hero cannot activate rune")
    b.hero.advance(10,Vector2.ZERO)
    var wins := [0]
    b.boss_sealed.connect(func(): wins[0] += 1)
    for i in range(3):
        b.hero.position = b.RUNE_POSITIONS[i]
        b._advance_seal(1.25)
        check(b.rune_index == i+1,"ordered rune %d" % (i+1))
        if i < 2: check(not b._finished(),"no early victory at rune %d" % (i+1))
    check(b.phase == "sealed" and b.guardian_unlocked,"third rune completes capture")
    b._seal()
    b._advance_seal(2)
    check(wins[0] == 1 and b.event_log.count("sealed") == 1,"capture event emitted exactly once")
    var hero_before: Vector2 = b.hero.position
    Input.action_press("hero_left")
    b._physics_process(1)
    Input.action_release("hero_left")
    check(b.hero.position == hero_before,"gameplay stops after victory")
    b.free()
    b = make_battle()
    b._hit_wall(500,"test")
    check(b.phase == "lost","wall destruction still loses battle")
    check(not b._hero_repair(),"cannot repair after defeat")
    b.free()
    var report := {"version":"v17","checks":checks,"failures":failures,"passed":failures.is_empty()}
    var file := FileAccess.open("user://v17_test_results.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    print("V17 RESULTS: ",JSON.stringify(report))
    quit(0 if failures.is_empty() else 1)
