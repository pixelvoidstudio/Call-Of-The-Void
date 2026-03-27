extends Node2D
class_name pixelvoid

# lobotomy threshold my beloved
var lobotomy_threshold: int = 3
var is_rolling = false

# dice dict variables
var l = ["lunie","cat","life","skull","crystal","void"]

@export var dice_dict = {}
var dice_example = {
	"is_picked": false,
	"is_rolling": false,
	"is_snapped": true,
	"current_face": 4
	}

# card modifier
@export var non_rerollable:        Array = ["skull"]
@export var minimum_reroll_amount: int   = 2
@export var thief_mode:            bool  = false
@export var lunie_worth:           int   = 100
@export var crystal_worth:         int   = 1
@export var cat_worth:             int   = 0
@export var extra_crystals:        int   = 0
@export var extra_lunies:          int   = 0
@export var set_bonus:             bool  = true
@export var chaos_bonus:           bool  = false
@export var reroll_penalty:        int   = 0
@export var max_reroll:            int   = -1
@export var reroll_amount:         int   = 0
@export var sigil_penalty:         int   = 0
@export var crystal_multiplier:    int   = 1
@export var lunie_multiplier:      int   = 1
@export var equilibrium:           bool  = false
@export var life_and_death:        bool  = false
@export var void_resistance:       bool  = false

# card DIHtionary
@export var deck = []
var card_dict = {
	"adorable thief":{
		"description": "UGH",
		"code": "code.thief_mode = true",
		"amount": 2
		},
	"cat frenzy": {
		"description": "UGH",
		"code": "code.lunie_worth = 0\n	code.crystal_worth = 0\n	code.cat_worth = 200",
		"amount": 3
		},
	"cat lover":{
		"description": "UGH",
		"code": "code.non_rerollable.append(code.l[1])",
		"amount": 3
		},
	"crystal":{
		"description": "UGH",
		"code": "code.extra_crystals += 1",
		"amount": 4
		},
	"curse of greed":{
		"description": "UGH",
		"code": "code.reroll_penalty = 100",
		"amount": 2
		},
	"curse of pride":{
		"description": "UGH",
		"code": "code.minimum_reroll_amount = 3",
		"amount": 2
		},
	"curse of sloth":{
		"description": "UGH",
		"code": "code.max_reroll = 2",
		"amount": 2
		},
	"detection":{
		"description": "UGH",
		"code": "code.sigil_penalty = 100",
		"amount": 3
		},
	"double crystal":{
		"description": "UGH",
		"code": "code.crystal_multiplier = 2",
		"amount": 3
		},
	"double lunies":{
		"description": "UGH",
		"code": "code.lunie_multiplier = 2",
		"amount": 3
		},
	"double skulls":{
		"description": "UGH",
		"code": "code.lobotomy_threshold -= 2",
		"amount": 2
		},
	"embrace chaos":{
		"description": "UGH",
		"code": "code.set_bonus = false\n	code.chaos_bonus = true",
		"amount": 3
		},
	"equilibrium":{
		"description": "UGH",
		"code": "code.equilibrium = true",
		"amount": 3
		},
	"life and death":{
		"description": "UGH",
		"code": "code.life_and_death = true",
		"amount": 2
		},
	"lunie":{
		"description": "UGH",
		"code": "code.extra_lunies += 1",
		"amount": 4
		},
	"skull":{
		"description": "UGH",
		"code": "code.lobotomy_threshold -= 1",
		"amount": 3
		},
	"treasure hunter":{
		"description": "UGH",
		"code": "code.lunie_worth = 200\n	code.crystal_worth = 0",
		"amount": 3
		},
	"void resistance":{
		"description": "UGH",
		"code": "code.void_resistance = true",
		"amount": 3
		},
}

# labulls
@onready var score_label: Label = $"../../Label"
@onready var crystal_label: Label = $"../../Label2"
@onready var card_label: Label = $"../../Label3"
@onready var MM :Game= $"../../Multiplayer Manager"

@rpc("any_peer","reliable")
func reset_turn():
	lobotomy_threshold = 3 #
	thief_mode = false 
	non_rerollable = ["skull"] #
	
	lunie_worth = 100 #
	crystal_worth = 1 #
	cat_worth = 0 #
	
	extra_crystals = 0 #
	extra_lunies = 0 #
	
	set_bonus = true #
	chaos_bonus = false #
	
	reroll_penalty = 0 
	
	max_reroll = -1 #
	reroll_amount = 0 #
	
	minimum_reroll_amount = 2 #
	
	sigil_penalty = 0 #
	
	crystal_multiplier = 1 #
	lunie_multiplier = 1 #
	
	equilibrium = false #
	life_and_death = false #
	void_resistance = false #

@rpc("any_peer","reliable")
func start_turn():
	draw_card()
	
	for DIE in dice_dict:
		DIE.roll_die()

func end_turn():
	pass

@export var current_card = ""

func draw_card():
	if is_multiplayer_authority():
		current_card = deck[0]
		deck.remove_at(0)
		execute_string(card_dict[current_card]["code"])
		update_card.rpc(current_card)

@rpc("call_local")
func update_card(c=""):
	$"../../CardBack".texture = load("res://cards/"+c+".png")
	card_label.text = c

@rpc("any_peer","reliable")
func setup_cards():
	for card in card_dict:
		var card_amount = card_dict[card]["amount"]
		for i in card_amount:
			deck.append(card)
	
	deck.shuffle()


# ------- SETUP -------
func _ready() -> void:
	MM.connect("hostConnected",_setup)

