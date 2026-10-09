class_name Person
extends Node3D
## A stylised person (toy figure look: slightly big head, smooth shapes). Roles set clothes,
## hair and accessories: "paramedic", "police", "business", "kid", "grandpa".

@export_enum("paramedic", "police", "business", "kid", "grandpa") var role := "paramedic"

var skin := Color(0.96, 0.78, 0.64)


func _ready() -> void:
	if get_child_count() == 0:
		build()


func build() -> void:
	var b := Builder.new(self)
	var look := _look()
	skin = look.skin
	var s: float = look.scale   # kid is smaller with a bigger head
	var skin_m := Mats.plastic(skin, 0.55)
	var top_m: Material = look.top
	var pants_m: Material = look.pants
	var shoe_m: Material = look.shoes
	var head_r: float = 0.15 * look.head * s

	var hip_y := 0.8 * s
	var shoulder_y := 1.3 * s
	var head_y := shoulder_y + 0.07 * s + head_r * 1.0

	# Shoes and legs.
	for side: float in [1.0, -1.0]:
		b.blob(shoe_m, Vector3(side * 0.105 * s, 0.05 * s, 0.035 * s), Vector3(0.068, 0.058, 0.135) * s)
		b.blob(Mats.matte(Color(0.12, 0.1, 0.1), 0.8), Vector3(side * 0.105 * s, 0.014 * s, 0.035 * s),
				Vector3(0.07, 0.016, 0.138) * s)
		var leg := PackedVector3Array([Vector3(side * 0.105 * s, hip_y - 0.02 * s, 0),
				Vector3(side * 0.105 * s, hip_y * 0.52, 0.01), Vector3(side * 0.105 * s, 0.1 * s, 0.0)])
		_tube(b, leg, PackedFloat32Array([0.095 * s, 0.078 * s, 0.068 * s]), pants_m)
	# Pelvis, torso.
	b.blob(pants_m, Vector3(0, hip_y + 0.02 * s, 0), Vector3(0.2, 0.13, 0.135) * s)
	var torso := MeshGen.lathe(PackedVector2Array([Vector2(0, hip_y - 0.02 * s), Vector2(0.19 * s, hip_y),
			Vector2(0.2 * s, hip_y + 0.18 * s), Vector2(0.215 * s, shoulder_y - 0.14 * s),
			Vector2(0.19 * s, shoulder_y - 0.02 * s), Vector2(0.1 * s, shoulder_y + 0.03 * s),
			Vector2(0, shoulder_y + 0.04 * s)]), 32)
	b.part(torso, top_m, Vector3.ZERO, Vector3.ZERO, Vector3(1, 1, 0.68))
	# Neck and head.
	_tube(b, PackedVector3Array([Vector3(0, shoulder_y, 0), Vector3(0, head_y - head_r * 0.6, 0)]),
			PackedFloat32Array([0.05 * s, 0.045 * s]), skin_m)
	var hc := Vector3(0, head_y, 0.0)
	var head := Vector3(head_r * 0.92, head_r * 1.06, head_r * 0.98)
	b.blob(skin_m, hc, head)
	for side: float in [1.0, -1.0]:
		b.blob(skin_m, hc + Vector3(side * head.x * 0.97, -head_r * 0.05, -head_r * 0.05),
				Vector3(head_r * 0.14, head_r * 0.22, head_r * 0.12))
	_face(b, hc, head, head_r, look)
	_hair(b, hc, head, head_r, look)

	# Arms with hands.
	for side: float in [1.0, -1.0]:
		var sh := Vector3(side * 0.225 * s, shoulder_y - 0.06 * s, 0)
		var elbow := Vector3(side * 0.28 * s, shoulder_y - 0.3 * s, -0.01)
		var wrist := Vector3(side * 0.3 * s, shoulder_y - 0.52 * s, 0.05 * s)
		if side < 0 and look.has("hold"):    # right hand carries something in front
			elbow = Vector3(side * 0.28 * s, shoulder_y - 0.3 * s, 0.03 * s)
			wrist = Vector3(side * 0.24 * s, shoulder_y - 0.42 * s, 0.24 * s)
		_tube(b, PackedVector3Array([sh, elbow, wrist]), PackedFloat32Array([0.075 * s, 0.062 * s, 0.056 * s]),
				look.get("sleeves", top_m))
		b.blob(skin_m, wrist + (wrist - elbow).normalized() * 0.06 * s, Vector3(0.055, 0.065, 0.042) * s,
				Vector3(0, 0, 0))
	_extras(b, look, s, shoulder_y, hip_y, hc, head_r)


