extends Node2D

@export var HAND_COUNT = 5
@export var HAND_Y_POSITION = 200
const CARD_SCENE_PATH = 'res://card.tscn'
var player_hand = []
var center_screen_x
const CARD_WIDTH = 20
var ActiveCard
var card_scene
# ✅ Opacidad base y rango ajustado para que todas sean visibles
var card_base_opacity = 1.0
var card_opacity_fade = 0.05  # Valor más razonable

func _ready() -> void:
	var viewport_width = get_viewport().size.x
	center_screen_x = viewport_width * 0.75  # Tu lógica original: viewport - viewport/4
	
	card_scene = preload(CARD_SCENE_PATH)
	for i in range(HAND_COUNT):
		var new_card = card_scene.instantiate()
		new_card.name = "Card_%s" % i
		self.add_child(new_card)
		add_card_to_hand(new_card)
		set_card_z_index(new_card,i,HAND_COUNT)
	confTopItem()

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

func getActiveCard():
	if(ActiveCard):
		return ActiveCard
	else:
		return player_hand[0] 
	pass
func confTopItem():
	var tcard= confirmOnStackTop()
	if ActiveCard:
		tcard.onTop = true
		tcard.get_node("DraggingArea").set_deferred("disabled", false)
func updated_hand_card_z_indexes():
	var actual_index = player_hand.find(ActiveCard,0)
	#array map example
	var z_indexes = []
	for i in range(player_hand.size()):
		# Calculamos la distancia absoluta desde el índice actual hasta el central
		var distancia = abs(i - actual_index)
		# Restamos esa distancia al valor máximo
		var z = player_hand.size() - distancia
		player_hand[i].z_index = z
	pass
func update_hand_position():
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = player_hand[i]
		card.get_node("DraggingArea").set_deferred("disabled", true)
		var new_opacity = 1
		animate_card_position_and_opacity(card, new_position, new_opacity)
	if(!ActiveCard):
		confTopItem()
func ManuallySelectCard(card):
	ActiveCard.onTop = false
	card.onTop = true
	ActiveCard = card
	updated_hand_card_z_indexes()
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

func confirmOnStackTop():
	if player_hand is Array and player_hand.size() > 0:
		ActiveCard = player_hand[0]
		return ActiveCard
	elif player_hand == null:
		return null
	else:
		return player_hand

# ✅ CORREGIDO: Usa vanish_card_and_self_remove en lugar de eliminar directamente
func takeout_of_hand(card):
	if card in player_hand and not card.get_meta("removing", false):
		vanish_card_and_self_remove(card)

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_R):
		update_hand_position()
	if Input.is_key_pressed(KEY_P):
		if Global.dragged_card and Global.dragged_card in player_hand:
			vanish_card_and_self_remove(Global.dragged_card)
	if Input.is_key_pressed(KEY_A):
		add_card_to_decK()
	if Input.is_key_pressed(KEY_D):
		remove_from_deck()
	if Input.is_key_pressed(KEY_RIGHT):
		ManuallySelectCard(get_next_card_based_on_array_position(player_hand.find(ActiveCard,0),false))
		pass
	if Input.is_key_pressed(KEY_LEFT):
		ManuallySelectCard(get_next_card_based_on_array_position(player_hand.find(ActiveCard,0)))
		pass
	

func add_card_to_decK():
	var new_card = card_scene.instantiate()
	new_card.name = "Card_%s" % player_hand.size()
	self.add_child(new_card)
	add_card_to_hand(new_card)
	set_card_z_index(new_card,player_hand.size(),HAND_COUNT)
	pass

# ============================================================================
# ✅ FUNCIONES CORREGIDAS PARA VANISH (Sin señales, sin flags, solo Tween)
# ============================================================================

func vanish_card_and_self_remove(card: Node2D) -> void:
	"""
	Animación de desaparición NO BLOQUEANTE usando Tween.
	Cada carta gestiona su propia animación y eliminación.
	"""
	# Prevenir eliminación duplicada
	if not is_instance_valid(card) or card.get_meta("removing", false):
		return
	card.set_meta("removing", true)
	
	# Desactivar interacciones inmediatamente
	if card.has_node("DraggingArea"):
		card.get_node("DraggingArea").set_deferred("disabled", true)
	
	# ✅ Crear Tween para la animación
	var tween = create_tween()
	# Animar opacidad a 0 (efecto vanish)
	tween.tween_property(card.get_node('Sprite2D'), "position", Vector2(card.position.x,card.position.y - 40), 1).from_current()
	tween.set_parallel()
	tween.tween_property(card.get_node('Sprite2D'), "modulate:a", 0.0, 1)
	
	# ✅ Callback que se ejecuta AL FINALIZAR la animación
	# Esto reemplaza la necesidad de señales y ConnectionFlags
	tween.tween_callback(_finalize_card_removal.bind(card))
	
	# ✅ Esta función retorna INMEDIATAMENTE → UI responsiva

func _finalize_card_removal(card: Node2D) -> void:
	"""
	Limpieza segura: remueve del array, del árbol y libera memoria.
	"""
	if not is_instance_valid(card):
		return
	
	# Remover del array de la mano
	var idx = player_hand.find(card)
	if idx != -1:
		var next_card = get_next_card_based_on_array_position(idx)
		player_hand.remove_at(idx)
		ManuallySelectCard(next_card)
	# Remover del árbol de nodos y liberar
	if card.get_parent():
		card.get_parent().remove_child(card)
	card.queue_free()
	
	# Actualizar posición de las cartas restantes
	update_hand_position()

func remove_from_deck() -> void:
	"""
	Elimina la última carta del mazo con animación NO BLOQUEANTE.
	"""
	if player_hand.is_empty():
		return
	var last_element = player_hand[-1]
	
	# ✅ Iniciar animación sin await → retorna inmediatamente
	vanish_card_and_self_remove(last_element)
func get_next_card_based_on_array_position(position,direction = true):
	#direction bool , true,false (left/right)
	var player_hand_size = player_hand.size() - 1
	var direction_sum = position - 1 if direction  else position + 1
	var card
	if(player_hand_size > 0 && direction_sum < player_hand.size()):
		if(direction_sum == -1):
			return player_hand[player_hand_size]
		else:
			return player_hand[direction_sum]
		pass
	else:
		return player_hand[0]
# ============================================================================
# FIN DE FUNCIONES CORREGIDAS
# ============================================================================

func _on_card_manager_reset_cards_position() -> void:
	update_hand_position()
	pass
func _on_card_hover_off(card):
	card.z_index = player_hand.size() + 1
	pass
func _on_card_hover_on(card):
	card.z_index = player_hand.size() + 1
	pass
