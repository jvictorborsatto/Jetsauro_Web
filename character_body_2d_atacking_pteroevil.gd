# pteroevil.gd
extends CharacterBody2D

@export var speed: float = 100
@export var limite_x_min: float = -200
@export var limite_x_max: float = 1200
@export var limite_y_min: float = 0
@export var limite_y_max: float = 450

# ⭐⭐ NOVAS VARIÁVEIS PARA ATAQUE AVANÇADO
@export var dano: int = 1
@export var chance_ataque: float = 0.3  # 30% de chance de atacar
@export var velocidade_ataque: float = 200.0
var ja_colidiu: bool = false
var esta_atacando: bool = false
var alvo_ataque: Vector2 = Vector2.ZERO
var tempo_ataque: float = 0.0

# Variáveis para evitar colisão
var original_speed: float = 100
var is_avoiding_obstacle: bool = false
var avoid_timer: float = 0.0
var avoid_duration: float = 1.0

# ⭐⭐ Variável para controlar a direção do sprite
var direcao_anterior: float = -1  # Começa indo para a esquerda

# Sprites
var sprites_voando = [
	preload("res://peteroevil/Pteroevi_atacking_1.png"),
	preload("res://peteroevil/Pteroevi_atacking_2.png")
]

var sprites_dano = [
	preload("res://peteroevil/Pteroevi_atacking_1.png"),
	preload("res://peteroevil/Pteroevi_atacking_2.png")
]

var sprite_index: int = 0
var anim_timer: float = 0.0
var troca_delay: float = 0.2

func _ready():
	add_to_group("pteroevil")
	_spawn_na_direita()
	
	collision_layer = 2
	collision_mask = 1
	original_speed = speed
	
	# ⭐⭐ Configuração inicial do flip (indo para esquerda)
	$Sprite2D.flip_h = false

func _physics_process(delta):
	# ⭐⭐ COMPORTAMENTO DE ATAQUE
	if esta_atacando:
		_executar_ataque(delta)
	else:
		_movimento_normal(delta)
	
	# ⭐⭐ ATUALIZA A DIREÇÃO DO SPRITE
	_atualizar_direcao_sprite()
	
	# Animação
	anim_timer += delta
	if anim_timer >= troca_delay:
		anim_timer = 0.0
		sprite_index = (sprite_index + 1) % sprites_voando.size()
		$Sprite2D.texture = sprites_voando[sprite_index]
	
	# Aplica o movimento
	move_and_slide()
	
	# Verifica colisões e limites
	_verificar_colisoes()
	
	# ⭐⭐ MODIFICAÇÃO SIMPLES: Destruir quando X < 1
	if global_position.x < 1:
		queue_free()
	

# ⭐⭐ NOVA FUNÇÃO: Atualiza a direção do sprite baseado na velocidade
func _atualizar_direcao_sprite():
	var direcao_atual = sign(velocity.x)
	
	# Se a direção mudou, atualiza o flip do sprite
	if direcao_atual != 0 and direcao_atual != direcao_anterior:
		direcao_anterior = direcao_atual
		
		# Se está indo para a direita (velocidade positiva), flip horizontal
		if direcao_atual > 0:
			$Sprite2D.flip_h = true
			
		# Se está indo para a esquerda (velocidade negativa), sem flip
		elif direcao_atual < 0:
			$Sprite2D.flip_h = false
			

func _movimento_normal(delta):
	# ⭐⭐ MOVIMENTO SEMPRE PARA ESQUERDA (negativo)
	velocity.x = -speed
	
	# ⭐⭐ CHANCE DE INICIAR ATAQUE
	if randf() < chance_ataque * delta and not esta_atacando:
		_iniciar_ataque()
	
	# Movimento vertical suave
	velocity.y = sin(Time.get_ticks_msec() * 0.001) * 20

func _iniciar_ataque():
	# Encontra o player para mirar
	var player = get_tree().get_first_node_in_group("player")
	if player:
		esta_atacando = true
		tempo_ataque = 0.0
		alvo_ataque = player.global_position
		
		
		# ⭐⭐ Ajusta a velocidade para o ataque (mantendo direção negativa)
		original_speed = speed
		speed = velocidade_ataque

func _executar_ataque(delta):
	tempo_ataque += delta
	
	# ⭐⭐ MOVIMENTO DE ATAQUE EM DIAGONAL - SEMPRE MANTENDO DIREÇÃO PARA ESQUERDA
	var direcao = (alvo_ataque - global_position).normalized()
	
	# ⭐⭐ GARANTE QUE A VELOCIDADE X SEMPRE SEJA NEGATIVA (ESQUERDA)
	var velocidade_x = abs(velocidade_ataque) * -1  # Força direção negativa
	var velocidade_y = direcao.y * velocidade_ataque
	
	velocity = Vector2(velocidade_x, velocidade_y)
	
	# ⭐⭐ TEMPO LIMITE DE ATAQUE (2 segundos)
	if tempo_ataque > 2.0:
		_finalizar_ataque()

func _finalizar_ataque():
	esta_atacando = false
	speed = original_speed
	
func _verificar_colisoes():
	if get_slide_collision_count() > 0 and not is_avoiding_obstacle:
		var collision = get_slide_collision(0)
		var collider = collision.get_collider()
		
		if collider and not collider.is_in_group("player"):
			_start_obstacle_avoidance()
	
	if is_on_floor() and not is_avoiding_obstacle:
		_start_obstacle_avoidance()

func _start_obstacle_avoidance():
	if not is_avoiding_obstacle:
		is_avoiding_obstacle = true
		avoid_timer = 0.0
		velocity.y = -speed * 0.8

func _spawn_na_direita():
	randomize()
	position = Vector2(limite_x_max, randf_range(limite_y_min, limite_y_max - 100))
	$Sprite2D.texture = sprites_voando[0]
	# ⭐⭐ Garante que comece com a direção correta (indo para esquerda)
	$Sprite2D.flip_h = false
	direcao_anterior = -1

func _on_body_entered(body):
	if body.is_in_group("player") and not ja_colidiu:
		ja_colidiu = true
		
		
		if body.has_method("_get_hit_by_pteroevil"):
			body._get_hit_by_pteroevil()
		
		_ativar_sprites_dano()
		velocity.x = speed * 0.5  # Recuo (mantém direção negativa)
		
		# Reativa colisão após 1 segundo
		get_tree().create_timer(1.0).timeout.connect(_reativar_colisao)

func _reativar_colisao():
	ja_colidiu = false

func _ativar_sprites_dano():
	if sprites_dano.size() > 0:
		sprites_voando = sprites_dano
		sprite_index = 0 
