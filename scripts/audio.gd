class_name Audio
extends Node
## Prozeduraler Klang: alle Geräusche und die Musik entstehen beim Start aus Code (PCM in AudioStreamWAV),
## verteilt über viele Bilder (Web ist Single-Threaded). Ereignisse kommen aus `Sim.sfx` (Warteschlange,
## je Bild geleert), aus den Signalen `Sim.logged`/`unit_died` und aus der Oberfläche (`Hud`-Signale,
## `tool()` aus `GuMain._paint_at/_tap_at`). Lautstärke nach Abstand zur Bildmitte und Zoom.

const SR: int = 22050          ## Abtastrate der Effekte
const SR_LO: int = 11025       ## tiefe/lange Klänge (Donner, Gong, Glocke)
const SR_MID: int = 16000      ## Musik-Phrasen, Glöckchen
const SR_VLO: int = 8000       ## Wind, Meer, Bordun-Luft
const POOL: int = 14           ## gleichzeitige Effekte
const CFG: String = "user://settings.cfg"
const BUDGET_US: int = 3000    ## Synthese je Bild (µs); bei flüssigen Bildern (< 20 ms) das Doppelte
const CHUNK: int = 2048        ## Samples je Häppchen einer Schicht (Nachbearbeitung: doppelt)

## Reihenfolge der Synthese: zuerst Oberfläche und häufige Effekte, dann Ambiente, zuletzt Musik.
const ORDER: PackedStringArray = ["click", "tab", "tick", "brush", "pop", "hit0", "hit1", "hit2", "bolt", "boom", "thunder",
	"km_fire", "km_water", "km_metal", "km_lightning", "km_wind", "km_soul", "km_light", "km_earth",
	"chime", "ascend", "bell", "war", "vil", "howl", "trib", "will", "ven",
	"fire", "rain", "wind", "sea",
	"air_calm", "ph_calm_0", "ph_calm_1", "air_dark", "ph_dark_0", "ph_dark_1", "ph_calm_2", "ph_dark_2"]
const PHRASES: int = 3   ## Phrasen je Stimmung

## Grundlautstärke je Klang (nach Normalisierung auf gleichen Spitzenpegel)
const GAIN: Dictionary = {"click": 0.32, "tab": 0.35, "tick": 0.22, "brush": 0.22, "pop": 0.3, "hit0": 0.3, "hit1": 0.3, "hit2": 0.3,
	"bolt": 0.55, "boom": 0.75, "thunder": 0.6, "chime": 0.4, "ascend": 0.6, "bell": 0.5, "war": 0.6, "vil": 0.4, "howl": 0.5,
	"trib": 0.65, "will": 0.7, "ven": 0.85, "km_fire": 0.5, "km_water": 0.55, "km_metal": 0.5, "km_lightning": 0.5, "km_wind": 0.55,
	"km_soul": 0.55, "km_light": 0.5, "km_earth": 0.55}
## Mindestabstand zwischen zwei gleichen Klängen (s)
const CD: Dictionary = {"click": 0.04, "tab": 0.06, "tick": 0.3, "brush": 0.13, "pop": 0.08, "hit0": 0.05, "hit1": 0.05, "hit2": 0.05,
	"bolt": 0.08, "boom": 0.12, "thunder": 0.9, "chime": 0.6, "ascend": 1.2, "bell": 2.5, "war": 3.0, "vil": 1.0, "howl": 4.0,
	"trib": 1.5, "will": 2.0, "ven": 3.0}
## höchstens so viele gleichzeitig
const MAXC: Dictionary = {"hit0": 2, "hit1": 2, "hit2": 2, "boom": 3, "bolt": 3, "thunder": 2, "brush": 1, "tick": 1, "bell": 1,
	"war": 1, "ven": 1, "will": 1, "howl": 1}
## Mordzug-Klangfamilie je Pfad (Ids aus GuData.PATH_NAME)
const FAM: PackedStringArray = ["earth", "light", "fire", "water", "wind", "lightning", "earth", "earth", "soul", "soul", "light", "light",
	"metal", "metal", "water", "water", "wind", "light", "soul", "soul", "light", "light", "soul", "soul",
	"light", "light", "soul", "earth", "lightning", "earth", "wind", "soul", "earth", "fire",
	"earth", "water", "metal", "metal", "metal", "soul", "soul", "soul", "earth", "fire", "light", "light", "wind", "metal"]
const DARK_AGES: PackedInt32Array = [2, 5, 8, 9]
## Bordun je Stimmung: [Frequenz, Lautstärke, LFO-Periode s] – gespielt vom Mischer selbst (Sinus-Tabelle mit mix_rate = f·128),
## kostet keine Synthesezeit; die Lautstärken wandern langsam (in _music).
const DRONE: Dictionary = {
	"calm": [[73.42, 0.5, 23.0], [110.0, 0.35, 17.0], [146.83, 0.3, 11.0], [220.0, 0.12, 13.0], [185.0, 0.06, 29.0], [73.67, 0.25, 31.0], [329.63, 0.05, 7.0]],
	"dark": [[55.0, 0.55, 19.0], [55.25, 0.4, 27.0], [82.41, 0.35, 13.0], [110.0, 0.2, 11.0], [130.81, 0.09, 17.0], [116.54, 0.035, 23.0],
		[41.2, 0.25, 15.0], [164.81, 0.1, 21.0], [220.0, 0.06, 9.0]]}
const OSC_N: int = 128
const AMB: PackedStringArray = ["fire", "rain", "wind", "sea"]
const AMB_GAIN: Dictionary = {"fire": 0.5, "rain": 0.38, "wind": 0.4, "sea": 0.42}
## Klänge mit Hall (Bus „GuSfxRev“; Musik-Phrasen über „GuMusicRev“) – Hall ist ein Bus-Effekt, kostet keine Synthesezeit
const RV: PackedStringArray = ["tab", "tick", "chime", "ascend", "bell", "war", "vil", "howl", "trib", "will", "ven", "km_water", "km_metal", "km_soul", "km_light"]

var m: GuMain = null
var enabled: bool = false       ## false im Headless-Betrieb (Tests): nichts wird erzeugt oder gespielt
var vol: float = 0.7            ## Effekte 0..1
var music_on: bool = true
var mvol: float = 0.5
var muted: bool = false

var streams: Dictionary = {}    ## Name -> AudioStreamWAV
var stats: Dictionary = {}      ## Name -> {ms, peak}
var _queue: PackedStringArray = PackedStringArray()
var _cur: Dictionary = {}
var _sr: int = SR
var _sd: int = 1                ## Rauschsamen (eigener Generator, die Simulation bleibt reproduzierbar)
var _ps: int = 1                ## Zufall der Phrasen-Erzeugung
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var synth_us: int = 0
var max_step_us: int = 0
var _t_start: int = 0
var _ready_printed: bool = false
var _now: float = 0.0

var _pool: Array[AudioStreamPlayer] = []
var _pool_nm: PackedStringArray = PackedStringArray()
var _pool_v: PackedFloat32Array = PackedFloat32Array()
var _pool_t: PackedFloat32Array = PackedFloat32Array()
var _cd: Dictionary = {}
var _later: Array = []          ## [Zeit, Name, Lautstärke, Tonhöhe]
var _amb: Dictionary = {}       ## Name -> AudioStreamPlayer
var _amb_v: Dictionary = {}
var _amb_goal: Dictionary = {}
var _amb_t: float = 0.0
var _osc: Dictionary = {}       ## Stimmung -> Array der Bordun-Spieler
var _air: Dictionary = {}       ## Stimmung -> Spieler der Bordun-Luft
var _mood_v: Dictionary = {"calm": 0.0, "dark": 0.0}
var _phr: AudioStreamPlayer
var _phr_t: float = 4.0
var _phr_last: String = ""
var _mood: String = "calm"
var _mood_t: float = 0.0


func _ready() -> void:
	_rng.seed = 7741
	_load_cfg()
	var dump: String = ""
	var test: bool = "--audiotest" in OS.get_cmdline_user_args()
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--sfxdump="):
			dump = a.substr(10)
	enabled = DisplayServer.get_name() != "headless" or dump != "" or test
	for i: int in range(POOL):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
		_pool_nm.append("")
		_pool_v.append(0.0)
		_pool_t.append(0.0)
	for nm: String in AMB:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(p)
		_amb[nm] = p
		_amb_v[nm] = 0.0
		_amb_goal[nm] = 0.0
	_phr = AudioStreamPlayer.new()
	add_child(_phr)
	if m != null:
		_connect()
	if not enabled:
		return
	_buses()
	_phr.bus = &"GuMusicRev"
	_make_osc()
	_queue = ORDER.duplicate()
	_t_start = Time.get_ticks_msec()
	if dump != "":
		_dump(dump)
	elif test and m != null:
		_audiotest.call_deferred()


## Hall-Busse (einmal je Programmlauf) und ein Begrenzer auf Master gegen Übersteuern bei vielen Ereignissen
func _buses() -> void:
	if AudioServer.get_bus_effect_count(0) == 0:
		var lim: AudioEffectHardLimiter = AudioEffectHardLimiter.new()
		lim.ceiling_db = -0.5
		AudioServer.add_bus_effect(0, lim)
	for spec: Array in [["GuSfxRev", 0.55, 0.22], ["GuMusicRev", 0.75, 0.3]]:
		if AudioServer.get_bus_index(spec[0]) >= 0:
			continue
		var i: int = AudioServer.bus_count
		AudioServer.add_bus(i)
		AudioServer.set_bus_name(i, spec[0])
		AudioServer.set_bus_send(i, &"Master")
		var rv: AudioEffectReverb = AudioEffectReverb.new()
		rv.room_size = spec[1]
		rv.damping = 0.45
		rv.spread = 0.7
		rv.dry = 1.0
		rv.wet = spec[2]
		AudioServer.add_bus_effect(i, rv)


