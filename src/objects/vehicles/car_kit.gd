class_name CarKit
extends RefCounted
## Building blocks for cars: a lofted lower body with wheel arches, a greenhouse (cabin) whose
## faces are split into paint and glass, wheels, lights and small parts.
##
## A car is described by a spec dictionary (metres, +Z = front):
##   length, width        overall size of the lower body
##   axles: [z_front, z_back], wheel_r, wheel_w, track (x of the wheel centre), arch_gap
##   sill                 y of the body bottom
##   top: [Vector2(z, y)] body top line (bumper → hood → belt → trunk), back to front
##   plan: [Vector2(z, half_width)]
##   e, tumble            cross-section roundness (1 = ellipse, 0.3 = boxy), width factor at the top
##   round_front, round_back  length over which the ends are rounded off
##   cabin: {z0, z1, belt, roof: [Vector2(z, y)], half_width, tumble, e, b_pillar: [z, …]}


## Monotone cubic interpolation through keys (Vector2(x, value)), clamped at the ends.
static func curve(keys: Array, x: float) -> float:
	var n := keys.size()
	if x <= keys[0].x:
		return keys[0].y
	if x >= keys[n - 1].x:
		return keys[n - 1].y
	var k := 0
	while keys[k + 1].x < x:
		k += 1
	var p0: Vector2 = keys[k]
	var p1: Vector2 = keys[k + 1]
	var h := p1.x - p0.x
	var t := (x - p0.x) / h
	var t2 := t * t
	var t3 := t2 * t
	return (2 * t3 - 3 * t2 + 1) * p0.y + (t3 - 2 * t2 + t) * h * _tangent(keys, k) \
			+ (-2 * t3 + 3 * t2) * p1.y + (t3 - t2) * h * _tangent(keys, k + 1)


static func _tangent(keys: Array, i: int) -> float:
	var n := keys.size()
	var d0 := NAN
	var d1 := NAN
	if i > 0:
		d0 = (keys[i].y - keys[i - 1].y) / (keys[i].x - keys[i - 1].x)
	if i < n - 1:
		d1 = (keys[i + 1].y - keys[i].y) / (keys[i + 1].x - keys[i].x)
	if is_nan(d0):
		return d1
	if is_nan(d1):
		return d0
	if d0 * d1 <= 0.0:
		return 0.0
	return 2.0 / (1.0 / d0 + 1.0 / d1)   # harmonic mean keeps the curve monotone


## Bottom of the body at z: the sill, raised over the wheels to form the arches.
static func bottom(spec: Dictionary, z: float) -> float:
	var y: float = spec.sill
	var r: float = spec.wheel_r + spec.get("arch_gap", 0.04)
	for az in spec.axles:
		var d: float = absf(z - az)
		if d < r:
			y = maxf(y, spec.wheel_r + sqrt(r * r - d * d) * 0.92)
	return y


static func half_width(spec: Dictionary, z: float) -> float:
	return curve(spec.plan, z)


static func top(spec: Dictionary, z: float) -> float:
	return curve(spec.top, z)


const TAB_STEP := 0.005


## Profiles sampled every 5 mm, so inside tests (used thousands of times by decals) are cheap.
## Built on first use; change the spec before that.
static func _tab(spec: Dictionary) -> Dictionary:
	if spec.has("_tab"):
		return spec._tab
	var l: float = spec.length
	var z0 := -l / 2.0
	var n := int(l / TAB_STEP) + 2
	var rb: float = spec.get("round_back", 0.12)
	var rf: float = spec.get("round_front", 0.12)
	var y0 := PackedFloat32Array()
	var y1 := PackedFloat32Array()
	var hw := PackedFloat32Array()
	var sh := PackedFloat32Array()
	for i in n:
		var z := minf(z0 + i * TAB_STEP, l / 2.0)
		var shrink := 1.0
		if rb > 0.0 and z - z0 < rb:
			var d := 1.0 - (z - z0) / rb
			shrink = sqrt(maxf(1.0 - d * d, 0.0))
		if rf > 0.0 and l / 2.0 - z < rf:
			var d := 1.0 - (l / 2.0 - z) / rf
			shrink = minf(shrink, sqrt(maxf(1.0 - d * d, 0.0)))
		y0.append(bottom(spec, z))
		y1.append(top(spec, z))
		hw.append(half_width(spec, z))
		sh.append(shrink)
	var t := {z0 = z0, n = n, y0 = y0, y1 = y1, hw = hw, shrink = sh}
	if spec.has("cabin"):
		var c: Dictionary = spec.cabin
		var roof := PackedFloat32Array()
		var cn := int((c.z1 - c.z0) / TAB_STEP) + 2
		for i in cn:
			roof.append(maxf(curve(c.roof, minf(c.z0 + i * TAB_STEP, c.z1)), c.belt - 0.08))
		t.cz0 = c.z0
		t.cn = cn
		t.roof = roof
	spec._tab = t
	return t


