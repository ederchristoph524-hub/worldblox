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
const ROW_Y: int = 10  ## Abstand Reiter-Unterkante → Knöpfe (WorldBox: etwas Luft)
const TAB_L: int = 14  ## Reiterzeile: Abstand links (Mäander-Streifen)
const TAB_R: int = 30  ## rechts frei für die Pfeil-Spalte
const TAB_SEP: int = 2
const TAB_MAX: int = 66
const ARROW_W: int = 26
const TOAST_MAX_W: float = 360.0

var font_bold: FontVariation
var font_black: FontVariation
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
var insp_btns: HFlowContainer
var insp_head: HBoxContainer
var modal: ColorRect
var modal_panel: PanelContainer
var modal_text: RichTextLabel
var modal_btns: HFlowContainer
var load_screen: ColorRect
var load_label: Label
var load_bar: ProgressBar
var age_lbl: Label
var show_btn: Button
var bar_hidden: bool = false
var legend: Control = null  ## Legende der Mächte (PowerLegend, gesetzt von GuMain); Meldungen rutschen darunter
var toggled: Callable = Callable()  ## Werkzeug-Id -> bool: Schalter-Knöpfe (Cheats) leuchten, solange sie an sind
var modal_input: LineEdit
var _input_cb: Callable = Callable()
var tool_pill: PanelContainer  ## dauerhafte Zeile „gewähltes Werkzeug“ über der Leiste (nachdem der große Hinweis verblasst)
var _pill_icon: TextureRect
var _pill_lbl: Label
var tip: PanelContainer  ## Tooltip der Werkzeug-Knöpfe (Maus: verweilen, Touch: lange drücken)
var _tip_name: Label
var _tip_desc: Label
var _tip_mode: Label
var _tip_btn: Button = null
var _tip_tool: Dictionary = {}
var _tip_wait: float = -1.0
var _tip_life: float = 0.0
var _down_btn: Button = null
var _down_scroll: int = 0
var _long_fired: bool = false
var _bar_tw: Tween = null
var insp_scroll: ScrollContainer
var insp_fold: Button
var insp_collapsed: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font_bold = FontVariation.new()
	font_bold.base_font = ThemeDB.fallback_font
	font_bold.variation_embolden = 0.7
	font_black = FontVariation.new()
	font_black.base_font = ThemeDB.fallback_font
	font_black.variation_embolden = 1.25
	font_black.spacing_glyph = 0
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
	_build_tip()
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


static var _tex_cache: Dictionary = {}


## Vertiefte Knopf-Mulde wie in WorldBox: dunkel, Risse, abgeschrägte Ecken, olivfarbene Unterkante.
## kind: "n" normal, "on" ausgewählt (rot), "riv" mit Nieten (Hauptmenü).
static func well_tex(kind: String, w: int = BTN, h: int = BTN) -> ImageTexture:
	var key: String = "%s%dx%d" % [kind, w, h]
	if _tex_cache.has(key):
		return _tex_cache[key]
	var q: Px = Px.new(w, h)
	var fill: Color = Color("#263027")
	var crack: Color = Color("#1c241d")
	var crack_hi: Color = Color("#2c372d")
	var inset: int = 2
	if kind == "riv":
		q.p(0, 0, w, h, "#151816")
		q.p(1, 1, w - 2, h - 2, "#6c6a48")
		q.p(2, 2, w - 4, h - 4, "#101410")
		inset = 3
	elif kind == "on":
		fill = Color("#2e2d27")
		crack = Color("#24221d")
		crack_hi = Color("#38362e")
		q.p(0, 0, w, h, "#7e241a")
		q.p(1, 1, w - 2, h - 2, "#c74634")
		q.p(1, 1, w - 2, 1, "#dc5a40")
		q.p(2, h - 2, w - 4, 1, "#a8321f")
		q.p(3, 3, w - 6, h - 6, "#3e1c16")
		inset = 4
	else:
		q.p(0, 0, w, h, "#151816")
		q.p(1, 1, w - 2, h - 2, "#3a3d2b")
		q.p(1, h - 2, w - 2, 1, "#5e5c3e")
		q.p(w - 2, 1, 1, h - 2, "#55553a")
		q.p(2, 2, w - 4, h - 4, "#141a15")
		inset = 3
	q.p(inset, inset, w - inset * 2, h - inset * 2, fill)
	# Risse in der Mulde
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7 + w * 31 + h + kind.length()
	for k: int in range(5):
		var x: int = rng.randi_range(inset + 2, w - inset - 3)
		var y: int = rng.randi_range(inset + 2, h - inset - 4)
		var dx: int = 1 if rng.randf() < 0.5 else -1
		for n: int in range(rng.randi_range(6, 14)):
			q.p(x, y, 1, 1, crack)
			q.p(x, y + 1, 1, 1, crack_hi)
			if rng.randf() < 0.55:
				x += dx
			else:
				y += 1 if rng.randf() < 0.6 else -1
			x = clampi(x, inset + 1, w - inset - 2)
			y = clampi(y, inset + 1, h - inset - 3)
	q.p(inset, inset, w - inset * 2, 1, Color(0, 0, 0, 0.3))
	q.p(inset, inset, 1, h - inset * 2, Color(0, 0, 0, 0.3))
	if kind == "riv":
		for c: Vector2i in [Vector2i(0, 0), Vector2i(w - 3, 0), Vector2i(0, h - 3), Vector2i(w - 3, h - 3)]:
			q.p(c.x, c.y, 3, 3, "#4a1410")
			q.p(c.x, c.y, 2, 2, "#d0402e")
			q.p(c.x, c.y, 1, 1, "#ff8a70")
	else:
		_chamfer(q, w, h, 2)
	var t: ImageTexture = q.tex()
	_tex_cache[key] = t
	return t


static func _chamfer(q: Px, w: int, h: int, n: int) -> void:
	for k: int in range(n):
		for j: int in range(n - k):
			for c: Vector2i in [Vector2i(j, k), Vector2i(w - 1 - j, k), Vector2i(j, h - 1 - k), Vector2i(w - 1 - j, h - 1 - k)]:
				q.img.set_pixel(c.x, c.y, Color(0, 0, 0, 0))


## Roter WorldBox-Knopf: oben heller, unten dunkler Rand.
static func red_tex(w: int = 46, h: int = 46) -> ImageTexture:
	var key: String = "red%dx%d" % [w, h]
	if _tex_cache.has(key):
		return _tex_cache[key]
	var q: Px = Px.new(w, h)
	q.p(0, 0, w, h, "#5e1a12")
	q.p(1, 1, w - 2, h - 2, "#7e241a")
	q.p(2, 2, w - 4, h - 6, "#c74634")
	q.p(2, 2, w - 4, (h - 6) / 2, "#d2553d")
	q.p(3, 2, w - 6, 1, "#e8735a")
	q.p(2, h - 4, w - 4, 2, "#9a2e22")
	_chamfer(q, w, h, 3)
	var t: ImageTexture = q.tex()
	_tex_cache[key] = t
	return t


static func _tex_style(t: Texture2D, m: int) -> StyleBoxTexture:
	var s: StyleBoxTexture = StyleBoxTexture.new()
	s.texture = t
	s.texture_margin_left = m
	s.texture_margin_right = m
	s.texture_margin_top = m
	s.texture_margin_bottom = m
	return s


static func well_style(on: bool, riv: bool = false) -> StyleBox:
	return _tex_style(well_tex("on" if on else ("riv" if riv else "n")), 6)


