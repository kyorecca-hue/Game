extends Node2D
## v15: deterministic hit priority and physical travel of the boss during dive.
## Gameplay coordinates are independent of the layered illustration's baked offsets.
signal boss_damaged(amount: float, remaining_hp: float)
signal wing_destroyed
signal wall_damaged(amount: float, remaining_hp: float)
signal boss_died
signal boss_sealed
signal battle_lost
const MAX_HP := 1200.0
const MAX_WING_HP := 300.0
const MAX_WALL_HP := 500.0
const TOWERS := [Vector2(205,290),Vector2(855,290),Vector2(240,555),Vector2(845,550)]
const ROUTE := [Vector2(60,40),Vector2(80,100),Vector2(90,180),Vector2(80,275)]
const PROJECTILE := preload("res://projectile_v15.gd")
@onready var boss: Node2D = $Boss
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
var notice := "Destroy wing, then hold F to seal."
var result := ""
var dive_active := false
var dive_elapsed := 0.0
var dive_duration := 0.75
var dive_origin := Vector2.ZERO
var dive_destination := Vector2.ZERO
var dive_damaged := false
var claw_damaged := false
var death_event_emitted := false
var battle_time := 0.0
var attack_cooldown := 0.0
var dive_cooldown := 0.0
var auto_attack_timer := 0.0
var auto_attacks_enabled := true
var attack_sequence := 0
var event_log: Array[String] = []
const ATTACK_INTERVAL := 3.0
const DIVE_COOLDOWN := 5.0
const CLAW_COOLDOWN := 2.0
func _ready() -> void:
    boss.get_node("CanvasLayer").visible = false
    boss.attack_hit.connect(_on_attack_hit)
    boss.dive_impact.connect(_on_dive_impact)
    boss.death_finished.connect(_on_death_finished)
    wing.input_event.connect(_on_wing_click)
    body.input_event.connect(_on_body_click)
    boss.play_state("fly")
    _sync_hitboxes()
    _update_hud()
func _physics_process(delta: float) -> void:
    if _finished():
        _update_hud()
        queue_redraw()
        return
    battle_time += delta
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    dive_cooldown = maxf(0.0, dive_cooldown - delta)
    auto_attack_timer += delta
    if auto_attacks_enabled and auto_attack_timer >= ATTACK_INTERVAL:
        auto_attack_timer -= ATTACK_INTERVAL
        _choose_attack()
    if dive_active:
        _advance_dive(delta)
    elif airborne and route_index < ROUTE.size() and not boss.lock_action:
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
func _finished() -> bool:
    return phase in ["sealed", "defeated", "lost"]
func _sync_hitboxes() -> void:
    body.global_position = boss.global_position + Vector2(480,330)
    wing.global_position = boss.global_position + Vector2(430,245)
    wing.input_pickable = airborne and not _finished()
    wing.monitorable = airborne and not _finished()
    dive.global_position = body.global_position + Vector2(0,70)
    claw.global_position = body.global_position + Vector2(45,65)
func _fire_tower() -> void:
    if _finished(): return
    var origin: Vector2 = TOWERS[shot_count % TOWERS.size()]
    shot_count += 1
    var target: Vector2 = wing.global_position if airborne else body.global_position
    var bullet = PROJECTILE.new()
    bullet.position = origin
    bullet.velocity = (target - origin).normalized() * 520.0
    bullet.damage = 24.0 if airborne else 38.0
    bullet.battle = self
    projectiles.add_child(bullet)
func resolve_projectile_segment(start: Vector2, finish: Vector2, radius: float, damage: float) -> bool:
    ## Explicit wing > body > wall priority. One segment yields at most one hit.
    ## Prevents overlapping Area2D callbacks from applying damage twice.
    if _finished(): return true
    if airborne and _segment_circle(start,finish,wing.global_position,52.0+radius):
        wing_hp = maxf(0.0, wing_hp - damage)
        _damage_boss(damage)
        if wing_hp <= 0.0 and not _finished(): _break_wing()
        return true
    if _segment_circle(start,finish,body.global_position,90.0+radius):
        _damage_boss(damage)
        return true
    return false
func _segment_circle(a: Vector2, b: Vector2, center: Vector2, radius: float) -> bool:
    var ab := b-a
    var t := clampf((center-a).dot(ab)/maxf(ab.length_squared(),0.0001),0.0,1.0)
    return (a+ab*t).distance_squared_to(center) <= radius*radius
func _damage_boss(amount: float) -> void:
    if _finished(): return
    hp = maxf(0.0,hp-amount)
    boss_damaged.emit(amount,hp)
    if hp <= 0.0: _defeat()
func _on_wing_click(_viewport: Node,event: InputEvent,_idx: int) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and airborne and not _finished():
        wing_hp = maxf(0.0,wing_hp-65.0)
        _damage_boss(25.0)
        if wing_hp <= 0.0 and not _finished(): _break_wing()
        get_viewport().set_input_as_handled()