## True if (x, y) lies inside the body's cross-section at z (end rounding included).
static func inside(spec: Dictionary, x: float, y: float, z: float) -> bool:
	var t := _tab(spec)
	var f: float = (z - t.z0) / TAB_STEP
	if f < 0.0 or f > t.n - 1.001:
		return false
	var i := int(f)
	var a := f - i
	var y0: PackedFloat32Array = t.y0
	var y1: PackedFloat32Array = t.y1
	var lo := lerpf(y0[i], y0[i + 1], a)
	var hi := lerpf(y1[i], y1[i + 1], a)
	var shrink: float = lerpf(t.shrink[i], t.shrink[i + 1], a)
	var hh := (hi - lo) / 2.0 * shrink
	if hh <= 0.0:
		return false
	var cy := (y - (lo + hi) / 2.0) / hh
	if absf(cy) >= 1.0:
		return false
	var e: float = spec.get("e", 0.35)
	var cx := pow(1.0 - pow(absf(cy), 2.0 / e), e / 2.0)
	var w: float = lerpf(t.hw[i], t.hw[i + 1], a) * shrink * lerpf(1.0, spec.get("tumble", 0.9), (cy + 1.0) / 2.0)
	return absf(x) <= w * cx


static func inside_body(spec: Dictionary, p: Vector3) -> bool:
	return inside(spec, p.x, p.y, p.z)


## z of the body surface at (x, y) at the front (or back) end; for placing lights and plates.
static func end_z(spec: Dictionary, x: float, y: float, front := true) -> float:
	var l: float = spec.length
	var z := l / 2.0 if front else -l / 2.0
	var step := -0.005 if front else 0.005
	for i in 400:
		if inside(spec, x, y, z):
			return z
		z += step
	return z


## x of the body side at (y, z).
static func side_x(spec: Dictionary, y: float, z: float) -> float:
	var x := 0.0
	while x < 3.0 and inside(spec, x, y, z):
		x += 0.004
	return x


## The lower body. surface_fn (optional) may split it into more surfaces (stripes, lights).
static func body(b: Builder, spec: Dictionary, mats: Array, surface_fn := Callable()) -> MeshInstance3D:
	var l: float = spec.length
	var section := func(z: float) -> Array:
		return [bottom(spec, z), top(spec, z), half_width(spec, z), spec.get("e", 0.35),
				spec.get("tumble", 0.9)]
	var mesh := MeshGen.loft(-l / 2.0, l / 2.0, section, spec.get("rings", 140), 56,
			spec.get("round_back", 0.12), spec.get("round_front", 0.12), false, surface_fn)
	return b.multi(mesh, mats, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, "Body")


static func _cabin_section(c: Dictionary, z: float) -> Array:
	var belt: float = c.belt
	return [belt - 0.1, maxf(curve(c.roof, z), belt - 0.08), c.half_width, c.get("e", 0.4), c.get("tumble", 0.72)]


## The greenhouse as a painted shell; windows are added with `window()`.
static func cabin(b: Builder, spec: Dictionary, paint: Material) -> MeshInstance3D:
	var c: Dictionary = spec.cabin
	var mesh := MeshGen.loft(c.z0, c.z1, func(z: float) -> Array: return _cabin_section(c, z),
			c.get("rings", 90), 56, 0.0, 0.0)
	return b.part(mesh, paint, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, "Cabin")


