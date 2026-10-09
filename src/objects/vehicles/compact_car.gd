class_name CompactCar
extends Node3D
## A small, round city car with a contrasting roof and round headlights, about 3.6 m long.

@export var paint_color := Color(0.45, 0.8, 0.72)
@export var roof_color := Color(0.97, 0.97, 0.95)

var spec := {
	length = 3.4, width = 1.66, axles = [1.12, -1.08], wheel_r = 0.31, wheel_w = 0.2, track = 0.69,
	arch_gap = 0.04, sill = 0.3, e = 0.45, tumble = 0.86, round_front = 0.32, round_back = 0.22,
	top = [Vector2(-1.7, 0.8), Vector2(-1.6, 0.96), Vector2(-1.3, 0.99), Vector2(0.6, 0.97),
		Vector2(1.1, 0.92), Vector2(1.5, 0.83), Vector2(1.7, 0.7)],
	plan = [Vector2(-1.7, 0.77), Vector2(-1.3, 0.83), Vector2(1.0, 0.83), Vector2(1.7, 0.75)],
	cabin = {z0 = -1.5, z1 = 0.95, belt = 0.98, half_width = 0.75, tumble = 0.78, e = 0.6,
		roof = [Vector2(-1.5, 0.88), Vector2(-1.15, 1.42), Vector2(-0.1, 1.47), Vector2(0.95, 0.88)]},
}


func _ready() -> void:
	if get_child_count() == 0:
		build()


func build() -> void:
	var b := Builder.new(self)
	var paint := Mats.paint(paint_color, 0.2, 0.15)
	var roof := Mats.paint(roof_color, 0.2, 0.05)
	var trim := Mats.plastic(Color(0.06, 0.06, 0.07), 0.45)
	var glass := Mats.glass()
	CarKit.arch_liners(b, spec)
	CarKit.body(b, spec, [paint])
	CarKit.cabin(b, spec, paint)
	CarKit.wheels(b, spec, "alloy")
	# Contrasting roof.
	CarKit.decal(b, spec, true, "top", CarKit.quad(Vector2(-0.8, 0.0), Vector2(0.8, 0.0), Vector2(0.8, 1.25),
			Vector2(-0.8, 1.25), 0.2), roof, 0.003)

	CarKit.decal(b, spec, true, "left", CarKit.side_window(spec, -0.22, 0.9, 0.08, 0.0, 0.06), glass, 0.004, 0.025)
	CarKit.decal(b, spec, true, "left", CarKit.side_window(spec, -1.4, -0.36, 0.08, 0.0, 0.06), glass, 0.004, 0.025)
	CarKit.decal(b, spec, true, "front", CarKit.end_window(spec, 0.075, 0.05, 0.07), glass, 0.004, 0.02)
	CarKit.decal(b, spec, true, "back", CarKit.end_window(spec, 0.12, 0.08, 0.1), glass, 0.004, 0.02)
	CarKit.mirrors(b, Vector3(CarKit.side_x(spec, 0.94, 0.8), 1.02, 0.8), paint)
	CarKit.handles(b, CarKit.side_x(spec, 0.9, 0.1), 0.9, [0.1])

	# Round headlights with chrome rings, small grille, round tail lights.
	for side: float in [1.0, -1.0]:
		var c := Vector2(side * 0.56, 0.8)
		CarKit.decal(b, spec, false, "front", _circle(c, 0.12), Mats.chrome(), 0.004)
		CarKit.decal(b, spec, false, "front", _circle(c, 0.095), Mats.glow(Color(1.0, 0.97, 0.88), 2.0), 0.008)
		CarKit.decal(b, spec, false, "front", _circle(c + Vector2(side * 0.0, -0.2), 0.04),
				Mats.glow(Color(1.0, 0.65, 0.15), 1.2), 0.004)
		CarKit.decal(b, spec, false, "back", _circle(Vector2(side * 0.6, 0.86), 0.075),
				Mats.glow(Color(0.9, 0.05, 0.05), 1.3), 0.004, 0.015, true, Mats.chrome())
	CarKit.decal(b, spec, false, "front", CarKit.quad(Vector2(-0.3, 0.52), Vector2(0.3, 0.52), Vector2(0.26, 0.64),
			Vector2(-0.26, 0.64), 0.06), trim, 0.004)
	CarKit.decal(b, spec, false, "front", CarKit.quad(Vector2(-0.9, 0.3), Vector2(0.9, 0.3), Vector2(0.9, 0.42),
			Vector2(-0.9, 0.42), 0.04), Mats.chrome(Color(0.75, 0.76, 0.78)), 0.004)
	CarKit.decal(b, spec, false, "back", CarKit.quad(Vector2(-0.9, 0.32), Vector2(0.9, 0.32), Vector2(0.9, 0.44),
			Vector2(-0.9, 0.44), 0.04), Mats.chrome(Color(0.75, 0.76, 0.78)), 0.004)
	CarKit.plate(b, Vector3(0, 0.5, CarKit.end_z(spec, 0, 0.5) + 0.012), false, "K · LE 500")
	CarKit.plate(b, Vector3(0, 0.62, CarKit.end_z(spec, 0, 0.62, false) - 0.012), true, "K · LE 500")


static func _circle(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts
