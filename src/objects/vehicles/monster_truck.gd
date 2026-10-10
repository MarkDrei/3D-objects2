class_name MonsterTruck
extends Node3D
## Monster truck: a pickup-style body lifted high above huge knobbly tyres, with visible axles,
## coil-over shocks, flames on the sides and a light bar on the roof.

@export var color := Color(0.1, 0.5, 0.12)


func _ready() -> void:
	var b := Builder.new(self)
	var spec := {
		length = 4.4, width = 2.0, axles = [1.45, -1.45], wheel_r = 0.78, wheel_w = 0.62, track = 1.1,
		arch_gap = 0.1, sill = 1.25, e = 0.28, tumble = 0.93, round_front = 0.2, round_back = 0.12,
		top = [Vector2(-2.2, 1.86), Vector2(-2.0, 1.92), Vector2(1.6, 1.92), Vector2(2.0, 1.85), Vector2(2.2, 1.66)],
		plan = [Vector2(-2.2, 0.98), Vector2(0.0, 1.0), Vector2(2.2, 0.96)],
		cabin = {z0 = -1.0, z1 = 0.95, belt = 1.92, half_width = 0.9, e = 0.3, tumble = 0.85,
			roof = [Vector2(-1.0, 1.86), Vector2(-0.94, 2.6), Vector2(0.15, 2.62), Vector2(0.88, 2.0),
				Vector2(0.95, 1.86)]},
	}
	var paint := Mats.paint(color, 0.18, 0.3)
	var frame := Mats.plastic(Color(0.08, 0.08, 0.09), 0.5)
	var yellow := Mats.plastic(Color(0.98, 0.78, 0.08), 0.35)
	CarKit.body(b, spec, [paint])
	CarKit.cabin(b, spec, paint)
	CarKit.glazing(b, spec, [[-0.3, 0.75], [-0.88, -0.42]])
	# Flames on both sides of the bonnet (outline in (z, y)).
	var flame := PackedVector2Array([Vector2(1.95, 1.65), Vector2(1.95, 1.84), Vector2(1.2, 1.87),
			Vector2(0.2, 1.86), Vector2(-0.6, 1.83), Vector2(0.2, 1.79), Vector2(-0.3, 1.75), Vector2(0.35, 1.72),
			Vector2(-0.5, 1.67), Vector2(0.6, 1.65)])
	var flames := MeshGen.rounded_polygon(CarKit.ccw(flame), 0.02)
	CarKit.decal(b, spec, false, "left", CarKit.ccw(flames), Mats.paint(Color(0.98, 0.55, 0.05), 0.2, 0.2))
	var inner := PackedVector2Array()
	for p in flames:
		inner.append(p.lerp(Vector2(1.9, 1.755), 0.4))
	CarKit.decal(b, spec, false, "left", CarKit.ccw(inner), Mats.paint(Color(1.0, 0.85, 0.15), 0.2, 0.2), 0.007)
	# Chassis: frame rails, axles, shocks and a bash plate.
	for side: float in [1.0, -1.0]:
		b.part(MeshGen.rounded_box(Vector3(0.12, 0.16, 3.8), 0.3), frame, Vector3(side * 0.45, 1.12, 0))
	for az: float in spec.axles:
		b.part(MeshGen.lathe(PackedVector2Array([Vector2(0.07, -1.0), Vector2(0.07, 1.0)]), 16), frame,
				Vector3(0, 0.78, az), Vector3(0, 0, 90))
		b.part(MeshGen.superellipsoid(Vector3(0.18, 0.16, 0.16), 0.6, 0.6), frame, Vector3(0, 0.78, az))
		for side: float in [1.0, -1.0]:
			for dz: float in [0.22, -0.22]:
				var x := side * 0.6
				b.part(MeshGen.lathe(PackedVector2Array([Vector2(0.045, 0.0), Vector2(0.045, 0.55)]), 12), Mats.chrome(),
						Vector3(x, 0.78, az + dz), Vector3(0, 0, side * 12))
				var coil := PackedVector3Array()
				for i in 60:
					var a := i * 0.55
					coil.append(Vector3(x + cos(a) * 0.075 - side * 0.02, 0.84 + i * 0.0068, az + dz + sin(a) * 0.075))
				var cr := PackedFloat32Array()
				for i in coil.size():
					cr.append(0.016)
				b.part(MeshGen.tube(coil, cr, 6), yellow)
	b.part(MeshGen.rounded_box(Vector3(1.0, 0.06, 0.6), 0.4), Mats.alloy(Color(0.6, 0.6, 0.62)), Vector3(0, 1.05, 2.0),
			Vector3(-15, 0, 0))
	# Front: grille guard, lights. Back: tail lights.
	var front := CarKit.end_z(spec, 0.0, 1.6, true)
	b.part(MeshGen.rounded_box(Vector3(1.1, 0.26, 0.06), 0.3), frame, Vector3(0, 1.58, front - 0.01))
	var guard := MeshGen.smooth_path(PackedVector3Array([Vector3(-0.8, 1.2, 2.2), Vector3(-0.75, 1.75, 2.3),
			Vector3(0, 1.8, 2.34), Vector3(0.75, 1.75, 2.3), Vector3(0.8, 1.2, 2.2)]))
	var gr := PackedFloat32Array()
	for i in guard.size():
		gr.append(0.035)
	b.part(MeshGen.tube(guard, gr, 12), Mats.chrome())
	CarKit.head_lights(b, spec, 0.7, 1.62, Vector3(0.26, 0.14, 0.08))
	CarKit.tail_lights(b, spec, 0.85, 1.7, Vector3(0.08, 0.26, 0.06))
	# Roof light bar.
	b.part(MeshGen.rounded_box(Vector3(1.3, 0.06, 0.08), 0.5), frame, Vector3(0, 2.66, 0.0))
	for i in 4:
		CarKit.lamp(b, Vector3(-0.45 + i * 0.3, 2.74, 0.02), Vector3(0.16, 0.14, 0.08), Color(1, 0.97, 0.85),
				Vector3(0, 0, 1), 2.2)
	CarKit.mirrors(b, Vector3(0.97, 2.1, 0.75), paint)
	CarKit.handles(b, CarKit.side_x(spec, 1.82, 0.2) + 0.005, 1.82, [0.2])
	CarKit.arch_liners(b, spec)
	_monster_wheels(b, spec)


## Huge tyres with knobbly tread and a yellow hub.
func _monster_wheels(b: Builder, spec: Dictionary) -> void:
	CarKit.wheels(b, spec, "black")
	var r: float = spec.wheel_r
	var w: float = spec.wheel_w
	var knob := MeshGen.superellipsoid(Vector3(0.04, 0.14, 0.075), 0.4, 0.4, 6, 12)
	var hub := MeshGen.lathe(PackedVector2Array([Vector2(r * 0.3, 0.0), Vector2(r * 0.28, 0.04), Vector2(0, 0.06)]), 24)
	for az: float in spec.axles:
		for side: float in [1.0, -1.0]:
			b.group("Tread", Vector3(side * spec.track, r, az), Vector3(0, 0, -90 * side))
			for i in 26:
				for row: float in [1.0, -1.0]:
					var a := TAU * (i + (0.5 if row > 0.0 else 0.0)) / 26.0
					b.part(knob, Mats.rubber(), Vector3(cos(a) * (r - 0.035), row * w * 0.2, sin(a) * (r - 0.035)),
							Vector3(0, -rad_to_deg(a), 0))
			b.part(hub, Mats.plastic(Color(0.98, 0.78, 0.08), 0.35), Vector3(0, w * 0.3, 0))
			b.end()
