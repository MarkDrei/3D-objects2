class_name Minivan
extends Node3D
## One-box family van: short sloping nose, big glass area, sliding door and a roof box.

@export var color := Color(0.42, 0.65, 0.82)


func _ready() -> void:
	var b := Builder.new(self)
	var spec := {
		length = 4.9, width = 1.9, axles = [1.5, -1.45], wheel_r = 0.35, wheel_w = 0.24, track = 0.8,
		arch_gap = 0.05, sill = 0.36, e = 0.3, tumble = 0.92, round_front = 0.22, round_back = 0.1,
		top = [Vector2(-2.45, 0.92), Vector2(-2.2, 1.02), Vector2(1.6, 1.02), Vector2(2.2, 0.92), Vector2(2.45, 0.72)],
		plan = [Vector2(-2.45, 0.92), Vector2(0.0, 0.95), Vector2(2.45, 0.9)],
		cabin = {z0 = -2.36, z1 = 2.0, belt = 1.02, half_width = 0.88, e = 0.3, tumble = 0.86, rings = 110,
			roof = [Vector2(-2.36, 0.98), Vector2(-2.3, 1.7), Vector2(0.1, 1.77), Vector2(0.9, 1.62),
				Vector2(1.9, 1.08), Vector2(2.0, 0.98)]},
	}
	var paint := Mats.paint(color, 0.2, 0.3)
	var trim := Mats.plastic(Color(0.12, 0.12, 0.13), 0.6)
	CarKit.body(b, spec, [paint])
	CarKit.cabin(b, spec, paint)
	CarKit.glazing(b, spec, [[0.55, 1.62], [-0.95, 0.42], [-2.2, -1.08]], true, true, {inset = 0.08})
	# Sliding door rail, lower cladding, bumpers.
	for side: float in [1.0, -1.0]:
		b.part(MeshGen.rounded_box(Vector3(0.03, 0.035, 1.2), 0.5), trim,
				Vector3(side * CarKit.cabin_side_x(spec, 1.12, -1.6), 1.12, -1.6))
		b.part(MeshGen.rounded_box(Vector3(0.05, 0.14, 1.5), 0.5), trim, Vector3(side * 0.9, 0.5, 0.02))
	b.part(MeshGen.rounded_box(Vector3(1.85, 0.24, 0.2), 0.5), trim, Vector3(0, 0.48, 2.32))
	b.part(MeshGen.rounded_box(Vector3(1.85, 0.22, 0.16), 0.5), trim, Vector3(0, 0.5, -2.38))
	var front := CarKit.end_z(spec, 0.0, 0.76, true)
	b.part(MeshGen.superellipsoid(Vector3(0.4, 0.07, 0.025), 0.4, 0.4), trim, Vector3(0, 0.76, front - 0.005))
	CarKit.head_lights(b, spec, 0.66, 0.86, Vector3(0.36, 0.13, 0.08))
	CarKit.tail_lights(b, spec, 0.78, 1.2, Vector3(0.09, 0.42, 0.06), -2.36)
	CarKit.plate(b, Vector3(0, 0.5, 2.43))
	CarKit.plate(b, Vector3(0, 0.8, CarKit.end_z(spec, 0.0, 0.8, false) - 0.01), true)
	# Roof rails and roof box.
	for side: float in [1.0, -1.0]:
		b.part(MeshGen.rounded_box(Vector3(0.05, 0.05, 2.2), 0.6), Mats.alloy(Color(0.6, 0.62, 0.65)),
				Vector3(side * 0.66, 1.83, -0.9))
	b.part(MeshGen.superellipsoid(Vector3(0.44, 0.16, 0.95), 0.4, 0.45), Mats.plastic(Color(0.18, 0.19, 0.2), 0.35),
			Vector3(0, 2.0, -0.9))
	CarKit.mirrors(b, Vector3(0.94, 1.22, 1.45), paint)
	CarKit.handles(b, CarKit.side_x(spec, 0.96, 0.9) + 0.005, 0.96, [0.9])
	CarKit.arch_liners(b, spec)
	CarKit.wheels(b, spec, "alloy")