## Bordun-Oszillatoren: eine Sinus-Periode (OSC_N Samples) als Schleife, Tonhöhe über mix_rate.
func _make_osc() -> void:
	var tbl: PackedByteArray = PackedByteArray()
	tbl.resize(OSC_N * 2)
	for i: int in range(OSC_N):
		tbl.encode_s16(i * 2, int(sin(TAU * i / OSC_N) * 29000.0))
	for md: String in DRONE:
		var arr: Array[AudioStreamPlayer] = []
		for p: Array in DRONE[md]:
			var st: AudioStreamWAV = AudioStreamWAV.new()
			st.format = AudioStreamWAV.FORMAT_16_BITS
			st.mix_rate = roundi(float(p[0]) * OSC_N)
			st.data = tbl
			st.loop_mode = AudioStreamWAV.LOOP_FORWARD
			st.loop_begin = 0
			st.loop_end = OSC_N
			var pl: AudioStreamPlayer = AudioStreamPlayer.new()
			pl.stream = st
			add_child(pl)
			arr.append(pl)
		_osc[md] = arr
		var ap: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(ap)
		_air[md] = ap


func _connect() -> void:
	var h: Hud = m.hud
	h.tab_pressed.connect(func(_i: int) -> void: play("tab", 0.8))
	h.tool_pressed.connect(func(_t: Dictionary) -> void: play("click", 0.8))
	h.meta_clicked.connect(func(_s: String) -> void: play("click", 0.6))
	h.brush_changed.connect(func(_i: int) -> void: play("click", 0.6))
	for sg: Signal in [h.back_pressed, h.pause_pressed, h.speed_pressed, h.star_pressed, h.gift_pressed, h.weather_stop, h.show_ui_pressed]:
		sg.connect(func() -> void: play("click", 0.8))
	m.sim.logged.connect(func(_t: String, _k: String, _n: bool) -> void:
		if _quiet():
			return
		play("tick", 0.7))
	m.sim.unit_died.connect(_on_died)


# ---------------- Einstellungen ----------------

func _load_cfg() -> void:
	var c: ConfigFile = ConfigFile.new()
	if c.load(CFG) != OK:
		return
	vol = clampf(float(c.get_value("audio", "volume", 0.7)), 0.0, 1.0)
	music_on = bool(c.get_value("audio", "music", true))
	mvol = clampf(float(c.get_value("audio", "music_volume", 0.5)), 0.0, 1.0)
	muted = bool(c.get_value("audio", "mute", false))


func _save_cfg() -> void:
	var c: ConfigFile = ConfigFile.new()
	c.load(CFG)   # andere Einträge behalten
	c.set_value("audio", "volume", vol)
	c.set_value("audio", "music", music_on)
	c.set_value("audio", "music_volume", mvol)
	c.set_value("audio", "mute", muted)
	c.save(CFG)


func set_volume(v: float) -> void:
	vol = clampf(snappedf(v, 0.05), 0.0, 1.0)
	_save_cfg()


func set_music(on: bool) -> void:
	music_on = on
	_save_cfg()


func set_music_volume(v: float) -> void:
	mvol = clampf(snappedf(v, 0.05), 0.0, 1.0)
	_save_cfg()


func set_mute(on: bool) -> void:
	muted = on
	_save_cfg()


## Links `snd:<k>` aus dem Fenster „Display“.
func meta(k: String) -> void:
	match k:
		"mute":
			set_mute(not muted)
		"music":
			set_music(not music_on)
		"vol-":
			set_volume(vol - 0.1)
		"vol+":
			set_volume(vol + 0.1)
		"mvol-":
			set_music_volume(mvol - 0.1)
		"mvol+":
			set_music_volume(mvol + 0.1)
	play("click", 0.8)


func _sw(on: bool) -> String:
	return "[color=#5fbf8a][b]● ON[/b][/color]" if on else "[color=#c74634][b]○ OFF[/b][/color]"


## Zeilen für das Fenster „Display“.
func display_text() -> String:
	var b: String = "[color=#9fd0ff][b]  %s  [/b][/color]"
	var s: String = "\n[b]Sound[/b]\n"
	s += "[url=snd:mute]%s  [b]Sound[/b][/url]\n    [color=#9db09e]All sound effects and music (mute).[/color]\n" % _sw(not muted)
	s += "[b]Effects volume[/b]  [url=snd:vol-]%s[/url] [b]%d %%[/b] [url=snd:vol+]%s[/url]\n" % [b % "−", roundi(vol * 100.0), b % "+"]
	s += "[url=snd:music]%s  [b]Music[/b][/url]\n    [color=#9db09e]Generative guzheng and dizi over a drone – darker in grim ages and while a Venerable lives.[/color]\n" % _sw(music_on)
	s += "[b]Music volume[/b]  [url=snd:mvol-]%s[/url] [b]%d %%[/b] [url=snd:mvol+]%s[/url]\n" % [b % "−", roundi(mvol * 100.0), b % "+"]
	if not enabled:
		s += "    [color=#9db09e](no audio device)[/color]\n"
	return s


# ---------------- Abspielen ----------------

func _quiet() -> bool:
	return m == null or m.loading or m.sim.presim or m.sim.cheats.jumping()


## Globaler Effekt (ohne Ort).
func play(nm: String, v: float = 1.0, pitch: float = 1.0) -> void:
	if not streams.has(nm) or muted or vol <= 0.001 or v <= 0.01:
		return
	if float(_cd.get(nm, -1.0)) > _now:
		return
	var same: int = 0
	var free: int = -1
	var steal: int = -1
	var steal_t: float = 1e9
	for i: int in range(POOL):
		var p: AudioStreamPlayer = _pool[i]
		if not p.playing:
			if free < 0:
				free = i
			continue
		if _pool_nm[i] == nm:
			same += 1
		# leisere und ältere Stimmen dürfen verdrängt werden
		var age_score: float = _pool_t[i] + _pool_v[i] * 4.0
		if _pool_v[i] <= v and age_score < steal_t:
			steal_t = age_score
			steal = i
	if same >= int(MAXC.get(nm, 2)):
		return
	var slot: int = free if free >= 0 else steal
	if slot < 0:
		return
	_cd[nm] = _now + float(CD.get(nm, 0.15))
	var pl: AudioStreamPlayer = _pool[slot]
	pl.stop()
	pl.stream = streams[nm]
	pl.bus = &"GuSfxRev" if RV.has(nm) else &"Master"
	pl.volume_db = linear_to_db(maxf(0.0001, v * vol * float(GAIN.get(nm, 0.6))))
	pl.pitch_scale = pitch * (1.0 + (_rng.randf() - 0.5) * 0.08)
	pl.play()
	_pool_nm[slot] = nm
	_pool_v[slot] = v
	_pool_t[slot] = _now


## Lautstärke nach Lage zur Bildmitte (1 im Bild, leiser bis 0 knapp außerhalb) und Zoom (Übersicht leiser).
func pos_vol(x: float, y: float) -> float:
	if m == null:
		return 1.0
	var vs: Vector2 = m.get_viewport_rect().size
	var hw: float = maxf(1.0, vs.x * 0.5 / m.z)
	var hh: float = maxf(1.0, m.view_h() * 0.5 / m.z)
	var d: float = maxf(absf(x - m.cam.x) / hw, absf(y - m.cam.y) / hh)
	var v: float = 1.0 if d <= 1.0 else clampf(1.0 - (d - 1.0) * 1.5, 0.0, 1.0)
	var zf: float = clampf(0.4 + 0.6 * (m.z - m.min_z) / maxf(0.5, 5.0 - m.min_z), 0.4, 1.0)
	return v * zf


func play_at(nm: String, x: float, y: float, v: float = 1.0, floor_v: float = 0.0, pitch: float = 1.0) -> void:
	play(nm, v * maxf(floor_v, pos_vol(x, y)), pitch)


## Werkzeug-Einsatz auf der Karte (aus GuMain._paint_at/_tap_at).
func tool(t: Dictionary) -> void:
	match str(t.get("m", "")):
		"spawn":
			play("pop", 0.7)
		"paint":
			play("brush", 0.8)
		_:
			play("pop", 0.5, 0.75)


func _on_died(u: Unit) -> void:
	if _quiet():
		return
	if u.fig != "" or (u.k == "p" and u.rank >= 6):
		play_at("bell", u.x, u.y, 1.0 if u.fig != "" else 0.7, 0.45)


## Ein Ereignis aus Sim.sfx: [Art, x, y, Wert].
func _event(e: Array, has_ven: bool) -> void:
	var k: String = e[0]
	var x: float = e[1]
	var y: float = e[2]
	var p: float = e[3]
	match k:
		"bolt":
			var v: float = pos_vol(x, y)
			play("bolt", v)
			if v > 0.15:
				_later.append([_now + 0.25 + _rng.randf() * 0.5, "thunder", v * 0.8, 0.9 + _rng.randf() * 0.2])
		"boom":
			play_at("boom", x, y, clampf(0.45 + p / 12.0, 0.45, 1.4), 0.0, clampf(1.3 - p * 0.03, 0.55, 1.2))
		"km", "snap":
			var f: String = FAM[clampi(int(p), 0, FAM.size() - 1)]
			if k == "km":
				play_at("km_" + f, x, y, 1.0, 0.0)
			else:
				play_at("km_" + f, x, y, 0.4, 0.0, 1.12)
		"hit":
			play_at("hit%d" % _rng.randi_range(0, 2), x, y, 0.45 + p * 0.25, 0.0, 1.0 - p * 0.12)
		"rank":
			if has_ven or p >= 9.0:
				return
			if p >= 6.0:
				play_at("ascend", x, y, 1.0, 0.35)
			elif p >= 3.0:
				play_at("chime", x, y, 0.3 + 0.12 * (p - 3.0), 0.0, 1.0 + (5.0 - p) * 0.06)
		"trib":
			play_at("trib", x, y, 1.0, 0.4)
		"will":
			play_at("will", x, y, 1.0, 0.6)
		"ven":
			play("ven", 1.0)
		"war":
			play("war", 0.8)
		"vil":
			play_at("vil", x, y, 0.8, 0.0)
		"tide":
			play_at("howl", x, y, 1.0, 0.4)


