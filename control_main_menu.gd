extends Control

# Caminhos das cenas
@export var game_scene_path: String = "res://node_2d_game.tscn"

@onready var button_start: Button = $Button_Start
@onready var button_credits: Button = $Button_Credits
@onready var button_exit: Button = $Button_Exit
@onready var button_back: Button = $Button_Back_To_Menu

func _ready() -> void:
	# Conectar botões de forma segura
	if button_start:
		button_start.pressed.connect(_on_start_game_pressed)
	if button_exit:
		button_exit.pressed.connect(_on_exit_pressed)
	if button_credits:
		button_credits.pressed.connect(_on_credits_pressed)
	if button_back:
		button_back.visible = false  # esconde o botão inicialmente
		button_back.pressed.connect(_on_back_pressed)

func _on_start_game_pressed() -> void:
	get_tree().change_scene_to_file(game_scene_path)

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_credits_pressed() -> void:
	# Aqui você pode mostrar a tela de créditos, se tiver
	if button_back:
		button_back.visible = true  # mostra o botão de voltar

func _on_back_pressed() -> void:
	# Esconde o botão de volta e volta ao menu principal
	if button_back:
		button_back.visible = false
	# Você pode colocar código para voltar à tela principal se precisar
