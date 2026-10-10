class_name MicroCar
extends Node3D
## Tiny two-seat city car: a dark safety cell with bright body panels, big round lights.

@export var color := Color(0.98, 0.78, 0.12)
@export var cell := Color(0.86, 0.87, 0.89)


func _ready() -> void:
	var b := Builder.new(self)
	var spec := {
		length = 2.65, width = 1.6, axles = [0.86, -0.82], wheel_r = 0.3, wheel_w = 0.2, track = 0.67,
		arch_gap = 0.04, sill = 0.26, e = 0.5, tumble = 0.86, round_front = 0.35, round_back = 0.22,
		top = [Vector2(-1.32, 0.78), Vector2(-1.15, 0.9), Vector2(0.55, 0.9), Vector2(1.1, 0.82), Vector2(1.32, 0.6)],
		plan = [Vector2(-1.32, 0.76), Vector2(0.0, 0.8), Vector2(1.32, 0.74)],
		cabin = {z0 = -1.24, z1 = 1.02, belt = 0.9, half_width = 0.74, e = 0.42, tumble = 0.82,
			roof = [Vector2(-1.24, 0.86), Vector2(-1.16, 1.5), Vector2(-0.2, 1.56), Vector2(0.45, 1.42),
				Vector2(0.97, 0.96), Vector2(1.02, 0.86)]},
	}
	var paint := Mats.paint(color, 0.18, 0.15)
	var dark := Mats.paint(cell, 0.25, 0.4)
	CarKit.body(b, spec, [paint])
	CarKit.cabin(b, spec, dark)
	CarKit.glazing(b, spec, [[-0.85, 0.82]], true, true, {inset = 0.06})
	# Safety cell band down the sides behind the door.
	var band := CarKit.quad(Vector2(-0.98, 0.3), Vector2(-0.84, 0.3), Vector2(-0.84, 0.92), Vector2(-0.98, 0.92), 0.02)
	CarKit.decal(b, spec, false, "left", band, dark)
	# Big round head lights, small tail lights, bumpers.
	for side: float in [1.0, -1.0]:
		var z := CarKit.end_z(spec, 0.5, 0.72, true)
		b.part(MeshGen.lathe(PackedVector2Array([Vector2(0.12, -0.03), Vector2(0.12, 0.02), Vector2(0.1, 0.03)]),
				28, false), Mats.chrome(Color(0.3, 0.3, 0.32)), Vector3(side * 0.5, 0.72, z - 0.01), Vector3(80, side * 18, 0))
		b.blob(Mats.glow(Color(1, 0.97, 0.88), 2.2), Vector3(side * 0.5, 0.72, z - 0.005), Vector3(0.1, 0.1, 0.04),
				Vector3(-10, side * 18, 0))
	CarKit.tail_lights(b, spec, 0.55, 0.7, Vector3(0.16, 0.16, 0.06))
	var trim := Mats.plastic(Color(0.12, 0.12, 0.13), 0.6)
	b.part(MeshGen.rounded_box(Vector3(1.4, 0.18, 0.16), 0.6), trim, Vector3(0, 0.42, CarKit.end_z(spec, 0.0, 0.42, true) - 0.04))
	b.part(MeshGen.rounded_box(Vector3(1.4, 0.18, 0.16), 0.6), trim, Vector3(0, 0.42, CarKit.end_z(spec, 0.0, 0.42, false) + 0.04))
	# Little smile-shaped grille.
	var smile := PackedVector3Array()
	for i in 9:
		var a := lerpf(-0.9, 0.9, i / 8.0)
		smile.append(Vector3(sin(a) * 0.28, 0.6 - cos(a) * 0.08 + 0.08, 0))
	for i in smile.size():
		var p := smile[i]
		smile[i] = Vector3(p.x, p.y, CarKit.end_z(spec, p.x, p.y, true) + 0.005)
	var sr := PackedFloat32Array()
	for i in smile.size():
		sr.append(0.018)
	b.part(MeshGen.tube(MeshGen.smooth_path(smile), MeshGen.resample(sr, MeshGen.smooth_path(smile).size()), 10), trim)
	CarKit.plate(b, Vector3(0, 0.62, CarKit.end_z(spec, 0.0, 0.62, false) - 0.01), true)
	CarKit.mirrors(b, Vector3(0.82, 1.06, 0.6), dark)
	CarKit.handles(b, CarKit.side_x(spec, 0.8, -0.2) + 0.005, 0.8, [-0.2])
	CarKit.arch_liners(b, spec)
	CarKit.wheels(b, spec, "alloy")
