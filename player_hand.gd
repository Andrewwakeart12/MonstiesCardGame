extends Node2D

@export var HAND_COUNT = 5
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
		self.add_child(new_card)
		add_card_to_hand(new_card)
		set_card_z_index(new_card,i,HAND_COUNT)
	confTopItem()
#	tcard.collider.global_position.y += int(400)
func _on_slot_receive_card(card):
	takeout_of_hand(card)
	pass
func add_card_to_hand(card):
	player_hand.insert(player_hand.size(), card)  # Inserta al inicio
	await update_hand_position()
func set_card_z_index(card,index,max_range):
	var z_index = max_range
	z_index = int(z_index) + int(max_range - index)  
	card.z_index=z_index
	pass
func confTopItem():
	var tcard= confirmOnStackTop()
	tcard.onTop = true
	tcard.get_node("DraggingArea").set_deferred("disabled", false)
func update_hand_position():
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = player_hand[i]
		card.get_node("DraggingArea").set_deferred("disabled", true)
		var new_opacity = calculate_card_opacity(i)
		animate_card_position_and_opacity(card, new_position, new_opacity)
		confTopItem()
	
		
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
	tween.tween_property(card, "rotation", 0, 0.15)
	tween.tween_property(card, "modulate:a", new_opacity, 0.15)
	#looks faster 
	#tween.tween_property(card, "skew", deg_to_rad(14.2), 0.15)
func confirmOnStackTop():
	if player_hand is Array:
		return player_hand[0]
	elif player_hand == null:
		return false
	else:
		return player_hand
func takeout_of_hand(card):
	player_hand.erase(card)
	player_hand.filter(func(item): return item.name == card.name)
	update_hand_position()
	pass
func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_R):
		update_hand_position()
	if Input.is_key_pressed(KEY_P):
		takeout_of_hand(Global.dragged_card)


func _on_card_manager_reset_cards_position() -> void:
	update_hand_position()
	pass # Replace with function body.
