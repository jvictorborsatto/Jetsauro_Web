extends Node2D

@export var tempo_spawn_min: float = 1.5   # tempo mínimo entre spawns
@export var tempo_spawn_max: float = 3.5   # tempo máximo entre spawns
@export var cena_pteroevil: PackedScene
@export var min_pteroevils: int = 1    # mínimo de pteroevils por spawn
@export var max_pteroevils: int = 3    # máximo de pteroevils por spawn
@export var altura_minima: float = 100  # altura mínima de spawn
@export var altura_maxima: float = 400  # altura máxima de spawn

var spawn_timer: Timer

func _ready():
	# Cria e configura o Timer
	spawn_timer = Timer.new()
	spawn_timer.autostart = true
	spawn_timer.one_shot = false
	add_child(spawn_timer)
	
	# Configura tempo aleatório inicial
	_configurar_tempo_aleatorio()
	
	# Conecta o sinal
	spawn_timer.timeout.connect(_spawn_pteroevil_group)

# ⭐⭐ NOVA FUNÇÃO: Configura tempo aleatório para o próximo spawn
func _configurar_tempo_aleatorio():
	var tempo_aleatorio = randf_range(tempo_spawn_min, tempo_spawn_max)
	spawn_timer.wait_time = tempo_aleatorio
	spawn_timer.start()


func _spawn_pteroevil_group():
	if cena_pteroevil:
		# Gera número aleatório de pteroevils (entre min e max)
		var quantidade = randi() % (max_pteroevils - min_pteroevils + 1) + min_pteroevils

		
		# Array para armazenar as alturas já usadas
		var alturas_usadas = []
		var pteroevils_spawnados = 0
		
		# ⭐⭐ Variável para controlar o deslocamento horizontal
		var deslocamento_base_x = 1200  # Posição base à direita
		
		for i in range(quantidade):
			# ⭐⭐ Gera posição segura que não colide com terreno
			var posicao_segura = _encontrar_posicao_segura(alturas_usadas)
			
			if posicao_segura != Vector2.ZERO:
				var p = cena_pteroevil.instantiate()
				get_parent().add_child(p)
				
				# ⭐⭐ APLICA DESLOCAMENTO HORIZONTAL SE FOR SEGUNDO PTEROEVIL OU MAIS
				var posicao_final = posicao_segura
				if i > 0:  # A partir do segundo Pteroevil
					# ⭐⭐ Gera deslocamento aleatório entre 50 e 75 pixels
					var deslocamento = randf_range(50, 75)
					posicao_final.x = deslocamento_base_x + deslocamento
					
				
				# Define a posição final
				p.position = posicao_final
				alturas_usadas.append(posicao_final.y)
				pteroevils_spawnados += 1
				
				
		
		
	
	# ⭐⭐ Configura tempo aleatório para o próximo spawn
	_configurar_tempo_aleatorio()

# ⭐⭐ NOVA FUNÇÃO: Encontra posição segura que não colide com terreno
func _encontrar_posicao_segura(alturas_usadas: Array) -> Vector2:
	var tentativas = 0
	var posicao_valida = false
	var nova_posicao = Vector2.ZERO
	
	while not posicao_valida and tentativas < 15:  # Máximo de 15 tentativas
		# Gera posição candidata
		var x_pos = 1200  # Fora da tela à direita
		var y_pos = randf_range(altura_minima, altura_maxima)
		nova_posicao = Vector2(x_pos, y_pos)
		
		# ⭐⭐ Verifica se colide com terreno
		if not _posicao_colide_com_terreno_simples(nova_posicao):
			# ⭐⭐ Verifica se não está muito próximo de outras alturas
			var altura_unica = true
			for altura_existente in alturas_usadas:
				if abs(y_pos - altura_existente) < 40:  # Mínimo 40 pixels de diferença
					altura_unica = false
					break
			
			if altura_unica:
				posicao_valida = true
		
		tentativas += 1
	
	if posicao_valida:
		return nova_posicao
	else:
		return Vector2.ZERO  # Retorna posição zero se não encontrar

# ⭐⭐ FUNÇÃO SIMPLIFICADA: Usa espaço livre para verificar colisão (SEM CORROTINA)
func _posicao_colide_com_terreno_simples(posicao: Vector2) -> bool:
	# Usa PhysicsPointQueryParameters para verificar colisão no ponto
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = posicao
	query.collision_mask = 1  # Camada do terreno
	query.exclude = []  # Não exclui nenhum objeto
	
	var resultado = space_state.intersect_point(query)
	return resultado.size() > 0

# ⭐⭐ VERSÃO ALTERNATIVA: Se precisar de verificação mais precisa com RayCast
func _posicao_colide_com_terreno_avancado(posicao: Vector2) -> bool:
	# Cria um RayCast2D temporário para verificar colisão
	var raycast = RayCast2D.new()
	raycast.enabled = true
	raycast.position = posicao
	raycast.target_position = Vector2(0, 0)  # Verifica apenas o ponto específico
	raycast.collision_mask = 1  # Camada do terreno
	raycast.collide_with_areas = true
	raycast.collide_with_bodies = true
	
	add_child(raycast)
	
	# Força uma atualização (sem await)
	get_tree().call_deferred("call_group", "_update_raycast", raycast)
	
	# Verifica se há colisão com terreno
	var colide = raycast.is_colliding()
	
	# Remove o RayCast
	remove_child(raycast)
	raycast.queue_free()
	
	return colide

	
