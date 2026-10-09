class_name CuteParts
extends RefCounted
## Shared parts for cute animals in three styles: PLUSH (soft fabric), VINYL (glossy toy
## figure, big eyes) and LOW_POLY (faceted, matte).

enum Style { PLUSH, VINYL, LOW_POLY }

const STYLE_NAMES := ["Plüsch", "Vinyl", "Low-Poly"]


static func is_flat(style: int) -> bool:
	return style == Style.LOW_POLY


## Fur / skin material for the style.
static func fur(style: int, color: Color) -> Material:
	match style:
		Style.PLUSH:
			return Mats.plush(color)
		Style.VINYL:
			return Mats.plastic(color, 0.32)
		_:
			return Mats.facet(color, 0.9)


## An eye on a head surface at `pos`; `facing` is the outward direction it looks to.
static func eye(b: Builder, style: int, pos: Vector3, r: float, facing: Vector3) -> void:
	var yaw := rad_to_deg(atan2(facing.x, facing.z))
	var pitch := -rad_to_deg(asin(clampf(facing.y, -1.0, 1.0)))
	b.group("Eye", pos, Vector3(pitch, yaw, 0))
	match style:
		Style.PLUSH:   # shiny black button
			b.blob(Mats.plastic(Color(0.03, 0.025, 0.02), 0.12), Vector3.ZERO, Vector3(r, r, r * 0.55))
			b.blob(Mats.unshaded(Color(1, 1, 1, 0.9)), Vector3(-r * 0.35, r * 0.4, r * 0.48),
					Vector3.ONE * r * 0.22)
		Style.VINYL:   # big oval eye with two sparkles
			b.blob(Mats.plastic(Color(0.06, 0.04, 0.05), 0.15), Vector3.ZERO,
					Vector3(r * 0.85, r * 1.1, r * 0.45))
			b.blob(Mats.plastic(Color(0.32, 0.2, 0.14), 0.2), Vector3(0, -r * 0.35, r * 0.2),
					Vector3(r * 0.55, r * 0.45, r * 0.3))
			b.blob(Mats.unshaded(Color.WHITE), Vector3(-r * 0.3, r * 0.4, r * 0.38),
					Vector3(r * 0.32, r * 0.36, r * 0.12))
			b.blob(Mats.unshaded(Color.WHITE), Vector3(r * 0.32, -r * 0.4, r * 0.36),
					Vector3.ONE * r * 0.14)
		_:
			b.blob(Mats.matte(Color(0.05, 0.04, 0.05), 0.5), Vector3.ZERO,
					Vector3(r, r * 1.15, r * 0.5), Vector3.ZERO, true)
			b.blob(Mats.unshaded(Color.WHITE), Vector3(-r * 0.3, r * 0.4, r * 0.42),
					Vector3.ONE * r * 0.25, Vector3.ZERO, true)
	b.end()


## Rosy cheek patch.
static func blush(b: Builder, style: int, pos: Vector3, r: float, facing: Vector3) -> void:
	var yaw := rad_to_deg(atan2(facing.x, facing.z))
	var col := Color(1.0, 0.45, 0.5, 0.55)
	b.blob(Mats.unshaded(col) if style != Style.PLUSH else Mats.plush(Color(1.0, 0.6, 0.62), 0.4),
			pos, Vector3(r, r * 0.6, r * 0.25), Vector3(0, yaw, 0), is_flat(style))


## A thin curved line (mouth, stitches) through `points`.
static func line(b: Builder, style: int, points: PackedVector3Array, width: float,
		color := Color(0.12, 0.07, 0.06)) -> void:
	var path := MeshGen.smooth_path(points, 4 if is_flat(style) else 8)
	var radii := PackedFloat32Array()
	radii.resize(path.size())
	radii.fill(width)
	b.part(MeshGen.tube(path, radii, 5 if is_flat(style) else 8, true, is_flat(style)),
			Mats.matte(color, 0.6))


## Point on the front (+Z) half of an ellipsoid at offsets dx, dy from its centre, pushed out
## by `lift`. Used to place mouths, noses and patches on curved surfaces.
static func on_ellipsoid(center: Vector3, radii: Vector3, dx: float, dy: float, lift := 0.0) -> Vector3:
	var q := 1.0 - pow(dx / radii.x, 2) - pow(dy / radii.y, 2)
	var dz := radii.z * sqrt(maxf(q, 0.0))
	var n := Vector3(dx / (radii.x * radii.x), dy / (radii.y * radii.y), dz / (radii.z * radii.z)).normalized()
	return center + Vector3(dx, dy, dz) + n * lift


## A limb: tube along control points with radii (interpolated).
static func limb(b: Builder, style: int, mat: Material, points: PackedVector3Array,
		radii: PackedFloat32Array, mirror := true) -> void:
	var flat := is_flat(style)
	var path := MeshGen.smooth_path(points, 3 if flat else 6)
	var mesh := MeshGen.tube(path, MeshGen.resample(radii, path.size()), 7 if flat else 18, true, flat)
	if mirror:
		b.mirror_mesh(mesh, mat)
	else:
		b.part(mesh, mat)
