extends AnimatedSprite2D

var tool: String = "none"

func _ready() -> void:
	tool = "none"
	frame = 3
	stop()

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
