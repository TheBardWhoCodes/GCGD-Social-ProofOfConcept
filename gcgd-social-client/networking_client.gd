extends Node
class_name NetworkingClient

const DEV = true

@onready var connect_btn = $Lobby/ConnectBtn
@onready var disconnect_btn = $Lobby/DisconnectBtn
@onready var main_node = $Main
@onready var starting_point = $Main/StartingPoint

var multiplayer_peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var url : String = "ec2-18-117-120-174.us-east-2.compute.amazonaws.com"
const PORT = 9009

var connected_peers : Dictionary = {}
var my_player : Player;

const player_factory = preload("res://Player.tscn")

func _ready():
	if DEV == true:
		url = "127.0.0.1"
	update_connection_buttons()
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func add_player_to_scene(peer_id: int, position: Vector2):
	var player: Player = player_factory.instantiate()
	player.set_name(str(peer_id))
	player.set_peer_id(peer_id)
	player.position = position
	main_node.add_child(player)
	connected_peers[peer_id] = player

func _on_connect_btn_pressed() -> void:
	print("Connecting ...")
	multiplayer_peer.create_client(url, PORT)
	multiplayer.multiplayer_peer = multiplayer_peer
	update_connection_buttons()


func _on_disconnect_btn_pressed():
	var peer_id = multiplayer_peer.get_unique_id()
	var player = connected_peers[peer_id]
	player.queue_free()
	connected_peers.erase(peer_id)
	multiplayer_peer.close()
	update_connection_buttons()
	print("Disconnected.")

func _on_connected_to_server():
	print("I'm connected!")

func _on_server_disconnected():
	multiplayer_peer.close()
	update_connection_buttons()
	print("Connection to server lost.")

func update_connection_buttons() -> void:
	if multiplayer_peer.get_connection_status() == multiplayer_peer.CONNECTION_DISCONNECTED:
		connect_btn.disabled = false
		disconnect_btn.disabled = true
	if multiplayer_peer.get_connection_status() == multiplayer_peer.CONNECTION_CONNECTING:
		connect_btn.disabled = true
		disconnect_btn.disabled = true
	if multiplayer_peer.get_connection_status() == multiplayer_peer.CONNECTION_CONNECTED:
		connect_btn.disabled = true
		disconnect_btn.disabled = false

func set_position(peer_id, position):
	rpc('_set_position', peer_id, position)

func move_player(peer_id, direction):
	rpc('_move_player', peer_id, direction)

@rpc("authority")
func sync_player_list(updated_connected_peers: Dictionary):
	var my_peer_id = multiplayer_peer.get_unique_id()
	for peer_id in updated_connected_peers.keys():
		if !connected_peers.has(peer_id):
			add_player_to_scene(peer_id, updated_connected_peers[peer_id])
	
	for peer_id in connected_peers:
		if !updated_connected_peers.has(peer_id):
			var player = connected_peers[peer_id]
			player.queue_free()
			connected_peers.erase(peer_id)
			
	update_connection_buttons()
	print("Currently connected Players: " + str(connected_peers.keys()))

@rpc("any_peer")
func _set_position(peer_id, position):
	pass

@rpc
func _set_initial_position(peer_id: int, position: Vector2):
	pass

@rpc("any_peer")
func _move_player(peer_id, direction):
	pass

@rpc("authority")
func set_new_velocity(peer_id, new_velocity):
	if connected_peers.has(peer_id):
		var player: Player = connected_peers.get(peer_id)
		player.velocity = new_velocity
