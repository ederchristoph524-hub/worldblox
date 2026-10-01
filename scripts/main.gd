class_name GuMain
extends Node2D
## Hauptszene: verbindet Simulation, Kamera, Eingabe, Zeichnen und Oberfläche.

const W: int = GuData.W
const H: int = GuData.H
const SAVE_PATH: String = "user://gu_weltenbox.json"
const SPEEDS: PackedInt32Array = [1, 2, 5, 10]
const PS: float = 0.27
const PRESIM_YEARS: float = 16.0

var sim: Sim
var powers: Powers
var hud: Hud
var world_root: Node2D
var far_spr: Sprite2D
var near_spr: Sprite2D
var terr_spr: Sprite2D
var ents: EntityLayer
var clouds: CloudLayer
var screen: ScreenLayer
var bg: TextureRect

var cam: Vector2 = Vector2(W / 2.0, H / 2.0)
var z: float = 1.4
var min_z: float = 0.8
const MAX_Z: float = 24.0
var shake_off: Vector2 = Vector2.ZERO

var paused: bool = false
var speed_idx: int = 0
var tab: int = -1
var tool_id: String = ""
var sel_unit: Unit = null
var sel_vil: Village = null
var insp_kind: String = ""
var follow: bool = false
var gift_cd: float = 0.0
var ui_hidden: bool = false
var show_terr: bool = true
var show_names: bool = true
var sim_acc: float = 0.0
var loading: bool = false
var load_live: bool = true
var insp_t: float = 0.0
var terr_t: float = 0.0
var auto_t: float = 0.0
var hover: Vector2 = Vector2(-1, -1)
var fresh: bool = false  ## Entwickler: --fresh lädt und speichert nichts

# Eingabe
var touches: Dictionary = {}
var gesture: Dictionary = {}
var stroke: Dictionary = {}
var last_spawn: int = 0


func _ready() -> void:
	randomize()
	sim = Sim.new()
	add_child(sim)
	powers = Powers.new(sim)
	sim.logged.connect(func(t: String, k: String, _n: bool) -> void: hud.toast(t, k, sim.year()))
	sim.unit_died.connect(func(u: Unit) -> void:
		if u == sel_unit:
			sel_unit = null
			follow = false
			if insp_kind == "u":
				_close_insp())
	_build_scene()
	get_viewport().size_changed.connect(_on_resize)
	_on_resize()
	_apply_tab(-1)
	fresh = "--fresh" in OS.get_cmdline_user_args()
	if fresh or not _load_game():
		_start_new_world(true)
	else:
		hud.toast("Deine Welt wurde fortgesetzt.", "jade", sim.year())
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			_dev_shots(a.substr(8))
		if a == "--selftest":
			_selftest()


func _build_scene() -> void:
	var bgl: CanvasLayer = CanvasLayer.new()
	bgl.layer = -10
	add_child(bgl)
	bg = TextureRect.new()
	var gt: GradientTexture2D = GradientTexture2D.new()
	var gr: Gradient = Gradient.new()
	gr.set_color(0, Color("#1b4c8e"))
	gr.set_color(1, Color("#3376c8"))
	gr.add_point(0.55, Color("#2a68b8"))
	gt.gradient = gr
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 8
	gt.height = 64
	bg.texture = gt

	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bgl.add_child(bg)
	world_root = Node2D.new()
	world_root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(world_root)
	far_spr = Sprite2D.new()
	far_spr.centered = false
	far_spr.texture = sim.world.far_tex
	world_root.add_child(far_spr)
	near_spr = Sprite2D.new()
	near_spr.centered = false
	near_spr.texture = sim.world.near_tex
	world_root.add_child(near_spr)
	terr_spr = Sprite2D.new()
	terr_spr.centered = false
	terr_spr.texture = sim.world.terr_tex
	world_root.add_child(terr_spr)
	ents = EntityLayer.new()
	ents.m = self
	world_root.add_child(ents)
	clouds = CloudLayer.new()
	clouds.m = self
	world_root.add_child(clouds)
	var scl: CanvasLayer = CanvasLayer.new()
	scl.layer = 1
	add_child(scl)
	screen = ScreenLayer.new()
	screen.m = self
	scl.add_child(screen)
	var hl: CanvasLayer = CanvasLayer.new()
	hl.layer = 2
	add_child(hl)
	hud = Hud.new()
	hl.add_child(hud)
	hud.tab_pressed.connect(func(i: int) -> void: _apply_tab(-1 if tab == i else i))
	hud.tool_pressed.connect(_click_tool)
	hud.back_pressed.connect(_go_back)
	hud.pause_pressed.connect(_toggle_pause)
	hud.speed_pressed.connect(_cycle_speed)
	hud.star_pressed.connect(_open_rank)
	hud.gift_pressed.connect(_gift)
	hud.weather_stop.connect(func() -> void: _set_weather(""))
	hud.brush_changed.connect(func(i: int) -> void:
		powers.brush_idx = i
		hud.set_brush(i))
	hud.meta_clicked.connect(_on_meta)
	hud.show_ui_pressed.connect(func() -> void: _set_ui_hidden(false))
	hud.set_brush(powers.brush_idx)


func _on_resize() -> void:
	var vs: Vector2 = get_viewport_rect().size
	hud.position = Vector2.ZERO
	hud.size = vs
	screen.position = Vector2.ZERO
	screen.size = vs
	bg.size = vs
	var vh: float = vs.y - hud.bar_height()
	min_z = minf(vs.x / W, vh / H) * 0.92
	_clamp_cam()
	hud.layout_floaters()


func view_h() -> float:
	return maxf(120.0, get_viewport_rect().size.y - hud.bar_height())


func _clamp_cam() -> void:
	z = clampf(z, min_z, MAX_Z)
	var vs: Vector2 = get_viewport_rect().size
	var hw: float = vs.x / 2.0 / z
	var hh: float = view_h() / 2.0 / z
	var mx: float = minf(hw * 1.1, W * 0.6)
	var my: float = minf(hh * 1.1, H * 0.6)
	cam.x = clampf(cam.x, hw - mx, W - hw + mx)
	cam.y = clampf(cam.y, hh - my, H - hh + my)
	if W * z <= vs.x * 0.9:
		cam.x = clampf(cam.x, W / 2.0 - hw * 0.4, W / 2.0 + hw * 0.4)


func world_origin() -> Vector2:
	var vs: Vector2 = get_viewport_rect().size
	return Vector2(vs.x / 2.0 - cam.x * z, view_h() / 2.0 - cam.y * z) + shake_off


func to_world(p: Vector2) -> Vector2:
	var o: Vector2 = world_origin()
	return (p - o) / z


func zoom_at(p: Vector2, nz: float) -> void:
	var w: Vector2 = to_world(p)
	z = clampf(nz, min_z, MAX_Z)
	var vs: Vector2 = get_viewport_rect().size
	cam = w - (p - Vector2(vs.x / 2.0, view_h() / 2.0)) / z
	_clamp_cam()


func zoom_to(x: float, y: float, nz: float) -> void:
	z = maxf(z, nz)
	cam = Vector2(x, y)
	_clamp_cam()


# ---------------- Ablauf ----------------

func _start_new_world(live: bool) -> void:
	loading = true
	load_live = live
	hud.set_loading(true, "Die fünf Regionen entstehen …", 0.05)
	_close_insp()
	hud.close_modal()
	sel_unit = null
	sel_vil = null
	follow = false
	await get_tree().process_frame
	await get_tree().process_frame
	sim.new_world(live)
	sim.world.render_all()
	if not live:
		_finish_start()
	else:
		hud.set_loading(true, "Die Vorgeschichte vergeht …", 0.1)


func _finish_start() -> void:
	loading = false
	hud.set_loading(false)
	z = min_z
	cam = Vector2(W / 2.0, H / 2.0)
	_clamp_cam()
	sim.update_leaders()
	sim.terr_dirty = true
	sim.world.render_all()


