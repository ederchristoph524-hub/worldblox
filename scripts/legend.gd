class_name PowerLegend
extends PanelContainer
## Zuklappbare Legende der stärksten Mächte (oben links unter der Zeitalter-Zeile), sichtbar solange die
## Gebietsanzeige an ist. Je Macht: Farbe mit Siegel, Name, Dörfer, Bund und beherrschender Ehrwürdiger.
## Tippen auf einen Eintrag meldet pick(Clan-Id) – GuMain zoomt zur Hauptstadt.

signal pick(clan_id: int)

const MAX_ROWS: int = 5
const WIDTH: float = 200.0

var hud: Hud
var sim: Sim
var collapsed: bool = false  ## in der Übersicht zugeklappt
var open_near: bool = false  ## nah herangezoomt aufgeklappt (sonst dort automatisch zu)
var near: bool = false  ## Kamera ist nah (von GuMain gesetzt)
var head_btn: Button
var rows: VBoxContainer
var _stamp: int = -1
var _lay: int = -1
var _sig: String = ""


func _init(h: Hud) -> void:
	hud = h
	var st: StyleBoxFlat = Hud.sb(Color(0.055, 0.072, 0.062, 0.84), Hud.C_RIM, 1, 4)
	st.content_margin_left = 4
	st.content_margin_right = 4
	st.content_margin_top = 2
	st.content_margin_bottom = 3
	add_theme_stylebox_override("panel", st)
	custom_minimum_size = Vector2(WIDTH, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	add_child(v)
	head_btn = Button.new()
	head_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	head_btn.flat = true
	head_btn.focus_mode = Control.FOCUS_NONE
	head_btn.add_theme_font_size_override("font_size", 11)
	head_btn.add_theme_color_override("font_color", Hud.C_YELLOW)
	head_btn.add_theme_color_override("font_hover_color", Color("#fff08a"))
	head_btn.add_theme_color_override("font_pressed_color", Hud.C_YELLOW)
	head_btn.add_theme_constant_override("outline_size", 3)
	head_btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	head_btn.custom_minimum_size = Vector2(0, 20)
	for k: String in ["normal", "hover", "pressed", "focus"]:
		head_btn.add_theme_stylebox_override(k, StyleBoxEmpty.new())
	head_btn.pressed.connect(func() -> void:
		if near:
			open_near = not open_near
		else:
			collapsed = not collapsed
		_stamp = -1
		refresh())
	v.add_child(head_btn)
	rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 1)
	v.add_child(rows)


## Neu aufbauen, wenn sich die Einflussdaten geändert haben (Influence.stamp).
func refresh() -> void:
	var fold: bool = (not open_near) if near else collapsed
	if sim == null or (_stamp == Influence.stamp and _lay == sim.world.layer and rows.visible != fold):
		return
	_stamp = Influence.stamp
	_lay = sim.world.layer
	var lay: String = World.LAYER_NAME[sim.world.layer] if sim.world.layer < World.LAYER_NAME.size() else ""
	head_btn.text = ("+  " if fold else "−  ") + "Mächte · " + lay
	rows.visible = not fold
	if fold:
		return
	var sig: String = ""
	var items: Array = []
	for h: int in Influence.tops:
		if items.size() >= MAX_ROWS:
			break
		var c: Clan = sim.clans[h]
		var b: Dictionary = Influence.bloc.get(h, {})
		var nm: int = int(b.get("n", 1))
		var sub: String = "%d Dörfer" % int(b.get("v", 0)) if int(b.get("v", 0)) != 1 else "1 Dorf"
		if nm > 1:
			sub += " · Bund aus %d" % nm
		if not c.war.is_empty():
			sub += " · Krieg"
		var dm: Dictionary = Influence.dominion_of(c)
		var ven: String = str(dm.get("name", ""))
		var vcol: Color = dm.get("col", Color.WHITE)
		var L: Unit = c.lead
		var rk: int = L.rank if L != null and L.hp > 0.0 else 0
		items.append([h, Influence.bloc_name(c), sub, c.col, c.glyph, ven, vcol, rk, c.align])
		sig += "%d|%s|%s|%s|%d;" % [h, Influence.bloc_name(c), sub, ven, rk]
	if sig == _sig and rows.get_child_count() == items.size():
		return
	_sig = sig
	for ch: Node in rows.get_children():
		rows.remove_child(ch)
		ch.queue_free()
	for it: Array in items:
		rows.add_child(_row(it))
	if items.is_empty():
		var l: Label = Label.new()
		l.text = "Noch keine Mächte"
		l.add_theme_font_size_override("font_size", 10)
		l.add_theme_color_override("font_color", Hud.C_MUTED)
		rows.add_child(l)


