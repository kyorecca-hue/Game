extends Node2D
const MAX_HP := 1200.0
const MAX_WING_HP := 300.0
const MAX_WALL_HP := 500.0
const TOWER_INTERVAL := 0.9
const BOSS_ROUTE := [Vector2(60, 40), Vector2(140, 90), Vector2(250, 120), Vector2(330, 160), Vector2(390, 210)]
const BOSS_SPEED := 45.0
const SEAL_DURATION := 2.5
const TOWERS := [Vector2(205, 290), Vector2(855, 290), Vector2(240, 555), Vector2(845, 550)]
const PROJECTILE_SCRIPT = preload("res://projectile_v12.gd")
@onready var boss = $Boss
@onready var hud: Label = $HUD/Info
@onready var weakpoint: Area2D = $Weakpoint
@onready var wall_hitbox: Area2D = $WallHitbox
@onready var projectiles: Node2D = $Projectiles
var hp := MAX_HP
var wing_hp := MAX_WING_HP
var wall_hp := MAX_WALL_HP
var tower_timer := 0.0
var phase := "approach"
var airborne := true
var route_index := 1
var seal_progress := 0.0
var phase_two := false
var shots := 0
var notice := "Shoot the wing weakpoint to disable flight."
var result := ""
func _ready() -> void:
    boss.get_node("CanvasLayer").visible = false
    boss.attack_hit.connect(_on_attack_hit)
    boss.dive_impact.connect(_on_dive_impact)
    boss.death_finished.connect(_on_death_finished)
    weakpoint.input_event.connect(_on_weakpoint_input)
    boss.play_state("fly")
    _update_hud()
func _physics_process(delta: float) -> void:
    if phase in ["sealed", "defeated", "lost"]:
        _update_hud()
        queue_redraw()
        return
    weakpoint.global_position = boss.global_position + Vector2(450, 215)
    weakpoint.monitorable = airborne
    if airborne and route_index < BOSS_ROUTE.size() and not boss.lock_action:
        boss.position = boss.position.move_toward(BOSS_ROUTE[route_index], BOSS_SPEED * delta)
        if boss.position.distance_to(BOSS_ROUTE[route_index]) < 1.0:
            route_index += 1
    tower_timer += delta
    if tower_timer >= TOWER_INTERVAL:
        tower_timer -= TOWER_INTERVAL
        _fire_tower()
    if not airborne and Input.is_key_pressed(KEY_F):
        seal_progress = minf(SEAL_DURATION, seal_progress + delta)
        if seal_progress >= SEAL_DURATION:
            _seal()
    else:
        seal_progress = maxf(0.0, seal_progress - delta * 0.5)
    if hp <= MAX_HP * 0.5 and not phase_two:
        phase_two = true
        notice = "Phase 2: Enraged"
    if wall_hp <= 0.0:
        _lose()
    _update_hud()
    queue_redraw()
func _fire_tower() -> void:
    if phase in ["sealed", "defeated", "lost"]:
        return
    var source: Vector2 = TOWERS[shots % TOWERS.size()]
    shots += 1
    var target: Vector2 = weakpoint.global_position if airborne else boss.global_position + Vector2(500, 330)
    var direction: Vector2 = (target - source).normalized()
    var projectile: Area2D = Area2D.new()
    projectile.set_script(PROJECTILE_SCRIPT)
    projectile.position = source
    projectile.velocity = direction * 480.0
    projectile.damage = 24.0 if airborne else 38.0
    projectile.impacted.connect(_on_projectile_impact)
    projectiles.add_child(projectile)
func _on_projectile_impact(damage: float, hit_weakpoint: bool) -> void:
    if phase in ["sealed", "defeated", "lost"]:
        return
    hp = maxf(0.0, hp - damage)
    if hit_weakpoint and airborne:
        wing_hp = maxf(0.0, wing_hp - damage * 0.65)
        if wing_hp <= 0.0:
            _break_wing()
    if hp <= 0.0:
        _defeat()
func _on_weakpoint_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and airborne and phase not in ["sealed", "defeated", "lost"]:
        wing_hp = maxf(0.0, wing_hp - 65.0)
        notice = "Wing weakpoint hit!"
        if wing_hp <= 0.0:
            _break_wing()
func _break_wing() -> void:
    airborne = false
    phase = "grounded"
    notice = "Wings disabled. Hold F to seal."
    weakpoint.set_deferred("monitorable", false)
    boss.play_state("hurt")
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_A: _fire_tower()
            KEY_D:
                if airborne and not boss.lock_action and phase not in ["sealed", "defeated", "lost"]:
                    boss.play_state("dive")
            KEY_R: get_tree().reload_current_scene()
func _seal() -> void:
    if airborne or phase in ["sealed", "defeated", "lost"]:
        return
    phase = "sealed"
    result = "VICTORY: SEALED"
    notice = "Guardian bonus: anti-air damage +20% (demo flag)"
    boss.play_state("hurt")
func _defeat() -> void:
    if phase in ["sealed", "defeated", "lost"]:
        return
    phase = "defeated"
    result = "VICTORY: BOSS DEFEATED"
    boss.play_state("death")
func _lose() -> void:
    if phase in ["sealed", "defeated", "lost"]:
        return
    phase = "lost"
    result = "DEFEAT: WALL DESTROYED"
func _on_attack_hit() -> void:
    if phase in ["sealed", "defeated", "lost"]:
        return
    if boss.global_position.distance_to(wall_hitbox.global_position) <= 180.0:
        wall_hp = maxf(0.0, wall_hp - (35.0 if phase_two else 25.0))
func _on_dive_impact() -> void:
    if phase in ["sealed", "defeated", "lost"]:
        return
    wall_hp = maxf(0.0, wall_hp - (80.0 if phase_two else 55.0))
    notice = "Dive impact on wall"
func _on_death_finished() -> void:
    notice = "Death animation finished"
func _update_hud() -> void:
    hud.text = "QIONGQI v12 | HP %d/1200 | WING %d/300 | WALL %d/500 | %s\n%s | Seal %d%% | %s" % [int(hp), int(wing_hp), int(wall_hp), phase, notice, int(seal_progress / SEAL_DURATION * 100.0), result]
func _draw() -> void:
    draw_rect(Rect2(0, 0, 1100, 760), Color("171b20"))
    for y in range(160, 720, 65):
        draw_line(Vector2(0, y), Vector2(1100, y), Color("3c3833"), 1.0)
    for x in range(-300, 1300, 100):
        draw_line(Vector2(x, 160), Vector2(x + 290, 720), Color("343634"), 1.0)
    draw_rect(Rect2(365, 600, 390, 65), Color("56534c"))
    for point in TOWERS:
        draw_circle(point, 27.0, Color("9d7951"))
        draw_circle(point, 12.0, Color("db8d40"))
    draw_arc(weakpoint.position, 78.0, 0.0, TAU, 64, Color("e74738") if airborne else Color("777777"), 3.0)
    if not airborne:
        draw_arc(Vector2(560, 470), 95.0, 0.0, TAU, 64, Color("ed5144"), 4.0)
    draw_rect(Rect2(375, 110, 360, 15), Color("3b2424"))
    draw_rect(Rect2(375, 110, 360 * hp / MAX_HP, 15), Color("c33e36"))
