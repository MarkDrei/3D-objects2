class_name Sedan
extends Node3D
## A family car, about 4.6 m long, as sedan or estate (wagon). Variants: "sedan", "taxi"
## (cream paint, roof sign) and "police" (estate in German police livery with light bar).

@export var paint_color := Color(0.12, 0.28, 0.55)
@export_enum("sedan", "taxi", "police") var variant := "sedan"

var spec := {
	length = 4.6, width = 1.8, axles = [1.42, -1.36], wheel_r = 0.33, wheel_w = 0.22, track = 0.78,
	arch_gap = 0.045, sill = 0.3, e = 0.3, tumble = 0.86, round_front = 0.22, round_back = 0.18,
	top = [Vector2(-2.3, 0.78), Vector2(-2.12, 0.95), Vector2(-1.7, 1.0), Vector2(-1.2, 1.0),
		Vector2(0.9, 0.97), Vector2(1.5, 0.9), Vector2(2.1, 0.8), Vector2(2.3, 0.66)],
	plan = [Vector2(-2.3, 0.84), Vector2(-1.9, 0.9), Vector2(1.6, 0.9), Vector2(2.3, 0.82)],
	cabin = {z0 = -1.45, z1 = 1.12, belt = 0.98, half_width = 0.8, tumble = 0.74, e = 0.45,
		roof = [Vector2(-1.45, 0.88), Vector2(-0.75, 1.42), Vector2(0.15, 1.46), Vector2(1.12, 0.88)],
		b_pillar = [-0.12], side_front = 0.95, side_back = -1.12},
}


func _ready() -> void:
	if get_child_count() == 0:
		build()


func build() -> void:
	var taxi := variant == "taxi"
	var police := variant == "police"
	if police:   # estate: long roof, steep tailgate
		spec.top = [Vector2(-2.3, 0.78), Vector2(-2.2, 0.98), Vector2(-1.2, 1.0),
				Vector2(0.9, 0.97), Vector2(1.5, 0.9), Vector2(2.1, 0.8), Vector2(2.3, 0.66)]
		spec.cabin = {z0 = -2.24, z1 = 1.12, belt = 0.98, half_width = 0.8, tumble = 0.76, e = 0.45,
				roof = [Vector2(-2.24, 0.9), Vector2(-2.08, 1.43), Vector2(0.15, 1.46), Vector2(1.12, 0.88)],
				rings = 120}
	var b := Builder.new(self)
	var col := Color(0.98, 0.86, 0.45) if taxi else (Color(0.86, 0.87, 0.89) if police else paint_color)
	var paint := Mats.paint(col)
	var trim := Mats.plastic(Color(0.05, 0.05, 0.06), 0.45)
	var glass := Mats.glass()
	CarKit.arch_liners(b, spec)
	CarKit.body(b, spec, [paint])
	CarKit.cabin(b, spec, paint)
	CarKit.wheels(b, spec, "steel" if taxi else "alloy")

	# Windows with black frames; the B-pillar stays black between them.
	CarKit.decal(b, spec, true, "left", CarKit.side_window(spec, -0.08, 1.0, 0.075), glass, 0.004, 0.025)
	if police:
		CarKit.decal(b, spec, true, "left", CarKit.side_window(spec, -1.25, -0.18, 0.075), glass, 0.004, 0.025)
		CarKit.decal(b, spec, true, "left", CarKit.side_window(spec, -2.1, -1.37, 0.075), glass, 0.004, 0.025)
	else:
		CarKit.decal(b, spec, true, "left", CarKit.side_window(spec, -1.3, -0.18, 0.075), glass, 0.004, 0.025)
	CarKit.decal(b, spec, true, "front", CarKit.end_window(spec, 0.1), glass, 0.004, 0.02)
	CarKit.decal(b, spec, true, "back", CarKit.end_window(spec, 0.09, 0.05, 0.08), glass, 0.004, 0.02)
	CarKit.mirrors(b, Vector3(CarKit.side_x(spec, 0.95, 0.85), 1.02, 0.85), paint)
	CarKit.handles(b, CarKit.side_x(spec, 0.9, 0.25), 0.9, [0.25, -0.75])

	# Headlights, grille, taillights.
	var head := CarKit.quad(Vector2(0.4, 0.66), Vector2(0.82, 0.69), Vector2(0.8, 0.79), Vector2(0.45, 0.77), 0.03)
	for poly in [head, CarKit.mirror_x(head)]:
		CarKit.decal(b, spec, false, "front", poly, Mats.chrome(Color(0.3, 0.32, 0.35)), 0.004)
		var inner: Array = Geometry2D.offset_polygon(poly, -0.025)
		CarKit.decal(b, spec, false, "front", inner[0], Mats.glow(Color(1.0, 0.98, 0.92), 2.2), 0.008)
	CarKit.decal(b, spec, false, "front", CarKit.quad(Vector2(-0.34, 0.5), Vector2(0.34, 0.5), Vector2(0.3, 0.66),
			Vector2(-0.3, 0.66), 0.04), trim, 0.004, 0.025, true, Mats.chrome())
	var tail := CarKit.quad(Vector2(0.4, 0.72), Vector2(0.76, 0.72), Vector2(0.76, 0.84), Vector2(0.4, 0.84), 0.03)
	for poly in [tail, CarKit.mirror_x(tail)]:
		CarKit.decal(b, spec, false, "back", poly, Mats.glow(Color(0.85, 0.04, 0.05), 1.2), 0.004, 0.015)
	# Bumpers and plates.
	CarKit.decal(b, spec, false, "front", CarKit.quad(Vector2(-0.95, 0.3), Vector2(0.95, 0.3), Vector2(0.95, 0.42),
			Vector2(-0.95, 0.42), 0.03), trim, 0.004)
	CarKit.decal(b, spec, false, "back", CarKit.quad(Vector2(-0.95, 0.32), Vector2(0.95, 0.32), Vector2(0.95, 0.46),
			Vector2(-0.95, 0.46), 0.03), trim, 0.004)
	CarKit.plate(b, Vector3(0, 0.44, CarKit.end_z(spec, 0, 0.44) + 0.012))
	CarKit.plate(b, Vector3(0, 0.62, CarKit.end_z(spec, 0, 0.62, false) - 0.012), true)
	if taxi:
		_taxi_sign(b)
	if police:
		_police(b)


