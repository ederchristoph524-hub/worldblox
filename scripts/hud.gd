class_name Hud
extends Control
## Bedienoberfläche im WorldBox-Stil: Reiter, Werkzeugleiste, Hinweise, Meldungen, Fenster.

signal tab_pressed(i: int)
signal tool_pressed(t: Dictionary)
signal back_pressed
signal pause_pressed
signal speed_pressed
signal star_pressed
signal gift_pressed
signal weather_stop
signal brush_changed(i: int)
signal meta_clicked(meta: String)
signal show_ui_pressed

const C_FRAME: Color = Color("#414f3e")
const C_FRAME_HI: Color = Color("#5a6e55")
const C_LINE: Color = Color("#2a3427")
const C_RIM: Color = Color("#151a16")
const C_WELL: Color = Color("#1f2923")
const C_RED: Color = Color("#c74634")
const C_RED_HI: Color = Color("#dc5a40")
const C_RED_DK: Color = Color("#7e241a")
const C_YELLOW: Color = Color("#e8c70a")
const C_ORANGE: Color = Color("#f5a01e")
const C_MUTED: Color = Color("#9db09e")
const C_BLUE: Color = Color("#9fd0ff")
const BTN: int = 43
const GAP: int = 6

var font_bold: FontVariation
var font_cjk: SystemFont
var bar: Panel
var tabs_box: HBoxContainer
var tab_buttons: Array[TabButton] = []
var tools_scroll: ScrollContainer
var tools_box: HBoxContainer
var tool_btns: Dictionary = {}
var fixed_box: HBoxContainer
var back_btn: Button
var pause_btn: Button
var speed_btn: Button
var speed_lbl: Label
var arrow: Button
var hint_box: VBoxContainer
var hint_name: Label
var hint_desc: Label
var hint_t: float = 0.0
var toasts: VBoxContainer
var top_r: VBoxContainer
var gift_btn: Button
var wbox: PanelContainer
var wicon: TextureRect
var brush_box: PanelContainer
var brush_btns: Array[Button] = []
var insp: PanelContainer
var insp_text: RichTextLabel
var insp_btns: HBoxContainer
var insp_head: HBoxContainer
var modal: ColorRect
var modal_panel: PanelContainer
var modal_text: RichTextLabel
var modal_btns: HBoxContainer
var load_screen: ColorRect
var load_label: Label
var load_bar: ProgressBar
var age_lbl: Label
var show_btn: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font_bold = FontVariation.new()
	font_bold.base_font = ThemeDB.fallback_font
	font_bold.variation_embolden = 0.7
	font_cjk = SystemFont.new()
	font_cjk.font_names = PackedStringArray(["Microsoft YaHei", "SimHei", "Noto Sans CJK SC", "Noto Sans SC", "WenQuanYi Micro Hei", "PingFang SC", "Source Han Sans SC"])
	font_cjk.fallbacks = [ThemeDB.fallback_font]
	var th: Theme = Theme.new()
	th.default_font = font_bold
	th.default_font_size = 14
	theme = th
	_build_bar()
	_build_top()
	_build_floaters()
	_build_windows()
	_build_loading()


# ---------------- Stile ----------------

static func sb(bg: Color, border: Color = Color.TRANSPARENT, bw: int = 0, radius: int = 6) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.anti_aliasing = false
	return s


static func well_style(on: bool) -> StyleBoxFlat:
	var s: StyleBoxFlat = sb(C_WELL, C_RED if on else C_RIM, 3 if on else 2, 6)
	if on:
		s.bg_color = Color("#2b3730")
	s.shadow_color = Color(0, 0, 0, 0.0)
	return s


static func red_style() -> StyleBoxFlat:
	var s: StyleBoxFlat = sb(C_RED, C_RED_DK, 2, 6)
	s.border_width_bottom = 4
	return s


func _style_button(b: Button, normal: StyleBox, pressed: StyleBox = null) -> void:
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", pressed if pressed != null else normal)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("disabled", normal)
	b.focus_mode = Control.FOCUS_NONE
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", 34)


