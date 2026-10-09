class_name MeshGen
extends RefCounted
## Procedural mesh generators. Every shape is a stack of rings (closed loops of points with the
## same point count), closed at the ends by caps. `from_rings` turns such a stack into an
## ArrayMesh with smooth or flat normals, optionally split into several surfaces (materials).
##
## Conventions for all objects: Y up, +Z is the model's front (Godot's MODEL_FRONT), metres,
## origin on the ground under the object's centre.

const FLAT_CAP := "flat"

static var _cache := {}


## Builds a mesh from `rings`. start_cap/end_cap: null (open end), a Vector3 the ring is fanned
## to (smooth), or FLAT_CAP (flat lid with a hard edge). flat: faceted shading.
## surface_fn(center: Vector3, normal: Vector3) -> int puts each triangle into a surface.
static func from_rings(rings: Array, start_cap: Variant = null, end_cap: Variant = null,
		flat := false, surface_fn := Callable()) -> ArrayMesh:
	var n: int = rings[0].size()
	var verts := PackedVector3Array()
	for ring in rings:
		verts.append_array(ring)
	var tris := PackedInt32Array()
	for r in rings.size() - 1:
		for i in n:
			var a := r * n + i
			var b := r * n + (i + 1) % n
			var c := (r + 1) * n + (i + 1) % n
			var d := (r + 1) * n + i
			tris.append_array([a, b, c, a, c, d])
	_add_cap(verts, tris, rings[0], 0, n, start_cap, true)
	_add_cap(verts, tris, rings[-1], (rings.size() - 1) * n, n, end_cap, false)
	return _build(verts, tris, flat, surface_fn)


static func _add_cap(verts: PackedVector3Array, tris: PackedInt32Array, ring: PackedVector3Array,
		base: int, n: int, cap: Variant, is_start: bool) -> void:
	if cap == null:
		return
	var center := Vector3.ZERO
	for p in ring:
		center += p
	center /= n
	if cap is Vector3:
		center = cap
	elif cap == FLAT_CAP:
		base = verts.size()     # own vertices, so the lid gets its own normals
		verts.append_array(ring)
	var ci := verts.size()
	verts.append(center)
	for i in n:
		var a := base + i
		var b := base + (i + 1) % n
		if is_start:
			tris.append_array([b, a, ci])
		else:
			tris.append_array([a, b, ci])


