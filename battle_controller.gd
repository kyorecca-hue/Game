extends Node2D
## Prototype tower-defense encounter. No claim of engine-run validation.
const MAX_HP := 1200.0
const MAX_WING_HP := 300.0
const TOWER_INTERVAL := 0.9
const BOSS_ROUTE := [Vector2(60, 40), Vector2(140, 90), Vector2(250, 120), Vector2(330, 160), Vector2(390, 210)]
const BOSS_SPEED := 45.0
const ATTACK_RADIUS := 155.0
const SEAL_DURATION := 2.5
const WING_RADIUS := 78.0
const WING_POS := Vector2(510, 255)
const SEAL_POS := Vector2(560, 470)
const TOWERS := [Vector2(205, 290), Vector2(855, 290), Vector2(240, 555), Vector2(845, 550)]
@onready var boss = $Boss
@onready var hud: Label = $HUD/Info
var hp := MAX_HP
var wing_hp := MAX_WING_HP
var wall_hp := 500.0
var timer := 0.0
var phase := "approach"
var airborne := true
var sealed := false
var tower_shots := 0
var impact_count := 0
var route_index := 1
var seal_progress := 0.0
var phase_two := false
var battle_result := ""
var notice := "Click near the red wing circle to break flight."

func _ready() -> void:
    boss.get_node("CanvasLayer").visible = false
    boss.attack_hit.connect(_on_attack_hit)
    boss.dive_impact.connect(_on_dive_impact)
    boss.death_finished.connect(_on_death_finished)
    boss.play_state("fly")
    queue_redraw()

func _process(delta: float) -> void:
    if phase in ["defeated", "sealed", "lost"]:
        _update_hud()
        queue_redraw()
        return
    if not airborne and Input.is_key_pressed(KEY_F):
        seal_progress += delta
        if seal_progress >= SEAL_DURATION:
            _seal()
    else:
        seal_progress = maxf(0.0, seal_progress - delta * 0.5)
    if airborne and route_index < BOSS_ROUTE.size() and not boss.lock_action:
        var destination: Vector2 = BOSS_ROUTE[route_index]
        boss.position = boss.position.move_toward(destination, BOSS_SPEED * delta)
        if boss.position.distance_to(destination) < 1.0:
            route_index += 1
    timer += delta
    if timer >= TOWER_INTERVAL:
        timer -= TOWER_INTERVAL
        _tower_fire()
    if hp <= MAX_HP * 0.5 and not phase_two:
        phase_two = true
        notice = "PHASE 2: Enraged! Faster attacks."
    if wall_hp <= 0.0:
        _lose()
    _update_hud()
    queue_redraw()

func _tower_fire() -> void:
    if phase in ["defeated", "sealed", "lost"]: return
    tower_shots += 1
    var damage := 24.0 if airborne else 38.0
    hp = maxf(0.0, hp - damage)
    if hp <= 0.0:
        _defeat()
    elif tower_shots % 5 == 0 and not boss.lock_action:
        boss.play_state("attack")

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if phase in ["defeated", "sealed", "lost"]: return
        if airborne and event.position.distance_to(_wing_position()) <= WING_RADIUS:
            wing_hp = maxf(0.0, wing_hp - 65.0)
            notice = "Wing weakpoint hit: -65"
            if wing_hp <= 0.0:
                airborne = false
                phase = "grounded"
                notice = "Wings disabled! Seal now available (F)."
                boss.play_state("hurt")
        elif not airborne and event.position.distance_to(SEAL_POS) <= 100.0:
            seal_progress = minf(SEAL_DURATION, seal_progress + 0.5)
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_A:
                _tower_fire()
            KEY_D:
                if airborne and not boss.lock_action: boss.play_state("dive")
            KEY_F:
                if not airborne: seal_progress = minf(SEAL_DURATION, seal_progress + 0.5)
            KEY_R:
                get_tree().reload_current_scene()
    _update_hud()
    queue_redraw()

func _seal() -> void:
    if airborne or sealed or phase in ["defeated", "lost"]: return
    sealed = true
    phase = "sealed"
    notice = "Qiongqi sealed! Reward: anti-air tower damage +20% (demo flag)."
    battle_result = "VICTORY: SEALED"
    boss.play_state("hurt")

func _lose() -> void:
    if phase in ["defeated", "sealed", "lost"]: return
    phase = "lost"
    battle_result = "DEFEAT: BASTION DESTROYED"
    notice = battle_result + " | Press R to restart."

func _wing_position() -> Vector2:
    return boss.position + Vector2(450, 215)

func _defeat() -> void:
    phase = "defeated"
    battle_result = "VICTORY: BOSS DEFEATED"
    notice = "Boss defeated. Press R to restart."
    boss.play_state("death")

func _on_attack_hit() -> void:
    if phase == "defeated" or sealed: return
    if boss.position.distance_to(Vector2(560, 470)) > ATTACK_RADIUS: return
    wall_hp = maxf(0.0, wall_hp - (35.0 if phase_two else 25.0))
    notice = "Claw attack damaged the bastion (-25)."

func _on_dive_impact() -> void:
    if phase == "defeated" or sealed: return
    impact_count += 1
    wall_hp = maxf(0.0, wall_hp - (80.0 if phase_two else 55.0))
    notice = "Dive impact! Bastion -55."

func _on_death_finished() -> void:
    notice = "Death animation completed."

func _update_hud() -> void:
    hud.text = "QIONGQI v11 | HP: %d/1200 | WINGS: %d/300 | BASTION: %d/500 | %s\n%s | Seal: %d%% %s" % [int(hp), int(wing_hp), int(wall_hp), "ENRAGED" if phase_two else phase, notice, int(seal_progress / SEAL_DURATION * 100.0), battle_result]

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(1100, 760)), Color("171b20"))
    # Isometric-inspired paving and a simple bastion. Visual test geometry only.
    for y in range(160, 720, 65):
        draw_line(Vector2(0, y), Vector2(1100, y), Color("3c3833"), 1.0)
    for x in range(-300, 1300, 100):
        draw_line(Vector2(x, 160), Vector2(x + 290, 720), Color("343634"), 1.0)
    draw_rect(Rect2(365, 600, 390, 65), Color("56534c"))
    draw_rect(Rect2(375, 595, 370, 13), Color("8a7860"))
    for p in TOWERS:
        draw_circle(p, 34.0, Color("2b343d"))
        draw_circle(p, 23.0, Color("9d7951"))
        draw_circle(p, 13.0, Color("db8d40"))
    draw_arc(_wing_position(), WING_RADIUS, 0, TAU, 60, Color("e74738") if airborne else Color("6c6969"), 3.0)
    if not airborne:
        draw_arc(SEAL_POS, 95.0, 0, TAU, 64, Color("ed5144"), 4.0)
        draw_arc(SEAL_POS, 66.0, 0, TAU, 64, Color("d9a359"), 2.0)
    draw_rect(Rect2(375, 110, 360, 15), Color("3b2424"))
    draw_rect(Rect2(375, 110, 360 * hp / MAX_HP, 15), Color("c33e36"))
    draw_rect(Rect2(375, 134, 360, 8), Color("29313c"))
    draw_rect(Rect2(375, 134, 360 * wing_hp / MAX_WING_HP, 8), Color("db9a49"))

# v11: Route, collision radius, seal progress and victory/defeat are gameplay prototypes.
