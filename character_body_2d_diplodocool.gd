# diplodocool.gd
extends CharacterBody2D

# Velocidade
@export var speed = 200
@export var jump_force = 400

# Limites da tela
@export var limite_x_max = 1152
@export var limite_y_max = 648
@export var limite_y_min = 0

# Variáveis de controle
var is_jumping = false
var is_jetpack_active = false
var sprite_timer = 0.0
var sprite_change_delay = 0.1
var gravity = 980
var game_over = false
var should_move
#
var is_falling = false
var is_dizzy = false
var is_celebrating = false
var fall_sprite_timer = 0.0
var fall_sprite_delay = 0.2
var fall_sprite_index = 0
var dizzy_sprite_timer = 0.0
var dizzy_sprite_delay = 0.3
var dizzy_sprite_index = 0
var celebrate_sprite_timer = 0.0
var celebrate_sprite_delay = 0.2
var celebrate_sprite_index = 0
var menu_scene_path: String = "res://Menu.tscn"

# Variáveis para controle de colisão durante queda
var ignore_pteroevil_collisions = false
const PTERODEVIL_LAYER = 2  # Camada dos Pteroevils
const YUCCA_LAYER = 4       # Camada das Yuccas
const PTEROPUNK_LAYER = 8   # Camada dos Pteropunks

# Animações
var running_index = 0
var idle_index = 0
var current_sprite_index = 0

# Sprites
var sprite_parado_1 = preload("res://diplocool/diplocool_parado_1.png")
var sprite_parado_2 = preload("res://diplocool/diplocool_parado_2.png")
var sprite_correndo_1 = preload("res://diplocool/diplocool_correndo_1.png")
var sprite_correndo_2 = preload("res://diplocool/diplocool_correndo_2.png")
var sprite_correndo_3 = preload("res://diplocool/diplocool_correndo_3.png")
var sprite_correndo_4 = preload("res://diplocool/diplocool_correndo_4.png")
var sprite_jetpack_voando_1 = preload("res://diplocool/diplocool_jetpack_voando_1.png")
var sprite_jetpack_voando_2 = preload("res://diplocool/diplocool_jetpack_voando_2.png")
var sprite_jetpack_voando_3 = preload("res://diplocool/diplocool_jetpack_voando_3.png")
var sprite_jetpack_parado_1 = preload("res://diplocool/diplocool_jetpack_parado_1.png")
var sprite_jetpack_parado_2 = preload("res://diplocool/diplocool_jetpack_parado_2.png")
var sprite_caindo_1 = preload("res://diplocool/diplocool_caindo_1.png")
var sprite_caindo_2 = preload("res://diplocool/diplocool_caindo_2.png")
var sprite_tonto_1 = preload("res://diplocool/diplocool_tonto_1.png")
var sprite_tonto_2 = preload("res://diplocool/diplocool_tonto_21.png")
var sprite_celebrando_1 = preload("res://diplocool/diplocool_celebrando_1.png")
var sprite_celebrando_2 = preload("res://diplocool/diplocool_celebrando_2.png")
var sprite_celebrando_3 = preload("res://diplocool/diplocool_celebrando_3.png")

# Arrays para as animações
var falling_sprites = [sprite_caindo_1, sprite_caindo_2]
var dizzy_sprites = [sprite_tonto_1, sprite_tonto_2]
var celebrate_sprites = [sprite_celebrando_1, sprite_celebrando_2, sprite_celebrando_3]

var running_sprites = [sprite_correndo_1, sprite_correndo_2, sprite_correndo_3, sprite_correndo_4]
var jetpack_flying_sprites = [sprite_jetpack_voando_1, sprite_jetpack_voando_2, sprite_jetpack_voando_3]
var jetpack_idle_sprites = [sprite_jetpack_parado_1, sprite_jetpack_parado_2]
var idle_sprites = [sprite_parado_1, sprite_parado_2]

# Variável para acessar o GameManager
var game_manager: Node = null

# Referência ao PointManager
var point_manager: Node = null

var idle_timer = Timer.new()


func _ready():
	collision_layer = 2  # Camada do player
	# CONFIGURA MÁSCARA DE COLISÃO: Terreno (1) + Inimigos (2) + Yuccas (4) + Pteropunks (8)
	set_collision_mask_value(1, true)   # Terreno
	set_collision_mask_value(2, true)   # Inimigos (Pteroevils)
	set_collision_mask_value(4, true)   # Yuccas
	set_collision_mask_value(8, true)   # Pteropunks
	
	add_to_group("player")
	
	add_child(idle_timer)
	idle_timer.wait_time = 0.2
	idle_timer.timeout.connect(_on_idle_timer_timeout)
	
	# Reset completo do estado
	reset_player_state()
	
	# Busca o GameManager de forma segura
	game_manager = _get_game_manager()
	
	# Busca o PointManager
	point_manager = get_node("/root/PointManager")

	is_dizzy = false
# Função para resetar completamente o estado do jogador


