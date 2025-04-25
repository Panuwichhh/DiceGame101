extends Node2D

# 🌐 Global Multiplayer State สำหรับเกม
class_name GameGlobal

# ชื่อของผู้เล่นคนนี้ (กำหนดจากเมนู)
var my_name: String = ""


# รายชื่อผู้เล่นทั้งหมด: {peer_id: player_name}
var players: Dictionary = {}
var player_order: Array = []   # ลำดับการเล่น [peer_id]
var current_turn_index: int = 0
var player_positions: Dictionary = {}  # {peer_id: position}

const TOTAL_TILES: int = 100



# ENet peer ที่ใช้เชื่อมต่อกับเซิร์ฟเวอร์
var peer: ENetMultiplayerPeer = null

func _init():
	print("🌍 Global initialized")

# เพิ่มตัวแปรเก็บการแมป ID ผู้เล่นกับสกินผู้เล่น
var player_slots: Dictionary = {}  # {peer_id: slot_number (1-4)}

# ฟังก์ชันเมื่อมี Client เข้ามา
func add_client(id: int, name: String):
	# หา ID ที่ว่างเริ่มจาก 2
	var new_id = 2
	while players.has(new_id) and new_id <= 4:
		new_id += 1
	
	if new_id > 4:
		print("⚠️ เกมเต็มแล้ว ไม่สามารถเพิ่มผู้เล่นได้")
		return
	
	add_player(new_id, name)
	player_order.append(new_id)
	player_order.sort()  # เรียงลำดับ 1,2,3,4

# เมื่อเพิ่มผู้เล่นใหม่
func add_player(id: int, name: String) -> void:
	players[id] = name
	player_positions[id] = 0
	
	# จองสกินผู้เล่นถ้ายังไม่มี
	if not player_slots.has(id):
		for slot in range(1, 5):  # สล็อต 1-4
			if not player_slots.values().has(slot):
				player_slots[id] = slot
				break
	
	print("🟢 เพิ่มผู้เล่น: [%d] %s (สกิน %d)" % [id, name, player_slots.get(id, 0)])

# ลบผู้เล่น (เมื่อ disconnect)
func remove_player(id: int) -> void:
	if players.has(id):
		print("🔴 ลบผู้เล่น: [%d] %s" % [id, players[id]])
		players.erase(id)
		player_positions.erase(id)
		player_order.erase(id)

func get_current_turn_id() -> int:
	if player_order.size() == 0:
		return 0
	return player_order[current_turn_index]

func advance_turn():
	if player_order.size() == 0:
		return
	current_turn_index = (current_turn_index + 1) % player_order.size()
