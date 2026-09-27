extends TextureRect

@export var fall_speed: float = 100.0
@export var sway_speed: float = 2.0
@export var sway_amount: float = 20.0

var start_position: Vector2

func _ready() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	position = Vector2(randf_range(0, screen_size.x), -50)
	start_position = position

func _process(delta: float) -> void:
	position.y += fall_speed * delta
	position.x = start_position.x + sin(Time.get_ticks_msec() / 1000.0 * sway_speed) * sway_amount
	if position.y > get_viewport().get_visible_rect().size.y + 50:
		queue_free()
