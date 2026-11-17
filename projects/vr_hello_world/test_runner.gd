extends SceneTree

# Expose get_tree() method for compatibility with standard Node script conventions
func get_tree() -> SceneTree:
	return self

func _fail(code: int, message: String, node_to_free: Node = null) -> void:
	printerr("FAIL [Code ", code, "]: ", message)
	if is_instance_valid(node_to_free):
		node_to_free.free()
	get_tree().quit(code)

func _init() -> void:
	print("--- Running Headless VR Project Validation Test ---")
	var scene_path: String = "res://main.tscn"
	
	# 1. Assert scene file exists
	if not ResourceLoader.exists(scene_path):
		_fail(1, "Scene file does not exist: " + scene_path)
		return
	
	# 2. Assert scene loads as PackedScene
	var scene_res = load(scene_path)
	if not scene_res is PackedScene:
		_fail(2, "Resource at " + scene_path + " is not a PackedScene")
		return
	print("PASS [1/6]: Scene resource loaded: ", scene_path)
	
	# 3. Assert scene instantiation succeeds
	var instance = scene_res.instantiate()
	if instance == null:
		_fail(3, "Scene instantiation failed: " + scene_path)
		return
	print("PASS [2/6]: Scene instantiated successfully as: ", instance.get_class())
	
	# 4. Assert XROrigin3D exists
	var origin: XROrigin3D = null
	if instance is XROrigin3D:
		origin = instance
	else:
		origin = instance.find_child("XROrigin3D", true, false) as XROrigin3D
		
	if origin == null:
		_fail(4, "XROrigin3D node missing from scene hierarchy.", instance)
		return
	print("PASS [3/6]: Verified node XROrigin3D found (name=", origin.name, ")")
	
	# 5. Assert XRCamera3D exists under origin
	var camera: XRCamera3D = origin.find_child("XRCamera3D", true, false) as XRCamera3D
	if camera == null:
		_fail(5, "XRCamera3D node missing under XROrigin3D.", instance)
		return
	print("PASS [4/6]: Verified node XRCamera3D found (name=", camera.name, ")")
	
	# 6. Assert XRController3D nodes exist with correct trackers
	var left_ctrl: XRController3D = null
	var right_ctrl: XRController3D = null
	
	for child in origin.get_children():
		if child is XRController3D:
			if child.tracker == &"left_hand":
				left_ctrl = child
			elif child.tracker == &"right_hand":
				right_ctrl = child
				
	if left_ctrl == null:
		_fail(6, "Left XRController3D with tracker='left_hand' missing.", instance)
		return
	print("PASS [5a/6]: Verified LeftController found (tracker=", left_ctrl.tracker, ")")
	
	if right_ctrl == null:
		_fail(7, "Right XRController3D with tracker='right_hand' missing.", instance)
		return
	print("PASS [5b/6]: Verified RightController found (tracker=", right_ctrl.tracker, ")")
	
	# 7. Assert XRServer OpenXR interface is available
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface == null:
		_fail(8, "XRServer OpenXR interface is null.", instance)
		return
	print("PASS [6/6]: Verified OpenXR interface: ", xr_interface.get_name(), " (initialized=", xr_interface.is_initialized(), ")")
	
	# Cleanup memory
	instance.free()
	
	print("========================================")
	print("ALL CI VALIDATION CHECKS PASSED (EXIT 0)")
	print("========================================")
	get_tree().quit(0)