## German police livery: blue band along the sides, lettering, blue lights on the roof.
func _police(b: Builder) -> void:
	var blue := Mats.paint(Color(0.05, 0.2, 0.55), 0.3, 0.1)
	var neon := Mats.paint(Color(0.85, 1.0, 0.1), 0.35, 0.0)
	var band := PackedVector2Array([Vector2(-2.25, 0.56), Vector2(2.25, 0.56), Vector2(2.25, 0.8), Vector2(-2.25, 0.8)])
	CarKit.decal(b, spec, false, "left", band, blue, 0.003)
	var stripe := PackedVector2Array([Vector2(-2.25, 0.82), Vector2(2.25, 0.82), Vector2(2.25, 0.86), Vector2(-2.25, 0.86)])
	CarKit.decal(b, spec, false, "left", stripe, neon, 0.003)
	var x := CarKit.side_x(spec, 0.68, 0.2) + 0.02
	CarKit.side_text(b, "POLIZEI", x, 0.68, -0.25, Color(1, 1, 1), 0.003)
	# Hood lettering, readable from the front.
	var hood := Label3D.new()
	hood.text = "POLIZEI"
	hood.font_size = 96
	hood.pixel_size = 0.0028
	hood.modulate = Color(0.05, 0.2, 0.55)
	hood.outline_size = 0
	hood.double_sided = false
	hood.position = Vector3(0, CarKit.top(spec, 1.75) + 0.004, 1.75)
	hood.rotation_degrees = Vector3(-90 + 9, 0, 0)
	b.node(hood)
	# Light bar.
	var bar_y := 1.47
	b.part(MeshGen.rounded_box(Vector3(1.2, 0.05, 0.28), 0.3), Mats.plastic(Color(0.12, 0.12, 0.13), 0.4),
			Vector3(0, bar_y, -0.05))
	for side: float in [1.0, -1.0]:
		b.part(MeshGen.rounded_box(Vector3(0.5, 0.09, 0.24), 0.45), Mats.glow(Color(0.1, 0.35, 1.0), 2.5),
				Vector3(side * 0.3, bar_y + 0.06, -0.05))
		b.part(MeshGen.rounded_box(Vector3(0.53, 0.11, 0.27), 0.45), Mats.clear_glass(Color(0.6, 0.75, 1.0, 0.3)),
				Vector3(side * 0.3, bar_y + 0.06, -0.05))
	b.part(MeshGen.rounded_box(Vector3(0.1, 0.08, 0.2), 0.4), Mats.plastic(Color(0.9, 0.9, 0.9), 0.3),
			Vector3(0, bar_y + 0.05, -0.05))


func _taxi_sign(b: Builder) -> void:
	b.part(MeshGen.rounded_box(Vector3(0.52, 0.16, 0.2), 0.3), Mats.glow(Color(1.0, 0.95, 0.75), 0.6),
			Vector3(0, 1.53, -0.25))
	b.part(MeshGen.rounded_box(Vector3(0.56, 0.03, 0.24), 0.3), Mats.plastic(Color(0.1, 0.1, 0.1)),
			Vector3(0, 1.455, -0.25))
	for side: float in [1.0, -1.0]:
		var label := Label3D.new()
		label.text = "TAXI"
		label.font_size = 64
		label.pixel_size = 0.0022
		label.modulate = Color(0.08, 0.08, 0.08)
		label.outline_size = 0
		label.double_sided = false
		label.position = Vector3(0, 1.53, -0.25 + side * 0.101)
		label.rotation_degrees = Vector3(0, 0 if side > 0 else 180, 0)
		b.node(label)