func _process(delta: float) -> void:
	var dt: float = minf(delta, 0.1)
	_now += dt
	if enabled and (not _queue.is_empty() or not _cur.is_empty()):
		_run_jobs(BUDGET_US * (2 if delta < 0.02 else 1))
	if m == null:
		return
	var q: Array = m.sim.sfx
	if not q.is_empty():
		if not _quiet():
			var has_ven: bool = false
			for e: Array in q:
				if e[0] == "ven":
					has_ven = true
			for e: Array in q:
				_event(e, has_ven)
		q.clear()
	var i: int = _later.size() - 1
	while i >= 0:
		var l: Array = _later[i]
		if float(l[0]) <= _now:
			play(l[1], l[2], l[3])
			_later.remove_at(i)
		i -= 1
	_amb_t -= dt
	if _amb_t <= 0.0:
		_amb_t = 0.25
		_ambience_goals()
	for nm: String in AMB:
		var p: AudioStreamPlayer = _amb[nm]
		var v: float = move_toward(float(_amb_v[nm]), float(_amb_goal[nm]), dt * 0.6)
		_amb_v[nm] = v
		_set_loop(p, nm, v * vol * float(AMB_GAIN[nm]) * (0.0 if muted else 1.0))
	_music(dt)


## Endlosschleife ein-/ausblenden (ab ~0 gestoppt, damit nichts unnötig mischt).
func _set_loop(p: AudioStreamPlayer, nm: String, v: float) -> void:
	if v < 0.003:
		if p.playing:
			p.stop()
		return
	if not streams.has(nm):
		return
	if p.stream != streams[nm]:
		p.stream = streams[nm]
	p.volume_db = linear_to_db(v)
	if not p.playing:
		var ln: float = (p.stream as AudioStreamWAV).get_length()
		p.play(_rng.randf() * ln * 0.9)


func _ambience_goals() -> void:
	for nm: String in AMB:
		_amb_goal[nm] = 0.0
	if m == null or m.loading:
		return
	var sim: Sim = m.sim
	var wt: String = sim.weather.get("type", "")
	var zf: float = clampf(0.45 + 0.55 * (m.z - m.min_z) / maxf(0.5, 4.0 - m.min_z), 0.45, 1.0)
	if wt == "rain":
		_amb_goal["rain"] = 0.9
		_amb_goal["wind"] = 0.3
	elif wt == "snow":
		_amb_goal["wind"] = 0.45
	elif wt == "sand":
		_amb_goal["wind"] = 1.0
	elif wt == "drought":
		_amb_goal["wind"] = 0.18
	# Sichtbereich in Kacheln
	var vs: Vector2 = m.get_viewport_rect().size
	var hw: float = vs.x * 0.5 / m.z
	var hh: float = m.view_h() * 0.5 / m.z
	var x0: float = m.cam.x - hw
	var y0: float = m.cam.y - hh
	var x1: float = m.cam.x + hw
	var y1: float = m.cam.y + hh
	# Feuer nahe der Kamera
	if not sim.fire.is_empty():
		var w: int = GuData.W
		var n: int = 0
		var seen: int = 0
		for fi: int in sim.fire:
			seen += 1
			if seen > 3000:
				break
			var fx: float = fi % w
			var fy: float = fi / w
			if fx >= x0 - 4.0 and fx <= x1 + 4.0 and fy >= y0 - 4.0 and fy <= y1 + 4.0:
				n += 1
				if n >= 60:
					break
		if n > 0:
			_amb_goal["fire"] = clampf(0.25 + n / 40.0, 0.0, 1.0) * zf
	# Meer und Küste, nur nah
	if m.z >= 2.0 and sim.world != null:
		var wat: int = 0
		var tot: int = 0
		for gy: int in range(7):
			for gx: int in range(7):
				var tx: int = int(x0 + (x1 - x0) * (gx + 0.5) / 7.0)
				var ty: int = int(y0 + (y1 - y0) * (gy + 0.5) / 7.0)
				if tx < 0 or ty < 0 or tx >= GuData.W or ty >= GuData.H:
					continue
				tot += 1
				if GuData.is_water(sim.world.tile[ty * GuData.W + tx]):
					wat += 1
		if tot > 0 and wat > 0:
			var f: float = float(wat) / tot
			var coast: float = minf(f, 1.0 - f) * 2.0
			_amb_goal["sea"] = clampf(coast * 0.75 + f * 0.35, 0.0, 1.0) * clampf((m.z - 2.0) / 2.5, 0.0, 1.0)


func _music(dt: float) -> void:
	var mf: float = mvol if (music_on and not muted) else 0.0
	_mood_t -= dt
	if _mood_t <= 0.0 and m != null:
		_mood_t = 2.0
		var dark: bool = DARK_AGES.has(m.sim.age_index()) or (m.sim.ven != null and not m.sim.ven.st.is_empty())
		_mood = "dark" if dark else "calm"
	for md: String in _mood_v:
		_mood_v[md] = move_toward(float(_mood_v[md]), 1.0 if (md == _mood and mf > 0.0) else 0.0, dt / 6.0)
	for md: String in _osc:
		var mv: float = float(_mood_v[md]) * mf
		var ps: Array = _osc[md]
		var parts: Array = DRONE[md]
		for i: int in range(ps.size()):
			var pl: AudioStreamPlayer = ps[i]
			var p: Array = parts[i]
			var lfo: float = 1.0 - 0.55 * (0.5 + 0.5 * cos(TAU * _now / float(p[2]) + i * 1.7))
			var v: float = mv * float(p[1]) * lfo * 0.3
			if v < 0.0015:
				if pl.playing:
					pl.stop()
				continue
			pl.volume_db = linear_to_db(v)
			if not pl.playing:
				pl.play()
		_set_loop(_air[md], "air_" + md, mv * 0.4)
	if mf <= 0.0:
		if _phr.playing:
			_phr.stop()
		return
	_phr.volume_db = linear_to_db(maxf(0.0001, mf * 0.75))
	if _phr.playing or _now < _phr_t:
		return
	var opts: Array[String] = []
	for k: int in range(PHRASES):
		var nm: String = "ph_%s_%d" % [_mood, k]
		if streams.has(nm) and nm != _phr_last:
			opts.append(nm)
	if opts.is_empty():
		return
	_phr_last = opts[_rng.randi() % opts.size()]
	_phr.stream = streams[_phr_last]
	_phr.play()
	_phr_t = _now + (_phr.stream as AudioStreamWAV).get_length() + 3.0 + _rng.randf() * (9.0 if _mood == "calm" else 14.0)


# ---------------- Synthese-Aufträge ----------------

func _run_jobs(budget: int) -> void:
	var t0: int = Time.get_ticks_usec()
	while true:
		if _cur.is_empty():
			if _queue.is_empty():
				break
			var nm: String = _queue[0]
			_queue.remove_at(0)
			var tb: int = Time.get_ticks_usec()
			_cur = _build(nm)
			_cur["us"] = Time.get_ticks_usec() - tb
		var ts: int = Time.get_ticks_usec()
		var done: bool = _step(_cur)
		var us: int = Time.get_ticks_usec() - ts
		_cur["us"] = int(_cur["us"]) + us
		max_step_us = maxi(max_step_us, us)
		if done:
			stats[_cur["nm"]] = {"ms": int(_cur["us"]) / 1000.0, "peak": float(_cur["pk_raw"])}
			_cur = {}
		if Time.get_ticks_usec() - t0 >= budget:
			break
	synth_us += Time.get_ticks_usec() - t0
	if _queue.is_empty() and _cur.is_empty() and not _ready_printed:
		_ready_printed = true
		print("AUDIO READY sounds=%d synth_ms=%.0f max_step_ms=%.1f wall_ms=%d" % [streams.size(), synth_us / 1000.0, max_step_us / 1000.0, Time.get_ticks_msec() - _t_start])


## Rezept: Puffer + Schichten (je Aufruf ein Häppchen einer Schicht), danach Gleichanteil/Spitze und Kodieren.
## Schleifen (loop) bekommen xf Sekunden Überhang, der in den Anfang geblendet wird.
func _rec(nm: String, dur: float, sr: int = SR, loop: bool = false, xf: float = 0.0, pk: float = 0.9) -> Dictionary:
	_sd = absi(hash(nm)) % 2147483647 + 1
	var n: int = int((dur + (xf if loop else 0.0)) * sr)
	var b: PackedFloat32Array = PackedFloat32Array()
	b.resize(n)
	return {"nm": nm, "sr": sr, "b": b, "L": [], "li": 0, "c": 0, "st": 0, "i": 0, "loop": loop, "len": int(dur * sr),
		"xf": int(xf * sr), "pk": pk, "pk_raw": 0.0, "mean": 0.0, "us": 0}


func _ns() -> int:
	_sd = (_sd * 1103515245 + 12345) & 0x7FFFFFFF
	return _sd


