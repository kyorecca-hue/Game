extends Node2D
const MAX_HP := 1200.0
const MAX_WING_HP := 300.0
const MAX_WALL_HP := 500.0
const TOWERS := [Vector2(205,290),Vector2(855,290),Vector2(240,555),Vector2(845,550)]
const ROUTE := [Vector2(60,40),Vector2(80,100),Vector2(90,180),Vector2(80,275)]
const PROJECTILE = preload("res://projectile_v13.gd")
@onready var boss = $Boss
@onready var body: Area2D = $BossBody
@onready var wing: Area2D = $Weakpoint
@onready var wall: Area2D = $WallHitbox
@onready var dive: Area2D = $DiveHitbox
@onready var claw: Area2D = $ClawHitbox
@onready var projectiles: Node2D = $Projectiles
@onready var hud: Label = $HUD/Info
var hp := MAX_HP
var wing_hp := MAX_WING_HP
var wall_hp := MAX_WALL_HP
var phase := "approach"
var airborne := true
var route_index := 1
var tower_timer := 0.0
var shot_count := 0
var seal_progress := 0.0
var enraged := false
var notice := "Destroy the wing, then seal Qiongqi."
var result := ""
var dive_active := false
var claw_active := false
var dive_hits := 0
var claw_hits := 0
var death_event_emitted := false
signal boss_damaged(amount: float, remaining_hp: float)
signal wing_destroyed
signal wall_damaged(amount: float, remaining_hp: float)
signal boss_died
signal boss_sealed
signal battle_lost
func _ready() -> void:
    boss.get_node("CanvasLayer").visible = false
    boss.attack_hit.connect(_on_attack_hit)
    boss.dive_impact.connect(_on_dive_impact)
    boss.death_finished.connect(_on_death_finished)
    wing.input_event.connect(_on_wing_click)
    body.input_event.connect(_on_body_click)
    dive.area_entered.connect(_on_dive_overlap)
    claw.area_entered.connect(_on_claw_overlap)
    boss.play_state("fly")
    _sync_hitboxes()
    _update_hud()
func _physics_process(delta: float) -> void:
    if phase in ["sealed","defeated","lost"]:
        _update_hud()
        queue_redraw()
        return
    if airborne and route_index < ROUTE.size() and not boss.lock_action:
        boss.position = boss.position.move_toward(ROUTE[route_index], (70.0 if enraged else 48.0) * delta)
        if boss.position.distance_to(ROUTE[route_index]) < 1.0:
            route_index += 1
    _sync_hitboxes()
    tower_timer += delta
    if tower_timer >= 0.9:
        tower_timer -= 0.9
        _fire_tower()
    if not airborne and Input.is_key_pressed(KEY_F):
        seal_progress = minf(2.5, seal_progress + delta)
        if seal_progress >= 2.5: _seal()
    else:
        seal_progress = maxf(0.0, seal_progress - delta * 0.5)
    if hp <= MAX_HP * 0.5 and not enraged:
        enraged = true
        notice = "Phase 2: Enraged"
    if wall_hp <= 0.0: _lose()
    _update_hud()
    queue_redraw()
func _sync_hitboxes() -> void:
    # v7 sprites have baked offsets: their artwork is centered near (480,330) relative to Preview.
    body.global_position = boss.global_position + Vector2(480,330)
    wing.global_position = boss.global_position + Vector2(430,245)
    wing.monitorable = airborne
    wing.input_pickable = airborne
    if not dive_active: dive.global_position = body.global_position + Vector2(0,80)
    if not claw_active: claw.global_position = body.global_position + Vector2(50,70)
func _fire_tower() -> void:
    if phase in ["sealed","defeated","lost"]: return
    var origin: Vector2 = TOWERS[shot_count % TOWERS.size()]
    shot_count += 1
    var target: Vector2 = wing.global_position if airborne else body.global_position
    var bullet: Area2D = Area2D.new()
    bullet.set_script(PROJECTILE)
    bullet.position = origin
    bullet.velocity = (target - origin).normalized() * 520.0
    bullet.damage = 24.0 if airborne else 38.0
    bullet.impacted.connect(_on_projectile_hit)
    projectiles.add_child(bullet)
func _on_projectile_hit(damage: float, target: String) -> void:
    if phase in ["sealed","defeated","lost"]: return
    if target == "wing" and airborne:
        wing_hp = maxf(0.0, wing_hp - damage)
        _damage_boss(damage)
        if wing_hp <= 0.0 and phase != "defeated": _break_wing()
    elif target == "body":
        _damage_boss(damage)
func _damage_boss(amount: float) -> void:
    hp = maxf(0.0, hp - amount)
    boss_damaged.emit(amount,hp)
    if hp <= 0.0: _defeat()
