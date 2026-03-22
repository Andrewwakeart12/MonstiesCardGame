extends Node2D

var dragging_card = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
func _process(delta: float) -> void:
		if dragging_card:
			var mouse_pos = get_global_mouse_position()
			dragging_card.position=mouse_pos
			print(mouse_pos,dragging_card.position)
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
		if event.pressed:
			#raycast for card
			var card_dragged = raycast_check_for_card()
			if(card_dragged):
				dragging_card = card_dragged
		else:
				dragging_card = false
func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parametters = PhysicsPointQueryParameters2D.new()
	parametters.position = get_global_mouse_position()
	parametters.collide_with_areas = true
	var result = space_state.intersect_point(parametters)
	result = result[0].collider.get_parent() if result.size() != 0  else false 
	return result
# Called every frame. 'delta' is the elapsed time since the previous frame.
