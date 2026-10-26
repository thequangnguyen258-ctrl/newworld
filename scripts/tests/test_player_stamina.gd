extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var player_scene := load("res://scenes/characters/player.tscn")
	if player_scene == null:
		push_error("[FAIL] Không tải được scene người chơi.")
		quit(1)
		return
	var world := Node3D.new()
	var ground := StaticBody3D.new()
	var ground_shape := CollisionShape3D.new()
	var ground_box := BoxShape3D.new()
	ground_box.size = Vector3(100.0, 0.2, 100.0)
	ground_shape.shape = ground_box
	ground_shape.position.y = -0.1
	ground.add_child(ground_shape)
	world.add_child(ground)
	var player: CharacterBody3D = player_scene.instantiate()
	root.add_child(world)
	world.add_child(player)

	for _frame in range(5):
		await physics_frame
		await process_frame

	var initial_stamina: float = player.current_stamina
	Input.action_press("move_forward")
	Input.action_press("sprint")
	for _frame in range(30):
		await physics_frame

	if player.current_stamina >= initial_stamina or player.velocity.length() <= player.walk_speed:
		push_error("[FAIL] Chạy phải tiêu hao thể lực và tăng tốc.")
		quit(1)
		return

	Input.action_release("sprint")
	Input.action_release("move_forward")
	var stamina_after_sprinting: float = player.current_stamina
	for _frame in range(30):
		await physics_frame

	if player.current_stamina <= stamina_after_sprinting:
		push_error("[FAIL] Thể lực phải hồi khi ngừng chạy.")
		quit(1)
		return
	player.current_stamina = 1.0
	Input.action_press("move_forward")
	Input.action_press("sprint")
	for _frame in range(8):
		await physics_frame

	if not player.sprint_exhausted or player.current_stamina >= player.max_stamina * 0.25:
		push_error("[FAIL] Chạy liên tục phải kích hoạt trạng thái kiệt sức.")
		quit(1)
		return
	if player.velocity.length() > player.walk_speed + 0.1:
		push_error("[FAIL] Khi cạn thể lực, người chơi phải trở về tốc độ đi bộ.")
		quit(1)
		return
	Input.action_release("sprint")
	Input.action_release("move_forward")
	world.queue_free()
	await process_frame
	print("[PASS] Chạy tiêu hao thể lực, hồi khi nghỉ và giới hạn tốc độ khi kiệt sức.")
	quit()
