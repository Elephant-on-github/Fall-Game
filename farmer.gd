extends CharacterBody2D

@export var speed: float = 200.0

# Reference the audio player node
@onready var footstep_player: AudioStreamPlayer2D = $Footsteps

const crop_scene = preload("res://crop.tscn")
const dirt_scene = preload("res://dirt.tscn")
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


@onready var tile_map_layer: TileMapLayer = %Main_Tiles

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
		elif event.keycode == KEY_H:
			set_tool.emit("hoe")
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

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_world_pos = get_global_mouse_position()
		var tile_coords = tile_map_layer.local_to_map(tile_map_layer.to_local(mouse_world_pos))
		var existing_tile = tile_map_layer.get_cell_tile_data(tile_coords)
		var world_pos = tile_map_layer.to_global(tile_map_layer.map_to_local(tile_coords))
		var tile_key = str(tile_coords)

		match current_tool:
			"spade":
				if existing_tile != null:
					tile_map_layer.erase_cell(tile_coords)
				hoed_tiles.erase(tile_key)

			"hoe":
				if existing_tile != null:
					return
				var new_dirt = dirt_scene.instantiate()
				new_dirt.global_position = world_pos
				get_tree().current_scene.add_child(new_dirt)
				hoed_tiles[tile_key] = true

			_:
				if not hoed_tiles.has(tile_key):
					return
				var crop_type = current_tool
				var new_crop = crop_scene.instantiate()
				new_crop.stop()
				new_crop.frame = crop_frames[crop_type]
				new_crop.global_position = world_pos
				get_tree().current_scene.add_child(new_crop)
func _on_set_tool(tool: String) -> void:
	current_tool = tool
func _ready() -> void:
	set_tool.emit("none")
	%Menu.visible = true
	%Tool.tool = "none"


func _on_button_pressed() -> void:
	%Menu.visible = false
