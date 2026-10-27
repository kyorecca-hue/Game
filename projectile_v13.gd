extends Area2D
signal impacted(damage: float, target: String)
var velocity := Vector2.ZERO
var damage := 24.0
var lifetime := 3.0
var consumed := false
func _ready() -> void:
    collision_layer = 64
    collision_mask = 2 | 4 | 8
    monitoring = true
    monitorable = true
    var hit := CollisionShape2D.new()
    var shape := CircleShape2D.new()
    shape.radius = 7.0
    hit.shape = shape
    add_child(hit)
    area_entered.connect(_on_area_entered)
    queue_redraw()
func _physics_process(delta: float) -> void:
    if consumed: return
    position += velocity * delta
    lifetime -= delta
    if lifetime <= 0.0: queue_free()
func _draw() -> void:
    draw_circle(Vector2.ZERO, 7.0, Color("f6b24b"))
func _on_area_entered(area: Area2D) -> void:
    if consumed: return
    if area.name == "Weakpoint":
        consumed = true
        impacted.emit(damage, "wing")
    elif area.name == "BossBody":
        consumed = true
        impacted.emit(damage, "body")
    elif area.name == "WallHitbox":
        consumed = true
    if consumed: queue_free()
