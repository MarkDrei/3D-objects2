class_name FormulaCar
extends Node3D
## Open-wheel racing car: needle nose, sidepods, air box over the driver, big front and rear
## wings, exposed suspension arms and fat slicks.

@export var color := Color(0.98, 0.45, 0.04)
@export var accent := Color(0.06, 0.1, 0.26)
@export var number := "7"


func _ready() -> void:
	var b := Builder.new(self)
	var spec := {
		length = 4.3, width = 0.9, axles = [], wheel_r = 0.33, sill = 0.1, e = 0.55, tumble = 0.7,
		round_front = 0.25, round_back = 0.2, rings = 120,
		top = [Vector2(-2.15, 0.5), Vector2(-1.3, 0.62), Vector2(-0.55, 0.98), Vector2(-0.3, 0.98),
			Vector2(-0.1, 0.66), Vector2(0.5, 0.64), Vector2(1.5, 0.48), Vector2(2.15, 0.26)],
		plan = [Vector2(-2.15, 0.16), Vector2(-1.5, 0.26), Vector2(-0.4, 0.34), Vector2(0.4, 0.3),
			Vector2(1.4, 0.16), Vector2(2.15, 0.1)],
	}
	var wheel_spec := {axles = [1.55, -1.32], wheel_r = 0.33, wheel_w = 0.38, track = 0.8, rim_ratio = 0.58}
	var paint := Mats.paint(color, 0.18, 0.15)
	var blue := Mats.paint(accent, 0.18, 0.2)
	var carbon := Mats.plastic(Color(0.04, 0.04, 0.045), 0.3)
	# Blue spine along the top, orange sides.
	CarKit.body(b, spec, [paint, blue], func(c: Vector3, n: Vector3) -> int:
		return 1 if n.y > 0.6 and absf(c.x) < 0.09 else 0)
	# Sidepods.
	for side: float in [1.0, -1.0]:
		var path := MeshGen.smooth_path(PackedVector3Array([Vector3(side * 0.42, 0.34, 0.25),
				Vector3(side * 0.44, 0.36, -0.3), Vector3(side * 0.36, 0.3, -1.1), Vector3(side * 0.22, 0.24, -1.6)]))
		b.part(MeshGen.tube(path, MeshGen.resample(PackedFloat32Array([0.15, 0.2, 0.15, 0.06]), path.size()),
				24, true, false, 0.8, Vector3(1, 0, 0)), paint)
		b.part(MeshGen.superellipsoid(Vector3(0.012, 0.11, 0.13), 0.5, 0.5), carbon, Vector3(side * 0.42, 0.36, 0.33))
	b.part(MeshGen.rounded_box(Vector3(1.3, 0.03, 2.4), 0.2), carbon, Vector3(0, 0.07, -0.3))
	# Cockpit with driver.
	b.part(MeshGen.superellipsoid(Vector3(0.22, 0.04, 0.4), 0.3, 0.5), carbon, Vector3(0, 0.66, 0.2))
	b.blob(Mats.paint(Color(0.95, 0.95, 0.95), 0.15, 0.1), Vector3(0, 0.78, 0.05), Vector3(0.13, 0.14, 0.15))
	b.blob(Mats.glass(Color(0.1, 0.1, 0.12)), Vector3(0, 0.8, 0.12), Vector3(0.115, 0.05, 0.1))
	b.blob(Mats.paint(accent, 0.18, 0.2), Vector3(0, 0.84, 0.03), Vector3(0.11, 0.08, 0.12))
	b.part(MeshGen.rounded_box(Vector3(0.24, 0.04, 0.03), 0.5), carbon, Vector3(0, 0.74, 0.42))
	# Halo.
	var halo := MeshGen.smooth_path(PackedVector3Array([Vector3(-0.2, 0.68, -0.15), Vector3(-0.17, 0.86, 0.2),
			Vector3(0, 0.9, 0.38), Vector3(0.17, 0.86, 0.2), Vector3(0.2, 0.68, -0.15)]))
	var hr := PackedFloat32Array()
	for i in halo.size():
		hr.append(0.022)
	b.part(MeshGen.tube(halo, hr, 12), carbon)
	b.part(MeshGen.rounded_box(Vector3(0.04, 0.24, 0.04), 0.5), carbon, Vector3(0, 0.78, 0.45), Vector3(-30, 0, 0))
	# Front wing with end plates, rear wing on a pylon.
	b.part(MeshGen.superellipsoid(Vector3(0.85, 0.018, 0.18), 0.3, 0.3), blue, Vector3(0, 0.1, 2.05))
	b.part(MeshGen.superellipsoid(Vector3(0.75, 0.014, 0.1), 0.3, 0.3), paint, Vector3(0, 0.16, 1.98), Vector3(-12, 0, 0))
	for side: float in [1.0, -1.0]:
		b.part(MeshGen.rounded_box(Vector3(0.02, 0.16, 0.42), 0.3), blue, Vector3(side * 0.85, 0.15, 2.04))
		b.part(MeshGen.rounded_box(Vector3(0.025, 0.42, 0.55), 0.25), blue, Vector3(side * 0.5, 0.86, -2.0))
	b.part(MeshGen.superellipsoid(Vector3(0.49, 0.02, 0.2), 0.3, 0.3), blue, Vector3(0, 0.98, -2.0), Vector3(8, 0, 0))
	b.part(MeshGen.superellipsoid(Vector3(0.49, 0.015, 0.1), 0.3, 0.3), paint, Vector3(0, 1.04, -2.18), Vector3(25, 0, 0))
	b.part(MeshGen.rounded_box(Vector3(0.05, 0.42, 0.1), 0.4), carbon, Vector3(0, 0.68, -1.95))
	b.part(MeshGen.superellipsoid(Vector3(0.55, 0.02, 0.1), 0.3, 0.3), carbon, Vector3(0, 0.62, -2.05))
	CarKit.lamp(b, Vector3(0, 0.36, -2.2), Vector3(0.1, 0.05, 0.04), Color(0.95, 0.05, 0.04), Vector3(0, 0, -1), 2.0)
	# Suspension arms from the body to the wheel hubs.
	for az: float in wheel_spec.axles:
		for side: float in [1.0, -1.0]:
			for arm: Array in [[0.24, 0.3], [0.44, 0.4]]:
				var p0 := Vector3(side * 0.12, arm[1], az)
				var p1 := Vector3(side * 0.62, arm[0] + 0.1, az)
				var arm_pts := PackedVector3Array([p0, p1])
				b.part(MeshGen.tube(arm_pts, PackedFloat32Array([0.018, 0.018]), 8), carbon)
	# Start number on the nose and the engine cover.
	CarKit.side_text(b, number, CarKit.side_x(spec, 0.45, 1.0) + 0.004, 0.45, 1.0, Color(1, 1, 1), 0.0022)
	CarKit.side_text(b, number, CarKit.side_x(spec, 0.62, -0.9) + 0.004, 0.62, -0.9, Color(1, 1, 1), 0.003)
	CarKit.wheels(b, wheel_spec, "sport", Color(0.95, 0.75, 0.05))
	# Coloured stripe on each tyre wall.
	var stripe := MeshGen.lathe(PackedVector2Array([Vector2(0.235, 0.165), Vector2(0.26, 0.19),
			Vector2(0.26, 0.17), Vector2(0.235, 0.15)]), 40)
	for az: float in wheel_spec.axles:
		for side: float in [1.0, -1.0]:
			b.part(stripe, Mats.plastic(Color(0.95, 0.8, 0.1), 0.5), Vector3(side * 0.8, 0.33, az), Vector3(0, 0, -90 * side))