static func inside_cabin(spec: Dictionary, p: Vector3) -> bool:
	var t := _tab(spec)
	var f: float = (p.z - t.cz0) / TAB_STEP
	if f < 0.0 or f > t.cn - 1.001:
		return false
	var c: Dictionary = spec.cabin
	var i := int(f)
	var roof: PackedFloat32Array = t.roof
	var sec := [c.belt - 0.1, lerpf(roof[i], roof[i + 1], f - i), c.half_width, c.get("e", 0.4),
			c.get("tumble", 0.72)]
	return _inside_section(sec, 1.0, p.x, p.y)


static func _inside_section(sec: Array, shrink: float, x: float, y: float) -> bool:
	var mid: float = (sec[0] + sec[1]) / 2.0
	var hh: float = (sec[1] - sec[0]) / 2.0 * shrink
	if hh <= 0.0:
		return false
	var cy := (y - mid) / hh
	if absf(cy) >= 1.0:
		return false
	var e: float = sec[3]
	var cx := pow(1.0 - pow(absf(cy), 2.0 / e), e / 2.0)
	var w: float = sec[2] * shrink * lerpf(1.0, sec[4], (cy + 1.0) / 2.0)
	return absf(x) <= w * cx


## A decal on the cabin or body. view: "left" (+X side, also mirrored to the right),
## "front" or "back"; outline in (z, y) for sides, (x, y) for front/back.
## frame > 0 adds a black frame of that width around it.
static func decal(b: Builder, spec: Dictionary, on_cabin: bool, view: String, outline: PackedVector2Array,
		mat: Material, lift := 0.004, frame := 0.0, mirror := true, frame_mat: Material = null) -> void:
	var fn := (func(p: Vector3) -> bool: return inside_cabin(spec, p)) if on_cabin \
			else (func(p: Vector3) -> bool: return inside_body(spec, p))
	outline = ccw(outline)
	var layers := []
	if frame > 0.0:
		var outer: Array = Geometry2D.offset_polygon(outline, frame, Geometry2D.JOIN_ROUND)
		if not outer.is_empty():
			layers.append([outer[0], frame_mat if frame_mat else Mats.plastic(Color(0.03, 0.03, 0.035), 0.35), lift])
	layers.append([outline, mat, lift + (0.003 if frame > 0.0 else 0.0)])
	for layer in layers:
		var mesh: ArrayMesh
		# Start the projection just outside the part, so few steps are needed to reach it.
		var c: Dictionary = spec.cabin
		var hw: float = (c.half_width if on_cabin else spec.width / 2.0) + 0.08
		var zc: float = (c.z0 + c.z1) / 2.0 if on_cabin else 0.0
		var hl: float = ((c.z1 - c.z0) / 2.0 if on_cabin else spec.length / 2.0) + 0.08
		var poly: PackedVector2Array = layer[0]
		var lo := poly[0]
		var hi := poly[0]
		for p in poly:
			lo = lo.min(p)
			hi = hi.max(p)
		var spacing := clampf(minf(hi.x - lo.x, hi.y - lo.y) / 5.0, 0.012, 0.05)
		# Windows on raked or curved glass are hit at a flat angle; only body decals need the
		# stricter limit that keeps them from smearing around the rounded ends.
		var facing := 0.08 if on_cabin else 0.3
		match view:
			"left":
				mesh = MeshGen.decal(fn, poly, Vector3.ZERO, Vector3(0, 0, 1), Vector3(0, 1, 0),
						Vector3(-1, 0, 0), layer[2], spacing, hw, facing)
			"front":
				mesh = MeshGen.decal(fn, poly, Vector3(0, 0, zc), Vector3(1, 0, 0), Vector3(0, 1, 0),
						Vector3(0, 0, -1), layer[2], spacing, hl, facing)
			"back":
				mesh = MeshGen.decal(fn, poly, Vector3(0, 0, zc), Vector3(1, 0, 0), Vector3(0, 1, 0),
						Vector3(0, 0, 1), layer[2], spacing, hl, facing)
			"top":
				mesh = MeshGen.decal(fn, poly, Vector3(0, 1.6, 0), Vector3(1, 0, 0), Vector3(0, 0, -1),
						Vector3(0, -1, 0), layer[2], spacing, 1.6, facing)
		if mesh == null:
			continue
		if view == "left" and mirror:
			b.mirror_mesh(mesh, layer[1])
		else:
			b.part(mesh, layer[1])


