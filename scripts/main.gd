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
var sel_place: Place = null
var lm_font: FontVariation
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
var presim_on: bool = false  ## Vorgeschichte läuft im Hintergrund, die Karte ist schon sichtbar
var t_boot: int = 0
var fresh: bool = false  ## Entwickler: --fresh lädt und speichert nichts

# Eingabe
var touches: Dictionary = {}
var gesture: Dictionary = {}
var stroke: Dictionary = {}
var last_spawn: int = 0
var zoom_goal: float = -1.0  ## weiches Zoomen: Ziel (< 0 = aus)
var zoom_pt: Vector2 = Vector2.ZERO
var fling: Vector2 = Vector2.ZERO  ## Schwung nach dem Wischen (Bildschirm-Pixel/s)
var pan_vel: Vector2 = Vector2.ZERO
var pan_us: int = 0
var last_tap_ms: int = -10000
var last_tap_pos: Vector2 = Vector2(-999, -999)
const PRESIM_FRAME_MS: float = 34.0  ## Vorgeschichte im Hintergrund: Bildzeit-Ziel (~30 fps)
var presim_budget: float = 12.0
var presim_ms0: int = 0


func _ready() -> void:
	t_boot = Time.get_ticks_msec()
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
		if a.begins_with("--sheets="):
			_dev_sheets(a.substr(9))


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
	# Desktop-Fenster im Querformat: etwas größere Oberfläche (Basis 760 statt 880 Pixel hoch)
	var win: Window = get_window()
	if win != null and win.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS:
		var want: Vector2i = Vector2i(400, 760) if win.size.x > win.size.y * 1.1 else Vector2i(400, 880)
		if win.content_scale_size != want:
			win.content_scale_size = want
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


## Kamera begrenzen: ist die Karte kleiner als der Bildausschnitt, bleibt sie ganz sichtbar;
## sonst darf man höchstens um einen halben Bildschirm über den Rand hinaus schieben.
func _clamp_cam() -> void:
	z = clampf(z, min_z, MAX_Z)
	var vs: Vector2 = get_viewport_rect().size
	var hw: float = vs.x / 2.0 / z
	var hh: float = view_h() / 2.0 / z
	if W <= hw * 2.0:
		cam.x = clampf(cam.x, W - hw, hw)
	else:
		cam.x = clampf(cam.x, hw * 0.5, W - hw * 0.5)
	if H <= hh * 2.0:
		cam.y = clampf(cam.y, H - hh, hh)
	else:
		cam.y = clampf(cam.y, hh * 0.5, H - hh * 0.5)


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
	zoom_goal = -1.0
	fling = Vector2.ZERO
	z = maxf(z, nz)
	cam = Vector2(x, y)
	_clamp_cam()


## Weiches Zoomen (Mausrad, Tasten, Doppeltippen): Ziel setzen, _process nähert sich an.
func zoom_smooth(p: Vector2, factor: float) -> void:
	var base: float = zoom_goal if zoom_goal > 0.0 else z
	zoom_goal = clampf(base * factor, min_z, MAX_Z)
	zoom_pt = p
	fling = Vector2.ZERO
	follow = false


func view_center() -> Vector2:
	return Vector2(get_viewport_rect().size.x / 2.0, view_h() / 2.0)


# ---------------- Ablauf ----------------

func _start_new_world(live: bool, mode: String = "gu") -> void:
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
	sim.new_world(live, mode)
	sim.world.render_all()
	# Karte sofort zeigen; die Vorgeschichte läuft danach in Häppchen im Hintergrund.
	presim_on = live
	presim_ms0 = Time.get_ticks_msec()
	presim_budget = 12.0
	_finish_start()
	print("WORLD VISIBLE ms ", Time.get_ticks_msec() - t_boot)


func _finish_start() -> void:
	loading = false
	hud.set_loading(false)
	z = min_z
	zoom_goal = -1.0
	fling = Vector2.ZERO
	cam = Vector2(W / 2.0, H / 2.0)
	_clamp_cam()
	sim.update_leaders()
	sim.terr_dirty = true
	sim.world.render_all()


## Vorgeschichte sofort beenden (der Spieler greift ein oder sie ist fertig).
func _end_presim() -> void:
	if not presim_on:
		return
	presim_on = false
	if sim.presim:
		sim.presim = false
		sim.log_event("Die Welt erwacht. Jahr %d." % sim.year(), "jade")
	sim.update_leaders()
	sim.terr_dirty = true


func _process(delta: float) -> void:
	var rdt: float = minf(delta, 0.1)
	if loading:
		return
	if presim_on:
		# Budget anpassen: was vom letzten Bild nicht Vorgeschichte war, ist Zeichnen/Eingabe
		var overhead: float = delta * 1000.0 - presim_budget
		# Untergrenze wächst mit der Zeit, damit die Vorgeschichte auch auf langsamen Geräten zügig endet
		var lo: float = clampf(6.0 + (Time.get_ticks_msec() - presim_ms0) / 1000.0 * 2.5 - 7.5, 6.0, 45.0)
		presim_budget = clampf(lerpf(presim_budget, PRESIM_FRAME_MS - overhead, 0.3), lo, maxf(28.0, lo))
		var pp: float = sim.presim_chunk(int(presim_budget), PRESIM_YEARS)
		if pp >= 1.0:
			print("PRESIM DONE ms ", Time.get_ticks_msec() - t_boot)
			_end_presim()
	elif not paused:
		sim_acc += rdt * SPEEDS[speed_idx]
		var n: int = 0
		while sim_acc >= Sim.DT and n < 14:
			sim.step(Sim.DT)
			sim_acc -= Sim.DT
			n += 1
		if n >= 14:
			sim_acc = 0.0
	# weiches Zoomen und Schwung
	if zoom_goal > 0.0:
		var nz: float = lerpf(z, zoom_goal, 1.0 - exp(-rdt * 13.0))
		if absf(nz - zoom_goal) < zoom_goal * 0.003:
			nz = zoom_goal
			zoom_goal = -1.0
		zoom_at(zoom_pt, nz)
	if fling != Vector2.ZERO:
		cam -= fling * rdt / z
		fling *= exp(-rdt * 4.2)
		var c0: Vector2 = cam
		_clamp_cam()
		if fling.length() < 12.0 or c0 != cam:
			fling = Vector2.ZERO
	if follow and sel_unit != null and sel_unit.hp > 0.0:
		cam += (Vector2(sel_unit.x, sel_unit.y) - cam) * minf(1.0, rdt * 6.0)
		_clamp_cam()
	if sim.world.water_dirty:
		sim.world.refresh_water()
	sim.world.flush_dirty(4)
	terr_t -= rdt
	var tz: float = terr_zoom()
	if sim.terr_dirty and show_terr and terr_t <= 0.0 and z < tz:
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
	terr_spr.visible = show_terr and z < tz
	terr_spr.modulate.a = clampf((tz - z) / 0.8, 0.0, 0.75)
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
	if presim_on:
		hud.age_lbl.text = "Vorgeschichte … %d %%" % int(clampf(sim.sim_time / (PRESIM_YEARS * 12.0), 0.0, 0.99) * 100.0)
	else:
		var ad: Dictionary = sim.age_data()
		hud.age_lbl.text = "%s · Jahr %d · nächstes in %d Jahren" % [ad["n"], sim.year(), sim.years_to_next_age()]
	hud.tick_layout()
	auto_t += rdt
	if auto_t > 60.0 and not presim_on:
		auto_t = 0.0
		_save_game()


## Bis zu dieser Zoomstufe sind Clan-Gebiete sichtbar (auf großen Bildschirmen entsprechend höher).
func terr_zoom() -> float:
	return 2.6 * maxf(1.0, min_z / 1.44)


# ---------------- Eingabe ----------------

