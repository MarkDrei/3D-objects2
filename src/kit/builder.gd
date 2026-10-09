class_name Builder
extends RefCounted
## Composes an object out of mesh parts. Parts are added to the current group; `group()` /
## `end()` nest groups, `mirror()` adds a part and its mirror image across the X = 0 plane.

var root: Node3D
var _parent: Node3D
var _stack: Array[Node3D] = []


func _init(target: Node3D) -> void:
	root = target
	_parent = target


## Adds a mesh part. rot is in degrees (Euler YXZ like Godot's rotation_degrees).
func part(mesh: Mesh, mat: Material, pos := Vector3.ZERO, rot := Vector3.ZERO,
		scl := Vector3.ONE, part_name := "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if mat:
		mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = scl
	if part_name != "":
		mi.name = part_name
	_parent.add_child(mi)
	return mi


## Adds a mesh with one material per surface.
func multi(mesh: Mesh, mats: Array, pos := Vector3.ZERO, rot := Vector3.ZERO,
		scl := Vector3.ONE, part_name := "") -> MeshInstance3D:
	var mi := part(mesh, null, pos, rot, scl, part_name)
	for i in mini(mats.size(), mesh.get_surface_count()):
		mi.set_surface_override_material(i, mats[i])
	return mi


## Adds the part at pos and its mirror image at (-pos.x, pos.y, pos.z).
func mirror(mesh: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO,
		scl := Vector3.ONE) -> Array[MeshInstance3D]:
	return [part(mesh, mat, pos, rot, scl),
		part(mesh, mat, Vector3(-pos.x, pos.y, pos.z), Vector3(rot.x, -rot.y, -rot.z), scl)]


## Adds a mesh built in object space on one side and its reflection across X = 0
## (negative scale; Godot flips the face winding for mirrored instances).
func mirror_mesh(mesh: Mesh, mat: Material) -> Array[MeshInstance3D]:
	return [part(mesh, mat), part(mesh, mat, Vector3.ZERO, Vector3.ZERO, Vector3(-1, 1, 1))]


## Ellipsoid with radii `r` (shares one unit sphere mesh).
func blob(mat: Material, pos: Vector3, r: Vector3, rot := Vector3.ZERO, flat := false,
		detail := 1.0) -> MeshInstance3D:
	var lat := 7 if flat else int(16 * detail)
	var lon := 10 if flat else int(32 * detail)
	return part(MeshGen.sphere(lat, lon, flat), mat, pos, rot, r)


func blob_pair(mat: Material, pos: Vector3, r: Vector3, rot := Vector3.ZERO,
		flat := false) -> Array[MeshInstance3D]:
	var lat := 7 if flat else 16
	var lon := 10 if flat else 32
	return mirror(MeshGen.sphere(lat, lon, flat), mat, pos, rot, r)


## Adds any other node (labels, lights) to the current group.
func node(n: Node3D) -> Node3D:
	_parent.add_child(n)
	return n


## Starts a sub-group (a Node3D) that following parts are added to.
func group(group_name: String, pos := Vector3.ZERO, rot := Vector3.ZERO) -> Node3D:
	var g := Node3D.new()
	g.name = group_name
	g.position = pos
	g.rotation_degrees = rot
	_parent.add_child(g)
	_stack.append(_parent)
	_parent = g
	return g


func end() -> void:
	_parent = _stack.pop_back()
