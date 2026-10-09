class_name ViewerUI
extends CanvasLayer
## Object list on the left, info card top right, view buttons bottom right.
## Fullscreen mode hides everything except a small "back" button.

signal selected(id: String)
signal fullscreen_toggled
signal reset_pressed
signal rotate_toggled(on: bool)

const ACCENT := Color(0.22, 0.42, 0.85)
const TEXT := Color(0.13, 0.15, 0.2)
const MUTED := Color(0.42, 0.45, 0.52)

var panel: PanelContainer
var tree: Tree
var info: PanelContainer
var title_label: Label
var info_label: Label
var buttons: HBoxContainer
var back_button: Button
var rotate_button: Button
var loading_label: Label
var fullscreen := false

var _items := {}     # id -> TreeItem
var _ids: Array[String] = []
var _silent := false


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _make_theme()
	add_child(root)

	panel = PanelContainer.new()
	panel.name = "ObjectPanel"
	panel.anchor_bottom = 1.0
	panel.offset_left = 12
	panel.offset_top = 12
	panel.offset_right = 12 + 270
	panel.offset_bottom = -12
	root.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	var title := Label.new()
	title.text = "3D-Objekte"
	title.add_theme_font_size_override("font_size", 24)
	vb.add_child(title)
	var sub := Label.new()
	sub.text = "Wähle ein Objekt"
	sub.add_theme_color_override("font_color", MUTED)
	vb.add_child(sub)
	tree = Tree.new()
	tree.name = "ObjectTree"
	tree.hide_root = true
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.item_selected.connect(_on_item_selected)
	vb.add_child(tree)
	var hint := Label.new()
	hint.text = "Ziehen: drehen · Rechts ziehen: verschieben\nMausrad / 2 Finger: zoomen\nBild auf/ab: anderes Objekt · F: Vollbild"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", MUTED)
	vb.add_child(hint)

	info = PanelContainer.new()
	info.name = "InfoCard"
	info.anchor_left = 1.0
	info.anchor_right = 1.0
	info.offset_left = -12 - 300
	info.offset_right = -12
	info.offset_top = 12
	info.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	root.add_child(info)
	var ivb := VBoxContainer.new()
	info.add_child(ivb)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 20)
	ivb.add_child(title_label)
	info_label = Label.new()
	info_label.add_theme_color_override("font_color", MUTED)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ivb.add_child(info_label)

	buttons = HBoxContainer.new()
	buttons.name = "ViewButtons"
	buttons.anchor_left = 1.0
	buttons.anchor_right = 1.0
	buttons.anchor_top = 1.0
	buttons.anchor_bottom = 1.0
	buttons.offset_right = -12
	buttons.offset_bottom = -12
	buttons.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	buttons.grow_vertical = Control.GROW_DIRECTION_BEGIN
	buttons.add_theme_constant_override("separation", 8)
	root.add_child(buttons)
	rotate_button = _button("Drehen", func() -> void: rotate_toggled.emit(rotate_button.button_pressed))
	rotate_button.toggle_mode = true
	_button("Ansicht zurücksetzen", func() -> void: reset_pressed.emit())
	var fs := _button("Vollbild", func() -> void: fullscreen_toggled.emit())
	fs.name = "FullscreenButton"

	loading_label = Label.new()
	loading_label.text = "Baue Objekt …"
	loading_label.add_theme_font_size_override("font_size", 18)
	loading_label.set_anchors_preset(Control.PRESET_CENTER)
	loading_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	loading_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	loading_label.visible = false
	root.add_child(loading_label)

	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "Zurück (Esc)"
	back_button.position = Vector2(12, 12)
	back_button.visible = false
	back_button.pressed.connect(func() -> void: fullscreen_toggled.emit())
	root.add_child(back_button)


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	buttons.add_child(b)
	return b


## Fills the list from catalog entries, grouped by category.
func set_entries(entries: Array) -> void:
	tree.clear()
	_items.clear()
	_ids.clear()
	var root_item := tree.create_item()
	var cats := {}
	for e in entries:
		var cat: String = e.category
		if not cats.has(cat):
			var c := tree.create_item(root_item)
			c.set_text(0, cat)
			c.set_selectable(0, false)
			c.set_custom_color(0, MUTED)
			c.set_custom_font_size(0, 13)
			cats[cat] = c
		var it := tree.create_item(cats[cat])
		it.set_text(0, e.name)
		it.set_metadata(0, e.id)
		_items[e.id] = it
		_ids.append(e.id)


