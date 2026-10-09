class_name Unicorn
extends Node3D
## A cute chibi unicorn on four legs with a rainbow mane. About 0.6 m tall.
## Styles: PLUSH (soft toy with sleepy closed eyes), VINYL (pearly toy figure with big eyes
## and a golden horn), LOW_POLY (faceted lavender unicorn).

@export_enum("Plüsch", "Vinyl", "Low-Poly") var style := 0

const RAINBOW := [Color(1.0, 0.38, 0.6), Color(1.0, 0.62, 0.22), Color(1.0, 0.86, 0.25),
		Color(0.35, 0.82, 0.5), Color(0.3, 0.6, 1.0), Color(0.62, 0.4, 1.0)]


func _ready() -> void:
	if get_child_count() == 0:
		build()


func build() -> void:
	var b := Builder.new(self)
	var flat := CuteParts.is_flat(style)
	var coat_col: Color = [Color(0.98, 0.96, 0.97), Color(1.0, 0.97, 0.99), Color(0.8, 0.7, 0.96)][style]
	var muzzle_col: Color = [Color(1.0, 0.86, 0.9), Color(1.0, 0.88, 0.92), Color(0.98, 0.9, 0.95)][style]
	var coat := CuteParts.fur(style, coat_col)
	var muzzle := CuteParts.fur(style, muzzle_col)
	var hoof := Mats.plastic(Color(0.95, 0.75, 0.45), 0.25) if style == 1 else CuteParts.fur(style, Color(0.75, 0.62, 0.85))
	var gold := Mats.chrome(Color(1.0, 0.8, 0.4)) if style == 1 else CuteParts.fur(style, Color(1.0, 0.85, 0.5))

	var body := Vector3(0.13, 0.12, 0.175)
	var body_y := 0.21
	var head_r: float = [0.14, 0.155, 0.13][style]
	var hc := Vector3(0, body_y + 0.25, body.z * 0.9)

	# Legs with hooves.
	for z in [body.z * 0.55, -body.z * 0.55]:
		for side in [1.0, -1.0]:
			var top := Vector3(side * body.x * 0.55, body_y - body.y * 0.3, z)
			var foot := Vector3(side * body.x * 0.6, 0.05, z + 0.01)
			CuteParts.limb(b, style, coat, PackedVector3Array([top, top.lerp(foot, 0.5), foot]),
					PackedFloat32Array([0.05, 0.042, 0.044]), false)
			var hp := PackedVector2Array([Vector2(0, 0), Vector2(0.05, 0), Vector2(0.051, 0.03),
					Vector2(0.045, 0.05), Vector2(0, 0.055)])
			b.part(MeshGen.lathe(hp, 7 if flat else 24, true, flat), hoof, Vector3(foot.x, 0, foot.z))

	# Body and neck.
	b.blob(coat, Vector3(0, body_y, 0), body, Vector3.ZERO, flat)
	CuteParts.limb(b, style, coat, PackedVector3Array([Vector3(0, body_y + 0.03, body.z * 0.55),
			Vector3(0, body_y + 0.13, body.z * 0.75), hc + Vector3(0, -0.05, -0.04)]),
			PackedFloat32Array([0.075, 0.065, 0.06]), false)

	# Head with muzzle and nostrils.
	var head := Vector3(head_r, head_r * 0.98, head_r * 1.02)
	b.blob(coat, hc, head, Vector3.ZERO, flat)
	var mz := hc + Vector3(0, -head_r * 0.45, head_r * 0.72)
	var mz_r := Vector3(head_r * 0.62, head_r * 0.48, head_r * 0.5)
	b.blob(muzzle, mz, mz_r, Vector3.ZERO, flat)
	for side in [1.0, -1.0]:
		b.blob(Mats.matte(Color(0.85, 0.5, 0.6), 0.6), CuteParts.on_ellipsoid(mz, mz_r, side * mz_r.x * 0.35, mz_r.y * 0.15),
				Vector3(0.008, 0.012, 0.005), Vector3(0, side * 20, 0), flat)
	var lw := head_r * 0.018
	CuteParts.line(b, style, PackedVector3Array([
			CuteParts.on_ellipsoid(mz, mz_r, -mz_r.x * 0.3, -mz_r.y * 0.35, lw),
			CuteParts.on_ellipsoid(mz, mz_r, 0.0, -mz_r.y * 0.5, lw),
			CuteParts.on_ellipsoid(mz, mz_r, mz_r.x * 0.3, -mz_r.y * 0.35, lw)]), lw)

	# Ears.
	for side in [1.0, -1.0]:
		var ep := PackedVector2Array([Vector2(0, 0), Vector2(0.03, 0.0), Vector2(0.028, 0.03),
				Vector2(0.015, 0.06), Vector2(0, 0.075)])
		b.part(MeshGen.lathe(ep, 7 if flat else 20, true, flat), coat,
				hc + Vector3(side * head_r * 0.55, head_r * 0.72, -head_r * 0.15), Vector3(-10, 0, -side * 25),
				Vector3(1, 1, 0.6))

	# Horn: a cone with a spiral ridge.
	var horn_base := hc + Vector3(0, head_r * 0.88, head_r * 0.2)
	b.group("Horn", horn_base, Vector3(18, 0, 0))
	var hl := 0.13
	b.part(MeshGen.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.026, 0), Vector2(0.0, hl)]),
			7 if flat else 24, true, flat), gold)
	var spiral := PackedVector3Array()
	var sr := PackedFloat32Array()
	for i in 41:
		var t := float(i) / 40.0
		var a := t * TAU * 3.0
		var r := 0.026 * (1.0 - t)
		spiral.append(Vector3(cos(a) * r, t * hl * 0.95, sin(a) * r))
		sr.append(0.006 * (1.0 - t * 0.8))
	b.part(MeshGen.tube(spiral, sr, 5 if flat else 8, true, flat), gold)
	b.end()

	# Eyes.
	for side in [1.0, -1.0]:
		var dir := Vector3(side * 0.5, 0.05, 0.86).normalized()
		var p := hc + Vector3(dir.x * head.x, dir.y * head.y, dir.z * head.z)
		if style == 0:
			_sleepy_eye(b, p, dir, head_r)
		else:
			CuteParts.eye(b, style, p, [0, 0.042, 0.022][style], dir)
			_lashes(b, p, dir, [0.0, 0.042, 0.022][style], side)
		var cd := Vector3(side * 0.7, -0.3, 0.64).normalized()
		CuteParts.blush(b, style, hc + Vector3(cd.x * head.x, cd.y * head.y, cd.z * head.z) * 1.0,
				head_r * 0.15, cd)

	_mane(b, hc, head_r, Vector3(0, body_y + body.y * 0.95, body.z * 0.2))
	_tail(b, Vector3(0, body_y + 0.05, -body.z * 0.95))
	if style == 1:
		_star(b, Vector3(body.x * 0.98, body_y + 0.02, -body.z * 0.45))


