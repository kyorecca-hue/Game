extends "res://battle_controller_v16.gd"
## Hero battle slice; legacy v16 Battle.tscn remains available for regression.
const SEAL_THRESHOLD := MAX_HP * 0.15
const RUNE_POSITIONS := [Vector2(285,370),Vector2(815,370),Vector2(550,225)]
const RUNE_RADIUS := 40.0
const RUNE_SECONDS := 1.25
const HERO_ATTACK_RANGE := 150.0
@onready var hero: Node2D = $Hero
var rune_index := 0
var rune_charge := 0.0
var hero_attack_left := 0.0
var sweep_left := 0.0
var sweep_flash := 0.0
var repair_left := 0.0
var hero_contact_left := 0.0
var guardian_unlocked := false

func _ready() -> void:
    super._ready()
    boss.set_process_unhandled_key_input(false)
    notice = "Defend the wall. At 15% boss HP, walk onto runes 1 > 2 > 3."
    $HUD/Instructions.text = "WASD / Right click: move   |   Q: sweep   |   E: repair wall nearby   |   R: restart\nAuto melee when grounded and in range. Stand inside each glowing rune to seal."
    _update_hud()

func _physics_process(delta: float) -> void:
    if _finished():
        _update_hud()
        queue_redraw()
        return
    _advance_hero(delta)
    if phase == "sealing":
        _advance_seal(delta)
        _update_hud()
        queue_redraw()
        return
    super._physics_process(delta)

func _advance_legacy_seal_input(_delta: float) -> void:
    pass

func _draw_legacy_seal_marker() -> void:
    pass

func _advance_hero(delta: float) -> void:
    hero.advance(delta, Input.get_vector("hero_left","hero_right","hero_up","hero_down"))
    hero_attack_left = maxf(0.0, hero_attack_left-delta)
    sweep_left = maxf(0.0, sweep_left-delta)
    repair_left = maxf(0.0, repair_left-delta)
    hero_contact_left = maxf(0.0, hero_contact_left-delta)
    sweep_flash = maxf(0.0, sweep_flash-delta)
    if not hero.is_alive() or phase == "sealing": return
    if hero.position.distance_to(body.position) <= HERO_ATTACK_RANGE and not airborne:
        if hero_attack_left <= 0.0:
            hero_attack_left = 0.75
            hero.facing = (body.position-hero.position).normalized()
            hero.attack_flash = 0.2
            _damage_boss(28.0)
            event_log.append("hero_attack")
        if phase != "sealing" and hero_contact_left <= 0.0:
            hero_contact_left = 1.2
            hero.take_damage(18.0)

func _damage_boss(amount: float) -> void:
    if _finished() or phase == "sealing" or amount <= 0.0: return
    var before := hp
    hp = maxf(SEAL_THRESHOLD, hp-amount)
    boss_damaged.emit(before-hp,hp)
    if hp <= SEAL_THRESHOLD: _begin_sealing()

func _begin_sealing() -> void:
    phase = "sealing"
    airborne = false
    dive_active = false
    auto_attacks_enabled = false
    wing.input_pickable = false
    wing.set_deferred("monitorable",false)
    rune_index = 0
    rune_charge = 0.0
    seal_progress = 0.0
    boss.play_state("hurt")
    notice = "SEALING: follow the glowing runes 1 > 2 > 3. Hold position to charge."
    event_log.append("sealing_started")

func _break_wing() -> void:
    if phase == "sealing" or _finished(): return
    super._break_wing()
    notice = "Wing broken. Hero can now strike in melee. Reach 15% HP to seal."

func _advance_seal(delta: float) -> void:
    if phase != "sealing" or rune_index >= RUNE_POSITIONS.size(): return
    if not hero.is_alive() or hero.position.distance_to(RUNE_POSITIONS[rune_index]) > RUNE_RADIUS:
        rune_charge = 0.0
        seal_progress = float(rune_index)/3.0*2.5
        return
    rune_charge = minf(RUNE_SECONDS, rune_charge+delta)
    seal_progress = (float(rune_index)+rune_charge/RUNE_SECONDS)/3.0*2.5
    if rune_charge >= RUNE_SECONDS:
        event_log.append("rune_%d" % (rune_index+1))
        rune_index += 1
        rune_charge = 0.0
        if rune_index == RUNE_POSITIONS.size(): _seal()