func _unhandled_input(e: InputEvent) -> void:
	if loading:
		return
	if e.is_action_pressed("toggle_pause"):
		_toggle_pause()
		return
	if e.is_action_pressed("zoom_in"):
		zoom_smooth(view_center(), 1.35)
		return
	if e.is_action_pressed("zoom_out"):
		zoom_smooth(view_center(), 1.0 / 1.35)
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
	if e is InputEventMagnifyGesture:
		var mg: InputEventMagnifyGesture = e
		zoom_goal = -1.0
		zoom_at(mg.position, z * mg.factor)
		follow = false
		return
	if e is InputEventPanGesture:
		var pg: InputEventPanGesture = e
		cam += pg.delta * 6.0 / z
		_clamp_cam()
		follow = false
		return
	if e is InputEventScreenTouch:
		var st: InputEventScreenTouch = e
		if st.pressed:
			touches[st.index] = st.position
			fling = Vector2.ZERO
			if touches.size() == 2:
				zoom_goal = -1.0
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
			zoom_smooth(mb.position, 1.0 + 0.2 * (mb.factor if mb.factor > 0.0 else 1.0))
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom_smooth(mb.position, 1.0 / (1.0 + 0.2 * (mb.factor if mb.factor > 0.0 else 1.0)))
			return
		if mb.pressed:
			fling = Vector2.ZERO
			pan_vel = Vector2.ZERO
			pan_us = Time.get_ticks_usec()
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
			if gesture.get("type", "") == "pan":
				if gesture["tap"] and float(gesture["moved"]) < 8.0:
					_tap_or_double(mb.position)
				elif float(gesture["moved"]) > 6.0 and Time.get_ticks_usec() - pan_us < 90000 and touches.size() < 2:
					# Schwung: nach einem schnellen Wischen gleitet die Karte weiter
					fling = pan_vel.limit_length(2600.0) if pan_vel.length() > 120.0 else Vector2.ZERO
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
				zoom_goal = -1.0
			var now_us: int = Time.get_ticks_usec()
			var dt_s: float = maxf(0.004, (now_us - pan_us) / 1000000.0)
			pan_vel = pan_vel.lerp(d2 / dt_s, 0.45) if now_us - pan_us < 100000 else d2 / dt_s
			pan_us = now_us
			gesture["last"] = mm.position


## Einfaches Tippen löst das Werkzeug aus; zweimal schnell hintereinander (ohne Werkzeug) zoomt hinein.
func _tap_or_double(p: Vector2) -> void:
	var now: int = Time.get_ticks_msec()
	var t: Dictionary = Powers.tool_by_id(tool_id)
	var zoomable: bool = t.is_empty() or t["id"] == "inspect"
	if zoomable and now - last_tap_ms < 340 and p.distance_to(last_tap_pos) < 28.0:
		last_tap_ms = -10000
		if insp_kind == "t":
			_close_insp()
		zoom_smooth(p, 2.2)
		return
	last_tap_ms = now
	last_tap_pos = p
	_tap_at(p)


func _paint_at(p: Vector2) -> void:
	var t: Dictionary = Powers.tool_by_id(tool_id)
	if t.is_empty():
		return
	_end_presim()
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
		_end_presim()
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
	else:
		hud.hide_hint()


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
			hud.open_modal("[font_size=20][color=#9fd0ff][b]Neue Welt erschaffen[/b][/color][/font_size]\n\n[b]Gu-Weltkarte (Standard)[/b]: die fünf Regionen der Gu-Welt mit Himmelshof, Gu-Yue-Dorf, Shang-Clan-Stadt und den anderen bekannten Orten. Mit Clans entstehen die kanonischen Mächte, dann vergehen %d Jahre Vorgeschichte.\n\n[b]Zufallswelt[/b]: frei erzeugte Regionen ohne benannte Orte.\n\n[color=#9db09e]Die aktuelle Welt geht verloren, wenn du sie nicht gespeichert hast.[/color]" % int(PRESIM_YEARS), [
				["Gu-Weltkarte mit Clans", func() -> void:
					hud.close_modal()
					_start_new_world(true, "gu"), "red"],
				["Gu-Weltkarte, nur Natur", func() -> void:
					hud.close_modal()
					_start_new_world(false, "gu"), ""],
				["Zufallswelt mit Clans", func() -> void:
					hud.close_modal()
					_start_new_world(true, "random"), "jade"],
				["Zufallswelt, nur Natur", func() -> void:
					hud.close_modal()
					_start_new_world(false, "random"), ""]])
		"hideui":
			_set_ui_hidden(true)
		"ev_war", "ev_dream", "ev_inherit":
			var r: Dictionary = powers.event_act(t["id"])
			if str(r["msg"]) != "":
				hud.show_hint(t["n"], r["msg"])
			var pos: Vector2 = r["pos"]
			if pos.x >= 0.0:
				zoom_to(pos.x, pos.y, 5.0)


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
	var pl: Place = sim.place_at(wx, wy)
	if pl != null:
		sel_unit = null
		sel_vil = null
		sel_place = pl
		_open_place()
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
		Sprites.draw_person(sink, 8.0, 14.5, 0.72 if u.rank >= 9 else (1.05 if u.rank >= 6 else 1.5), u.race, u.rank, unit_col(u), 1, sim.uage(u) >= 14.0, false, 0.0, false, false, u.rogue, u.sick > 0.0, false, 0.0, 0.0, u.ow)
	else:
		var ss: float = float(GuData.SPEC[u.sp].get("ss", 1.0))
		Sprites.draw_animal(sink, 8.0, 13.0, minf(1.5, 1.5 / ss * (1.0 if ss <= 1.0 else 0.75)), u.sp, 1, false, 1.0, false, u.tide, u.id, 0.0, u.path)
	return q.outline().tex()


## Gewandfarbe einer Figur: Ehrwürdige in ihrer Farbe, sonst Clanfarbe.
func unit_col(u: Unit) -> Color:
	if u.rank >= 9 and u.fig != "":
		for vd: Dictionary in Lore.VEN:
			if vd["fig"] == u.fig:
				return Color(str(vd["col"]))
	if u.ow:
		return Color("#6a2a8a")
	return sim.clans[u.clan].col if u.clan >= 0 else (Color("#3a2a3a") if u.rogue else Color("#8e8676"))