## Marks `id` as selected without emitting `selected`.
func select(id: String) -> void:
	if not _items.has(id):
		return
	_silent = true
	var it: TreeItem = _items[id]
	it.select(0)
	tree.scroll_to_item(it)
	_silent = false


## Screen rectangle of a list entry (found with the same hit test the Tree uses for clicks).
func item_rect(id: String) -> Rect2:
	var it: TreeItem = _items[id]
	tree.scroll_to_item(it)
	var ys: Array[float] = []
	var y := 0.0
	while y < tree.size.y:
		if tree.get_item_at_position(Vector2(40, y)) == it:
			ys.append(y)
		y += 1.0
	if ys.is_empty():
		return Rect2()
	var origin := tree.get_global_rect().position
	return Rect2(origin + Vector2(0, ys[0]), Vector2(tree.size.x, ys[-1] - ys[0]))


func neighbour(id: String, step: int) -> String:
	var i := _ids.find(id)
	return _ids[wrapi(i + step, 0, _ids.size())]


func set_info(title: String, text: String) -> void:
	title_label.text = title
	info_label.text = text


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	panel.visible = not on
	info.visible = not on
	buttons.visible = not on
	back_button.visible = on


func set_overlay_visible(on: bool) -> void:
	panel.visible = on
	info.visible = on
	buttons.visible = on
	back_button.visible = false


func _on_item_selected() -> void:
	if _silent:
		return
	var it := tree.get_selected()
	if it and it.get_metadata(0) != null:
		selected.emit(String(it.get_metadata(0)))


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 15
	var card := StyleBoxFlat.new()
	card.bg_color = Color(1, 1, 1, 0.86)
	card.set_corner_radius_all(14)
	card.set_content_margin_all(14)
	card.shadow_color = Color(0, 0, 0, 0.08)
	card.shadow_size = 8
	t.set_stylebox("panel", "PanelContainer", card)
	t.set_color("font_color", "Label", TEXT)

	var clear := StyleBoxEmpty.new()
	t.set_stylebox("panel", "Tree", clear)
	t.set_stylebox("focus", "Tree", clear)
	var sel := StyleBoxFlat.new()
	sel.bg_color = ACCENT
	sel.set_corner_radius_all(8)
	t.set_stylebox("selected", "Tree", sel)
	t.set_stylebox("selected_focus", "Tree", sel)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(ACCENT, 0.12)
	hover.set_corner_radius_all(8)
	t.set_stylebox("hovered", "Tree", hover)
	t.set_stylebox("hover", "Tree", hover)
	t.set_color("font_color", "Tree", TEXT)
	t.set_color("font_hovered_color", "Tree", TEXT)
	t.set_color("font_selected_color", "Tree", Color.WHITE)
	t.set_color("guide_color", "Tree", Color(0, 0, 0, 0))
	t.set_color("relationship_line_color", "Tree", Color(0, 0, 0, 0))
	t.set_constant("v_separation", "Tree", 6)
	t.set_constant("item_margin", "Tree", 10)
	t.set_constant("draw_relationship_lines", "Tree", 0)

	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		var b := StyleBoxFlat.new()
		b.bg_color = Color(1, 1, 1, 0.9)
		if state == "hover":
			b.bg_color = Color(0.94, 0.96, 1.0, 0.95)
		if state in ["pressed", "hover_pressed"]:
			b.bg_color = ACCENT
		if state == "focus":
			b = StyleBoxFlat.new()
			b.draw_center = false
		b.set_corner_radius_all(10)
		b.content_margin_left = 16
		b.content_margin_right = 16
		b.content_margin_top = 9
		b.content_margin_bottom = 9
		b.shadow_color = Color(0, 0, 0, 0.08)
		b.shadow_size = 6 if state != "focus" else 0
		t.set_stylebox(state, "Button", b)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", TEXT)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_hover_pressed_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", TEXT)
	return t