func _process(delta: float) -> void:
	var rdt: float = minf(delta, 0.1)
	if loading:
		if load_live:
			var p: float = sim.presim_chunk(40, PRESIM_YEARS)
			hud.set_loading(true, "Die Vorgeschichte vergeht …", 0.1 + p * 0.9)
			if p >= 1.0:
				_finish_start()
		return
	if not paused:
		sim_acc += rdt * SPEEDS[speed_idx]
		var n: int = 0
		while sim_acc >= Sim.DT and n < 14:
			sim.step(Sim.DT)
			sim_acc -= Sim.DT
			n += 1
		if n >= 14:
			sim_acc = 0.0
	if follow and sel_unit != null and sel_unit.hp > 0.0:
		cam += (Vector2(sel_unit.x, sel_unit.y) - cam) * minf(1.0, rdt * 6.0)
		_clamp_cam()
	if sim.world.water_dirty:
		sim.world.refresh_water()
	sim.world.flush_dirty(4)
	terr_t -= rdt
	if sim.terr_dirty and show_terr and terr_t <= 0.0 and z < 2.6:
		terr_t = 1.5
		sim.terr_dirty = false
		sim.world.update_territory(sim.villages, sim.clans)
	# Kamera-Wackeln
	if sim.shake > 0.0:
		sim.shake = maxf(0.0, sim.shake - rdt * 1.6)
		shake_off = Vector2((randf() - 0.5) * sim.shake * 10.0, (randf() - 0.5) * sim.shake * 10.0)
	else:
		shake_off = Vector2.ZERO
	world_root.position = world_origin()
	world_root.scale = Vector2(z, z)
	var lod: float = clampf((z - 2.0) / 0.9, 0.0, 1.0)
	near_spr.modulate.a = lod
	near_spr.visible = lod > 0.0
	terr_spr.visible = show_terr and z < 2.6
	terr_spr.modulate.a = clampf((2.6 - z) / 0.8, 0.0, 0.75)
	ents.queue_redraw()
	clouds.tick(rdt)
	clouds.queue_redraw()
	screen.tick(rdt)
	screen.queue_redraw()
	insp_t -= rdt
	if insp_t <= 0.0:
		insp_t = 0.6
		_refresh_insp()
	if gift_cd > 0.0:
		gift_cd -= rdt
		hud.gift_btn.disabled = gift_cd > 0.0
	var ad: Dictionary = sim.age_data()
	hud.age_lbl.text = "%s · Jahr %d · nächstes in %d Jahren" % [ad["n"], sim.year(), sim.years_to_next_age()]
	auto_t += rdt
	if auto_t > 60.0:
		auto_t = 0.0
		_save_game()


# ---------------- Eingabe ----------------

func _unhandled_input(e: InputEvent) -> void:
	if loading:
		return
	if e.is_action_pressed("toggle_pause"):
		_toggle_pause()
		return
	if e.is_action_pressed("zoom_in"):
		zoom_at(get_viewport_rect().size * Vector2(0.5, 0.0) + Vector2(0, view_h() / 2.0), z * 1.25)
		return
	if e.is_action_pressed("zoom_out"):
		zoom_at(get_viewport_rect().size * Vector2(0.5, 0.0) + Vector2(0, view_h() / 2.0), z / 1.25)
		return
	if e.is_action_pressed("ui_back"):
		_go_back()
		return
	if e.is_action_pressed("speed_cycle"):
		_cycle_speed()
		return
	if e.is_action_pressed("quick_save"):
		_save_game()
		hud.toast("Welt gespeichert (Jahr %d)." % sim.year(), "jade", sim.year())
		return
	if e is InputEventScreenTouch:
		var st: InputEventScreenTouch = e
		if st.pressed:
			touches[st.index] = st.position
			if touches.size() == 2:
				var ps: Array = touches.values()
				var a: Vector2 = ps[0]
				var b: Vector2 = ps[1]
				gesture = {"type": "pinch", "d0": maxf(1.0, a.distance_to(b)), "z0": z, "w0": to_world((a + b) / 2.0)}
		else:
			touches.erase(st.index)
			if touches.size() < 2 and gesture.get("type", "") == "pinch":
				gesture = {"type": "pan", "last": touches.values()[0] if touches.size() == 1 else Vector2.ZERO, "moved": 99.0, "tap": false}
				if touches.is_empty():
					gesture = {}
		return
	if e is InputEventScreenDrag:
		var sd: InputEventScreenDrag = e
		touches[sd.index] = sd.position
		if gesture.get("type", "") == "pinch" and touches.size() >= 2:
			var ps2: Array = touches.values()
			var a2: Vector2 = ps2[0]
			var b2: Vector2 = ps2[1]
			var d: float = maxf(1.0, a2.distance_to(b2))
			z = clampf(float(gesture["z0"]) * d / float(gesture["d0"]), min_z, MAX_Z)
			var vs: Vector2 = get_viewport_rect().size
			cam = Vector2(gesture["w0"]) - ((a2 + b2) / 2.0 - Vector2(vs.x / 2.0, view_h() / 2.0)) / z
			_clamp_cam()
			follow = false
		return
	if touches.size() >= 2:
		return
	if e is InputEventMouseButton:
		var mb: InputEventMouseButton = e
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom_at(mb.position, z * 1.15)
			follow = false
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom_at(mb.position, z / 1.15)
			follow = false
			return
		if mb.pressed:
			var t: Dictionary = Powers.tool_by_id(tool_id)
			var pan_btn: bool = mb.button_index != MOUSE_BUTTON_LEFT
			if not pan_btn and not t.is_empty() and (t["m"] == "paint" or t["m"] == "spawn"):
				gesture = {"type": "paint", "last": mb.position}
				stroke = {}
				powers.begin_stroke()
				_paint_at(mb.position)
			else:
				gesture = {"type": "pan", "last": mb.position, "moved": 0.0, "tap": not pan_btn}
		else:
			if gesture.get("type", "") == "pan" and gesture["tap"] and float(gesture["moved"]) < 8.0:
				_tap_at(mb.position)
			if gesture.get("type", "") != "pinch":
				gesture = {}
		return
	if e is InputEventMouseMotion:
		var mm: InputEventMouseMotion = e
		hover = mm.position
		var gt: String = gesture.get("type", "")
		if gt == "paint":
			var t2: Dictionary = Powers.tool_by_id(tool_id)
			if not t2.is_empty() and t2["m"] == "spawn":
				if Time.get_ticks_msec() - last_spawn > 130:
					last_spawn = Time.get_ticks_msec()
					_paint_at(mm.position)
				return
			var last: Vector2 = gesture["last"]
			var dd: Vector2 = mm.position - last
			var step_px: float = maxf(3.0, powers.brush_r() * z * 0.5)
			if dd.length() >= step_px:
				var n: int = ceili(dd.length() / step_px)
				for k: int in range(1, n + 1):
					_paint_at(last + dd * (float(k) / n))
				gesture["last"] = mm.position
		elif gt == "pan":
			var last2: Vector2 = gesture["last"]
			var d2: Vector2 = mm.position - last2
			gesture["moved"] = float(gesture["moved"]) + absf(d2.x) + absf(d2.y)
			if float(gesture["moved"]) > 6.0:
				cam -= d2 / z
				_clamp_cam()
				follow = false
			gesture["last"] = mm.position


func _paint_at(p: Vector2) -> void:
	var t: Dictionary = Powers.tool_by_id(tool_id)
	if t.is_empty():
		return
	var w: Vector2 = to_world(p)
	if w.x < 0 or w.y < 0 or w.x >= W or w.y >= H:
		return
	if t["m"] == "spawn":
		var msg: String = powers.spawn_at(t, w.x, w.y)
		if msg != "":
			hud.show_hint("", msg)
	else:
		powers.apply_paint(t, w.x, w.y, stroke)


func _tap_at(p: Vector2) -> void:
	var w: Vector2 = to_world(p)
	if w.x < 0 or w.y < 0 or w.x >= W or w.y >= H:
		return
	var t: Dictionary = Powers.tool_by_id(tool_id)
	if not t.is_empty() and (t["m"] == "tap" or t["m"] == "pair"):
		if t["id"] == "inspect":
			_inspect_at(w.x, w.y)
			return
		var msg: String = powers.tap_tool(t, w.x, w.y)
		if msg != "":
			hud.show_hint("", msg)
	elif t.is_empty():
		_inspect_at(w.x, w.y)


# ---------------- Werkzeuge ----------------

func _apply_tab(i: int) -> void:
	tab = i
	powers.pair_sel = null
	var t: Dictionary = Powers.tool_by_id(tool_id)
	if not t.is_empty() and int(t["tab"]) != i:
		tool_id = ""
	hud.set_tools(i)
	hud.refresh_tools(tool_id, sim.weather.get("type", ""))
	if i >= 0:
		hud.show_hint(Powers.TABS[i], "")


