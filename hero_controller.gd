extends Node2D
## Simple prototype hero; simulation is advanced by the battle controller.
const MAX_HEALTH := 180.0
const SPEED := 225.0
const RESPAWN_SECONDS := 10.0
const SPAWN := Vector2(550, 680)
const ARENA := Rect2(35, 165, 1030, 520)
var health := MAX_HEALTH
var respawn_left := 0.0
var invulnerable_left := 0.0
var destination := SPAWN
var moving_to_destination := false
var facing := Vector2.UP
var attack_flash := 0.0
var step_time := 0.0
var is_moving := false

static func ensure_input_actions() -> void:
    var bindings := {"hero_left":KEY_A, "hero_right":KEY_D, "hero_up":KEY_W, "hero_down":KEY_S}
    for action in bindings:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
            var key := InputEventKey.new()
            key.physical_keycode = bindings[action]
            InputMap.action_add_event(action, key)

func _ready() -> void:
    ensure_input_actions()
    position = SPAWN
    z_index = 8

func is_alive() -> bool:
    return health > 0.0

func set_destination(point: Vector2) -> void:
    if not is_alive(): return
    destination = point.clamp(ARENA.position, ARENA.end)
    moving_to_destination = true

func advance(delta: float, direction: Vector2) -> void:
    attack_flash = maxf(0.0, attack_flash - delta)
    invulnerable_left = maxf(0.0, invulnerable_left - delta)
    is_moving = false
    if not is_alive():
        respawn_left = maxf(0.0, respawn_left - delta)
        if respawn_left <= 0.0:
            health = MAX_HEALTH
            position = SPAWN
            invulnerable_left = 2.0
            moving_to_destination = false
        queue_redraw()
        return
    var previous := position
    if direction.length_squared() > 0.0:
        moving_to_destination = false
        position += direction.limit_length() * SPEED * delta
    elif moving_to_destination:
        position = position.move_toward(destination, SPEED * delta)
        if position.distance_to(destination) < 1.0: moving_to_destination = false
    position = position.clamp(ARENA.position, ARENA.end)
    if position.distance_squared_to(previous) > 0.001:
        facing = (position - previous).normalized()
        is_moving = true
        step_time += delta * 12.0
    queue_redraw()

func take_damage(amount: float) -> bool:
    if not is_alive() or invulnerable_left > 0.0 or amount <= 0.0: return false
    health = maxf(0.0, health - amount)
    invulnerable_left = 0.6
    if health <= 0.0:
        respawn_left = RESPAWN_SECONDS
        moving_to_destination = false
    queue_redraw()
    return true

func _draw() -> void:
    var font := ThemeDB.fallback_font
    if not is_alive():
        draw_arc(Vector2.ZERO, 22, 0, TAU, 40, Color("777f8e"), 2)
        draw_string(font, Vector2(-26, -28), "%ds" % ceili(respawn_left), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
        return
    draw_circle(Vector2(0, 6), 19, Color(0,0,0,0.35))
    var stride := sin(step_time) * 4.0 if is_moving else 0.0
    draw_line(Vector2(-5,4),Vector2(-8,16+stride),Color("bac3ce"),6)
    draw_line(Vector2(5,4),Vector2(8,16-stride),Color("bac3ce"),6)
    draw_colored_polygon(PackedVector2Array([Vector2(-12,-6),Vector2(12,-6),Vector2(17,17),Vector2(0,11),Vector2(-17,17)]),Color("207c83"))
    draw_rect(Rect2(-9,-13,18,23),Color("a2c8ce"))
    draw_line(Vector2(-9,-5),Vector2(9,-5),Color("e7c47c"),3)
    draw_circle(Vector2(0,-19),9,Color("e9c09c"))
    draw_arc(Vector2(0,-20),10,PI,TAU,20,Color("e0dbca"),5)
    draw_line(Vector2(0,-28),Vector2(-4,-36),Color("c44843"),5)
    draw_line(Vector2(13,-5),Vector2(13,-5)+facing*31,Color("efdfb2"),4)
    draw_circle(Vector2(-13,-3),7,Color("586d7b"))
    draw_arc(Vector2.ZERO,25,0,TAU,48,Color("62d9d0"),2)
    if invulnerable_left > 0.0:
        draw_arc(Vector2.ZERO,29,0,TAU,48,Color("f3dc91"),2)
    if attack_flash > 0.0:
        draw_arc(Vector2.ZERO,65,facing.angle()-0.9,facing.angle()+0.9,32,Color("ffe8a5"),4)
    draw_rect(Rect2(-22,-44,44,5),Color("3b3438"))
    draw_rect(Rect2(-22,-44,44*health/MAX_HEALTH,5),Color("66d2a5"))
    draw_string(font,Vector2(-25,38),"HERO",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("9ce6df"))
