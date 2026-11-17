extends Node3D

var xr_interface: XRInterface
var is_vr_mode: bool = false

@onready var desktop_cam: Camera3D = $DesktopCamera
@onready var xr_origin: XROrigin3D = $XROrigin3D
@onready var xr_camera: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var left_controller: XRController3D = $XROrigin3D/LeftController
@onready var right_controller: XRController3D = $XROrigin3D/RightController
@onready var colored_cube: StaticBody3D = $ColoredCube
@onready var cube_mesh: MeshInstance3D = $ColoredCube/CubeMesh

var move_speed: float = 4.0
var mouse_sensitivity: float = 0.003
var cam_yaw: float = 0.0
var cam_pitch: float = 0.0

var color_palette: Array[Color] = [
	Color(0.15, 0.65, 0.95),  # Cyan
	Color(0.95, 0.25, 0.35),  # Coral Red
	Color(0.25, 0.90, 0.45),  # Emerald Green
	Color(0.95, 0.85, 0.20),  # Golden Yellow
	Color(0.75, 0.30, 0.95),  # Purple
	Color(1.00, 0.55, 0.15)   # Amber Orange
]
var color_index: int = 0

func _ready() -> void:
	print("[VR_INIT] ========================================")
	print("[VR_INIT] Godot 4 VR Hello World - Initializing...")
	print("[VR_INIT] ========================================")
	
	# Connect interaction signals
	if colored_cube:
		colored_cube.input_event.connect(_on_cube_input_event)
	
	if left_controller:
		left_controller.button_pressed.connect(_on_controller_button_pressed.bind("Left"))
	if right_controller:
		right_controller.button_pressed.connect(_on_controller_button_pressed.bind("Right"))
	
	# OpenXR Interface Detection & Initialization
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface:
		print("[VR_INIT] OpenXR interface found: ", xr_interface.get_name())
		if xr_interface.is_initialized():
			print("[VR_INIT] OpenXR interface already active!")
			_setup_vr()
		else:
			print("[VR_INIT] Probing OpenXR runtime initialization...")
			if xr_interface.initialize():
				print("[VR_INIT] OpenXR runtime successfully initialized!")
				_setup_vr()
			else:
				print("[VR_INIT] OpenXR initialization returned false (No HMD / headless CI).")
				_setup_desktop_fallback()
	else:
		print("[VR_INIT] OpenXR interface not found on this platform.")
		_setup_desktop_fallback()

func _setup_vr() -> void:
	is_vr_mode = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	get_viewport().use_xr = true
	if desktop_cam:
		desktop_cam.current = false
	if xr_camera:
		xr_camera.current = true
	print("[VR_MODE] Stereoscopic VR rendering enabled on active XR viewport.")

func _setup_desktop_fallback() -> void:
	is_vr_mode = false
	get_viewport().use_xr = false
	if desktop_cam:
		desktop_cam.current = true
		desktop_cam.make_current()
	print("[DESKTOP_FALLBACK] Desktop Camera active at: ", desktop_cam.global_position if desktop_cam else Vector3.ZERO)
	print("[DESKTOP_FALLBACK] Controls:")
	print("   - Mouse Click: Capture mouse to look around")
	print("   - Mouse Move: Free-look rotation (Pitch / Yaw)")
	print("   - ESC: Release mouse cursor")
	print("   - W/S: Move Forward / Backward")
	print("   - A/D: Strafe Left / Right")
	print("   - Space/E: Ascend Up")
	print("   - Shift/Q: Descend Down")
	print("   - Left Click on ColoredCube: Cycle cube colors")

func _unhandled_input(event: InputEvent) -> void:
	if is_vr_mode:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if desktop_cam:
			cam_yaw -= event.relative.x * mouse_sensitivity
			cam_pitch -= event.relative.y * mouse_sensitivity
			cam_pitch = clampf(cam_pitch, deg_to_rad(-85.0), deg_to_rad(85.0))
			desktop_cam.rotation = Vector3(cam_pitch, cam_yaw, 0.0)

func _process(delta: float) -> void:
	# Continuous gentle animation for ColoredCube
	if colored_cube:
		colored_cube.rotate_y(0.7 * delta)
		colored_cube.rotate_x(0.3 * delta)
	
	# Free-look keyboard movement for desktop fallback
	if not is_vr_mode and desktop_cam:
		_process_desktop_movement(delta)

func _process_desktop_movement(delta: float) -> void:
	var input_dir = Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir += -desktop_cam.global_transform.basis.z
	if Input.is_key_pressed(KEY_S):
		input_dir += desktop_cam.global_transform.basis.z
	if Input.is_key_pressed(KEY_A):
		input_dir += -desktop_cam.global_transform.basis.x
	if Input.is_key_pressed(KEY_D):
		input_dir += desktop_cam.global_transform.basis.x
	if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_E):
		input_dir += Vector3.UP
	if Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_Q):
		input_dir += Vector3.DOWN
	
	if input_dir.length_squared() > 0.0001:
		desktop_cam.position += input_dir.normalized() * move_speed * delta

func _on_cube_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		cycle_cube_color()

func _on_controller_button_pressed(button_name: String, controller_tag: String) -> void:
	print("[VR_INPUT] %s Controller pressed: %s" % [controller_tag, button_name])
	cycle_cube_color()

func cycle_cube_color() -> void:
	color_index = (color_index + 1) % color_palette.size()
	var new_color = color_palette[color_index]
	if cube_mesh:
		var mat = cube_mesh.get_surface_override_material(0)
		if mat and mat is StandardMaterial3D:
			mat.albedo_color = new_color
		else:
			var new_mat = StandardMaterial3D.new()
			new_mat.albedo_color = new_color
			new_mat.metallic = 0.2
			new_mat.roughness = 0.3
			cube_mesh.set_surface_override_material(0, new_mat)
	print("[INTERACTION] ColoredCube cycled to color index %d: %s" % [color_index, str(new_color)])