func _click_tool(t: Dictionary) -> void:
	if t["m"] == "act":
		_run_action(t)
		return
	powers.pair_sel = null
	tool_id = "" if tool_id == t["id"] else str(t["id"])
	hud.refresh_tools(tool_id, sim.weather.get("type", ""))
	if tool_id != "":
		hud.show_hint(t["n"], t.get("d", ""))


func _run_action(t: Dictionary) -> void:
	if t.has("w"):
		_set_weather(t["w"])
		if not sim.weather.is_empty():
			hud.show_hint(t["n"], t.get("d", ""))
		return
	match str(t["id"]):
		"winfo":
			_open_world_info()
		"help":
			_open_help()
		"chron":
			_open_chron()
		"ages":
			_open_ages()
		"laws":
			_open_laws()
		"disp":
			_open_display()
		"rank":
			_open_rank()
		"stats", "stats2":
			_open_clans()
		"will":
			var top: Array[Unit] = sim.strongest(1)
			if top.is_empty():
				hud.show_hint("", "Noch hat niemand die Aufmerksamkeit des Himmels erregt.")
				return
			sim.heavens_will(top[0])
			sel_unit = top[0]
			follow = true
			zoom_to(top[0].x, top[0].y, 8.0)
		"save":
			var ok: bool = _save_game()
			hud.toast("Welt gespeichert (Jahr %d)." % sim.year() if ok else "Speichern ist fehlgeschlagen.", "jade" if ok else "red", sim.year())
		"load":
			var ok2: bool = _load_game()
			hud.toast("Gespeicherte Welt geladen." if ok2 else "Kein Spielstand gefunden.", "jade" if ok2 else "red", sim.year())
		"new":
			hud.open_modal("[font_size=20][color=#9fd0ff][b]Neue Welt erschaffen[/b][/color][/font_size]\n\nDie aktuelle Welt geht verloren, wenn du sie nicht gespeichert hast.", [
				["Mit Clans (%d Jahre Vorgeschichte)" % int(PRESIM_YEARS), func() -> void:
					hud.close_modal()
					_start_new_world(true), "red"],
				["Nur Natur", func() -> void:
					hud.close_modal()
					_start_new_world(false), ""]])
		"hideui":
			_set_ui_hidden(true)


func _set_ui_hidden(h: bool) -> void:
	ui_hidden = h
	hud.set_ui_hidden(h)
	if h:
		_close_insp()
	_on_resize()


func _set_weather(type: String) -> void:
	if type == "" or sim.weather.get("type", "") == type:
		sim.weather = {}
	else:
		sim.weather = {"type": type, "t": 40.0}
	hud.show_weather(sim.weather.get("type", ""))
	hud.refresh_tools(tool_id, sim.weather.get("type", ""))
	hud.layout_floaters()


func _go_back() -> void:
	if hud.modal.visible:
		hud.close_modal()
		return
	if hud.insp.visible:
		_close_insp()
		return
	if powers.pair_sel != null:
		powers.pair_sel = null
		return
	if tool_id != "":
		tool_id = ""
		hud.refresh_tools("", sim.weather.get("type", ""))
		return
	if tab >= 0:
		_apply_tab(-1)


func _toggle_pause() -> void:
	paused = not paused
	hud.set_paused(paused)
	hud.show_hint("Pausiert" if paused else "Weiter", "")


func _cycle_speed() -> void:
	speed_idx = (speed_idx + 1) % SPEEDS.size()
	hud.set_speed(SPEEDS[speed_idx])
	hud.show_hint("Zeit x%d" % SPEEDS[speed_idx], "")


func _gift() -> void:
	if gift_cd > 0.0:
		return
	gift_cd = 15.0
	var p: Vector2 = powers.fate()
	if p.x >= 0.0:
		zoom_to(p.x, p.y, 6.0)


# ---------------- Inspektion ----------------

static func _c(c: Color) -> String:
	return c.to_html(false)


func _swatch(c: Color) -> String:
	return "[color=#%s]■[/color] " % _c(c)


func _inspect_at(wx: float, wy: float) -> void:
	var r: float = maxf(2.5, 18.0 / z)
	var best: Unit = null
	var bd: float = 1e9
	for u: Unit in sim.units:
		if u.hp <= 0.0:
			continue
		var d: float = Vector2(u.x - wx, u.y - 1.5 - wy).length()
		if d < r and d < bd:
			bd = d
			best = u
	if best != null:
		sel_unit = best
		sel_vil = null
		_open_unit()
		return
	var v: Village = sim.village_at(clampi(int(wx), 0, W - 1), clampi(int(wy), 0, H - 1))
	if v != null:
		sel_vil = v
		sel_unit = null
		_open_village()
		return
	sel_unit = null
	sel_vil = null
	_open_tile(int(wx), int(wy))


func _close_insp() -> void:
	hud.close_insp()
	insp_kind = ""
	follow = false


func _portrait(u: Unit) -> ImageTexture:
	var q: Px = Px.new(16, 16)
	var sink: Callable = func(r: Rect2, c: Color) -> void: q.p(roundi(r.position.x), roundi(r.position.y), maxi(1, roundi(r.size.x)), maxi(1, roundi(r.size.y)), c)
	if u.k == "p":
		var cl: Color = sim.clans[u.clan].col if u.clan >= 0 else (Color("#3a2a3a") if u.rogue else Color("#8e8676"))
		Sprites.draw_person(sink, 8.0, 14.5, 1.05 if u.rank >= 6 else 1.5, u.race, u.rank, cl, 1, sim.uage(u) >= 14.0, false, 0.0, false, false, u.rogue, u.sick > 0.0, false)
	else:
		Sprites.draw_animal(sink, 8.0, 13.0, 0.55 if u.sp == "ancient" else (0.8 if u.sp == "kingwolf" else 1.5), u.sp, 1, false, 1.0, false, u.tide, u.id)
	return q.outline().tex()


func _open_unit() -> void:
	insp_kind = "u"
	var u: Unit = sel_unit
	var sub: String
	if u.k == "p":
		var c: Clan = sim.clans[u.clan] if u.clan >= 0 else null
		var v: Village = sim.villages[u.vil] if u.vil >= 0 else null
		sub = (u.title if u.rank == 9 else GuData.rank_title(u.rank)) + ((" · " + GuData.STAGE[u.stage]) if (u.rank > 0 and u.rank < 9) else "")
		sub += "\n" + ("Dämonischer Einzelgänger" if u.rogue else ((c.name + ((" · " + v.name) if v != null else "")) if c != null else "ohne Clan"))
	else:
		sub = "Teil einer Wolfsflut" if u.tide else ("Wild – kann von Gu-Meistern veredelt werden" if u.sp == "wildgu" else "Wildtier")
	var btns: Array = [
		["Folgt" if follow else "Folgen", func() -> void:
			follow = not follow
			_open_unit(), "jade" if follow else ""]]
	if u.k == "p":
		btns.append(["Glück schenken", func() -> void:
			u.luck = 1.0
			sim.spark(u.x, u.y - 2.0, Color("#ffe27a"), 10, 5.0), ""])
	btns.append(["Auslöschen", func() -> void:
		u.dreason = "göttliche Auslöschung"
		sim.hurt(u, 1e9, null)
		_close_insp(), "red"])
	hud.open_insp(_portrait(u), "", Color.WHITE, u.pname(), sub, _unit_body(u), btns)
	hud.layout_floaters()


func _bar_txt(frac: float, col: Color, width: int = 14) -> String:
	var n: int = clampi(roundi(frac * width), 0, width)
	return "[color=#%s]%s[/color][color=#2a352c]%s[/color]" % [_c(col), "█".repeat(n), "█".repeat(width - n)]