func reset_player_state():
	# Reset de todas as variáveis de estado
	is_jumping = false
	is_jetpack_active = false
	sprite_timer = 0.0
	game_over = false
	
	is_falling = false
	is_dizzy = false
	is_celebrating = false
	fall_sprite_timer = 0.0
	dizzy_sprite_timer = 0.0
	celebrate_sprite_timer = 0.0
	fall_sprite_index = 0
	dizzy_sprite_index = 0
	celebrate_sprite_index = 0
	
	running_index = 0
	idle_index = 0
	current_sprite_index = 0
	
	# Reativa colisões
	ignore_pteroevil_collisions = false
	set_collision_mask_value(PTERODEVIL_LAYER, true)
	
	# Reinicia timers
	if idle_timer:
		idle_timer.start()
	
	# Reset de posição e velocidade
	position = Vector2(100, 100)
	velocity = Vector2.ZERO
	
	# Sprite inicial
	$Sprite2D.texture = sprite_correndo_1
	$Sprite2D.modulate = Color.WHITE
	$Sprite2D.flip_h = false
	
	# Recupera referência do GameManager
	game_manager = _get_game_manager()
# 
	add_to_group("resetavel")
	
func _on_idle_timer_timeout():
	# Atualiza animação idle quando parado
	if not game_over and not _is_in_animation():
		if velocity.x == 0 and is_on_floor() and not is_jetpack_active:
			idle_index = (idle_index + 1) % idle_sprites.size()
			$Sprite2D.texture = idle_sprites[idle_index]

# Função segura para buscar o GameManager
func _get_game_manager():
	if has_node("/root/GameManager"):
		return get_node("/root/GameManager")
	else:
		return null

# 
# NOVA FUNÇÃO: Verifica se está em animação (para permitir movimento mas não controle)
func _is_in_animation() -> bool:
	if game_manager:
		return (game_manager.current_game_state == game_manager.GameState.GAME_OVER_ANIMATION)
	return false

func _physics_process(delta):
		
	# NOVO: Se está em animação, só processa as animações mas não o controle
	if _is_in_animation():
		# Processa apenas as animações de game over/vitória
		if is_falling:
			_handle_falling_animation(delta)
		elif is_dizzy:
			_handle_dizzy_animation(delta)
		elif is_celebrating:
			_handle_celebrating_animation(delta)
		return
	
	if game_over:
		# Animação de queda, tonto ou celebração durante game over
		if is_falling:
			_handle_falling_animation(delta)
		elif is_dizzy:
			_handle_dizzy_animation(delta)
		elif is_celebrating:
			_handle_celebrating_animation(delta)
		return  # Para todo o processamento se game over
	
	sprite_timer += delta
	is_jetpack_active = Input.is_key_pressed(KEY_SPACE)
	var input_vector = Vector2.ZERO
	var moving_left = Input.is_key_pressed(KEY_A)
	var moving_right = Input.is_key_pressed(KEY_D)
	
	# Movimento horizontal
	if moving_left and position.x > 15:
		input_vector.x = -1
		$Sprite2D.flip_h = true
	elif moving_right:
		input_vector.x = 1
		$Sprite2D.flip_h = false
	else:
		input_vector.x = 0.05
		$Sprite2D.flip_h = false
	
	# Aplica velocidade horizontal
	velocity.x = input_vector.x * speed
	
	# Gravidade
	if not is_jetpack_active and not is_on_floor():
		velocity.y += gravity * delta
	
	# Jetpack
	if is_jetpack_active:
		_handle_jetpack_movement(input_vector, delta)
	
	# Verifica se o timer deve começar (primeiro movimento)	
	if point_manager and not point_manager.is_timer_active():
		var moving = Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_SPACE)
		if moving:
			point_manager.start_timer()
		
	# Se está em animação, só processa as animações mas não o controle
	if _is_in_animation():
		# Processa apenas as animações de game over/vitória
		if is_falling:
			_handle_falling_animation(delta)
		elif is_dizzy:
			_handle_dizzy_animation(delta)
		elif is_celebrating:
			_handle_celebrating_animation(delta)
		return
		
	# Movimento
	move_and_slide()
	
	# VERIFICA TODAS AS COLISÕES (Pteroevils, Yuccas E Pteropunks)
	if not ignore_pteroevil_collisions:
		_check_pteroevil_collisions()
		_check_yucca_collisions()
		
	
	# Animação parado ou corrida
	if velocity.x <= 0 and not moving_left and is_on_floor():
		if sprite_timer >= sprite_change_delay:
			sprite_timer = 0
			idle_index = (idle_index + 1) % idle_sprites.size()
			$Sprite2D.texture = idle_sprites[idle_index]
	else:
		if is_on_floor() and not is_jetpack_active and sprite_timer >= sprite_change_delay:
			_animate_running()
	
	# Limites e game over
	_enforce_screen_limits()
	_check_game_over()
	
	# Fica vermelho se X < 1
	if position.x < 1:
		$Sprite2D.modulate = Color.RED
	else:
		$Sprite2D.modulate = Color.WHITE
	
	if is_on_floor():
		velocity.y = 0
		is_jumping = false

