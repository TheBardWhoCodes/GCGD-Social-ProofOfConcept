extends Node

const DEV = true

var multiplayer_peer = ENetMultiplayerPeer.new()
var url : String = "your-prod.url"
const PORT = 9009

var connected_peers : Dictionary = {}

func _ready():
	if DEV == true:
		url = "127.0.0.1"
	multiplayer_peer.create_server(PORT)
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer_peer.peer_connected.connect(_on_peer_connected)
	multiplayer_peer.peer_disconnected.connect(_on_peer_disconnected)
	print("Server is up and running.")


func _on_peer_connected(new_peer_id : int) -> void:
	print("Player " + str(new_peer_id) + " is joining...")
	# The connect signal fires before the client is added to the connected
	# clients in multiplayer.get_peers(), so we wait for a moment.
	await get_tree().create_timer(1).timeout
	add_player(new_peer_id)


func add_player(new_peer_id : int) -> void:
	var position: Vector2 = Vector2(0, 0)
	connected_peers[new_peer_id] = position
	print("Player " + str(new_peer_id) + " joined.")
	print("Currently connected Players: " + str(connected_peers.keys()))
	rpc("sync_player_list", connected_peers)

func _on_peer_disconnected(leaving_peer_id : int) -> void:
	# The disconnect signal fires before the client is removed from the connected
	# clients in multiplayer.get_peers(), so we wait for a moment.
	await get_tree().create_timer(1).timeout 
	remove_player(leaving_peer_id)

func remove_player(leaving_peer_id : int) -> void:
	if connected_peers.has(leaving_peer_id):
		connected_peers.erase(leaving_peer_id)
	print("Player " + str(leaving_peer_id) + " disconnected.")
	rpc("sync_player_list", connected_peers)

@rpc
func sync_player_list(_updated_connected_peer_ids):
	pass # only implemented in client (but still has to exist here)

@rpc("any_peer")
func _move_player(peer_id: int, direction: Vector2):
	rpc('set_new_velocity', peer_id, direction * 400)
	
@rpc
func set_new_velocity(peer_id, velocity):
	pass
	
@rpc("any_peer")
func _set_position(peer_id: int, position: Vector2):
	connected_peers[peer_id] = position

@rpc("any_peer")
func _set_initial_position(peer_id: int, position: Vector2):
	print("Set Initial Position")
	print(peer_id)
	connected_peers[peer_id] = position
	rpc("sync_player_list", connected_peers)