func _hair(color_index: int) -> Material:
	var c: Color = RAINBOW[color_index % RAINBOW.size()]
	match style:
		0: return Mats.plush(c, 0.5)
		1: return Mats.plastic(c, 0.25)
		_: return Mats.facet(c, 0.85)


## Mane: thick rainbow locks along the crest from the forehead down the neck, swept to the
## model's left (+X), plus a forelock next to the horn.
func _mane(b: Builder, hc: Vector3, head_r: float, withers: Vector3) -> void:
	var flat := CuteParts.is_flat(style)
	var crest := MeshGen.smooth_path(PackedVector3Array([hc + Vector3(0, head_r * 0.92, -head_r * 0.15),
			hc + Vector3(0, head_r * 0.7, -head_r * 0.75), hc.lerp(withers, 0.55) + Vector3(0, 0.02, -0.03),
			withers]), 6)
	var count := 9
	for i in count:
		var t := float(i) / (count - 1)
		var root := crest[int(t * (crest.size() - 1))]
		var length := lerpf(0.11, 0.17, sin(t * PI))
		var pts := PackedVector3Array([root + Vector3(-0.015, 0.01, 0), root + Vector3(0.03, 0.02, -0.01),
				root + Vector3(0.06, -length * 0.45, -0.02), root + Vector3(0.055, -length, 0.0),
				root + Vector3(0.03, -length * 1.05, 0.015)])
		_lock(b, pts, 0.042 - t * 0.01, i, flat)
		if i % 2 == 0:   # shorter locks on the other side
			var other := PackedVector3Array([root + Vector3(0.01, 0.01, 0), root + Vector3(-0.035, 0.0, -0.01),
					root + Vector3(-0.05, -length * 0.4, 0.0), root + Vector3(-0.035, -length * 0.6, 0.015)])
			_lock(b, other, 0.032, i + 3, flat)
	# Forelock falling forward beside the horn.
	var top := hc + Vector3(0, head_r * 0.95, 0.0)
	_lock(b, PackedVector3Array([top + Vector3(0, 0, -0.02), top + Vector3(0.03, 0.03, 0.03),
			top + Vector3(0.07, -0.02, 0.07), top + Vector3(0.075, -0.07, 0.06)]), 0.03, 0, flat)
	_lock(b, PackedVector3Array([top + Vector3(0, 0, -0.02), top + Vector3(-0.025, 0.03, 0.03),
			top + Vector3(-0.055, -0.0, 0.07), top + Vector3(-0.06, -0.04, 0.07)]), 0.026, 4, flat)


