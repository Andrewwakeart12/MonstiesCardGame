extends Node2D

@export var HAND_COUNT = 10
@export var HAND_Y_POSITION = 200
const CARD_SCENE_PATH = 'res://card.tscn'
var player_hand = []
var center_screen_x
const CARD_WIDTH = 20

# ✅ Opacidad base y rango ajustado para que todas sean visibles
var card_base_opacity = 1.0
var card_opacity_fade = 0.05  # Valor más razonable

func _ready() -> void:
	var viewport_width = get_viewport().size.x
	center_screen_x = viewport_width * 0.75  # Tu lógica original: viewport - viewport/4
	
	var card_scene = preload(CARD_SCENE_PATH)
	for i in range(HAND_COUNT):
		var new_card = card_scene.instantiate()
		new_card.name = "Card_%s" % i
		
		# ⚠️ IMPORTANTE: Asegúrate de que CardManager esté en la posición esperada
		# O mejor: añade las cartas como hijas de ESTE nodo para controlar coordenadas
		$"../CardManager".add_child(new_card)
		
		add_card_to_hand(new_card)
		print("Carta añadida: %s | Total en mano: %s" % [new_card.name, player_hand.size()])
	var tcard= confirmOnStackTop()
#	tcard.collider.global_position.y += int(400)

func add_card_to_hand(card):
	player_hand.insert(0, card)  # Inserta al inicio
	update_hand_position()

func update_hand_position():
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = player_hand[i]
		var new_opacity = calculate_card_opacity(i)
		animate_card_position_and_opacity(card, new_position, new_opacity)
		
func calculate_card_position(index):
	# ✅ PARÉNTESIS CORRECTOS:
	var total_width = (player_hand.size() - 1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2
	return x_offset

func calculate_card_opacity(index):
	# ✅ Opacidad que disminuye gradualmente pero se mantiene visible
	var opacity = card_base_opacity - (index * card_opacity_fade)
	return clamp(opacity, 0.3, 1.0)  # Mínimo 30% de opacidad para que siempre se vean

func animate_card_position_and_opacity(card, new_position, new_opacity):
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "position", new_position, 0.15)
	tween.tween_property(card, "modulate:a", new_opacity, 0.15)
func confirmOnStackTop():
	return player_hand[0]