func _open_unit() -> void:
	insp_kind = "u"
	var u: Unit = sel_unit
	var sub: String
	if u.k == "p":
		var c: Clan = sim.clans[u.clan] if u.clan >= 0 else null
		var v: Village = sim.villages[u.vil] if u.vil >= 0 else null
		sub = (u.title if (u.rank == 9 or u.ow) and u.title != "" else GuData.rank_title(u.rank)) + ((" · " + GuData.STAGE[u.stage]) if (u.rank > 0 and u.rank < 9) else "")
		sub += "\n" + ("Dämonischer Einzelgänger" if u.rogue else ((c.name + ((" · " + v.name) if v != null else "")) if c != null else "ohne Clan"))
	else:
		var tn: String = GuData.TIER_NAME.get(u.rank, "Wildtier")
		if u.beh == GuData.B_GU:
			sub = "Wilder Gu des %s-Pfades – Gu-Meister fangen ihn" % GuData.PATH_NAME[maxi(0, u.path)]
		elif u.beh == GuData.B_IGU:
			sub = "Wildes Unsterbliches Gu (Rang %d) – nur Unsterbliche fangen es" % int(Lore.igu(u.gname).get("r", 6))
		elif u.tide:
			sub = "Teil einer Wolfsflut"
		elif u.ldr != null and u.ldr.hp > 0.0:
			sub = tn + " · Rudel von " + u.ldr.pname()
		else:
			sub = tn
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
		s += mt + "Volk[/color]  " + GuData.RACE_NAME[u.race] + ("  [color=#c080ff](Fremdweltdämon)[/color]" if u.ow else "") + "\n"
		s += mt + "Alter[/color]  %d / %d Jahre\n" % [int(a), int(u.life)]
		if u.rank > 0:
			s += mt + "Pfad[/color]  " + _swatch(GuData.PATH_COL[u.path]) + GuData.PATH_NAME[u.path] + "-Pfad\n"
			s += mt + "Gesinnung[/color]  " + ("[color=#ff8a7a]dämonisch[/color]" if (u.align == 1 or u.rogue) else "[color=#9fe0b0]rechtschaffen[/color]") + "\n"
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
		if not u.igu.is_empty():
			var ig: PackedStringArray = PackedStringArray()
			for id: String in u.igu:
				var e: Dictionary = Lore.igu(id)
				ig.append(str(e.get("n", id)) + " [color=#9db09e](" + str(Lore.FX_TEXT.get(str(e.get("fx", "gen")), "")) + ")[/color]")
			s += "\n\n[color=#ffd24a]Unsterbliche Gu:[/color] " + ", ".join(ig)
		if u.notrib:
			s += "\n[color=#cfe0ff]An ein Himmelsfragment gebunden – keine Drangsale[/color]"
		if not u.gus.is_empty():
			s += "\n\n[color=#e8c70a]Gu:[/color] " + ", ".join(u.gus)
		if u.fig != "" and u.rank < 9:
			for fd: Dictionary in Lore.FIG:
				if fd["id"] == u.fig:
					s += "\n[color=#9db09e]" + str(fd["d"]) + "[/color]"
		elif u.rank >= 9 and u.fig != "":
			for vd: Dictionary in Lore.VEN:
				if vd["fig"] == u.fig:
					s += "\n[color=#9db09e]" + str(vd["d"]) + "[/color]"
		if u.luck > 0.0:
			s += "\n[color=#ffd23a]Großes Glück[/color]"
		if u.sick > 0.0:
			s += "\n[color=#86e04a]Seuchen-Gu[/color]"
	else:
		var S: Dictionary = GuData.SPEC[u.sp]
		if u.beh == GuData.B_GU or u.beh == GuData.B_IGU:
			s += mt + "Pfad[/color]  " + _swatch(GuData.PATH_COL[maxi(0, u.path)]) + GuData.PATH_NAME[maxi(0, u.path)] + "-Pfad\n"
			if u.beh == GuData.B_IGU:
				var e2: Dictionary = Lore.igu(u.gname)
				s += mt + "Wirkung[/color]  " + str(Lore.FX_TEXT.get(str(e2.get("fx", "gen")), "")) + "\n"
				s += "[color=#9db09e]" + str(e2.get("d", "")) + "[/color]\n"
			s += mt + "Leben[/color]  " + _bar_txt(u.hp / u.mhp, Color("#d24a35"))
			return s
		if u.rank > 0:
			s += mt + "Stufe[/color]  " + _swatch(GuData.ESS_COL[u.rank]) + str(GuData.TIER_NAME.get(u.rank, "")) + " (wie Rang %d)\n" % u.rank
		s += mt + "Leben[/color]  " + _bar_txt(u.hp / u.mhp, Color("#d24a35")) + "\n"
		s += mt + "Stärke[/color]  %d\n" % int(u.atk)
		s += mt + "Beute[/color]  %d" % u.kills
		if S.has("d"):
			s += "\n[color=#9db09e]" + str(S["d"]) + "[/color]"
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


func _open_place() -> void:
	insp_kind = "pl"
	var p: Place = sel_place
	var D: Dictionary = Lore.PLACE[p.type]
	var btns: Array = []
	btns.append(["Auflösen", func() -> void:
		p.alive = false
		sim.places.erase(p)
		sim.spark(p.x, p.y - 4.0, Color("#fff1c0"), 20, 8.0)
		_close_insp(), "red"])
	hud.open_insp(Icons.get_icon("pl_" + p.type), "", Color.WHITE, p.name, str(D["n"]) + " · " + GuData.REGN[sim.region_at(p.x, p.y)], _place_body(p), btns)
	hud.layout_floaters()