func _unit_body(u: Unit) -> String:
	var a: float = sim.uage(u)
	var mt: String = "[color=#9db09e]"
	var s: String = ""
	if u.k == "p":
		s += mt + "Volk[/color]  " + GuData.RACE_NAME[u.race] + "\n"
		s += mt + "Alter[/color]  %d / %d Jahre\n" % [int(a), int(u.life)]
		if u.rank > 0:
			s += mt + "Pfad[/color]  " + _swatch(GuData.PATH_COL[u.path]) + GuData.PATH_NAME[u.path] + "-Pfad · " + ("dämonisch" if u.align == 1 else "rechtschaffen") + "\n"
			s += mt + "Begabung[/color]  " + ("Extremkonstitution" if u.apt == "X" else u.apt + "-Grad") + "\n"
			s += mt + "Essenz[/color]  " + _swatch(GuData.ESS_COL[u.rank]) + GuData.ESS_NAME[u.rank] + "\n"
			if u.rank < 9:
				s += mt + "Fortschritt[/color]  " + _bar_txt(u.prog, GuData.ESS_COL[u.rank]) + "\n"
		else:
			var jobs: Dictionary = {"wood": "Holzfäller", "mine": "Urstein-Bergmann", "farm": "Bauer", "gather": "Sammler", "hunt": "Jäger"}
			s += mt + "Öffnung[/color]  " + ("nicht erweckt" if u.awk else "noch nicht geprüft") + "\n"
			s += mt + "Arbeit[/color]  " + str(jobs.get(u.job, "Kind" if a < 14.0 else "–")) + "\n"
		s += mt + "Leben[/color]  " + _bar_txt(u.hp / u.mhp, Color("#d24a35")) + "\n"
		s += mt + "Siege[/color]  %d" % u.kills
		if not u.gus.is_empty():
			s += "\n\n[color=#e8c70a]Gu:[/color] " + ", ".join(u.gus)
		if u.luck > 0.0:
			s += "\n[color=#ffd23a]Großes Glück[/color]"
		if u.sick > 0.0:
			s += "\n[color=#86e04a]Seuchen-Gu[/color]"
	else:
		s += mt + "Leben[/color]  " + _bar_txt(u.hp / u.mhp, Color("#d24a35")) + "\n"
		s += mt + "Stärke[/color]  %d\n" % int(GuData.SPEC[u.sp]["atk"])
		s += mt + "Beute[/color]  %d" % u.kills
	return s


func _open_village() -> void:
	insp_kind = "v"
	var v: Village = sel_vil
	var c: Clan = sim.clans[v.clan]
	var btns: Array = [["+20 Ursteine", func() -> void:
		v.stones += 20.0
		_refresh_insp(), ""]]
	if not c.war.is_empty():
		btns.append(["Frieden schließen", func() -> void:
			for e: int in c.war.keys():
				sim.make_peace(c, sim.clans[e])
			_open_village(), "jade"])
	btns.append(["Wolfsflut rufen", func() -> void:
		sim.beast_tide(v, Vector2(-1, -1))
		_close_insp(), "red"])
	hud.open_insp(null, c.glyph, c.col, v.name, c.name + " · " + GuData.REGN[v.reg], _village_body(v), btns)
	hud.layout_floaters()


func _village_body(v: Village) -> String:
	var c: Clan = sim.clans[v.clan]
	var mt: String = "[color=#9db09e]"
	var by_r: Array[int] = []
	by_r.resize(10)
	by_r.fill(0)
	var mem: int = 0
	var top: Unit = null
	for u: Unit in sim.units:
		if u.k == "p" and u.hp > 0.0 and u.vil == v.id:
			mem += 1
			by_r[u.rank] += 1
			if u.rank > 0 and (top == null or u.rank * 4 + u.stage > top.rank * 4 + top.stage):
				top = u
	var gm: int = mem - by_r[0]
	var nv: int = 0
	for w: Village in sim.villages:
		if w.alive and w.clan == c.id:
			nv += 1
	var s: String = ""
	s += mt + "Bewohner[/color]  %d / %d · %d Gu-Meister\n" % [mem, v.cap, gm]
	s += mt + "Vorräte[/color]  %d Nahrung · %d Holz · %d Ursteine\n" % [int(v.food), int(v.wood), int(v.stones)]
	s += mt + "Gebäude[/color]  " + ("Ahnenhalle" if v.lvl > 0 else "Lagerfeuer") + " · %d Hütten · %d Felder" % [v.houses, v.farms] + (" · Gu-Veredelung" if v.forge else "") + ((" · %d Türme" % v.towers) if v.towers > 0 else "") + "\n"
	s += mt + "Clan[/color]  %d Dörfer · gegründet Jahr %d\n" % [nv, c.born]
	if top != null:
		s += mt + "Stärkster[/color]  " + _swatch(GuData.ESS_COL[top.rank]) + top.pname() + ", " + GuData.rank_title(top.rank) + "\n"
	if not c.war.is_empty():
		var names: PackedStringArray = []
		for e: int in c.war.keys():
			names.append(sim.clans[e].name)
		s += mt + "Fehden[/color]  [color=#ffa894]" + ", ".join(names) + "[/color]\n"
	if not c.ally.is_empty():
		var names2: PackedStringArray = []
		for e: int in c.ally.keys():
			names2.append(sim.clans[e].name)
		s += mt + "Bündnisse[/color]  " + ", ".join(names2) + "\n"
	s += "\n" + mt + "Gu-Meister nach Rang[/color]\n"
	var maxn: int = 1
	for r: int in range(1, 10):
		maxn = maxi(maxn, by_r[r])
	for r: int in range(1, 10):
		if by_r[r] == 0:
			continue
		s += "[color=#%s]R%d %s[/color] %d\n" % [_c(GuData.ESS_COL[r]), r, "█".repeat(maxi(1, roundi(by_r[r] * 12.0 / maxn))), by_r[r]]
	return s


func _open_tile(tx: int, ty: int) -> void:
	if not sim.world.in_map(tx, ty):
		return
	insp_kind = "t"
	var i: int = ty * W + tx
	var f: int = sim.world.feat[i]
	var title: String = GuData.TNAME[sim.world.tile[i]] + ((" · " + GuData.FNAME[f]) if f != 0 else "")
	hud.open_insp(null, "", Color.WHITE, title, GuData.REGN[sim.world.region[i]] + " · Feld %d, %d" % [tx, ty] + (" · brennt" if sim.fire.has(i) else ""), "", [])
	hud.layout_floaters()


func _refresh_insp() -> void:
	if not hud.insp.visible:
		return
	if insp_kind == "u":
		if sel_unit == null or sel_unit.hp <= 0.0:
			_close_insp()
			return
		hud.update_insp_body(_unit_body(sel_unit))
	elif insp_kind == "v":
		if sel_vil == null or not sel_vil.alive:
			_close_insp()
			return
		hud.update_insp_body(_village_body(sel_vil))


# ---------------- Fenster ----------------

func _h(t: String) -> String:
	return "[font_size=20][color=#9fd0ff][b]%s[/b][/color][/font_size]\n\n" % t


func _h3(t: String) -> String:
	return "\n[color=#e8c70a][b]%s[/b][/color]\n" % t.to_upper()


func _open_world_info() -> void:
	var ps: int = 0
	var gm: int = 0
	var imm: int = 0
	var an: int = 0
	var gu: int = 0
	for u: Unit in sim.units:
		if u.k == "p":
			ps += 1
			if u.rank > 0:
				gm += 1
			if u.rank >= 6:
				imm += 1
		elif u.sp == "wildgu":
			gu += 1
		else:
			an += 1
	var trees: int = 0
	for i: int in range(GuData.N):
		if GuData.is_tree(sim.world.feat[i]):
			trees += 1
	var cl: int = 0
	for c: Clan in sim.clans:
		if c.alive:
			cl += 1
	var vl: int = 0
	for v: Village in sim.villages:
		if v.alive:
			vl += 1
	var bl: int = 0
	for b: Building in sim.buildings:
		if b != null:
			bl += 1
	var rows: Array = [["Jahr", sim.year()], ["Zeitalter", sim.age_data()["n"]], ["Seelen", ps], ["Gu-Meister", gm], ["Gu-Unsterbliche", imm], ["Clans und Sekten", cl], ["Dörfer", vl], ["Tiere", an], ["Wilde Gu", gu], ["Bäume", trees], ["Gebäude", bl]]
	var s: String = _h("Weltinfo") + "[table=2]"
	for r: Array in rows:
		s += "[cell][color=#9db09e]%s[/color]   [/cell][cell][b]%s[/b][/cell]" % [r[0], str(r[1])]
	s += "[/table]"
	hud.open_modal(s)


