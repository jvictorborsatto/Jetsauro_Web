extends Node2D

@export var tempo_spawn: float = 2.0   # a cada 2 segundos surge um grupo
@export var cena_pteroevil_atacking: PackedScene
@export var min_pteroevils: int = 1    # mínimo de pteroevils por spawn
@export var max_pteroevils: int = 3    # máximo de pteroevils por spawn
@export var altura_minima: float = 100  # altura mínima de spawn
@export var altura_maxima: float = 400  # altura máxima de spawn

var spawn_timer: Timer

func _ready():
	# Cria e configura o Timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = tempo_spawn
	spawn_timer.autostart = true
	spawn_timer.one_shot = false
	add_child(spawn_timer)
	
	# Conecta o sinal
	spawn_timer.timeout.connect(_spawn_pteroevil_group)

func _spawn_pteroevil_group():
	if cena_pteroevil_atacking:
		# Gera número aleatório de pteroevils (entre min e max)
		var quantidade = randi() % (max_pteroevils - min_pteroevils + 1) + min_pteroevils
		
		
		# Array para armazenar as alturas já usadas
		var alturas_usadas = []
		
		for i in range(quantidade):
			var p = cena_pteroevil_atacking.instantiate()
			get_parent().add_child(p)
			
			# Gera altura única para cada pteroevil
			var nova_altura = _gerar_altura_unica(alturas_usadas)
			alturas_usadas.append(nova_altura)
			
			# Define a posição com altura única
			p.position.y = nova_altura
			p.position.x = 1200  # Fora da tela à direita
			
			

func _gerar_altura_unica(alturas_usadas: Array) -> float:
	var altura_valida = false
	var nova_altura = 0.0
	var tentativas = 0
	
	# Tenta até encontrar uma altura única ou após 10 tentativas
	while not altura_valida and tentativas < 10:
		nova_altura = randf_range(altura_minima, altura_maxima)
		altura_valida = true
		
		# Verifica se a altura é muito próxima das existentes
		for altura_existente in alturas_usadas:
			if abs(nova_altura - altura_existente) < 50:  # Mínimo 50 pixels de diferença
				altura_valida = false
				break
		
		tentativas += 1
	
	return nova_altura
