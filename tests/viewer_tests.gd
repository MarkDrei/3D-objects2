extends Node
## Headless tests for the viewer and the objects. Started by `scripts/test.sh` via --test=1.
## UI tests use real input events (mouse, keys, touch) through Input.parse_input_event.
## Prints "TEST ok <name>" / "TEST FAIL <name>: <reason>" and quits with the failure count.

var viewer: Node
var _failures := 0
var _passed := 0
var _current := ""
var _failed_current := false

## Plausible heights per category (metres).
const HEIGHTS := {"Tiere": Vector2(0.2, 1.2), "Fahrzeuge": Vector2(1.0, 3.5), "Menschen": Vector2(0.7, 2.3)}


func run(v: Node) -> void:
	viewer = v
	get_tree().root.size = Vector2i(1280, 720)   # headless windows are 64x64 otherwise
	await _frames(3)
	var only := String(viewer.options.get("only", ""))
	for m in get_method_list():
		var name: String = m.name
		if not name.begins_with("test_") or (only != "" and name != only):
			continue
		_current = name
		_failed_current = false
		viewer.show_object(Catalog.entries()[0].id)
		viewer.ui.set_fullscreen(false)
		await _frames(2)
		await call(name)
		if _failed_current:
			_failures += 1
		else:
			_passed += 1
			print("TEST ok ", name)
	print("TESTS DONE %d passed, %d failed" % [_passed, _failures])
	get_tree().quit(_failures)


func check(cond: bool, msg: String) -> void:
	if not cond and not _failed_current:
		_failed_current = true
		print("TEST FAIL ", _current, ": ", msg)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _mouse_button(pos: Vector2, button: MouseButton, pressed: bool, shift := false) -> void:
	var e := InputEventMouseButton.new()
	e.position = pos
	e.global_position = pos
	e.button_index = button
	e.pressed = pressed
	e.shift_pressed = shift
	if pressed and button <= MOUSE_BUTTON_MIDDLE:
		e.button_mask = 1 << (button - 1)
	Input.parse_input_event(e)


func _mouse_move(pos: Vector2, rel: Vector2, mask: int) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	e.relative = rel
	e.button_mask = mask
	Input.parse_input_event(e)


func _click(pos: Vector2) -> void:
	_mouse_move(pos, Vector2.ZERO, 0)
	_mouse_button(pos, MOUSE_BUTTON_LEFT, true)
	await _frames(1)
	_mouse_button(pos, MOUSE_BUTTON_LEFT, false)
	await _frames(2)


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = pressed
		Input.parse_input_event(e)
		await _frames(1)


func _view_center() -> Vector2:
	return Vector2(800, 380)   # right of the object panel


# --- Objects ---------------------------------------------------------------------------------

func test_every_object_builds_and_stands_on_the_ground() -> void:
	for e in Catalog.entries():
		viewer.show_object(e.id)
		await _frames(1)
		var meshes: Array = viewer.exhibit.find_children("*", "MeshInstance3D", true, false)
		check(meshes.size() > 0, "%s has no meshes" % e.id)
		var box: AABB = viewer.current_aabb()
		check(absf(box.position.y) < 0.03, "%s does not stand on the ground (min y %.3f)" % [e.id, box.position.y])
		var h: Vector2 = HEIGHTS[e.category]
		check(box.size.y > h.x and box.size.y < h.y, "%s has an odd height %.2f m" % [e.id, box.size.y])
		var tris: int = viewer.triangle_count(viewer.exhibit)
		check(tris < 400000, "%s has too many triangles (%d)" % [e.id, tris])


func test_objects_can_be_used_without_the_viewer() -> void:
	var bear := TeddyBear.new()
	bear.style = 2
	add_child(bear)
	await _frames(1)
	check(bear.find_children("*", "MeshInstance3D", true, false).size() > 10, "TeddyBear.new() built nothing")
	var car := Sedan.new()
	car.variant = "police"
	add_child(car)
	await _frames(1)
	check(Catalog.bounds(car).size.z > 4.0, "Sedan.new() is not car-sized")
	bear.queue_free()
	car.queue_free()


# --- Viewer UI (real input) -----------------------------------------------------------------

func test_click_on_list_item_shows_object() -> void:
	var id := "sports_car"
	var rect: Rect2 = viewer.ui.item_rect(id)
	await _click(rect.get_center())
	await _frames(3)
	check(viewer.current_id == id, "clicked %s but shows %s" % [id, viewer.current_id])


func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	var t := InputEventScreenTouch.new()
	t.index = index
	t.position = pos
	t.pressed = pressed
	Input.parse_input_event(t)


func test_tap_on_list_item_shows_object() -> void:
	var id := "bunny_1"
	var pos: Vector2 = viewer.ui.item_rect(id).get_center()
	_touch(0, pos, true)
	await _frames(1)
	_touch(0, pos, false)
	await _frames(5)
	check(viewer.current_id == id, "tapped %s but shows %s" % [id, viewer.current_id])


