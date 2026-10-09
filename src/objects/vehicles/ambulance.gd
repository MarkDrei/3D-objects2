class_name Ambulance
extends Node3D
## A German-style ambulance (Rettungswagen): van cab with a box body, luminous red stripes,
## blue lights and lettering. About 6 m long.

const RED := Color(1.0, 0.18, 0.08)

var spec := {
	length = 6.0, width = 2.0, axles = [2.15, -1.55], wheel_r = 0.37, wheel_w = 0.24, track = 0.86,
	arch_gap = 0.05, sill = 0.42, e = 0.25, tumble = 0.94, round_front = 0.25, round_back = 0.1,
	top = [Vector2(-3.0, 1.1), Vector2(1.6, 1.1), Vector2(2.2, 1.24), Vector2(2.75, 1.1), Vector2(3.0, 0.88)],
	plan = [Vector2(-3.0, 1.0), Vector2(2.4, 1.0), Vector2(3.0, 0.93)],
	cabin = {z0 = 0.9, z1 = 2.3, belt = 1.24, half_width = 0.98, tumble = 0.88, e = 0.3,
		roof = [Vector2(0.9, 1.16), Vector2(1.05, 2.32), Vector2(1.55, 2.36), Vector2(2.3, 1.16)]},
}

const BOX_SIZE := Vector3(2.16, 1.95, 4.3)
const BOX_POS := Vector3(0, 0.98 + 0.975, -0.82)
const BOX_E := 0.1


func _ready() -> void:
	if get_child_count() == 0:
		build()


func build() -> void:
	var b := Builder.new(self)
	var white := Mats.paint(Color(0.96, 0.96, 0.95), 0.22, 0.05)
	var red := Mats.paint(RED, 0.3, 0.0)
	var blue := Mats.paint(Color(0.05, 0.25, 0.75), 0.3, 0.0)
	var trim := Mats.plastic(Color(0.07, 0.07, 0.08), 0.45)
	var glass := Mats.glass()
	CarKit.arch_liners(b, spec)
	CarKit.body(b, spec, [white])
	CarKit.cabin(b, spec, white)
	CarKit.wheels(b, spec, "steel")
	b.part(MeshGen.rounded_box(BOX_SIZE, BOX_E), white, BOX_POS)

	# Cab windows.
	CarKit.decal(b, spec, true, "left", CarKit.side_window(spec, 1.0, 2.25, 0.09, 0.0, 0.05), glass, 0.004, 0.025)
	CarKit.decal(b, spec, true, "front", CarKit.end_window(spec, 0.07, 0.05, 0.08), glass, 0.004, 0.025)
	CarKit.mirrors(b, Vector3(CarKit.side_x(spec, 1.2, 2.1), 1.5, 2.1), trim)

	# Box: red band, thin second stripe, window, lettering, star of life.
	var band_y := Vector2(1.18, 1.5)
	_box_decal(b, "left", CarKit.quad(Vector2(-2.97, band_y.x), Vector2(1.29, band_y.x), Vector2(1.29, band_y.y),
			Vector2(-2.97, band_y.y), 0.0), red, 0.006)
	_box_decal(b, "left", CarKit.quad(Vector2(-2.97, 1.56), Vector2(1.29, 1.56), Vector2(1.29, 1.62),
			Vector2(-2.97, 1.62), 0.0), red, 0.006)
	CarKit.decal(b, spec, false, "left", CarKit.quad(Vector2(1.35, 0.78), Vector2(2.85, 0.78), Vector2(2.85, 1.02),
			Vector2(1.35, 1.02), 0.0), red, 0.003)
	_box_decal(b, "left", CarKit.quad(Vector2(-0.35, 2.15), Vector2(0.75, 2.15), Vector2(0.75, 2.6),
			Vector2(-0.35, 2.6), 0.06), Mats.glass(Color(0.75, 0.78, 0.8)), 0.006)
	_box_decal(b, "front", _star_of_life(Vector2(0, 2.45), 0.18), blue)
	for side: float in [1.0, -1.0]:
		var label := Label3D.new()
		label.text = "RETTUNGSDIENST"
		label.font_size = 128
		label.pixel_size = 0.0028
		label.modulate = Color(0.05, 0.2, 0.6)
		label.outline_size = 0
		label.double_sided = false
		label.position = Vector3(side * (BOX_SIZE.x / 2.0 + 0.008), 1.85, -0.75)
		label.rotation_degrees = Vector3(0, 90 * side, 0)
		b.node(label)
		var star := _box_mesh("left", _star_of_life(Vector2(-2.3, 2.4), 0.22), 0.006)
		if star:
			b.part(star, blue, Vector3.ZERO, Vector3.ZERO, Vector3(side, 1, 1))

	# Rear doors with windows and warning chevrons.
	_box_decal(b, "back", CarKit.quad(Vector2(-0.006, 0.95), Vector2(0.006, 0.95), Vector2(0.006, 2.85),
			Vector2(-0.006, 2.85), 0.0), trim)
	for side: float in [1.0, -1.0]:
		_box_decal(b, "back", CarKit.quad(Vector2(side * 0.12, 2.0), Vector2(side * 0.85, 2.0), Vector2(side * 0.85, 2.6),
				Vector2(side * 0.12, 2.6), 0.05), Mats.glass(Color(0.7, 0.73, 0.76)), 0.006)
		for i in 4:
			var x0 := side * (0.12 + i * 0.24)
			var chev := PackedVector2Array([Vector2(x0, 1.1), Vector2(x0 + side * 0.12, 1.1),
					Vector2(x0 + side * 0.24, 1.5), Vector2(x0 + side * 0.12, 1.5)])
			_box_decal(b, "back", CarKit.ccw(chev), red)

	# Blue lights: bar on the cab, lamps at the box corners.
	var bar_y := 2.38
	b.part(MeshGen.rounded_box(Vector3(1.5, 0.06, 0.3), 0.3), trim, Vector3(0, bar_y, 1.5))
	for side: float in [1.0, -1.0]:
		_blue_light(b, Vector3(side * 0.42, bar_y + 0.07, 1.5), Vector3(0.6, 0.1, 0.26))
		_blue_light(b, Vector3(side * 0.85, BOX_POS.y + BOX_SIZE.y / 2.0 + 0.04, BOX_POS.z - BOX_SIZE.z / 2.0 + 0.15),
				Vector3(0.18, 0.1, 0.18))
		_blue_light(b, Vector3(side * 0.85, BOX_POS.y + BOX_SIZE.y / 2.0 + 0.04, BOX_POS.z + BOX_SIZE.z / 2.0 - 0.15),
				Vector3(0.18, 0.1, 0.18))
		var tail := CarKit.quad(Vector2(side * 0.88, 0.62), Vector2(side * 1.02, 0.62), Vector2(side * 1.02, 1.05),
				Vector2(side * 0.88, 1.05), 0.02)
		_box_decal(b, "back", tail, Mats.glow(Color(0.9, 0.05, 0.05), 1.3), 0.006)

	# Front: headlights, grille, bumper, plate.
	var head := CarKit.quad(Vector2(0.48, 0.92), Vector2(0.86, 0.9), Vector2(0.86, 1.04), Vector2(0.5, 1.06), 0.03)
	for poly in [head, CarKit.mirror_x(head)]:
		CarKit.decal(b, spec, false, "front", poly, Mats.chrome(Color(0.3, 0.32, 0.35)), 0.004)
		var inner: Array = Geometry2D.offset_polygon(poly, -0.02)
		CarKit.decal(b, spec, false, "front", inner[0], Mats.glow(Color(1.0, 0.98, 0.92), 2.2), 0.008)
	CarKit.decal(b, spec, false, "front", CarKit.quad(Vector2(-0.4, 0.72), Vector2(0.4, 0.72), Vector2(0.42, 0.98),
			Vector2(-0.42, 0.98), 0.05), trim, 0.004)
	CarKit.decal(b, spec, false, "front", CarKit.quad(Vector2(-1.0, 0.42), Vector2(1.0, 0.42), Vector2(1.0, 0.64),
			Vector2(-1.0, 0.64), 0.04), trim, 0.004)
	CarKit.plate(b, Vector3(0, 0.54, CarKit.end_z(spec, 0, 0.54) + 0.012), false, "HH · RD 112")
	CarKit.plate(b, Vector3(0, 0.62, BOX_POS.z - BOX_SIZE.z / 2.0 - 0.01), true, "HH · RD 112")
	b.part(MeshGen.rounded_box(Vector3(2.0, 0.16, 0.2), 0.3), trim, Vector3(0, 0.5, BOX_POS.z - BOX_SIZE.z / 2.0 + 0.04))