## Side window outline (z, y) between z_back and z_front, following the roof line `inset` below
## it, from just above the belt line. Rounded corners.
static func side_window(spec: Dictionary, z_back: float, z_front: float, inset := 0.07,
		top_cut := 0.0, corner := 0.05) -> PackedVector2Array:
	var c: Dictionary = spec.cabin
	var y0: float = c.belt + 0.035
	var roof_top := 0.0
	for k in c.roof:
		roof_top = maxf(roof_top, k.y)
	var y_cap := roof_top - (top_cut if top_cut > 0.0 else inset)
	var top_pts := PackedVector2Array()
	var steps := 24
	for i in steps + 1:
		var z := lerpf(z_back, z_front, float(i) / steps)
		var y := minf(curve(c.roof, z) - inset, y_cap)
		if y > y0 + 0.04:
			top_pts.append(Vector2(z, y))
	if top_pts.size() < 2:
		return PackedVector2Array()
	var poly := PackedVector2Array([Vector2(top_pts[0].x, y0), Vector2(top_pts[-1].x, y0)])
	top_pts.reverse()
	poly.append_array(top_pts)
	return MeshGen.rounded_polygon(_simplify(poly), corner)


## Windscreen / rear window outline (x, y): the cabin's cross-section narrowed by `inset`.
static func end_window(spec: Dictionary, inset := 0.08, bottom_gap := 0.04, top_gap := 0.06) -> PackedVector2Array:
	var c: Dictionary = spec.cabin
	var roof_top := 0.0
	var roof_z := 0.0
	for k in c.roof:
		if k.y > roof_top:
			roof_top = k.y
			roof_z = k.x
	var sec := _cabin_section(c, roof_z)
	var y0: float = c.belt + bottom_gap
	var y1: float = roof_top - top_gap
	var right := PackedVector2Array()
	for i in 13:
		var y := lerpf(y0, y1, float(i) / 12.0)
		var x := 0.0
		while x < 3.0 and _inside_section(sec, 1.0, x, y):
			x += 0.005
		right.append(Vector2(maxf(x - inset, 0.05), y))
	var poly := PackedVector2Array()
	for i in range(right.size() - 1, -1, -1):
		poly.append(Vector2(-right[i].x, right[i].y))
	poly.append_array(right)
	return ccw(MeshGen.rounded_polygon(_simplify(ccw(poly)), 0.05))


