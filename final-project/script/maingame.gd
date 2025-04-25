extends Node2D

# Node references
@onready var turn_label = $TurnLabel
@onready var dice = $Dice
@onready var dice_animation = $DiceAnimation
@onready var dice_face = $DiceFace
@onready var game_over = $GameOver
@onready var timer = $Timer
@onready var dice_button = $Dice_Button
@onready var is_host_label = $isHost
@onready var diceLabel = $DiceLabel
@onready var path_walk = $PathWalk  # ต้องมี Node นี้ใน Scene
@onready var path_follow = $PathWalk/PathFollow2D  # ต้องเป็น PathFollow2D
@onready var player = $PathWalk/PathFollow2D/Player1



const TOTAL_CELLS = 100
var curve: Curve2D

# Player paths
var player_nodes = [
	$PathWalk/Player1,
	$PathWalk/Player2,
	$PathWalk/Player3,
	$PathWalk/Player4
]

func _ready():
	if not multiplayer.has_multiplayer_peer():
		return_to_lobby()
		return
	
	var my_name = Global.my_name
	if multiplayer.is_server():
		is_host_label.text = "🖥️ คุณคือ Host " + my_name
	else:
		is_host_label.text = "🎮 คุณคือ Client " + my_name
	
	if Global.peer:
		multiplayer.multiplayer_peer = Global.peer
		
	# เชื่อมต่อสัญญาณปุ่ม dice_button
	dice_button.pressed.connect(_on_dice_pressed)
	# ตรวจสอบการเชื่อมต่อ Host
	await get_tree().create_timer(1.0).timeout
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return_to_lobby()
	
	# ตรวจสอบว่า Path2D มี Curve และจุดต่างๆ
	if path_walk.curve == null:
		push_error("Path2D ไม่มี Curve กําหนด!")
		return
	
	print("จํานวนจุดในเส้นทาง: ", path_walk.curve.get_point_count())
   # ตั้งค่า PathFollow2D
	path_follow.progress_ratio = 0
	path_follow.rotation = false

	
func move_player(steps: int) -> void:

	var target_cell = min(current_cell + steps, TOTAL_CELLS)
	var point_count = path_walk.curve.get_point_count()

	# เพิ่มการตรวจสอบให้ target_cell ไม่เกินจำนวนจุดใน curve
	if target_cell >= point_count:
		print("พยายามเดินเกินจำนวนจุด curve!")
		target_cell = point_count - 1  # จำกัดการเดินให้อยู่ในขอบเขตของ curve

	for i in range(current_cell + 1, target_cell + 1):
		var point_position = path_walk.curve.get_point_position(i)
		var tween := create_tween()
		tween.tween_property(path_follow, "position", point_position, 0.2)
		current_cell = target_cell

	print("ถึงจุดที่ ", current_cell)
	


func return_to_lobby():
	get_tree().change_scene_to_file("res://Scene/lobby.tscn")

	# เมื่อกดปุ่ม 	Dice
func _on_dice_pressed():
	#if multiplayer.get_unique_id() != Global.get_current_turn_id():
		#return # ไม่ใช่เทิร์นของเรา
		#
		# เล่น animation ทอยลูกเต๋า
	$DiceFace.hide()
	$DiceAnimation.show()
	$DiceAnimation.play("DiceRolling")
	
	await $DiceAnimation.animation_finished
	var my_name = Global.my_name
	
	# สุ่มค่า 1-6
	var roll = randi_range(1, 6)
	diceLabel.text = my_name + "🎲 ทอยได้ : " + str(roll)
	print(my_name, "🎲 ทอยได้ : " , roll)

	$DiceFace.frame = roll - 1
	$DiceFace.show()
	$DiceAnimation.hide()
	move_player(roll)
	# ส่ง ID ผู้เล่นและผลทอยไปให้ Host
	send_roll_to_host.rpc_id(1, roll)  # id 1 คือ host


#Host
# Dictionary เก็บข้อมูลผู้เล่น
var players_data = {}  # {player_id: {"name": "ชื่อ", "position": ตำแหน่ง, "node": PathFollow2D}}

