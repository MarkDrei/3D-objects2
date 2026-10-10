class_name MuscleCar
extends Node3D
## Classic American fastback: long bonnet with a scoop, twin racing stripes, chrome bumpers,
## fat tyres and side exhausts.

@export var color := Color(0.95, 0.42, 0.04)
@export var stripe := Color(0.04, 0.04, 0.05)


func _ready() -> void:
	var b := Builder.new(self)
	var spec := {
		length = 4.8, width = 1.94, axles = [1.48, -1.42], wheel_r = 0.36, wheel_w = 0.3, track = 0.8,
		arch_gap = 0.04, sill = 0.3, e = 0.3, tumble = 0.9, round_front = 0.1, round_back = 0.1,
		top = [Vector2(-2.4, 0.86), Vector2(-2.25, 0.98), Vector2(-1.4, 1.0), Vector2(1.2, 0.98),
			Vector2(2.2, 0.93), Vector2(2.4, 0.76)],
		plan = [Vector2(-2.4, 0.92), Vector2(-1.4, 0.97), Vector2(1.4, 0.95), Vector2(2.4, 0.9)],
		cabin = {z0 = -2.0, z1 = 0.78, belt = 1.0, half_width = 0.8, e = 0.4, tumble = 0.74,
			roof = [Vector2(-2.0, 0.96), Vector2(-1.0, 1.3), Vector2(-0.55, 1.38), Vector2(0.05, 1.38),
				Vector2(0.72, 1.04), Vector2(0.78, 0.96)]},
	}
	var paint := Mats.paint(color, 0.16, 0.2)
	var black := Mats.paint(stripe, 0.2, 0.2)
	var trim := Mats.plastic(Color(0.05, 0.05, 0.055), 0.5)
	CarKit.body(b, spec, [paint])
	CarKit.cabin(b, spec, paint)
	CarKit.glazing(b, spec, [[-0.7, 0.62]], true, true, {inset = 0.06})
	# Twin stripes over bonnet, roof and boot (top view: outline in (x, -z)).
	for side: float in [1.0, -1.0]:
		var s := CarKit.quad(Vector2(side * 0.08, -2.45), Vector2(side * 0.24, -2.45), Vector2(side * 0.24, 2.45),
				Vector2(side * 0.08, 2.45), 0.005)
		CarKit.decal(b, spec, false, "top", s, black, 0.003, 0.0, false)
		CarKit.decal(b, spec, true, "top", s, black, 0.003, 0.0, false)
	# Bonnet scoop.
	b.part(MeshGen.superellipsoid(Vector3(0.28, 0.07, 0.36), 0.5, 0.35), black, Vector3(0, 1.0, 1.3))
	b.part(MeshGen.superellipsoid(Vector3(0.22, 0.04, 0.02), 0.5, 0.35), trim, Vector3(0, 1.02, 1.66))
	# Grille with round lamps, chrome bumpers.
	var front := CarKit.end_z(spec, 0.0, 0.72, true)
	b.part(MeshGen.rounded_box(Vector3(1.6, 0.24, 0.06), 0.3), trim, Vector3(0, 0.74, front - 0.015))
	for side: float in [1.0, -1.0]:
		for x: float in [0.62, 0.38]:
			b.part(MeshGen.lathe(PackedVector2Array([Vector2(0.09, -0.02), Vector2(0.09, 0.02), Vector2(0.075, 0.025)]),
					24, false), Mats.chrome(), Vector3(side * x, 0.74, front + 0.02), Vector3(90, 0, 0))
			b.blob(Mats.glow(Color(1, 0.96, 0.85), 2.2), Vector3(side * x, 0.74, front + 0.02), Vector3(0.078, 0.078, 0.03))
	b.part(MeshGen.rounded_box(Vector3(1.9, 0.12, 0.14), 0.6), Mats.chrome(), Vector3(0, 0.52, 2.36))
	b.part(MeshGen.rounded_box(Vector3(1.9, 0.12, 0.14), 0.6), Mats.chrome(), Vector3(0, 0.52, -2.36))
	# Full-width tail light panel.
	var back := CarKit.end_z(spec, 0.0, 0.8, false)
	b.part(MeshGen.rounded_box(Vector3(1.6, 0.16, 0.04), 0.3), trim, Vector3(0, 0.8, back + 0.005))
	for side: float in [1.0, -1.0]:
		for i in 3:
			CarKit.lamp(b, Vector3(side * (0.2 + i * 0.22), 0.8, back - 0.012), Vector3(0.18, 0.1, 0.03),
					Color(0.9, 0.05, 0.04), Vector3(0, 0, -1), 1.6)
	# Side exhausts and a small spoiler lip.
	for side: float in [1.0, -1.0]:
		b.part(MeshGen.lathe(PackedVector2Array([Vector2(0.05, -0.6), Vector2(0.05, 0.6)]), 20), Mats.chrome(),
				Vector3(side * 0.97, 0.3, 0.05), Vector3(90, 0, 0))
	b.part(MeshGen.superellipsoid(Vector3(0.82, 0.02, 0.07), 0.3, 0.3), black,
			Vector3(0, CarKit.top(spec, -2.25) + 0.03, -2.25), Vector3(-12, 0, 0))
	CarKit.plate(b, Vector3(0, 0.5, 2.44))
	CarKit.plate(b, Vector3(0, 0.62, back - 0.01), true)
	CarKit.mirrors(b, Vector3(0.9, 1.1, 0.62), paint)
	CarKit.handles(b, CarKit.side_x(spec, 0.9, -0.1) + 0.005, 0.9, [-0.1])
	CarKit.arch_liners(b, spec)
	CarKit.wheels(b, spec, "sport", Color(0.1, 0.1, 0.1))
