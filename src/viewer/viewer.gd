extends Node3D
## Object viewer: pick an object from the catalog, look at it fullscreen, orbit, pan and zoom.
##
## Options (command line after `--` as --key=value, or URL query on the web):
##   obj=<id>                 open this object
##   shots=<id,id|all>        screenshot mode (web): shows each object from `views`, prints
##   views=hero,front,…       "SHOT <id>__<view>" and waits until the page sets window.__shot
##   test=1                   runs the headless tests in tests/viewer_tests.gd

const VIEWS := {
	"hero": [35.0, 14.0, 1.0], "front": [0.0, 6.0, 1.0], "side": [90.0, 4.0, 1.0],
	"back": [205.0, 18.0, 1.0], "top": [30.0, 62.0, 1.0], "face": [15.0, 8.0, 0.55],
}

var stage: Stage
var cam: OrbitCamera
var ui: ViewerUI
var exhibit: Node3D
var current_id := ""
var options := {}


func _ready() -> void:
	options = _read_options()
	stage = Stage.new()
	add_child(stage)
	cam = OrbitCamera.new()
	add_child(cam)
	cam.current = true
	exhibit = Node3D.new()
	exhibit.name = "Exhibit"
	add_child(exhibit)
	ui = ViewerUI.new()
	add_child(ui)
	ui.set_entries(Catalog.entries())
	ui.selected.connect(select_object)
	ui.fullscreen_toggled.connect(toggle_fullscreen)
	ui.reset_pressed.connect(cam.reset_view)
	ui.rotate_toggled.connect(func(on: bool) -> void: cam.auto_rotate = on)
	get_viewport().size_changed.connect(func() -> void: _frame(true))

	if options.has("test"):
		var tests: Node = load("res://tests/viewer_tests.gd").new()
		add_child(tests)
		tests.run(self)
	elif options.has("shots"):
		_run_shots()
	else:
		var first: String = options.get("obj", Catalog.entries()[0].id)
		show_object(first)
		cam.snap()


## Shows an object picked by the user: a hint first, since some objects take a moment to build.
func select_object(id: String) -> void:
	ui.loading_label.visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	show_object(id)
	ui.loading_label.visible = false


## Replaces the shown object.
func show_object(id: String) -> void:
	var entry := Catalog.find(id)
	if entry.is_empty():
		push_warning("unknown object: " + id)
		return
	for c in exhibit.get_children():
		exhibit.remove_child(c)
		c.queue_free()
	var obj := Catalog.instantiate(entry)
	exhibit.add_child(obj)
	current_id = id
	_frame(false)
	ui.select(id)
	ui.set_info(entry.name, "%s · %s\n%d Dreiecke" % [entry.category, entry.get("info", ""),
			triangle_count(obj)])


func current_aabb() -> AABB:
	return Catalog.bounds(exhibit)


func _frame(keep_angles: bool) -> void:
	if current_id == "":
		return
	cam.left_inset = ui.panel.offset_right + 8.0 if ui.panel.visible else 0.0
	var aabb := current_aabb()
	stage.fit(aabb)
	cam.frame(aabb, keep_angles)


func toggle_fullscreen() -> void:
	var on := not ui.fullscreen
	ui.set_fullscreen(on)
	_frame(true)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on
				else DisplayServer.WINDOW_MODE_WINDOWED)


static func triangle_count(node: Node) -> int:
	var n := 0
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (mi as MeshInstance3D).mesh
		for s in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(s)
			var idx = arr[Mesh.ARRAY_INDEX]
			n += (idx.size() if idx != null else arr[Mesh.ARRAY_VERTEX].size()) / 3
	return n


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_F:
			toggle_fullscreen()
		KEY_ESCAPE:
			if ui.fullscreen:
				toggle_fullscreen()
		KEY_R:
			cam.reset_view()
		KEY_SPACE:
			cam.auto_rotate = not cam.auto_rotate
			ui.rotate_button.set_pressed_no_signal(cam.auto_rotate)
		KEY_PAGEDOWN, KEY_N:
			select_object(ui.neighbour(current_id, 1))
		KEY_PAGEUP, KEY_P:
			select_object(ui.neighbour(current_id, -1))
		_:
			return
	get_viewport().set_input_as_handled()


func _read_options() -> Dictionary:
	var out := {}
	var args := OS.get_cmdline_user_args()
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("window.location.search")
		if q is String and q.length() > 1:
			args = PackedStringArray(Array((q as String).substr(1).split("&")))
	for a in args:
		var kv := a.trim_prefix("--").split("=", true, 1)
		out[kv[0]] = kv[1].uri_decode() if kv.size() > 1 else "1"
	return out


## Screenshot mode for the web export: see the header comment.
func _run_shots() -> void:
	ui.set_overlay_visible(false)
	cam.left_inset = 0.0
	var ids: Array = []
	if options.shots == "all":
		for e in Catalog.entries():
			ids.append(e.id)
	else:
		ids = Array(String(options.shots).split(","))
	var views: Array = Array(String(options.get("views", "hero")).split(","))
	for id in ids:
		show_object(id)
		for v in views:
			if v.begins_with("c:"):   # custom: c:yaw:pitch:zoom:tx:ty:tz (target relative to the centre)
				var f := Array(v.split(":")).slice(1).map(func(x: String) -> float: return x.to_float())
				cam.set_view(f[0], f[1], f[2])
				if f.size() >= 6:
					cam.offset_target(Vector3(f[3], f[4], f[5]))
			else:
				var p: Array = VIEWS.get(v, VIEWS.hero)
				cam.set_view(p[0], p[1], p[2])
			cam.snap()
			for i in 6:
				await get_tree().process_frame
			var label := "%s__%s" % [id, v.replace(":", "_")]
			print("SHOT " + label)
			var t0 := Time.get_ticks_msec()
			while Time.get_ticks_msec() - t0 < 60000:
				await get_tree().process_frame
				if OS.has_feature("web") and JavaScriptBridge.eval("window.__shot || ''") == label:
					break
	print("SHOTS DONE")