## Orients triangles outwards (positive volume), computes normals and emits Godot's
## clockwise front faces.
static func _build(verts: PackedVector3Array, tris: PackedInt32Array, flat: bool,
		surface_fn: Callable, orient := true) -> ArrayMesh:
	var vol := 0.0
	if orient:
		for t in range(0, tris.size(), 3):
			vol += verts[tris[t]].dot(verts[tris[t + 1]].cross(verts[tris[t + 2]]))
	if vol < 0.0:
		for t in range(0, tris.size(), 3):
			var tmp := tris[t + 1]
			tris[t + 1] = tris[t + 2]
			tris[t + 2] = tmp
	var normals := PackedVector3Array()
	normals.resize(verts.size())
	normals.fill(Vector3.ZERO)
	for t in range(0, tris.size(), 3):
		var a := verts[tris[t]]
		var fn := (verts[tris[t + 1]] - a).cross(verts[tris[t + 2]] - a)
		for k in 3:
			normals[tris[t + k]] += fn
	for i in normals.size():
		normals[i] = normals[i].normalized() if normals[i].length_squared() > 1e-20 else Vector3.UP

	# Group triangles per surface.
	var groups := {}
	for t in range(0, tris.size(), 3):
		var s := 0
		if surface_fn.is_valid():
			var a := verts[tris[t]]
			var b := verts[tris[t + 1]]
			var c := verts[tris[t + 2]]
			s = surface_fn.call((a + b + c) / 3.0, (b - a).cross(c - a).normalized())
		if not groups.has(s):
			groups[s] = PackedInt32Array()
		groups[s].append_array([tris[t], tris[t + 1], tris[t + 2]])

	var mesh := ArrayMesh.new()
	var ids := groups.keys()
	ids.sort()
	for s in range(ids[-1] + 1 if not ids.is_empty() else 0):
		var g: PackedInt32Array = groups.get(s, PackedInt32Array())
		var v := PackedVector3Array()
		var nn := PackedVector3Array()
		var cols := PackedColorArray()
		var idx := PackedInt32Array()
		if g.is_empty():   # keep surface indices stable: add a degenerate triangle
			v.append_array([Vector3.ZERO, Vector3.ZERO, Vector3.ZERO])
			nn.append_array([Vector3.UP, Vector3.UP, Vector3.UP])
			idx.append_array([0, 1, 2])
		elif flat:
			for t in range(0, g.size(), 3):
				var a := verts[g[t]]
				var b := verts[g[t + 1]]
				var c := verts[g[t + 2]]
				var fn := (b - a).cross(c - a).normalized()
				var base := v.size()
				v.append_array([a, c, b])
				nn.append_array([fn, fn, fn])
				# Slight brightness variation per facet (used by Mats.facet).
				var j := 1.0 + (fposmod(sin(a.dot(Vector3(12.99, 78.23, 37.72))) * 43758.55, 1.0) - 0.5) * 0.14
				var fc := Color(j, j, j)
				cols.append_array([fc, fc, fc])
				idx.append_array([base, base + 1, base + 2])
		else:
			var remap := {}
			for t in range(0, g.size(), 3):
				for k in [0, 2, 1]:   # clockwise
					var oi := g[t + k]
					if not remap.has(oi):
						remap[oi] = v.size()
						v.append(verts[oi])
						nn.append(normals[oi])
					idx.append(remap[oi])
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = v
		arrays[Mesh.ARRAY_NORMAL] = nn
		if not cols.is_empty():
			arrays[Mesh.ARRAY_COLOR] = cols
		arrays[Mesh.ARRAY_INDEX] = idx
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _c(w: float, m: float) -> float:
	var c := cos(w)
	return signf(c) * pow(absf(c), m)


static func _s(w: float, m: float) -> float:
	var s := sin(w)
	return signf(s) * pow(absf(s), m)


## Superellipsoid with half extents `radii`. e_v/e_h = 1 is an ellipsoid, smaller values give
## boxier shapes (0.2 ≈ rounded box), larger values pinch.
static func superellipsoid(radii: Vector3, e_v := 1.0, e_h := 1.0, lat := 16, lon := 32,
		flat := false) -> ArrayMesh:
	var key := "se%s_%s_%s_%d_%d_%s" % [radii, e_v, e_h, lat, lon, flat]
	if _cache.has(key):
		return _cache[key]
	var rings := []
	for j in range(1, lat):
		var th := -PI / 2.0 + PI * j / lat
		var ring := PackedVector3Array()
		for i in lon:
			var ph := TAU * i / lon
			ring.append(Vector3(radii.x * _c(th, e_v) * _c(ph, e_h), radii.y * _s(th, e_v),
					radii.z * _c(th, e_v) * _s(ph, e_h)))
		rings.append(ring)
	var mesh := from_rings(rings, Vector3(0, -radii.y, 0), Vector3(0, radii.y, 0), flat)
	_cache[key] = mesh
	return mesh


## Unit sphere (radius 1); scale the instance for ellipsoids.
static func sphere(lat := 16, lon := 32, flat := false) -> ArrayMesh:
	return superellipsoid(Vector3.ONE, 1.0, 1.0, lat, lon, flat)


## Rounded box with full size `size`; roundness 0 (sharp) … 1 (ellipsoid).
static func rounded_box(size: Vector3, roundness := 0.25, flat := false) -> ArrayMesh:
	var e := clampf(roundness, 0.05, 1.0)
	return superellipsoid(size / 2.0, e, e, 20, 40, flat)