func _row(it: Array) -> Button:
	var b: Button = Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	var has_ven: bool = str(it[5]) != ""
	b.custom_minimum_size = Vector2(WIDTH - 8.0, 35.0 if has_ven else 25.0)
	var hov: StyleBoxFlat = Hud.sb(Color(1, 1, 1, 0.07), Color.TRANSPARENT, 0, 3)
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", hov)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.tooltip_text = "Zur Hauptstadt"
	var id: int = int(it[0])
	b.pressed.connect(func() -> void: pick.emit(id))
	b.draw.connect(func() -> void: _draw_row(b, it))
	return b


func _draw_row(b: Button, it: Array) -> void:
	var col: Color = it[3]
	var fb: Font = hud.font_bold
	var fr: Font = ThemeDB.fallback_font
	var cjk: Font = hud.font_cjk
	var w: float = b.size.x
	# Siegel-Kästchen in Clanfarbe (dämonisch: dunkelroter Rand)
	var sx: float = 2.0
	var sy: float = 3.0
	var ss: float = 18.0
	b.draw_rect(Rect2(sx - 1.0, sy - 1.0, ss + 2.0, ss + 2.0), Color("#5a0c0c") if int(it[8]) == 1 else col.darkened(0.65))
	b.draw_rect(Rect2(sx, sy, ss, ss), col.darkened(0.06))
	b.draw_rect(Rect2(sx + 2.0, sy + 2.0, ss - 4.0, ss - 4.0), col.lightened(0.4), false, 1.0)
	var gl: String = it[4]
	var gw: float = cjk.get_string_size(gl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	b.draw_string(cjk, Vector2(roundf(sx + ss / 2.0 - gw / 2.0), sy + 13.5), gl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col.lightened(0.8))
	var tx: float = sx + ss + 5.0
	var rk: int = int(it[7])
	var rtxt: String = ("R%d" % rk) if rk > 0 else ""
	var rw: float = fb.get_string_size(rtxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	var nm: String = _fit(fb, str(it[1]), 11, w - tx - rw - 6.0)
	b.draw_string_outline(fb, Vector2(tx, 12.0), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 3, Color(0, 0, 0, 0.6))
	b.draw_string(fb, Vector2(tx, 12.0), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col.lightened(0.55))
	if rtxt != "":
		b.draw_string(fb, Vector2(w - rw - 3.0, 12.0), rtxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, GuData.ESS_COL[clampi(rk, 0, GuData.ESS_COL.size() - 1)].lightened(0.2))
	b.draw_string(fr, Vector2(tx, 22.0), _fit(fr, str(it[2]), 9, w - tx - 2.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Hud.C_MUTED)
	if str(it[5]) != "":
		TerrOverlay._crown(b, Vector2(tx + 5.0, 25.0), 0.55, Color("#ffd24a"))
		b.draw_string(fr, Vector2(tx + 12.0, 32.0), _fit(fr, str(it[5]), 9, w - tx - 14.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, (it[6] as Color).lightened(0.35))


static func _fit(f: Font, s: String, fs: int, maxw: float) -> String:
	if f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x <= maxw:
		return s
	while s.length() > 2 and f.get_string_size(s + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > maxw:
		s = s.substr(0, s.length() - 1)
	return s + "…"
