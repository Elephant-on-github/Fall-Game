extends CharacterBody2D

@export var speed: float = 200.0

# Reference the audio player node
@onready var footstep_player: AudioStreamPlayer2D = $Footsteps

const crop_scene = preload("res://crop.tscn")
const dirt_scene = preload("res://dirt.tscn")
const leaf_scene = preload("res://leaf.tscn")
signal set_tool(tool : String)
var current_tool: String = "none"
var hoed_tiles: Dictionary = {}
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

		match current_tool:
			"spade":
				if existing_tile != null and tile_map_layer.get_cell_source_id(tile_coords) == 0:
					tile_map_layer.erase_cell(tile_coords)
				hoed_tiles.erase(tile_key)

			"hoe":
				if existing_tile != null:
					_show_tooltip("Can't hoe here!")
					return
				var new_dirt = dirt_scene.instantiate()
				new_dirt.global_position = world_pos
				get_tree().current_scene.add_child(new_dirt)
				hoed_tiles[tile_key] = true
			"scythe": pass

			_:
				if not hoed_tiles.has(tile_key):
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
	tooltip_tween.tween_property(tooltip_label, "modulate:a", 0.0, 0.8)
	tooltip_tween.tween_callback(func(): tooltip_label.visible = false)

func _process(delta: float) -> void:
	leaf_spawn_timer -= delta
	if leaf_spawn_timer <= 0:
		leaf_spawn_timer = leaf_frequency
		_spawn_leaf()

func _spawn_leaf() -> void:
	var leaf = leaf_scene.instantiate()
	get_node("/root/main/UI").add_child(leaf)
	var screen_size = get_viewport_rect().size
	leaf.position = Vector2(randf_range(0, screen_size.x), -50)

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