func _tube(b: Builder, pts: PackedVector3Array, radii: PackedFloat32Array, mat: Material) -> void:
	var path := MeshGen.smooth_path(pts, 6)
	b.part(MeshGen.tube(path, MeshGen.resample(radii, path.size()), 18, true), mat)


func _look() -> Dictionary:
	match role:
		"paramedic":
			return {skin = Color(0.93, 0.74, 0.6), scale = 1.0, head = 1.0,
				top = Mats.matte(Color(1.0, 0.25, 0.1), 0.7), pants = Mats.matte(Color(0.12, 0.14, 0.2), 0.8),
				shoes = Mats.plastic(Color(0.08, 0.08, 0.09), 0.4), hair = Color(0.3, 0.18, 0.1), hair_style = "short"}
		"police":
			return {skin = Color(0.78, 0.56, 0.42), scale = 1.0, head = 1.0,
				top = Mats.matte(Color(0.1, 0.2, 0.45), 0.8), pants = Mats.matte(Color(0.1, 0.15, 0.33), 0.8),
				shoes = Mats.plastic(Color(0.05, 0.05, 0.06), 0.3), hair = Color(0.1, 0.07, 0.05), hair_style = "short"}
		"business":
			return {skin = Color(0.98, 0.82, 0.7), scale = 0.98, head = 1.0, hold = true,
				top = Mats.matte(Color(0.22, 0.24, 0.3), 0.6), pants = Mats.matte(Color(0.22, 0.24, 0.3), 0.6),
				shoes = Mats.plastic(Color(0.35, 0.12, 0.08), 0.25), hair = Color(0.85, 0.62, 0.3), hair_style = "long"}
		"kid":
			return {skin = Color(0.98, 0.8, 0.66), scale = 0.62, head = 1.25,
				top = Mats.matte(Color(1.0, 0.82, 0.15), 0.7), pants = Mats.matte(Color(0.3, 0.45, 0.8), 0.85),
				shoes = Mats.plastic(Color(0.9, 0.2, 0.25), 0.4), hair = Color(0.55, 0.3, 0.12), hair_style = "cap"}
		_:
			return {skin = Color(0.95, 0.78, 0.68), scale = 0.97, head = 1.0, hold = true,
				top = Mats.matte(Color(0.45, 0.52, 0.38), 0.85), pants = Mats.matte(Color(0.55, 0.48, 0.4), 0.85),
				shoes = Mats.plastic(Color(0.3, 0.18, 0.1), 0.4), hair = Color(0.9, 0.9, 0.9), hair_style = "hat"}


func _face(b: Builder, hc: Vector3, head: Vector3, r: float, look: Dictionary) -> void:
	var eye_m := Mats.plastic(Color(0.06, 0.05, 0.05), 0.15)
	for side: float in [1.0, -1.0]:
		var dir := Vector3(side * 0.36, 0.08, 0.93).normalized()
		var p := hc + Vector3(dir.x * head.x, dir.y * head.y, dir.z * head.z)
		var yaw := rad_to_deg(atan2(dir.x, dir.z))
		b.blob(eye_m, p, Vector3(r * 0.13, r * 0.17, r * 0.06), Vector3(0, yaw, 0))
		b.blob(Mats.unshaded(Color.WHITE), p + Vector3(-r * 0.04, r * 0.06, r * 0.05), Vector3.ONE * r * 0.04)
		# Eyebrows.
		var bp := CuteParts.on_ellipsoid(hc, head, side * r * 0.36, r * 0.32, r * 0.015)
		var hair_c: Color = look.hair
		CuteParts.line(b, 1, PackedVector3Array([bp + Vector3(-side * r * 0.12, -r * 0.02, 0), bp + Vector3(0, r * 0.02, 0),
				bp + Vector3(side * r * 0.12, -r * 0.0, -r * 0.02)]), r * 0.028, hair_c.darkened(0.2))
	# Nose and smile.
	b.blob(Mats.plastic(skin.darkened(0.06), 0.55), CuteParts.on_ellipsoid(hc, head, 0, -r * 0.12), Vector3(r * 0.11, r * 0.13, r * 0.1))
	var lw := r * 0.022
	CuteParts.line(b, 1, PackedVector3Array([CuteParts.on_ellipsoid(hc, head, -r * 0.2, -r * 0.4, lw),
			CuteParts.on_ellipsoid(hc, head, 0, -r * 0.5, lw), CuteParts.on_ellipsoid(hc, head, r * 0.2, -r * 0.4, lw)]),
			lw, Color(0.5, 0.2, 0.18))
	for side: float in [1.0, -1.0]:
		var cd := Vector3(side * 0.6, -0.3, 0.74).normalized()
		CuteParts.blush(b, 1, hc + Vector3(cd.x * head.x, cd.y * head.y, cd.z * head.z), r * 0.14, cd)