static func red_style() -> StyleBox:
	var s: StyleBoxTexture = _tex_style(red_tex(), 8)
	s.content_margin_bottom = 4
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
	var st: StyleBoxFlat = sb(C_FRAME, Color("#2a3526"), 0, 0)
	st.border_width_top = 2
	bar.add_theme_stylebox_override("panel", st)
	bar.draw.connect(func() -> void:
		bar.draw_rect(Rect2(0, 2, bar.size.x, 1), Color("#5a6e55"))
		bar.draw_rect(Rect2(0, 3, bar.size.x, 1), Color("#4a5a46")))
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
	meander.position = Vector2(2, ROW_Y - 1)
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
	tabs_box.offset_left = TAB_L
	tabs_box.offset_right = -TAB_R
	tabs_box.offset_top = -27
	tabs_box.offset_bottom = 1
	tabs_box.add_theme_constant_override("separation", TAB_SEP)
	tabs_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(tabs_box)
	for i: int in range(Powers.TABS.size()):
		var tb: TabButton = TabButton.new()
		tb.icon_tex = Icons.get_icon("tab%d" % i)
		tb.tooltip_text = Powers.TABS[i]
		tb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		tb.pressed_cb = func() -> void: tab_pressed.emit(i)
		tabs_box.add_child(tb)
		tab_buttons.append(tb)
	# Inhalt
	var row: HBoxContainer = HBoxContainer.new()
	row.position = Vector2(12, ROW_Y)
	row.anchor_right = 1.0
	row.offset_left = 12
	row.offset_right = 0
	row.offset_top = ROW_Y
	row.offset_bottom = ROW_Y + BTN * 2 + GAP
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
	back_btn.tooltip_text = "Back"
	back_btn.pressed.connect(func() -> void: back_pressed.emit())
	fixed_box.add_child(back_btn)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", GAP)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fixed_box.add_child(col)
	pause_btn = _tool_button(Icons.get_icon("pause"), "Pause (Space)")
	pause_btn.pressed.connect(func() -> void: pause_pressed.emit())
	col.add_child(pause_btn)
	speed_btn = _tool_button(Icons.get_icon("speed"), "Time speed (T)")
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
	tools_scroll.gui_input.connect(func(e: InputEvent) -> void:
		# Mausrad über der Leiste blättert waagrecht (Desktop)
		if e is InputEventMouseButton and e.pressed:
			var mbe: InputEventMouseButton = e
			var dir: int = 0
			if mbe.button_index == MOUSE_BUTTON_WHEEL_DOWN or mbe.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
				dir = 1
			elif mbe.button_index == MOUSE_BUTTON_WHEEL_UP or mbe.button_index == MOUSE_BUTTON_WHEEL_LEFT:
				dir = -1
			if dir != 0:
				scroll_bar_to(clampi(_bar_goal() + dir * (BTN + 7) * 2, 0, _bar_max()), 0.16)
				tools_scroll.accept_event())
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
	arrow.offset_left = -ARROW_W
	arrow.offset_right = 0
	arrow.offset_top = -10
	arrow.offset_bottom = BTN * 2 + GAP + 14
	arrow.mouse_filter = Control.MOUSE_FILTER_STOP
	arrow.draw.connect(func() -> void:
		var h: float = arrow.size.y
		var back: bool = _bar_at_end()
		arrow.draw_rect(Rect2(0, 0, 26, h), Color("#2e3a2b"))
		arrow.draw_rect(Rect2(1, 0, 25, h), Color("#4a5847"))
		arrow.draw_rect(Rect2(1, 0, 2, h), Color("#5f735b"))
		arrow.draw_rect(Rect2(3, 0, 1, h), Color("#3c4939"))
		arrow.draw_rect(Rect2(22, 0, 1, h), Color("#3c4939"))
		var cy: float = roundf(h * 0.5)
		# am Ende der Leiste zeigt der Pfeil zurück an den Anfang
		for k: int in range(13):
			var hh: float = 13.0 - k
			var x0: float = (21 - k) if back else (9 + k)
			arrow.draw_rect(Rect2(x0, cy - hh, 1, hh * 2.0), Color("#5a4a00"))
		for k: int in range(11):
			var hh2: float = 11.0 - k
			var x1: float = (20 - k) if back else (9 + k)
			arrow.draw_rect(Rect2(x1, cy - hh2, 1, hh2 * 2.0 - 1.0), C_YELLOW)
			arrow.draw_rect(Rect2(x1, cy + hh2 * 0.3, 1, hh2 * 0.7 - 1.0), Color("#b89a00")))
	arrow.pressed.connect(func() -> void:
		var to: int = 0 if _bar_at_end() else mini(_bar_max(), tools_scroll.scroll_horizontal + int(tools_scroll.size.x * 0.7))
		scroll_bar_to(to))
	bar.add_child(arrow)
	var ver: Label = _label("gu-world 0.3-27@gdt (4)", 10, Color("#a4b0a4"))
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


func _bar_max() -> int:
	return maxi(0, int(tools_box.size.x - tools_scroll.size.x))


func _bar_at_end() -> bool:
	return _bar_max() > 0 and tools_scroll.scroll_horizontal >= _bar_max() - 4


var _bar_to: int = -1


func _bar_goal() -> int:
	return _bar_to if _bar_tw != null and _bar_tw.is_running() else tools_scroll.scroll_horizontal