func _open_chron() -> void:
	var s: String = _h("Chronik der Welt")
	if sim.log_entries.is_empty():
		s += "Noch ist nichts geschehen."
	for l: Dictionary in sim.log_entries:
		var k: String = l["k"]
		var col: Color = Color("#eef3ea") if k == "info" else GuData.KCOL.get(k, Color.WHITE)
		s += "[color=#9db09e]Jahr %d[/color]  [color=#%s]%s[/color]\n" % [int(l["y"]), _c(col), Hud._esc(str(l["t"]))]
	hud.open_modal(s)


func _open_rank() -> void:
	var top: Array[Unit] = sim.strongest(15)
	var s: String = _h("Rangliste der Stärksten")
	if top.is_empty():
		s += "Noch hat niemand seine Öffnung erweckt."
	var k: int = 1
	for u: Unit in top:
		var c: Clan = sim.clans[u.clan] if u.clan >= 0 else null
		s += "[color=#9db09e]%d.[/color] %s[url=u%d][b]%s[/b][/url]\n    [color=#9db09e]%s · %s-Pfad · %s[/color]\n" % [k, _swatch(GuData.ESS_COL[u.rank]), u.id, u.pname(), u.title if u.rank == 9 else GuData.rank_title(u.rank) + " · " + GuData.STAGE[u.stage], GuData.PATH_NAME[u.path], "Dämonischer Einzelgänger" if u.rogue else (c.name if c != null else "ohne Clan")]
		k += 1
	hud.open_modal(s)


func _open_clans() -> void:
	var rows: Array = []
	for c: Clan in sim.clans:
		if not c.alive:
			continue
		var vs: int = 0
		var first: int = -1
		for v: Village in sim.villages:
			if v.alive and v.clan == c.id:
				vs += 1
				if first < 0:
					first = v.id
		var pop: int = 0
		var gm: int = 0
		var topr: int = 0
		for u: Unit in sim.units:
			if u.k == "p" and u.clan == c.id:
				pop += 1
				if u.rank > 0:
					gm += 1
				topr = maxi(topr, u.rank)
		rows.append([c, vs, pop, gm, topr, first])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[2] > b[2])
	var s: String = _h("Clans und Sekten")
	if rows.is_empty():
		s += "Noch hat kein Clan ein Dorf gegründet. Setze Menschen auf fruchtbares Land."
	for r: Array in rows:
		var c: Clan = r[0]
		s += "[color=#%s]■[/color] [url=v%d][b]%s[/b][/url]\n    [color=#9db09e]%d Dörfer · %d Seelen · %d Gu-Meister · stärkster Rang %d%s[/color]\n" % [_c(c.col), r[5], c.name, r[1], r[2], r[3], r[4], " · im Krieg" if not c.war.is_empty() else ""]
	hud.open_modal(s)


func _on_meta(m: String) -> void:
	if m.begins_with("u"):
		var id: int = int(m.substr(1))
		for u: Unit in sim.units:
			if u.id == id:
				sel_unit = u
				zoom_to(u.x, u.y, 9.0)
				follow = true
				hud.close_modal()
				_open_unit()
				return
	elif m.begins_with("v"):
		var vi: int = int(m.substr(1))
		if vi >= 0 and vi < sim.villages.size():
			sel_vil = sim.villages[vi]
			sel_unit = null
			zoom_to(sel_vil.cx, sel_vil.cy, 7.0)
			hud.close_modal()
			_open_village()
	elif m.begins_with("law:"):
		var k: String = m.substr(4)
		sim.laws[k] = not sim.laws[k]
		_open_laws()
	elif m == "disp:terr":
		show_terr = not show_terr
		sim.terr_dirty = true
		_open_display()
	elif m == "disp:names":
		show_names = not show_names
		_open_display()


const LAWS: Array = [["war", "Fehden", "Clans erklären sich gegenseitig den Krieg."], ["tide", "Bestienfluten", "Wolfsfluten überfallen Dörfer."], ["immortal", "Unsterblichkeit", "Rang-5-Gu-Meister können zu Gu-Unsterblichen aufsteigen."], ["trib", "Drangsale", "Unsterbliche müssen regelmäßig Himmelsdrangsale überstehen."], ["will", "Himmelswille", "Der Himmel schlägt die Herausragendsten nieder."], ["walls", "Regionswände", "Sterbliche können die Wände nicht durchqueren."], ["growth", "Wachstum", "Geburten, Tiernachwuchs und Pflanzenwachstum."], ["fire", "Feuerausbreitung", "Feuer springt auf Nachbarfelder über."]]


func _switch(on: bool) -> String:
	return "[color=#5fbf8a][b]● AN[/b][/color]" if on else "[color=#c74634][b]○ AUS[/b][/color]"


func _open_laws() -> void:
	var s: String = _h("Weltgesetze") + "Tippe auf ein Gesetz, um es umzuschalten.\n\n"
	for l: Array in LAWS:
		s += "[url=law:%s]%s  [b]%s[/b][/url]\n    [color=#9db09e]%s[/color]\n" % [l[0], _switch(sim.laws[l[0]]), l[1], l[2]]
	hud.open_modal(s)


func _open_display() -> void:
	var s: String = _h("Anzeige")
	s += "[url=disp:terr]%s  [b]Clan-Gebiete[/b][/url]\n    [color=#9db09e]Grenzen der Clans in der Übersicht zeigen.[/color]\n" % _switch(show_terr)
	s += "[url=disp:names]%s  [b]Dorfnamen[/b][/url]\n    [color=#9db09e]Banner mit Clan-Siegel und Einwohnerzahl.[/color]\n" % _switch(show_names)
	hud.open_modal(s)


func _open_ages() -> void:
	var s: String = _h("Die zehn Zeitalter")
	s += "Wie in WorldBox wechselt die Welt alle %d Jahre das Zeitalter. Jedes ändert Fruchtbarkeit, Kriegslust und Kultivierung.\n\n" % GuData.AGE_YEARS
	var cur: int = sim.age_index()
	for i: int in range(GuData.AGES.size()):
		var a: Dictionary = GuData.AGES[i]
		var mark: String = "[color=#e8c70a]▶[/color] " if i == cur else "   "
		s += "%s[b]%s[/b]\n    [color=#9db09e]Wachstum ×%.1f · Kriegslust ×%.1f · Kultivierung ×%.1f[/color]\n" % [mark, a["n"], a["grow"], a["war"], a["cult"]]
	s += "\nJetzt: [b]%s[/b], nächstes Zeitalter in %d Jahren." % [sim.age_data()["n"], sim.years_to_next_age()]
	hud.open_modal(s)


func _open_help() -> void:
	var s: String = _h("Lexikon")
	s += _h3("Steuerung") + "Ein Finger verschiebt die Karte, zwei Finger zoomen. Am PC: ziehen mit der Maus, Mausrad zum Zoomen, Leertaste pausiert, T ändert die Zeit, Esc geht zurück, F5 speichert. Mit einem Pinsel-Werkzeug malst du. Ohne Werkzeug zeigt ein Tippen, wer dort lebt.\n"
	s += _h3("Die fünf Regionen") + "Nordebenen (Steppe und Schnee), Südgrenze (Berge, Bambus, Herbstwälder), Westwüste (Sand und Oasen), Ostmeer (Inseln) und der Zentralkontinent mit seinen Sekten. Regionswände trennen sie; nur Gu-Unsterbliche fliegen hindurch.\n"
	s += _h3("Kultivierung") + "Mit 14 Jahren wird die Öffnung geprüft. Wer erwacht, wird Rang-1-Gu-Meister mit Begabung A bis D. Jeder Rang hat vier Stufen. Gu-Meister verbrauchen Ursteine aus Adern und Geisterquellen und veredeln wilde Gu. Ab Rang 6 droht regelmäßig eine Drangsal; Rang 9 gibt es nur einmal zur selben Zeit.\n\n"
	for r: int in range(1, 10):
		s += _swatch(GuData.ESS_COL[r]) + "Rang %d · %s\n" % [r, GuData.ESS_NAME[r]]
	s += _h3("Schicksalsgabe") + "Das Geschenk oben rechts löst ein zufälliges Ereignis aus: ein Erbe, eine Frühling-Herbst-Zikade, Urstein-Regen, einen Glücksstern oder einen Bestienkönig.\n"
	s += "\nDie Welt speichert sich jede Minute von selbst."
	hud.open_modal(s)


# ---------------- Speichern ----------------

