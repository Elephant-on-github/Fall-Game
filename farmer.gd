extends CharacterBody2D

@export var speed: float = 200.0

# Reference the audio player node
@onready var footstep_player: AudioStreamPlayer2D = $Footsteps

const crop_scene = preload("res://crop.tscn")

const leaf_scene = preload("res://leaf.tscn")
signal set_tool(tool : String)
var current_tool: String = "none"
var crops: Dictionary = {}
var crop_frames: Dictionary = {
	"carrot": 0,
	"radish": 4,
	"corn": 8,
	"tomato": 12,
	"cabbage": 16,
	"wheat": 20
}
var seeds: Dictionary = {
	"carrot": 5,
	"radish": 5,
	"corn": 5,
	"tomato": 5,
	"cabbage": 5,
	"wheat": 5
}
var score: int = 0
var shop_open: bool = false
var shop_items: Dictionary = {
	"Carrot": 3,
	"Raddish": 3,
	"Corn": 3,
	"Tomato": 3,
	"Cabbage": 3,
	"wheat": 3,
	"Scythe": 3,
	"Hoe": 3,
	"Spade": 3
}
var shop_seed_map: Dictionary = {
	"Carrot": "carrot",
	"Raddish": "radish",
	"Corn": "corn",
	"Tomato": "tomato",
	"Cabbage": "cabbage",
	"wheat": "wheat"
}
var shop_tool_map: Dictionary = {
	"Scythe": "scythe",
	"Hoe": "hoe",
	"Spade": "spade"
}

@export var leaf_frequency: float = 1.0
var leaf_spawn_timer: float = 0.0
var tooltip_tween: Tween = null
@onready var tile_map_layer: TileMapLayer = %Main_Tiles
@onready var tooltip_label = get_node("/root/main/UI/MarginContainer2/tooltip")
@onready var shop_canvas: CanvasLayer = get_node("/root/main/Shop")
@onready var score_label: Label = get_node("/root/main/UI/MarginContainer3/CenterContainer/Score")

