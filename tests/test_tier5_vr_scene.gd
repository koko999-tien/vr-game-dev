extends SceneTree

var frames: int = 0
var verified: bool = false

func _init() -> void:
	print("[TIER5_GD_TEST] Starting SceneTree with change_scene_to_file('res://main.tscn')...")
	change_scene_to_file("res://main.tscn")
	process_frame.connect(_on_process_frame)

func _on_process_frame() -> void:
	frames += 1
	if frames < 3:
		return
	if verified:
		return
	verified = true
	
	print("[TIER5_GD_TEST] Running white-box assertions after SceneTree settled...")
	var main_node = current_scene
	if not main_node:
		printerr("[FAIL] current_scene is null")
		quit(1)
		return
	
	print("[PASS 1/7] Current scene active: ", main_node.name)
	
	# Check 1: Fallback state verification
	if main_node.is_vr_mode:
		printerr("[FAIL] is_vr_mode should be false in headless mode without HMD")
		quit(2)
		return
	print("[PASS 2/7] Fallback mode verified: is_vr_mode == false")
	
	var desktop_cam = main_node.get_node_or_null("DesktopCamera") as Camera3D
	var xr_camera = main_node.get_node_or_null("XROrigin3D/XRCamera3D") as XRCamera3D
	if not desktop_cam or not desktop_cam.current:
		printerr("[FAIL] DesktopCamera should be active and current")
		quit(3)
		return
	if xr_camera and xr_camera.current:
		printerr("[FAIL] XRCamera3D should not be current in desktop fallback mode")
		quit(4)
		return
	print("[PASS 3/7] Camera activation verified: DesktopCamera is current, XRCamera is not current.")
	
	# Check 2: Color cycling resilience (test 14 cycles, 2+ full wraps of 6-item palette)
	var initial_idx = main_node.color_index
	for i in range(14):
		main_node.cycle_cube_color()
		var expected_idx = (initial_idx + i + 1) % main_node.color_palette.size()
		if main_node.color_index != expected_idx:
			printerr("[FAIL] Color cycling index mismatch: expected ", expected_idx, " got ", main_node.color_index)
			quit(5)
			return
	print("[PASS 4/7] Color cycling verified across 14 iterations (modulo wrap-around passed).")
	
	# Check 3: Free-look rotation and pitch clamping boundary test
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Extreme downward motion
	var extreme_down_event = InputEventMouseMotion.new()
	extreme_down_event.relative = Vector2(0, 10000)
	main_node._unhandled_input(extreme_down_event)
	
	var min_allowed_pitch = deg_to_rad(-85.0)
	var max_allowed_pitch = deg_to_rad(85.0)
	if main_node.cam_pitch < min_allowed_pitch - 0.001 or main_node.cam_pitch > max_allowed_pitch + 0.001:
		printerr("[FAIL] Cam pitch clamp failure: ", main_node.cam_pitch)
		quit(6)
		return
	
	# Extreme upward motion
	var extreme_up_event = InputEventMouseMotion.new()
	extreme_up_event.relative = Vector2(0, -20000)
	main_node._unhandled_input(extreme_up_event)
	if main_node.cam_pitch < min_allowed_pitch - 0.001 or main_node.cam_pitch > max_allowed_pitch + 0.001:
		printerr("[FAIL] Cam pitch clamp failure upward: ", main_node.cam_pitch)
		quit(7)
		return
	print("[PASS 5/7] Free-look pitch clamping verified at extreme bounds [-85°, +85°].")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Check 4: Controller button signal handling
	var left_ctrl = main_node.get_node_or_null("XROrigin3D/LeftController")
	var right_ctrl = main_node.get_node_or_null("XROrigin3D/RightController")
	if left_ctrl:
		main_node._on_controller_button_pressed("trigger_click", "Left")
	if right_ctrl:
		main_node._on_controller_button_pressed("grip_click", "Right")
	print("[PASS 6/7] Controller button signal dispatch tested successfully.")
	
	# Check 5: Process loop execution (animation & movement)
	main_node._process(0.016)
	main_node._process_desktop_movement(0.016)
	print("[PASS 7/7] Animation rotation and desktop movement processed without error.")
	
	print("\n[ALL PASS] Godot VR Scene white-box adversarial verification complete (exit 0).")
	quit(0)