func _save_game() -> bool:
	if loading or fresh:
		return false
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(sim.serialize()))
	f.close()
	return true


func _load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var d: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (d is Dictionary):
		return false
	if not sim.deserialize(d):
		return false
	_close_insp()
	sel_unit = null
	sel_vil = null
	hud.set_loading(false)
	loading = false
	z = min_z
	cam = Vector2(W / 2.0, H / 2.0)
	_clamp_cam()
	return true


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save_game()


# =====================================================================
# Zeichen-Ebenen
# =====================================================================

class EntityLayer:
	extends Node2D
	var m: GuMain
	var sink: Callable

	func _ready() -> void:
		sink = func(r: Rect2, c: Color) -> void: draw_rect(r, c)

	func _draw() -> void:
		var sim: Sim = m.sim
		var z: float = m.z
		var vs: Vector2 = m.get_viewport_rect().size
		var o: Vector2 = m.world_origin()
		var vx0: float = -o.x / z - 16.0
		var vy0: float = -o.y / z - 8.0
		var vx1: float = (vs.x - o.x) / z + 16.0
		var vy1: float = (vs.y - o.y) / z + 20.0
		var tnow: float = Time.get_ticks_msec() / 1000.0
		# Feuer
		for i: int in sim.fire.keys():
			var x: float = i % GuData.W
			var y: float = i / GuData.W
			if x < vx0 or x > vx1 or y < vy0 or y > vy1:
				continue
			var fl: float = sin(tnow * 18.0 + i) * 0.5 + 0.5
			var big: bool = GuData.is_tree(sim.world.feat[i])
			draw_rect(Rect2(x - (2.0 if big else 0.0), y - (5.0 if big else 1.0), 5.0 if big else 1.0, 6.0 if big else 2.0), Color("#e0402a"))
			draw_rect(Rect2(x - (1.0 if big else 0.0), y - (6.0 if big else 1.0) - fl, 3.0 if big else 1.0, 4.0 if big else 1.0), Color("#ff9a2a"))
			draw_rect(Rect2(x, y - (4.0 if big else 0.0) - fl, 1.0, 1.0), Color("#ffe27a"))
			if randf() < 0.015:
				sim.parts.append({"x": x + 0.5, "y": y - (6.0 if big else 1.0), "vx": randf() - 0.5, "vy": -3.0, "l": 1.4, "ml": 1.4, "c": Color(0.27, 0.25, 0.24, 0.55), "s": 1.0, "g": 0.0})
		# Gebäude
		var insp_open: bool = m.hud.insp.visible
		for b: Building in sim.buildings:
			if b == null:
				continue
			if b.x > vx1 or b.y > vy1 or b.x + 16 < vx0 or b.y + 16 < vy0:
				continue
			var v: Village = sim.villages[b.v]
			var c: Clan = sim.clans[v.clan]
			var tx: Dictionary = Sprites.clan_textures(c.col)
			var key: String = b.type
			if b.type == "hall" and v.lvl == 0:
				key = "fire"
			var tex: Texture2D = tx[key]
			var dx: float = b.x - (tex.get_width() - b.w) / 2
			var dy: float = b.y + b.h - tex.get_height() + (1 if b.type == "farm" else 0)
			draw_texture(tex, Vector2(dx, dy))
			if key == "fire":
				var f: int = int(tnow * 8.0) % 3
				draw_rect(Rect2(dx + 3, dy - 2 + (1 if f == 1 else 0), 3, 3), Color("#ff7a2a"))
				draw_rect(Rect2(dx + 4, dy - 3 + (1 if f == 2 else 0), 1, 3), Color("#ffd23a"))
				draw_rect(Rect2(dx + 3 + (2 if f == 0 else 0), dy - 1, 1, 1), Color("#ffb43a"))
			if b.type == "forge" and randf() < 0.04:
				sim.parts.append({"x": dx + 7.0, "y": dy + 2.0, "vx": (randf() - 0.5) * 0.6, "vy": -2.4, "l": 1.4, "ml": 1.4, "c": Color(0.59, 0.94, 0.78, 0.55), "s": 1.0, "g": 0.0})
			if insp_open and m.sel_vil != null and b.v == m.sel_vil.id:
				draw_rect(Rect2(dx - 0.5, dy - 0.5, tex.get_width() + 1, tex.get_height() + 1), Color(1, 0.9, 0.47, 0.9), false, 1.5 / z)
		# Wesen
		for u: Unit in sim.units:
			if u.x < vx0 or u.x > vx1 or u.y < vy0 or u.y > vy1:
				continue
			if u.k == "p":
				var cl: Color = sim.clans[u.clan].col if u.clan >= 0 else (Color("#3a2a3a") if u.rogue else Color("#8e8676"))
				Sprites.draw_person(sink, u.x, u.y, GuMain.PS, u.race, u.rank, cl, u.face, sim.uage(u) >= 14.0, u.moving, u.anim, u.flash > 0.0, u.st == "work", u.rogue, u.sick > 0.0, u.luck > 0.0)
			else:
				Sprites.draw_animal(sink, u.x, u.y, GuMain.PS, u.sp, u.face, u.moving, u.anim, u.flash > 0.0, u.tide, u.id)
		var su: Unit = m.sel_unit
		if su != null and su.hp > 0.0:
			draw_arc(Vector2(su.x, su.y), 2.4, 0.0, TAU, 24, Color("#ffe27a"), maxf(0.15, 1.5 / z))
		# Geschosse
		for p: Dictionary in sim.projs:
			var c2: Color = p["c"]
			var big2: bool = p["big"]
			var pos: Vector2 = Vector2(p["x"], p["y"])
			if int(p["path"]) == 1:
				draw_arc(pos, 2.2 if big2 else 1.3, float(p["a"]) - 1.3, float(p["a"]) + 1.3, 8, c2, 0.8 if big2 else 0.5)
			else:
				var r: float = 1.4 if big2 else 0.7
				draw_rect(Rect2(pos - Vector2(r, r), Vector2(r * 2, r * 2)), Color(c2, 0.5))
				draw_rect(Rect2(pos - Vector2(0.3, 0.3), Vector2(0.6, 0.6)), Color.WHITE)
		# Partikel
		var pi: int = sim.parts.size() - 1
		var rdt: float = get_process_delta_time()
		while pi >= 0:
			var q: Dictionary = sim.parts[pi]
			q["l"] -= rdt
			if q["l"] <= 0.0:
				sim.parts.remove_at(pi)
			else:
				q["x"] += q["vx"] * rdt
				q["y"] += q["vy"] * rdt
				q["vy"] += q["g"] * rdt
				var pc: Color = q["c"]
				pc.a *= clampf(q["l"] / q["ml"], 0.0, 1.0)
				draw_rect(Rect2(q["x"], q["y"], q["s"], q["s"]), pc)
			pi -= 1
		if sim.parts.size() > 1800:
			sim.parts = sim.parts.slice(sim.parts.size() - 1800)
		# Effekte
		var fi: int = sim.fx.size() - 1
		while fi >= 0:
			var e: Dictionary = sim.fx[fi]
			e["l"] -= rdt
			if e["l"] <= 0.0:
				sim.fx.remove_at(fi)
				fi -= 1
				continue
			var t: float = 1.0 - e["l"] / e["ml"]
			match str(e["k"]):
				"ring":
					draw_arc(Vector2(e["x"], e["y"]), maxf(0.1, float(e["r"]) * (0.3 + t * 0.8)), 0.0, TAU, 40, Color(e["c"], 1.0 - t), maxf(0.5, 2.0 / z))
				"bolt":
					var pts: PackedVector2Array = e["pts"]
					draw_polyline(pts, Color(1, 0.97, 0.78, e["l"] / e["ml"]), maxf(0.7, 2.4 / z))
					draw_polyline(pts, Color(0.73, 0.55, 1.0, e["l"] / e["ml"]), maxf(0.3, 1.0 / z))
				"pillar":
					var w: float = 3.0 * float(e["w"])
					draw_rect(Rect2(float(e["x"]) - w / 2.0, float(e["y"]) - 70.0, w, 70.0), Color(e["c"], (1.0 - t) * 0.7))
					draw_rect(Rect2(float(e["x"]) - w / 6.0, float(e["y"]) - 70.0, w / 3.0, 70.0), Color(1, 1, 1, (1.0 - t) * 0.9))
				"cres":
					var a: float = e["a"]
					draw_arc(Vector2(e["x"], e["y"]), float(e["r"]) * (0.6 + t * 0.4), a - 1.1, a + 1.1, 32, Color(0.91, 0.96, 1.0, 1.0 - t), 4.0 * (1.0 - t) + 1.0)
				"met":
					var sx0: float = float(e["x"]) - 60.0
					var sy0: float = float(e["y"]) - 80.0
					var px: float = sx0 + (float(e["x"]) - sx0) * t
					var py: float = sy0 + (float(e["y"]) - sy0) * t
					draw_line(Vector2(px - 12, py - 16), Vector2(px, py), Color("#ff9a3a"), 4.0 if e["big"] else 2.0)
					var rr: float = 3.0 if e["big"] else 1.5
					draw_rect(Rect2(px - rr, py - rr, rr * 2, rr * 2), Color("#ffe4a0"))
			fi -= 1


