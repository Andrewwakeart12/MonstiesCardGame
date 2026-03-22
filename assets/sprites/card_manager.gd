extends Node2D

var dragging_card: Node2D = null
var drag_offset: Vector2 = Vector2.ZERO
var shake_intensity: float = 0.0

# Física de rotación tipo ragdoll
var angular_velocity: float = 0.2
var previous_mouse_pos: Vector2 = Vector2.ZERO
var mouse_velocity: Vector2 = Vector2.ZERO

# Animación de retorno
var returning_card: Node2D = null
var original_position: Vector2 = Vector2.ZERO
var original_rotation: float = 0.0
var return_progress: float = 0.0
var dropped_in_interactive_area: bool = false
# --- CONFIGURACIÓN ---
@export var drag_smoothness: float = 0.1      	# Inercia de movimiento (0.05 = muy pesado, 1.0 = instantáneo)
@export var rotation_force: float = 0.01      # Fuerza que aplica el movimiento a la rotación (ragdoll)
@export var angular_damping: float = 0.50       # Amortiguación de velocidad angular (0.85 = mucho, 0.98 = poco)
@export var rotation_return_speed: float = 0.05 # Velocidad para volver a 0 cuando no hay movimiento
@export var max_rotation_deg: float = 45.0      # Rotación máxima permitida
@export var card_size: Vector2 = Vector2(200, 300) # Tamaño real de tu carta (ajustar en Inspector)
@export var shake_duration: float = 0.2         # Duración del temblor al agarrar (segundos)
@export var shake_strength: float = 0.08        # Fuerza del temblor (radianes)
@export var tremor_amplitude: float = 0.03      # Amplitud del temblor en hover
@export var tremor_speed: float = 12.0          # Velocidad del temblor en hover
@export var return_animation_speed: float = 0.02 # Velocidad de animación de retorno (0.01 = lento, 0.2 = rápido)
@export var interactive_area_layers: Array = [] # Capas de áreas interactivas (opcional)
# ---------------------

func _ready() -> void:
	pass 

func _process(delta: float) -> void:
	if dragging_card:
		var mouse_pos = get_global_mouse_position()
		var target_pos = mouse_pos + drag_offset
		
		# 1. Calcular velocidad del mouse (continuamente durante el drag)
		mouse_velocity = mouse_pos - previous_mouse_pos
		previous_mouse_pos = mouse_pos
		
		# 2. Movimiento con Inercia (Lerp)
		dragging_card.global_position = dragging_card.global_position.lerp(target_pos, drag_smoothness)
		
		# 3. Rotación tipo Ragdoll (interactúa con el movimiento DURANTE el drag)
		var force = mouse_velocity.x * rotation_force
		angular_velocity += force
		angular_velocity *= angular_damping
		dragging_card.rotation += angular_velocity
		
		# Fuerza de retorno a 0 cuando la velocidad es baja
		if abs(mouse_velocity.length()) < 5.0:
			dragging_card.rotation = lerp_angle(dragging_card.rotation, 0.0, rotation_return_speed)
		
		# Limitar rotación máxima
		var max_rot = deg_to_rad(max_rotation_deg)
		dragging_card.rotation = clamp(dragging_card.rotation, -max_rot, max_rot)
		
		# 4. Límites de Pantalla (Sin espacio muerto)
		clamp_card_to_screen(dragging_card)
		
		# 5. Temblor Momentáneo (Decaimiento)
		if shake_intensity > 0:
			dragging_card.rotation += randf_range(-shake_strength, shake_strength)
			shake_intensity -= delta
			
	elif returning_card:
		# Animación de retorno a posición original
		return_progress += return_animation_speed
		
		if return_progress >= 1.0:
			# Animación completada
			returning_card.global_position = original_position
			returning_card.rotation = original_rotation
			returning_card = null
			return_progress = 0.0
		else:
			# Interpolación suave con easing
			var ease_progress = ease(return_progress, 2.0) # Ease out para efecto más natural
			returning_card.global_position = original_position.lerp(returning_card.global_position, 1.0 - ease_progress)
			returning_card.rotation = lerp_angle(returning_card.rotation, original_rotation, return_animation_speed * 2)
	else:
		# Resetear cuando no se arrastra ni retorna
		mouse_velocity = Vector2.ZERO
		angular_velocity = 0.0
		previous_mouse_pos = get_global_mouse_position()
		
		# Temblor suave en hover
	

func _input(event: InputEvent) :
	if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
		if event.pressed:
			var card_dragged = raycast_check_for_card()

			if card_dragged:
				if(card_dragged.has_method('is_interactive_area')):
					print("is_slot")
					return false
				dragging_card = card_dragged
				
				# Guardar posición original para posible retorno
				original_position = dragging_card.global_position
				original_rotation = dragging_card.rotation
				
				# Calcular offset exacto donde se agarró la carta
				drag_offset = dragging_card.global_position - get_global_mouse_position()
				
				# Resetear física para evitar saltos
				previous_mouse_pos = get_global_mouse_position()
				mouse_velocity = Vector2.ZERO
				angular_velocity = 0.0
				
				# ACTIVAR TEMBLOR MOMENTÁNEO
				shake_intensity = shake_duration
		else:
			if dragging_card:
				# Verificar si se soltó en un área interactiva
				dropped_in_interactive_area = check_interactive_area(dragging_card)
				if not dropped_in_interactive_area:
					# Iniciar animación de retorno
					returning_card = dragging_card
					# original_position ya está guardado desde el inicio del drag
				else:
					# La carta se queda en su posición (fue droppeada exitosamente)
					pass
				
				dragging_card = null
				drag_offset = Vector2.ZERO
			

func check_interactive_area(card: Node2D) -> bool:
	# Verifica si la carta está sobre un área interactiva al soltar
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = card.global_position
	parameters.collide_with_areas = true
	var result = space_state.intersect_point(parameters)
	
	for hit in result:
		var collider = hit["collider"]
		if collider:
			collider = collider.get_parent()
			# Verificar si el collider tiene la señal/método de área interactiva
			if collider.has_method("is_interactive_area") and collider.is_interactive_area():
				return true
			# O verificar por grupo
			if collider.is_in_group("interactive_area"):
				return true
			# O verificar por nombre de clase
			if collider.is_class("Area2D") and collider.name.contains("Interactive"):
				return true
	
	return false

func clamp_card_to_screen(card: Node2D):
	var viewport_size = get_viewport_rect().size
	var half_card = card_size / 3.0
	
	var min_x = half_card.x
	var max_x = viewport_size.x - half_card.x
	var min_y = half_card.y
	var max_y = viewport_size.y - half_card.y
	
	card.global_position.x = clamp(card.global_position.x, min_x, max_x)
	card.global_position.y = clamp(card.global_position.y, min_y, max_y)
func connect_card_signals(card):
	card.connect('hovered',on_hovering_card)
	card.connect('hovering_off',on_hovering_card_off)
func on_hovering_card(card):
	pass
func on_hovering_card_off(card):
	pass
func raycast_check_for_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	
	var result = space_state.intersect_point(parameters)
	
	if result.size() != 0:
		var collider = result[0]["collider"] 
		return collider.get_parent() if collider else null
	else:
		return null

func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	var result = space_state.intersect_point(parameters)
	if result.size() != 0:
		var collider = result[0]["collider"] 
		return collider.get_parent() if collider else null
	else:
		return null
