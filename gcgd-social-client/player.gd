extends CharacterBody2D
class_name Player
var this_players_peer_id: int
var multiplayer_peer: ENetMultiplayerPeer
var networking_client: NetworkingClient

func _ready() -> void:
	networking_client = get_tree().root.get_node('Networking')
	multiplayer_peer = networking_client.multiplayer_peer

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	networking_client.move_player(this_players_peer_id, input_direction)

func set_peer_id(peer_id: int):
	this_players_peer_id = peer_id

func sync_current_position():
	networking_client.set_position(this_players_peer_id, position)

func _physics_process(delta):
	var my_peer_id = multiplayer_peer.get_unique_id()
	if this_players_peer_id == my_peer_id:
		sync_current_position()
		get_input()
	move_and_slide()
