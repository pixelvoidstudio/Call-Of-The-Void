class_name Game
extends Node2D

signal hostConnected

@onready var multiplayer_ui = $"../CanvasLayer/Multiplayer UI"
const PLAYER = preload("res://player.tscn")
var peer = NodeTunnelPeer.new()
var players_by_pid: Dictionary = {}
@export var max_players: int = 0
@export var turn = 1

@onready var DM :pixelvoid= $"../Die Circle/Die MANAGER"

func _ready() -> void:
	multiplayer.multiplayer_peer = peer
	peer.connect_to_relay("relay.nodetunnel.io", 9998)
	
	await peer.relay_connected
	$"../CanvasLayer/Multiplayer UI/VBoxContainer/HBoxContainer2".show()
	%OnlineID.text = peer.online_id
	$MultiplayerSpawner.spawn_function = add_player

func _on_host_pressed() -> void:
	peer.host()
	
	await peer.hosting
	
	hostConnected.emit()
	
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
	
	max_players += 1
	print(max_players)
	
	
	
	
	return player
@rpc("any_peer","call_local")
func set_next_player() -> void:
	print(max_players)
	turn = wrap(turn + 1, 1, max_players+1)
	print(turn)
	DM._setup.rpc_id(turn)
	$"../Label4".text = str(turn)




func _on_button_2_pressed() -> void:
	print("turn:", turn, "\nid: ", multiplayer.get_unique_id())
	if turn == multiplayer.get_unique_id():
		print("is yo turn bish boi")
		set_next_player.rpc()
