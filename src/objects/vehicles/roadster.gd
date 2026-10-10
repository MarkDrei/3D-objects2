class_name Roadster
extends Node3D
## Open two-seater: long bonnet, low windscreen, leather seats with fairings behind them.

@export var color := Color(0.06, 0.26, 0.17)
@export var leather := Color(0.62, 0.4, 0.22)


func _ready() -> void:
	var b := Builder.new(self)
	var spec := {
		length = 4.1, width = 1.8, axles = [1.3, -1.22], wheel_r = 0.33, wheel_w = 0.24, track = 0.76,
		arch_gap = 0.05, sill = 0.22, e = 0.42, tumble = 0.86, round_front = 0.3, round_back = 0.22,
		top = [Vector2(-2.05, 0.66), Vector2(-1.55, 0.82), Vector2(-0.9, 0.84), Vector2(0.3, 0.83),
			Vector2(1.7, 0.74), Vector2(2.05, 0.56)],
		plan = [Vector2(-2.05, 0.82), Vector2(-1.2, 0.9), Vector2(0.0, 0.86), Vector2(1.3, 0.88), Vector2(2.05, 0.74)],
	}
	var paint := Mats.paint(color)
	var dark := Mats.matte(Color(0.05, 0.05, 0.055), 0.8)
	var seat := Mats.plastic(leather, 0.55)
	CarKit.body(b, spec, [paint])
	# Cockpit opening (dark tub) and seats.
	b.part(MeshGen.superellipsoid(Vector3(0.62, 0.04, 0.55), 0.3, 0.4), dark, Vector3(0, 0.82, -0.32))
	for side: float in [1.0, -1.0]:
		b.part(MeshGen.rounded_box(Vector3(0.46, 0.12, 0.48), 0.5), seat, Vector3(side * 0.3, 0.84, -0.3))
		b.part(MeshGen.rounded_box(Vector3(0.44, 0.48, 0.12), 0.55), seat, Vector3(side * 0.3, 1.04, -0.6),
				Vector3(-14, 0, 0))
		b.part(MeshGen.rounded_box(Vector3(0.24, 0.14, 0.1), 0.7), seat, Vector3(side * 0.3, 1.34, -0.66),
				Vector3(-14, 0, 0))
		# Fairing behind each seat.
		var path := MeshGen.smooth_path(PackedVector3Array([Vector3(side * 0.3, 0.8, -0.72),
				Vector3(side * 0.3, 0.93, -0.95), Vector3(side * 0.3, 0.84, -1.6)]))
		b.part(MeshGen.tube(path, MeshGen.resample(PackedFloat32Array([0.2, 0.18, 0.04]), path.size()),
				20, true, false, 0.7), paint)
	# Dashboard, steering wheel, windscreen with a chrome frame.
	b.part(MeshGen.rounded_box(Vector3(1.3, 0.1, 0.18), 0.5), dark, Vector3(0, 0.88, 0.12))
	var wheel := PackedVector2Array()
	for i in 13:
		var a := TAU * i / 12.0
		wheel.append(Vector2(0.17 + cos(a) * 0.018, sin(a) * 0.018))
	b.part(MeshGen.lathe(wheel, 32, false), dark, Vector3(0.3, 0.95, 0.02), Vector3(-60, 0, 0))
	b.part(MeshGen.rounded_box(Vector3(0.06, 0.06, 0.2), 0.5), dark, Vector3(0.3, 0.93, 0.08), Vector3(-25, 0, 0))
	b.group("Windscreen", Vector3(0, 0.86, 0.3), Vector3(-32, 0, 0))
	b.part(MeshGen.rounded_box(Vector3(1.32, 0.38, 0.03), 0.25), Mats.chrome(), Vector3(0, 0.19, 0))
	b.part(MeshGen.rounded_box(Vector3(1.24, 0.33, 0.036), 0.25), Mats.glass(Color(0.1, 0.13, 0.16)), Vector3(0, 0.19, 0))
	b.end()
	# Chrome details: grille, bumpers, side vents, twin exhausts.
	var front := CarKit.end_z(spec, 0.0, 0.42, true)
	b.part(MeshGen.superellipsoid(Vector3(0.3, 0.12, 0.03), 0.6, 0.6), Mats.chrome(), Vector3(0, 0.44, front))
	b.part(MeshGen.superellipsoid(Vector3(0.26, 0.09, 0.03), 0.6, 0.6), dark, Vector3(0, 0.44, front + 0.012))
	for z: float in [2.0, -2.0]:
		for side: float in [1.0, -1.0]:
			b.part(MeshGen.rounded_box(Vector3(0.36, 0.05, 0.06), 0.6), Mats.chrome(),
					Vector3(side * 0.5, 0.36, CarKit.end_z(spec, 0.5, 0.36, z > 0) + signf(z) * 0.02),
					Vector3(0, side * signf(z) * -15, 0))
	for side: float in [1.0, -1.0]:
		for i in 3:
			b.part(MeshGen.rounded_box(Vector3(0.02, 0.025, 0.22), 0.6), Mats.chrome(),
					Vector3(side * (CarKit.side_x(spec, 0.62, 0.9) - 0.002), 0.58 + i * 0.05, 0.85))
		b.part(MeshGen.lathe(PackedVector2Array([Vector2(0.035, 0.0), Vector2(0.035, 0.18), Vector2(0.025, 0.18),
				Vector2(0.025, 0.05)]), 20, false), Mats.chrome(), Vector3(side * 0.35, 0.28, -2.0), Vector3(-90, 0, 0))
	CarKit.head_lights(b, spec, 0.56, 0.6, Vector3(0.2, 0.2, 0.12))
	CarKit.tail_lights(b, spec, 0.58, 0.62, Vector3(0.12, 0.12, 0.06))
	CarKit.plate(b, Vector3(0, 0.5, CarKit.end_z(spec, 0.0, 0.5, false) - 0.01), true)
	CarKit.arch_liners(b, spec)
	CarKit.wheels(b, spec, "alloy")
