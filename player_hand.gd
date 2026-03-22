extends Node2D


@export var HAND_COUNT = 10
@export var HAND_Y_POSITION = 200
const CARD_SCENE_PATH = 'res://card.tscn'
@export var player_hand = []
var  center_screen_x
const CARD_WIDTH = 20

var card_actual_opacity= 1
var card_opacity_decrease_factor=0.01
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var temp_screen_x =get_viewport().size.x
	center_screen_x =  temp_screen_x  - temp_screen_x/ 4
	var card_scene = preload(CARD_SCENE_PATH)
	for i in range(HAND_COUNT):
		var new_card = card_scene.instantiate()
		$"../CardManager".add_child(new_card)
		new_card.name="Card_%s" % i
		add_card_to_hand(new_card)
	pass # Replace with function body.

func add_card_to_hand(card):
	player_hand.insert(0,card)
	update_hand_position()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func update_hand_position():
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position(i),HAND_Y_POSITION)
		var card = player_hand[i]
		animate_card_position_and_opacity(card,new_position,calculate_card_opacity(i))
		
func calculate_card_position(index):
	var total_width = player_hand.size() - 1  * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2
	return x_offset
func calculate_card_opacity(index):
	return card_opacity_decrease_factor * index
	pass
func animate_card_position_and_opacity(card,new_position,new_opacity):
	var tween = get_tree().create_tween()
	print("new_opacity",new_opacity)
	tween.tween_property(card,"position", new_position,0.1)
	tween.tween_property(card,"modulate:a", card_actual_opacity - new_opacity,0.1)
	pass
