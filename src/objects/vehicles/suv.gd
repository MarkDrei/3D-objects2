class_name Suv
extends Node3D
## Boxy off-roader: high body, upright glasshouse, roof rails, spare wheel on the tailgate.

@export var color := Color(0.24, 0.34, 0.24)


func _ready() -> void:
	var b := Builder.new(self)
	var spec := {
		length = 4.6, width = 1.9, axles = [1.38, -1.4], wheel_r = 0.39, wheel_w = 0.28, track = 0.8,
		arch_gap = 0.06, sill = 0.44, e = 0.22, tumble = 0.95, round_front = 0.14, round_back = 0.1,
		top = [Vector2(-2.3, 0.98), Vector2(-2.1, 1.1), Vector2(1.5, 1.12), Vector2(2.05, 1.08), Vector2(2.3, 0.94)],
		plan = [Vector2(-2.3, 0.92), Vector2(0.0, 0.95), Vector2(2.3, 0.92)],
		cabin = {z0 = -2.18, z1 = 1.02, belt = 1.12, half_width = 0.88, e = 0.28, tumble = 0.86,
			roof = [Vector2(-2.18, 1.06), Vector2(-2.1, 1.84), Vector2(0.3, 1.88), Vector2(0.96, 1.22),
				Vector2(1.02, 1.06)]},
	}
	var paint := Mats.paint(color)
	var trim := Mats.plastic(Color(0.07, 0.07, 0.08), 0.6)
	CarKit.body(b, spec, [paint])
	CarKit.cabin(b, spec, paint)
	CarKit.glazing(b, spec, [[-0.02, 0.88], [-1.08, -0.12], [-2.02, -1.18]])
	# Dark cladding along the sills and bumpers.
	for side: float in [1.0, -1.0]:
		b.part(MeshGen.rounded_box(Vector3(0.06, 0.12, 1.6), 0.5), trim, Vector3(side * 0.93, 0.55, -0.02))
	b.part(MeshGen.rounded_box(Vector3(1.86, 0.26, 0.2), 0.5), trim, Vector3(0, 0.56, 2.24))
	b.part(MeshGen.rounded_box(Vector3(1.86, 0.26, 0.2), 0.5), trim, Vector3(0, 0.56, -2.24))
	# Grille with horizontal bars, round head lights, fog lights.
	var front := CarKit.end_z(spec, 0.0, 0.85, true)
	b.part(MeshGen.rounded_box(Vector3(0.9, 0.26, 0.05), 0.3), trim, Vector3(0, 0.86, front - 0.01))
	for i in 3:
		b.part(MeshGen.rounded_box(Vector3(0.86, 0.025, 0.03), 0.5), Mats.chrome(), Vector3(0, 0.79 + i * 0.07, front + 0.02))
	CarKit.head_lights(b, spec, 0.66, 0.88, Vector3(0.2, 0.2, 0.08))
	for side: float in [1.0, -1.0]:
		CarKit.lamp(b, Vector3(side * 0.62, 0.56, 2.34), Vector3(0.1, 0.06, 0.04), Color(1, 0.95, 0.8), Vector3(0, 0, 1))
	CarKit.tail_lights(b, spec, 0.82, 0.92, Vector3(0.09, 0.3, 0.06))
	CarKit.spare_wheel(b, Vector3(0, 1.02, -2.42), 0.36, 0.24, paint)
	CarKit.plate(b, Vector3(0, 0.57, 2.35))
	CarKit.plate(b, Vector3(0, 0.57, -2.35), true)
	# Roof rails.
	for side: float in [1.0, -1.0]:
		b.part(MeshGen.rounded_box(Vector3(0.05, 0.05, 2.1), 0.6), Mats.alloy(Color(0.2, 0.2, 0.22)),
				Vector3(side * 0.66, 1.95, -0.85))
		for z: float in [-1.85, 0.15]:
			b.part(MeshGen.rounded_box(Vector3(0.06, 0.1, 0.1), 0.5), trim, Vector3(side * 0.66, 1.9, z))
	CarKit.mirrors(b, Vector3(0.95, 1.28, 0.82), paint)
	CarKit.handles(b, CarKit.side_x(spec, 1.0, 0.3) + 0.005, 1.0, [0.3, -0.75])
	CarKit.arch_liners(b, spec)
	CarKit.wheels(b, spec, "black")