func _step(r: Dictionary) -> bool:
	_sr = r["sr"]
	var b: PackedFloat32Array = r["b"]
	var st: int = r["st"]
	if st == 0:   # Schichten in Häppchen
		var L: Array = r["L"]
		var li: int = r["li"]
		if li < L.size():
			var e: Array = L[li]
			var c0: int = r["c"]
			var c1: int = mini(int(e[1]), c0 + CHUNK)
			(e[0] as Callable).call(b, e[2], c0, c1)
			if c1 >= int(e[1]):
				r["li"] = li + 1
				r["c"] = 0
			else:
				r["c"] = c1
			return false
		if r["loop"]:
			# nahtlose Schleife: Überhang in den Anfang blenden
			var n: int = r["len"]
			var x: int = r["xf"]
			for i: int in range(x):
				var a: float = float(i) / x
				b[i] = b[i] * a + b[n + i] * (1.0 - a)
			b.resize(n)
		r["st"] = 1 if r["loop"] else 2
		r["i"] = 0
		r["dc"] = PackedFloat64Array([0.0, 0.0])
		return false
	var i0: int = r["i"]
	var i1: int = mini(b.size(), i0 + CHUNK * 2)
	var nb: int = b.size()
	if st == 1:   # Schleife: Mittelwert
		var sm: float = r["mean"]
		for i: int in range(i0, i1):
			sm += b[i]
		r["mean"] = sm
		r["i"] = i1
		if i1 >= nb:
			r["mean"] = sm / maxf(1.0, nb)
			r["st"] = 2
			r["i"] = 0
		return false
	if st == 2:   # Gleichanteil entfernen (Schleife: Mittelwert, sonst Hochpass) und Spitze messen
		var pk: float = r["pk_raw"]
		if r["loop"]:
			var mean: float = r["mean"]
			for i: int in range(i0, i1):
				var v: float = b[i] - mean
				b[i] = v
				pk = maxf(pk, absf(v))
		else:
			var dc: PackedFloat64Array = r["dc"]
			var x1: float = dc[0]
			var y1: float = dc[1]
			var R: float = 1.0 - TAU * 12.0 / _sr
			for i: int in range(i0, i1):
				var x: float = b[i]
				var y: float = x - x1 + R * y1
				x1 = x
				y1 = y
				b[i] = y
				pk = maxf(pk, absf(y))
			dc[0] = x1
			dc[1] = y1
		r["pk_raw"] = pk
		r["i"] = i1
		if i1 >= nb:
			r["st"] = 3
			r["i"] = 0
			var by: PackedByteArray = PackedByteArray()
			by.resize(nb * 2)
			r["by"] = by
		return false
	if st == 3:   # 16 Bit kodieren, Ein-/Ausblenden
		var by: PackedByteArray = r["by"]
		var g: float = float(r["pk"]) / maxf(1e-6, float(r["pk_raw"])) * 32767.0
		var fi: int = 0 if r["loop"] else 48
		var fo: int = 0 if r["loop"] else mini(int(0.25 * _sr), nb / 8)
		for i: int in range(i0, i1):
			var v: float = b[i] * g
			if i < fi:
				v *= float(i) / fi
			elif nb - i < fo:
				v *= float(nb - i) / fo
			by.encode_s16(i * 2, int(v))
		r["i"] = i1
		if i1 >= nb:
			r["st"] = 4
		return false
	var ws: AudioStreamWAV = AudioStreamWAV.new()
	ws.format = AudioStreamWAV.FORMAT_16_BITS
	ws.mix_rate = _sr
	ws.stereo = false
	ws.data = r["by"]
	if r["loop"]:
		ws.loop_mode = AudioStreamWAV.LOOP_FORWARD
		ws.loop_begin = 0
		ws.loop_end = nb
	streams[r["nm"]] = ws
	r.erase("b")
	r.erase("by")
	return true


# ---------------- Schichten ----------------
# Jede Schicht: fn(b, s, c0, c1, i0, n, …) addiert die Samples c0..c1 (von n) ab Pufferstelle i0;
# s = Zustand zwischen den Häppchen. Bauen über die Helfer _T, _N, _B, _C, _P, _F, _H, _Fl, _Pad, _Sw (Zeiten in s).

func _L(r: Dictionary, t0: float, dur: float, fn: Callable, args: Array) -> void:
	var sr: int = r["sr"]
	var b: PackedFloat32Array = r["b"]
	var i0: int = int(t0 * sr)
	var n: int = mini(int(dur * sr), b.size() - i0)
	if n <= 0:
		return
	(r["L"] as Array).append([fn.bindv([i0, n] + args), n, {}])


## Länge nach Hüllkurve kürzen (−52 dB)
func _cut(dur: float, att: float, tau: float) -> float:
	return minf(dur, att + tau * 6.0) if tau > 0.0 else dur


## Sinus mit exponentiellem Gleiten f0 → f1, Einschwingen att, Abklingen tau (≤ 0: keins), Vibrato, h3 = Rechteck-Anteil.
func _T(r: Dictionary, t0: float, dur: float, f0: float, f1: float, amp: float, att: float, tau: float, vib: float = 0.0, h3: float = 0.0) -> void:
	if maxf(f0, f1) * (1.0 + vib) * (5.0 if h3 > 0.0 else 1.0) >= float(r["sr"]) * 0.48:
		return   # läge über der Nyquist-Grenze
	_L(r, t0, _cut(dur, att, tau), _tone, [f0, f1, amp, att, tau, vib, h3])


## Rauschen durch Tiefpass (Grenze gleitet lp0 → lp1) und optionalen Hochpass hp.
func _N(r: Dictionary, t0: float, dur: float, amp: float, att: float, tau: float, lp0: float, lp1: float, hp: float) -> void:
	_L(r, t0, _cut(dur, att, tau), _noise, [amp, att, tau, lp0, lp1, hp, _ns()])


## Bandpass-Rauschen (Zustandsvariablen-Filter), Mitte f0 → f1, LFO in Oktaven; q = Dämpfung (klein = schmal).
func _B(r: Dictionary, t0: float, dur: float, amp: float, att: float, tau: float, f0: float, f1: float, q: float, lfo: float = 0.0, oct: float = 0.0) -> void:
	_L(r, t0, _cut(dur, att, tau), _bandn, [amp, att, tau, f0, f1, q, _ns(), lfo, oct])


## Knistern: zufällige kurze, helle Klicks (rate je Sekunde, ms Länge).
func _C(r: Dictionary, t0: float, dur: float, rate: float, amp: float, ms: float) -> void:
	_L(r, t0, dur, _crackle, [rate, amp, _ns(), ms])


## Gezupfte Saite (Guzheng, Karplus-Strong mit Allpass-Feinstimmung): t60 Abklingzeit, bright 0..1.
func _P(r: Dictionary, t0: float, f: float, amp: float, t60: float, bright: float, dur: float = -1.0) -> void:
	_L(r, t0, dur if dur > 0.0 else t60 * 0.75, _pluck, [f, amp, t60, bright, _ns()])


## FM-Ton (Metall): Träger fc, Modulator fc·ratio, Index idx fällt mit itau.
func _F(r: Dictionary, t0: float, dur: float, fc: float, ratio: float, idx: float, amp: float, att: float, tau: float, itau: float) -> void:
	_L(r, t0, _cut(dur, att, tau), _fm, [fc, ratio, idx, amp, att, tau, itau])


## Heulen (Wolf): steigt f0 → fp, hält, fällt auf fe.
func _H(r: Dictionary, t0: float, dur: float, f0: float, fp: float, fe: float, amp: float) -> void:
	_L(r, t0, dur, _howl, [f0, fp, fe, amp, _ns()])


## Flöte (Dizi/Xiao): Anblasen von unten, verzögertes Vibrato, h = Obertöne, breath = Atem.
func _Fl(r: Dictionary, t0: float, dur: float, f: float, amp: float, breath: float, h: float) -> void:
	_L(r, t0, dur, _flute, [f, amp, breath, h, _ns()])


## Fläche (Bordun): Sinus mit langsamer Lautstärke-Welle (Periode per s, Tiefe 0..1, Phase ph0).
func _Pad(r: Dictionary, t0: float, dur: float, f: float, amp: float, per: float, depth: float, ph0: float) -> void:
	_L(r, t0, dur, _pad, [f, amp, per, depth, ph0])


## Rauschen mit Wellen-Hüllkurve (Meer).
func _Sw(r: Dictionary, t0: float, dur: float, amp: float, lp: float, hp: float, per: float, ph0: float) -> void:
	_L(r, t0, dur, _swell, [amp, lp, hp, per, ph0, _ns()])


func _tone(b: PackedFloat32Array, s: Dictionary, c0: int, c1: int, i0: int, n: int, f0: float, f1: float, amp: float, att: float, tau: float, vib: float, h3: float) -> void:
	var sr: float = _sr
	var ph: float = s.get("ph", 0.0)
	var env: float = s.get("e", amp)
	var w: float = s.get("w", TAU * f0 / sr)
	var gk: float = exp(log(f1 / f0) / n)
	var dec: float = exp(-1.0 / (tau * sr)) if tau > 0.0 else 1.0
	var na: int = int(att * sr)
	var ia: float = 1.0 / maxf(1.0, na)
	var fo: int = maxi(1, mini(n / 3, int(0.01 * sr)))
	var nf: int = n - fo
	var j: int = i0 + c0
	if vib == 0.0 and h3 == 0.0:
		for i: int in range(c0, c1):
			var g: float = env
			if i < na:
				g *= i * ia
			elif i > nf:
				g *= float(n - i) / fo
			b[j] += sin(ph) * g
			env *= dec
			ph += w
			w *= gk
			j += 1
	else:
		var vr: float = TAU * 5.3 / sr
		for i: int in range(c0, c1):
			var g: float = env
			if i < na:
				g *= i * ia
			elif i > nf:
				g *= float(n - i) / fo
			var v: float = sin(ph)
			if h3 > 0.0:
				v += h3 * (sin(ph * 3.0) * 0.333 + sin(ph * 5.0) * 0.2)
			b[j] += v * g
			env *= dec
			ph += w * (1.0 + vib * sin(i * vr))
			w *= gk
			j += 1
	s["ph"] = ph
	s["e"] = env
	s["w"] = w