func _label(text: String, size: int, col: Color, outline: int = 0, outline_col: Color = Color.BLACK) -> Label:
	var l: Label = Label.new()
	l.text = text
	var ls: LabelSettings = LabelSettings.new()
	ls.font = font_bold
	ls.font_size = size
	ls.font_color = col
	ls.outline_size = outline
	ls.outline_color = outline_col
	l.label_settings = ls
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# ---------------- Leiste ----------------

func _build_bar() -> void:
	bar = Panel.new()
	var st: StyleBoxFlat = sb(C_FRAME, C_RIM, 0, 0)
	st.border_width_top = 2
	bar.add_theme_stylebox_override("panel", st)
	bar.anchor_left = 0.0
	bar.anchor_right = 1.0
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_top = -(BTN * 2 + GAP + 26)
	bar.offset_bottom = 0
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bar)
	# Mäander-Streifen links
	var meander: Control = Control.new()
	meander.position = Vector2(2, 6)
	meander.size = Vector2(6, BTN * 2 + GAP)
	meander.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meander.draw.connect(func() -> void:
		for y: int in range(0, int(meander.size.y), 6):
			meander.draw_rect(Rect2(0, y, 5, 1), Color("#33402f"))
			meander.draw_rect(Rect2(0, y, 1, 4), Color("#33402f"))
			meander.draw_rect(Rect2(3, y + 2, 2, 1), Color("#33402f")))
	bar.add_child(meander)
	# Reiter
	tabs_box = HBoxContainer.new()
	tabs_box.anchor_left = 0.0
	tabs_box.anchor_right = 1.0
	tabs_box.offset_left = 22
	tabs_box.offset_right = -22
	tabs_box.offset_top = -28
	tabs_box.offset_bottom = 2
	tabs_box.add_theme_constant_override("separation", 6)
	tabs_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(tabs_box)
	for i: int in range(6):
		var tb: TabButton = TabButton.new()
		tb.icon_tex = Icons.get_icon("tab%d" % i)
		tb.tooltip_text = Powers.TABS[i]
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.pressed_cb = func() -> void: tab_pressed.emit(i)
		tabs_box.add_child(tb)
		tab_buttons.append(tb)
	# Inhalt
	var row: HBoxContainer = HBoxContainer.new()
	row.position = Vector2(12, 7)
	row.anchor_right = 1.0
	row.offset_left = 12
	row.offset_right = 0
	row.offset_top = 7
	row.offset_bottom = 7 + BTN * 2 + GAP
	row.add_theme_constant_override("separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(row)
	fixed_box = HBoxContainer.new()
	fixed_box.add_theme_constant_override("separation", 7)
	fixed_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(fixed_box)
	back_btn = Button.new()
	back_btn.custom_minimum_size = Vector2(BTN, BTN * 2 + GAP)
	_style_button(back_btn, red_style())
	back_btn.icon = Icons.get_icon("back")
	back_btn.add_theme_constant_override("icon_max_width", 30)
	back_btn.tooltip_text = "Zurück"
	back_btn.pressed.connect(func() -> void: back_pressed.emit())
	fixed_box.add_child(back_btn)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", GAP)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fixed_box.add_child(col)
	pause_btn = _tool_button(Icons.get_icon("pause"), "Pause (Leertaste)")
	pause_btn.pressed.connect(func() -> void: pause_pressed.emit())
	col.add_child(pause_btn)
	speed_btn = _tool_button(Icons.get_icon("speed"), "Zeitgeschwindigkeit (T)")
	speed_btn.pressed.connect(func() -> void: speed_pressed.emit())
	speed_lbl = _label("x1", 12, Color.WHITE, 4, Color.BLACK)
	speed_lbl.position = Vector2(24, 26)
	speed_btn.add_child(speed_lbl)
	col.add_child(speed_btn)
	var sep: Control = _separator()
	row.add_child(sep)
	tools_scroll = ScrollContainer.new()
	tools_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tools_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tools_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	tools_scroll.scroll_deadzone = 8
	tools_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(tools_scroll)
	tools_box = HBoxContainer.new()
	tools_box.add_theme_constant_override("separation", 7)
	tools_box.mouse_filter = Control.MOUSE_FILTER_PASS
	tools_scroll.add_child(tools_box)
	arrow = Button.new()
	arrow.flat = true
	arrow.focus_mode = Control.FOCUS_NONE
	arrow.anchor_left = 1.0
	arrow.anchor_right = 1.0
	arrow.offset_left = -26
	arrow.offset_right = 0
	arrow.offset_top = 0
	arrow.offset_bottom = BTN * 2 + GAP + 14
	arrow.mouse_filter = Control.MOUSE_FILTER_STOP
	arrow.draw.connect(func() -> void:
		var h: float = arrow.size.y
		arrow.draw_rect(Rect2(0, 0, 26, h), Color(C_FRAME, 0.85))
		arrow.draw_rect(Rect2(17, 0, 6, h), Color("#4a5a46"))
		arrow.draw_rect(Rect2(15, 0, 2, h), C_LINE)
		var cy: float = h * 0.5
		arrow.draw_colored_polygon(PackedVector2Array([Vector2(13, cy - 12), Vector2(26, cy), Vector2(13, cy + 12)]), Color("#6b5a00"))
		arrow.draw_colored_polygon(PackedVector2Array([Vector2(13, cy - 11), Vector2(25, cy), Vector2(13, cy + 9)]), C_YELLOW))
	arrow.pressed.connect(func() -> void: tools_scroll.scroll_horizontal += int(tools_scroll.size.x * 0.7))
	bar.add_child(arrow)
	var ver: Label = _label("gu-welt 0.3 · Godot", 10, Color("#7e927f"))
	ver.anchor_left = 1.0
	ver.anchor_right = 1.0
	ver.anchor_top = 1.0
	ver.anchor_bottom = 1.0
	ver.offset_left = -130
	ver.offset_right = -8
	ver.offset_top = -15
	ver.offset_bottom = -2
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bar.add_child(ver)


func _separator() -> Control:
	var s: Control = Control.new()
	s.custom_minimum_size = Vector2(14, 0)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.draw.connect(func() -> void:
		s.draw_rect(Rect2(5, 0, 3, s.size.y), C_LINE)
		s.draw_rect(Rect2(8, 0, 1, s.size.y), Color("#556650")))
	return s


func _tool_button(icon: Texture2D, tip: String, riv: bool = false) -> Button:
	var b: Button = Button.new()
	b.custom_minimum_size = Vector2(BTN, BTN)
	_style_button(b, well_style(false))
	b.icon = icon
	b.tooltip_text = tip
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	if riv:
		b.draw.connect(func() -> void:
			var c: Color = Color("#b83a2c")
			for p: Vector2 in [Vector2(-1, -1), Vector2(BTN - 3, -1), Vector2(-1, BTN - 3), Vector2(BTN - 3, BTN - 3)]:
				b.draw_rect(Rect2(p, Vector2(4, 4)), c))
	return b


func set_tools(tab: int) -> void:
	for i: int in range(tab_buttons.size()):
		tab_buttons[i].active = i == tab
		tab_buttons[i].queue_redraw()
	back_btn.visible = tab >= 0
	for c: Node in tools_box.get_children():
		c.queue_free()
	tool_btns.clear()
	var last_g: int = -1
	var column: VBoxContainer = null
	for t: Dictionary in Powers.TOOLS:
		if int(t["tab"]) != tab:
			continue
		var g: int = int(t["g"])
		if last_g != -1 and g != last_g:
			tools_box.add_child(_separator())
			column = null
		last_g = g
		if column == null or column.get_child_count() >= 2:
			column = VBoxContainer.new()
			column.add_theme_constant_override("separation", GAP)
			column.mouse_filter = Control.MOUSE_FILTER_PASS
			tools_box.add_child(column)
		var b: Button = _tool_button(Icons.get_icon(t["id"]), t["n"], t.get("riv", false))
		var tt: Dictionary = t
		b.pressed.connect(func() -> void: tool_pressed.emit(tt))
		column.add_child(b)
		tool_btns[t["id"]] = b
	tools_scroll.scroll_horizontal = 0
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(26, 0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tools_box.add_child(spacer)


func refresh_tools(active_id: String, weather_type: String) -> void:
	for id: String in tool_btns.keys():
		var t: Dictionary = Powers.tool_by_id(id)
		var on: bool = id == active_id or (t.has("w") and t["w"] == weather_type)
		var b: Button = tool_btns[id]
		var s: StyleBoxFlat = well_style(on)
		b.add_theme_stylebox_override("normal", s)
		b.add_theme_stylebox_override("hover", s)
		b.add_theme_stylebox_override("pressed", s)
	var tl: Dictionary = Powers.tool_by_id(active_id)
	brush_box.visible = not tl.is_empty() and tl["m"] == "paint"


func set_paused(p: bool) -> void:
	pause_btn.icon = Icons.get_icon("play" if p else "pause")
	var s: StyleBoxFlat = well_style(p)
	pause_btn.add_theme_stylebox_override("normal", s)
	pause_btn.add_theme_stylebox_override("hover", s)


func set_speed(x: int) -> void:
	speed_lbl.text = "x%d" % x


func bar_height() -> float:
	if not bar.visible:
		return 0.0
	return BTN * 2 + GAP + 26 + 28


# ---------------- oben ----------------

func _build_top() -> void:
	top_r = VBoxContainer.new()
	top_r.anchor_left = 1.0
	top_r.anchor_right = 1.0
	top_r.offset_left = -56
	top_r.offset_right = -10
	top_r.offset_top = 12
	top_r.add_theme_constant_override("separation", 12)
	top_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_r)
	var star: Button = Button.new()
	star.custom_minimum_size = Vector2(46, 46)
	_style_button(star, red_style())
	star.icon = Icons.get_icon("star")
	star.tooltip_text = "Rangliste der Stärksten"
	star.pressed.connect(func() -> void: star_pressed.emit())
	top_r.add_child(star)
	gift_btn = Button.new()
	gift_btn.custom_minimum_size = Vector2(46, 46)
	_style_button(gift_btn, red_style())
	gift_btn.icon = Icons.get_icon("gift")
	gift_btn.tooltip_text = "Schicksalsgabe"
	gift_btn.pressed.connect(func() -> void: gift_pressed.emit())
	top_r.add_child(gift_btn)
	toasts = VBoxContainer.new()
	toasts.position = Vector2(10, 12)
	toasts.anchor_right = 1.0
	toasts.offset_left = 10
	toasts.offset_right = -66
	toasts.offset_top = 12
	toasts.add_theme_constant_override("separation", 4)
	toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toasts)
	age_lbl = _label("", 11, Color("#e8f0ff"), 4, Color(0, 0, 0, 0.7))
	age_lbl.position = Vector2(12, 0)
	add_child(age_lbl)
	move_child(age_lbl, 0)
	show_btn = Button.new()
	show_btn.custom_minimum_size = Vector2(46, 46)
	_style_button(show_btn, red_style())
	show_btn.icon = Icons.get_icon("hideui")
	show_btn.anchor_left = 1.0
	show_btn.anchor_right = 1.0
	show_btn.anchor_top = 1.0
	show_btn.anchor_bottom = 1.0
	show_btn.offset_left = -58
	show_btn.offset_right = -12
	show_btn.offset_top = -60
	show_btn.offset_bottom = -14
	show_btn.visible = false
	show_btn.pressed.connect(func() -> void: show_ui_pressed.emit())
	add_child(show_btn)