func _on_wing_click(_viewport: Node,event: InputEvent,_idx: int) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and airborne and phase not in ["sealed","defeated","lost"]:
        wing_hp = maxf(0.0,wing_hp - 65.0)
        _damage_boss(25.0)
        if wing_hp <= 0.0 and phase != "defeated": _break_wing()
func _on_body_click(_viewport: Node,event: InputEvent,_idx: int) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and phase not in ["sealed","defeated","lost"]:
        _damage_boss(10.0)
func _break_wing() -> void:
    airborne = false
    phase = "grounded"
    notice = "Wing broken. Hold F to seal."
    wing.set_deferred("monitorable",false)
    boss.play_state("hurt")
    wing_destroyed.emit()
func _on_attack_hit() -> void:
    if phase in ["sealed","defeated","lost"]: return
    _activate_strike(claw,false)
func _on_dive_impact() -> void:
    if phase in ["sealed","defeated","lost"]: return
    _activate_strike(dive,true)
func _activate_strike(hitbox: Area2D, is_dive: bool) -> void:
    # Physical overlap is checked on the next physics frame, not inferred from distance.
    hitbox.global_position = wall.global_position + Vector2(0,-20) if is_dive else body.global_position + Vector2(45,65)
    hitbox.get_node("CollisionShape2D").set_deferred("disabled",false)
    if is_dive: dive_active = true
    else: claw_active = true
    await get_tree().physics_frame
    if not is_inside_tree(): return
    for area in hitbox.get_overlapping_areas():
        if area == wall: _resolve_strike(is_dive)
    hitbox.get_node("CollisionShape2D").set_deferred("disabled",true)
    if is_dive: dive_active = false
    else: claw_active = false
func _on_dive_overlap(area: Area2D) -> void:
    if area == wall and dive_active: _resolve_strike(true)
func _on_claw_overlap(area: Area2D) -> void:
    if area == wall and claw_active: _resolve_strike(false)
func _resolve_strike(is_dive: bool) -> void:
    if phase in ["sealed","defeated","lost"]: return
    # Guard against double damage from area_entered + overlap query.
    if is_dive:
        if dive_hits > 0: return
        dive_hits += 1
    else:
        if claw_hits > 0: return
        claw_hits += 1
    var damage := (80.0 if enraged else 55.0) if is_dive else (35.0 if enraged else 25.0)
    wall_hp = maxf(0.0,wall_hp - damage)
    wall_damaged.emit(damage,wall_hp)
    notice = "Dive hit wall" if is_dive else "Claw hit wall"
    if wall_hp <= 0.0: _lose()
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_A: _fire_tower()
            KEY_D:
                if airborne and not boss.lock_action and phase not in ["sealed","defeated","lost"]:
                    dive_hits = 0
                    boss.play_state("dive")
            KEY_J:
                if not boss.lock_action and phase not in ["sealed","defeated","lost"]:
                    claw_hits = 0
                    boss.play_state("attack")
            KEY_R: get_tree().reload_current_scene()
func _seal() -> void:
    if airborne or phase in ["sealed","defeated","lost"]: return
    phase = "sealed"
    result = "VICTORY: SEALED"
    notice = "Anti-air guardian bonus +20% (demo)"
    boss_sealed.emit()
    boss.play_state("hurt")
func _defeat() -> void:
    if phase in ["sealed","defeated","lost"]: return
    phase = "defeated"
    result = "VICTORY: BOSS DEFEATED"
    boss_died.emit()
    death_event_emitted = true
    boss.play_state("death")
func _lose() -> void:
    if phase in ["sealed","defeated","lost"]: return
    phase = "lost"
    result = "DEFEAT: WALL DESTROYED"
    battle_lost.emit()
func _on_death_finished() -> void:
    notice = "Death animation finished"
func _update_hud() -> void:
    hud.text = "QIONGQI v13 | HP %d/1200 | WING %d/300 | WALL %d/500 | %s\n%s | Seal %d%% | %s" % [int(hp),int(wing_hp),int(wall_hp),phase,notice,int(seal_progress / 2.5 * 100.0),result]
func _draw() -> void:
    draw_rect(Rect2(0,0,1100,760),Color("171b20"))
    for y in range(160,720,65): draw_line(Vector2(0,y),Vector2(1100,y),Color("3c3833"),1.0)
    draw_rect(Rect2(365,600,390,65),Color("56534c"))
    for point in TOWERS:
        draw_circle(point,27.0,Color("9d7951"))
        draw_circle(point,12.0,Color("db8d40"))
    draw_arc(wing.position,52.0,0.0,TAU,64,Color("e74738") if airborne else Color("777777"),3.0)
    if not airborne: draw_arc(Vector2(560,470),95.0,0.0,TAU,64,Color("ed5144"),4.0)
    draw_rect(Rect2(375,110,360,15),Color("3b2424"))
    draw_rect(Rect2(375,110,360 * hp / MAX_HP,15),Color("c33e36"))
