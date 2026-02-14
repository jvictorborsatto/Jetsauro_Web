# pteroevil.gd
extends CharacterBody2D

@export var speed: float = 200  
@export var limite_x_min: float = -200
@export var limite_x_max: float = 1200
@export var limite_y_min: float = 0
@export var limite_y_max: float = 450


@export var dano: int = 1
var ja_colidiu: bool = false  

# Variáveis para evitar colisão
var original_speed: float = 100  
var is_avoiding_obstacle: bool = false
var avoid_timer: float = 0.0
var avoid_duration: float = 1.0


var sprites_voando = [
	preload("res://peteroevil/Pteroevi_flying_1l.png"),
	preload("res://peteroevil/Pteroevi_flying_2l.png"),
	preload("res://peteroevil/Pteroevi_flying_3.png"),
]


var sprites_dano = [
	preload("res://peteroevil/Pteroevi_hit_1.png"),
	preload("res://peteroevil/Pteroevi_hit_2.png")
]

var sprite_index: int = 0
var anim_timer: float = 0.0
var troca_delay: float = 0.2

func _ready():
	add_to_group("pteroevil")
	_spawn_na_direita()
	
	
	collision_layer = 2  # Camada dos inimigos
	collision_mask = 1   # Colide apenas com o player
	
	original_speed = speed

func _physics_process(delta):
	
	velocity.x = -speed
	
	# Animação
	anim_timer += delta
	if anim_timer >= troca_delay:
		anim_timer = 0.0
		sprite_index = (sprite_index + 1) % sprites_voando.size()
		$Sprite2D.texture = sprites_voando[sprite_index]
	
	
	if is_avoiding_obstacle:
		avoid_timer += delta
		velocity.y = -speed * 0.8
		
		if avoid_timer >= avoid_duration:
			is_avoiding_obstacle = false
			velocity.y = 0
	else:
		# Movimento normal - oscilações aleatórias
		velocity.y = sin(Time.get_ticks_msec() * 0.001) * 20
	
	
	move_and_slide()
	

	if get_slide_collision_count() > 0 and not is_avoiding_obstacle:
		var collision = get_slide_collision(0)
		var collider = collision.get_collider()
		
		if collider and not collider.is_in_group("player"):
			_start_obstacle_avoidance()
	
	
	if is_on_floor() and not is_avoiding_obstacle:
		_start_obstacle_avoidance()
	
	
	if global_position.x < 1:
		queue_free()
	

func _start_obstacle_avoidance():
	if not is_avoiding_obstacle:
		is_avoiding_obstacle = true
		avoid_timer = 0.0

func _spawn_na_direita():
	randomize()
	position = Vector2(limite_x_max, randf_range(limite_y_min, limite_y_max - 100))
	$Sprite2D.texture = sprites_voando[0]


func _on_body_entered(body):
	if body.is_in_group("player") and not ja_colidiu:
		ja_colidiu = true
	
		
		
		if body.has_method("_get_hit_by_pteroevil"):
			body._get_hit_by_pteroevil()
		
	
		_ativar_sprites_dano()
		
		
		velocity.x = speed * 0.5  # Recua um pouco
		
	

func _reativar_colisao():
	ja_colidiu = false



func _ativar_sprites_dano():
	if sprites_dano.size() > 0:
		sprites_voando = sprites_dano
		sprite_index = 0
	