## Drops points closer than 1 cm to their predecessor.
static func _simplify(poly: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		if out.is_empty() or out[-1].distance_to(p) > 0.01:
			out.append(p)
	if out.size() > 2 and out[0].distance_to(out[-1]) < 0.01:
		out.remove_at(out.size() - 1)
	return out


static func ccw(poly: PackedVector2Array) -> PackedVector2Array:
	if Geometry2D.is_polygon_clockwise(poly):
		poly.reverse()
	return poly


## Mirror image of a polygon across x = 0 (for front/back decals on the other side).
static func mirror_x(poly: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(Vector2(-p.x, p.y))
	return ccw(out)


## Rounded quad from four corner points.
static func quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, r := 0.03) -> PackedVector2Array:
	return ccw(MeshGen.rounded_polygon(ccw(PackedVector2Array([a, b, c, d])), r))


## Black liners inside the wheel arches (one per wheel, kept below the body's top line).
static func arch_liners(b: Builder, spec: Dictionary) -> void:
	for az in spec.axles:
		var r: float = minf(spec.wheel_r + spec.get("arch_gap", 0.04) * 0.6, top(spec, az) - spec.wheel_r - 0.04)
		var pts := PackedVector2Array()
		for i in 17:
			var a := PI * i / 16.0
			pts.append(Vector2(cos(a) * r, sin(a) * r))
		# Inboard of the tyre: in front of it, it would hide the upper half of the wheel.
		var inner: float = spec.track - spec.wheel_w / 2.0 - 0.01
		var depth := 0.25
		for side: float in [1.0, -1.0]:
			b.part(MeshGen.extrude(pts, depth, 0.0, false), Mats.matte(Color(0.03, 0.03, 0.035), 0.9),
					Vector3(side * (inner - depth / 2.0), spec.wheel_r, az), Vector3(0, 90, 0))


## Four wheels. rim: "alloy", "black", "steel" or "sport".
static func wheels(b: Builder, spec: Dictionary, rim := "alloy", caliper := Color(0.75, 0.1, 0.1)) -> void:
	var r: float = spec.wheel_r
	var w: float = spec.wheel_w
	var rim_r: float = r * spec.get("rim_ratio", 0.66)
	var tire := PackedVector2Array([Vector2(rim_r * 1.02, -w * 0.42), Vector2(r * 0.86, -w * 0.5),
			Vector2(r * 0.95, -w * 0.48), Vector2(r * 0.99, -w * 0.4), Vector2(r, -w * 0.25),
			Vector2(r, w * 0.25), Vector2(r * 0.99, w * 0.4), Vector2(r * 0.95, w * 0.48),
			Vector2(r * 0.86, w * 0.5), Vector2(rim_r * 1.02, w * 0.42), Vector2(rim_r * 0.98, 0.0),
			Vector2(rim_r * 1.02, -w * 0.42)])
	var tire_mesh := MeshGen.lathe(tire, 48, false)
	var rim_mat: Material = {"alloy": Mats.alloy(), "black": Mats.plastic(Color(0.06, 0.06, 0.07), 0.3),
			"steel": Mats.plastic(Color(0.55, 0.57, 0.6), 0.45), "sport": Mats.alloy(Color(0.3, 0.31, 0.33))}[rim]
	var face: float = w * 0.3
	var dish := PackedVector2Array([Vector2(0, face + 0.012), Vector2(rim_r * 0.18, face + 0.012),
			Vector2(rim_r * 0.24, face), Vector2(rim_r * 0.3, face - 0.03), Vector2(rim_r * 0.88, face - 0.05),
			Vector2(rim_r * 0.97, face - 0.01), Vector2(rim_r * 1.03, face - 0.02), Vector2(rim_r * 1.03, -w * 0.3),
			Vector2(0, -w * 0.3)])
	var dish_mesh := MeshGen.lathe(dish, 40)
	var star := MeshGen.extrude(_spoke_star(5, rim_r * 0.2, rim_r * 0.98, 0.17, 0.12), 0.03, 0.006, false)
	for az in spec.axles:
		for side: float in [1.0, -1.0]:
			b.group("Wheel", Vector3(side * spec.track, r, az), Vector3(0, 0, -90 * side))
			b.part(tire_mesh, Mats.rubber())
			b.part(dish_mesh, Mats.matte(Color(0.05, 0.05, 0.055), 0.6) if rim != "steel" else rim_mat)
			if rim != "steel":
				b.part(star, rim_mat, Vector3(0, face - 0.01, 0), Vector3(-90, 0, 0))
			if rim == "steel":
				b.part(MeshGen.lathe(PackedVector2Array([Vector2(0, face + 0.02), Vector2(rim_r * 0.45, face + 0.015),
						Vector2(rim_r * 0.5, face - 0.01), Vector2(0, face - 0.01)]), 32), Mats.chrome())
			else:
				b.part(MeshGen.lathe(PackedVector2Array([Vector2(0, face + 0.02), Vector2(rim_r * 0.16, face + 0.016),
						Vector2(rim_r * 0.2, face - 0.01), Vector2(0, face - 0.01)]), 24), rim_mat)
			# Brake disc and caliper behind the spokes.
			b.part(MeshGen.lathe(PackedVector2Array([Vector2(0, face - 0.06), Vector2(rim_r * 0.82, face - 0.06),
					Vector2(rim_r * 0.82, face - 0.075), Vector2(0, face - 0.075)]), 32), Mats.chrome(Color(0.5, 0.5, 0.52)))
			if rim == "sport":
				b.part(MeshGen.rounded_box(Vector3(rim_r * 0.35, 0.05, rim_r * 0.5), 0.4),
						Mats.plastic(caliper, 0.3), Vector3(rim_r * 0.55, face - 0.05, 0))
			b.end()


## Outline of a spoked wheel face: `n` spokes from the hub radius to the rim, as one
## star-shaped polygon. Widths are angular half-widths (radians) at hub and rim.
static func _spoke_star(n: int, hub: float, outer: float, w_hub: float, w_outer: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(Vector2(cos(a - w_hub * 2.2), sin(a - w_hub * 2.2)) * hub * 0.9)
		pts.append(Vector2(cos(a - w_hub), sin(a - w_hub)) * hub)
		pts.append(Vector2(cos(a - w_outer), sin(a - w_outer)) * outer)
		pts.append(Vector2(cos(a + w_outer), sin(a + w_outer)) * outer)
		pts.append(Vector2(cos(a + w_hub), sin(a + w_hub)) * hub)
	return pts


## A lamp: flattened glowing ellipsoid under a clear cover, facing `facing`.
static func lamp(b: Builder, pos: Vector3, size: Vector3, color: Color, facing: Vector3,
		energy := 2.0, tilt := Vector3.ZERO) -> void:
	var yaw := rad_to_deg(atan2(facing.x, facing.z))
	b.group("Lamp", pos, Vector3(tilt.x, yaw, tilt.z))
	b.blob(Mats.glow(color, energy), Vector3.ZERO, size * Vector3(0.5, 0.5, 0.5))
	b.blob(Mats.clear_glass(Color(1, 1, 1, 0.18)), Vector3(0, 0, size.z * 0.12), size * Vector3(0.56, 0.56, 0.5))
	b.end()


## Licence plate (EU style: blue band at the left).
static func plate(b: Builder, pos: Vector3, facing_back := false, text := "B · OB 3D") -> void:
	b.group("Plate", pos, Vector3(0, 180 if facing_back else 0, 0))
	b.part(MeshGen.rounded_box(Vector3(0.52, 0.12, 0.012), 0.2), Mats.plastic(Color(0.97, 0.97, 0.95), 0.4))
	b.part(MeshGen.rounded_box(Vector3(0.045, 0.11, 0.004), 0.2), Mats.plastic(Color(0.1, 0.25, 0.75), 0.4),
			Vector3(-0.23, 0, 0.007))
	var label := Label3D.new()
	label.text = text
	label.font_size = 64
	label.pixel_size = 0.0011
	label.modulate = Color(0.05, 0.05, 0.05)
	label.outline_size = 0
	label.position = Vector3(0.02, 0, 0.008)
	label.shaded = true
	label.double_sided = false
	b.node(label)
	b.end()


## Text on a car's side (both sides), e.g. "POLIZEI".
static func side_text(b: Builder, text: String, x: float, y: float, z: float, color: Color,
		size := 0.0028, font_size := 96) -> void:
	for side: float in [1.0, -1.0]:
		var label := Label3D.new()
		label.text = text
		label.font_size = font_size
		label.pixel_size = size
		label.modulate = color
		label.outline_size = 0
		label.double_sided = false
		label.position = Vector3(side * x, y, z)
		label.rotation_degrees = Vector3(0, 90 * side, 0)
		b.node(label)


## Side mirror on both sides, at the front of the side windows.
static func mirrors(b: Builder, pos: Vector3, paint: Material) -> void:
	for side: float in [1.0, -1.0]:
		var p := Vector3(pos.x * side, pos.y, pos.z)
		b.part(MeshGen.rounded_box(Vector3(0.06, 0.03, 0.04), 0.4), Mats.plastic(Color(0.05, 0.05, 0.06), 0.4),
				p + Vector3(-side * 0.05, -0.02, 0))
		b.part(MeshGen.rounded_box(Vector3(0.1, 0.09, 0.07), 0.45), paint, p + Vector3(side * 0.03, 0, 0),
				Vector3(0, side * 10, 0))


## Door handles: small chrome bars on both sides.
static func handles(b: Builder, x: float, y: float, zs: Array) -> void:
	for z in zs:
		for side: float in [1.0, -1.0]:
			b.part(MeshGen.rounded_box(Vector3(0.02, 0.025, 0.13), 0.5), Mats.chrome(), Vector3(side * x, y, z))


## All glass of a greenhouse: side windows between the given [z_back, z_front] pairs, plus
## windscreen and rear window. Extra options: inset, top_cut (see `side_window`), end_top_gap.
static func glazing(b: Builder, spec: Dictionary, sides: Array, front := true, back := true,
		opts := {}) -> void:
	var glass := Mats.glass()
	var inset: float = opts.get("inset", 0.07)
	var top_cut: float = opts.get("top_cut", 0.0)
	for s in sides:
		var poly := side_window(spec, s[0], s[1], inset, top_cut)
		if poly.size() > 2:
			decal(b, spec, true, "left", poly, glass, 0.004, 0.012)
	var gap: float = opts.get("end_top_gap", 0.06)
	if front:
		decal(b, spec, true, "front", end_window(spec, 0.08, 0.04, gap), glass, 0.004, 0.012)
	if back:
		decal(b, spec, true, "back", end_window(spec, 0.1, 0.06, opts.get("back_top_gap", gap)), glass,
				0.004, 0.012)


## A tyre with a plain rim, axis along +Z (spare wheels, monster wheels' hub caps).
static func spare_wheel(b: Builder, pos: Vector3, r: float, w: float, cover: Material = null) -> void:
	b.group("SpareWheel", pos, Vector3(90, 0, 0))
	b.part(MeshGen.lathe(PackedVector2Array([Vector2(r * 0.6, -w / 2.0), Vector2(r * 0.95, -w / 2.0),
			Vector2(r, -w * 0.3), Vector2(r, w * 0.3), Vector2(r * 0.95, w / 2.0), Vector2(r * 0.6, w / 2.0)]), 40),
			Mats.rubber())
	if cover:
		b.part(MeshGen.lathe(PackedVector2Array([Vector2(r * 0.9, -w * 0.45), Vector2(r * 0.9, w * 0.4),
				Vector2(r * 0.7, w * 0.6), Vector2(0, w * 0.65)]), 40), cover)
	else:
		b.part(MeshGen.lathe(PackedVector2Array([Vector2(r * 0.62, -w * 0.4), Vector2(r * 0.62, w * 0.3),
				Vector2(r * 0.2, w * 0.4), Vector2(0, w * 0.42)]), 32), Mats.plastic(Color(0.55, 0.57, 0.6), 0.45))
	b.end()


## Tail lights on both sides of the back, pressed into the body at height y (y must lie on the
## body, or pass the back face's z for lights on other parts such as a cabin or tailgate).
static func tail_lights(b: Builder, spec: Dictionary, x: float, y: float, size: Vector3, at_z := NAN) -> void:
	for side: float in [1.0, -1.0]:
		var z := end_z(spec, x, y, false) if is_nan(at_z) else at_z
		lamp(b, Vector3(side * x, y, z + size.z * 0.15), size, Color(0.9, 0.05, 0.04), Vector3(0, 0, -1), 1.6)


## Head lights on both sides of the front.
static func head_lights(b: Builder, spec: Dictionary, x: float, y: float, size: Vector3,
		color := Color(1.0, 0.97, 0.88)) -> void:
	for side: float in [1.0, -1.0]:
		var z := end_z(spec, x, y, true)
		lamp(b, Vector3(side * x, y, z - size.z * 0.15), size, color, Vector3(0, 0, 1), 2.4)


## x of the cabin side at (y, z).
static func cabin_side_x(spec: Dictionary, y: float, z: float) -> float:
	var x := 0.0
	while x < 3.0 and inside_cabin(spec, Vector3(x, y, z)):
		x += 0.004
	return x
