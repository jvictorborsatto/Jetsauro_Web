# GameManager.gd
extends Node

# Sinais globais
signal game_paused
signal game_resumed
signal game_over_triggered
signal victory_triggered
signal level_changed(new_level)

# Estado do jogo
enum GameState {PLAYING, PAUSED, GAME_OVER, VICTORY}
var current_game_state = GameState.PLAYING

# Informações do jogador que podem persistir entre fases
var player_score: int = 0
var player_lives: int = 3
var current_level: String = ""

# Configurações
var music_volume: float = 1.0
var sfx_volume: float = 1.0

# Referência para o jogador (será definida quando o jogador for instanciado)
var player_node: Node = null

# Método para pausar o jogo
func pause_game():
	if current_game_state == GameState.PLAYING:
		current_game_state = GameState.PAUSED
		Engine.time_scale = 0
		game_paused.emit()
		print("⏸️ Jogo pausado")

# Método para despausar o jogo
func resume_game():
	if current_game_state == GameState.PAUSED:
		current_game_state = GameState.PLAYING
		Engine.time_scale = 1
		game_resumed.emit()
		print("▶️ Jogo retomado")

# Método para trigger game over
func trigger_game_over():
	if current_game_state != GameState.GAME_OVER:
		current_game_state = GameState.GAME_OVER
		game_over_triggered.emit()
		print("💀 Game Over acionado")
		# Aqui você pode adicionar lógica adicional como salvar pontuação, etc.

# Método para trigger vitória
func trigger_victory():
	if current_game_state != GameState.VICTORY:
		current_game_state = GameState.VICTORY
		victory_triggered.emit()
		print("🎉 Vitória acionada!")
		# Lógica adicional para vitória

# Método para mudar de fase
func change_level(level_path: String):
	current_level = level_path
	level_changed.emit(level_path)
	get_tree().change_scene_to_file(level_path)
	resume_game()  # Garante que o jogo não fique pausado na nova fase

# Método para reiniciar o jogo completamente
func restart_game():
	player_score = 0
	player_lives = 3
	current_game_state = GameState.PLAYING
	Engine.time_scale = 1
	print("🔄 Jogo reiniciado completamente")

# Método para registrar o jogador (chamado pelo script do Diplodocool)
func register_player(player):
	player_node = player
	print("👤 Jogador registrado no GameManager")

# Salvar configurações (pode ser expandido)
func save_settings():
	var config = {
		"music_volume": music_volume,
		"sfx_volume": sfx_volume
	}
	# Aqui você pode salvar em arquivo usando ResourceSaver ou FileAccess
	print("⚙️ Configurações salvas")

# Carregar configurações (pode ser expandido)  
func load_settings():
	# Aqui você pode carregar de um arquivo
	print("⚙️ Configurações carregadas")
