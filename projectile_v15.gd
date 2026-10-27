extends Area2D
## Swept projectile: checks the entire travel segment, not only the endpoint.
## Hit priority is resolved once by battle_controller_v15.gd.
var velocity := Vector2.ZERO
var damage := 24.0
var lifetime := 3.0
var consumed := false
var battle: Node2D
func _ready() -> void:
    collision_layer = 64
    collision_mask = 0
    monitoring = false
    monitorable = false
    queue_redraw()
func _physics_process(delta: float) -> void:
    if consumed: return
    var start := global_position
    var finish := start + velocity*delta
    if is_instance_valid(battle) and battle.resolve_projectile_segment(start,finish,7.0,damage):
        consumed = true
        queue_free()
        return
    global_position = finish
    lifetime -= delta
    if lifetime <= 0.0: queue_free()
func _draw() -> void:
    draw_circle(Vector2.ZERO,7.0,Color("f6b24b"))
