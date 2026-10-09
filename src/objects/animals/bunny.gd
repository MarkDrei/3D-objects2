class_name Bunny
extends Node3D
## A cute bunny sitting upright. About 0.4 m tall including the ears.
## Styles: PLUSH (cream lop-eared bunny with a ribbon), VINYL (pastel toy with a carrot),
## LOW_POLY (faceted wild hare with upright ears).

@export_enum("Plüsch", "Vinyl", "Low-Poly") var style := 0


func _ready() -> void:
	if get_child_count() == 0:
		build()


func build() -> void:
	var b := Builder.new(self)
	var flat := CuteParts.is_flat(style)
	var fur_col: Color = [Color(0.96, 0.92, 0.84), Color(0.98, 0.9, 0.93), Color(0.62, 0.52, 0.42)][style]
	var light_col: Color = [Color(1.0, 0.98, 0.95), Color(1.0, 1.0, 1.0), Color(0.93, 0.88, 0.8)][style]
	var pink_col := Color(1.0, 0.68, 0.74)
	var fur := CuteParts.fur(style, fur_col)
	var light := CuteParts.fur(style, light_col)
	var pink := CuteParts.fur(style, pink_col)

	var head_r: float = [0.1, 0.125, 0.09][style]
	var body := Vector3(0.105, 0.12, 0.11) if style != 1 else Vector3(0.095, 0.1, 0.1)
	var body_y := body.y * 0.95
	var head_y := body_y + body.y * 0.85 + head_r * 0.8
	var head_z := 0.025

	# Body with a light chest, big hind legs and long feet.
	b.blob(fur, Vector3(0, body_y, 0), body, Vector3(-8, 0, 0), flat)
	b.blob(light, Vector3(0, body_y + 0.01, body.z * 0.6), Vector3(body.x * 0.62, body.y * 0.7, body.z * 0.42),
			Vector3.ZERO, flat)
	b.blob_pair(fur, Vector3(body.x * 0.72, body.y * 0.55, -0.01), Vector3(0.055, 0.07, 0.085), Vector3.ZERO, flat)
	b.blob_pair(fur, Vector3(body.x * 0.78, 0.022, 0.06), Vector3(0.036, 0.024, 0.075), Vector3.ZERO, flat)
	b.blob_pair(pink if style != 2 else light, Vector3(body.x * 0.78, 0.022, 0.132),
			Vector3(0.022, 0.015, 0.008), Vector3.ZERO, flat)
	# Tail.
	var tail_r := 0.042
	b.blob(light, Vector3(0, 0.06, -body.z * 0.98), Vector3.ONE * tail_r, Vector3.ZERO, flat)

	# Front paws: down to the ground, or holding the carrot.
	for side in [1.0, -1.0]:
		var top := Vector3(side * body.x * 0.5, body_y + body.y * 0.45, body.z * 0.55)
		var paw := Vector3(side * body.x * 0.42, 0.025, body.z * 0.95)
		if style == 1:
			paw = Vector3(side * 0.035, body_y + 0.0, body.z + 0.03)
		CuteParts.limb(b, style, fur, PackedVector3Array([top, top.lerp(paw, 0.5) + Vector3(side * 0.012, 0, 0.012), paw]),
				PackedFloat32Array([0.03, 0.026, 0.026]), false)

	# Head with cheeks.
	var hc := Vector3(0, head_y, head_z)
	var head := Vector3(head_r * 1.08, head_r * 0.95, head_r)
	b.blob(fur, hc, head, Vector3.ZERO, flat)
	for side in [1.0, -1.0]:
		b.blob(light, hc + Vector3(side * head_r * 0.32, -head_r * 0.38, head_r * 0.62),
				Vector3(head_r * 0.36, head_r * 0.28, head_r * 0.3), Vector3.ZERO, flat)
	# Nose, mouth, teeth.
	var nose := hc + Vector3(0, -head_r * 0.2, head_r * 0.97)
	b.blob(Mats.plastic(Color(1.0, 0.5, 0.6), 0.3), nose, Vector3(head_r * 0.13, head_r * 0.09, head_r * 0.08),
			Vector3.ZERO, flat)
	var lw := head_r * 0.02
	var m1 := CuteParts.on_ellipsoid(hc, head, 0.0, -head_r * 0.32, lw)
	CuteParts.line(b, style, PackedVector3Array([CuteParts.on_ellipsoid(hc, head, 0.0, -head_r * 0.24, lw), m1]), lw)
	for side in [1.0, -1.0]:
		CuteParts.line(b, style, PackedVector3Array([m1,
				CuteParts.on_ellipsoid(hc, head, side * head_r * 0.08, -head_r * 0.37, lw),
				CuteParts.on_ellipsoid(hc, head, side * head_r * 0.15, -head_r * 0.32, lw)]), lw)
	if style == 1:
		b.part(MeshGen.rounded_box(Vector3(head_r * 0.2, head_r * 0.13, head_r * 0.05), 0.35),
				Mats.plastic(Color.WHITE, 0.25), CuteParts.on_ellipsoid(hc, head, 0.0, -head_r * 0.42),
				Vector3(-25, 0, 0))

	# Ears.
	var ear_len: float = [0.13, 0.16, 0.17][style]
	for side in [1.0, -1.0]:
		var root := hc + Vector3(side * head_r * 0.42, head_r * 0.72, -head_r * 0.1)
		var pts: PackedVector3Array
		if style == 0:   # lop ears hanging down at the sides
			pts = PackedVector3Array([root, root + Vector3(side * 0.05, 0.02, 0.0),
					root + Vector3(side * 0.085, -0.04, 0.01), root + Vector3(side * 0.09, -ear_len + 0.01, 0.02)])
		else:
			var tilt := 0.03 if style == 1 else 0.012
			pts = PackedVector3Array([root, root + Vector3(side * tilt * 0.5, ear_len * 0.5, -0.01),
					root + Vector3(side * tilt * 1.6, ear_len, -0.025 if style == 1 else 0.0)])
		_ear(b, fur, pink, pts, head_r * (0.3 if style != 2 else 0.26), style == 0, side)

	# Eyes and blush.
	var eye_r: float = [0.018, 0.034, 0.015][style]
	var ex: float = [0.42, 0.45, 0.5][style]
	for side in [1.0, -1.0]:
		var dir := Vector3(side * ex, 0.12, 0.85).normalized()
		CuteParts.eye(b, style, hc + Vector3(dir.x * head.x, dir.y * head.y, dir.z * head.z), eye_r, dir)
		if style != 2:
			var cd := Vector3(side * 0.66, -0.3, 0.7).normalized()
			CuteParts.blush(b, style, hc + Vector3(cd.x * head.x, cd.y * head.y, cd.z * head.z) * 1.02,
					head_r * 0.16, cd)

	match style:
		0: _ribbon(b, hc + Vector3(-head_r * 0.55, head_r * 0.62, head_r * 0.15))
		1: _carrot(b, Vector3(0, body_y + 0.0, body.z + 0.05))


