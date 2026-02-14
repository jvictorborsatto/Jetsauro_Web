# terreno.gd
extends Node2D

@export var superficie_scene: PackedScene
@export var terra_scene: PackedScene

# Yucca configuration
@export_group("Yucca Config")
@export var yucca_folhas_scene: PackedScene
@export var chance_yucca_folhas: float = 0.05
@export var yucca_media_scene: PackedScene
@export var chance_yucca_media: float = 0.07

var block_height := 32
var block_width := 32
var screen_size: Vector2
var generating := true

# Terrain generation tracking
var last_height := 5
var last_pos_x := 0.0
var next_pos_x := 0.0
var generation_margin := 500.0  # generate blocks this far ahead

# Yucca tracking
var active_yuccas: Array = []

# Optional Pteropunk tracking
var pteropunk_spawned: bool = false
var pteropunk_position: float = 0.0


func _ready():
	randomize()
	await get_tree().process_frame
	screen_size = get_viewport().get_visible_rect().size

	if not superficie_scene or not terra_scene:
		push_error("❌ Terrain scenes not loaded")
		return
	
	_generate_initial_ground()
	next_pos_x = last_pos_x


func _process(delta):
	if not generating:
		return

	_remove_old_blocks()
	_remove_old_yuccas()

	# Incremental terrain generation: generate one block per frame
	if next_pos_x < last_pos_x + screen_size.x + generation_margin:
		_generate_column(next_pos_x)
		next_pos_x += block_width
		last_pos_x = next_pos_x


func _generate_initial_ground():
	var required_blocks = int(screen_size.x / block_width) + 2
	last_height = 5
	
	for i in range(required_blocks):
		var pos_x = i * block_width
		_generate_column(pos_x)
	
	last_pos_x = required_blocks * block_width
	next_pos_x = last_pos_x


func _generate_column(pos_x: float):
	if _block_exists_at_x(pos_x):
		return

	# Random height variation
	var variation = 0
	if randf() > 0.7:
		variation = randi_range(-1, 2)
	elif randf() < 0.2:
		variation = randi_range(-2, 3)
	
	var new_height = clamp(last_height + variation, 3, int(screen_size.y / block_height * 0.45))
	last_height = new_height
	var surface_y = screen_size.y - (new_height * block_height)

	# Ground blocks
	var y_ground = surface_y + block_height
	while y_ground < screen_size.y:
		var ground = terra_scene.instantiate()
		ground.position = Vector2(pos_x, y_ground + 64)
		add_child(ground)
		y_ground += block_height

	# Surface block
	var surface = superficie_scene.instantiate()
	surface.position = Vector2(pos_x, surface_y + 2 * block_height + 1)
	add_child(surface)

	# Try to spawn Yucca on surface
	if _can_spawn_yucca(pos_x):
		_try_add_yucca(pos_x, surface_y + 2 * block_height + 1)


func _can_spawn_yucca(pos_x: float) -> bool:
	if not pteropunk_spawned:
		return true
	var distance = abs(pos_x - pteropunk_position)
	return distance >= 100.0  # default yucca spacing


func _try_add_yucca(pos_x: float, surface_height: float):
	var yucca_options = []
	if yucca_folhas_scene and randf() < chance_yucca_folhas:
		yucca_options.append(yucca_folhas_scene)
	if yucca_media_scene and randf() < chance_yucca_media:
		yucca_options.append(yucca_media_scene)

	if yucca_options.size() > 0:
		var yucca_scene = yucca_options[randi() % yucca_options.size()]
		var yucca = yucca_scene.instantiate()
		add_child(yucca)
		yucca.position = Vector2(pos_x, surface_height - 30)
		if yucca.has_method("adjust_position_on_block"):
			yucca.adjust_position_on_block(surface_height)
		active_yuccas.append(yucca)


func _remove_old_blocks():
	for child in get_children():
		if child is StaticBody2D and child.position.x < -block_width * 3:
			child.queue_free()


func _remove_old_yuccas():
	for i in range(active_yuccas.size() - 1, -1, -1):
		var yucca = active_yuccas[i]
		if yucca and yucca.position.x < -block_width * 3:
			yucca.queue_free()
			active_yuccas.remove_at(i)


func _block_exists_at_x(pos_x: float) -> bool:
	for child in get_children():
		if child is StaticBody2D and abs(child.position.x - pos_x) < 1.0:
			return true
	return false