func _noise(b: PackedFloat32Array, s: Dictionary, c0: int, c1: int, i0: int, n: int, amp: float, att: float, tau: float, lp0: float, lp1: float, hp: float, sd0: int) -> void:
	var sr: float = _sr
	var sd: int = s.get("sd", sd0)
	var y: float = s.get("y", 0.0)
	var y2: float = s.get("y2", 0.0)
	var hl: float = s.get("hl", 0.0)
	var env: float = s.get("e", amp * 1.6)
	var dec: float = exp(-1.0 / (tau * sr)) if tau > 0.0 else 1.0
	var na: int = int(att * sr)
	var ia: float = 1.0 / maxf(1.0, na)
	var fo: int = maxi(1, mini(n / 3, int(0.01 * sr)))
	var nf: int = n - fo
	var ah: float = 1.0 - exp(-TAU * hp / sr) if hp > 0.0 else 0.0
	var lr: float = log(lp1 / lp0)
	var a: float = 0.0
	var j: int = i0 + c0
	for i: int in range(c0, c1):
		if (i & 31) == 0 or i == c0:
			a = 1.0 - exp(-TAU * minf(sr * 0.45, lp0 * exp(lr * i / n)) / sr)
		sd = (sd * 1103515245 + 12345) & 0x7FFFFFFF
		y += (float(sd) / 1073741824.0 - 1.0 - y) * a
		y2 += (y - y2) * a
		var o: float = y2
		if ah > 0.0:
			hl += (y2 - hl) * ah
			o = y2 - hl
		var g: float = env
		if i < na:
			g *= i * ia
		elif i > nf:
			g *= float(n - i) / fo
		b[j] += o * g
		env *= dec
		j += 1
	s["sd"] = sd
	s["y"] = y
	s["y2"] = y2
	s["hl"] = hl
	s["e"] = env


func _bandn(b: PackedFloat32Array, s: Dictionary, c0: int, c1: int, i0: int, n: int, amp: float, att: float, tau: float, f0: float, f1: float, q: float, sd0: int, lfo: float, oct: float) -> void:
	var sr: float = _sr
	var sd: int = s.get("sd", sd0)
	var lo: float = s.get("lo", 0.0)
	var bd: float = s.get("bd", 0.0)
	var env: float = s.get("e", amp * sqrt(q) * 1.4)
	var dec: float = exp(-1.0 / (tau * sr)) if tau > 0.0 else 1.0
	var na: int = int(att * sr)
	var ia: float = 1.0 / maxf(1.0, na)
	var fo: int = maxi(1, mini(n / 3, int(0.02 * sr)))
	var nf: int = n - fo
	var lr: float = log(f1 / f0)
	var lw: float = TAU * lfo / sr
	var fc: float = 0.1
	var j: int = i0 + c0
	for i: int in range(c0, c1):
		if (i & 15) == 0 or i == c0:
			var f: float = f0 * exp(lr * i / n)
			if oct != 0.0:
				f *= pow(2.0, oct * sin(lw * i))
			fc = 2.0 * sin(PI * minf(f, sr * 0.2) / sr)
		sd = (sd * 1103515245 + 12345) & 0x7FFFFFFF
		lo += fc * bd
		bd += fc * (float(sd) / 1073741824.0 - 1.0 - lo - q * bd)
		var g: float = env
		if i < na:
			g *= i * ia
		elif i > nf:
			g *= float(n - i) / fo
		b[j] += bd * g
		env *= dec
		j += 1
	s["sd"] = sd
	s["lo"] = lo
	s["bd"] = bd
	s["e"] = env


func _crackle(b: PackedFloat32Array, s: Dictionary, c0: int, c1: int, i0: int, n: int, rate: float, amp: float, sd0: int, ms: float) -> void:
	var sr: float = _sr
	var sd: int = s.get("sd", sd0)
	var cl: float = s.get("cl", 0.0)
	var pv: float = s.get("pv", 0.0)
	var p: float = rate / sr
	var dec: float = exp(-1.0 / (ms * 0.001 * sr))
	var j: int = i0 + c0
	for i: int in range(c0, c1):
		sd = (sd * 1103515245 + 12345) & 0x7FFFFFFF
		var r: float = float(sd) / 2147483648.0
		if r < p:
			var r2: float = r / p
			cl = amp * (0.2 + 0.8 * r2 * r2)
		if cl > 0.0005:
			sd = (sd * 1103515245 + 12345) & 0x7FFFFFFF
			var x: float = float(sd) / 1073741824.0 - 1.0
			b[j] += (x - pv) * 0.6 * cl
			pv = x
			cl *= dec
		j += 1
	s["sd"] = sd
	s["cl"] = cl
	s["pv"] = pv


func _pluck(b: PackedFloat32Array, s: Dictionary, c0: int, c1: int, i0: int, n: int, f: float, amp: float, t60: float, bright: float, sd0: int) -> void:
	var sr: float = _sr
	# Schleifenverzögerung P = N + 0,5 (Mittelwert) + Δ (Allpass)
	var p: float = sr / f
	var nd: int = maxi(2, int(p - 0.6))
	var dl: float = p - 0.5 - nd
	var cc: float = (1.0 - dl) / (1.0 + dl)
	var d: PackedFloat32Array
	var sc: float = amp
	if c0 == 0:
		d = PackedFloat32Array()
		d.resize(nd)
		var sd: int = sd0
		var y: float = 0.0
		var mean: float = 0.0
		for k: int in range(nd):
			sd = (sd * 1103515245 + 12345) & 0x7FFFFFFF
			y += (float(sd) / 1073741824.0 - 1.0 - y) * bright
			d[k] = y
			mean += y
		mean /= nd
		var pk: float = 1e-6
		for k: int in range(nd):
			d[k] -= mean
			pk = maxf(pk, absf(d[k]))
		s["d"] = d
		sc = amp / pk
		s["sc"] = sc
	else:
		d = s["d"]
		sc = s["sc"]
	var ix: int = s.get("ix", 0)
	var po: float = s.get("po", 0.0)
	var ax: float = s.get("ax", 0.0)
	var ay: float = s.get("ay", 0.0)
	var g: float = pow(0.001, 1.0 / (f * t60))
	var fo: int = maxi(1, mini(n / 3, int(0.03 * sr)))
	var nf: int = n - fo
	var j: int = i0 + c0
	for i: int in range(c0, c1):
		var o: float = d[ix]
		var av: float = (o + po) * 0.5
		po = o
		ay = cc * (av - ay) + ax
		ax = av
		d[ix] = ay * g
		ix += 1
		if ix >= nd:
			ix = 0
		if i > nf:
			b[j] += o * sc * float(n - i) / fo
		else:
			b[j] += o * sc
		j += 1
	s["ix"] = ix
	s["po"] = po
	s["ax"] = ax
	s["ay"] = ay


func _fm(b: PackedFloat32Array, s: Dictionary, c0: int, c1: int, i0: int, n: int, fc: float, ratio: float, idx: float, amp: float, att: float, tau: float, itau: float) -> void:
	var sr: float = _sr
	var wc: float = TAU * fc / sr
	var wm: float = wc * ratio
	var dec: float = exp(-1.0 / (tau * sr))
	var idec: float = exp(-1.0 / (itau * sr))
	var na: int = int(att * sr)
	var ia: float = 1.0 / maxf(1.0, na)
	var fo: int = maxi(1, mini(n / 3, int(0.01 * sr)))
	var nf: int = n - fo
	var env: float = s.get("e", amp)
	var ie: float = s.get("ie", idx)
	var j: int = i0 + c0
	for i: int in range(c0, c1):
		var g: float = env
		if i < na:
			g *= i * ia
		elif i > nf:
			g *= float(n - i) / fo
		b[j] += sin(wc * i + ie * sin(wm * i)) * g
		env *= dec
		ie *= idec
		j += 1
	s["e"] = env
	s["ie"] = ie


func _howl(b: PackedFloat32Array, s: Dictionary, c0: int, c1: int, i0: int, n: int, f0: float, fp: float, fe: float, amp: float, sd0: int) -> void:
	var sr: float = _sr
	var ph: float = s.get("ph", 0.0)
	var y: float = s.get("y", 0.0)
	var sd: int = s.get("sd", sd0)
	var ia: float = 1.0 / (0.18 * sr)
	var rel: int = mini(n / 2, int(0.5 * sr))
	var j: int = i0 + c0
	for i: int in range(c0, c1):
		var t: float = float(i) / n
		var f: float
		if t < 0.3:
			var u: float = t / 0.3
			f = f0 + (fp - f0) * u * u * (3.0 - 2.0 * u)
		elif t < 0.7:
			f = fp * (1.0 + 0.012 * sin(TAU * 5.0 * i / sr))
		else:
			var u: float = (t - 0.7) / 0.3
			f = fp + (fe - fp) * u * u
		ph += TAU * f / sr
		var e: float = minf(1.0, i * ia)
		if n - i < rel:
			e *= float(n - i) / rel
		sd = (sd * 1103515245 + 12345) & 0x7FFFFFFF
		y += (float(sd) / 1073741824.0 - 1.0 - y) * 0.3
		b[j] += (sin(ph) + 0.45 * sin(ph * 2.0) + 0.18 * sin(ph * 3.0) + y * 0.25) * amp * e
		j += 1
	s["ph"] = ph
	s["y"] = y
	s["sd"] = sd