func toast(text: String, kind: String, year: int) -> void:
	var p: PanelContainer = PanelContainer.new()
	var s: StyleBoxFlat = sb(Color(0.07, 0.094, 0.078, 0.84), Color.TRANSPARENT, 0, 4)
	s.border_width_left = 3
	s.border_color = GuData.KCOL.get(kind, C_YELLOW)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 3
	s.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var r: RichTextLabel = RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.custom_minimum_size = Vector2(200, 0)
	r.add_theme_font_override("normal_font", ThemeDB.fallback_font)
	r.add_theme_font_override("bold_font", font_bold)
	r.add_theme_font_size_override("normal_font_size", 12)
	r.add_theme_font_size_override("bold_font_size", 12)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.text = "[b][color=#%s]J%d[/color][/b] %s" % [GuData.KCOL.get(kind, C_YELLOW).to_html(false), year, _esc(text)]
	p.add_child(r)
	toasts.add_child(p)
	while toasts.get_child_count() > 3:
		var old: Node = toasts.get_child(0)
		toasts.remove_child(old)
		old.queue_free()
	var tw: Tween = create_tween()
	tw.tween_interval(5.0)
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(p.queue_free)


static func _esc(s: String) -> String:
	return s.replace("[", "[lb]")


# ---------------- Hinweis, Wetter, Pinsel ----------------

