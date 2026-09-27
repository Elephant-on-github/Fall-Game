extends Sprite2D

@export var fall_speed: float = 100.0
@export var sway_speed: float = 2.0
@export var sway_amount: float = 20.0

var start_position: Vector2

func _ready() -> void:
	start_position = global_position

func _process(delta: float) -> void:
	global_position.y += fall_speed * delta
	global_position.x = start_position.x + sin(Time.get_ticks_msec() / 1000.0 * sway_speed) * sway_amount
	var cam = get_node_or_null("/root/main/Camera2D")
	if cam != null:
		var threshold = cam.position.y + (get_viewport_rect().size.y / cam.zoom.y) + 50
		if global_position.y > threshold:
			queue_free()
	else:
		if global_position.y > get_viewport_rect().size.y + 50:
			queue_free()
