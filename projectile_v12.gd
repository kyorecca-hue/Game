extends Area2D
signal impacted(damage: float, weakpoint: bool)
var velocity := Vector2.ZERO
var damage := 24.0
var weakpoint := false
var lifetime := 3.0
func _ready() -> void:
    collision_layer = 8
    collision_mask = 2 | 4
    monitoring = true
    monitorable = true
    var shape := CollisionShape2D.new()
    var circle := CircleShape2D.new()
    circle.radius = 7.0
    shape.shape = circle
    add_child(shape)
    area_entered.connect(_on_area_entered)
    queue_redraw()
func _physics_process(delta: float) -> void:
    position += velocity * delta
    lifetime -= delta
    if lifetime <= 0.0:
        queue_free()
func _draw() -> void:
    draw_circle(Vector2.ZERO, 7.0, Color("f6b24b"))
    draw_circle(Vector2.ZERO, 3.0, Color("fff2bf"))
func _on_area_entered(area: Area2D) -> void:
    if area.name == "Weakpoint":
        impacted.emit(damage, true)
        queue_free()
    elif area.name == "WallHitbox":
        queue_free()