func _build_floaters() -> void:
	hint_box = VBoxContainer.new()
	hint_box.anchor_left = 0.0
	hint_box.anchor_right = 1.0
	hint_box.anchor_top = 1.0
	hint_box.anchor_bottom = 1.0
	hint_box.alignment = BoxContainer.ALIGNMENT_END
	hint_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_box.modulate.a = 0.0
	add_child(hint_box)
	hint_name = _label("", 28, C_ORANGE, 9, Color("#5a2a06"))
	hint_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_box.add_child(hint_name)
	var dp: PanelContainer = PanelContainer.new()
	var ds: StyleBoxFlat = sb(Color(0.055, 0.078, 0.063, 0.8), Color.TRANSPARENT, 0, 4)
	ds.content_margin_left = 10
	ds.content_margin_right = 10
	ds.content_margin_top = 4
	ds.content_margin_bottom = 4
	dp.add_theme_stylebox_override("panel", ds)
	dp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_desc = Label.new()
	hint_desc.add_theme_font_override("font", ThemeDB.fallback_font)
	hint_desc.add_theme_font_size_override("font_size", 12)
	hint_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_desc.custom_minimum_size = Vector2(0, 0)
	hint_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dp.add_child(hint_desc)
	hint_box.add_child(dp)
	wbox = PanelContainer.new()
	var ws: StyleBoxFlat = sb(Color("#1e2620"), Color("#0e130f"), 2, 5)
	ws.content_margin_left = 4
	ws.content_margin_right = 4
	ws.content_margin_top = 5
	ws.content_margin_bottom = 3
	wbox.add_theme_stylebox_override("panel", ws)
	wbox.position = Vector2(12, 0)
	wbox.visible = false
	add_child(wbox)
	var wv: VBoxContainer = VBoxContainer.new()
	wv.add_theme_constant_override("separation", 2)
	wbox.add_child(wv)
	wicon = TextureRect.new()
	wicon.custom_minimum_size = Vector2(34, 34)
	wicon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wicon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wv.add_child(wicon)
	var wx: Button = Button.new()
	wx.custom_minimum_size = Vector2(34, 30)
	_style_button(wx, StyleBoxEmpty.new())
	wx.icon = Icons.get_icon("x")
	wx.add_theme_constant_override("icon_max_width", 22)
	wx.pressed.connect(func() -> void: weather_stop.emit())
	wv.add_child(wx)
	brush_box = PanelContainer.new()
	var bs: StyleBoxFlat = sb(C_FRAME, C_RIM, 2, 6)
	bs.set_content_margin_all(4)
	brush_box.add_theme_stylebox_override("panel", bs)
	brush_box.visible = false
	add_child(brush_box)
	var bh: HBoxContainer = HBoxContainer.new()
	bh.add_theme_constant_override("separation", 4)
	brush_box.add_child(bh)
	var sizes: Array[int] = [5, 8, 12, 16, 21]
	for k: int in range(5):
		var b: Button = Button.new()
		b.custom_minimum_size = Vector2(30, 30)
		_style_button(b, well_style(k == 2))
		var d: int = sizes[k]
		b.draw.connect(func() -> void: b.draw_circle(Vector2(15, 15), d / 2.0, Color("#d2ecdb")))
		var kk: int = k
		b.pressed.connect(func() -> void: brush_changed.emit(kk))
		b.tooltip_text = "Pinselgröße %d" % (Powers.BRUSH[k] * 2 + 1)
		bh.add_child(b)
		brush_btns.append(b)


