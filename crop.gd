extends AnimatedSprite2D

@export var growth_interval: float = 5.0

var growth_timer: float = 0.0

func _ready() -> void:
	growth_timer = randf_range(0, growth_interval)

func _process(delta: float) -> void:
	growth_timer -= delta
	if growth_timer <= 0:
		growth_timer = growth_interval * randf_range(0.5, 1.5)
		_grow()

func _grow() -> void:
	var base_frame := -1
	for i in range(6):
		if frame >= i * 4 and frame < (i + 1) * 4:
			base_frame = i * 4
			break
	if base_frame == -1:
		return
	var stage := frame - base_frame
	if stage < 2:
		frame = base_frame + stage + 1