## Surface of revolution around the Y axis. profile: points (radius, y) from bottom to top.
## Ends with radius 0 are closed smoothly; other ends get a flat lid if close_ends is true.
static func lathe(profile: PackedVector2Array, sides := 32, close_ends := true,
		flat := false, surface_fn := Callable()) -> ArrayMesh:
	var rings := []
	var start_cap: Variant = null
	var end_cap: Variant = null
	for k in profile.size():
		var p := profile[k]
		if p.x < 1e-5:
			if k == 0:
				start_cap = Vector3(0, p.y, 0)
			elif k == profile.size() - 1:
				end_cap = Vector3(0, p.y, 0)
			continue
		var ring := PackedVector3Array()
		for i in sides:
			var a := TAU * i / sides
			ring.append(Vector3(cos(a) * p.x, p.y, sin(a) * p.x))
		rings.append(ring)
	if close_ends:
		if start_cap == null:
			start_cap = FLAT_CAP
		if end_cap == null:
			end_cap = FLAT_CAP
	return from_rings(rings, start_cap, end_cap, flat, surface_fn)


## Smooth Catmull-Rom curve through `points` with `steps` samples per segment.
static func smooth_path(points: PackedVector3Array, steps := 6) -> PackedVector3Array:
	var out := PackedVector3Array()
	var n := points.size()
	for i in n - 1:
		var p0 := points[maxi(i - 1, 0)]
		var p1 := points[i]
		var p2 := points[i + 1]
		var p3 := points[mini(i + 2, n - 1)]
		for s in steps:
			out.append(p1.cubic_interpolate(p2, p0, p3, float(s) / steps))
	out.append(points[-1])
	return out


