extends Node2D
signal hovered
signal hovering_off
#game phases : 
#1 draft , 
#2 card play you can put terran and creature but not advantages , 
#3 advantage face pre combat
#4 combat if theres two monties at the same time in the field you can start a combat the combat can be started with adventage if a card can take place just before this start
# inside combat the gameplay change to a 1v1 combat between monsties the one who wins gets the card of the rival (1 point) when a rival has 2 points above the other the rival win
#the weather influencce terrain in combat give some damage bonuses and other hazards in advanced stages
#5 evolution,a card automatically evolves after a turn in field if a combat didn't happen , a card normaly card evolves 3 times , evolution only grants new moves and combat options 
	#ev stage 1 - simple combos , grab , minor elemental attac
	#ev stage 2 - extended combos , parrys
	#ev stage 3 - elemental hazards(cooldown) if terrain its in advantage and stage 3
# in tie case both monster are deleted from field

#all terrains have 4 phases
	#0 inexistence 
	#1 calm (no advantages) 
	#2 bad weather (advantages depending on card) 
	#3 calamity (adventages potenciated)
# any advantage its a disaventage if the weather its a rival one for example water > fire > grass > earth
#all games start in neutral grass or field state
var onTop = false
#card object definition
var card_definition={
	"type":'monstie',
	"element":'water', 
	"terrain":'waves', #water advantage
	"interactive":true,
	"status":0, #0 normal, 1 poison, 2 sleep, 3 stuned, 4 hurt(hp under 30%), 5 dead
	"health_percentage":100, # defined by percentage for testing
	"name": "Antonino",
	"attack_type": "element",
	"attk":20, # from 5 to 50
	"def":5, # from 5 to 50
	"res": 10, # resistence how much one can evade/atk
	"sres":20, # status resistence
	"speed":10, # from 3 to 50 for now (hidden)
}
func _ready() -> void:
		# ✅ Verifica que el padre exista Y tenga el método
	var parent = get_parent()
	if parent and parent.has_method("connect_card_signals"):
		parent.connect_card_signals(self)
	else:
		push_warning("⚠️ Card %s: parent no tiene connect_card_signals" % name)
	pass # Replace with function body.
func _process(delta: float) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	emit_signal('hovered',self)
	if(onTop):
		$AnimationPlayer.play("hovered")
	pass # Replace with function body.


func _on_area_2d_mouse_exited() -> void:
	emit_signal('hovering_off',self)
	if(onTop):
		$AnimationPlayer.play_backwards("hovered")
	pass # Replace with function body.