class CloudLayer:
	extends Node2D
	var m: GuMain
	var list: Array[Dictionary] = []

	func _ready() -> void:
		for k: int in range(7):
			var tex: ImageTexture = _make_cloud()
			list.append({"x": randf() * GuData.W * 1.4 - GuData.W * 0.2, "y": randf() * GuData.H, "tex": tex, "sh": _shadow(tex), "sp": 1.0 + randf() * 1.5})

	func _make_cloud() -> ImageTexture:
		var w: int = randi_range(34, 60)
		var h: int = randi_range(14, 22)
		var im: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
		im.fill(Color(0, 0, 0, 0))
		var blobs: Array[Vector3] = []
		for k: int in range(7):
			blobs.append(Vector3(w * (0.15 + randf() * 0.7), h * (0.35 + randf() * 0.35), h * (0.25 + randf() * 0.25)))
		for y: int in range(h):
			for x: int in range(w):
				var depth: float = -1.0
				for b: Vector3 in blobs:
					var d: float = Vector2((x - b.x) * 0.8, y - b.y).length() / b.z
					if d < 1.0:
						depth = maxf(depth, 1.0 - d)
				if depth < 0.0:
					continue
				var col: Color = Color("#bcd6ec") if y > h * 0.58 else (Color.WHITE if depth > 0.45 else Color("#e4f0fa"))
				im.set_pixel(x, y, col)
		return ImageTexture.create_from_image(im)

	func _shadow(t: ImageTexture) -> ImageTexture:
		var im: Image = t.get_image()
		for y: int in range(im.get_height()):
			for x: int in range(im.get_width()):
				if im.get_pixel(x, y).a > 0.0:
					im.set_pixel(x, y, Color("#06180c"))
		return ImageTexture.create_from_image(im)

	func tick(dt: float) -> void:
		for c: Dictionary in list:
			c["x"] += c["sp"] * dt
			if c["x"] > GuData.W * 1.3:
				c["x"] = -GuData.W * 0.3 - 60.0

	func _draw() -> void:
		var ca: float = clampf((7.0 - m.z) / 5.0, 0.0, 1.0)
		if ca <= 0.0:
			return
		var storm: bool = m.sim.weather.get("type", "") in ["rain", "snow"]
		for c: Dictionary in list:
			draw_texture(c["sh"], Vector2(c["x"] + 10.0, c["y"] + 14.0), Color(1, 1, 1, ca * 0.2))
		for c: Dictionary in list:
			var mod: Color = Color(0.55, 0.57, 0.62, ca * 0.95) if storm else Color(1, 1, 1, ca * 0.85)
			draw_texture(c["tex"], Vector2(c["x"], c["y"]), mod)