func test_one_finger_drag_orbits_once() -> void:
	var cam: OrbitCamera = viewer.cam
	var yaw0 := cam.goal_yaw()
	var p := _view_center()
	_touch(0, p, true)
	await _frames(1)
	for i in 5:
		p += Vector2(-20, 0)
		var d := InputEventScreenDrag.new()
		d.index = 0
		d.position = p
		d.relative = Vector2(-20, 0)
		Input.parse_input_event(d)
		await _frames(1)
	_touch(0, p, false)
	await _frames(2)
	var turned := cam.goal_yaw() - yaw0
	# 100 px at 0.008 rad/px; twice that would mean the emulated mouse events were used as well.
	check(turned > 0.6 and turned < 1.0, "one-finger drag turned %.2f rad instead of 0.8" % turned)


func test_page_keys_step_through_objects() -> void:
	var first: String = viewer.current_id
	await _key(KEY_PAGEDOWN)
	await _frames(3)
	var second: String = viewer.current_id
	check(second != first, "Page Down did not change the object")
	await _key(KEY_PAGEUP)
	await _frames(3)
	check(viewer.current_id == first, "Page Up did not go back")


func test_left_drag_orbits() -> void:
	var cam: OrbitCamera = viewer.cam
	var yaw0 := cam.goal_yaw()
	var p := _view_center()
	_mouse_move(p, Vector2.ZERO, 0)
	_mouse_button(p, MOUSE_BUTTON_LEFT, true)
	for i in 5:
		p += Vector2(-20, 0)
		_mouse_move(p, Vector2(-20, 0), MOUSE_BUTTON_MASK_LEFT)
		await _frames(1)
	_mouse_button(p, MOUSE_BUTTON_LEFT, false)
	await _frames(2)
	check(cam.goal_yaw() > yaw0 + 0.5, "dragging left did not orbit (yaw %.2f -> %.2f)" % [yaw0, cam.goal_yaw()])


func test_wheel_zooms() -> void:
	var cam: OrbitCamera = viewer.cam
	var d0 := cam.goal_distance()
	for i in 3:
		_mouse_button(_view_center(), MOUSE_BUTTON_WHEEL_UP, true)
		_mouse_button(_view_center(), MOUSE_BUTTON_WHEEL_UP, false)
		await _frames(1)
	check(cam.goal_distance() < d0 * 0.8, "wheel up did not zoom in")
	for i in 6:
		_mouse_button(_view_center(), MOUSE_BUTTON_WHEEL_DOWN, true)
		_mouse_button(_view_center(), MOUSE_BUTTON_WHEEL_DOWN, false)
		await _frames(1)
	check(cam.goal_distance() > d0, "wheel down did not zoom out")


func test_right_drag_pans() -> void:
	var cam: OrbitCamera = viewer.cam
	var t0 := cam.goal_target()
	var p := _view_center()
	_mouse_button(p, MOUSE_BUTTON_RIGHT, true)
	for i in 4:
		p += Vector2(15, 10)
		_mouse_move(p, Vector2(15, 10), MOUSE_BUTTON_MASK_RIGHT)
		await _frames(1)
	_mouse_button(p, MOUSE_BUTTON_RIGHT, false)
	await _frames(1)
	check(cam.goal_target().distance_to(t0) > 0.01, "right drag did not pan")


func test_pinch_zooms_on_touch() -> void:
	var cam: OrbitCamera = viewer.cam
	var d0 := cam.goal_distance()
	var a := Vector2(760, 380)
	var b := Vector2(840, 380)
	for i in 2:
		var t := InputEventScreenTouch.new()
		t.index = i
		t.position = [a, b][i]
		t.pressed = true
		Input.parse_input_event(t)
	await _frames(1)
	for k in 5:
		var d := InputEventScreenDrag.new()
		d.index = 1
		b += Vector2(30, 0)
		d.position = b
		d.relative = Vector2(30, 0)
		Input.parse_input_event(d)
		await _frames(1)
	for i in 2:
		var t := InputEventScreenTouch.new()
		t.index = i
		t.position = [a, b][i]
		t.pressed = false
		Input.parse_input_event(t)
	await _frames(1)
	check(cam.goal_distance() < d0 * 0.7, "spreading two fingers did not zoom in (%.2f -> %.2f)" % [d0, cam.goal_distance()])


func test_fullscreen_with_key_and_buttons() -> void:
	var ui: ViewerUI = viewer.ui
	await _key(KEY_F)
	check(not ui.panel.visible, "F did not hide the object list")
	await _key(KEY_ESCAPE)
	check(ui.panel.visible, "Esc did not bring the object list back")
	var fs: Button = ui.buttons.get_node("FullscreenButton")
	await _click(fs.get_global_rect().get_center())
	check(ui.fullscreen and not ui.panel.visible, "the Vollbild button did not switch to fullscreen")
	await _click(ui.back_button.get_global_rect().get_center())
	check(not ui.fullscreen and ui.panel.visible, "the Zurück button did not leave fullscreen")


func test_drag_on_the_list_does_not_orbit() -> void:
	var cam: OrbitCamera = viewer.cam
	var yaw0 := cam.goal_yaw()
	var p := Vector2(140, 600)
	_mouse_button(p, MOUSE_BUTTON_LEFT, true)
	_mouse_move(p + Vector2(60, 0), Vector2(60, 0), MOUSE_BUTTON_MASK_LEFT)
	await _frames(1)
	_mouse_button(p + Vector2(60, 0), MOUSE_BUTTON_LEFT, false)
	await _frames(1)
	check(is_equal_approx(cam.goal_yaw(), yaw0), "a drag starting on the panel orbited the camera")
