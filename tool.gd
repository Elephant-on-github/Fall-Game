extends AnimatedSprite2D

var tool: String = "none"
var seeds_map: Dictionary = {
	"carrot": true, "radish": true, "corn": true, "tomato": true, "cabbage": true, "wheat": true
}

@onready var number_label: Label = $number

func _ready() -> void:
	tool = "none"
	frame = 3
	stop()
	number_label.visible = false

func _on_farmer_set_tool(tool: String) -> void:
	if tool == "hoe": frame = 2
	elif tool == "spade": frame = 1
	elif tool == "scythe": frame = 3
	elif tool == "none": frame = 0
	elif tool == "carrot": frame = 4
	elif tool == "raddish": frame = 5
	elif tool == "corn": frame = 6
	elif tool == "tomato": frame = 7
	elif tool == "cabbage": frame = 8
	elif tool == "wheat": frame = 9

func update_seed_display(tool_name: String, seed_count: int) -> void:
	_on_farmer_set_tool(tool_name)
	if tool_name in seeds_map:
		number_label.visible = true
		number_label.text = str(seed_count)
		if seed_count <= 0:
			modulate = Color(0.5, 0.5, 0.5, 1.0)
		else:
			modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		number_label.visible = false
		modulate = Color(1.0, 1.0, 1.0, 1.0)
