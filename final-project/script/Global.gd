extends Node2D

# Global Multiplayer State
class_name GameGlobal
var my_name: String = ""
var players: Dictionary = {} #ชื่อผู้เล่น
var players_point: Dictionary = {} #แต้ม
var players_turn: Dictionary = {} #เช็ค turn
var player_order: Array = []   # ลำดับการเล่น [peer_id]
var peer: ENetMultiplayerPeer = null

func copy_player_id():
	players_point = players.duplicate()
	for id in players_point.keys():
		players_point[id] = 0 

	players_turn = players.duplicate()
	for id in players_turn.keys():
		players_turn[id] = 0 
	
	# สุ่มเลือก 1 key และตั้งค่าเป็น 1
	var random_key = players_turn.keys().pick_random()
	players_turn[random_key] = 1

# ลบผู้เล่น (เมื่อ disconnect)
func remove_player(id: int) -> void:
	if players.has(id):
		print("🔴 ลบผู้เล่น: [%d] %s" % [id, players[id]])
		players.erase(id)
	
		
	if player_order.has(id):
		player_order.erase(id)
		


func _init():
	print("🌍 Global initialized")
