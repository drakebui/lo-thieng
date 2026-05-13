extends CharacterBody2D

const SPEED := 180.0


func _ready() -> void:
	# Thân — ~44×56px, rõ ràng hơn trong viewport 1024×768
	var body := Polygon2D.new()
	body.color = Color(0.28, 0.42, 0.62)
	body.polygon = PackedVector2Array([
		Vector2(-22, -26), Vector2(22, -26),
		Vector2(22, 30),   Vector2(-22, 30),
	])
	add_child(body)

	# Chi tiết tạp dề
	var apron := Polygon2D.new()
	apron.color = Color(0.60, 0.38, 0.18)
	apron.polygon = PackedVector2Array([
		Vector2(-12, -6), Vector2(12, -6),
		Vector2(12, 28),  Vector2(-12, 28),
	])
	add_child(apron)

	# Đầu
	var head := Polygon2D.new()
	head.color = Color(0.82, 0.68, 0.52)
	head.polygon = PackedVector2Array([
		Vector2(-16, -52), Vector2(16, -52),
		Vector2(16, -28),  Vector2(-16, -28),
	])
	add_child(head)

	# Collision khớp với thân
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(44, 56)
	col.shape = shape
	add_child(col)

	# Layer 1 = player, chỉ va chạm với tường (layer 4), không chặn khách (layer 2)
	collision_layer = 1
	collision_mask  = 4


func _physics_process(_delta: float) -> void:
	var x := 0.0
	var y := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  y += 1.0
	velocity = Vector2(x, y).normalized() * SPEED
	move_and_slide()
