class_name TeddyBear
extends Node3D
## A cute bear standing on its hind legs, like a teddy. About 0.6 m tall.
## Styles: PLUSH (classic teddy with bow tie), VINYL (chibi toy hugging a honey pot),
## LOW_POLY (faceted forest bear with scarf, waving).

@export_enum("Plüsch", "Vinyl", "Low-Poly") var style := 0


func _ready() -> void:
	if get_child_count() == 0:
		build()


func build() -> void:
	var b := Builder.new(self)
	var flat := CuteParts.is_flat(style)
	var fur_col: Color = [Color(0.66, 0.43, 0.22), Color(0.88, 0.62, 0.34), Color(0.45, 0.29, 0.18)][style]
	var light_col: Color = [Color(0.93, 0.8, 0.6), Color(1.0, 0.9, 0.74), Color(0.82, 0.66, 0.48)][style]
	var fur := CuteParts.fur(style, fur_col)
	var light := CuteParts.fur(style, light_col)
	var dark := Mats.plastic(Color(0.1, 0.06, 0.05), 0.2)

	# Proportions: the vinyl figure has a much bigger head, the low-poly bear a pear-shaped body.
	var head_r: float = [0.15, 0.2, 0.14][style]
	var body: Vector3 = [Vector3(0.155, 0.18, 0.135), Vector3(0.14, 0.14, 0.125), Vector3(0.18, 0.19, 0.155)][style]
	var body_y: float = [0.29, 0.25, 0.29][style]
	var head_y := body_y + body.y + head_r * 0.72

	# Legs and feet.
	var hip_y := body_y - body.y * 0.55
	var leg_x: float = 0.075 if style != 2 else 0.09
	CuteParts.limb(b, style, fur, PackedVector3Array([Vector3(leg_x, hip_y, 0.0),
			Vector3(leg_x + 0.01, hip_y * 0.55, 0.01), Vector3(leg_x + 0.013, 0.06, 0.02)]),
			PackedFloat32Array([0.072, 0.066, 0.062]))
	b.blob_pair(fur, Vector3(leg_x + 0.015, 0.045, 0.045), Vector3(0.065, 0.045, 0.095), Vector3.ZERO, flat)
	b.blob_pair(light, Vector3(leg_x + 0.015, 0.05, 0.128), Vector3(0.045, 0.035, 0.018), Vector3(-15, 0, 0), flat)

	# Body, belly and tail.
	b.blob(fur, Vector3(0, body_y, 0), body, Vector3.ZERO, flat)
	if style == 2:   # pear shape: wider bottom
		b.blob(fur, Vector3(0, body_y - body.y * 0.3, 0), body * Vector3(1.08, 0.7, 1.05), Vector3.ZERO, flat)
	if style != 1:
		var belly_c := Vector3(0, body_y - 0.01 - (0.04 if style == 2 else 0.0), body.z * 0.62)
		b.blob(light, belly_c, Vector3(body.x * 0.68, body.y * 0.75, body.z * 0.45), Vector3.ZERO, flat)
	b.blob(fur if style != 0 else light, Vector3(0, body_y - body.y * 0.6, -body.z * 0.95),
			Vector3.ONE * 0.04, Vector3.ZERO, flat)

	# Arms with paw pads.
	var sh := Vector3(body.x * 0.78, body_y + body.y * 0.55, 0.0)
	for side in [1.0, -1.0]:
		var paw := Vector3(body.x + 0.055, body_y - body.y * 0.25, 0.07)
		var mid := sh.lerp(paw, 0.5) + Vector3(0.03, 0, 0)
		if style == 1:     # hugging the honey pot
			paw = Vector3(0.1, body_y - 0.01, body.z + 0.07)
			mid = sh.lerp(paw, 0.5) + Vector3(0.05, 0, 0.0)
		elif style == 2 and side < 0:   # waving
			paw = Vector3(body.x + 0.12, head_y - 0.02, 0.03)
			mid = Vector3(body.x + 0.13, body_y + body.y * 0.7, 0.03)
		var pts := PackedVector3Array([sh, mid, paw])
		for i in pts.size():
			pts[i].x *= side
		CuteParts.limb(b, style, fur, pts, PackedFloat32Array([0.052, 0.048, 0.05]), false)
		var pad_dir := Vector3(0, 0, 1) if not (style == 2 and side < 0) else Vector3(0, 0.3, 1).normalized()
		if style == 1:
			pad_dir = Vector3(-side, 0, 0.3).normalized()
		var pad_rot := Vector3(0, rad_to_deg(atan2(pad_dir.x, pad_dir.z)), 0)
		b.blob(light, Vector3(paw.x * side, paw.y, paw.z) + pad_dir * 0.042, Vector3(0.032, 0.035, 0.015),
				pad_rot, flat)

	# Head.
	var hc := Vector3(0, head_y, 0.0)
	var head := Vector3(head_r * 1.06, head_r * 0.96, head_r * 0.98)
	b.blob(fur, hc, head, Vector3.ZERO, flat)
	var ear_s: float = [0.36, 0.34, 0.3][style]
	for side in [1.0, -1.0]:
		var ep := hc + Vector3(side * head_r * 0.72, head_r * 0.72, -head_r * 0.08)
		b.blob(fur, ep, Vector3(head_r * ear_s, head_r * ear_s, head_r * 0.2), Vector3(0, 0, -side * 30), flat)
		b.blob(light, ep + Vector3(0, -0.004, head_r * 0.1), Vector3(head_r * ear_s * 0.6, head_r * ear_s * 0.6, head_r * 0.12),
				Vector3(0, 0, -side * 30), flat)
	# Muzzle (longer on the low-poly bear), nose and mouth.
	var mz_r := Vector3(head_r * 0.48, head_r * 0.36, head_r * (0.36 if style != 2 else 0.55))
	var mz := hc + Vector3(0, -head_r * 0.3, head_r * 0.8)
	b.blob(light, mz, mz_r, Vector3.ZERO, flat)
	var nose := CuteParts.on_ellipsoid(mz, mz_r, 0.0, mz_r.y * 0.45)
	b.blob(dark, nose, Vector3(head_r * 0.2, head_r * 0.13, head_r * 0.12), Vector3(10, 0, 0), flat)
	var lw := head_r * 0.02
	var m0 := CuteParts.on_ellipsoid(mz, mz_r, 0.0, mz_r.y * 0.1, lw)
	var m1 := CuteParts.on_ellipsoid(mz, mz_r, 0.0, -mz_r.y * 0.35, lw)
	CuteParts.line(b, style, PackedVector3Array([m0, m1]), lw)
	for side in [1.0, -1.0]:
		CuteParts.line(b, style, PackedVector3Array([m1,
				CuteParts.on_ellipsoid(mz, mz_r, side * mz_r.x * 0.25, -mz_r.y * 0.48, lw),
				CuteParts.on_ellipsoid(mz, mz_r, side * mz_r.x * 0.45, -mz_r.y * 0.3, lw)]), lw)
	# Eyes.
	var eye_r: float = [0.024, 0.045, 0.022][style]
	var ey: float = [0.12, 0.08, 0.14][style]
	var ex: float = [0.36, 0.42, 0.34][style]
	for side in [1.0, -1.0]:
		var dir := Vector3(side * ex, ey, 0.9).normalized()
		var p := hc + Vector3(dir.x * head.x, dir.y * head.y, dir.z * head.z)
		CuteParts.eye(b, style, p, eye_r, dir)
		if style != 0:
			var cd := Vector3(side * 0.62, -0.28, 0.75).normalized()
			CuteParts.blush(b, style, hc + Vector3(cd.x * head.x, cd.y * head.y, cd.z * head.z),
					head_r * (0.16 if style == 1 else 0.12), cd)

	match style:
		0: _bow_tie(b, Vector3(0, body_y + body.y * 0.9, body.z * 0.78))
		1: _honey_pot(b, Vector3(0, body_y - 0.02, body.z + 0.06))
		2: _scarf(b, body_y + body.y * 0.88, body)