func set_brush(i: int) -> void:
	for k: int in range(brush_btns.size()):
		var s: StyleBoxFlat = well_style(k == i)
		brush_btns[k].add_theme_stylebox_override("normal", s)
		brush_btns[k].add_theme_stylebox_override("hover", s)
		brush_btns[k].add_theme_stylebox_override("pressed", s)


func show_hint(n: String, d: String) -> void:
	hint_name.text = n
	hint_name.visible = n != ""
	hint_desc.text = d
	hint_desc.get_parent().visible = d != ""
	hint_box.modulate.a = 1.0
	hint_t = 3.2 if d != "" else 1.8


func show_weather(type: String) -> void:
	wbox.visible = type != ""
	if type != "":
		wicon.texture = Icons.get_icon("w_" + type)


func layout_floaters() -> void:
	var b: float = bar_height()
	var vs: Vector2 = get_viewport_rect().size
	hint_box.offset_top = -(b + 120)
	hint_box.offset_bottom = -(b + 14)
	hint_box.offset_left = 16
	hint_box.offset_right = -16
	hint_desc.custom_minimum_size.x = minf(vs.x - 60, 340)
	wbox.position = Vector2(12, vs.y - b - 14 - 80)
	brush_box.position = Vector2(vs.x - 192, vs.y - b - 14 - 42)
	age_lbl.position = Vector2(12, 8)
	toasts.offset_top = 28