func _seal() -> void:
    if phase != "sealing" or rune_index != RUNE_POSITIONS.size(): return
    phase = "sealed"
    seal_progress = 2.5
    guardian_unlocked = true
    result = "VICTORY: QIONGQI SEALED"
    notice = "Guardian captured! Prototype reward; campaign saving is not implemented yet."
    boss_sealed.emit()
    event_log.append("sealed")
    boss.play_state("hurt")

func _fire_tower() -> void:
    if phase != "sealing": super._fire_tower()

func _choose_attack() -> void:
    if phase != "sealing": super._choose_attack()

func _begin_dive() -> void:
    if phase != "sealing": super._begin_dive()

func _begin_claw() -> void:
    if phase != "sealing": super._begin_claw()

func _hit_wall(damage: float, message: String) -> void:
    if phase != "sealing": super._hit_wall(damage,message)

func resolve_projectile_segment(start: Vector2, finish: Vector2, radius: float, damage: float) -> bool:
    if phase == "sealing": return true
    return super.resolve_projectile_segment(start,finish,radius,damage)

func _on_wing_click(_viewport: Node, _event: InputEvent, _idx: int) -> void:
    pass # Hero actions replace debug click damage in v17.

func _on_body_click(_viewport: Node, _event: InputEvent, _idx: int) -> void:
    pass

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_Q: _hero_sweep()
            KEY_E: _hero_repair()
            KEY_R: get_tree().reload_current_scene()
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
        if not _finished():
            hero.set_destination(get_global_transform_with_canvas().affine_inverse() * event.position)

func _hero_sweep() -> bool:
    if _finished() or phase == "sealing" or not hero.is_alive() or sweep_left > 0.0: return false
    if airborne or hero.position.distance_to(body.position) > 185.0:
        notice = "Sweep needs a grounded target nearby."
        return false
    sweep_left = 5.0
    sweep_flash = 0.3
    hero.attack_flash = 0.3
    _damage_boss(90.0)
    event_log.append("hero_sweep")
    return true

func _hero_repair() -> bool:
    if _finished() or not hero.is_alive() or repair_left > 0.0: return false
    if not _circle_rect(hero.position,60.0,wall.position,Vector2(390,65)):
        notice = "Move beside the wall to repair it."
        return false
    if wall_hp >= MAX_WALL_HP: return false
    repair_left = 6.0
    wall_hp = minf(MAX_WALL_HP,wall_hp+55.0)
    event_log.append("hero_repair")
    notice = "Wall repaired +55."
    return true

func _update_hud() -> void:
    if not is_instance_valid(hero): return
    var status := "HP %d/180" % int(hero.health) if hero.is_alive() else "REVIVE %ds" % ceili(hero.respawn_left)
    hud.text = "BEASTFALL v17 | BOSS %d/1200 | WING %d/300 | WALL %d/500 | %s\nHERO %s | Q %.1fs | E %.1fs | RUNES %d/3\n%s%s" % [int(hp),int(wing_hp),int(wall_hp),phase,status,sweep_left,repair_left,rune_index,notice," | "+result if result != "" else ""]
    hud.add_theme_font_size_override("font_size",17)

func _draw() -> void:
    super._draw()
    var font := ThemeDB.fallback_font
    if is_instance_valid(hero) and hero.moving_to_destination and hero.is_alive():
        draw_arc(hero.destination,12,0,TAU,32,Color("76cfc9"),2)
    if is_instance_valid(hero) and sweep_flash > 0.0:
        draw_arc(hero.position,185,0,TAU,64,Color("f6cf7a"),3)
    if phase not in ["sealing","sealed"]: return
    for i in range(RUNE_POSITIONS.size()):
        var point: Vector2 = RUNE_POSITIONS[i]
        var color := Color("5cc5ad") if i < rune_index else Color("eec56f") if i == rune_index else Color("636a7c")
        draw_circle(point,RUNE_RADIUS,Color(color,0.16))
        draw_arc(point,RUNE_RADIUS,0,TAU,64,color,3)
        draw_arc(point,RUNE_RADIUS-7,0,TAU,64,color,1)
        draw_string(font,point+Vector2(-7,8),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,24,color)
        if i == rune_index:
            draw_arc(point,RUNE_RADIUS+6,-PI/2,-PI/2+TAU*rune_charge/RUNE_SECONDS,64,Color.WHITE,4)
            draw_string(font,point+Vector2(-43,-57),"STAND HERE",HORIZONTAL_ALIGNMENT_LEFT,-1,15,color)