## Linear interpolation of `values` (one per control point) onto a path of `count` samples.
static func resample(values: PackedFloat32Array, count: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for i in count:
		var f := float(i) / maxf(count - 1, 1) * (values.size() - 1)
		var k := mini(int(f), values.size() - 2)
		out.append(lerpf(values[k], values[k + 1], f - k) if values.size() > 1 else values[0])
	return out


## Tube along `path` with a radius per path point; round_ends adds half-sphere ends.
## squash scales the cross-section along the frame's second axis (flat tubes, e.g. ears).
static func tube(path: PackedVector3Array, radii: PackedFloat32Array, sides := 16,
		round_ends := true, flat := false, squash := 1.0, up_hint := Vector3.UP) -> ArrayMesh:
	var n := path.size()
	var tangents := PackedVector3Array()
	for i in n:
		var t := path[mini(i + 1, n - 1)] - path[maxi(i - 1, 0)]
		tangents.append(t.normalized())
	# Parallel transport frame.
	var normal := up_hint.cross(tangents[0])
	if normal.length_squared() < 1e-6:
		normal = Vector3.RIGHT.cross(tangents[0])
	normal = normal.normalized()
	var centers := PackedVector3Array()
	var rads := PackedFloat32Array()
	var frames := []
	var add := func(c: Vector3, r: float, t: Vector3, nrm: Vector3) -> void:
		centers.append(c)
		rads.append(r)
		frames.append([nrm, t.cross(nrm).normalized()])
	var t0 := tangents[0]
	if round_ends:
		for k in range(4, 0, -1):
			var a := PI / 2.0 * k / 5.0
			add.call(path[0] - t0 * radii[0] * sin(a), radii[0] * cos(a), t0, normal)
	for i in n:
		if i > 0:
			var axis := tangents[i - 1].cross(tangents[i])
			if axis.length_squared() > 1e-10:
				normal = normal.rotated(axis.normalized(), tangents[i - 1].angle_to(tangents[i]))
		add.call(path[i], radii[i], tangents[i], normal)
	var t1 := tangents[-1]
	if round_ends:
		for k in range(1, 5):
			var a := PI / 2.0 * k / 5.0
			add.call(path[-1] + t1 * radii[-1] * sin(a), radii[-1] * cos(a), t1, normal)
	var rings := []
	for i in centers.size():
		var ring := PackedVector3Array()
		var nrm: Vector3 = frames[i][0]
		var bin: Vector3 = frames[i][1]
		for s in sides:
			var a := TAU * s / sides
			ring.append(centers[i] + (nrm * cos(a) + bin * sin(a) * squash) * rads[i])
		rings.append(ring)
	var start_cap: Variant = path[0] - t0 * radii[0] if round_ends else FLAT_CAP
	var end_cap: Variant = path[-1] + t1 * radii[-1] if round_ends else FLAT_CAP
	return from_rings(rings, start_cap, end_cap, flat)


## Body lofted along Z from z0 to z1. section_fn(z) returns [y_bottom, y_top, half_width,
## exponent, top_scale]: a superellipse cross-section (exponent 1 = ellipse, 0.3 = boxy) whose
## width is scaled by top_scale at the top (tumblehome). round_front/round_back round off the
## ends over that length. Rings are denser towards the ends.
static func loft(z0: float, z1: float, section_fn: Callable, count := 80, ring_n := 40,
		round_back := 0.0, round_front := 0.0, flat := false, surface_fn := Callable()) -> ArrayMesh:
	var rings := []
	for k in count:
		var u := 0.5 - 0.5 * cos(PI * k / (count - 1))
		var z := lerpf(z0, z1, u)
		var sec: Array = section_fn.call(z)
		var y0: float = sec[0]
		var y1: float = sec[1]
		var hw: float = sec[2]
		var e: float = sec[3]
		var top: float = sec[4]
		var shrink := 1.0
		if round_back > 0.0 and z - z0 < round_back:
			var d := 1.0 - (z - z0) / round_back
			shrink = sqrt(maxf(1.0 - d * d, 0.0))
		if round_front > 0.0 and z1 - z < round_front:
			var d := 1.0 - (z1 - z) / round_front
			shrink = minf(shrink, sqrt(maxf(1.0 - d * d, 0.0)))
		shrink = maxf(shrink, 0.02)
		var mid := (y0 + y1) / 2.0
		var hh := (y1 - y0) / 2.0 * shrink
		var ring := PackedVector3Array()
		for i in ring_n:
			var a := TAU * i / ring_n
			var cy := _s(a, e)
			var w := hw * shrink * lerpf(1.0, top, (cy + 1.0) / 2.0)
			ring.append(Vector3(w * _c(a, e), mid + hh * cy, z))
		rings.append(ring)
	return from_rings(rings, _ring_center(rings[0]), _ring_center(rings[-1]), flat, surface_fn)


static func _ring_center(ring: PackedVector3Array) -> Vector3:
	var c := Vector3.ZERO
	for p in ring:
		c += p
	return c / ring.size()


## Polygon with rounded corners (radius r, `steps` points per corner). Counter-clockwise.
static func rounded_polygon(points: PackedVector2Array, r: float, steps := 5) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := points.size()
	for i in n:
		var p := points[i]
		var a := points[(i - 1 + n) % n]
		var c := points[(i + 1) % n]
		var da := (a - p).normalized()
		var dc := (c - p).normalized()
		var rr := minf(r, minf(p.distance_to(a), p.distance_to(c)) * 0.45)
		var p0 := p + da * rr
		var p1 := p + dc * rr
		for k in steps + 1:
			var t := float(k) / steps
			out.append(p0.lerp(p, t).lerp(p.lerp(p1, t), t))   # quadratic Bézier
	return out


## A patch that sits on the surface of a solid, like a decal or sticker. inside_fn(p) -> bool
## describes the solid. `outline` is a polygon in the plane spanned by u_axis and v_axis
## (passing through `origin`); every point is projected along `dir` (pointing into the solid)
## onto the surface and lifted by `lift`. Points that miss the solid are dropped.
static func decal(inside_fn: Callable, outline: PackedVector2Array, origin: Vector3, u_axis: Vector3,
		v_axis: Vector3, dir: Vector3, lift := 0.004, spacing := 0.03, reach := 4.0,
		min_facing := 0.3) -> ArrayMesh:
	# Outline subdivided, plus an interior grid.
	var pts := PackedVector2Array()
	var n := outline.size()
	for i in n:
		var a := outline[i]
		var b := outline[(i + 1) % n]
		var steps := maxi(1, ceili(a.distance_to(b) / spacing))
		for k in steps:
			pts.append(a.lerp(b, float(k) / steps))
	var n_outline := pts.size()
	var lo := outline[0]
	var hi := outline[0]
	for p in outline:
		lo = lo.min(p)
		hi = hi.max(p)
	var gy := lo.y + spacing * 0.5
	while gy < hi.y:
		var gx := lo.x + spacing * 0.5
		while gx < hi.x:
			var q := Vector2(gx, gy)
			if Geometry2D.is_point_in_polygon(q, outline):
				var near := false
				for k in n_outline:
					if pts[k].distance_squared_to(q) < spacing * spacing * 0.16:
						near = true
						break
				if not near:
					pts.append(q)
			gx += spacing
		gy += spacing
	var tri2 := Geometry2D.triangulate_delaunay(pts)
	# Project every point onto the surface.
	var hits := PackedVector3Array()
	var ok := []
	var prev_t := -1.0
	for q in pts:
		var start := origin + u_axis * q.x + v_axis * q.y - dir * reach
		var step := 0.03
		# Neighbouring points hit at similar depths: start a little before the previous hit.
		var t := 0.0
		if prev_t > 0.12 and not inside_fn.call(start + dir * (prev_t - 0.12)):
			t = prev_t - 0.12
		var found := false
		while t < reach * 2.0:
			if inside_fn.call(start + dir * t):
				found = true
				break
			t += step
		if found:
			var t0 := maxf(t - step, 0.0)
			var t1 := t
			for k in 9:
				var m := (t0 + t1) / 2.0
				if inside_fn.call(start + dir * m):
					t1 = m
				else:
					t0 = m
			hits.append(start + dir * (t0 - lift))
			prev_t = t0
		else:
			hits.append(Vector3.ZERO)
		ok.append(found)
	var tris := PackedInt32Array()
	for t in range(0, tri2.size(), 3):
		var i0 := tri2[t]
		var i1 := tri2[t + 1]
		var i2 := tri2[t + 2]
		if not (ok[i0] and ok[i1] and ok[i2]):
			continue
		if not Geometry2D.is_point_in_polygon((pts[i0] + pts[i1] + pts[i2]) / 3.0, outline):
			continue
		var fn := (hits[i1] - hits[i0]).cross(hits[i2] - hits[i0])
		# Skip faces the projection only grazes (they would smear around curved ends).
		if absf(fn.normalized().dot(dir)) < min_facing:
			continue
		if fn.dot(-dir) >= 0.0:
			tris.append_array([i0, i1, i2])
		else:
			tris.append_array([i0, i2, i1])
	if tris.is_empty():
		return null
	return _build(hits, tris, false, Callable(), false)


## Extrudes a closed 2D outline (in the XY plane, counter-clockwise) along Z by `depth`,
## centred on z = 0, with a small bevel. Good for flat parts like signs, ears, fins.
## The lids are fans from the centroid, so the outline must be star-shaped around it.
static func extrude(outline: PackedVector2Array, depth: float, bevel := 0.0, flat := true) -> ArrayMesh:
	var rings := []
	var steps := [[-depth / 2.0, 0.0], [depth / 2.0, 0.0]]
	if bevel > 0.0:
		steps = [[-depth / 2.0, bevel], [-depth / 2.0 + bevel, 0.0], [depth / 2.0 - bevel, 0.0],
				[depth / 2.0, bevel]]
	var c := Vector2.ZERO
	for p in outline:
		c += p
	c /= outline.size()
	for st in steps:
		var ring := PackedVector3Array()
		for p in outline:
			var q: Vector2 = p - (p - c).normalized() * float(st[1])
			ring.append(Vector3(q.x, q.y, st[0]))
		rings.append(ring)
	return from_rings(rings, FLAT_CAP, FLAT_CAP, flat)
