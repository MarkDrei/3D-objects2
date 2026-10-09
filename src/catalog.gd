class_name Catalog
extends RefCounted
## All objects of the gallery. Each entry: id, name (German UI text), category, the object's
## class (a Node3D that builds itself in _ready) and properties set before it enters the tree.


static func entries() -> Array:
	var out := [
		{id = "sedan", name = "Limousine", category = "Fahrzeuge", cls = Sedan, info = "Familienauto"},
		{id = "taxi", name = "Taxi", category = "Fahrzeuge", cls = Sedan, props = {variant = "taxi"},
			info = "Limousine mit Taxischild"},
		{id = "police", name = "Polizei", category = "Fahrzeuge", cls = Sedan, props = {variant = "police"},
			info = "Streifenwagen (Kombi)"},
		{id = "sports_car", name = "Sportwagen", category = "Fahrzeuge", cls = SportsCar, info = "Mittelmotor-Sportwagen"},
		{id = "compact", name = "Kleinwagen", category = "Fahrzeuge", cls = CompactCar, info = "Rundlicher Stadtflitzer"},
		{id = "ambulance", name = "Krankenwagen", category = "Fahrzeuge", cls = Ambulance, info = "Rettungswagen"},
	]
	var styles := CuteParts.STYLE_NAMES
	var roles := [["paramedic", "Notärztin", "Rettungsdienst"], ["police", "Polizist", "Streife"],
			["business", "Geschäftsfrau", "Mit Kaffee und Aktenkoffer"], ["kid", "Kind", "Mit Luftballon"],
			["grandpa", "Opa", "Mit Hut und Stock"]]
	for r in roles:
		out.append({id = "person_" + r[0], name = r[1], category = "Menschen", cls = Person,
				props = {role = r[0]}, info = r[2]})
	var animals := [["bear", "Teddybär", TeddyBear], ["bunny", "Hase", Bunny], ["unicorn", "Einhorn", Unicorn]]
	for a in animals:
		for s in 3:
			out.append({id = "%s_%d" % [a[0], s], name = "%s · %s" % [a[1], styles[s]], category = "Tiere",
					cls = a[2], props = {style = s}, info = "Stil: %s" % styles[s]})
	return out


static func find(id: String) -> Dictionary:
	for e in entries():
		if e.id == id:
			return e
	return {}


static func instantiate(entry: Dictionary) -> Node3D:
	var obj: Node3D = entry.cls.new()
	obj.name = entry.id
	for k in entry.get("props", {}):
		obj.set(k, entry.props[k])
	return obj


## Bounding box of all meshes below `node`, in global space.
static func bounds(node: Node) -> AABB:
	var box := AABB()
	var first := true
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var b := m.global_transform * m.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box