func _blue_light(b: Builder, pos: Vector3, size: Vector3) -> void:
	b.part(MeshGen.rounded_box(size, 0.45), Mats.glow(Color(0.1, 0.35, 1.0), 2.6), pos)
	b.part(MeshGen.rounded_box(size + Vector3(0.03, 0.02, 0.03), 0.45), Mats.clear_glass(Color(0.6, 0.75, 1.0, 0.3)), pos)


func _inside_box(p: Vector3) -> bool:
	var q := (p - BOX_POS) / (BOX_SIZE / 2.0)
	var k := 2.0 / BOX_E
	return pow(absf(q.x), k) + pow(absf(q.y), k) + pow(absf(q.z), k) <= 1.0


func _box_mesh(view: String, outline: PackedVector2Array, lift: float) -> ArrayMesh:
	outline = CarKit.ccw(outline)
	match view:
		"left":
			return MeshGen.decal(_inside_box, outline, Vector3.ZERO, Vector3(0, 0, 1), Vector3(0, 1, 0),
					Vector3(-1, 0, 0), lift, 0.06, 1.2)
		"back":
			return MeshGen.decal(_inside_box, outline, Vector3(0, 0, BOX_POS.z), Vector3(1, 0, 0), Vector3(0, 1, 0),
					Vector3(0, 0, 1), lift, 0.06, BOX_SIZE.z / 2.0 + 0.2)
		_:
			return MeshGen.decal(_inside_box, outline, Vector3(0, 0, BOX_POS.z), Vector3(1, 0, 0), Vector3(0, 1, 0),
					Vector3(0, 0, -1), lift, 0.06, BOX_SIZE.z / 2.0 + 0.2)


func _box_decal(b: Builder, view: String, outline: PackedVector2Array, mat: Material, lift := 0.004) -> void:
	var mesh := _box_mesh(view, outline, lift)
	if mesh == null:
		return
	if view == "left":
		b.mirror_mesh(mesh, mat)
	else:
		b.part(mesh, mat)


## Six-armed star (the "star of life") as one outline.
static func _star_of_life(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var w := r * 0.3
	for i in 6:
		var a := PI / 2.0 + TAU * i / 6.0
		var dir := Vector2(cos(a), sin(a))
		var n := Vector2(-dir.y, dir.x)
		var a_prev := a - TAU / 12.0
		pts.append(c + Vector2(cos(a_prev), sin(a_prev)) * w / sin(PI / 6.0) * 0.5)
		pts.append(c + dir * r - n * w / 2.0)
		pts.append(c + dir * r + n * w / 2.0)
	return pts
