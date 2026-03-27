class_name Game
extends Node2D

@onready var multiplayer_ui = $"../CanvasLayer/Multiplayer UI"
const PLAYER = preload("res://player.tscn")
var peer = NodeTunnelPeer.new()
var players_by_pid: Dictionary = {}
var turn_order: Array[int] = []
@export var current_player_idx: int = 0

func _ready() -> void:
	multiplayer.multiplayer_peer = peer
	peer.connect_to_relay("relay.nodetunnel.io", 9998)
	
	await peer.relay_connected
	
	%OnlineID.text = peer.online_id
	$MultiplayerSpawner.spawn_function = add_player

func _on_host_pressed() -> void:
	peer.host()
	
	await peer.hosting
	
	DisplayServer.clipboard_set(peer.online_id)
	
	multiplayer.peer_connected.connect(
		func(pid):
			print("Peer " + str(pid) + " has joined the game")
			$MultiplayerSpawner.spawn(pid)
	)
	
	$MultiplayerSpawner.spawn(multiplayer.get_unique_id())
	multiplayer_ui.hide()

func _on_join_pressed() -> void:
	peer.join(%HostOnlineID.text)
	
	await peer.joined
	
	multiplayer_ui.hide()

func add_player(pid):
	var player = PLAYER.instantiate()
	player.name = str(pid)
	players_by_pid[pid] = player
	
	# TODO KYS
	if not turn_order.has(pid):
		turn_order.append(pid)
	
	if turn_order.size() == 1:
		current_player_idx = 0
		
		if multiplayer.is_server():
			_apply_turn.rpc(pid, current_player_idx)
	
	return player

func set_next_player() -> void:
	if turn_order.is_empty():
		return
	
	current_player_idx = wrapi(current_player_idx + 1, 0, turn_order.size() + 1)
	var next_pid := turn_order[current_player_idx]
	
	_apply_turn.rpc(next_pid, current_player_idx)

@rpc("authority", "call_local", "reliable")
func _apply_turn(pid: int, idx: int):
	current_player_idx = idx
	$"../Die Circle/Die MANAGER".set_multiplayer_authority(pid)
	print("Turn owner is now peer: ", pid)
	print("Local peer: ", multiplayer.get_unique_id(), " | Die manager authority? ", $"../Die Circle/Die MANAGER".is_multiplayer_authority())

@rpc("any_peer","reliable")
func _request_next_turn() -> void:
	if not multiplayer.is_server():
		return
	
	set_next_player()

func _on_button_2_pressed() -> void:
	print("IS MULT AUTH: ", $"../Die Circle/Die MANAGER".is_multiplayer_authority())
	if multiplayer.is_server():
		_request_next_turn()
	else:
		_request_next_turn.rpc_id(1)