func _hair(b: Builder, hc: Vector3, head: Vector3, r: float, look: Dictionary) -> void:
	var hair_m := Mats.plastic(look.hair, 0.6)
	match look.hair_style:
		"short":
			b.blob(hair_m, hc + Vector3(0, r * 0.22, -r * 0.08), head * Vector3(1.06, 0.86, 1.04))
			b.blob(hair_m, hc + Vector3(r * 0.25, r * 0.68, r * 0.45), Vector3(r * 0.55, r * 0.3, r * 0.4), Vector3(20, 0, -15))
		"long":
			b.blob(hair_m, hc + Vector3(0, r * 0.2, -r * 0.1), head * Vector3(1.1, 0.92, 1.06))
			b.blob(hair_m, hc + Vector3(0, -r * 0.55, -r * 0.45), Vector3(r * 1.05, r * 1.25, r * 0.6))
			for side: float in [1.0, -1.0]:
				b.blob(hair_m, hc + Vector3(side * r * 0.82, -r * 0.5, -r * 0.05), Vector3(r * 0.3, r * 1.0, r * 0.45),
						Vector3(0, 0, side * 6))
			b.blob(hair_m, hc + Vector3(-r * 0.3, r * 0.62, r * 0.58), Vector3(r * 0.62, r * 0.3, r * 0.3), Vector3(25, 0, 18))
		"cap":   # kid with a baseball cap
			b.blob(hair_m, hc + Vector3(0, r * 0.05, -r * 0.12), head * Vector3(1.05, 0.95, 1.0))
			var cap := Mats.plastic(Color(0.2, 0.5, 0.95), 0.5)
			b.blob(cap, hc + Vector3(0, r * 0.38, -r * 0.04), Vector3(r * 1.0, r * 0.78, r * 1.02))
			b.part(MeshGen.superellipsoid(Vector3(r * 0.8, r * 0.06, r * 0.6), 0.6, 1.0), cap,
					hc + Vector3(0, r * 0.55, r * 0.95), Vector3(-12, 0, 0))
			b.blob(Mats.plastic(Color(1, 1, 1), 0.5), hc + Vector3(0, r * 1.15, -r * 0.04), Vector3.ONE * r * 0.1)
		"hat":   # grandpa: grey hair at the sides and a felt hat
			for side: float in [1.0, -1.0]:
				b.blob(hair_m, hc + Vector3(side * r * 0.7, -r * 0.05, -r * 0.3), Vector3(r * 0.35, r * 0.4, r * 0.55))
			b.blob(hair_m, hc + Vector3(0, -r * 0.1, -r * 0.75), Vector3(r * 0.7, r * 0.45, r * 0.3))
			# Moustache.
			for side: float in [1.0, -1.0]:
				b.blob(hair_m, CuteParts.on_ellipsoid(hc, head, side * r * 0.14, -r * 0.3, r * 0.04),
						Vector3(r * 0.18, r * 0.07, r * 0.08), Vector3(0, 0, side * 12))
			var felt := Mats.matte(Color(0.35, 0.28, 0.22), 0.8)
			b.part(MeshGen.lathe(PackedVector2Array([Vector2(0, 0), Vector2(r * 1.55, 0), Vector2(r * 1.6, r * 0.05),
					Vector2(r * 1.0, r * 0.06), Vector2(r * 0.92, r * 0.5), Vector2(r * 0.7, r * 0.62), Vector2(0, r * 0.56)]), 40),
					felt, hc + Vector3(0, r * 0.62, -r * 0.05), Vector3(-6, 0, 0))
			b.part(MeshGen.lathe(PackedVector2Array([Vector2(r * 0.99, 0), Vector2(r * 1.0, r * 0.14),
					Vector2(r * 0.96, r * 0.14), Vector2(r * 0.95, 0)]), 40, true), Mats.matte(Color(0.15, 0.1, 0.08)),
					hc + Vector3(0, r * 0.68, -r * 0.05), Vector3(-6, 0, 0))