func _flute(b: PackedFloat32Array, s: Dictionary, c0: int, c1: int, i0: int, n: int, f: float, amp: float, breath: float, h: float, sd0: int) -> void:
	var sr: float = _sr
	var ph: float = s.get("ph", 0.0)
	var y: float = s.get("y", 0.0)
	var hl: float = s.get("hl", 0.0)
	var sd: int = s.get("sd", sd0)
	var ia: float = 1.0 / (0.09 * sr)
	var rel: int = mini(n / 2, int(0.25 * sr))
	var scp: int = int(0.12 * sr)
	var vd: int = int(0.3 * sr)
	var vw: float = TAU * 5.2 / sr
	var w: float = TAU * f / sr
	var h2: float = h * 0.25
	var h3: float = h * 0.09
	var j: int = i0 + c0
	for i: int in range(c0, c1):
		var ff: float = w
		if i < scp:
			ff *= 0.944 + 0.056 * float(i) / scp
		var vb: float = 0.0
		if i > vd:
			vb = sin(vw * i) * minf(1.0, float(i - vd) / (0.4 * sr))
		ph += ff * (1.0 + 0.007 * vb)
		var e: float = minf(1.0, i * ia) * (1.0 + 0.08 * vb)
		if n - i < rel:
			e *= float(n - i) / rel
		sd = (sd * 1103515245 + 12345) & 0x7FFFFFFF
		y += (float(sd) / 1073741824.0 - 1.0 - y) * 0.45
		hl += (y - hl) * 0.12
		b[j] += (sin(ph) + h2 * sin(ph * 2.0) + h3 * sin(ph * 3.0) + (y - hl) * breath) * amp * e
		j += 1
	s["ph"] = ph
	s["y"] = y
	s["hl"] = hl
	s["sd"] = sd


func _pad(b: PackedFloat32Array, _s: Dictionary, c0: int, c1: int, i0: int, _n: int, f: float, amp: float, per: float, depth: float, ph0: float) -> void:
	var sr: float = _sr
	var w: float = TAU * f / sr
	var lw: float = TAU / (per * sr)
	var g: float = amp
	var j: int = i0 + c0
	for i: int in range(c0, c1):
		if (i & 63) == 0 or i == c0:
			g = amp * (1.0 - depth * (0.5 + 0.5 * cos(lw * i + ph0)))
		b[j] += sin(w * i) * g
		j += 1


func _swell(b: PackedFloat32Array, s: Dictionary, c0: int, c1: int, i0: int, _n: int, amp: float, lp: float, hp: float, per: float, ph0: float, sd0: int) -> void:
	var sr: float = _sr
	var a: float = 1.0 - exp(-TAU * lp / sr)
	var ah: float = 1.0 - exp(-TAU * hp / sr)
	var lw: float = TAU / (per * sr)
	var y: float = s.get("y", 0.0)
	var hl: float = s.get("hl", 0.0)
	var sd: int = s.get("sd", sd0)
	var g: float = 0.0
	var j: int = i0 + c0
	for i: int in range(c0, c1):
		if (i & 63) == 0 or i == c0:
			var c: float = 0.5 - 0.5 * cos(lw * i + ph0)
			g = amp * (0.15 + 0.85 * c * c * c)
		sd = (sd * 1103515245 + 12345) & 0x7FFFFFFF
		y += (float(sd) / 1073741824.0 - 1.0 - y) * a
		hl += (y - hl) * ah
		b[j] += (y - hl) * g
		j += 1
	s["y"] = y
	s["hl"] = hl
	s["sd"] = sd


# ---------------- Klang-Rezepte ----------------

## Glocke: Teiltöne [Verhältnis, Lautstärke, Abklingzeit] auf Grundton f, dazu ein kurzer Anschlag.
func _bell(r: Dictionary, t0: float, dur: float, f: float, amp: float, parts: Array) -> void:
	for p: Array in parts:
		_T(r, t0, dur, f * float(p[0]), f * float(p[0]), amp * float(p[1]), 0.002, float(p[2]))
	_N(r, t0, 0.05, amp * 0.25, 0.0005, 0.012, 6000.0, 2000.0, 400.0)


const BELL_P: Array = [[0.5, 0.55, 3.2], [1.0, 1.0, 2.6], [1.19, 0.45, 1.9], [1.5, 0.3, 1.6], [2.0, 0.38, 1.3], [2.52, 0.22, 0.9], [3.01, 0.16, 0.7], [4.17, 0.1, 0.45], [1.004, 0.5, 2.4]]
const CHIME_P: Array = [[1.0, 1.0, 0.8], [2.76, 0.35, 0.3], [5.4, 0.15, 0.12], [1.003, 0.4, 0.9]]
const GONG_P: Array = [[1.0, 1.0, 6.0, 0.01], [1.52, 0.7, 5.0, 0.15], [2.03, 0.6, 4.5, 0.25], [2.48, 0.5, 3.8, 0.4], [2.97, 0.42, 3.2, 0.5],
	[3.61, 0.35, 2.6, 0.6], [4.15, 0.28, 2.2, 0.7], [5.1, 0.2, 1.6, 0.8], [6.33, 0.14, 1.2, 0.8], [1.008, 0.6, 6.5, 0.02]]
## D-Dur-Pentatonik (gong-Modus) ab D3, Halbtöne relativ zu D4
const PENTA: PackedInt32Array = [-12, -10, -8, -5, -3, 0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]
## A-Moll-Pentatonik (yu-Modus) ab A2, Halbtöne relativ zu A4
const PENTA_YU: PackedInt32Array = [-24, -21, -19, -17, -14, -12, -9, -7, -5, -2, 0, 3]
const D4: float = 293.66


func _pf(semi: float) -> float:
	return D4 * pow(2.0, semi / 12.0)