@rpc("any_peer","call_local")
func _setup():
	if MM.turn == multiplayer.get_unique_id():
		if multiplayer.is_server():
			setup_dice()
			setup_cards()
			reset_turn()
			start_turn()
		else:
			setup_dice.rpc_id(1)
			setup_cards.rpc_id(1)
			reset_turn.rpc_id(1)
			start_turn.rpc_id(1)

@rpc("any_peer","reliable")
func setup_dice():
	
	for DIE in get_children():
		# connect signals
		DIE.landed.connect(on_die_landed)
		DIE.picked_updated.connect(_die_picked_updated)
		
		# add to dice_dict
		dice_dict[DIE] = {
			"is_picked": false,
			"is_rolling": false,
			"is_snapped": true,
			"current_face": "crystal"
			}

# ------- SIGNALS -------
func on_die_landed(die, face):
	#update specific die
	dice_dict[die]["is_rolling"] = false
	dice_dict[die]["is_snapped"] = true
	dice_dict[die]["current_face"] = face
	
	# is roll over
	var snapped_and_picked = get_amount([["is_picked",true],["is_snapped",true]])
	var picked = get_amount([["is_picked",true]])
	
	if snapped_and_picked == picked:
		finished_roll()

func _on_button_pressed() -> void:
	print("is my turn: ",(MM.turn == multiplayer.get_unique_id()),"   id: ",
	MM.turn," myid: ", multiplayer.get_unique_id())
	if MM.turn == multiplayer.get_unique_id():
		press_roll.rpc()
@rpc("any_peer","call_local")
func press_roll():
		if reroll_amount >= max_reroll and max_reroll != -1:
			return
		
		if is_rolling or get_amount([["is_picked",true]]) < minimum_reroll_amount:
			return
		
		reroll_amount += 1
		print("run")
		start_roll.rpc_id(1)

func _on_button_2_pressed() -> void:
	score_label.text = str("Score: ", calculate_score())
	crystal_label.text = str("Crystals: ", calculate_crystals())

func _die_picked_updated(die, picked) -> void:
	if die not in dice_dict:
		push_error("DAWG WDYM THE DICE DOESNT EXIST WAITWAITWAITWAITWAITWAITWAIT")
		return 
	
	dice_dict[die]["is_picked"] = picked

# ------- ROLL FUNCTIONS -------
@rpc("any_peer","call_local")
func start_roll():
	for die in dice_dict:
		if dice_dict[die]["is_picked"] == true:
			
			#NEXT dawg this is_rolling statement is NOT it
			is_rolling = true
			print(die)
			die.roll_die()
			dice_dict[die]["is_rolling"] = true
			dice_dict[die]["is_snapped"] = false

func finished_roll():
	is_rolling = false
	unpick_all_dice()

func unpick_all_dice():
	for die in dice_dict:
		if multiplayer.is_server():
			die.toggle_pick(false)
		else:
			if $"../../Multiplayer Manager".turn == multiplayer.get_unique_id():
				die.toggle_pick.rpc_id(1,false)


# ------- HELPERS -------
func get_amount(checklist = []) -> int :
	var amount = 0
	for die in dice_dict:
		var valid = true
		for i in checklist:
			if dice_dict[die][i[0]] != i[1]:
				valid = false
		if valid: amount += 1
	
	return amount

func calculate_score() -> int:
	var dead = false
	var score = 0
	var penalties = 0
	
	for type in l:
		var amount = get_amount([["current_face",type]])
		var set_size
		
		# calculate penalties
		if type == "life" or type == "void":
			penalties += amount * sigil_penalty
		
		if type == "skull" and amount >= lobotomy_threshold:
			dead = true
		
		match type:
			"lunie":
				score += (amount + extra_lunies) * lunie_worth * lunie_multiplier
				set_size = amount + extra_lunies
			"crystal":
				set_size = amount + extra_crystals
			"cat":
				score += amount * cat_worth
				set_size = amount
			"life":
				if not life_and_death:
					set_size = amount
				else:
					set_size = amount + get_amount([["current_face","void"]])
			"void":
				if not life_and_death:
					set_size = amount
				else:
					set_size = 0
			_:
				set_size = amount
		
		score += calculate_set_bonus(set_size)
	
	score += calculate_chaos_bonus()
	
	if dead:
		return - penalties
	else:
		return score - penalties

func calculate_crystals():
	var skull_amount = get_amount([["current_face","skull"]])
	if skull_amount >= lobotomy_threshold:
		return 0
	
	var crystals = get_amount([["current_face", "crystal"]]) + calculate_equilibrium_bonus()
	return (crystals + extra_crystals) * crystal_worth * crystal_multiplier

func calculate_set_bonus(amount):
	if !set_bonus:
		return 0
	
	var bonus = 0
	match amount:
		3: bonus = 100
		4: bonus = 200
		5: bonus = 500
		6: bonus = 1000
		7: bonus = 2000
		8: bonus = 4000
		9: bonus = 8000
		10: bonus = 16000
		_: bonus = 0
	return bonus

func calculate_chaos_bonus():
	if not chaos_bonus:
		return 0
	
	var different_symbols = 0
	for type in l:
		var amount = get_amount([["current_face",type]])
		if amount >= 1:
			different_symbols += 1
	
	if different_symbols >= 6:
		return 1000
	else:
		return 0

func calculate_equilibrium_bonus():
	if not equilibrium:
		return 0
	
	var life_amount  = get_amount([["current_face","life"]])
	var void_amount  = get_amount([["current_face","void"]])
	
	return 2 * min(life_amount,void_amount)

func execute_string(code: String) -> void:
	var dynamic_script = GDScript.new()
	dynamic_script.source_code = "func run(code):\n\t" + code
	var err = dynamic_script.reload()
	if err != OK:
		print("Failed to compile dynamic script!")
		return
	var runner = dynamic_script.new()
	runner.run(self)