class ScreenLayer:
	extends Control
	var m: GuMain
	var wparts: Array[Vector3] = []

	func _ready() -> void:
			mouse_filter = Control.MOUSE_FILTER_IGNORE

	func tick(_dt: float) -> void:
		pass

	func _draw() -> void:
		var sim: Sim = m.sim
		var z: float = m.z
		var o: Vector2 = m.world_origin()
		var vs: Vector2 = size
		# Zeitalter-Tönung
		var tint: Color = sim.age_data()["tint"]
		if tint.a > 0.0:
			draw_rect(Rect2(Vector2.ZERO, vs), tint)
		# Weltrand gestrichelt
		var r: Rect2 = Rect2(o.round() - Vector2(0.5, 0.5), Vector2(GuData.W * z + 1.0, GuData.H * z + 1.0))
		var dc: Color = Color(0.86, 0.93, 1.0, 0.45)
		draw_dashed_line(r.position, Vector2(r.end.x, r.position.y), dc, 1.0, 4.0)
		draw_dashed_line(Vector2(r.end.x, r.position.y), r.end, dc, 1.0, 4.0)
		draw_dashed_line(r.end, Vector2(r.position.x, r.end.y), dc, 1.0, 4.0)
		draw_dashed_line(Vector2(r.position.x, r.end.y), r.position, dc, 1.0, 4.0)
		for e: Dictionary in sim.fx:
			if e["k"] == "flash":
				draw_rect(Rect2(Vector2.ZERO, vs), Color(1, 0.98, 0.9, float(e["l"]) / float(e["ml"]) * 0.35))
		_weather(vs)
		if m.show_names:
			_labels(o, z, vs)
		var font: Font = m.hud.font_bold
		for e: Dictionary in sim.fx:
			if e["k"] == "txt" and z > 2.5:
				var t: float = 1.0 - float(e["l"]) / float(e["ml"])
				var p: Vector2 = Vector2(e["x"], e["y"]) * z + o - Vector2(0, t * 18.0)
				var txt: String = e["t"]
				var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
				draw_string_outline(font, p - Vector2(tw / 2.0, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color(0.06, 0.08, 0.06, 1.0 - t))
				draw_string(font, p - Vector2(tw / 2.0, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(e["c"], 1.0 - t))
		var tl: Dictionary = Powers.tool_by_id(m.tool_id)
		if m.hover.x >= 0.0 and not tl.is_empty() and (tl["m"] == "paint" or tl["m"] == "spawn"):
			var rr: float = 7.0 if tl["m"] == "spawn" else maxf(4.0, (m.powers.brush_r() + 0.5) * z)
			draw_arc(m.hover, rr, 0.0, TAU, 48, Color(1, 1, 1, 0.9), 1.5)
		var ps: Village = m.powers.pair_sel
		if ps != null and ps.alive:
			draw_arc(Vector2(ps.cx, ps.cy) * z + o, maxf(16.0, 14.0 * z), 0.0, TAU, 48, Color("#ff6a4a"), 2.0)

	func _weather(vs: Vector2) -> void:
		var wt: String = m.sim.weather.get("type", "")
		var age_snow: bool = m.sim.age_index() == 7
		if wt == "" and not age_snow:
			wparts.clear()
			return
		if wt == "":
			wt = "snow"
		var rdt: float = get_process_delta_time()
		if wt == "sand":
			draw_rect(Rect2(Vector2.ZERO, vs), Color(0.84, 0.63, 0.31, 0.2))
		elif wt == "drought":
			draw_rect(Rect2(Vector2.ZERO, vs), Color(1, 0.67, 0.24, 0.1))
			return
		elif wt == "rain":
			draw_rect(Rect2(Vector2.ZERO, vs), Color(0.08, 0.12, 0.24, 0.16))
		var want: int = 70 if wt == "sand" else 140
		while wparts.size() < want:
			wparts.append(Vector3(randf() * vs.x, randf() * vs.y, 0.6 + randf() * 0.6))
		for k: int in range(wparts.size()):
			var p: Vector3 = wparts[k]
			if wt == "rain":
				p.y += 900.0 * p.z * rdt
				p.x -= 120.0 * p.z * rdt
				draw_line(Vector2(p.x, p.y), Vector2(p.x + 3.0, p.y - 12.0), Color(0.7, 0.82, 1.0, 0.32), 1.0)
			elif wt == "snow":
				p.y += 60.0 * p.z * rdt
				p.x += sin(p.y * 0.03) * 20.0 * rdt
				draw_rect(Rect2(p.x, p.y, 2.5 * p.z, 2.5 * p.z), Color(1, 1, 1, 0.9))
			else:
				p.x += 700.0 * p.z * rdt
				p.y += 40.0 * rdt
				draw_rect(Rect2(p.x, p.y, 14.0 * p.z, 1.5), Color(0.94, 0.78, 0.51, 0.45))
			if p.y > vs.y:
				p.y = -10.0
			if p.x < -20.0:
				p.x = vs.x
			if p.x > vs.x + 20.0:
				p.x = -20.0
			wparts[k] = p

	func _labels(o: Vector2, z: float, vs: Vector2) -> void:
		var sim: Sim = m.sim
		var font: Font = m.hud.font_bold
		var cjk: Font = m.hud.font_cjk
		var rects: Array[Rect2] = []
		var fs: int = 12
		var h: float = 18.0
		var sink: Callable = func(r: Rect2, c: Color) -> void: draw_rect(r, c)
		for v: Village in sim.villages:
			if not v.alive:
				continue
			var c: Clan = sim.clans[v.clan]
			var X: float = v.cx * z + o.x
			var Y: float = (v.y - (9.0 if v.lvl > 0 else 3.0)) * z + o.y - 6.0
			if X < -120 or X > vs.x + 120 or Y < -30 or Y > vs.y:
				continue
			var txt: String = "%s %d" % [v.name, v.pop]
			var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var bw: float = h + 2.0
			var pw: float = 12.0
			var w: float = bw + pw + tw + 14.0
			var rx: float = roundf(X - w / 2.0)
			var ry: float = roundf(Y - h)
			var rr: Rect2 = Rect2(rx, ry, w, h)
			var clash: bool = false
			for q: Rect2 in rects:
				if q.intersects(rr):
					clash = true
					break
			if clash:
				continue
			rects.append(rr)
			var body: StyleBoxFlat = Hud.sb(Color(0.08, 0.09, 0.094, 0.9), Color("#0a0c0c"), 1, 4)
			draw_style_box(body, Rect2(rx + bw - 3.0, ry + 1.0, w - bw + 3.0, h - 2.0))
			draw_rect(Rect2(rx + w - 3.0, ry + 2.0, 2.0, h - 4.0), Color("#d8a83a"))
			draw_style_box(Hud.sb(Color("#0a1426"), Color.TRANSPARENT, 0, 3), Rect2(rx, ry - 1.0, bw, h + 2.0))
			draw_style_box(Hud.sb(c.col, Color.TRANSPARENT, 0, 2), Rect2(rx + 1.5, ry + 0.5, bw - 3.0, h - 1.0))
			draw_rect(Rect2(rx + 3.5, ry + 2.5, bw - 7.0, h - 5.0), Color(1, 1, 1, 0.45), false, 1.0)
			var gw: float = cjk.get_string_size(c.glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			draw_string(cjk, Vector2(rx + bw / 2.0 - gw / 2.0, ry + h / 2.0 + 5.0), c.glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
			var L: Unit = v.lead
			if L != null and L.hp > 0.0:
				var sc: float = 1.65 / (2.1 if L.rank >= 9 else (1.45 if L.rank >= 6 else 1.0))
				Sprites.draw_person(sink, rx + bw + 7.0, ry + h - 3.0, sc, L.race, L.rank, c.col, 1, true, false, 0.0, false, false, false, false, false)
			draw_string(font, Vector2(rx + bw + pw + 4.0, ry + h / 2.0 + 4.5), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#ffa894") if not c.war.is_empty() else Color("#8ec8ff"))
		for u: Unit in sim.units:
			if u.k != "p" or u.hp <= 0.0:
				continue
			if not (u.rank >= 6 or u == m.sel_unit or (u.rank >= 4 and z >= 8.0)):
				continue
			if u.rank < 9 and z < 3.0 and u != m.sel_unit:
				continue
			var X2: float = u.x * z + o.x
			var Y2: float = (u.y - (9.0 if u.rank >= 9 else (6.5 if u.rank >= 6 else 4.5))) * z + o.y - 6.0
			if X2 < 0 or X2 > vs.x or Y2 < 0 or Y2 > vs.y:
				continue
			var t2: String = "%s · R%d" % [u.given, u.rank]
			var tw2: float = font.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			draw_style_box(Hud.sb(Color(0.08, 0.09, 0.094, 0.85), Color.TRANSPARENT, 0, 3), Rect2(X2 - tw2 / 2.0 - 5.0, Y2 - 8.0, tw2 + 10.0, 15.0))
			draw_string(font, Vector2(X2 - tw2 / 2.0, Y2 + 4.0), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, GuData.ESS_COL[u.rank])


# ---------------- Entwickler: Screenshots für Vergleiche ----------------
# Start: godot --path . -- --shots=<ordner>   (läuft nur, wenn dieses Argument gesetzt ist)

func _dev_shots(dir: String) -> void:
	while loading:
		await get_tree().process_frame
	for k: int in range(40):
		await get_tree().process_frame
	_apply_tab(1)
	_set_weather("rain")
	await _wait(0.5)
	await _shot(dir + "/A.png")
	_set_weather("")
	var best: Village = null
	for v: Village in sim.villages:
		if v.alive and (v.reg == 1 or v.reg == 4) and (best == null or v.pop > best.pop):
			best = v
	if best != null:
		z = 3.6
		cam = Vector2(best.cx, best.cy + 4.0)
		_clamp_cam()
	await _wait(1.0)
	await _shot(dir + "/B.png")
	var coast: Vector2 = Vector2(-1, -1)
	for k: int in range(30000):
		var x: int = 20 + randi() % 200
		var y: int = 40 + randi() % 170
		var i: int = y * W + x
		var t: PackedByteArray = sim.world.tile
		if t[i] == GuData.SAND and t[i + W] == GuData.SHAL and t[i - 6 * W] == GuData.GRASS and t[i + 12 * W] <= 1 and t[i + 30 * W] >= 2 and t[i + 30 * W] != GuData.WALL:
			coast = Vector2(x, y)
			break
	if coast.x >= 0.0:
		z = 3.6
		cam = coast + Vector2(0, 10)
		_clamp_cam()
	_apply_tab(2)
	await _wait(1.0)
	await _shot(dir + "/C.png")
	_apply_tab(-1)
	await _wait(0.4)
	await _shot(dir + "/D.png")
	_apply_tab(4)
	await _wait(0.4)
	await _shot(dir + "/E.png")
	if best != null:
		sel_vil = best
		_open_village()
	await _wait(0.3)
	await _shot(dir + "/F.png")
	_close_insp()
	_open_rank()
	await _wait(0.3)
	await _shot(dir + "/G.png")
	get_tree().quit()


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)


func _selftest() -> void:
	while loading:
		await get_tree().process_frame
	var t0: int = Time.get_ticks_msec()
	var c: Vector2 = Vector2(W / 2.0, H / 2.0)
	for v: Village in sim.villages:
		if v.alive:
			c = Vector2(v.cx, v.cy)
			break
	for t: Dictionary in Powers.TOOLS:
		var id: String = t["id"]
		if id in ["new", "hideui", "load"]:
			continue
		match str(t["m"]):
			"paint":
				powers.begin_stroke()
				var st: Dictionary = {}
				for k: int in range(4):
					powers.apply_paint(t, c.x + k * 3.0, c.y + 20.0, st)
			"spawn":
				powers.spawn_at(t, c.x + 6.0, c.y + 8.0)
			"tap", "pair":
				if id == "inspect":
					_inspect_at(c.x, c.y)
				else:
					powers.tap_tool(t, c.x, c.y)
					powers.tap_tool(t, c.x + 40.0, c.y)
			"act":
				_run_action(t)
				hud.close_modal()
		for k: int in range(40):
			sim.step(Sim.DT)
		print("ok ", id, " units=", sim.units.size())
	_set_weather("")
	_inspect_at(c.x, c.y)
	_refresh_insp()
	_open_rank()
	_open_clans()
	_open_chron()
	_open_world_info()
	_open_ages()
	_open_laws()
	_on_meta("law:war")
	_open_display()
	_gift()
	var t1: int = Time.get_ticks_msec()
	for k: int in range(400):
		sim.step(Sim.DT)
	print("400 steps ms ", Time.get_ticks_msec() - t1, " units ", sim.units.size())
	fresh = false
	print("save ", _save_game())
	print("load ", _load_game())
	fresh = true
	for k: int in range(100):
		sim.step(Sim.DT)
	print("SELFTEST DONE ms ", Time.get_ticks_msec() - t0)
	get_tree().quit()