func _process(delta: float) -> void:
	if hint_t > 0.0:
		hint_t -= delta
		if hint_t <= 0.0:
			var tw: Tween = create_tween()
			tw.tween_property(hint_box, "modulate:a", 0.0, 0.45)


# ---------------- Fenster ----------------

func _rich() -> RichTextLabel:
	var r: RichTextLabel = RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.selection_enabled = false
	r.add_theme_font_override("normal_font", ThemeDB.fallback_font)
	r.add_theme_font_override("bold_font", font_bold)
	r.add_theme_font_size_override("normal_font_size", 13)
	r.add_theme_font_size_override("bold_font_size", 13)
	r.add_theme_constant_override("line_separation", 3)
	r.add_theme_color_override("default_color", Color("#eef3ea"))
	r.meta_clicked.connect(func(m: Variant) -> void: meta_clicked.emit(str(m)))
	return r


func _win_style() -> StyleBoxFlat:
	var s: StyleBoxFlat = sb(Color("#2a352c"), C_RIM, 2, 7)
	s.set_content_margin_all(12)
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = 10
	return s


func _close_button(cb: Callable) -> Button:
	var x: Button = Button.new()
	x.custom_minimum_size = Vector2(28, 28)
	_style_button(x, red_style())
	x.text = "✕"
	x.add_theme_font_size_override("font_size", 14)
	x.pressed.connect(cb)
	return x


