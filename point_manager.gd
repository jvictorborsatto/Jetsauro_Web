# PointManager.gd
extends Node

# Sinais
signal score_updated(score: int, formatted_time: String)
signal record_updated(record_score: int, record_time: float)
signal timer_started()
signal timer_stopped()

# Variáveis de tempo e pontuação
var start_time: float = 0.0
var current_time: float = 0.0
var total_seconds: float = 0.0
var current_score: int = 0
var timer_active: bool = false
var game_ended: bool = false

# Records
var record_score: int = 0
var record_seconds: float = 0.0
var record_date: String = ""

# Multiplicadores por minuto
const MULTIPLIER_PER_MINUTE = [1, 10, 100, 1000, 1000, 1000, 1000, 1000, 1000, 1000]

# Referência ao GameManager
var game_manager: Node = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_records()
	
	# Encontra o GameManager
	await get_tree().process_frame
	game_manager = get_node("/root/GameManager")
	
	if game_manager:
		# Conecta aos sinais do GameManager
		game_manager.game_over_triggered.connect(_on_game_over)
		game_manager.victory_triggered.connect(_on_game_over)
		game_manager.game_restarted.connect(_on_game_restarted)
		print("✅ PointManager conectado ao GameManager")

func _process(delta):
	if timer_active and not game_ended:
		# Atualiza o tempo atual
		current_time = Time.get_ticks_msec() / 1000.0 - start_time
		total_seconds = current_time
		
		# Calcula a pontuação baseada no tempo
		update_score()

# Função para iniciar o timer (chamada quando o jogador começa a se mover)
func start_timer():
	if not timer_active and not game_ended:
		timer_active = true
		start_time = Time.get_ticks_msec() / 1000.0
		current_time = 0.0
		total_seconds = 0.0
		current_score = 0
		
		timer_started.emit()
		print("⏱️ Timer iniciado!")

# Função para parar o timer (quando o jogo acaba)
func stop_timer():
	if timer_active and not game_ended:
		timer_active = false
		game_ended = true
		
		# Verifica se é recorde
		check_record()
		
		timer_stopped.emit()
		print("⏱️ Timer parado! Pontuação: ", current_score, " - Tempo: ", total_seconds)

# Função para calcular a pontuação baseada no tempo
func update_score():
	var minutes = int(total_seconds / 60)
	var seconds_in_current_minute = int(total_seconds) % 60
	
	# Garante que o multiplicador não ultrapasse o array
	var multiplier_index = min(minutes, MULTIPLIER_PER_MINUTE.size() - 1)
	var multiplier = MULTIPLIER_PER_MINUTE[multiplier_index]
	
	# Calcula a pontuação: segundos totais * multiplicador
	current_score = int(total_seconds) * multiplier
	
	# Emite sinal de atualização
	score_updated.emit(current_score, get_formatted_time())

# Função para verificar e salvar recorde
func check_record():
	if current_score > record_score:
		record_score = current_score
		record_seconds = total_seconds
		record_date = Time.get_datetime_string_from_system()
		save_records()
		record_updated.emit(record_score, record_seconds)
		print("🎉 Novo recorde! Pontuação: ", record_score, " - Tempo: ", record_seconds)

# Funções para salvar/carregar records
func save_records():
	var save_data = {
		"record_score": record_score,
		"record_seconds": record_seconds,
		"record_date": record_date
	}
	
	var file = FileAccess.open("user://diplodocool_records.save", FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		print("💾 Records salvos!")

func load_records():
	if FileAccess.file_exists("user://diplodocool_records.save"):
		var file = FileAccess.open("user://diplodocool_records.save", FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				var data = json.data
				record_score = data.get("record_score", 0)
				record_seconds = data.get("record_seconds", 0.0)
				record_date = data.get("record_date", "")
				print("📂 Records carregados: ", record_score, " pontos em ", record_seconds, " segundos")

# Handlers para eventos do GameManager
func _on_game_over():
	stop_timer()

func _on_game_restarted():
	# Reseta todas as variáveis
	timer_active = false
	game_ended = false
	start_time = 0.0
	current_time = 0.0
	total_seconds = 0.0
	current_score = 0
	print("🔄 PointManager resetado")

# Funções utilitárias
func get_formatted_time() -> String:
	var minutes = int(total_seconds / 60)
	var seconds = int(total_seconds) % 60
	var milliseconds = int((total_seconds - int(total_seconds)) * 100)
	return "%02d:%02d:%02d" % [minutes, seconds, milliseconds]

func get_formatted_record_time() -> String:
	var minutes = int(record_seconds / 60)
	var seconds = int(record_seconds) % 60
	var milliseconds = int((record_seconds - int(record_seconds)) * 100)
	return "%02d:%02d:%02d" % [minutes, seconds, milliseconds]

func get_current_multiplier() -> int:
	var minutes = int(total_seconds / 60)
	var multiplier_index = min(minutes, MULTIPLIER_PER_MINUTE.size() - 1)
	return MULTIPLIER_PER_MINUTE[multiplier_index]

func get_score() -> int:
	return current_score

func get_time() -> float:
	return total_seconds

func is_timer_active() -> bool:
	return timer_active