func _build(nm: String) -> Dictionary:
	if nm.begins_with("ph_"):
		return _phrase(nm)
	var r: Dictionary = {}
	match nm:
		"click":
			r = _rec(nm, 0.08)
			_T(r, 0.0, 0.07, 1750.0, 1600.0, 1.0, 0.0008, 0.012)
			_T(r, 0.0, 0.05, 2900.0, 2800.0, 0.35, 0.0008, 0.007)
			_N(r, 0.0, 0.012, 0.3, 0.0003, 0.003, 7000.0, 3000.0, 1200.0)
		"tab":
			r = _rec(nm, 0.4)
			_P(r, 0.0, _pf(7), 0.8, 0.4, 0.5)
			_T(r, 0.0, 0.05, 1500.0, 1400.0, 0.25, 0.0008, 0.01)
		"tick":
			r = _rec(nm, 0.2)
			_T(r, 0.0, 0.18, _pf(28), _pf(28), 0.6, 0.002, 0.035)
			_T(r, 0.0, 0.18, _pf(28) * 2.76, _pf(28) * 2.76, 0.15, 0.001, 0.015)
		"brush":
			r = _rec(nm, 0.2)
			_B(r, 0.0, 0.2, 1.0, 0.04, 0.06, 900.0, 2600.0, 0.9)
		"pop":
			r = _rec(nm, 0.15)
			_T(r, 0.0, 0.14, 320.0, 980.0, 1.0, 0.003, 0.05)
			_T(r, 0.0, 0.1, 640.0, 1960.0, 0.25, 0.003, 0.035)
		"hit0", "hit1", "hit2":
			var k: int = int(nm.substr(3))
			r = _rec(nm, 0.13)
			_N(r, 0.0, 0.11, 1.0, 0.001, 0.022, 3800.0 - k * 600.0, 700.0, 120.0)
			_T(r, 0.0, 0.1, 210.0 + k * 45.0, 110.0, 0.8, 0.001, 0.03)
		"bolt":
			r = _rec(nm, 0.7)
			_N(r, 0.0, 0.3, 1.0, 0.0004, 0.045, 9500.0, 2500.0, 700.0)
			_C(r, 0.0, 0.25, 500.0, 1.0, 1.5)
			_T(r, 0.0, 0.25, 1500.0, 160.0, 0.35, 0.001, 0.07, 0.0, 0.9)
			_T(r, 0.0, 0.6, 95.0, 38.0, 0.8, 0.002, 0.16)
		"thunder":
			r = _rec(nm, 3.6, SR_LO)
			_N(r, 0.0, 0.4, 0.7, 0.003, 0.09, 4000.0, 700.0, 150.0)
			var t: float = 0.05
			for k: int in range(6):
				var d: float = 0.6 + k * 0.25
				_N(r, t, minf(d * 2.2, 3.55 - t), 1.0 - k * 0.1, 0.04 + k * 0.03, d, 600.0 - k * 60.0, 110.0, 22.0)
				t += 0.18 + k * 0.12
		"boom":
			r = _rec(nm, 2.4)
			_N(r, 0.0, 2.2, 1.0, 0.002, 0.3, 6000.0, 140.0, 20.0)
			_T(r, 0.0, 1.1, 115.0, 30.0, 1.1, 0.002, 0.28)
			_C(r, 0.03, 1.0, 120.0, 0.25, 3.0)
			_N(r, 0.1, 2.3, 0.6, 0.25, 0.8, 320.0, 90.0, 20.0)
		"km_fire":
			r = _rec(nm, 1.6)
			_B(r, 0.0, 1.4, 1.0, 0.07, 0.4, 260.0, 1500.0, 0.6)
			_N(r, 0.0, 1.5, 0.8, 0.05, 0.45, 2600.0, 400.0, 60.0)
			_C(r, 0.08, 1.3, 110.0, 0.45, 2.5)
			_T(r, 0.0, 0.6, 125.0, 45.0, 0.8, 0.002, 0.2)
		"km_water":
			r = _rec(nm, 1.5)
			_B(r, 0.0, 1.0, 1.0, 0.01, 0.28, 2600.0, 450.0, 0.7)
			_N(r, 0.0, 0.8, 0.5, 0.01, 0.25, 1200.0, 300.0, 80.0)
			for k: int in range(7):
				var f: float = 380.0 + float((k * 211) % 520)
				_T(r, 0.06 + k * 0.07, 0.07, f, f * 1.9, 0.3, 0.003, 0.03)
			for f: float in [_pf(24), _pf(28), _pf(31)]:
				_T(r, 0.05, 1.3, f, f, 0.18, 0.002, 0.4)
		"km_metal":
			r = _rec(nm, 1.8)
			_B(r, 0.0, 0.35, 0.9, 0.005, 0.12, 2400.0, 7000.0, 0.4)
			_F(r, 0.03, 1.75, 1180.0, 1.414, 3.0, 0.7, 0.002, 0.45, 0.18)
			_T(r, 0.03, 1.75, 2613.0, 2620.0, 0.28, 0.002, 0.35)
			_T(r, 0.03, 1.75, 3771.0, 3771.0, 0.18, 0.002, 0.25)
		"km_lightning":
			r = _rec(nm, 1.3)
			_N(r, 0.0, 0.35, 1.0, 0.0004, 0.05, 9500.0, 2000.0, 500.0)
			_C(r, 0.0, 0.7, 600.0, 0.9, 1.5)
			_T(r, 0.0, 0.9, 230.0, 65.0, 0.4, 0.004, 0.3, 0.04, 1.0)
			_T(r, 0.02, 0.9, 82.0, 34.0, 0.9, 0.003, 0.25)
		"km_wind":
			r = _rec(nm, 1.4)
			_B(r, 0.0, 0.8, 1.0, 0.3, 0.0, 250.0, 2400.0, 0.5)
			_B(r, 0.45, 0.95, 0.9, 0.05, 0.3, 2200.0, 300.0, 0.5)
			_N(r, 0.0, 1.3, 0.3, 0.3, 0.5, 400.0, 200.0, 40.0)
		"km_soul":
			r = _rec(nm, 1.9, SR_LO)
			for f: float in [220.0, 223.5, 330.5, 261.6]:
				_T(r, 0.0, 1.8, f * 1.03, f * 0.97, 0.3, 0.5, 0.55, 0.012)
			_B(r, 0.0, 1.6, 0.45, 0.4, 0.5, 1800.0, 600.0, 0.25, 3.0, 0.4)
			_T(r, 0.0, 1.5, 58.0, 50.0, 0.6, 0.15, 0.5)
		"km_light":
			r = _rec(nm, 1.6)
			var sc: Array = [12, 14, 16, 19, 21, 24, 28]
			for k: int in range(sc.size()):
				var f: float = _pf(sc[k])
				_T(r, k * 0.045, 1.4 - k * 0.04, f, f, 0.32, 0.003, 0.3)
			_C(r, 0.0, 1.0, 160.0, 0.35, 0.8)
			_B(r, 0.0, 1.1, 0.25, 0.15, 0.35, 5000.0, 3500.0, 0.3)
		"km_earth":
			r = _rec(nm, 1.4, SR_LO)
			_T(r, 0.0, 1.1, 95.0, 36.0, 1.0, 0.002, 0.3)
			_N(r, 0.0, 1.3, 0.85, 0.003, 0.25, 1900.0, 120.0, 30.0)
			_C(r, 0.05, 0.9, 80.0, 0.6, 4.0)
		"chime":
			r = _rec(nm, 1.6, SR_MID)
			for k: int in range(3):
				_bell(r, k * 0.11, 1.5 - k * 0.11, _pf([19, 24, 26][k]), 0.5, CHIME_P)
		"ascend":
			r = _rec(nm, 3.4, SR_LO, false, 0.0, 0.88)
			for p: Array in GONG_P.slice(0, 4):
				_T(r, 0.0, 2.5, 110.0 * float(p[0]), 110.0 * float(p[0]) * 1.02, 0.4 * float(p[1]), 0.003 + float(p[3]) * 0.3, float(p[2]) * 0.3)
			var arp: Array = [12, 14, 16, 19, 24]
			for k: int in range(arp.size()):
				_bell(r, 0.25 + k * 0.12, 3.1 - k * 0.12, _pf(arp[k]), 0.32, CHIME_P.slice(0, 3))
			for f: float in [_pf(0), _pf(7), _pf(12)]:
				_T(r, 0.2, 3.2, f, f, 0.18, 0.7, 0.9, 0.006)
			_B(r, 0.0, 1.4, 0.3, 0.9, 0.4, 400.0, 3500.0, 0.4)
		"bell":
			r = _rec(nm, 5.0, SR_LO)
			_bell(r, 0.0, 5.0, 196.0, 0.8, BELL_P)
		"war":
			r = _rec(nm, 2.0, SR_LO)
			var hits: Array = [0.0, 0.42, 0.84, 1.05, 1.26]
			for k: int in range(hits.size()):
				var a: float = 1.0 if (k == 0 or k == 2) else 0.75
				_T(r, hits[k], 0.7, 108.0, 50.0, a, 0.002, 0.18)
				_N(r, hits[k], 0.18, a * 0.55, 0.001, 0.045, 2200.0, 400.0, 60.0)
		"vil":
			r = _rec(nm, 2.0)
			_P(r, 0.0, _pf(0), 0.8, 1.8, 0.4)
			_P(r, 0.2, _pf(7), 0.7, 1.8, 0.4)
			_P(r, 0.4, _pf(12), 0.5, 1.6, 0.35)
		"howl":
			r = _rec(nm, 3.2, SR_LO)
			_H(r, 0.0, 2.4, 340.0, 560.0, 380.0, 0.6)
			_H(r, 0.35, 2.3, 300.0, 500.0, 330.0, 0.45)
			_H(r, 0.8, 2.2, 380.0, 610.0, 420.0, 0.25)
			_N(r, 0.0, 3.2, 0.25, 0.4, 1.5, 220.0, 160.0, 30.0)
		"trib":
			r = _rec(nm, 4.6, SR_LO)
			_N(r, 0.0, 0.3, 0.8, 0.001, 0.06, 5000.0, 1500.0, 300.0)
			for k: int in range(4):
				_N(r, 0.08 + k * 0.4, 4.5 - k * 0.4, 1.0 - k * 0.15, 0.05 + k * 0.05, 0.9 + k * 0.2, 520.0, 110.0, 22.0)
			_bell(r, 0.15, 4.4, 130.8, 0.55, BELL_P)
			_T(r, 0.0, 4.5, 41.2, 40.0, 0.5, 0.4, 2.0)
		"will":
			# anschwellendes Rauschen, dann ein dunkler Cluster-Akkord (kleine Sekunde, Tritonus)
			r = _rec(nm, 6.2, SR_LO, false, 0.0, 0.9)
			_B(r, 0.0, 2.2, 0.55, 2.0, 0.0, 300.0, 4000.0, 0.35)
			for f: float in [55.0, 58.27, 77.78, 110.0, 116.54, 155.56, 233.08]:
				_T(r, 2.12, 4.0, f, f * 0.985, 0.32 if f < 200.0 else 0.15, 0.2, 2.0, 0.004)
			_T(r, 2.12, 1.5, 90.0, 35.0, 0.8, 0.004, 0.35)
			_N(r, 2.1, 4.0, 0.6, 0.05, 1.5, 300.0, 120.0, 20.0)
		"ven":
			r = _rec(nm, 7.0, SR_LO, false, 0.0, 0.92)
			for p: Array in GONG_P:
				var f: float = 82.0 * float(p[0])
				_T(r, 0.0, 6.9, f * 0.985, f * 1.03, float(p[1]), 0.004 + float(p[3]), float(p[2]))
			_N(r, 0.0, 0.5, 0.5, 0.001, 0.12, 1800.0, 400.0, 40.0)
			_T(r, 0.0, 6.9, 36.7, 36.7, 0.5, 1.0, 3.5)
			_T(r, 0.3, 6.6, 55.0, 55.0, 0.3, 1.5, 3.0, 0.003)
		"fire":
			r = _rec(nm, 3.0, SR, true, 0.5, 0.75)
			_N(r, 0.0, 4.5, 0.6, 0.0, 0.0, 600.0, 600.0, 70.0)
			_B(r, 0.0, 4.5, 0.3, 0.0, 0.0, 320.0, 320.0, 0.6, 0.7, 0.6)
			_C(r, 0.0, 4.5, 16.0, 1.0, 3.0)
			_C(r, 0.0, 4.5, 70.0, 0.3, 1.2)
		"rain":
			r = _rec(nm, 3.0, SR, true, 0.5, 0.7)
			_N(r, 0.0, 4.5, 0.55, 0.0, 0.0, 7000.0, 7000.0, 1300.0)
			_N(r, 0.0, 4.5, 0.35, 0.0, 0.0, 900.0, 900.0, 80.0)
			_C(r, 0.0, 4.5, 260.0, 0.35, 1.0)
		"wind":
			r = _rec(nm, 8.0, SR_VLO, true, 1.0, 0.7)
			_B(r, 0.0, 9.0, 1.0, 0.0, 0.0, 380.0, 380.0, 0.35, 0.125, 1.0)
			_B(r, 0.0, 9.0, 0.5, 0.0, 0.0, 900.0, 900.0, 0.25, 0.375, 0.7)
			_N(r, 0.0, 9.0, 0.3, 0.0, 0.0, 250.0, 250.0, 30.0)
		"sea":
			r = _rec(nm, 8.0, SR_VLO, true, 1.0, 0.7)
			_Sw(r, 0.0, 9.0, 1.0, 1400.0, 90.0, 4.0, 0.0)
			_Sw(r, 0.0, 9.0, 0.7, 2500.0, 300.0, 8.0 / 3.0, 2.0)
			_N(r, 0.0, 9.0, 0.4, 0.0, 0.0, 180.0, 180.0, 25.0)
		"air_calm":
			r = _rec(nm, 8.0, SR_VLO, true, 1.0, 0.7)
			_B(r, 0.0, 9.0, 0.6, 0.0, 0.0, 700.0, 700.0, 0.3, 0.125, 0.8)
			_N(r, 0.0, 9.0, 0.3, 0.0, 0.0, 300.0, 300.0, 40.0)
		"air_dark":
			r = _rec(nm, 8.0, SR_VLO, true, 1.0, 0.7)
			_N(r, 0.0, 9.0, 1.0, 0.0, 0.0, 130.0, 130.0, 20.0)
			_B(r, 0.0, 9.0, 0.25, 0.0, 0.0, 450.0, 450.0, 0.2, 0.125, 1.0)
		_:
			r = _rec(nm, 0.05)
	return r