func _lock(b: Builder, pts: PackedVector3Array, r: float, color_index: int, flat: bool) -> void:
	var path := MeshGen.smooth_path(pts, 3 if flat else 6)
	var radii := PackedFloat32Array()
	for k in path.size():
		var u := float(k) / (path.size() - 1)
		radii.append(r * (1.0 - u * 0.75) * (1.0 + sin(u * PI) * 0.25))
	b.part(MeshGen.tube(path, radii, 6 if flat else 14, true, flat), _hair(color_index))


func _tail(b: Builder, root: Vector3) -> void:
	var flat := CuteParts.is_flat(style)
	for i in 6:
		var off := (i - 2.5) * 0.012
		var path := MeshGen.smooth_path(PackedVector3Array([root, root + Vector3(off, 0.04, -0.06),
				root + Vector3(off * 1.6, -0.05, -0.12), root + Vector3(off * 2.0, -0.16, -0.1),
				root + Vector3(off * 2.2, -0.2, -0.06)]), 3 if flat else 6)
		var radii := PackedFloat32Array()
		for k in path.size():
			var u := float(k) / (path.size() - 1)
			radii.append(0.036 * (1.0 - u * 0.65) * (1.0 + sin(u * PI) * 0.4))
		b.part(MeshGen.tube(path, radii, 6 if flat else 12, true, flat), _hair(i * 2 + 1))


func _sleepy_eye(b: Builder, p: Vector3, dir: Vector3, head_r: float) -> void:
	var right := Vector3.UP.cross(dir).normalized()
	var up := dir.cross(right).normalized()
	var w := head_r * 0.2
	var pts := PackedVector3Array()
	for i in 5:
		var t := float(i) / 4.0 * 2.0 - 1.0
		pts.append(p + right * t * w + up * (-(1.0 - t * t) * w * 0.45) + dir * 0.004)
	CuteParts.line(b, style, pts, head_r * 0.025, Color(0.25, 0.15, 0.2))
	for k in 2:
		var s := right * (-0.5 + k) * w
		var base := p + s + up * (-w * 0.38) + dir * 0.004
		CuteParts.line(b, style, PackedVector3Array([base, base - up * w * 0.3 + dir * 0.006]),
				head_r * 0.018, Color(0.25, 0.15, 0.2))


func _lashes(b: Builder, p: Vector3, dir: Vector3, r: float, side: float) -> void:
	var right := Vector3.UP.cross(dir).normalized()
	var up := dir.cross(right).normalized()
	for k in 3:
		var a := deg_to_rad(40.0 + k * 25.0)
		var outward := right * side
		var base := p + (outward * cos(a) * 0.85 + up * sin(a) * 1.1) * r - dir * r * 0.1
		var tip := base + (outward * cos(a) + up * sin(a) * 1.3).normalized() * r * 0.5 + dir * r * 0.05
		CuteParts.line(b, style, PackedVector3Array([base, tip]), r * 0.08, Color(0.1, 0.06, 0.08))


func _star(b: Builder, pos: Vector3) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := PI / 2.0 + TAU * i / 10.0
		var r := 0.035 if i % 2 == 0 else 0.015
		pts.append(Vector2(cos(a), sin(a)) * r)
	b.part(MeshGen.extrude(pts, 0.01, 0.003, true), Mats.plastic(Color(1.0, 0.75, 0.3), 0.25), pos,
			Vector3(0, 90, 0))