@rpc("any_peer", "reliable")
func send_roll_to_host(player_id: int, rolled_number: int):
	if not multiplayer.is_server():
		return
	
	print("📨 รับค่าทอยจากผู้เล่น ID:", player_id, " ได้แต้ม:", rolled_number)
	move_player(rolled_number)
	# ตรวจสอบว่าเป็นตาของผู้เล่นนี้หรือไม่
	#if player_id != Global.get_current_turn_id():
		#print("⚠️ ไม่ใช่ตาของผู้เล่นนี้")
		#return
	
	# 1. หาตำแหน่งปัจจุบันของผู้เล่น
	#var current_pos = players_data[player_id]["position"]
	
	# 2. คำนวณตำแหน่งใหม่
	#var new_pos = current_pos + rolled_number
	
	# 3. ตรวจสอบไม่ให้เกินกระดาน
	#const BOARD_MAX = 100  # จำนวนช่องสูงสุด
	#if new_pos > BOARD_MAX:
		#new_pos = BOARD_MAX
	
	# 4. ตรวจสอบบันไดหรืองู
	#new_pos = check_snakes_and_ladders(new_pos)
	
	# 5. อัพเดทตำแหน่งผู้เล่น
	#players_data[player_id]["position"] = new_pos
	
	# 6. สั่งให้ผู้เล่นเคลื่อนที่ (ทั้ง Host และ Client)
	#move_player_to_position.rpc(player_id, current_pos, new_pos)
	#
	## 7. ตรวจสอบผู้ชนะ
	#if new_pos >= BOARD_MAX:
		#announce_winner.rpc(player_id)
	#else:
		## 8. เปลี่ยนตาผู้เล่น
		#change_turn.rpc()


@rpc("reliable")
func move_player_to_position(player_id: int, start_pos: int, end_pos: int):
	var path_follow = players_data[player_id]["node"]
	var curve = $Path2D.curve
	var point_count = curve.get_point_count()
	
	# สร้าง Tween สำหรับการเคลื่อนที่แบบต่อเนื่อง
	var tween = create_tween()
	
	# เคลื่อนที่ทีละช่อง
	for pos in range(start_pos + 1, end_pos + 1):
		var progress = float(pos) / (point_count - 1)
		tween.tween_property(path_follow, "progress_ratio", progress, 0.2)
		tween.tween_interval(0.05)  # หยุดเล็กน้อยระหว่างช่อง
	
	# เมื่อเคลื่อนที่เสร็จ
	tween.tween_callback(check_tile_effect.bind(player_id, end_pos))

func check_tile_effect(player_id: int, position: int):
	# ตรวจสอบผลกระทบของช่อง (บันได/งู)
	var final_pos = check_snakes_and_ladders(position)
	
	if final_pos != position:
		# หากมีการเคลื่อนที่เพิ่มเติมจากบันไดหรืองู
		players_data[player_id]["position"] = final_pos
		move_player_to_position.rpc(player_id, position, final_pos)


func check_snakes_and_ladders(position: int) -> int:
	var special_tiles = {
		3: 22, 5: 8, 20: 11, 17: 4,
		# เพิ่มจุดบันไดและงูตามต้องการ
	}
	return special_tiles.get(position, position)




@rpc("any_peer", "reliable")
func request_player_list():
	var sender_id = multiplayer.get_remote_sender_id()
	# Host ส่งข้อมูลกลับไปให้ Client ที่ขอ
	send_player_list.rpc_id(sender_id, Global.players)

# Host ส่งข้อมูลผู้เล่นกลับไปให้ Client
@rpc("authority", "reliable")
func send_player_list(players_data: Dictionary):
	print("Received player list from host:")
	for id in players_data:
		print("Player ID: ", id, " Name: ", players_data[id])


@rpc("authority", "call_local")
func start_game():
	# เรียงลำดับ turn ตาม ID
	Global.turn_order = Global.players.keys()
	Global.turn_order.sort()  # เรียงตาม id เลย

	Global.current_turn_index = 0
	sync_turn_to_all.rpc(Global.get_current_turn_id())

@rpc("authority", "reliable")
func next_turn():
	Global.advance_turn()
	sync_turn_to_all.rpc(Global.get_current_turn_id())

@rpc("any_peer", "call_local", "reliable")
func sync_turn_to_all(current_turn_id: int):
	var is_my_turn = (multiplayer.get_unique_id() == current_turn_id)
	print("🎯 My turn:", is_my_turn)
	turn_label.text = "🎲 เทิร์นของคุณ!" if is_my_turn else "⏳ รอผู้เล่นคนอื่น..."