func _build_windows() -> void:
	insp = PanelContainer.new()
	insp.add_theme_stylebox_override("panel", _win_style())
	insp.anchor_left = 0.0
	insp.anchor_right = 1.0
	insp.offset_left = 12
	insp.offset_right = -12
	insp.offset_top = 70
	insp.visible = false
	add_child(insp)
	var v: VBoxContainer = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 8)
	insp.add_child(v)
	insp_head = HBoxContainer.new()
	insp_head.add_theme_constant_override("separation", 10)
	v.add_child(insp_head)
	insp_text = _rich()
	insp_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(insp_text)
	insp_btns = HBoxContainer.new()
	insp_btns.add_theme_constant_override("separation", 6)
	v.add_child(insp_btns)
	modal = ColorRect.new()
	modal.color = Color(0.02, 0.04, 0.03, 0.55)
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.visible = false
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			close_modal())
	add_child(modal)
	modal_panel = PanelContainer.new()
	modal_panel.add_theme_stylebox_override("panel", _win_style())
	modal_panel.anchor_left = 0.0
	modal_panel.anchor_right = 1.0
	modal_panel.anchor_top = 0.0
	modal_panel.anchor_bottom = 1.0
	modal_panel.offset_left = 12
	modal_panel.offset_right = -12
	modal_panel.offset_top = 50
	modal_panel.offset_bottom = -50
	modal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.add_child(modal_panel)
	var msc: ScrollContainer = ScrollContainer.new()
	msc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal_panel.add_child(msc)
	var mv: VBoxContainer = VBoxContainer.new()
	mv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mv.add_theme_constant_override("separation", 10)
	msc.add_child(mv)
	var mh: HBoxContainer = HBoxContainer.new()
	mv.add_child(mh)
	var sp: Control = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mh.add_child(sp)
	mh.add_child(_close_button(close_modal))
	modal_text = _rich()
	modal_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mv.add_child(modal_text)
	modal_btns = HBoxContainer.new()
	modal_btns.add_theme_constant_override("separation", 6)
	mv.add_child(modal_btns)


func _fill_buttons(box: HBoxContainer, buttons: Array) -> void:
	for c: Node in box.get_children():
		c.queue_free()
	for e: Array in buttons:
		var b: Button = Button.new()
		b.text = e[0]
		var kind: String = e[2] if e.size() > 2 else ""
		var col: Color = C_RED if kind == "red" else (Color("#2f7a5c") if kind == "jade" else Color("#3c4a3b"))
		var st: StyleBoxFlat = sb(col, C_RIM, 2, 5)
		st.content_margin_left = 10
		st.content_margin_right = 10
		st.content_margin_top = 5
		st.content_margin_bottom = 5
		_style_button(b, st)
		b.add_theme_font_size_override("font_size", 13)
		var cb: Callable = e[1]
		b.pressed.connect(cb)
		box.add_child(b)


## Inspektionskarte oben: Kopf (Bild + Titel), BBCode-Text, Knöpfe [[Text, Callable, Art]].
func open_insp(head_tex: Texture2D, head_glyph: String, head_col: Color, title: String, sub: String, body: String, buttons: Array) -> void:
	for c: Node in insp_head.get_children():
		c.queue_free()
	if head_tex != null:
		var tr: TextureRect = TextureRect.new()
		tr.texture = head_tex
		tr.custom_minimum_size = Vector2(52, 52)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var pb: PanelContainer = PanelContainer.new()
		pb.add_theme_stylebox_override("panel", sb(C_WELL, C_RIM, 2, 5))
		pb.add_child(tr)
		insp_head.add_child(pb)
	elif head_glyph != "":
		var cr: PanelContainer = PanelContainer.new()
		cr.add_theme_stylebox_override("panel", sb(head_col, C_RIM, 2, 5))
		cr.custom_minimum_size = Vector2(50, 50)
		var gl: Label = Label.new()
		gl.text = head_glyph
		gl.add_theme_font_override("font", font_cjk)
		gl.add_theme_font_size_override("font_size", 30)
		gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cr.add_child(gl)
		insp_head.add_child(cr)
	var tv: VBoxContainer = VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", 0)
	var tl: Label = _label(title, 17, C_BLUE)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(tl)
	for line: String in sub.split("\n"):
		if line == "":
			continue
		var sl: Label = Label.new()
		sl.text = line
		sl.add_theme_font_override("font", ThemeDB.fallback_font)
		sl.add_theme_font_size_override("font_size", 12)
		sl.add_theme_color_override("font_color", C_MUTED)
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tv.add_child(sl)
	insp_head.add_child(tv)
	insp_head.add_child(_close_button(close_insp))
	insp_text.text = body
	_fill_buttons(insp_btns, buttons)
	insp_btns.visible = not buttons.is_empty()
	insp.visible = true