func _bow_tie(b: Builder, pos: Vector3) -> void:
	var red := Mats.plush(Color(0.75, 0.07, 0.12), 0.3, Color(0.95, 0.4, 0.45))
	b.group("BowTie", pos, Vector3(-20, 0, 0))
	for side in [1.0, -1.0]:
		b.blob(red, Vector3(side * 0.036, 0, 0), Vector3(0.04, 0.028, 0.016), Vector3(0, 0, side * 8))
	b.blob(red, Vector3(0, 0, 0.004), Vector3(0.016, 0.019, 0.018))
	b.end()


func _honey_pot(b: Builder, pos: Vector3) -> void:
	var pot := Mats.plastic(Color(0.62, 0.36, 0.22), 0.45)
	var honey := Mats.plastic(Color(1.0, 0.66, 0.08), 0.12)
	var prof := PackedVector2Array([Vector2(0, 0), Vector2(0.06, 0.0), Vector2(0.082, 0.04),
			Vector2(0.084, 0.075), Vector2(0.066, 0.112), Vector2(0.072, 0.124), Vector2(0.066, 0.13)])
	var base := pos + Vector3(0, -0.075, 0)
	b.part(MeshGen.lathe(prof, 40), pot, base)
	b.blob(honey, base + Vector3(0, 0.126, 0), Vector3(0.064, 0.018, 0.064))
	b.blob(honey, base + Vector3(0.0, 0.11, 0.068), Vector3(0.016, 0.03, 0.012))
	b.blob(honey, base + Vector3(0.0, 0.082, 0.074), Vector3(0.012, 0.014, 0.01))
	var label := Mats.plastic(Color(1.0, 0.95, 0.82), 0.5)
	b.blob(label, base + Vector3(0, 0.06, 0.07), Vector3(0.042, 0.026, 0.02))
	b.blob(Mats.plastic(Color(0.95, 0.35, 0.4), 0.4), base + Vector3(0, 0.06, 0.087),
			Vector3(0.012, 0.01, 0.006))


func _scarf(b: Builder, y: float, body: Vector3) -> void:
	var red := Mats.facet(Color(0.75, 0.16, 0.14), 0.9)
	var stripe := Mats.facet(Color(0.95, 0.88, 0.75), 0.9)
	var prof := PackedVector2Array()
	var torus_r := body.x * 0.72
	for i in 9:
		var a := TAU * i / 8.0
		prof.append(Vector2(torus_r + cos(a) * 0.03, sin(a) * 0.024))
	b.part(MeshGen.lathe(prof, 10, false, true), red, Vector3(0, y, 0.0))
	b.part(MeshGen.rounded_box(Vector3(0.05, 0.13, 0.02), 0.3, true), red, Vector3(0.06, y - 0.07, body.z * 0.85),
			Vector3(-14, 0, 8))
	b.part(MeshGen.rounded_box(Vector3(0.052, 0.018, 0.022), 0.3, true), stripe, Vector3(0.068, y - 0.11, body.z * 0.86),
			Vector3(-14, 0, 8))