func _handle_falling_animation(delta):
	# Animação de caindo durante a queda
	fall_sprite_timer += delta
	if fall_sprite_timer >= fall_sprite_delay:
		fall_sprite_timer = 0
		fall_sprite_index = (fall_sprite_index + 1) % falling_sprites.size()
		$Sprite2D.texture = falling_sprites[fall_sprite_index]
	
	# Aplica gravidade aumentada durante a queda
	velocity.y += gravity * 1.5 * delta
	move_and_slide()
	
	# Verifica se chegou no chão
	if is_on_floor():
		_start_dizzy_animation()

func _handle_dizzy_animation(delta):
	# Animação de tonto no chão
	dizzy_sprite_timer += delta
	if dizzy_sprite_timer >= dizzy_sprite_delay:
		dizzy_sprite_timer = 0
		dizzy_sprite_index = (dizzy_sprite_index + 1) % dizzy_sprites.size()
		$Sprite2D.texture = dizzy_sprites[dizzy_sprite_index]

func _handle_celebrating_animation(delta):
	# Animação de celebração quando encontra Pteropunks
	celebrate_sprite_timer += delta
	if celebrate_sprite_timer >= celebrate_sprite_delay:
		celebrate_sprite_timer = 0
		celebrate_sprite_index = (celebrate_sprite_index + 1) % celebrate_sprites.size()
		$Sprite2D.texture = celebrate_sprites[celebrate_sprite_index]

func _start_dizzy_animation():
	# Transição de queda para estado tonto
	is_falling = false
	is_dizzy = true
	velocity = Vector2.ZERO

# Chama o GameManager de forma segura
	if game_manager and game_manager.has_method("trigger_victory"):
		game_manager.trigger_victory()
	

func _check_yucca_collisions():
	# Verifica se colidiu com alguma yucca
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider and collider.is_in_group("yucca") and not game_over:
			_start_dizzy_from_yucca(collider)
			break

func _start_dizzy_from_yucca(yucca):
	# Inicia a animação de tontura ao colidir com yucca
	game_over = true
	is_dizzy = true
	dizzy_sprite_index = 0
	dizzy_sprite_timer = 0
	velocity = Vector2.ZERO
	
	# Chama o GameManager de forma segura
	if game_manager and game_manager.has_method("trigger_game_over"):
		game_manager.trigger_game_over()
		
	
	idle_timer.stop()

func _check_pteroevil_collisions():
	# Verifica se colidiu com algum Pteroevil
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider and collider.is_in_group("pteroevil") and not game_over:
			_start_falling_animation(collider)
			break

func _start_falling_animation(pteroevil):
	# Inicia a animação de queda ao ser atingido
	game_over = true
	is_falling = true
	fall_sprite_index = 0
	fall_sprite_timer = 0
	
	# Ignora colisões com Pteroevils durante a queda
	ignore_pteroevil_collisions = true
	set_collision_mask_value(PTERODEVIL_LAYER, false)
	
	# Chama o GameManager de forma segura
	if game_manager and game_manager.has_method("trigger_game_over"):
		game_manager.trigger_game_over()
	else:
		print("⚠️ GameManager não disponível para game over")
	

	idle_timer.stop()

func _animate_running():
	if sprite_timer >= sprite_change_delay:
		sprite_timer = 0
		running_index = (running_index + 1) % running_sprites.size()
		$Sprite2D.texture = running_sprites[running_index]

func _handle_jetpack_movement(input_vector, delta):
	if Input.is_key_pressed(KEY_W):
		velocity.y = -speed
	elif Input.is_key_pressed(KEY_S):
		velocity.y = speed
	else:
		velocity.y = 0
	
	if Input.is_key_pressed(KEY_SPACE) and Input.is_key_pressed(KEY_S) and is_jumping:
		is_jumping = false
		velocity.y = speed * 2
		is_jetpack_active = false
	
	if sprite_timer >= sprite_change_delay:
		sprite_timer = 0.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_D):
			current_sprite_index = (current_sprite_index + 1) % jetpack_flying_sprites.size()
			$Sprite2D.texture = jetpack_flying_sprites[current_sprite_index]
		else:
			current_sprite_index = (current_sprite_index + 1) % jetpack_idle_sprites.size()
			$Sprite2D.texture = jetpack_idle_sprites[current_sprite_index]

func _enforce_screen_limits():
	position.x = clamp(position.x, 0, limite_x_max)
	if position.y < limite_y_min:
		position.y = limite_y_min
		velocity.y = 0

func _check_game_over():
	if position.y > limite_y_max and not game_over:
		_start_falling_animation(null)

	
func resetar():
	should_move = true
	print("▶️ Bloco ", name, " - movimento reiniciado")