func _physics_process(_delta: float) -> void:
	# Track whether a movement key is actually being held down
	var is_trying_to_move = false
	
	velocity = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		velocity.x = speed
		is_trying_to_move = true
	elif Input.is_action_pressed("ui_left"):
		velocity.x = -speed
		is_trying_to_move = true
	elif Input.is_action_pressed("ui_down"):
		velocity.y = speed
		is_trying_to_move = true
	elif Input.is_action_pressed("ui_up"):
		velocity.y = -speed
		is_trying_to_move = true

	# Moves the character and handles wall collisions
	move_and_slide()

	# Play sound ONLY if we are trying to move AND our movement isn't blocked by a wall
	if is_trying_to_move and velocity != Vector2.ZERO:
		if not footstep_player.playing:
			footstep_player.play()
	else:
		footstep_player.stop()
		
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			set_tool.emit("spade")
		elif event.keycode == KEY_R:
			set_tool.emit("hoe")
		elif event.keycode == KEY_T:
			set_tool.emit("scythe")
		elif event.keycode == KEY_1:
			set_tool.emit("carrot")
		elif event.keycode == KEY_2:
			set_tool.emit("radish")
		elif event.keycode == KEY_3:
			set_tool.emit("corn")
		elif event.keycode == KEY_4:
			set_tool.emit("tomato")
		elif event.keycode == KEY_5:
			set_tool.emit("cabbage")
		elif event.keycode == KEY_6:
			set_tool.emit("wheat")

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and shop_open:
		shop_open = false
		shop_canvas.visible = false
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_world_pos = get_global_mouse_position()
		var mouse_screen_pos = get_viewport().get_mouse_position()

		if shop_open:
			var grid = shop_canvas.get_node("ColorRect/MarginContainer/TextureRect/GridContainer")
			for child in grid.get_children():
				if child is TextureRect:
					var rect = child.get_rect()
					var global_rect = Rect2(child.global_position, rect.size)
					if mouse_screen_pos.x >= global_rect.position.x and mouse_screen_pos.x <= global_rect.position.x + global_rect.size.x and mouse_screen_pos.y >= global_rect.position.y and mouse_screen_pos.y <= global_rect.position.y + global_rect.size.y:
						_buy_item(child.name)
						return
			shop_open = false
			shop_canvas.visible = false
			return

		var tile_coords = tile_map_layer.local_to_map(tile_map_layer.to_local(mouse_world_pos))
		var existing_tile = tile_map_layer.get_cell_tile_data(tile_coords)
		var world_pos = tile_map_layer.to_global(tile_map_layer.map_to_local(tile_coords))
		var tile_key = str(tile_coords)

		if existing_tile != null and tile_map_layer.get_cell_source_id(tile_coords) == 3:
			shop_open = !shop_open
			shop_canvas.visible = shop_open
			return

		var source_id = tile_map_layer.get_cell_source_id(tile_coords) if existing_tile != null else -1

		if source_id == 4:
			_show_tooltip("click on shop to buy more")
			return

		if source_id == 5:
			_show_tooltip("Use scythe to harvest!")
			return

		if source_id == 6:
			if current_tool in seeds:
				if seeds[current_tool] <= 0:
					_show_tooltip("No seeds left!")
					return
				seeds[current_tool] -= 1
				var new_crop = crop_scene.instantiate()
				new_crop.stop()
				new_crop.frame = crop_frames[current_tool]
				new_crop.global_position = world_pos
				get_tree().current_scene.add_child(new_crop)
				crops[tile_key] = new_crop
				%Tool.update_seed_display(current_tool, seeds[current_tool])
			else:
				_show_tooltip("Select a seed with number keys!")
			return

		if source_id == 7:
			_show_tooltip("select tool with e,r,t")
			return

		match current_tool:
			"spade":
				if existing_tile != null and tile_map_layer.get_cell_source_id(tile_coords) in [8, 0]:
					tile_map_layer.erase_cell(tile_coords)

			"hoe":
				if existing_tile != null:
					_show_tooltip("Can't hoe here!")
					return
				tile_map_layer.set_cell(tile_coords, 8, Vector2i.ZERO, 0)
			"scythe":
				if crops.has(tile_key):
					var crop = crops[tile_key]
					if crop.frame % 4 == 2:
						crop.queue_free()
						crops.erase(tile_key)
						score += 5
						_update_score()
					else:
						_show_tooltip("Crop not ready yet!")
				else:
					_show_tooltip("No crop to harvest!")

			_:
				if source_id != 8:
					_show_tooltip("Need to hoe this first!")
					return
					var crop_type = current_tool
					if seeds[crop_type] <= 0:
						_show_tooltip("No seeds left!")
						return
					seeds[crop_type] -= 1
					var new_crop = crop_scene.instantiate()
					new_crop.stop()
					new_crop.frame = crop_frames[crop_type]
					new_crop.global_position = world_pos
					get_tree().current_scene.add_child(new_crop)
					%Tool.update_seed_display(crop_type, seeds[crop_type])

func _update_score() -> void:
	score_label.text = str(score)

func _buy_item(item_name: String) -> void:
	var price = shop_items[item_name]
	if score < price:
		_show_tooltip("Insufficient score!")
		return
	score -= price
	_update_score()
	if item_name in shop_seed_map:
		var crop_type = shop_seed_map[item_name]
		seeds[crop_type] += 1
		_show_tooltip("Bought " + item_name + "!")
	elif item_name in shop_tool_map:
		var tool_name = shop_tool_map[item_name]
		set_tool.emit(tool_name)
		_show_tooltip("Bought " + item_name + "!")

func _show_tooltip(text: String) -> void:
	tooltip_label.text = text
	tooltip_label.visible = true
	tooltip_label.modulate.a = 1.0
	if tooltip_tween != null and tooltip_tween.is_valid():
		tooltip_tween.kill()
	tooltip_tween = create_tween()
	tooltip_tween.tween_property(tooltip_label, "modulate:a", 0.0, 2.0)
	tooltip_tween.tween_callback(func(): tooltip_label.visible = false)

func _process(delta: float) -> void:
	leaf_spawn_timer -= delta
	if leaf_spawn_timer <= 0:
		leaf_spawn_timer = leaf_frequency * randf_range(0.5, 1.5)
		_spawn_leaf()

func _spawn_leaf() -> void:
	var leaf = leaf_scene.instantiate()
	get_node("/root/main/UI").add_child(leaf)

func _on_set_tool(tool: String) -> void:
	current_tool = tool
	if tool in seeds:
		%Tool.update_seed_display(tool, seeds[tool])
	else:
		%Tool.update_seed_display(tool, 0)
func _ready() -> void:
	set_tool.emit("none")
	%Menu.visible = true
	%Tool.tool = "none"
	%UI.visible = false
	_update_score()


func _on_button_pressed() -> void:
	%Menu.visible = false
	shop_open = false
	shop_canvas.visible = false
	%UI.visible = true