## Werkzeugleiste weich blättern (Pfeil, Mausrad).
func scroll_bar_to(to: int, dur: float = 0.3) -> void:
	if _bar_tw != null:
		_bar_tw.kill()
	_bar_to = to
	_hide_tip()
	_bar_tw = create_tween()
	_bar_tw.tween_property(tools_scroll, "scroll_horizontal", to, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


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
	_style_button(b, well_style(false, riv))
	b.set_meta("riv", riv)
	b.icon = icon
	b.tooltip_text = tip
	b.mouse_filter = Control.MOUSE_FILTER_PASS
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
		if t.has("gl"):
			var gl: Label = Label.new()
			gl.text = t["gl"]
			gl.add_theme_font_override("font", font_cjk)
			gl.add_theme_font_size_override("font_size", 12)
			gl.add_theme_color_override("font_color", Color.WHITE)
			gl.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05, 1.0))
			gl.add_theme_constant_override("outline_size", 4)
			gl.position = Vector2(26, 23)
			gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(gl)
		var tt: Dictionary = t
		b.tooltip_text = ""  # eigener Tooltip mit Beschreibung (Maus: verweilen, Touch: lange drücken)
		b.mouse_entered.connect(func() -> void:
			if _down_btn == null:
				_tip_btn = b
				_tip_tool = tt
				_tip_wait = 0.45)
		b.mouse_exited.connect(func() -> void:
			if _tip_btn == b and _down_btn == null:
				_hide_tip())
		b.button_down.connect(func() -> void:
			_down_btn = b
			_down_scroll = tools_scroll.scroll_horizontal
			_long_fired = false
			_tip_btn = b
			_tip_tool = tt
			if not tip.visible:
				_tip_wait = 0.42)
		b.button_up.connect(func() -> void:
			if _down_btn == b:
				_down_btn = null)
		b.pressed.connect(func() -> void:
			if _long_fired:
				# langes Drücken zeigt nur die Beschreibung
				_long_fired = false
				_tip_life = 2.6
				return
			_hide_tip()
			tool_pressed.emit(tt))
		column.add_child(b)
		tool_btns[t["id"]] = b
	if _bar_tw != null:
		_bar_tw.kill()
	tools_scroll.scroll_horizontal = 0
	_hide_tip()
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(26, 0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tools_box.add_child(spacer)


func refresh_tools(active_id: String, weather_type: String) -> void:
	for id: String in tool_btns.keys():
		var t: Dictionary = Powers.tool_by_id(id)
		var on: bool = id == active_id or (t.has("w") and t["w"] == weather_type) or (toggled.is_valid() and bool(toggled.call(id)))
		var b: Button = tool_btns[id]
		var s: StyleBox = well_style(on, bool(b.get_meta("riv", false)))
		b.add_theme_stylebox_override("normal", s)
		b.add_theme_stylebox_override("hover", s)
		b.add_theme_stylebox_override("pressed", s)
	var tl: Dictionary = Powers.tool_by_id(active_id)
	brush_box.visible = not tl.is_empty() and tl["m"] == "paint"
	_set_pill(tl)


const MODE_TEXT: Dictionary = {"paint": "drag to paint", "spawn": "tap to place", "tap": "tap the map", "pair": "tap two targets"}


## Zeile „gewähltes Werkzeug“: Icon, Name und was zu tun ist; leer = aus.
func _set_pill(t: Dictionary) -> void:
	if t.is_empty() or str(t["m"]) == "act":
		tool_pill.visible = false
		return
	_pill_icon.texture = Icons.get_icon(t["id"])
	_pill_lbl.text = "%s · %s" % [t["n"], MODE_TEXT.get(str(t["m"]), "")]
	tool_pill.visible = not bar_hidden
	tool_pill.reset_size()


func _hide_tip() -> void:
	_tip_btn = null
	_tip_wait = -1.0
	_tip_life = 0.0
	if tip != null:
		tip.visible = false


func _show_tip() -> void:
	var t: Dictionary = _tip_tool
	if _tip_btn == null or t.is_empty() or not is_instance_valid(_tip_btn):
		return
	_tip_name.text = str(t["n"])
	var d: String = str(t.get("d", ""))
	_tip_desc.text = d
	_tip_desc.visible = d != ""
	var mt: String = MODE_TEXT.get(str(t["m"]), "")
	_tip_mode.text = ("Tap to use" if str(t["m"]) == "act" else "Tap to select, then " + mt)
	var vs: Vector2 = get_viewport_rect().size
	var w: float = minf(270.0, vs.x - 16.0)
	_tip_desc.custom_minimum_size.x = w - 20.0
	tip.custom_minimum_size.x = w
	_tip_desc.size.x = w - 20.0
	tip.visible = true
	_place_tip()
	_tip_life = 6.0


## Tooltip über dem Knopf, über der Reiterzeile; Höhe folgt dem umbrochenen Text (läuft, solange er sichtbar ist).
func _place_tip() -> void:
	if _tip_btn == null or not is_instance_valid(_tip_btn):
		return
	tip.reset_size()
	var vs: Vector2 = get_viewport_rect().size
	var br: Rect2 = _tip_btn.get_global_rect()
	var x: float = clampf(br.get_center().x - tip.size.x / 2.0, 8.0, vs.x - tip.size.x - 8.0)
	var y: float = vs.y - bar_height() - 6.0 - tip.size.y
	if tool_pill.visible:
		y = minf(y, tool_pill.position.y - 6.0 - tip.size.y)
	if brush_box.visible:
		y = minf(y, brush_box.position.y - 6.0 - tip.size.y)
	tip.position = Vector2(roundf(x), roundf(y))
	if tip.get_index() != get_child_count() - 1:
		move_child(tip, -1)


func set_paused(p: bool) -> void:
	pause_btn.icon = Icons.get_icon("play" if p else "pause")
	var s: StyleBox = well_style(p)
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
	star.tooltip_text = "Ranking of the strongest"
	star.pressed.connect(func() -> void: star_pressed.emit())
	top_r.add_child(star)
	gift_btn = Button.new()
	gift_btn.custom_minimum_size = Vector2(46, 46)
	_style_button(gift_btn, red_style())
	gift_btn.icon = Icons.get_icon("gift")
	gift_btn.tooltip_text = "Gift of Fate"
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


const MAX_TOASTS: int = 3
const TOAST_SECS: float = 3.6
const TOAST_CHARS: int = 96  ## längere Meldungen werden gekürzt – die Chronik hat alles


## Meldung oben links: kompakt (höchstens zwei Zeilen, schmal), verblasst nach TOAST_SECS; höchstens drei.
func toast(text: String, kind: String, year: int) -> void:
	var col: Color = GuData.KCOL.get(kind, C_YELLOW)
	var p: PanelContainer = PanelContainer.new()
	var s: StyleBoxFlat = sb(Color(0.05, 0.07, 0.06, 0.74), Color.TRANSPARENT, 0, 3)
	s.border_width_left = 3
	s.border_color = col
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 1
	s.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var r: RichTextLabel = RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.add_theme_font_override("normal_font", ThemeDB.fallback_font)
	r.add_theme_font_override("bold_font", font_bold)
	r.add_theme_font_size_override("normal_font_size", 11)
	r.add_theme_font_size_override("bold_font_size", 11)
	r.add_theme_constant_override("line_separation", 0)
	r.add_theme_color_override("default_color", Color("#e6ece4"))
	r.add_theme_constant_override("outline_size", 2)
	r.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t: String = text.strip_edges()
	if t.length() > TOAST_CHARS:
		t = t.substr(0, TOAST_CHARS - 1).strip_edges() + "…"
	r.text = "[b][color=#%s]Y%d[/color][/b] %s" % [col.to_html(false), year, _esc(t)]
	# schmal: kurze Meldungen nur so breit wie nötig
	var tw: float = ThemeDB.fallback_font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + font_bold.get_string_size("Y%d " % year, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 6.0
	r.custom_minimum_size = Vector2(minf(tw, _toast_w() - 15.0), 0)
	p.add_child(r)
	toasts.add_child(p)
	while toasts.get_child_count() > MAX_TOASTS:
		var old: Node = toasts.get_child(0)
		toasts.remove_child(old)
		old.queue_free()
	p.modulate.a = 0.0
	var tw2: Tween = p.create_tween()
	tw2.tween_property(p, "modulate:a", 1.0, 0.15)
	tw2.tween_interval(TOAST_SECS)
	tw2.tween_property(p, "modulate:a", 0.0, 0.5)
	tw2.tween_callback(p.queue_free)
	tick_layout()


## Breite der Meldungsspalte: links oben, nie unter Stern/Geschenk, höchstens 300 px.
func _toast_w() -> float:
	var vs: Vector2 = get_viewport_rect().size
	return clampf(minf(vs.x * 0.68, vs.x - 10.0 - (vs.x - top_r.get_rect().position.x) - 8.0), 160.0, 300.0)


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
	hint_name = _label("", 21, Color("#eb9e1a"), 2, Color(0.24, 0.13, 0.02, 0.55))
	hint_name.label_settings.font = font_black
	hint_name.label_settings.shadow_color = Color(0.14, 0.08, 0.02, 0.8)
	hint_name.label_settings.shadow_offset = Vector2(1, 2)
	hint_name.label_settings.shadow_size = 1
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
	var ws: StyleBox = _tex_style(well_tex("n", 44, 80), 7)
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
		b.tooltip_text = "Brush size %d" % (Powers.BRUSH[k] * 2 + 1)
		bh.add_child(b)
		brush_btns.append(b)


func _build_tip() -> void:
	tip = PanelContainer.new()
	var ts: StyleBoxFlat = sb(Color(0.06, 0.08, 0.07, 1.0), Color("#c8a040"), 1, 4)
	ts.set_content_margin_all(8)
	ts.content_margin_top = 5
	ts.shadow_color = Color(0, 0, 0, 0.4)
	ts.shadow_size = 6
	tip.add_theme_stylebox_override("panel", ts)
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.visible = false
	add_child(tip)
	var tv: VBoxContainer = VBoxContainer.new()
	tv.add_theme_constant_override("separation", 2)
	tip.add_child(tv)
	_tip_name = _label("", 15, Color("#f5a01e"), 3, Color(0.1, 0.05, 0.0, 0.8))
	_tip_name.label_settings.font = font_black
	tv.add_child(_tip_name)
	_tip_desc = Label.new()
	_tip_desc.add_theme_font_override("font", ThemeDB.fallback_font)
	_tip_desc.add_theme_font_size_override("font_size", 12)
	_tip_desc.add_theme_color_override("font_color", Color("#e8eee6"))
	_tip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(_tip_desc)
	_tip_mode = Label.new()
	_tip_mode.add_theme_font_override("font", ThemeDB.fallback_font)
	_tip_mode.add_theme_font_size_override("font_size", 11)
	_tip_mode.add_theme_color_override("font_color", C_MUTED)
	tv.add_child(_tip_mode)
	# Zeile „gewähltes Werkzeug“
	tool_pill = PanelContainer.new()
	var ps: StyleBoxFlat = sb(Color(0.06, 0.08, 0.07, 0.86), Color("#c74634"), 0, 4)
	ps.border_width_left = 3
	ps.content_margin_left = 5
	ps.content_margin_right = 9
	ps.content_margin_top = 2
	ps.content_margin_bottom = 2
	tool_pill.add_theme_stylebox_override("panel", ps)
	tool_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tool_pill.visible = false
	add_child(tool_pill)
	var ph: HBoxContainer = HBoxContainer.new()
	ph.add_theme_constant_override("separation", 5)
	ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tool_pill.add_child(ph)
	_pill_icon = TextureRect.new()
	_pill_icon.custom_minimum_size = Vector2(20, 20)
	_pill_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pill_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pill_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ph.add_child(_pill_icon)
	_pill_lbl = _label("", 12, Color("#f2f6f0"), 3, Color(0, 0, 0, 0.6))
	_pill_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_pill_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_pill_lbl.clip_text = true
	ph.add_child(_pill_lbl)


func set_brush(i: int) -> void:
	for k: int in range(brush_btns.size()):
		var s: StyleBox = well_style(k == i)
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
	tick_layout()


func hide_hint() -> void:
	hint_t = 0.0
	hint_box.modulate.a = 0.0


func show_weather(type: String) -> void:
	wbox.visible = type != ""
	if type != "":
		wicon.texture = Icons.get_icon("w_" + type)


func layout_floaters() -> void:
	var b: float = bar_height()
	var vs: Vector2 = get_viewport_rect().size
	_layout_tabs(vs.x)
	wbox.position = Vector2(12, vs.y - b - 12 - 80)
	brush_box.position = Vector2(vs.x - 192, vs.y - b - 12 - 42)
	age_lbl.position = Vector2(12, 8)
	# Fenster: auf breiten Bildschirmen schmal und mittig statt über die ganze Breite
	var iw: float = minf(vs.x - 24.0, 400.0)
	if vs.x >= 760.0:
		# Querformat: Inspektor links, die Karte daneben bleibt frei
		insp.offset_left = 12
		insp.offset_right = -roundf(vs.x - 12.0 - iw)
		insp.offset_top = 40
	else:
		insp.offset_left = roundf((vs.x - iw) / 2.0)
		insp.offset_right = -roundf((vs.x - iw) / 2.0)
		insp.offset_top = 70
	var mw: float = minf(vs.x - 24.0, 480.0)
	modal_panel.offset_left = roundf((vs.x - mw) / 2.0)
	modal_panel.offset_right = -roundf((vs.x - mw) / 2.0)
	var mh: float = vs.y - 100.0
	if mh > 760.0:
		modal_panel.offset_top = roundf((vs.y - 760.0) / 2.0)
		modal_panel.offset_bottom = -roundf((vs.y - 760.0) / 2.0)
	else:
		modal_panel.offset_top = 50
		modal_panel.offset_bottom = -50
	tick_layout()


## Reiter so breit wie möglich, aber alle sieben passen in die Zeile (360–1600 px); nie gestreckt.
func _layout_tabs(w: float) -> void:
	var n: int = tab_buttons.size()
	if n == 0:
		return
	var avail: float = w - TAB_L - TAB_R
	var tw: int = clampi(int(floor((avail - TAB_SEP * (n - 1)) / n)), 30, TAB_MAX)
	for tb: TabButton in tab_buttons:
		tb.custom_minimum_size = Vector2(tw, 28)
		tb.queue_redraw()


## Hinweis und Meldungen so legen, dass sie nichts verdecken (läuft jedes Bild, billig).
func tick_layout() -> void:
	var b: float = bar_height()
	var vs: Vector2 = get_viewport_rect().size
	# Hinweis: mittig über der Leiste; seitlich frei für Wetter-Kasten, über dem Pinsel-Kasten
	var side: float = 16.0
	if wbox.visible:
		side = maxf(side, wbox.position.x + wbox.size.x + 8.0)
	var bottom: float = b + 10.0
	if brush_box.visible and brush_box.position.x < vs.x / 2.0 + 180.0:
		bottom = b + 12.0 + 42.0 + 8.0
	hint_box.offset_left = side
	hint_box.offset_right = -side
	hint_box.offset_bottom = -bottom
	hint_box.offset_top = -(bottom + 120.0)
	hint_desc.custom_minimum_size.x = minf(vs.x - side * 2.0 - 24.0, 340.0)
	# Titel lieber etwas kleiner als umbrechen
	var avail: float = vs.x - side * 2.0 - 8.0
	var fs: int = 21
	while fs > 15 and font_black.get_string_size(hint_name.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > avail:
		fs -= 1
	if hint_name.label_settings.font_size != fs:
		hint_name.label_settings.font_size = fs
	# Meldungen: oben links unter Zeitalter-Zeile und Legende, schmal; solange ein Fenster offen ist, ruhen sie (Chronik hat alles)
	var tw: float = _toast_w()
	var ty: float = 28.0
	toasts.offset_left = 10
	toasts.offset_right = -(vs.x - 10.0 - tw)
	if legend != null and legend.visible:
		ty = maxf(ty, legend.get_global_rect().end.y + 4.0)
	toasts.offset_top = ty
	toasts.visible = not bar_hidden and not insp.visible and not modal.visible and ty + 40.0 < vs.y - b - 60.0
	# Zeile „gewähltes Werkzeug“: links über der Leiste (neben dem Wetter-Kasten, nicht unter dem Pinsel-Kasten)
	if tool_pill.visible:
		var px: float = 10.0
		if wbox.visible:
			px = wbox.position.x + wbox.size.x + 8.0
		var right: float = vs.x - 10.0
		if brush_box.visible:
			right = brush_box.position.x - 8.0
		_pill_lbl.custom_minimum_size.x = 0
		var want: float = font_bold.get_string_size(_pill_lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 6.0
		_pill_lbl.custom_minimum_size.x = clampf(minf(want, right - px - 45.0), 40.0, 400.0)
		_pill_lbl.size.x = _pill_lbl.custom_minimum_size.x
		tool_pill.reset_size()
		tool_pill.position = Vector2(px, vs.y - b - 8.0 - tool_pill.size.y)
	# Inspektor: Werte-Zeilen scrollen, wenn sie mehr als ~40 % des Bildschirms brauchen
	if insp.visible and insp_scroll != null:
		var ch: float = insp_rows.get_combined_minimum_size().y
		var mh: float = clampf(vs.y * 0.4 - 40.0, 120.0, 460.0)
		var want_h: float = 0.0 if insp_collapsed else minf(ch, mh)
		if absf(insp_scroll.custom_minimum_size.y - want_h) > 0.5:
			insp_scroll.custom_minimum_size.y = want_h
		# nur die Höhe auf den Inhalt schrumpfen (Breite hängt an den Ankern)
		if insp.size.y > insp.get_combined_minimum_size().y + 0.5:
			insp.size = Vector2(insp.size.x, 0.0)


func _process(delta: float) -> void:
	if hint_t > 0.0:
		hint_t -= delta
		if hint_t <= 0.0:
			var tw: Tween = create_tween()
			tw.tween_property(hint_box, "modulate:a", 0.0, 0.45)
	# die Werkzeug-Zeile erscheint, sobald der große Hinweis verblasst
	tool_pill.modulate.a = clampf(1.0 - hint_box.modulate.a * 1.6, 0.0, 1.0)
	# Tooltip: verweilen (Maus) bzw. lange drücken (Touch); Wischen über die Leiste bricht ab
	if _down_btn != null and absi(tools_scroll.scroll_horizontal - _down_scroll) > 6:
		_down_btn = null
		_long_fired = false
		_hide_tip()
	if _tip_btn != null and _tip_wait > 0.0:
		_tip_wait -= delta
		if _tip_wait <= 0.0:
			_show_tip()
			if _down_btn != null and _down_btn == _tip_btn and _down_btn.button_pressed:
				_long_fired = true
	elif tip.visible:
		_place_tip()
		_tip_life -= delta
		if _tip_life <= 0.0 or (_tip_btn != null and not is_instance_valid(_tip_btn)):
			_hide_tip()
	if _bar_at_end() != arrow.get_meta("back", false):
		arrow.set_meta("back", _bar_at_end())
		arrow.queue_redraw()


# ---------------- Fenster ----------------
# WorldBox-Fenster: dunkle Schiefer-Fläche, Titelleiste, Werte-Zeilen mit kleinen Symbolen.

const C_SLATE: Color = Color("#27323a")
const C_SLATE_DK: Color = Color("#1c2429")
const C_SLATE_ROW: Color = Color("#222b31")
const C_SLATE_ROW2: Color = Color("#2a343b")
const C_SLATE_EDGE: Color = Color("#4d5d66")
const MT_PREFIX: String = "[color=#9db09e]"

var insp_title: Label
var insp_rows: VBoxContainer
var insp_sig: String = ""
var modal_title: Label

const STAT_ICON: Dictionary = {
	"Bewohner": "person", "Volk": "person", "Vorräte": "apple", "Gebäude": "house", "Clan": "flag", "Stärkster": "crown",
	"Fehden": "sword", "Bündnisse": "hand", "Alter": "hourglass", "Pfad": "orb", "Begabung": "star", "Essenz": "gem",
	"Fortschritt": "arrow", "Öffnung": "eye", "Arbeit": "hammer", "Leben": "heart", "Siege": "sword", "Stärke": "sword", "Beute": "skull",
	"Gesinnung": "yinyang", "Besitzer": "crown", "Wirkung": "gem", "Gu-Meister": "person", "Stufe": "star", "Verblasst": "hourglass", "Fötus-Gu": "orb",
	"Einfluss": "crown", "Gebiet": "flag",
	# English labels (inspector rows)
	"Population": "person", "Race": "person", "People": "person", "Supplies": "apple", "Buildings": "house", "Strongest": "crown",
	"Feuds": "sword", "Alliances": "hand", "Age": "hourglass", "Path": "orb", "Aptitude": "star", "Talent": "star", "Essence": "gem",
	"Progress": "arrow", "Aperture": "eye", "Work": "hammer", "Job": "hammer", "Life": "heart", "Health": "heart", "Victories": "sword", "Wins": "sword", "Strength": "sword", "Kills": "skull", "Prey": "skull", "Loot": "skull",
	"Disposition": "yinyang", "Alignment": "yinyang", "Owner": "crown", "Effect": "gem", "Gu Masters": "person", "Rank": "star", "Tier": "star", "Fades": "hourglass", "Fetus Gu": "orb",
	"Influence": "crown", "Territory": "flag",
	"Stage": "bars", "Might": "bolt", "Tribulation": "bolt", "Capital": "castle", "Clan Leader": "crown", "Dominion": "crown",
	"Plan": "scroll", "Agenda": "scroll", "Goal": "scroll", "States": "scroll", "Title": "tag", "Id": "tag", "Figure": "tag",
	"Luck": "clover", "Loyalty": "shield", "War weariness": "sword", "Bloodline": "drop", "Cultivation": "lotus", "Cheat": "wand",
	"Villages": "house", "Souls": "person"}


static func stat_icon(id: String) -> ImageTexture:
	var key: String = "si_" + id
	if _tex_cache.has(key):
		return _tex_cache[key]
	var g: Array = [".......", "..WWW..", ".WWWWW.", ".WWWWW.", ".WWWWW.", "..WWW..", "......."]
	match id:
		"person":
			g = ["..HHH..", "..SSS..", "..SSS..", ".BBBBB.", "S.BBB.S", "..L.L..", "..L.L.."]
		"heart":
			g = [".RR.RR.", "RWRRRRR", "RRRRRRR", "RRRRRRR", ".RRRRR.", "..RRR..", "...R..."]
		"apple":
			g = ["...g...", "..Gg...", ".RRWRR.", "RRWRRRR", "RRRRRRR", ".RRRRR.", "..R.R.."]
		"house":
			g = ["...R...", "..RRR..", ".RRRRR.", "RRRRRRR", ".WWDWW.", ".WWDWW.", ".WWWWW."]
		"flag":
			g = ["PFFFF..", "PFFFFF.", "PFFFF..", "PFF....", "P......", "P......", "P......"]
		"crown":
			g = [".......", "Y.Y.Y.Y", "YYYYYYY", "YRYBYCY", "YYYYYYY", ".......", "......."]
		"sword":
			g = ["......W", ".....WG", "....WG.", "Y..WG..", ".YWG...", "..b....", ".b.Y..."]
		"skull":
			g = [".WWWWW.", "WWWWWWW", "WKKWKKW", "WWWKWWW", ".WWWWW.", ".W.W.W.", "......."]
		"hourglass":
			g = ["YYYYYYY", ".G...G.", "..GsG..", "...s...", "..GsG..", ".GsssG.", "YYYYYYY"]
		"star":
			g = ["...Y...", "..YYY..", "YYYYYYY", ".YYYYY.", "..YYY..", ".YY.YY.", "Y.....Y"]
		"gem":
			g = ["..CCC..", ".CWCCC.", "CCCCCCC", ".CCCCC.", "..CCC..", "...C...", "......."]
		"orb":
			g = ["..VVV..", ".VWVVV.", "VVVVVVV", "VVVVVVV", ".VVVVV.", "..VVV..", "......."]
		"arrow":
			g = ["...G...", "..GGG..", ".GGGGG.", "GGGGGGG", "..GGG..", "..GGG..", "..GGG.."]
		"eye":
			g = [".......", "..WWW..", ".WWKWW.", "WWKCKWW", ".WWKWW.", "..WWW..", "......."]
		"hammer":
			g = [".GGG...", "GGGGG..", ".GGG...", "..b....", "...b...", "....b..", ".....b."]
		"hand":
			g = [".......", "SS...TT", "SSS.TTT", ".SSSTT.", "..SST..", "...S...", "......."]
		"yinyang":
			g = ["..WWK..", ".WWWKK.", "WWKWKKK", "WWWKKKK", "WWWWKWK", ".WWWKK.", "..WKK.."]
		"bars":
			g = [".......", ".....C.", ".....C.", "...C.C.", "...C.C.", ".C.C.C.", ".C.C.C."]
		"bolt":
			g = ["...YY..", "..YY...", ".YYYYY.", "...YY..", "..YY...", ".YY....", ".Y....."]
		"castle":
			g = ["G.G.G.G", "GGGGGGG", ".GGGGG.", ".GGKGG.", ".GGKGG.", ".GGGGG.", "......."]
		"scroll":
			g = [".sssss.", "s.....s", ".sKKKs.", ".s...s.", ".sKKKs.", "s.....s", ".sssss."]
		"tag":
			g = [".YYYYY.", "YYYYYYY", "YKYYYYY", "YYYYYYY", ".YYYYY.", ".......", "......."]
		"clover":
			g = [".gg.gg.", "gGGgGGg", ".gGGGg.", "gGGgGGg", ".gg.gg.", "...b...", "....b.."]
		"shield":
			g = ["BBBBBBB", "BWBBBWB", "BBWBWBB", "BBBWBBB", ".BBBBB.", "..BBB..", "...B..."]
		"drop":
			g = ["...R...", "..RRR..", ".RRRRR.", ".RWRRR.", ".RRRRR.", "..RRR..", "......."]
		"lotus":
			g = ["...V...", "..VVV..", "V.VVV.V", "VVVVVVV", ".VVVVV.", "..ggg..", "......."]
		"wand":
			g = ["Y.....Y", ".Y...Y.", "...Y...", "..b....", ".b.....", "b......", "......."]
	var pal: Dictionary = {"H": "#5a3a22", "S": "#f0c090", "B": "#3d6fd0", "L": "#3a2c26", "R": "#e0402e", "W": "#eef2f0", "g": "#3a7a2a",
		"G": "#9aa4ac", "D": "#5a3a22", "P": "#8a6a3a", "F": "#3d6fd0", "Y": "#f0c040", "C": "#62d8a4", "K": "#22262a", "s": "#e8d090",
		"b": "#7a5030", "T": "#c8a070", "V": "#b98cff"}
	if id == "arrow":
		pal["G"] = "#6fd24a"
	if id == "house":
		pal["R"] = "#c63a2a"
		pal["W"] = "#e8dcc0"
	if id == "clover":
		pal["g"] = "#2f8a3a"
		pal["G"] = "#6fd24a"
	if id == "lotus":
		pal["V"] = "#f08ac0"
	var q: Px = Px.new(9, 9)
	q.draw_image(Px.grid(g, pal), 1, 1)
	q.outline(Color("#0e1214"))
	var t: ImageTexture = q.tex()
	_tex_cache[key] = t
	return t


func _rich(fs: int = 13) -> RichTextLabel:
	var r: RichTextLabel = RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.selection_enabled = false
	r.meta_underlined = false
	r.add_theme_font_override("normal_font", ThemeDB.fallback_font)
	r.add_theme_font_override("bold_font", font_bold)
	r.add_theme_font_size_override("normal_font_size", fs)
	r.add_theme_font_size_override("bold_font_size", fs)
	r.add_theme_constant_override("line_separation", 3)
	r.add_theme_color_override("default_color", Color("#eef3ea"))
	r.meta_clicked.connect(func(m: Variant) -> void: meta_clicked.emit(str(m)))
	return r


func _win_style() -> StyleBoxFlat:
	var s: StyleBoxFlat = sb(C_SLATE, Color("#0c1013"), 2, 4)
	s.set_content_margin_all(0)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 3)
	return s


func _win_bevel(c: Control) -> void:
	var w: float = c.size.x
	var h: float = c.size.y
	c.draw_rect(Rect2(2, 2, w - 4, h - 4), C_SLATE_EDGE, false, 1.0)


func _title_bar(lbl: Label, close_cb: Callable, fold: Button = null) -> PanelContainer:
	var tb: PanelContainer = PanelContainer.new()
	var ts: StyleBoxFlat = sb(C_SLATE_DK, Color("#3a4850"), 0, 2)
	ts.border_width_bottom = 2
	ts.border_color = Color("#11171b")
	ts.content_margin_left = 10
	ts.content_margin_right = 4
	ts.content_margin_top = 4
	ts.content_margin_bottom = 4
	tb.add_theme_stylebox_override("panel", ts)
	tb.draw.connect(func() -> void:
		tb.draw_rect(Rect2(2, 1, tb.size.x - 4, 1), Color(1, 1, 1, 0.07)))
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	tb.add_child(h)
	if fold != null:
		h.add_child(fold)
	else:
		var pad: Control = Control.new()
		pad.custom_minimum_size = Vector2(0, 0)
		h.add_child(pad)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.clip_text = true
	h.add_child(lbl)
	h.add_child(_close_button(close_cb))
	return tb


func _close_button(cb: Callable) -> Button:
	var x: Button = Button.new()
	x.custom_minimum_size = Vector2(26, 26)
	_style_button(x, _tex_style(red_tex(26, 26), 6))
	if not _tex_cache.has("closex"):
		var q: Px = Px.new(12, 12)
		for k: int in range(8):
			q.p(2 + k, 2 + k, 2, 2, "#f4f0ea")
			q.p(8 - k, 2 + k, 2, 2, "#f4f0ea")
		q.outline(Color("#5a1a12"))
		_tex_cache["closex"] = q.tex()
	x.icon = _tex_cache["closex"]
	x.add_theme_constant_override("icon_max_width", 14)
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
	insp.draw.connect(_win_bevel.bind(insp))
	add_child(insp)
	var v: VBoxContainer = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 0)
	insp.add_child(v)
	insp_title = _label("", 16, Color("#f2f6f8"), 4, Color("#0c1013"))
	insp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Zuklappen: nur Kopf und Knöpfe, die Karte bleibt frei
	insp_fold = Button.new()
	insp_fold.custom_minimum_size = Vector2(26, 26)
	_style_button(insp_fold, _tex_style(well_tex("n", 26, 26), 6))
	insp_fold.tooltip_text = "Fold / unfold"
	insp_fold.draw.connect(func() -> void:
		var c: Vector2 = insp_fold.size / 2.0
		var pts: PackedVector2Array = PackedVector2Array([c + Vector2(-5, -2), c + Vector2(5, -2), c + Vector2(0, 4)]) if not insp_collapsed else PackedVector2Array([c + Vector2(-2, -5), c + Vector2(-2, 5), c + Vector2(4, 0)])
		insp_fold.draw_colored_polygon(pts, Color("#e8c70a")))
	insp_fold.pressed.connect(func() -> void:
		insp_collapsed = not insp_collapsed
		insp_fold.queue_redraw()
		tick_layout())
	v.add_child(_title_bar(insp_title, close_insp, insp_fold))
	var inner: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		inner.add_theme_constant_override("margin_" + side, 8)
	v.add_child(inner)
	var iv: VBoxContainer = VBoxContainer.new()
	iv.add_theme_constant_override("separation", 8)
	inner.add_child(iv)
	insp_head = HBoxContainer.new()
	insp_head.add_theme_constant_override("separation", 10)
	iv.add_child(insp_head)
	insp_scroll = ScrollContainer.new()
	insp_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	insp_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	insp_scroll.scroll_deadzone = 6
	iv.add_child(insp_scroll)
	insp_rows = VBoxContainer.new()
	insp_rows.add_theme_constant_override("separation", 1)
	insp_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	insp_scroll.add_child(insp_rows)
	insp_text = _rich()
	insp_text.visible = false
	iv.add_child(insp_text)
	insp_btns = HFlowContainer.new()
	insp_btns.add_theme_constant_override("h_separation", 5)
	insp_btns.add_theme_constant_override("v_separation", 5)
	iv.add_child(insp_btns)
	modal = ColorRect.new()
	modal.color = Color(0.02, 0.03, 0.05, 0.55)
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
	modal_panel.draw.connect(_win_bevel.bind(modal_panel))
	modal.add_child(modal_panel)
	var mvv: VBoxContainer = VBoxContainer.new()
	mvv.add_theme_constant_override("separation", 0)
	modal_panel.add_child(mvv)
	modal_title = _label("", 16, Color("#f2f6f8"), 4, Color("#0c1013"))
	modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mvv.add_child(_title_bar(modal_title, close_modal))
	var mbg: PanelContainer = PanelContainer.new()
	var ms: StyleBoxFlat = sb(C_SLATE_ROW, Color.TRANSPARENT, 0, 3)
	ms.set_content_margin_all(10)
	mbg.add_theme_stylebox_override("panel", ms)
	mbg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mm: MarginContainer = MarginContainer.new()
	for side2: String in ["left", "right", "top", "bottom"]:
		mm.add_theme_constant_override("margin_" + side2, 6)
	mm.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mm.add_child(mbg)
	mvv.add_child(mm)
	var msc: ScrollContainer = ScrollContainer.new()
	msc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mbg.add_child(msc)
	var mv: VBoxContainer = VBoxContainer.new()
	mv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mv.add_theme_constant_override("separation", 10)
	msc.add_child(mv)
	modal_text = _rich()
	modal_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mv.add_child(modal_text)
	modal_input = LineEdit.new()
	modal_input.visible = false
	modal_input.custom_minimum_size = Vector2(0, 32)
	modal_input.add_theme_stylebox_override("normal", sb(C_SLATE_DK, Color("#4d5d66"), 1, 3))
	modal_input.add_theme_stylebox_override("focus", sb(C_SLATE_DK, C_BLUE, 1, 3))
	modal_input.add_theme_font_size_override("font_size", 14)
	modal_input.text_submitted.connect(func(txt: String) -> void:
		if _input_cb.is_valid():
			var cb: Callable = _input_cb
			_input_cb = Callable()
			close_modal()
			cb.call(txt))
	mv.add_child(modal_input)
	modal_btns = HFlowContainer.new()
	modal_btns.add_theme_constant_override("h_separation", 6)
	modal_btns.add_theme_constant_override("v_separation", 6)
	mv.add_child(modal_btns)


func _fill_buttons(box: Container, buttons: Array) -> void:
	for c: Node in box.get_children():
		c.queue_free()
	for e: Array in buttons:
		var b: Button = Button.new()
		b.text = e[0]
		var kind: String = e[2] if e.size() > 2 else ""
		var col: Color = C_RED if kind == "red" else (Color("#2f8a64") if kind == "jade" else Color("#3e4c56"))
		var st: StyleBoxFlat = sb(col, col.darkened(0.55), 1, 2)
		st.border_width_bottom = 3
		st.content_margin_left = 10
		st.content_margin_right = 10
		st.content_margin_top = 4
		st.content_margin_bottom = 4
		_style_button(b, st)
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_color_override("font_color", Color("#f4f8f4"))
		b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
		b.add_theme_constant_override("outline_size", 3)
		var cb: Callable = e[1]
		b.pressed.connect(cb)
		box.add_child(b)


## Banner mit Clan-Siegel wie auf den Dorf-Schildern.
func _banner(col: Color, glyph: String) -> Control:
	var c: Control = Control.new()
	c.custom_minimum_size = Vector2(40, 50)
	c.draw.connect(func() -> void:
		var w: float = c.size.x
		var h: float = c.size.y
		c.draw_rect(Rect2(0, 0, w, h), col.darkened(0.62))
		c.draw_rect(Rect2(2, 2, w - 4, h - 4), col.darkened(0.08))
		c.draw_rect(Rect2(4.5, 4.5, w - 9, h - 9), col.lightened(0.38), false, 1.0)
		c.draw_rect(Rect2(6, 6, w - 12, h - 12), col.darkened(0.18))
		for q: Vector2 in [Vector2(-1, -1), Vector2(w - 3, -1), Vector2(-1, h - 3), Vector2(w - 3, h - 3)]:
			c.draw_rect(Rect2(q, Vector2(4, 4)), col.darkened(0.62))
		var gw: float = font_cjk.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		c.draw_string(font_cjk, Vector2(roundf(w / 2.0 - gw / 2.0), h / 2.0 + 8.0), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, col.lightened(0.75)))
	return c


## Inspektionskarte oben: Kopf (Bild + Titel), Werte-Zeilen, Knöpfe [[Text, Callable, Art]].
func open_insp(head_tex: Texture2D, head_glyph: String, head_col: Color, title: String, sub: String, body: String, buttons: Array) -> void:
	for c: Node in insp_head.get_children():
		c.queue_free()
	insp_title.text = title
	if head_tex != null:
		var tr: TextureRect = TextureRect.new()
		tr.texture = head_tex
		tr.custom_minimum_size = Vector2(48, 48)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var pb: PanelContainer = PanelContainer.new()
		var ps: StyleBox = _tex_style(well_tex("n", 54, 54), 6)
		ps.content_margin_left = 3
		ps.content_margin_right = 3
		ps.content_margin_top = 3
		ps.content_margin_bottom = 3
		pb.add_theme_stylebox_override("panel", ps)
		pb.add_child(tr)
		insp_head.add_child(pb)
	elif head_glyph != "":
		insp_head.add_child(_banner(head_col, head_glyph))
	var tv: VBoxContainer = VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.add_theme_constant_override("separation", 0)
	var first: bool = true
	for line: String in sub.split("\n"):
		if line == "":
			continue
		var sl: Label = Label.new()
		sl.text = line
		sl.add_theme_font_override("font", font_bold if first else ThemeDB.fallback_font)
		sl.add_theme_font_size_override("font_size", 13 if first else 12)
		sl.add_theme_color_override("font_color", Color("#62a6e6") if first else Color("#a8b8c0"))
		first = false
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tv.add_child(sl)
	insp_head.add_child(tv)
	insp_sig = ""
	update_insp_body(body)
	_fill_buttons(insp_btns, buttons)
	insp_btns.visible = not buttons.is_empty()
	insp_scroll.scroll_vertical = 0
	insp.visible = true
	insp_scroll.custom_minimum_size.y = 0.0
	tick_layout()


## Zerlegt den BBCode-Text in Zeilen: "Name  Wert" wird zur Werte-Zeile mit Symbol.
func update_insp_body(body: String) -> void:
	insp_text.text = body
	var lines: PackedStringArray = body.split("\n")
	var sig: String = ""
	for line: String in lines:
		sig += (line.substr(0, line.find("[/color]")) if line.begins_with(MT_PREFIX) else "#") + "|"
	if sig == insp_sig and insp_rows.get_child_count() == lines.size():
		for k: int in range(lines.size()):
			var row: Control = insp_rows.get_child(k)
			if row.has_meta("val"):
				(row.get_meta("val") as RichTextLabel).text = _row_value(lines[k])
			elif row is RichTextLabel:
				(row as RichTextLabel).text = lines[k]
		return
	insp_sig = sig
	for c: Node in insp_rows.get_children():
		insp_rows.remove_child(c)
		c.queue_free()
	var n: int = 0
	for line: String in lines:
		if line.begins_with(MT_PREFIX) and line.find("[/color]  ") > 0:
			var name: String = line.substr(MT_PREFIX.length(), line.find("[/color]") - MT_PREFIX.length())
			var row2: PanelContainer = PanelContainer.new()
			var rs: StyleBoxFlat = sb(C_SLATE_ROW if n % 2 == 0 else C_SLATE_ROW2, Color.TRANSPARENT, 0, 2)
			rs.content_margin_left = 4
			rs.content_margin_right = 6
			rs.content_margin_top = 1
			rs.content_margin_bottom = 1
			row2.add_theme_stylebox_override("panel", rs)
			var h: HBoxContainer = HBoxContainer.new()
			h.add_theme_constant_override("separation", 6)
			row2.add_child(h)
			var ic: TextureRect = TextureRect.new()
			ic.texture = stat_icon(STAT_ICON.get(name, "dot"))
			ic.custom_minimum_size = Vector2(18, 18)
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(ic)
			var nl: Label = Label.new()
			nl.text = name
			nl.custom_minimum_size = Vector2(76, 0)
			nl.add_theme_font_override("font", ThemeDB.fallback_font)
			nl.add_theme_font_size_override("font_size", 12)
			nl.add_theme_color_override("font_color", Color("#9fb0b8"))
			nl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(nl)
			var val: RichTextLabel = _rich(12)
			val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			val.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			val.text = _row_value(line)
			h.add_child(val)
			row2.set_meta("val", val)
			insp_rows.add_child(row2)
			n += 1
		elif line.strip_edges() == "":
			var sp: Control = Control.new()
			sp.custom_minimum_size = Vector2(0, 4)
			insp_rows.add_child(sp)
		else:
			var r: RichTextLabel = _rich(12)
			r.text = line
			insp_rows.add_child(r)


static func _row_value(line: String) -> String:
	var i: int = line.find("[/color]  ")
	return "[b]" + line.substr(i + 10) + "[/b]" if i >= 0 else line


func close_insp() -> void:
	insp.visible = false


const H_PREFIX: String = "[font_size=20][color=#9fd0ff][b]"


func open_modal(body: String, buttons: Array = []) -> void:
	var title: String = ""
	if body.begins_with(H_PREFIX):
		var e: int = body.find("[/b]")
		title = body.substr(H_PREFIX.length(), e - H_PREFIX.length())
		var rest: int = body.find("[/font_size]")
		body = body.substr(rest + 12).lstrip("\n")
	modal_title.text = title
	modal_text.text = body
	modal_input.visible = false
	_input_cb = Callable()
	_fill_buttons(modal_btns, buttons)
	modal_btns.visible = not buttons.is_empty()
	modal.visible = true


func close_modal() -> void:
	modal.visible = false
	modal_input.visible = false
	modal_input.release_focus()


## Fenster mit Eingabezeile (z. B. „Namen ändern“): ok bekommt den Text.
func open_input(body: String, value: String, ok_text: String, ok: Callable) -> void:
	open_modal(body, [[ok_text, func() -> void:
		var txt: String = modal_input.text
		_input_cb = Callable()
		close_modal()
		ok.call(txt), "jade"], ["Cancel", func() -> void: close_modal(), ""]])
	modal_input.text = value
	modal_input.visible = true
	_input_cb = ok
	if modal_input.is_inside_tree():
		modal_input.grab_focus()
		modal_input.select_all()


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
	load_label = _label("The five regions are taking shape …", 15, Color.WHITE)
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
	bar_hidden = h
	bar.visible = not h
	top_r.visible = not h
	toasts.visible = not h
	hint_box.visible = not h
	age_lbl.visible = not h
	show_btn.visible = h
	tool_pill.visible = false if h else tool_pill.visible
	_hide_tip()
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
		var w: int = int(size.x)
		var h: int = int(size.y)
		var ins: int = 7
		var dark: Color = Color("#7e241a") if active else Color("#2e3a2b")
		var face: Color = Color("#c5332b") if active else Color("#4a5847")
		var bev: Color = Color("#d8603e") if active else Color("#5f735b")
		var top: Color = Color("#e08048") if active else Color("#6e8367")
		var key: Color = Color("#a82a22") if active else Color("#3c4939")
		for y: int in range(h):
			var l: int = int(round(ins * float(h - 1 - y) / float(h - 1)))
			draw_rect(Rect2(l, y, w - 2 * l, 1), dark)
			if y == 0:
				continue
			draw_rect(Rect2(l + 1, y, w - 2 * l - 2, 1), bev)
			draw_rect(Rect2(l + 3, y, w - 2 * l - 6, 1), face)
		draw_rect(Rect2(ins + 1, 1, w - 2 * ins - 2, 2), top)
		if active:
			# schräge Glanzstreifen
			for k: int in range(2):
				var x0: float = w * (0.18 + k * 0.08)
				for y: int in range(4, h):
					draw_rect(Rect2(x0 + (h - y) * 0.6, y, 2, 1), Color(1, 0.55, 0.35, 0.28))
		else:
			# Mäander-Gravur an beiden Seiten
			for sd: int in [0, 1]:
				for y: int in range(6, h - 3):
					var l2: int = int(round(ins * float(h - 1 - y) / float(h - 1))) + 5
					var xx: int = l2 if sd == 0 else w - 1 - l2
					draw_rect(Rect2(xx, y, 1, 1), key)
				var yb: int = h - 4
				var lb: int = int(round(ins * float(h - 1 - yb) / float(h - 1))) + 5
				var xa: int = lb if sd == 0 else w - lb - 6
				draw_rect(Rect2(xa, yb, 6, 1), key)
				draw_rect(Rect2(xa + (5 if sd == 0 else 0), yb - 4, 1, 4), key)
				draw_rect(Rect2(xa + (3 if sd == 0 else 0), yb - 4, 3, 1), key)
		if icon_tex != null:
			var iw: float = minf(w * 0.62, 40.0)
			var ih: float = iw * 0.5
			draw_texture_rect(icon_tex, Rect2(roundf((w - iw) * 0.5), roundf((h - ih) * 0.5 + 1), roundf(iw), roundf(ih)), false)
