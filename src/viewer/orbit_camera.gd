class_name OrbitCamera
extends Camera3D
## Orbits around a target point. Mouse: left drag rotates, right/middle drag (or Shift + left)
## pans, wheel zooms. Touch: one finger rotates, two fingers pinch-zoom and pan.
## Keyboard: W/A/S/D orbit, Q/E zoom. Movements are smoothed.

const DEFAULT_YAW := 35.0
const DEFAULT_PITCH := 14.0

var yaw := deg_to_rad(DEFAULT_YAW)     ## around Y; 0 = looking at the object's front (+Z)
var pitch := deg_to_rad(DEFAULT_PITCH)
var dist := 5.0
var target := Vector3.ZERO
var auto_rotate := false
## Screen pixels on the left covered by UI; the object is framed and centred in the rest.
var left_inset := 0.0

var _goal_yaw := yaw
var _goal_pitch := pitch
var _goal_dist := dist
var _goal_target := target
var _min_dist := 0.5
var _max_dist := 50.0
var _radius := 1.0
var _aabb := AABB(Vector3.ZERO, Vector3.ONE)
var _home_target := Vector3.ZERO
var _home_dist := 5.0
var _rotating := false
var _panning := false
var _touches := {}       # index -> position


func _ready() -> void:
	fov = 35.0
	_apply()


## Frames a bounding box; keep_angles keeps the current viewing direction.
func frame(aabb: AABB, keep_angles := false) -> void:
	_aabb = aabb
	_radius = maxf(aabb.size.length() / 2.0, 0.05)
	_home_target = aabb.get_center()
	_min_dist = _radius * 0.35
	_max_dist = _radius * 10.0
	near = maxf(_radius * 0.01, 0.005)
	far = _radius * 400.0
	if not keep_angles:
		_goal_yaw = deg_to_rad(DEFAULT_YAW)
		_goal_pitch = deg_to_rad(DEFAULT_PITCH)
	_goal_target = _home_target
	_home_dist = fit_distance(_goal_yaw, _goal_pitch)
	_goal_dist = _home_dist


## Smallest distance at which the whole box is visible from this direction, with a margin.
func fit_distance(at_yaw: float, at_pitch: float, margin := 0.98) -> float:
	var aspect := 16.0 / 9.0
	var vp := get_viewport()
	if vp:
		var s := vp.get_visible_rect().size
		aspect = (s.x - left_inset) / maxf(s.y, 1.0)
	var tan_v := tan(deg_to_rad(fov) / 2.0)
	var tan_h := tan_v * aspect
	var back := Vector3(sin(at_yaw) * cos(at_pitch), sin(at_pitch), cos(at_yaw) * cos(at_pitch))
	var right := Vector3.UP.cross(back).normalized()
	var up := back.cross(right)
	var d := 0.0
	for i in 8:
		var c := _aabb.get_endpoint(i) - _home_target
		var z := c.dot(back)
		d = maxf(d, z + absf(c.dot(right)) * margin / tan_h)
		d = maxf(d, z + absf(c.dot(up)) * margin / tan_v)
	return maxf(d, _radius * 0.5)


## Jumps to the goal immediately (no smoothing).
func snap() -> void:
	yaw = _goal_yaw
	pitch = _goal_pitch
	dist = _goal_dist
	target = _goal_target
	_apply()


func set_view(yaw_deg: float, pitch_deg: float, zoom := 1.0) -> void:
	_goal_yaw = deg_to_rad(yaw_deg)
	_goal_pitch = deg_to_rad(pitch_deg)
	_goal_dist = fit_distance(_goal_yaw, _goal_pitch) * zoom
	_goal_target = _home_target


func offset_target(offset: Vector3) -> void:
	_goal_target = _home_target + offset


func reset_view() -> void:
	set_view(DEFAULT_YAW, DEFAULT_PITCH)


func zoom_by(factor: float) -> void:
	_goal_dist = clampf(_goal_dist * factor, _min_dist, _max_dist)


func rotate_by(dyaw: float, dpitch: float) -> void:
	_goal_yaw += dyaw
	_goal_pitch = clampf(_goal_pitch + dpitch, deg_to_rad(-5.0), deg_to_rad(88.0))


func pan_by(pixels: Vector2) -> void:
	var h := get_viewport().get_visible_rect().size.y
	var scale_m := 2.0 * _goal_dist * tan(deg_to_rad(fov) / 2.0) / maxf(h, 1.0)
	var b := global_transform.basis
	_goal_target += (-b.x * pixels.x + b.y * pixels.y) * scale_m
	_goal_target = _home_target + (_goal_target - _home_target).limit_length(_radius * 3.0)


func goal_distance() -> float:
	return _goal_dist


func goal_target() -> Vector3:
	return _goal_target


func goal_yaw() -> float:
	return _goal_yaw


func _process(delta: float) -> void:
	var key_yaw := float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
	var key_pitch := float(Input.is_physical_key_pressed(KEY_W)) - float(Input.is_physical_key_pressed(KEY_S))
	var key_zoom := float(Input.is_physical_key_pressed(KEY_E)) - float(Input.is_physical_key_pressed(KEY_Q))
	if key_yaw != 0.0 or key_pitch != 0.0:
		rotate_by(key_yaw * 1.6 * delta, key_pitch * 1.0 * delta)
	if key_zoom != 0.0:
		zoom_by(1.0 - key_zoom * 1.5 * delta)
	if auto_rotate and not _rotating and _touches.is_empty():
		_goal_yaw += 0.35 * delta
	var k := 1.0 - exp(-14.0 * delta)
	yaw = lerpf(yaw, _goal_yaw, k)
	pitch = lerpf(pitch, _goal_pitch, k)
	dist = lerpf(dist, _goal_dist, k)
	target = target.lerp(_goal_target, k)
	_apply()


func _apply() -> void:
	var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	position = target + dir * dist
	look_at(target, Vector3.UP)
	var vp := get_viewport()
	if vp:
		var h := maxf(vp.get_visible_rect().size.y, 1.0)
		h_offset = -left_inset / 2.0 / h * 2.0 * dist * tan(deg_to_rad(fov) / 2.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_LEFT:
				_rotating = mb.pressed and not mb.shift_pressed
				_panning = mb.pressed and mb.shift_pressed
			MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
				_panning = mb.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if mb.pressed:
					zoom_by(0.88)
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed:
					zoom_by(1.0 / 0.88)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _rotating:
			rotate_by(-mm.relative.x * 0.008, mm.relative.y * 0.006)
			get_viewport().set_input_as_handled()
		elif _panning:
			pan_by(mm.relative)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_touches[st.index] = st.position
		else:
			_touches.erase(st.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if not _touches.has(sd.index):
			return
		if _touches.size() == 1:
			rotate_by(-sd.relative.x * 0.008, sd.relative.y * 0.006)
		elif _touches.size() == 2:
			var other: Vector2 = _touches[_touches.keys().filter(func(i): return i != sd.index)[0]]
			var before: float = (_touches[sd.index] as Vector2).distance_to(other)
			var after := sd.position.distance_to(other)
			if before > 1.0 and after > 1.0:
				zoom_by(before / after)
			pan_by(sd.relative / 2.0)
		_touches[sd.index] = sd.position
		get_viewport().set_input_as_handled()
	elif event is InputEventMagnifyGesture:
		zoom_by(1.0 / (event as InputEventMagnifyGesture).factor)
	elif event is InputEventPanGesture:
		zoom_by(1.0 + (event as InputEventPanGesture).delta.y * 0.05)