func _pr() -> float:
	_ps = (_ps * 1103515245 + 12345) & 0x7FFFFFFF
	return float(_ps) / 2147483648.0


## Musik-Phrase: Guzheng-Zupfen (Läufe, Tremolo, Oktaven) und Dizi/Xiao, pentatonisch; hell (D-gong) oder dunkel (A-yu).
func _phrase(nm: String) -> Dictionary:
	var dark: bool = nm.contains("dark")
	_ps = absi(hash(nm)) % 2147483647 + 3
	for k: int in range(5):
		_pr()
	var notes: Array = []   # [art, t, f, amp, t60/dur, bright/breath]
	var sc: Array = []
	if dark:
		for s: int in PENTA_YU:
			sc.append(440.0 * pow(2.0, s / 12.0))
	else:
		for s: int in PENTA:
			sc.append(_pf(s))
	var beat: float = (0.72 + _pr() * 0.15) if dark else (0.4 + _pr() * 0.1)
	var t: float = 0.1
	var idx: int = (5 + int(_pr() * 3)) if dark else (5 + int(_pr() * 4))
	var hi: int = 10 if dark else 13
	notes.append(["p", 0.05, sc[0], 0.55, 4.0 if dark else 3.0, 0.2])   # Grundton im Bass
	var cnt: int = (5 + int(_pr() * 4)) if dark else (9 + int(_pr() * 6))
	for j: int in range(cnt):
		var roll: float = _pr()
		if not dark and roll < 0.12 and j < cnt - 2:
			# Glissando (hua zhi): schneller Lauf aufwärts
			var st: int = maxi(0, idx - 4)
			for g: int in range(5):
				notes.append(["p", t + g * 0.045, sc[mini(st + g, sc.size() - 1)], 0.32, 1.2, 0.5])
			idx = mini(st + 4, hi)
			t += 0.35
			continue
		if roll < (0.1 if dark else 0.2):
			# Tremolo (yao zhi) auf einem Ton
			for g: int in range(7):
				notes.append(["p", t + g * 0.075, sc[idx], 0.3 * (1.0 - g * 0.07), 0.5, 0.45])
			t += 0.65
			continue
		var steps: Array = [-2, -1, -1, 1, 1, 2, 0, 3, -3]
		idx = clampi(idx + int(steps[int(_pr() * steps.size())]), 2, hi)
		var t60: float = (2.4 + _pr() * 1.0) if dark else (1.4 + _pr() * 1.1)
		notes.append(["p", t, sc[idx], 0.5 + 0.25 * _pr(), t60, (0.22 + 0.12 * _pr()) if dark else (0.33 + 0.25 * _pr())])
		if _pr() < 0.2 and idx >= 5:
			notes.append(["p", t, sc[idx - 5], 0.28, t60, 0.3])   # Oktave darunter
		var durs: Array = [1.0, 1.0, 1.0, 2.0, 0.5, 0.5, 1.5]
		t += beat * float(durs[int(_pr() * durs.size())])
	# Schluss: hell auf Grundton/Quinte, dunkel offen (kleine Terz/Quarte)
	var fin: int = ([6, 7][int(_pr() * 2)]) if dark else ([5, 8, 10][int(_pr() * 3)])
	notes.append(["p", t, sc[fin], 0.55, 3.2 if dark else 2.8, 0.3])
	var end: float = t + (3.0 if dark else 2.5)
	# Flötenstimme: Dizi (hell) bzw. Xiao (dunkel, tiefer, mehr Atem)
	if _pr() < (0.6 if dark else 0.45):
		var ft: float = 0.6 + _pr() * 1.0
		var fi: int = (5 + int(_pr() * 3)) if dark else (8 + int(_pr() * 4))
		while ft < t - 0.5:
			var fd: float = (2.0 + _pr() * 1.2) if dark else (1.3 + _pr() * 1.3)
			notes.append(["f", ft, sc[fi], 0.2 if dark else 0.17, fd, 0.35 if dark else 0.14])
			ft += fd + 0.15 + _pr() * 0.6
			fi = clampi(fi + [-1, 1, -2, 2, 0][int(_pr() * 5)], 4 if dark else 7, hi)
	var r: Dictionary = _rec(nm, end, SR_MID, false, 0.0, 0.8)
	for nt: Array in notes:
		if nt[0] == "p":
			_P(r, nt[1], nt[2], nt[3], nt[4], nt[5])
		else:
			_Fl(r, nt[1], nt[4], nt[2], nt[3], nt[5], 0.4 if dark else 1.0)
	return r


# ---------------- Entwickler ----------------

## `--sfxdump=<ordner>`: alles sofort erzeugen, als WAV speichern, Zeiten ausgeben, beenden.
func _dump(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var t0: int = Time.get_ticks_msec()
	while not _queue.is_empty() or not _cur.is_empty():
		_run_jobs(1000000)
	print("SFXDUMP total_ms=%d synth_ms=%.0f max_step_ms=%.1f" % [Time.get_ticks_msec() - t0, synth_us / 1000.0, max_step_us / 1000.0])
	var sfx_ms: float = 0.0
	for nm: String in ORDER:
		var st: AudioStreamWAV = streams[nm]
		st.save_to_wav(dir.path_join(nm + ".wav"))
		print("SFX %-13s %5.2fs sr=%d gen_ms=%6.1f raw_peak=%.3f" % [nm, st.get_length(), st.mix_rate, stats[nm]["ms"], stats[nm]["peak"]])
		if not nm.begins_with("ph_") and not nm.begins_with("air_"):
			sfx_ms += float(stats[nm]["ms"])
	print("SFXDUMP effects_ms=%.0f music_ms=%.0f" % [sfx_ms, synth_us / 1000.0 - sfx_ms])
	print("SFXDUMP DONE")
	get_tree().quit()


## `--fresh --audiotest`: wartet auf alle Klänge, löst jedes Ereignis, Signal, Wetter und beide Stimmungen aus, endet mit `AUDIOTEST DONE`.
func _audiotest() -> void:
	var tree: SceneTree = get_tree()
	while not _queue.is_empty() or not _cur.is_empty() or m.loading:
		await tree.process_frame
	m._end_presim()
	var c: Vector2 = m.cam
	var n_played: int = 0
	for k: String in ["bolt", "boom", "km", "snap", "hit", "rank", "trib", "will", "ven", "war", "vil", "tide"]:
		for p: float in [0.0, 4.0, 7.0, 13.0]:
			m.sim.sfx_ev(k, c.x, c.y, p)
		await tree.process_frame
		for pl: AudioStreamPlayer in _pool:
			n_played += 1 if pl.playing else 0
		_cd.clear()
	for k: int in range(FAM.size()):
		m.sim.sfx_ev("km", c.x + 2000.0, c.y, k)   # weit außerhalb: still
	await tree.process_frame
	m.sim.sfx_ev("bolt", c.x, c.y)
	for t: Dictionary in [{"m": "spawn"}, {"m": "paint"}, {"m": "tap"}]:
		tool(t)
	m.hud.tab_pressed.emit(0)
	m.sim.logged.emit("Audio test.", "info", true)
	var u: Unit = Unit.new()
	u.fig = "test"
	u.x = c.x
	u.y = c.y
	_on_died(u)
	var txt: String = display_text()
	for w: String in ["rain", "snow", "sand", "drought", ""]:
		m.sim.weather = {"type": w, "t": 5.0} if w != "" else {}
		_amb_t = 0.0
		for f: int in range(20):
			await tree.process_frame
	m.zoom_to(c.x, c.y, 6.0)
	m.sim.ignite(int(c.y) * GuData.W + int(c.x), 1.0)
	for f: int in range(20):
		await tree.process_frame
	var amb: String = ""
	for nm: String in AMB:
		amb += "%s=%.2f " % [nm, float(_amb_v[nm])]
	_phr_t = 0.0
	for md: String in ["dark", "calm"]:
		_mood = md
		_mood_t = 99.0
		_phr_t = 0.0
		for f: int in range(40):
			await tree.process_frame
	print("AUDIOTEST sounds=%d played=%d amb=[%s] mood=%s/%.2f phrase=%s display=%d chars" % [streams.size(), n_played, amb, _mood, float(_mood_v[_mood]), _phr_last, txt.length()])
	print("AUDIOTEST DONE")
	tree.quit()

