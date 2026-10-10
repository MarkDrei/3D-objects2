class_name Pickup
extends Node3D
## Double-cab pickup truck with an open load bed, chrome grille and a tow hitch.

@export var color := Color(0.62, 0.08, 0.07)


func _ready() -> void:
	var b := Builder.new(self)
	var spec := {
		length = 5.3, width = 1.96, axles = [1.68, -1.62], wheel_r = 0.4, wheel_w = 0.28, track = 0.82,
		arch_gap = 0.06, sill = 0.46, e = 0.24, tumble = 0.95, round_front = 0.14, round_back = 0.06,
		top = [Vector2(-2.65, 0.9), Vector2(-0.62, 0.9), Vector2(-0.48, 1.16), Vector2(1.9, 1.16),
			Vector2(2.35, 1.08), Vector2(2.65, 0.9)],
		plan = [Vector2(-2.65, 0.97), Vector2(0.0, 0.98), Vector2(2.65, 0.93)],
		cabin = {z0 = -0.56, z1 = 1.5, belt = 1.16, half_width = 0.9, e = 0.28, tumble = 0.85,
			roof = [Vector2(-0.56, 1.1), Vector2(-0.5, 1.88), Vector2(0.62, 1.9), Vector2(1.42, 1.26),
				Vector2(1.5, 1.1)]},
	}
	var paint := Mats.paint(color)
	var trim := Mats.plastic(Color(0.07, 0.07, 0.08), 0.6)
	CarKit.body(b, spec, [paint])
	CarKit.cabin(b, spec, paint)
	CarKit.glazing(b, spec, [[0.08, 1.32], [-0.44, -0.04]])
	# Load bed: side walls, front wall, tailgate and a dark liner on the floor.
	var bed_z0 := -2.62
	var bed_z1 := -0.58
	var wall_x := 0.88
	for side: float in [1.0, -1.0]:
		b.part(MeshGen.rounded_box(Vector3(0.08, 0.36, bed_z1 - bed_z0), 0.25), paint,
				Vector3(side * wall_x, 1.04, (bed_z0 + bed_z1) / 2.0))
		b.part(MeshGen.rounded_box(Vector3(0.1, 0.03, bed_z1 - bed_z0), 0.5), trim,
				Vector3(side * wall_x, 1.23, (bed_z0 + bed_z1) / 2.0))
	b.part(MeshGen.rounded_box(Vector3(wall_x * 2.0, 0.36, 0.08), 0.25), paint, Vector3(0, 1.04, bed_z0 + 0.02))
	b.part(MeshGen.rounded_box(Vector3(wall_x * 2.0, 0.34, 0.06), 0.25), trim, Vector3(0, 1.04, bed_z1))
	b.part(MeshGen.rounded_box(Vector3(wall_x * 2.0 - 0.1, 0.03, bed_z1 - bed_z0 - 0.08), 0.3),
			Mats.matte(Color(0.1, 0.1, 0.11)), Vector3(0, 0.9, (bed_z0 + bed_z1) / 2.0))
	b.part(MeshGen.rounded_box(Vector3(0.3, 0.05, 0.02), 0.5), Mats.chrome(), Vector3(0, 1.14, bed_z0 - 0.03))
	# Big chrome grille, bumpers, lights.
	var front := CarKit.end_z(spec, 0.0, 0.9, true)
	b.part(MeshGen.rounded_box(Vector3(1.2, 0.36, 0.06), 0.3), Mats.chrome(), Vector3(0, 0.92, front - 0.01))
	b.part(MeshGen.rounded_box(Vector3(1.1, 0.3, 0.04), 0.3), trim, Vector3(0, 0.92, front + 0.015))
	for i in 3:
		b.part(MeshGen.rounded_box(Vector3(1.08, 0.025, 0.03), 0.5), Mats.chrome(), Vector3(0, 0.84 + i * 0.08, front + 0.03))
	b.part(MeshGen.rounded_box(Vector3(1.9, 0.22, 0.2), 0.5), Mats.chrome(), Vector3(0, 0.6, 2.6))
	b.part(MeshGen.rounded_box(Vector3(1.9, 0.18, 0.18), 0.5), Mats.chrome(), Vector3(0, 0.6, -2.66))
	b.part(MeshGen.rounded_box(Vector3(0.08, 0.08, 0.2), 0.5), trim, Vector3(0, 0.5, -2.82))
	b.blob(Mats.chrome(), Vector3(0, 0.56, -2.9), Vector3(0.04, 0.04, 0.04))
	CarKit.head_lights(b, spec, 0.75, 0.95, Vector3(0.26, 0.16, 0.08))
	CarKit.tail_lights(b, spec, 0.88, 1.02, Vector3(0.07, 0.24, 0.06), -2.64)
	CarKit.plate(b, Vector3(0, 0.6, 2.71))
	CarKit.plate(b, Vector3(0, 0.82, -2.68), true)
	CarKit.mirrors(b, Vector3(0.97, 1.32, 1.3), paint)
	CarKit.handles(b, CarKit.side_x(spec, 1.05, 0.4) + 0.005, 1.05, [0.45, -0.4])
	CarKit.arch_liners(b, spec)
	CarKit.wheels(b, spec, "alloy")