func _place_body(p: Place) -> String:
	var mt: String = "[color=#9db09e]"
	var s: String = ""
	if p.owner >= 0:
		var o: Unit = sim.unit_by_id(p.owner)
		if o != null:
			s += mt + "Besitzer[/color]  " + _swatch(GuData.ESS_COL[o.rank]) + o.pname() + ", " + GuData.rank_title(o.rank) + "\n"
	elif p.type in ["blessed", "grotto", "hu"]:
		s += mt + "Besitzer[/color]  herrenlos\n"
	s += mt + "Alter[/color]  %d Jahre\n" % int((sim.sim_time - p.born) / 12.0)
	if p.until > 0.0:
		s += mt + "Verblasst[/color]  in %d Monaten\n" % int(p.until - sim.sim_time)
	s += mt + "Wirkung[/color]  %d Felder\n" % int(p.radius())
	if p.type == "yitian":
		s += mt + "Fötus-Gu[/color]  " + ("bereits erschienen" if p.used else "erscheint in %d Monaten" % maxi(0, int(24.0 - p.t))) + "\n"
	var n: int = 0
	for u: Unit in sim.near_units(p.x, p.y, p.radius()):
		if u.k == "p" and u.rank > 0:
			n += 1
	s += mt + "Gu-Meister[/color]  %d in der Nähe\n" % n
	s += "\n[color=#9db09e]" + str(Lore.PLACE[p.type]["d"]) + "[/color]"
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
	elif insp_kind == "pl":
		if sel_place == null or not sel_place.alive:
			_close_insp()
			return
		hud.update_insp_body(_place_body(sel_place))


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
		elif u.beh == GuData.B_GU or u.beh == GuData.B_IGU:
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
	var rows: Array = [["Jahr", sim.year()], ["Zeitalter", sim.age_data()["n"]], ["Seelen", ps], ["Gu-Meister", gm], ["Gu-Unsterbliche", imm], ["Clans und Sekten", cl], ["Dörfer", vl], ["Tiere", an], ["Wilde Gu", gu], ["Besondere Orte", sim.places.size()], ["Bäume", trees], ["Gebäude", bl]]
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
	s += _h3("Völker") + "Neben den Menschen leben Variant-Menschen: Haar-, Stein-, Fischschuppen-, Feder-, Schnee-, Drachen-, Tier-, Pilz-, Schlamm- und Holzmenschen – jedes Volk mit eigener Heimat, Gestalt und Gabe. Nur Menschen können Ehrwürdige werden.\n"
	s += _h3("Pfade und Mordzüge") + "Es gibt %d Pfade. Gu-Meister sammeln die sterblichen Gu ihres Pfades, indem sie wilde Gu fangen. Ab Rang 6 setzen Unsterbliche Mordzüge ihres Pfades ein, etwa den Mondsichel-Mordzug oder den Feuermeer-Mordzug. Rechtschaffene und Dämonische bekriegen sich; Dämonische werden oft zu mordenden Einzelgängern.\n" % GuData.PATH_NAME.size()
	s += _h3("Unsterbliche Gu") + "Wilde Unsterbliche Gu leuchten golden. Nur Gu-Unsterbliche können sie fangen. Die Frühling-Herbst-Zikade lässt ihren Träger nach dem Tod jung wiedergeboren werden; andere schenken Glück, Zeit, Kraft, Tempo, Heilung oder Weisheit. Ödbestien tragen manchmal eines in sich.\n"
	s += _h3("Bestien") + "Hundert-, Tausend- und Zehntausend-Bestienkönige führen Rudel. Ödbestien (Rang 6 bis 8) verteidigen ihr Revier und überfallen nahe Dörfer.\n"
	s += _h3("Orte") + "Gesegnete Länder und Grottenhimmel stärken Unsterbliche und gebären Unsterbliche Gu. Traumreiche locken Gu-Meister an, Erbe schenken Macht oder Tod, der Himmelshof straft Dämonische. Tippe einen Ort an, um mehr zu erfahren.\n"
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
		# Dorfwege (unter den Gebäuden)
		var insp_open: bool = m.hud.insp.visible
		var road: Color = Color("#a8875a")
		var road_e: Color = Color(0.32, 0.24, 0.12, 0.35)
		for v: Village in sim.villages:
			if not v.alive or v.b.size() < 2:
				continue
			if v.cx < vx0 - 30 or v.cx > vx1 + 30 or v.cy < vy0 - 30 or v.cy > vy1 + 30:
				continue
			var hall: Building = null
			for id: int in v.b:
				var hb: Building = sim.buildings[id]
				if hb != null and hb.type == "hall":
					hall = hb
					break
			if hall == null:
				continue
			var a: Vector2 = Sprites.door(hall)
			var ra: float = 0.8 if v.lvl > 0 else 0.5
			for pass_i: int in range(2):
				for id: int in v.b:
					var ob: Building = sim.buildings[id]
					if ob == null or ob == hall:
						continue
					var d2: Vector2 = Sprites.door(ob)
					var x0: float = minf(a.x, d2.x)
					var x1: float = maxf(a.x, d2.x)
					var y0: float = minf(a.y, d2.y)
					var y1: float = maxf(a.y, d2.y)
					if pass_i == 0:
						draw_rect(Rect2(x0 - 0.25, a.y - 0.25, x1 - x0 + 1.5, 1.5), road_e)
						draw_rect(Rect2(d2.x - 0.25, y0 - 0.25, 1.5, y1 - y0 + 1.5), road_e)
					else:
						draw_rect(Rect2(x0, a.y, x1 - x0 + 1.0, 1.0), Color(road, ra))
						draw_rect(Rect2(d2.x, y0, 1.0, y1 - y0 + 1.0), Color(road, ra))
		# Gebäude (von hinten nach vorne)
		var vis: Array[Building] = []
		for b: Building in sim.buildings:
			if b == null:
				continue
			if b.x > vx1 or b.y > vy1 or b.x + 16 < vx0 or b.y + 16 < vy0:
				continue
			vis.append(b)
		vis.sort_custom(func(p: Building, q: Building) -> bool: return p.y + p.h < q.y + q.h)
		for b: Building in vis:
			var v: Village = sim.villages[b.v]
			var c: Clan = sim.clans[v.clan]
			var tx: Dictionary = Sprites.clan_textures(c.col, v.race)
			var key: String = Sprites.building_key(b, v)
			var tex: Texture2D = tx[key]
			var tw: int = tex.get_width() - 1
			var th: int = tex.get_height() - 1
			var dx: float = b.x - floori((tw - b.w) / 2.0)
			var dy: float = b.y + b.h - th
			draw_texture(tex, Vector2(dx, dy))
			if key == "fire":
				var f: int = int(tnow * 8.0) % 3
				var fx: float = dx + 1.0
				var fy: float = dy + 1.0
				draw_rect(Rect2(fx + 4, fy + 1, 3, 3), Color("#e0402a"))
				draw_rect(Rect2(fx + 4 + (1 if f == 1 else 0), fy - 1 + (1 if f == 2 else 0), 2, 3), Color("#ff9a2a"))
				draw_rect(Rect2(fx + 5, fy + 1 - (1 if f == 0 else 0), 1, 2), Color("#ffe27a"))
				draw_rect(Rect2(fx + 4 + (2 if f == 0 else 0), fy - 2 + (1 if f == 1 else 0), 1, 1), Color("#ffb43a"))
				if randf() < 0.03:
					sim.parts.append({"x": fx + 5.5, "y": fy - 1.0, "vx": (randf() - 0.5) * 0.6, "vy": -2.0, "l": 1.6, "ml": 1.6, "c": Color(0.55, 0.53, 0.5, 0.5), "s": 1.0, "g": 0.0})
			elif key == "pen" and z > 1.6:
				Sprites.draw_pen_animals(sink, b.x, b.y, tnow, b.id)
			if b.type == "forge" and randf() < 0.04:
				sim.parts.append({"x": dx + 7.0, "y": dy + 0.0, "vx": (randf() - 0.5) * 0.6, "vy": -2.4, "l": 1.4, "ml": 1.4, "c": Color(0.59, 0.94, 0.78, 0.55), "s": 1.0, "g": 0.0})
			if insp_open and m.sel_vil != null and b.v == m.sel_vil.id:
				draw_rect(Rect2(dx - 0.5, dy - 0.5, tw + 1, th + 1), Color(1, 0.9, 0.47, 0.9), false, 1.5 / z)
		# Orte (Gesegnete Länder, Himmelshof, Traumreiche …)
		for p: Place in sim.places:
			if not p.alive:
				continue
			var ps: float = Sprites.place_size(p.type)
			if p.x < vx0 - ps or p.x > vx1 + ps or p.y < vy0 - ps or p.y > vy1 + ps:
				continue
			_draw_place(p, tnow, insp_open and m.sel_place == p)
		# Wesen (Kontur etwa 1 Bildschirmpixel breit, im Fernblick keine)
		var ol: float = 0.0 if z * GuMain.PS < 0.5 else clampf(0.9 / (z * GuMain.PS), 0.4, 0.9)
		Sprites.outline_col = Color(Sprites.OUTLINE, clampf((z * GuMain.PS - 0.6) / 1.0, 0.0, 0.92))
		for u: Unit in sim.units:
			if u.x < vx0 or u.x > vx1 or u.y < vy0 or u.y > vy1:
				continue
			if u.k == "p":
				var cl: Color = sim.clans[u.clan].col if u.clan >= 0 else (Color("#3a2a3a") if u.rogue else Color("#8e8676"))
				if u.fig != "" or u.ow:
					cl = m.unit_col(u)
				Sprites.draw_person(sink, u.x, u.y, GuMain.PS, u.race, u.rank, cl, u.face, sim.uage(u) >= 14.0, u.moving, u.anim, u.flash > 0.0, u.st == "work", u.rogue, u.sick > 0.0, u.luck > 0.0, ol, tnow, u.ow)
			else:
				Sprites.draw_animal(sink, u.x, u.y, GuMain.PS, u.sp, u.face, u.moving or u.fly, u.anim, u.flash > 0.0, u.tide, u.id, ol, u.path)
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
				"km":
					_draw_km(e, t)
			fi -= 1

	## Mordzug: Strahlenkranz und Wellen in der Pfadfarbe, je nach Pfad mit eigener Form.
	func _draw_km(e: Dictionary, t: float) -> void:
		var c: Color = e["c"]
		var p: int = e["p"]
		var cen: Vector2 = Vector2(e["x"], e["y"])
		var r: float = float(e["r"]) * (0.35 + t * 0.75)
		var a0: float = t * 2.4
		var al: float = 1.0 - t
		var lw: float = maxf(0.4, 2.2 / m.z)
		draw_circle(cen, r * 0.55, Color(c, 0.22 * al))
		draw_arc(cen, r, 0.0, TAU, 40, Color(c, al), lw * 1.6)
		draw_arc(cen, r * 0.7, 0.0, TAU, 32, Color(1, 1, 1, al * 0.8), lw)
		var n: int = 12 if p in [5, 17, 20, 11] else 8
		for k: int in range(n):
			var a: float = a0 + k * TAU / n
			var d0: float = r * 0.3
			var d1: float = r * (1.05 if k % 2 == 0 else 0.8)
			if p == 36 or p == 37 or p == 4:
				# Klingen: schräge Striche
				draw_line(cen + Vector2(cos(a), sin(a)) * d0, cen + Vector2(cos(a + 0.5), sin(a + 0.5)) * d1, Color(c.lightened(0.3), al), lw)
			elif p == 2 or p == 8:
				# Flammen/Blut: dicke Zungen
				draw_line(cen + Vector2(cos(a), sin(a)) * d0, cen + Vector2(cos(a), sin(a)) * d1 - Vector2(0, r * 0.2 * (1.0 - t)), Color(c, al), lw * 2.2)
			else:
				draw_line(cen + Vector2(cos(a), sin(a)) * d0, cen + Vector2(cos(a), sin(a)) * d1, Color(c, al), lw)

	## Ort zeichnen: Schatten, Bild (schwebend mit Auf und Ab), belebte Effekte.
	func _draw_place(p: Place, tnow: float, sel: bool) -> void:
		var tex: Texture2D = Sprites.place_tex(p.type)
		var tw: float = tex.get_width()
		var th: float = tex.get_height()
		var fl: bool = p.type in Sprites.PLACE_FLOAT
		var bob: float = sin(tnow * 1.3 + p.id) * 0.8 if fl else 0.0
		var pos: Vector2 = Vector2(roundf(p.x - tw / 2.0), roundf(p.y - th + 2.0 - (8.0 if fl else 0.0) + bob))
		if fl:
			for k: int in range(3):
				var sw: float = tw * (0.7 - k * 0.15)
				draw_rect(Rect2(p.x - sw / 2.0, p.y - 1.0 + k * 0.3, sw, 2.0 - k * 0.5), Color(0.03, 0.12, 0.03, 0.18))
		match p.type:
			"dream":
				var a: float = tnow * 0.8
				for k: int in range(3):
					draw_arc(Vector2(p.x, p.y - th * 0.45), th * (0.25 + k * 0.12), a + k * 2.1, a + k * 2.1 + 2.4, 20, Color("#e8c0ff", 0.55 - k * 0.12), 1.2)
			"court":
				var pa: float = 0.25 + 0.15 * sin(tnow * 2.0)
				draw_rect(Rect2(p.x - 1.0, pos.y - 26.0, 2.0, 26.0), Color(1.0, 0.95, 0.7, pa))
		draw_texture(tex, pos)
		if p.type == "dream":
			var a2: float = -tnow * 1.3
			draw_arc(Vector2(p.x, pos.y + th * 0.55), th * 0.3, a2, a2 + 2.0, 16, Color(1, 1, 1, 0.6), 0.8)
		if (p.type == "blessed" or p.type == "grotto" or p.type == "hu") and randf() < 0.05:
			m.sim.parts.append({"x": p.x + (randf() - 0.5) * tw * 0.7, "y": pos.y + th * 0.4, "vx": 0.0, "vy": -2.0, "l": 1.2, "ml": 1.2, "c": Color("#fff6b0"), "s": 0.6, "g": 0.0})
		if p.type == "fragment" and int(tnow * 3.0 + p.id) % 5 == 0:
			draw_rect(Rect2(p.x - 0.5, pos.y + 2.0, 1.0, 1.0), Color.WHITE)
		if p.type == "yitian" and not p.used:
			draw_rect(Rect2(p.x - 0.5, pos.y - 20.0, 1.0, 20.0), Color(1.0, 0.9, 0.5, 0.25 + 0.15 * sin(tnow * 3.0)))
		if sel:
			draw_rect(Rect2(pos.x - 0.5, pos.y - 0.5, tw + 1.0, th + 1.0), Color(1, 0.9, 0.47, 0.9), false, 1.5 / m.z)


