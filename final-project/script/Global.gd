extends Node

var my_name: String = ""
var players := {}  # เก็บรายชื่อผู้เล่นทั้งหมด
var room_code = ""  # รหัสห้อง (สำหรับ Client)

# ฟังก์ชันเพิ่มผู้เล่นใหม่ (เรียกจาก Host เท่านั้น)
func add_player(id: int, name: String):
	players[id] = name
	print("🟢 เก็บผู้เล่นใน Global: [%d] %s" % [id, name])
func _init():
	print("Global initialized")  # ตรวจสอบว่าโหลดจริง