func _on_body_click(_viewport: Node,event: InputEvent,_idx: int) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not _finished():
        ## Clicks in the weakpoint circle belong to wing even when body receives event first.
        if airborne and get_global_mouse_position().distance_to(wing.global_position) <= 52.0: return
        _damage_boss(10.0)
func _break_wing() -> void:
    airborne = false
    dive_active = false
    phase = "grounded"
    notice = "Wing broken. Hold F to seal."
    wing.set_deferred("monitorable",false)
    boss.play_state("hurt")
    wing_destroyed.emit()
    event_log.append("wing_destroyed")
func _choose_attack() -> void:
    if _finished() or boss.lock_action or dive_active or not airborne:
        return
    if attack_sequence % 2 == 0 and dive_cooldown <= 0.0:
        _begin_dive()
    elif attack_cooldown <= 0.0:
        _begin_claw()

func _begin_claw() -> void:
    if _finished() or boss.lock_action or attack_cooldown > 0.0 or dive_active:
        return
    attack_cooldown = CLAW_COOLDOWN
    claw_damaged = false
    attack_sequence += 1
    event_log.append("claw_started")
    boss.play_state("attack")

func _begin_dive() -> void:
    if not airborne or dive_active or boss.lock_action or _finished() or dive_cooldown > 0.0: return
    dive_cooldown = DIVE_COOLDOWN
    attack_sequence += 1
    event_log.append("dive_started")
    dive_active = true
    dive_elapsed = 0.0
    dive_damaged = false
    dive_origin = boss.position
    ## Collision point for body relative to the wall; avoid teleport-on-impact.
    dive_destination = wall.global_position - Vector2(480,405)
    boss.play_state("dive")
    notice = "Dive in progress"
func _advance_dive(delta: float) -> void:
    dive_elapsed = minf(dive_duration,dive_elapsed+delta)
    var t := dive_elapsed/dive_duration
    ## Smooth trajectory with a visible elevated arc.
    var eased := t*t*(3.0-2.0*t)
    boss.position = dive_origin.lerp(dive_destination,eased) + Vector2(0,-95.0*sin(t*PI))
    _sync_hitboxes()
    if not dive_damaged and _circle_rect(dive.global_position,75.0,wall.global_position,Vector2(390,65)):
        dive_damaged = true
        _hit_wall(80.0 if enraged else 55.0,"Dive hit wall")
    if t >= 1.0:
        event_log.append("dive_finished")
        dive_active = false
        if not _finished() and airborne:
            boss.play_state("fly")
func _circle_rect(center: Vector2, radius: float, rect_center: Vector2, rect_size: Vector2) -> bool:
    var half := rect_size*0.5
    var nearest := Vector2(clampf(center.x,rect_center.x-half.x,rect_center.x+half.x),clampf(center.y,rect_center.y-half.y,rect_center.y+half.y))
    return nearest.distance_squared_to(center) <= radius*radius
func _on_dive_impact() -> void:
    ## Animation timing event only; damage is applied by physical trajectory overlap.
    if dive_active: notice = "Dive impact animation event"
func _on_attack_hit() -> void:
    if _finished() or claw_damaged: return
    _sync_hitboxes()
    if _circle_rect(claw.global_position,65.0,wall.global_position,Vector2(390,65)):
        claw_damaged = true
        _hit_wall(35.0 if enraged else 25.0,"Claw hit wall")
func _hit_wall(damage: float, message: String) -> void:
    if _finished(): return
    wall_hp = maxf(0.0,wall_hp-damage)
    wall_damaged.emit(damage,wall_hp)
    event_log.append("wall_hit")
    notice = message
    if wall_hp <= 0.0: _lose()
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_A: _fire_tower()
            KEY_D: _begin_dive()
            KEY_J:
                if not boss.lock_action and not _finished():
                    _begin_claw()
            KEY_R: get_tree().reload_current_scene()
func _seal() -> void:
    if airborne or _finished(): return
    phase = "sealed"
    result = "VICTORY: SEALED"
    notice = "Anti-air guardian bonus +20% (demo)"
    boss_sealed.emit()
    event_log.append("sealed")
    boss.play_state("hurt")
func _defeat() -> void:
    if _finished(): return
    phase = "defeated"
    result = "VICTORY: BOSS DEFEATED"
    boss_died.emit()
    event_log.append("boss_died")
    death_event_emitted = true
    boss.play_state("death")
func _lose() -> void:
    if _finished(): return
    phase = "lost"
    result = "DEFEAT: WALL DESTROYED"
    battle_lost.emit()
    event_log.append("battle_lost")
func _on_death_finished() -> void:
    notice = "Death animation finished"
func _update_hud() -> void:
    hud.text = "QIONGQI v15 | HP %d/1200 | WING %d/300 | WALL %d/500 | %s\n%s | Seal %d%% | %s" % [int(hp),int(wing_hp),int(wall_hp),phase,notice,int(seal_progress/2.5*100.0),result]
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
    draw_rect(Rect2(375,110,360*hp/MAX_HP,15),Color("c33e36"))