func update_insp_body(body: String) -> void:
	insp_text.text = body


func close_insp() -> void:
	insp.visible = false


func open_modal(body: String, buttons: Array = []) -> void:
	modal_text.text = body
	_fill_buttons(modal_btns, buttons)
	modal_btns.visible = not buttons.is_empty()
	modal.visible = true


func close_modal() -> void:
	modal.visible = false


# ---------------- Ladebildschirm ----------------

func _build_loading() -> void:
	load_screen = ColorRect.new()
	load_screen.color = Color("#1d4f94")
	load_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	load_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(load_screen)
	var v: VBoxContainer = VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.offset_left = -130
	v.offset_right = 130
	v.offset_top = -70
	v.offset_bottom = 70
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	load_screen.add_child(v)
	var big: Label = Label.new()
	big.text = "蛊界"
	big.add_theme_font_override("font", font_cjk)
	big.add_theme_font_size_override("font_size", 56)
	big.add_theme_color_override("font_shadow_color", Color("#0c2a55"))
	big.add_theme_constant_override("shadow_offset_y", 3)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(big)
	load_label = _label("Die fünf Regionen entstehen …", 15, Color.WHITE)
	load_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(load_label)
	load_bar = ProgressBar.new()
	load_bar.show_percentage = false
	load_bar.custom_minimum_size = Vector2(200, 12)
	load_bar.add_theme_stylebox_override("background", sb(Color("#102c55"), Color("#0c1f3d"), 2, 5))
	load_bar.add_theme_stylebox_override("fill", sb(C_YELLOW, Color.TRANSPARENT, 0, 4))
	load_bar.max_value = 1.0
	v.add_child(load_bar)


func set_loading(visible_now: bool, text: String = "", progress: float = 0.0) -> void:
	load_screen.visible = visible_now
	if text != "":
		load_label.text = text
	load_bar.value = progress


func set_ui_hidden(h: bool) -> void:
	bar.visible = not h
	top_r.visible = not h
	toasts.visible = not h
	hint_box.visible = not h
	age_lbl.visible = not h
	show_btn.visible = h
	if h:
		insp.visible = false
		brush_box.visible = false
		wbox.visible = false


# ---------------- Reiter-Knopf ----------------

class TabButton:
	extends Control
	var icon_tex: Texture2D
	var active: bool = false
	var pressed_cb: Callable

	func _init() -> void:
		custom_minimum_size = Vector2(40, 30)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			pressed_cb.call()
			accept_event()

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var inset: float = w * 0.09
		var outer: PackedVector2Array = PackedVector2Array([Vector2(inset, 0), Vector2(w - inset, 0), Vector2(w, h), Vector2(0, h)])
		draw_colored_polygon(outer, Color("#151a16"))
		var inner: PackedVector2Array = PackedVector2Array([Vector2(inset + 2, 2), Vector2(w - inset - 2, 2), Vector2(w - 2, h), Vector2(2, h)])
		draw_colored_polygon(inner, Color("#c74634") if active else Color("#414f3e"))
		var hi: PackedVector2Array = PackedVector2Array([Vector2(inset + 2, 2), Vector2(w - inset - 2, 2), Vector2(w - inset - 1.6, 5), Vector2(inset + 1.6, 5)])
		draw_colored_polygon(hi, Color("#e2664a") if active else Color("#5a6e55"))
		if icon_tex != null:
			var iw: float = minf(w * 0.72, 42.0)
			var ih: float = iw * 0.5
			draw_texture_rect(icon_tex, Rect2((w - iw) * 0.5, (h - ih) * 0.5 + 2, iw, ih), false)
