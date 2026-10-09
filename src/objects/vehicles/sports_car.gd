class_name SportsCar
extends Node3D
## A low, wide mid-engine sports car with a rear wing, about 4.5 m long.

@export var paint_color := Color(0.78, 0.03, 0.04)

var spec := {
	length = 4.5, width = 1.96, axles = [1.38, -1.3], wheel_r = 0.34, wheel_w = 0.29, track = 0.84,
	arch_gap = 0.03, sill = 0.16, e = 0.28, tumble = 0.8, round_front = 0.3, round_back = 0.16,
	rim_ratio = 0.74, rings = 160,
	top = [Vector2(-2.25, 0.6), Vector2(-2.12, 0.86), Vector2(-1.7, 0.93), Vector2(-0.9, 0.9),
		Vector2(0.55, 0.8), Vector2(1.3, 0.7), Vector2(1.95, 0.56), Vector2(2.25, 0.38)],
	plan = [Vector2(-2.25, 0.9), Vector2(-1.6, 0.98), Vector2(-0.6, 0.94), Vector2(0.2, 0.93),
		Vector2(1.3, 0.97), Vector2(2.25, 0.8)],
	cabin = {z0 = -1.55, z1 = 1.05, belt = 0.8, half_width = 0.72, tumble = 0.6, e = 0.5,
		roof = [Vector2(-1.55, 0.72), Vector2(-0.6, 1.12), Vector2(-0.15, 1.16), Vector2(1.05, 0.72)]},
}


func _ready() -> void:
	if get_child_count() == 0:
		build()


func build() -> void:
	var b := Builder.new(self)
	var paint := Mats.paint(paint_color, 0.18, 0.35)
	var carbon := Mats.plastic(Color(0.04, 0.04, 0.045), 0.3)
	var glass := Mats.glass()
	CarKit.arch_liners(b, spec)
	CarKit.body(b, spec, [paint])
	CarKit.cabin(b, spec, paint)
	CarKit.wheels(b, spec, "sport", Color(1.0, 0.8, 0.1))

	CarKit.decal(b, spec, true, "left", CarKit.side_window(spec, -0.85, 0.95, 0.07, 0.0, 0.06), glass, 0.004, 0.02)
	CarKit.decal(b, spec, true, "front", CarKit.end_window(spec, 0.06, 0.03, 0.05), glass, 0.004, 0.02)
	# Engine cover louvres instead of a rear window.
	for i in 5:
		var z := -1.0 - i * 0.1
		CarKit.decal(b, spec, true, "top", CarKit.quad(Vector2(-0.38, -z - 0.03), Vector2(0.38, -z - 0.03),
				Vector2(0.38, -z + 0.03), Vector2(-0.38, -z + 0.03), 0.02), carbon, 0.003)
	CarKit.mirrors(b, Vector3(CarKit.side_x(spec, 0.8, 0.75), 0.86, 0.72), paint)

	# Side air intakes behind the doors.
	var intake := PackedVector2Array([Vector2(-0.95, 0.42), Vector2(-0.45, 0.48), Vector2(-0.4, 0.74), Vector2(-0.75, 0.72)])
	CarKit.decal(b, spec, false, "left", CarKit.ccw(MeshGen.rounded_polygon(CarKit.ccw(intake), 0.06)), carbon, 0.004)
	# Side skirt.
	CarKit.decal(b, spec, false, "left", CarKit.quad(Vector2(-0.95, 0.17), Vector2(0.95, 0.17), Vector2(0.95, 0.27),
			Vector2(-0.95, 0.25), 0.02), carbon, 0.003)

	# Slim headlights, big lower intakes, splitter.
	var head := CarKit.quad(Vector2(0.42, 0.5), Vector2(0.84, 0.54), Vector2(0.8, 0.6), Vector2(0.48, 0.58), 0.025)
	for poly in [head, CarKit.mirror_x(head)]:
		CarKit.decal(b, spec, false, "front", poly, Mats.plastic(Color(0.08, 0.08, 0.09), 0.2), 0.004)
		var inner: Array = Geometry2D.offset_polygon(poly, -0.015)
		CarKit.decal(b, spec, false, "front", inner[0], Mats.glow(Color(1.0, 0.98, 0.94), 2.5), 0.007)
	for poly in [CarKit.quad(Vector2(0.3, 0.22), Vector2(0.82, 0.22), Vector2(0.78, 0.4), Vector2(0.36, 0.38), 0.04),
			CarKit.mirror_x(CarKit.quad(Vector2(0.3, 0.22), Vector2(0.82, 0.22), Vector2(0.78, 0.4), Vector2(0.36, 0.38), 0.04))]:
		CarKit.decal(b, spec, false, "front", poly, carbon, 0.004)
	CarKit.decal(b, spec, false, "front", CarKit.quad(Vector2(-0.22, 0.24), Vector2(0.22, 0.24), Vector2(0.2, 0.36),
			Vector2(-0.2, 0.36), 0.04), carbon, 0.004)
	b.part(MeshGen.rounded_box(Vector3(1.3, 0.03, 0.2), 0.3), carbon, Vector3(0, 0.15, CarKit.end_z(spec, 0, 0.2) - 0.1))

	# Rear: full-width light strip, diffuser, quad exhaust, wing.
	var strip := CarKit.quad(Vector2(-0.82, 0.74), Vector2(0.82, 0.74), Vector2(0.8, 0.79), Vector2(-0.8, 0.79), 0.02)
	CarKit.decal(b, spec, false, "back", strip, Mats.glow(Color(0.95, 0.05, 0.05), 1.6), 0.004, 0.012)
	CarKit.decal(b, spec, false, "back", CarKit.quad(Vector2(-0.9, 0.17), Vector2(0.9, 0.17), Vector2(0.86, 0.42),
			Vector2(-0.86, 0.42), 0.04), carbon, 0.004)
	var back_z := CarKit.end_z(spec, 0.0, 0.3, false)
	for x in [-0.32, -0.18, 0.18, 0.32]:
		b.part(MeshGen.lathe(PackedVector2Array([Vector2(0.04, -0.06), Vector2(0.045, 0.0), Vector2(0.04, 0.02),
				Vector2(0.03, 0.02), Vector2(0.03, -0.06)]), 24, false), Mats.chrome(), Vector3(x, 0.3, back_z + 0.02),
				Vector3(-90, 0, 0))
		b.blob(Mats.matte(Color(0.02, 0.02, 0.02)), Vector3(x, 0.3, back_z + 0.0), Vector3(0.031, 0.031, 0.01))
	var wing_z := -1.98
	var wing_y := 1.06
	for side: float in [1.0, -1.0]:
		b.part(MeshGen.rounded_box(Vector3(0.03, 0.18, 0.1), 0.3), carbon,
				Vector3(side * 0.5, wing_y - 0.09, wing_z + 0.02), Vector3(-12, 0, 0))
		b.part(MeshGen.rounded_box(Vector3(0.02, 0.1, 0.28), 0.3), carbon, Vector3(side * 0.8, wing_y + 0.01, wing_z))
	var wing := PackedVector2Array([Vector2(-0.14, -0.012), Vector2(0.0, -0.025), Vector2(0.16, -0.01),
			Vector2(0.17, 0.012), Vector2(0.0, 0.025), Vector2(-0.15, 0.01)])
	b.part(MeshGen.extrude(wing, 1.6, 0.004, false), carbon, Vector3(0, wing_y, wing_z), Vector3(8, 90, 0))
	CarKit.plate(b, Vector3(0, 0.5, CarKit.end_z(spec, 0, 0.5, false) - 0.01), true, "M · SR 911")
