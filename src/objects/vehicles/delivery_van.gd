class_name DeliveryVan
extends Node3D
## Panel van with a high roof, a short nose and a courier livery on the cargo box.

@export var color := Color(0.95, 0.95, 0.93)
@export var stripe := Color(0.95, 0.42, 0.05)


func _ready() -> void:
	var b := Builder.new(self)
	var spec := {
		length = 5.4, width = 2.0, axles = [1.8, -1.6], wheel_r = 0.36, wheel_w = 0.25, track = 0.84,
		arch_gap = 0.05, sill = 0.4, e = 0.2, tumble = 0.96, round_front = 0.25, round_back = 0.06,
		top = [Vector2(-2.7, 1.02), Vector2(1.9, 1.06), Vector2(2.4, 0.98), Vector2(2.7, 0.78)],
		plan = [Vector2(-2.7, 1.0), Vector2(1.6, 1.0), Vector2(2.7, 0.94)],
		cabin = {z0 = -2.66, z1 = 2.25, belt = 1.06, half_width = 0.98, e = 0.18, tumble = 0.93, rings = 110,
			roof = [Vector2(-2.66, 1.0), Vector2(-2.62, 2.5), Vector2(1.1, 2.55), Vector2(1.45, 2.42),
				Vector2(2.15, 1.25), Vector2(2.25, 1.0)]},
	}
	var paint := Mats.paint(color, 0.3, 0.1)
	var trim := Mats.plastic(Color(0.12, 0.12, 0.13), 0.65)
	CarKit.body(b, spec, [paint])
	CarKit.cabin(b, spec, paint)
	CarKit.glazing(b, spec, [[1.2, 1.98]], true, false, {top_cut = 0.6, end_top_gap = 0.6})
	# Rear doors: two windows and the split line.
	for side: float in [1.0, -1.0]:
		var w := CarKit.quad(Vector2(side * 0.08, 1.75), Vector2(side * 0.78, 1.75), Vector2(side * 0.78, 2.3),
				Vector2(side * 0.08, 2.3), 0.04)
		CarKit.decal(b, spec, true, "back", w, Mats.glass(), 0.004, 0.012)
	b.part(MeshGen.rounded_box(Vector3(0.015, 1.4, 0.01), 0.5), trim, Vector3(0, 1.75, -2.665))
	# Livery: orange band and lettering on both sides of the cargo box.
	var band := CarKit.quad(Vector2(-2.5, 1.38), Vector2(1.0, 1.38), Vector2(1.0, 1.56), Vector2(-2.5, 1.56), 0.02)
	CarKit.decal(b, spec, true, "left", band, Mats.paint(stripe, 0.3, 0.1))
	var x := CarKit.side_x(spec, 1.0, 0.0)
	CarKit.side_text(b, "BLITZ-KURIER", CarKit.cabin_side_x(spec, 2.0, -0.75) + 0.006, 2.0, -0.75,
			Color(0.1, 0.12, 0.2), 0.0045)
	CarKit.side_text(b, "schnell · sicher · freundlich", CarKit.cabin_side_x(spec, 1.72, -0.75) + 0.006, 1.72,
			-0.75, Color(0.35, 0.35, 0.38), 0.0018)
	# Sliding door rail and handles.
	for side: float in [1.0, -1.0]:
		b.part(MeshGen.rounded_box(Vector3(0.03, 0.04, 1.6), 0.5), trim, Vector3(side * CarKit.cabin_side_x(spec, 1.62, -0.6), 1.62, -0.6))
	CarKit.handles(b, x + 0.005, 0.98, [1.2, 0.35])
	# Front: dark grille, bumpers, lights.
	var front := CarKit.end_z(spec, 0.0, 0.75, true)
	b.part(MeshGen.rounded_box(Vector3(1.1, 0.24, 0.05), 0.4), trim, Vector3(0, 0.8, front - 0.01))
	b.part(MeshGen.rounded_box(Vector3(1.95, 0.24, 0.22), 0.5), trim, Vector3(0, 0.5, 2.62))
	b.part(MeshGen.rounded_box(Vector3(1.95, 0.24, 0.16), 0.5), trim, Vector3(0, 0.5, -2.72))
	CarKit.head_lights(b, spec, 0.72, 0.86, Vector3(0.3, 0.16, 0.08))
	CarKit.tail_lights(b, spec, 0.88, 1.25, Vector3(0.1, 0.4, 0.06), -2.66)
	CarKit.plate(b, Vector3(0, 0.52, 2.74))
	CarKit.plate(b, Vector3(0, 0.52, -2.81), true)
	CarKit.mirrors(b, Vector3(1.02, 1.5, 1.85), trim)
	CarKit.arch_liners(b, spec)
	CarKit.wheels(b, spec, "steel")