## Flattened ear with a pink inner side.
func _ear(b: Builder, fur: Material, inner: Material, pts: PackedVector3Array, width: float,
		lop: bool, side: float) -> void:
	var flat := CuteParts.is_flat(style)
	var path := MeshGen.smooth_path(pts, 3 if flat else 6)
	var n := path.size()
	var radii := PackedFloat32Array()
	for i in n:
		var t := float(i) / (n - 1)
		radii.append(width * (0.75 + 0.55 * sin(t * PI * 0.9)) * (1.0 - t * 0.3))
	var face := Vector3(side, 0, 0) if lop else Vector3(0, 0, 1)
	var sides := 7 if flat else 16
	b.part(MeshGen.tube(path, radii, sides, true, flat, 0.4, face), fur)
	if lop:   # the inner side faces the head
		return
	var inner_path := PackedVector3Array()
	var inner_r := PackedFloat32Array()
	for i in range(1, n - 1):
		inner_path.append(path[i] + face * width * 0.26)
		inner_r.append(radii[i] * 0.62)
	b.part(MeshGen.tube(inner_path, inner_r, sides, true, flat, 0.35, face), inner)


func _ribbon(b: Builder, pos: Vector3) -> void:
	var blue := Mats.plush(Color(0.45, 0.7, 0.95), 0.3, Color(0.85, 0.95, 1.0))
	b.group("Ribbon", pos, Vector3(0, 0, 25))
	for side in [1.0, -1.0]:
		b.blob(blue, Vector3(side * 0.024, 0, 0), Vector3(0.026, 0.018, 0.011), Vector3(0, 0, side * 10))
	b.blob(blue, Vector3.ZERO, Vector3(0.011, 0.013, 0.013))
	b.end()


func _carrot(b: Builder, pos: Vector3) -> void:
	var orange := Mats.plastic(Color(1.0, 0.5, 0.1), 0.35)
	var green := Mats.plastic(Color(0.35, 0.75, 0.3), 0.4)
	b.group("Carrot", pos, Vector3(-20, 0, -60))
	var prof := PackedVector2Array([Vector2(0, -0.08), Vector2(0.008, -0.07), Vector2(0.018, -0.03),
			Vector2(0.024, 0.02), Vector2(0.022, 0.035), Vector2(0, 0.04)])
	b.part(MeshGen.lathe(prof, 24), orange)
	for i in 3:
		var a := (i - 1) * 25.0
		var leaf_path := PackedVector3Array([Vector3(0, 0.035, 0), Vector3(sin(deg_to_rad(a)) * 0.02, 0.06, 0),
				Vector3(sin(deg_to_rad(a)) * 0.035, 0.085, 0)])
		b.part(MeshGen.tube(MeshGen.smooth_path(leaf_path, 4), PackedFloat32Array([0.007, 0.007, 0.007,
				0.008, 0.008, 0.009, 0.009, 0.008, 0.006]), 8, true, false, 0.5), green)
	b.end()
