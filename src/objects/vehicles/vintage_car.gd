class_name VintageCar
extends Node3D
## 1930s saloon: narrow body, upright windscreen, separate flowing mudguards with running
## boards, free-standing head lamps, whitewall tyres and a spare wheel at the back.

@export var color := Color(0.36, 0.06, 0.1)
@export var fender_color := Color(0.04, 0.04, 0.05)


func _ready() -> void:
	var b := Builder.new(self)
	# The body sits between the wheels, so it needs no arches; the wheels get their own spec.
	var spec := {
		length = 4.1, width = 1.3, axles = [], wheel_r = 0.38, sill = 0.42, e = 0.5, tumble = 0.92,
		round_front = 0.12, round_back = 0.45,
		top = [Vector2(-2.05, 0.95), Vector2(-1.6, 1.12), Vector2(1.9, 1.12), Vector2(2.05, 1.06)],
		plan = [Vector2(-2.05, 0.6), Vector2(-1.0, 0.66), Vector2(0.4, 0.66), Vector2(2.05, 0.5)],
		cabin = {z0 = -1.62, z1 = 0.62, belt = 1.12, half_width = 0.64, e = 0.36, tumble = 0.88,
			roof = [Vector2(-1.62, 1.06), Vector2(-1.45, 1.72), Vector2(-0.9, 1.86), Vector2(0.5, 1.86),
				Vector2(0.6, 1.7), Vector2(0.62, 1.06)]},
	}
	var wheel_spec := {axles = [1.35, -1.3], wheel_r = 0.38, wheel_w = 0.16, track = 0.78, rim_ratio = 0.5}
	var paint := Mats.paint(color, 0.18, 0.15)
	var fender := Mats.paint(fender_color, 0.18, 0.2)
	CarKit.body(b, spec, [paint])
	CarKit.cabin(b, spec, paint)
	CarKit.glazing(b, spec, [[-0.38, 0.48], [-1.32, -0.5]], true, true, {inset = 0.09})
	# Black fabric roof.
	var roof := CarKit.quad(Vector2(-0.56, -0.56), Vector2(0.56, -0.56), Vector2(0.56, 1.5), Vector2(-0.56, 1.5), 0.12)
	CarKit.decal(b, spec, true, "top", roof, Mats.matte(Color(0.05, 0.05, 0.05), 0.7), 0.004)
	# Bonnet louvres.
	for side: float in [1.0, -1.0]:
		for i in 5:
			b.part(MeshGen.rounded_box(Vector3(0.015, 0.16, 0.04), 0.5), Mats.chrome(),
					Vector3(side * (CarKit.side_x(spec, 0.9, 1.1 + i * 0.12) - 0.004), 0.9, 1.1 + i * 0.12))
	# Mudguards: flat tubes arching over each wheel, joined by the running boards.
	var r_arc := 0.47
	for az: float in wheel_spec.axles:
		var front := az > 0.0
		var pts := PackedVector3Array()
		for i in 15:
			var a := lerpf(-0.25, PI, float(i) / 14.0) if front else lerpf(0.0, PI + 0.3, float(i) / 14.0)
			pts.append(Vector3(0, 0.38 + sin(a) * r_arc, az + cos(a) * r_arc))
		if front:
			pts.append(Vector3(0, 0.36, az - r_arc - 0.08))
		else:
			pts.insert(0, Vector3(0, 0.36, az + r_arc + 0.08))
		var radii := PackedFloat32Array()
		for i in pts.size():
			radii.append(0.12)
		var mesh := MeshGen.tube(pts, radii, 20, true, false, 1.0, Vector3(1, 0, 0))
		for side: float in [1.0, -1.0]:
			b.part(mesh, fender, Vector3(side * 0.78, 0, 0), Vector3.ZERO, Vector3(1.25, 1, 1))
	for side: float in [1.0, -1.0]:
		b.part(MeshGen.rounded_box(Vector3(0.3, 0.05, 1.5), 0.3), fender, Vector3(side * 0.76, 0.35, 0.03))
		b.part(MeshGen.rounded_box(Vector3(0.24, 0.015, 1.3), 0.5), Mats.matte(Color(0.12, 0.12, 0.12)),
				Vector3(side * 0.76, 0.378, 0.03))
	# Radiator grille with chrome shell, mascot, free-standing head lamps on a bar.
	b.part(MeshGen.rounded_box(Vector3(0.62, 0.7, 0.08), 0.3), Mats.chrome(), Vector3(0, 0.78, 2.03))
	b.part(MeshGen.rounded_box(Vector3(0.52, 0.6, 0.04), 0.3), Mats.matte(Color(0.1, 0.1, 0.1)), Vector3(0, 0.78, 2.06))
	for i in 9:
		b.part(MeshGen.rounded_box(Vector3(0.012, 0.58, 0.02), 0.5), Mats.chrome(), Vector3(-0.24 + i * 0.06, 0.78, 2.08))
	b.blob(Mats.chrome(), Vector3(0, 1.17, 2.0), Vector3(0.025, 0.06, 0.04))
	b.part(MeshGen.rounded_box(Vector3(1.2, 0.03, 0.03), 0.5), Mats.chrome(), Vector3(0, 0.72, 2.0))
	var lamp := PackedVector2Array([Vector2(0, -0.13), Vector2(0.09, -0.11), Vector2(0.13, -0.04),
			Vector2(0.14, 0.04), Vector2(0.135, 0.06)])
	for side: float in [1.0, -1.0]:
		b.group("HeadLamp", Vector3(side * 0.56, 0.86, 1.98), Vector3(90, 0, 0))
		b.part(MeshGen.lathe(lamp, 32, false), Mats.chrome())
		b.part(MeshGen.lathe(PackedVector2Array([Vector2(0.13, 0.05), Vector2(0.06, 0.065), Vector2(0, 0.068)]), 32),
				Mats.glow(Color(1, 0.94, 0.78), 2.0))
		b.end()
		b.part(MeshGen.rounded_box(Vector3(0.03, 0.14, 0.03), 0.5), Mats.chrome(), Vector3(side * 0.56, 0.75, 1.98))
		# Horn and small tail lamp on the rear mudguard.
		b.blob(Mats.glow(Color(0.9, 0.08, 0.05), 1.4), Vector3(side * 0.78, 0.86, -1.55), Vector3(0.05, 0.05, 0.04))
	# Chrome bumper bars, spare wheel at the back, plates.
	for z: float in [2.22, -2.18]:
		b.part(MeshGen.rounded_box(Vector3(1.6, 0.07, 0.05), 0.6), Mats.chrome(), Vector3(0, 0.42, z))
	CarKit.spare_wheel(b, Vector3(0, 0.82, -2.14), 0.36, 0.15, fender)
	CarKit.plate(b, Vector3(0, 0.55, 2.24))
	CarKit.handles(b, CarKit.cabin_side_x(spec, 1.25, -0.4) + 0.005, 1.25, [-0.3, -0.6])
	CarKit.wheels(b, wheel_spec, "steel")
	# Whitewalls.
	var ww := MeshGen.lathe(PackedVector2Array([Vector2(0.27, 0.074), Vector2(0.32, 0.082),
			Vector2(0.32, 0.07), Vector2(0.27, 0.064)]), 40)
	for az: float in wheel_spec.axles:
		for side: float in [1.0, -1.0]:
			b.part(ww, Mats.plastic(Color(0.93, 0.92, 0.88), 0.6), Vector3(side * 0.78, 0.38, az), Vector3(0, 0, -90 * side))