class CloudLayer:
	extends Node2D
	var m: GuMain
	var list: Array[Dictionary] = []

	func _ready() -> void:
		for k: int in range(7):
			var ims: Array[Image] = _make_cloud()
			list.append({"x": randf() * GuData.W * 1.4 - GuData.W * 0.2, "y": randf() * GuData.H, "tex": ImageTexture.create_from_image(ims[0]), "dark": ImageTexture.create_from_image(ims[1]), "sh": _shadow(ims[0]), "sp": 1.0 + randf() * 1.5})

	## Pixelwolke aus überlappenden Ballen: oben weiß, Mitte hellblau, Unterseite blaugrau (WorldBox).
	func _make_cloud() -> Array[Image]:
		var w: int = randi_range(70, 124)
		var h: int = randi_range(22, 32)
		var lite: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
		lite.fill(Color(0, 0, 0, 0))
		var dark: Image = lite.duplicate()
		var blobs: Array[Vector3] = []
		var n: int = 6 + w / 16
		for k: int in range(n):
			var f: float = float(k) / float(n - 1)
			var bx: float = w * (0.1 + 0.8 * f) + randf_range(-4.0, 4.0)
			var r: float = h * randf_range(0.26, 0.44) * (1.0 - absf(f - 0.45) * 0.9)
			blobs.append(Vector3(bx, h - r - 1.5 - randf() * 4.0, maxf(3.0, r)))
		for y: int in range(h):
			for x: int in range(w):
				var margin: float = -99.0
				var top: float = 1.0
				for bl: Vector3 in blobs:
					var d: float = Vector2((x - bl.x) * 0.6, y - bl.y).length()
					if d <= bl.z:
						margin = maxf(margin, bl.z - d)
						top = minf(top, (y - (bl.y - bl.z)) / (bl.z * 2.0))
				if margin < 0.0:
					continue
				if margin < 1.2 and (x + y) % 2 == 0:
					continue
				var c: Color
				var cd: Color
				if top > 0.78:
					c = Color("#9fd6d6")
					cd = Color("#3c434c")
				elif top < 0.25:
					c = Color("#f6fffd")
					cd = Color("#7a838d")
				elif top < 0.55:
					c = Color("#dcf6f2")
					cd = Color("#646d77")
				else:
					c = Color("#bfeae6")
					cd = Color("#525a64")
				lite.set_pixel(x, y, c)
				dark.set_pixel(x, y, cd)
		return [lite, dark]

	func _shadow(im0: Image) -> ImageTexture:
		var im: Image = im0.duplicate()
		for y: int in range(im.get_height()):
			for x: int in range(im.get_width()):
				if im.get_pixel(x, y).a > 0.0:
					im.set_pixel(x, y, Color("#08161c"))
		return ImageTexture.create_from_image(im)

	var glints: Array[Vector3] = []

	func tick(dt: float) -> void:
		for c: Dictionary in list:
			c["x"] += c["sp"] * dt
			if c["x"] > GuData.W * 1.3:
				c["x"] = -GuData.W * 0.3 - 90.0
		# Wasserglitzern: kurze helle Striche auf dem Meer
		var k: int = glints.size() - 1
		while k >= 0:
			var g: Vector3 = glints[k]
			g.z -= dt
			if g.z <= 0.0:
				glints.remove_at(k)
			else:
				glints[k] = g
			k -= 1
		var tries: int = 0
		while glints.size() < 90 and tries < 40:
			tries += 1
			var x: int = randi() % GuData.W
			var y: int = randi() % GuData.H
			if GuData.is_water(m.sim.world.tile[y * GuData.W + x]):
				glints.append(Vector3(x, y, randf_range(0.8, 2.2)))

	func _draw() -> void:
		var z: float = m.z
		# Glitzern (in allen Zoomstufen, im Nahblick feiner)
		var gw: float = clampf(2.0 / z, 0.35, 1.6)
		for g: Vector3 in glints:
			var a: float = sin(clampf(g.z / 2.2, 0.0, 1.0) * PI)
			draw_rect(Rect2(g.x, g.y, gw * 2.0, maxf(0.3, gw * 0.6)), Color(0.86, 0.95, 1.0, 0.35 * a))
		var ca: float = clampf((3.4 - z) / 1.4, 0.0, 1.0)
		if ca <= 0.0:
			return
		var storm: bool = m.sim.weather.get("type", "") in ["rain", "snow"]
		for c: Dictionary in list:
			draw_texture(c["sh"], Vector2(c["x"] + 6.0, c["y"] + 18.0), Color(1, 1, 1, ca * 0.36))
		var i: int = 0
		for c: Dictionary in list:
			var dk: bool = storm and i % 2 == 0
			draw_texture(c["dark"] if dk else c["tex"], Vector2(c["x"], c["y"]), Color(1, 1, 1, ca * (0.9 if dk else 0.78)))
			i += 1


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
			_landmarks(o, z, vs)
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
		var fs: int = 11
		var h: float = 15.0
		var sink: Callable = func(r: Rect2, c: Color) -> void: draw_rect(r, c)
		Sprites.outline_col = Sprites.OUTLINE
		for v: Village in sim.villages:
			if not v.alive:
				continue
			var c: Clan = sim.clans[v.clan]
			var X: float = v.cx * z + o.x
			# Oberkante des Dorfzentrums (Lagerfeuer 7, Halle 10/13 Pixel hoch)
			var th: float = 7.0 if v.lvl == 0 else (13.0 if Sprites.village_tier(v) == 2 else 10.0)
			var Y: float = (v.y + 2.0 - th) * z + o.y - 2.0
			if X < -140 or X > vs.x + 140 or Y < -30 or Y > vs.y + 20:
				continue
			var txt: String = "%s %d" % [v.name, v.pop]
			var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var bw: float = 13.0
			var cw: float = 4.0
			var pw: float = 13.0
			var w: float = bw + cw + pw + tw + 10.0
			var rx: float = roundf(X - w / 2.0)
			var ry: float = roundf(Y - h)
			var placed: bool = false
			for dy: float in [0.0, -(h + 5.0), h + 5.0]:
				var rr: Rect2 = Rect2(rx - 1.0, ry + dy - 3.0, w + 2.0, h + 6.0)
				var clash: bool = false
				for q: Rect2 in rects:
					if q.intersects(rr):
						clash = true
						break
				if not clash:
					rects.append(rr)
					ry += dy
					placed = true
					break
			if not placed:
				continue
			_kingdom_label(rx, ry, w, h, bw, cw, pw, c, v, txt, font, cjk, fs, sink)
		for u: Unit in sim.units:
			if u.k != "p" or u.hp <= 0.0:
				continue
			var named: bool = u.fig != "" or u.ow
			if not (u.rank >= 6 or named or u == m.sel_unit or (u.rank >= 4 and z >= 8.0)):
				continue
			if u.rank < 9 and z < 3.0 and u != m.sel_unit and not named:
				continue
			var X2: float = u.x * z + o.x
			var Y2: float = (u.y - (9.0 if u.rank >= 9 else (6.5 if u.rank >= 6 else 4.5))) * z + o.y - 6.0
			if X2 < 0 or X2 > vs.x or Y2 < 0 or Y2 > vs.y:
				continue
			var t2: String = "%s · R%d" % [u.given if u.sur == "" or u.fig == "" else u.sur + " " + u.given, u.rank]
			if u.ow:
				t2 = "Fremdweltdämon · R%d" % u.rank
			var tw2: float = font.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			var r2: Rect2 = Rect2(roundf(X2 - tw2 / 2.0 - 5.0), roundf(Y2 - 7.0), roundf(tw2 + 10.0), 13.0)
			var clash2: bool = false
			for q: Rect2 in rects:
				if q.intersects(r2):
					clash2 = true
					break
			if clash2:
				continue
			rects.append(r2)
			_plate(r2)
			draw_rect(Rect2(r2.position.x + 2.0, r2.position.y + 2.0, 2.0, r2.size.y - 4.0), GuData.ESS_COL[u.rank])
			draw_string(font, Vector2(r2.position.x + 6.0, r2.position.y + 10.0), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, GuData.ESS_COL[u.rank].lightened(0.15))

	## Namen der Orte der Gu-Weltkarte und gesetzter Orte im Fernblick: klein, schräg, weiß mit dunkler Kontur.
	func _landmarks(o: Vector2, z: float, vs: Vector2) -> void:
		if z > 3.4:
			return
		var a: float = clampf((3.4 - z) / 0.8, 0.0, 1.0)
		if m.lm_font == null:
			m.lm_font = FontVariation.new()
			m.lm_font.base_font = ThemeDB.fallback_font
			m.lm_font.variation_embolden = 0.35
			m.lm_font.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.22, 1), Vector2.ZERO)
		var fnt: Font = m.lm_font
		var fs: int = 9 if z < 2.0 else 10
		var lms: Array = []
		for l0: Dictionary in m.sim.world.landmarks:
			var dup: bool = false
			for p0: Place in m.sim.places:
				if p0.alive and absf(p0.x - float(l0["x"])) < 14.0 and absf(p0.y - float(l0["y"])) < 14.0:
					dup = true
					break
			if not dup:
				lms.append(l0)
		for p: Place in m.sim.places:
			if p.alive:
				lms.append({"name": p.name, "x": p.x, "y": p.y + 3.0, "kind": "ort"})
		for l: Dictionary in lms:
			var nm: String = l["name"]
			var tw: float = fnt.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var pos: Vector2 = Vector2(float(l["x"]) * z + o.x - tw / 2.0, float(l["y"]) * z + o.y + (fs + 4.0 if l["kind"] == "siedlung" else 3.0))
			if pos.x < -tw or pos.x > vs.x or pos.y < 0 or pos.y > vs.y:
				continue
			var col: Color = Color(1, 1, 1, a * 0.92)
			if l["kind"] == "fluss":
				col = Color(0.8, 0.92, 1.0, a * 0.92)
			draw_string_outline(fnt, pos, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0.05, 0.07, 0.1, a * 0.85))
			draw_string(fnt, pos, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

	## Dunkle Namensplatte mit abgeschrägten Ecken und heller Kante (WorldBox).
	func _plate(r: Rect2) -> void:
		var x: float = r.position.x
		var y: float = r.position.y
		var w: float = r.size.x
		var hh: float = r.size.y
		var edge: Color = Color("#55574b")
		draw_rect(Rect2(x + 1.0, y, w - 2.0, hh), Color(0.04, 0.045, 0.035, 0.75))
		draw_rect(Rect2(x, y + 1.0, w, hh - 2.0), Color(0.04, 0.045, 0.035, 0.75))
		draw_rect(Rect2(x + 1.0, y + 1.0, w - 2.0, hh - 2.0), Color("#1d1f1a"))
		draw_rect(Rect2(x + 2.0, y + 1.0, w - 4.0, 1.0), edge)
		draw_rect(Rect2(x + 2.0, y + hh - 2.0, w - 4.0, 1.0), edge)
		draw_rect(Rect2(x + 1.0, y + 2.0, 1.0, hh - 4.0), edge)
		draw_rect(Rect2(x + w - 2.0, y + 2.0, 1.0, hh - 4.0), edge)
		draw_rect(Rect2(x + 2.0, y + 2.0, w - 4.0, 1.0), Color(1, 1, 1, 0.04))

	func _kingdom_label(rx: float, ry: float, w: float, h: float, bw: float, cw: float, pw: float, c: Clan, v: Village, txt: String, font: Font, cjk: Font, fs: int, sink: Callable) -> void:
		var px: float = rx + bw + cw
		_plate(Rect2(px, ry, w - bw - cw, h))
		# Goldene Zierleiste rechts
		var gx: float = rx + w - 3.0
		draw_rect(Rect2(gx, ry - 1.0, 3.0, h + 2.0), Color("#3a2a10"))
		for k: int in range(int(h + 2.0)):
			draw_rect(Rect2(gx + 1.0, ry - 1.0 + k, 1.0, 1.0), Color("#f0c048") if k % 3 != 1 else Color("#9a6a1c"))
		draw_rect(Rect2(gx, ry - 2.0, 3.0, 1.0), Color("#f0c048"))
		draw_rect(Rect2(gx, ry + h + 1.0, 3.0, 1.0), Color("#f0c048"))
		# Verbindung ≡ zwischen Banner und Platte
		for k: int in range(3):
			draw_rect(Rect2(rx + bw, ry + h / 2.0 - 3.0 + k * 3.0, cw + 1.0, 1.0), Color("#c8ccc4"))
		# Banner in Clanfarbe mit Siegel
		var bc: Color = c.col
		var by: float = ry - 2.0
		var bh: float = h + 4.0
		draw_rect(Rect2(rx, by, bw, bh), bc.darkened(0.62))
		draw_rect(Rect2(rx + 1.0, by + 1.0, bw - 2.0, bh - 2.0), bc.darkened(0.08))
		draw_rect(Rect2(rx + 2.0, by + 2.0, bw - 4.0, bh - 4.0), bc.lightened(0.38), false, 1.0)
		draw_rect(Rect2(rx + 3.0, by + 3.0, bw - 6.0, bh - 6.0), bc.darkened(0.2))
		for q: Vector2 in [Vector2(rx - 1.0, by - 1.0), Vector2(rx + bw - 1.0, by - 1.0), Vector2(rx - 1.0, by + bh - 1.0), Vector2(rx + bw - 1.0, by + bh - 1.0)]:
			draw_rect(Rect2(q, Vector2(2, 2)), bc.darkened(0.62))
		var gw: float = cjk.get_string_size(c.glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		draw_string(cjk, Vector2(roundf(rx + bw / 2.0 - gw / 2.0), by + bh / 2.0 + 3.5), c.glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, bc.lightened(0.7))
		# Anführer
		var L: Unit = v.lead
		if L != null and L.hp > 0.0:
			var sc: float = 1.45 / (2.1 if L.rank >= 9 else (1.45 if L.rank >= 6 else 1.0))
			Sprites.draw_person(sink, px + 7.0, ry + h - 1.0, sc, L.race, L.rank, c.col, 1, true, false, 0.0, false, false, false, false, false, 0.7)
		var tc: Color = Color("#ef7a62") if not c.war.is_empty() else Color("#62a6e6")
		draw_string(font, Vector2(px + pw + 1.0, ry + h / 2.0 + 5.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.55))
		draw_string(font, Vector2(px + pw, ry + h / 2.0 + 4.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tc)


# ---------------- Entwickler: Screenshots für Vergleiche ----------------
# Start: godot --path . -- --shots=<ordner>   (läuft nur, wenn dieses Argument gesetzt ist)

func _dev_shots(dir: String) -> void:
	while loading:
		await get_tree().process_frame
	# P: Karte sichtbar, Vorgeschichte läuft noch im Hintergrund
	await _wait(1.0)
	await _shot(dir + "/P.png")
	while presim_on:
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
	hud.close_modal()
	# Q: Reiter 6 mit Wetter-Kasten und Hinweis; R: Malwerkzeug mit Pinsel-Kasten und Beschreibung, drei Meldungen
	_apply_tab(6)
	_set_weather("rain")
	await _wait(0.3)
	await _shot(dir + "/Q.png")
	_apply_tab(0)
	_click_tool(Powers.tool_by_id("t_deep"))
	for k: int in range(5):
		hud.toast("Testmeldung %d: Ein Gu-Meister durchbricht zum nächsten Rang." % k, "jade", sim.year())
	await _wait(0.3)
	await _shot(dir + "/R.png")
	_set_weather("")
	tool_id = ""
	hud.refresh_tools("", "")
	# Leisten der Reiter (jeweils Anfang und weiter rechts)
	for tb: int in [0, 1, 2, 5, 6]:
		_apply_tab(tb)
		await _wait(0.2)
		await _shot(dir + "/bar%d_a.png" % tb)
		hud.tools_scroll.scroll_horizontal = 340
		await _wait(0.2)
		await _shot(dir + "/bar%d_b.png" % tb)
		hud.tools_scroll.scroll_horizontal = 700
		await _wait(0.2)
		await _shot(dir + "/bar%d_c.png" % tb)
	_apply_tab(-1)
	# Nahaufnahme: Ehrwürdige, Figuren, Bestien, Orte
	var c: Vector2 = Vector2(best.cx, best.cy) if best != null else Vector2(W / 2.0, H / 2.0)
	var spot: Vector2 = c + Vector2(30, 10)
	for k: int in range(60):
		var t2: Vector2 = c + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		if sim.world.in_map(int(t2.x), int(t2.y)) and GuData.buildable(sim.world.tile[int(t2.y) * W + int(t2.x)]) and sim.nearest_village(t2.x, t2.y, 18.0) == null:
			spot = t2
			break
	sim.add_place("blessed", spot.x - 14.0, spot.y - 6.0, true)
	sim.add_place("dream", spot.x + 16.0, spot.y - 4.0, true)
	sim.spawn_venerable(Lore.VEN[4], spot.x - 6.0, spot.y + 6.0)
	sim.spawn_venerable(Lore.VEN[7], spot.x + 2.0, spot.y + 6.0)
	sim.spawn_figure(Lore.FIG[0], spot.x - 2.0, spot.y + 2.0)
	sim.spawn_beast(spot.x + 10.0, spot.y + 8.0, "flying_bear")
	sim.spawn_beast(spot.x - 12.0, spot.y + 10.0, "qi_grand_lion")
	sim.spawn_beast(spot.x + 2.0, spot.y + 14.0, "bk100")
	sim.spawn_wild_igu(spot.x - 4.0, spot.y - 2.0, "spring_autumn_cicada")
	for k2: int in range(4):
		sim.spawn_wild_gu(spot.x + 6.0 + k2, spot.y + 2.0, [2, 8, 11, 6][k2])
	for r: int in range(4, 11):
		sim.mk_person(spot.x - 10.0 + (r - 4) * 3.0, spot.y + 18.0, r, 25.0)
	paused = true
	z = 7.0
	cam = spot + Vector2(0, 4)
	_clamp_cam()
	await _wait(3.2)
	await _shot(dir + "/H.png")
	z = 11.0
	cam = spot + Vector2(-2, 12)
	_clamp_cam()
	await _wait(0.4)
	await _shot(dir + "/I.png")
	var ven: Unit = sim.fig_alive("red_lotus")
	if ven != null:
		sel_unit = ven
		_open_unit()
		await _wait(0.3)
		await _shot(dir + "/J.png")
		_close_insp()
	var pl: Place = sim.find_place("blessed")
	if pl != null:
		sel_place = pl
		_open_place()
		await _wait(0.3)
		await _shot(dir + "/K.png")
		_close_insp()
	paused = false
	for k3: int in range(80):
		sim.step(Sim.DT)
	z = 6.0
	await _wait(0.5)
	await _shot(dir + "/L.png")
	# Übersicht mit Ortsnamen
	z = min_z
	cam = Vector2(W / 2.0, H / 2.0)
	_clamp_cam()
	await _wait(0.5)
	await _shot(dir + "/M.png")
	z = 2.2
	cam = Vector2(110, 190)
	_clamp_cam()
	await _wait(0.5)
	await _shot(dir + "/N.png")
	_run_action(Powers.tool_by_id("new"))
	await _wait(0.3)
	await _shot(dir + "/O.png")
	get_tree().quit()


## Entwickler: Icon- und Sprite-Bögen als PNG (läuft auch headless): <ordner>/icons.png, sprites.png
func _dev_sheets(dir: String) -> void:
	var sc: int = 3
	var cols: int = 16
	var ids: Array[String] = []
	var last_tab: int = -99
	for t: Dictionary in Powers.TOOLS:
		if int(t["tab"]) != last_tab and not ids.is_empty():
			while ids.size() % cols != 0:
				ids.append("")
		last_tab = int(t["tab"])
		ids.append(t["id"])
	var rows: int = ceili(ids.size() / float(cols))
	var sheet: Image = Image.create_empty(cols * 26 * sc, rows * 26 * sc, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#2a3427"))
	for k: int in range(ids.size()):
		if ids[k] == "":
			continue
		var im: Image = Icons._make(ids[k]).img
		im.resize(im.get_width() * sc, im.get_height() * sc, Image.INTERPOLATE_NEAREST)
		var cx: int = (k % cols) * 26 * sc + sc
		var cy: int = (k / cols) * 26 * sc + sc
		sheet.fill_rect(Rect2i(cx, cy, 24 * sc, 24 * sc), Color("#1f2923"))
		sheet.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(cx + (24 * sc - im.get_width()) / 2, cy + (24 * sc - im.get_height()) / 2))
	sheet.save_png(dir + "/icons.png")
	var order: PackedStringArray = PackedStringArray()
	for k2: int in range(ids.size()):
		order.append("%d:%s" % [k2, ids[k2]])
	print("ICONS ", " ".join(order))
	# Wesen: Völker (Rang 0, 3, 6, 9), Bestien, Gu, Orte
	var cell: int = 64
	var items: Array = []
	for r: int in range(GuData.RACE_NAME.size()):
		for rk: int in [0, 3, 6, 9]:
			items.append(["p", r, rk])
	for s: String in GuData.SPEC.keys():
		items.append(["a", s])
	for pt: String in Lore.PLACE_ORDER:
		items.append(["pl", pt])
	items.append(["pl", "fragment"])
	var cols2: int = 12
	var sp: Image = Image.create_empty(cols2 * cell, ceili(items.size() / float(cols2)) * cell, false, Image.FORMAT_RGBA8)
	sp.fill(Color("#5a9a48"))
	for k3: int in range(items.size()):
		var it: Array = items[k3]
		var q: Px = Px.new(cell, cell)
		var sk: Callable = func(rr: Rect2, c: Color) -> void: q.p(roundi(rr.position.x), roundi(rr.position.y), maxi(1, roundi(rr.size.x)), maxi(1, roundi(rr.size.y)), c)
		match str(it[0]):
			"p":
				Sprites.draw_person(sk, 32.0, 58.0, 2.4 if int(it[2]) < 9 else 1.6, int(it[1]), int(it[2]), GuData.CLANCOL[int(it[1]) % 16], 1, true, false, 0.0, false, false, false, false, false, 0.5, 0.0, false)
			"a":
				var ss: float = float(GuData.SPEC[it[1]].get("ss", 1.0))
				Sprites.draw_animal(sk, 30.0, 56.0, 2.6 / maxf(1.0, ss * 0.8), it[1], 1, false, 1.0, false, false, 3, 0.5, 1)
			"pl":
				var pim: Image = Sprites.place_image(it[1])
				var f: int = maxi(1, int(60.0 / maxf(pim.get_width(), pim.get_height())))
				pim.resize(pim.get_width() * f, pim.get_height() * f, Image.INTERPOLATE_NEAREST)
				q.draw_image(pim, (cell - pim.get_width()) / 2, cell - pim.get_height() - 2)
		sp.blend_rect(q.img, Rect2i(0, 0, cell, cell), Vector2i((k3 % cols2) * cell, (k3 / cols2) * cell))
	sp.save_png(dir + "/sprites.png")
	print("SHEETS DONE")
	get_tree().quit()


## Kamera-Prüfung: Übersicht passt, weiches Zoomen per Mausrad, Schwung nach dem Wischen, Doppeltippen.
func _selftest_camera() -> void:
	_close_insp()
	hud.close_modal()
	tool_id = ""
	z = min_z
	cam = Vector2(W / 2.0, H / 2.0)
	_clamp_cam()
	var o: Vector2 = world_origin()
	var vs: Vector2 = get_viewport_rect().size
	var fits: bool = o.x >= -0.5 and o.y >= -0.5 and o.x + W * z <= vs.x + 0.5 and o.y + H * z <= view_h() + 0.5
	print("cam overview fits ", fits, " z ", snappedf(z, 0.01))
	var wheel: InputEventMouseButton = InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.position = view_center()
	_unhandled_input(wheel)
	var z0: float = z
	for k: int in range(3):
		await get_tree().process_frame
	var mid: float = z
	for k: int in range(90):
		await get_tree().process_frame
	print("cam smooth zoom ", mid > z0 and mid < z0 * 1.2, " -> ", snappedf(z / z0, 0.01))
	# Wischen: Druck, schnelle Bewegung, Loslassen -> Karte gleitet weiter
	z = min_z * 3.0
	cam = Vector2(W / 2.0, H / 2.0)
	_clamp_cam()
	var p: Vector2 = view_center()
	var down: InputEventMouseButton = InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = p
	_unhandled_input(down)
	for k: int in range(6):
		await get_tree().process_frame
		var mv: InputEventMouseMotion = InputEventMouseMotion.new()
		p += Vector2(-18, 0)
		mv.position = p
		_unhandled_input(mv)
	var up: InputEventMouseButton = InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.position = p
	_unhandled_input(up)
	var c1: Vector2 = cam
	for k: int in range(30):
		await get_tree().process_frame
	print("cam fling ", cam.x > c1.x + 1.0, " glide ", snappedf(cam.x - c1.x, 0.1))
	# Doppeltippen zoomt hinein
	var zt: float = z
	for k: int in range(2):
		var d2: InputEventMouseButton = down.duplicate()
		d2.position = view_center()
		_unhandled_input(d2)
		var u2: InputEventMouseButton = up.duplicate()
		u2.position = view_center()
		_unhandled_input(u2)
	for k: int in range(90):
		await get_tree().process_frame
	print("cam double tap ", z > zt * 1.5, " insp ", hud.insp.visible)


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)


func _selftest() -> void:
	while loading or presim_on:
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
	# Gu-Welt: Inspektoren aller Wesenarten und Orte, Mordzüge, Wiedergeburt
	var seen: Dictionary = {}
	for u: Unit in sim.units:
		var key: String = u.sp if u.k == "a" else "p%d_%d" % [u.race, u.rank]
		if seen.has(key):
			continue
		seen[key] = true
		_unit_body(u)
		_portrait(u)
	for p: Place in sim.places:
		_place_body(p)
		sel_place = p
		_open_place()
		_close_insp()
	var imm: Unit = sim.spawn_immortal(c.x, c.y - 30.0, 7)
	for pth: int in [1, 2, 6, 7, 14, 36, 47]:
		imm.path = pth
		sim.killer_move(imm, c.x + 4.0, c.y - 30.0)
	var fy: Unit = sim.fig_alive("fang_yuan")
	if fy == null and sim.spawn_figure(Lore.FIG[0], c.x, c.y + 12.0) == "":
		fy = sim.fig_alive("fang_yuan")
	if fy != null and (fy.igf & Sim.F_REVIVE) == 0:
		sim.give_igu(fy, "spring_autumn_cicada")
	if fy != null and (fy.igf & Sim.F_REVIVE) != 0:
		sim.hurt(fy, 1e9, null)
		sim.step(Sim.DT)
		print("revive ", fy.hp > 0.0, " age ", int(sim.uage(fy)))
	print("places ", sim.places.size(), " wild_igu ", sim.wild_igu)
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
	var np: int = sim.places.size()
	var nig: int = 0
	for u2: Unit in sim.units:
		nig += u2.igu.size()
	print("save ", _save_game())
	print("load ", _load_game())
	var nig2: int = 0
	for u3: Unit in sim.units:
		nig2 += u3.igu.size()
	print("places after load ", sim.places.size(), " / ", np, " · immortal gu owned ", nig2, " / ", nig, " · map ", sim.world.map_mode, " landmarks ", sim.world.landmarks.size())
	fresh = true
	for k: int in range(100):
		sim.step(Sim.DT)
	await _selftest_camera()
	print("SELFTEST DONE ms ", Time.get_ticks_msec() - t0)
	get_tree().quit()