func _extras(b: Builder, look: Dictionary, s: float, shoulder_y: float, hip_y: float, hc: Vector3, r: float) -> void:
	match role:
		"paramedic":
			var refl := Mats.chrome(Color(0.85, 0.87, 0.9))
			for y in [hip_y + 0.12, hip_y + 0.2]:
				b.part(MeshGen.lathe(PackedVector2Array([Vector2(0.2, y), Vector2(0.203, y + 0.035)]), 32, false),
						refl, Vector3.ZERO, Vector3.ZERO, Vector3(1.01, 1, 0.7))
			_back_text(b, "NOTARZT", shoulder_y - 0.16, Color(1, 1, 1))
			# Medical bag.
			b.part(MeshGen.rounded_box(Vector3(0.14, 0.22, 0.34), 0.35), Mats.plastic(Color(0.95, 0.3, 0.1), 0.45),
					Vector3(-0.36, 0.52, 0.05))
			b.part(MeshGen.rounded_box(Vector3(0.142, 0.04, 0.12), 0.3), Mats.plastic(Color.WHITE), Vector3(-0.36, 0.56, 0.05))
			b.part(MeshGen.rounded_box(Vector3(0.142, 0.12, 0.04), 0.3), Mats.plastic(Color.WHITE), Vector3(-0.36, 0.56, 0.05))
		"police":
			var cap := Mats.matte(Color(0.08, 0.12, 0.28), 0.6)
			b.part(MeshGen.lathe(PackedVector2Array([Vector2(0, 0), Vector2(r * 1.02, 0), Vector2(r * 1.05, r * 0.3),
					Vector2(r * 1.22, r * 0.55), Vector2(r * 1.18, r * 0.66), Vector2(0, r * 0.62)]), 40), cap,
					hc + Vector3(0, r * 0.45, -r * 0.03), Vector3(-6, 0, 0))
			b.part(MeshGen.lathe(PackedVector2Array([Vector2(r * 1.02, 0), Vector2(r * 1.04, r * 0.18),
					Vector2(r * 1.0, r * 0.18), Vector2(r * 0.99, 0)]), 40, true), Mats.matte(Color(0.95, 0.95, 0.95)),
					hc + Vector3(0, r * 0.47, -r * 0.03), Vector3(-6, 0, 0))
			b.part(MeshGen.superellipsoid(Vector3(r * 0.8, r * 0.05, r * 0.45), 0.6, 1.0),
					Mats.plastic(Color(0.03, 0.03, 0.03), 0.2), hc + Vector3(0, r * 0.42, r * 0.95), Vector3(-18, 0, 0))
			b.blob(Mats.chrome(Color(0.95, 0.8, 0.4)), hc + Vector3(0, r * 0.8, r * 1.06), Vector3(r * 0.14, r * 0.16, r * 0.04))
			b.part(MeshGen.lathe(PackedVector2Array([Vector2(0.197, hip_y + 0.03), Vector2(0.2, hip_y + 0.09)]), 32, false),
					Mats.plastic(Color(0.05, 0.05, 0.05), 0.4), Vector3.ZERO, Vector3.ZERO, Vector3(1.02, 1, 0.72))
			b.part(MeshGen.rounded_box(Vector3(0.08, 0.05, 0.02), 0.4), Mats.chrome(Color(0.8, 0.8, 0.8)),
					Vector3(0, hip_y + 0.06, 0.145))
			_back_text(b, "POLIZEI", shoulder_y - 0.16, Color(1, 1, 1))
			b.blob(Mats.matte(Color(0.95, 0.85, 0.2)), Vector3(0.215, shoulder_y - 0.16, 0.0), Vector3(0.012, 0.05, 0.04))
		"business":
			# Shirt collar and tie.
			b.blob(Mats.matte(Color(0.97, 0.97, 0.98), 0.7), Vector3(0, shoulder_y - 0.02, 0.06), Vector3(0.07, 0.05, 0.05))
			b.part(MeshGen.extrude(PackedVector2Array([Vector2(-0.02, 0), Vector2(0.02, 0), Vector2(0.035, -0.2),
					Vector2(0, -0.24), Vector2(-0.035, -0.2)]), 0.015, 0.003), Mats.plastic(Color(0.7, 0.1, 0.15), 0.5),
					Vector3(0, shoulder_y - 0.03, 0.115), Vector3(-8, 0, 0))
			# Coffee cup in the right hand.
			var cup := PackedVector2Array([Vector2(0, 0), Vector2(0.035, 0), Vector2(0.045, 0.12), Vector2(0.047, 0.125),
					Vector2(0, 0.125)])
			var cup_pos := Vector3(-0.24 * s, shoulder_y - 0.5 * s, 0.33 * s)
			b.part(MeshGen.lathe(cup, 24), Mats.plastic(Color(0.62, 0.42, 0.26), 0.6), cup_pos)
			b.part(MeshGen.lathe(PackedVector2Array([Vector2(0.041, 0.04), Vector2(0.044, 0.09)]), 24, false),
					Mats.matte(Color(0.95, 0.94, 0.9)), cup_pos)
			b.part(MeshGen.lathe(PackedVector2Array([Vector2(0, 0.125), Vector2(0.05, 0.125), Vector2(0.05, 0.14),
					Vector2(0.03, 0.15), Vector2(0, 0.15)]), 24), Mats.plastic(Color(0.95, 0.95, 0.95), 0.4), cup_pos)
			# Briefcase in the left hand.
			b.part(MeshGen.rounded_box(Vector3(0.1, 0.3, 0.42), 0.2), Mats.plastic(Color(0.3, 0.16, 0.08), 0.35),
					Vector3(0.33, 0.5, 0.05))
			b.part(MeshGen.tube(PackedVector3Array([Vector3(0.33, 0.65, -0.05), Vector3(0.33, 0.7, 0.0),
					Vector3(0.33, 0.7, 0.1), Vector3(0.33, 0.65, 0.15)]), PackedFloat32Array([0.012, 0.012, 0.012, 0.012]), 8),
					Mats.chrome(Color(0.85, 0.7, 0.4)))
		"kid":
			# Stripes on the shirt and a balloon on a string.
			for i in 3:
				var y := hip_y + 0.08 * s + i * 0.12 * s
				b.part(MeshGen.lathe(PackedVector2Array([Vector2(0.17 * s, y), Vector2(0.175 * s, y + 0.04 * s)]), 32, false),
						Mats.matte(Color(1, 1, 1), 0.7), Vector3.ZERO, Vector3.ZERO, Vector3(1.02, 1, 0.68))
			var hand := Vector3(0.3 * s, shoulder_y - 0.52 * s - 0.06 * s, 0.07 * s)
			var top := hand + Vector3(0.15, 0.85, -0.05)
			b.part(MeshGen.tube(MeshGen.smooth_path(PackedVector3Array([hand, hand + Vector3(0.05, 0.3, 0.0),
					top + Vector3(0, -0.2, 0), top]), 6), _fill(19, 0.003), 5), Mats.matte(Color(0.9, 0.9, 0.9)))
			b.blob(Mats.paint(Color(0.95, 0.15, 0.25), 0.15, 0.0), top + Vector3(0, 0.17, 0), Vector3(0.14, 0.17, 0.14))
			b.blob(Mats.paint(Color(0.95, 0.15, 0.25), 0.15, 0.0), top + Vector3(0, 0.0, 0), Vector3(0.02, 0.025, 0.02))
		"grandpa":
			# Cane in the right hand, glasses, cardigan buttons.
			var hand := Vector3(-0.24 * s, shoulder_y - 0.42 * s - 0.03, 0.3 * s)
			b.part(MeshGen.tube(PackedVector3Array([hand + Vector3(0.0, 0.03, -0.08), hand + Vector3(0, 0.07, -0.02),
					hand + Vector3(0, 0.05, 0.04), hand, Vector3(hand.x, 0.02, hand.z + 0.05)]),
					PackedFloat32Array([0.015, 0.015, 0.015, 0.015, 0.015]), 10), Mats.plastic(Color(0.35, 0.2, 0.1), 0.4))
			var rim := Mats.chrome(Color(0.3, 0.3, 0.32))
			for side: float in [1.0, -1.0]:
				var gp := CuteParts.on_ellipsoid(hc, Vector3(r * 0.92, r * 1.06, r * 0.98), side * r * 0.34, r * 0.06, r * 0.07)
				b.part(MeshGen.lathe(PackedVector2Array([Vector2(r * 0.17, -0.003), Vector2(r * 0.19, 0.0),
						Vector2(r * 0.17, 0.003)]), 24, false), rim, gp, Vector3(90, side * 20, 0))
			for i in 4:
				b.blob(Mats.plastic(Color(0.9, 0.85, 0.7), 0.3), Vector3(0, hip_y + 0.08 + i * 0.1, 0.122),
						Vector3(0.012, 0.012, 0.006))


func _back_text(b: Builder, text: String, y: float, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 64
	label.pixel_size = 0.0018
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	label.position = Vector3(0, y, -0.15)
	label.rotation_degrees = Vector3(0, 180, 0)
	b.node(label)


static func _fill(n: int, v: float) -> PackedFloat32Array:
	var a := PackedFloat32Array()
	a.resize(n)
	a.fill(v)
	return a
