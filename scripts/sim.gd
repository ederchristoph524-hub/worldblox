class_name Sim
extends Node
## Die Simulation: Clans, Dörfer, Gu-Meister, Tiere, Feuer, Wetter, Zeitalter und Gottkräfte.

signal logged(text: String, kind: String, notify: bool)
signal unit_died(u: Unit)

## Kartengröße (aus GuData, in reset_state nachgezogen – Größe ist zur Laufzeit umstellbar)
var W: int = GuData.W
var H: int = GuData.H
var N: int = GuData.N
const DT: float = 0.05
const GC: int = 16
var GW: int = W / GC
var GH: int = H / GC

var world: World
var units: Array[Unit] = []
var villages: Array[Village] = []
var clans: Array[Clan] = []
var buildings: Array[Building] = []   # Einträge können null sein
var projs: Array[Dictionary] = []
var fx: Array[Dictionary] = []
var parts: Array[Dictionary] = []
var sched: Array[Dictionary] = []
var fire: Dictionary = {}              # Kachel-Index -> Stärke
var sim_time: float = 0.0
var last_month: int = 0
var seed_val: int = 1
var next_id: int = 1
var log_entries: Array[Dictionary] = []
var laws: Dictionary = {"war": true, "tide": true, "will": true, "trib": true, "immortal": true, "walls": true, "growth": true, "fire": true,
	"hunger": true, "age": true, "rebel": true, "diplo": true, "expand": true, "animals": true, "grass": true, "trees": true, "disaster": true, "ages": true, "cult": true}
## Weitere Weltgesetze (WorldBox-Parität) für das Gesetze-Fenster: [Schlüssel, Name, Beschreibung].
const LAWS_EXTRA: Array = [["hunger", "Hunger", "Villages without food lose inhabitants."], ["age", "Old Age", "Mortals and animals die of old age."],
	["rebel", "Rebellions", "Villages with low loyalty break away from their clan."], ["diplo", "Diplomacy", "Clans plan and forge alliances."],
	["expand", "Expansion", "Full villages send out settlers – even by boat to islands."], ["animals", "Animal Spawn", "Wild animals, wild Gu, beasts and beast kings appear on their own."],
	["grass", "Grass Spread", "Soil and ash turn green again."], ["trees", "Tree Growth", "Forests spread."],
	["disaster", "Disasters", "From time to time: earthquakes, earth-fire volcanoes, whirlwinds, poison rain, starfall, plagues and shifting dunes."],
	["ages", "Ages", "The world changes its age every %d years. Off: the current age remains." % GuData.AGE_YEARS],
	["cult", "Cultivation", "Gu Masters cultivate and advance on their own. Off: only god powers make them grow."]]
var weather: Dictionary = {}           # {type, t}
var shake: float = 0.0
var terr_dirty: bool = true
var presim: bool = false
var sp_count: Dictionary = {}
var places: Array[Place] = []
var next_pid: int = 1
var wild_igu: int = 0   # Zahl der wilden Unsterblichen Gu (monatlich gezählt)
# Gottkräfte-Parität: laufende Naturgewalten
var lava: Dictionary = {}              # Kachel-Index -> Hitze (fließt, kühlt bei 0 zu Fels ab)
var volcs: Array[Dictionary] = []      # aktive Erdfeuer-Vulkane {x, y, t}
var storms: Array[Dictionary] = []     # Windpfad-Wirbel {x, y, vx, vy, t}
var acids: Array[Dictionary] = []      # Giftregen-Wolken {x, y, vx, vy, t}
var goo: Array[Dictionary] = []        # Verzehrender Gu-Schwarm: aktive Zellen {i, e} (e = Restenergie)
var goo_left: int = 0                  # Kacheln, die der Schwarm noch fressen darf
var mines: PackedInt32Array = PackedInt32Array()   # Erdminen-Gu (Kachel-Indizes)
var seeds: Array[Dictionary] = []      # Biom-Samen {x, y, tt, r, n}
var possessed: Unit = null             # Seelenbesitz
var age_off: int = 0                   # Jahre, die das Zeitalter angehalten war (Gesetz „Zeitalter“ aus) bzw. per Hand verschoben wurde
var ven: Venerables                    # Rang-9-Ehrwürdige: Pfad-Blüte, Herrschaft, Blutlinien, Agenden, Schicksals-Gu (v5)
var cheats: Cheats                     # Cheat-Schalter, Wesens-Merker, Friedhof, Zeitsprung (scripts/cheats.gd)
var _nat_acc: float = 0.0

# Wirkungen Unsterblicher Gu (Unit.igf)
const F_REVIVE: int = 1
const F_REZ: int = 2
const F_FORTUNE: int = 4
const F_FIRE: int = 8
const F_BOLT: int = 16
const F_LUCK: int = 32
const F_HEAL: int = 64
const F_THIEF: int = 128
const F_STEAL: int = 256
const F_STONES: int = 512
const F_REFINE: int = 1024
const F_DREAM: int = 2048
const F_FATE: int = 4096
var _grid: Array = []
var _fire_acc: float = 0.0
var _sand: bool = false
const MOVE_OFFS: PackedFloat32Array = [0.0, 0.6, -0.6, 1.2, -1.2, 1.9, -1.9]


func _init() -> void:
	world = World.new()
	ven = Venerables.new(self)
	cheats = Cheats.new(self)
	_sync_size()


## Kartengröße aus GuData übernehmen (nach GuData.set_size) und das Wesen-Raster neu anlegen.
func _sync_size() -> void:
	W = GuData.W
	H = GuData.H
	N = GuData.N
	GW = ceili(float(W) / GC)
	GH = ceili(float(H) / GC)
	if _grid.size() == GW * GH:
		return
	_grid.resize(GW * GH)
	for k: int in range(GW * GH):
		_grid[k] = []


# ---------------- Hilfen ----------------

func year() -> int:
	return int(sim_time / 12.0) + 1


## Jahr für die Zeitalter-Rechnung (ohne die angehaltenen bzw. verschobenen Jahre).
func age_year() -> int:
	return maxi(1, year() - age_off)


func age_index() -> int:
	return int((age_year() - 1) / GuData.AGE_YEARS) % GuData.AGES.size()


func age_data() -> Dictionary:
	return GuData.AGES[age_index()]


func years_to_next_age() -> int:
	return GuData.AGE_YEARS - ((age_year() - 1) % GuData.AGE_YEARS)


func uage(u: Unit) -> float:
	return (sim_time - u.birth) / 12.0


func pick(a: Array) -> Variant:
	return a[randi() % a.size()]


func log_event(t: String, kind: String = "info", notify: bool = false) -> void:
	log_entries.push_front({"y": year(), "t": t, "k": kind})
	if log_entries.size() > 260:
		log_entries.resize(260)
	if notify and not presim:
		logged.emit(t, kind, true)


func later(t: float, fn: Callable) -> void:
	sched.append({"t": sim_time + t, "fn": fn})


func region_at(x: float, y: float) -> int:
	return world.region_at(x, y)


func rank_title(r: int) -> String:
	return GuData.rank_title(r)


# ---------------- Effekte ----------------

func puff(x: float, y: float, c: Color, n: int) -> void:
	for k: int in range(n):
		parts.append({"x": x, "y": y, "vx": (randf() - 0.5) * 5.0, "vy": -randf() * 4.0, "l": 0.6 + randf() * 0.5, "ml": 1.1, "c": c, "s": 0.6 + randf() * 0.7, "g": 3.0})


func spark(x: float, y: float, c: Color, n: int, spd: float = 6.0) -> void:
	for k: int in range(n):
		var a: float = randf() * TAU
		var v: float = spd * (0.4 + randf())
		parts.append({"x": x, "y": y, "vx": cos(a) * v, "vy": sin(a) * v, "l": 0.4 + randf() * 0.4, "ml": 0.8, "c": c, "s": 0.5 + randf() * 0.5, "g": 0.0})


func float_txt(u: Unit, t: String, c: Color) -> void:
	fx.append({"k": "txt", "x": u.x, "y": u.y - 4.0, "t": t, "c": c, "l": 1.6, "ml": 1.6})


func pillar(x: float, y: float, c: Color, sc: float = 1.0) -> void:
	fx.append({"k": "pillar", "x": x, "y": y, "c": c, "l": 1.8 * sc, "ml": 1.8 * sc, "w": sc})


func ring(x: float, y: float, r: float, c: Color, l: float = 0.6) -> void:
	fx.append({"k": "ring", "x": x, "y": y, "r": r, "c": c, "l": l, "ml": l})


func flash(l: float) -> void:
	fx.append({"k": "flash", "l": l, "ml": l})


func bolt(x: float, y: float, dmg: float, ign: bool, src: Unit = null) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var px: float = x + (randf() - 0.5) * 8.0
	var py: float = y - 70.0
	for k: int in range(11):
		var t: float = k / 10.0
		var jit: float = (randf() - 0.5) * 5.0 if (k > 0 and k < 10) else 0.0
		pts.append(Vector2(px + (x - px) * t + jit, py + (y - py) * t))
	fx.append({"k": "bolt", "pts": pts, "l": 0.35, "ml": 0.35})
	flash(0.15)
	spark(x, y, Color("#fff7b0"), 10, 10.0)
	var i: int = clampi(int(y), 0, H - 1) * W + clampi(int(x), 0, W - 1)
	if dmg > 0.0:
		for o: Unit in near_units(x, y, 3.0):
			if src == null or (o != src and hostile(src, o)):
				hurt(o, dmg, src)
		if ign:
			ignite(i, 1.0)
	elif ign and randf() < 0.4:
		ignite(i, 0.8)


# ---------------- Raster ----------------

func rebuild_grid() -> void:
	for c: Array in _grid:
		c.clear()
	for u: Unit in units:
		if u.hp <= 0.0:
			continue
		var gx: int = clampi(int(u.x / GC), 0, GW - 1)
		var gy: int = clampi(int(u.y / GC), 0, GH - 1)
		_grid[gy * GW + gx].append(u)


func near_units(x: float, y: float, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	var x0: int = clampi(int((x - r) / GC), 0, GW - 1)
	var x1: int = clampi(int((x + r) / GC), 0, GW - 1)
	var y0: int = clampi(int((y - r) / GC), 0, GH - 1)
	var y1: int = clampi(int((y + r) / GC), 0, GH - 1)
	var r2: float = r * r
	for gy: int in range(y0, y1 + 1):
		for gx: int in range(x0, x1 + 1):
			for o: Unit in _grid[gy * GW + gx]:
				if o.hp <= 0.0:
					continue
				var dx: float = o.x - x
				var dy: float = o.y - y
				if dx * dx + dy * dy <= r2:
					out.append(o)
	return out


## Nächstes Wesen im Umkreis r, das pred erfüllt (läuft direkt über das Raster, ohne Zwischenliste).
func nearest(u: Unit, r: float, pred: Callable) -> Unit:
	var best: Unit = null
	var bd: float = r * r
	var x0: int = clampi(int((u.x - r) / GC), 0, GW - 1)
	var x1: int = clampi(int((u.x + r) / GC), 0, GW - 1)
	var y0: int = clampi(int((u.y - r) / GC), 0, GH - 1)
	var y1: int = clampi(int((u.y + r) / GC), 0, GH - 1)
	for gy: int in range(y0, y1 + 1):
		for gx: int in range(x0, x1 + 1):
			for o: Unit in _grid[gy * GW + gx]:
				if o == u or o.hp <= 0.0:
					continue
				var dx: float = o.x - u.x
				var dy: float = o.y - u.y
				var d2: float = dx * dx + dy * dy
				if d2 <= bd and pred.call(o):
					bd = d2
					best = o
	return best


# ---------------- Wesen ----------------

func rand_sur(r: int) -> String:
	if r == 4:
		return GuData.SURN[randi() % 4].pick_random()[0]
	return GuData.SURN[r].pick_random()[0]


func given_name() -> String:
	var g: String = GuData.GIVEN[randi() % GuData.GIVEN.size()]
	if randf() < 0.55:
		g += GuData.GIVEN[randi() % GuData.GIVEN.size()].to_lower()
	return g


func mk_person(x: float, y: float, race: int, p_age: float = 0.0, sur: String = "") -> Unit:
	var u: Unit = Unit.new()
	u.id = next_id
	next_id += 1
	u.k = "p"
	u.race = race
	u.x = clampf(x, 0.5, W - 0.5)
	u.y = clampf(y, 0.5, H - 0.5)
	u.tx = u.x
	u.ty = u.y
	u.birth = sim_time - p_age * 12.0
	u.life = GuData.RACE_LIFE[race] * (0.85 + randf() * 0.3)
	if sur != "":
		u.sur = sur
	elif race >= 4:
		u.sur = GuData.RACE_SUR[race].pick_random()[0]
	else:
		u.sur = rand_sur(region_at(x, y))
	u.given = given_name()
	u.think = randf()
	u.anim = randf() * 10.0
	u.swim = GuData.RACE_SWIM[race]
	set_stats(u, true)
	units.append(u)
	return u


func set_stats(u: Unit, full: bool) -> void:
	var m: float = GuData.RACE_HP[u.race] * u.ig_hp
	var f: float = 1.0 + 0.1 * u.stage
	var bl: float = 1.3 if u.bless > 0 else (0.65 if u.bless < 0 else 1.0)
	var ratio: float = u.hp / u.mhp if u.mhp > 1.0 else 1.0
	u.mhp = GuData.HP[u.rank] * m * f * bl
	u.atk = GuData.ATK[u.rank] * f * GuData.RACE_ATK[u.race] * u.ig_atk * (1.4 if u.ow else 1.0) * bl * (1.3 if u.undead else 1.0)
	u.rng = GuData.RNG[u.rank] * u.ig_rng
	u.aoe = GuData.AOE[u.rank]
	u.hp = u.mhp if full else u.mhp * ratio
	u.speed = GuData.RACE_SP[u.race] * (1.6 if u.rank >= 6 else 1.0 + u.rank * 0.04) * u.ig_sp * (1.1 if u.bless > 0 else (0.85 if u.bless < 0 else 1.0)) * (0.75 if u.undead else 1.0)
	if u.rank >= 9:
		u.speed *= 1.8   # Ehrwürdige durchqueren die Welt in wenigen Jahren
	if u.rank >= 6 or GuData.RACE_FLY[u.race]:
		u.fly = true


## Rechnet die Wirkungen der Unsterblichen Gu eines Wesens in Faktoren und Merker um.
func apply_igu(u: Unit) -> void:
	u.ig_atk = 1.0
	u.ig_hp = 1.0
	u.ig_sp = 1.0
	u.ig_cult = 1.0
	u.ig_rng = 1.0
	u.igf = 0
	for id: String in u.igu:
		var e: Dictionary = Lore.igu(id)
		if e.is_empty():
			continue
		match str(e["fx"]):
			"revive":
				u.igf |= F_REVIVE
			"rez":
				u.igf |= F_REZ
			"fortune":
				u.igf |= F_FORTUNE
			"str":
				u.ig_atk *= 1.6
			"str2":
				u.ig_atk *= 2.0
			"hp":
				u.ig_hp *= 1.5
			"move":
				u.ig_sp *= 1.8
			"wis":
				u.ig_cult *= 2.2
			"cult":
				u.ig_cult *= 2.0
			"dream":
				u.ig_cult *= 1.5
				u.igf |= F_DREAM
			"range":
				u.ig_rng *= 1.4
				u.ig_atk *= 1.2
			"fire":
				u.ig_atk *= 1.3
				u.igf |= F_FIRE
			"bolt":
				u.ig_atk *= 1.15
				u.igf |= F_BOLT
			"luck":
				u.igf |= F_LUCK
			"heal":
				u.igf |= F_HEAL
			"thief":
				u.ig_atk *= 1.1
				u.igf |= F_THIEF
			"steal":
				u.igf |= F_STEAL
			"stones":
				u.igf |= F_STONES
			"refine":
				u.ig_cult *= 1.3
				u.igf |= F_REFINE
			"life":
				u.ig_hp *= 1.1
			"fate":
				u.ig_cult *= 1.3
				u.igf |= F_FATE
			"tower":
				u.ig_rng *= 1.5
				u.ig_hp *= 1.4
				u.ig_atk *= 1.2
			"pool":
				u.ig_hp *= 1.3
				u.igf |= F_HEAL | F_REFINE
			"chess":
				u.ig_cult *= 1.6
				u.ig_atk *= 1.2
			"eternal":
				u.ig_hp *= 1.1
			_:
				u.ig_atk *= 1.15
				u.ig_hp *= 1.15


## Gibt einem Wesen ein Unsterbliches Gu (Wirkung sofort).
func give_igu(u: Unit, id: String) -> void:
	var e: Dictionary = Lore.igu(id)
	if e.is_empty() or u.k != "p":
		return
	match str(e["fx"]):
		"fetus":
			if u.rank < 6:
				if u.rank == 0:
					awaken(u, true)
				ascend(u, 6)
				log_event(u.pname() + " fuses with the Sovereign Immortal Fetus Gu and becomes a Gu Immortal.", "gold", true)
				pillar(u.x, u.y, GuData.ESS_COL[6])
			else:
				u.prog = minf(0.99, u.prog + 0.5)
			return
		"life":
			u.life += 400.0
		"eternal":
			u.life = maxf(u.life, uage(u) + 100000.0)
		"destiny":
			if u.rank == 0:
				awaken(u, true)
			var top: int = mini(8, u.rank + 3)
			for r: int in range(u.rank + 1, top + 1):
				ascend(u, r)
			u.luck = 1.0
			u.life = maxf(u.life, uage(u) + GuData.LIFEB[u.rank])
			log_event(u.pname() + " receives the Destiny Gu – their fate is rewritten: " + rank_title(u.rank) + ".", "gold", true)
			pillar(u.x, u.y, GuData.PATH_COL[28], 1.2)
			return
	if u.igu.has(id):
		return
	u.igu.append(id)
	if u.igu.size() > 6:
		u.igu.remove_at(1 if u.igu[0] == "fate_gu" else 0)
	apply_igu(u)
	set_stats(u, false)


func mk_animal(x: float, y: float, s: String) -> Unit:
	var S: Dictionary = GuData.SPEC[s]
	var u: Unit = Unit.new()
	u.id = next_id
	next_id += 1
	u.k = "a"
	u.sp = s
	u.x = clampf(x, 0.5, W - 0.5)
	u.y = clampf(y, 0.5, H - 0.5)
	u.tx = u.x
	u.ty = u.y
	u.birth = sim_time
	u.hp = S["hp"]
	u.mhp = S["hp"]
	u.atk = S["atk"]
	u.rng = S["range"]
	u.aoe = float(S.get("aoe", 0.0))
	u.speed = S["sp"]
	u.fly = S["fly"]
	u.swim = bool(S.get("swim", false))
	u.think = randf()
	u.anim = randf() * 10.0
	u.hungry = randf() * 0.5
	u.rank = int(S.get("tier", 0))
	u.life = 900.0 if u.rank >= 6 else (60.0 + randf() * 20.0 if u.rank >= 3 else 12.0 + randf() * 8.0)
	init_animal(u)
	if u.rank >= 6:
		u.hx = x
		u.hy = y
	units.append(u)
	return u


## Abgeleitete Tierwerte (auch nach dem Laden).
func init_animal(u: Unit) -> void:
	var S: Dictionary = GuData.SPEC[u.sp]
	u.beh = int(S.get("beh", GuData.B_SHY))
	u.aqua = bool(S.get("aqua", false))


## Setzt eine Bestie samt Gefolge (Bestienkönige führen Rudel).
func spawn_beast(x: float, y: float, s: String) -> Unit:
	var u: Unit = mk_animal(x, y, s)
	var S: Dictionary = GuData.SPEC[s]
	if S.has("fol"):
		var fs: String = S["fol"]
		for k: int in range(int(S.get("foln", 4))):
			for t: int in range(6):
				var fx2: float = x + (randf() - 0.5) * 8.0
				var fy2: float = y + (randf() - 0.5) * 8.0
				if passable(u, int(fx2), int(fy2)):
					var f: Unit = mk_animal(fx2, fy2, fs)
					f.ldr = u
					break
	return u


# ---------------- Machtmodell (Ränge wie in Reverend Insanity) ----------------
# Macht-Stufe je Rang (Index = Rang bzw. Bestien-Stufe). Schaden zwischen zwei Wesen wird mit
# might(Angreifer) / might(Ziel) multipliziert: sterbliche Ränge ×3,5 je Rang, der Sprung zu Rang 6
# ×1000 (Unsterblichenessenz gegen Uressenz), Rang 7 ×2,8, Rang 8 ×2,5 und Rang 9 ×500 über Rang 8.
const MIGHT: PackedFloat32Array = [1.0, 3.5, 12.0, 42.0, 150.0, 520.0, 520000.0, 1.46e6, 3.64e6, 1.82e9]
## Faktor je Kleinstufe (Anfang → Mitte → Ober → Spitze) – sterblich bzw. unsterblich (Dao-Male)
const STAGE_MIGHT: PackedFloat32Array = [1.13, 1.15]
const APT_MIGHT: Dictionary = {"X": 1.25, "A": 1.12, "B": 1.05, "C": 1.0, "D": 0.93}
## Gu-Meister fliehen vor Gegnern mit mehr als FLEE_P-facher Kampfkraft (≈ besiegt allein ein Dutzend wie sie)
const FLEE_P: float = 150.0
var arena: bool = false   ## Entwickler-Arena (--ranktest): niemand flieht, Unterwerfung aus


## Ab Rang 6 (bzw. Bestien-Stufe 6) zählt ein Wesen als Unsterblicher: Sterbliche können es praktisch nicht verletzen.
func is_imm(u: Unit) -> bool:
	return u.rank >= 6 and u.beh != GuData.B_IGU and u.beh != GuData.B_GU


## Quasi-Rang-9: Rang 8 Spitzenstufe mit mehreren Unsterblichen Gu (oder Herzog Long).
func quasi9(u: Unit) -> bool:
	return u.k == "p" and u.rank == 8 and u.stage >= 3 and (u.fig == "duke_long" or u.igu.size() >= 3)


## Macht-Stufe eines Wesens: Rang × Kleinstufe × Begabung (× Quasi-Rang-9).
func might(u: Unit) -> float:
	var r: int = clampi(u.rank, 0, 9)
	var m: float = MIGHT[r]
	if u.k == "p" and r > 0:
		m *= pow(STAGE_MIGHT[1 if r >= 6 else 0], u.stage) * float(APT_MIGHT.get(u.apt, 1.0))
		if quasi9(u):
			m *= 5.0
	return m


## Schadensfaktor von s gegen t. Sterbliche ohne Unsterbliche Gu richten gegen Unsterbliche fast nichts aus,
## gegen einen Ehrwürdigen richtet niemand unter Rang 9 etwas aus; Ehrwürdige untereinander nur ein Viertel.
func dmg_mul(s: Unit, t: Unit) -> float:
	var f: float = clampf(might(s) / might(t), 1e-6, 1e5)
	if is_imm(t) and not is_imm(s) and not s.igu.is_empty():
		f *= 10.0   # Unsterbliches Gu in sterblicher Hand
	if t.rank >= 9 and t.k == "p":
		if s.rank < 9:
			f = minf(f, 1e-4 if quasi9(s) else 1e-5)
		elif s.k == "p":
			f *= 0.5   # Ehrwürdige untereinander: zäh und langwierig
	return f


## Kampfkraft (für Rangliste, Flucht, Wahl der Beute): Angriff × Leben × Macht² – ein Verhältnis von
## power(a) / power(b) ≈ n² heißt, a besiegt etwa n Gegner wie b.
func power(u: Unit) -> float:
	var m: float = might(u)
	return (u.atk + 1.0) * (u.mhp + 1.0) * m * m


func passable(u: Unit, tx: int, ty: int) -> bool:
	if not world.in_map(tx, ty):
		return false
	var t: int = world.tile[ty * W + tx]
	if t == GuData.WALL:
		return not laws["walls"] or u.rank >= 6
	if u.aqua:
		return t == GuData.DEEP or t == GuData.SHAL
	if u.fly:
		return true
	if t == GuData.DEEP:
		return u.swim or u.boat
	return true


func sp_mul(u: Unit, t: int) -> float:
	if u.fly:
		return 1.0
	if u.boat and t <= GuData.SHAL:
		return 1.3
	if t == GuData.SHAL:
		return 1.0 if (u.swim or u.race == 9) else 0.55
	if t == GuData.MOUNT:
		return 0.8 if u.race == 2 else 0.5
	if t == GuData.SNOW:
		return 1.0 if u.race == 5 else 0.8
	if t == GuData.HILL:
		return 1.0 if u.race == 2 else 0.8
	return 1.0


func hostile(a: Unit, b: Unit) -> bool:
	if a == b or b.hp <= 0.0:
		return false
	if a.k == "p" and b.k == "p":
		if a.undead or b.undead:
			return a.undead != b.undead
		if a.rogue or b.rogue or a.ow or b.ow:
			return true
		if a.duel_t > sim_time and b.duel_t > sim_time:
			return true
		if a.clan < 0 or b.clan < 0 or a.clan == b.clan:
			return false
		var c: Clan = clans[a.clan]
		return c.alive and c.war.has(b.clan)
	if a.k == "p":
		match b.beh:
			GuData.B_GU, GuData.B_IGU:
				return false
			GuData.B_KING:
				return true
			GuData.B_PRED:
				return b.tide or b.aggro == a or a.job == "hunt" or a.rank > 0
			GuData.B_PREY, GuData.B_BOAR:
				return a.job == "hunt" or b.aggro == a
		return b.tide or b.aggro == a
	if b.k == "p":
		if a.tide or a.beh == GuData.B_KING:
			return true
		if a.beh == GuData.B_PRED:
			return a.hungry > 0.97 or a.aggro == b
		return a.aggro == b
	if b.beh == GuData.B_GU or b.beh == GuData.B_IGU:
		return false
	if a.beh == GuData.B_PRED or (a.beh == GuData.B_KING and a.rank < 6):
		if b.beh == GuData.B_PREY:
			return a.hungry > 0.4 or a.beh == GuData.B_KING
		return a.aggro == b
	if a.beh == GuData.B_KING:
		return b.sp != a.sp and b.ldr != a and a.ldr != b
	return a.aggro == b


# ---------------- Clans, Dörfer, Gebäude ----------------

func village_name(race: int = 0) -> String:
	var pre: Array = GuData.RACE_VPRE[clampi(race, 0, GuData.RACE_VPRE.size() - 1)]
	for k: int in range(20):
		var n: String = (str(pre.pick_random()) if (not pre.is_empty() and randf() < 0.6) else GuData.VPRE[randi() % GuData.VPRE.size()]) + GuData.VSUF[randi() % GuData.VSUF.size()]
		var used: bool = false
		for v: Village in villages:
			if v != null and v.alive and v.name == n:
				used = true
		if not used:
			return n
	return GuData.VPRE[randi() % GuData.VPRE.size()] + GuData.VSUF[randi() % GuData.VSUF.size()]


func new_clan(r: int, sur: String, race: int = 0) -> Clan:
	var c: Clan = Clan.new()
	if race >= 4:
		var found2: Array = []
		for a: Array in GuData.RACE_SUR[race]:
			if a[0] == sur:
				found2 = a
		if found2.is_empty():
			found2 = GuData.RACE_SUR[race].pick_random()
		c.name = str(found2[0]) + "-" + GuData.RACE_CLAN[race]
		c.glyph = found2[1]
		c.kind = "Stamm" if (GuData.RACE_CLAN[race].to_lower().ends_with("stamm") or GuData.RACE_CLAN[race].to_lower().ends_with("tribe")) else "Clan"
		c.sur = found2[0]
	elif r == 4:
		var s: Array = GuData.SURN[4].pick_random()
		c.name = s[0] + " Sect"
		c.glyph = s[1]
		c.kind = "Sekte"
	else:
		var list: Array = GuData.SURN[r if (r >= 0 and r < 4) else 1]
		var found: Array = []
		for a: Array in list:
			if a[0] == sur:
				found = a
		if found.is_empty():
			for rr: int in range(4):
				for a: Array in GuData.SURN[rr]:
					if a[0] == sur:
						found = a
		if found.is_empty():
			found = list.pick_random()
		c.kind = "Stamm" if r == 0 else "Clan"
		c.name = c.kind + " " + found[0]
		c.glyph = found[1]
	for o: Clan in clans:
		if o.alive and o.name == c.name:
			c.name += " (Branch)"
			break
	var used: Array[String] = []
	for o: Clan in clans:
		if o.alive:
			used.append(o.col.to_html(false))
	c.col = GuData.CLANCOL.pick_random()
	for col: Color in GuData.CLANCOL:
		if not used.has(col.to_html(false)):
			c.col = col
			break
	c.id = clans.size()
	c.born = year()
	c.region = r
	clans.append(c)
	return c


## Clan einer Organisation aus Lore.ORGS (fester Name, Siegel, Farbe).
func new_org_clan(o: Dictionary, r: int) -> Clan:
	var c: Clan = Clan.new()
	c.name = str(o["n"]) + cheats.org_suffix(str(o["id"]))
	c.glyph = o["gl"]
	c.kind = o["k"]
	c.col = Color(str(o["col"]))
	c.org = o["id"]
	c.align = int(o.get("al", 0))
	c.sur = str(o.get("sur", ""))
	c.id = clans.size()
	c.born = year()
	c.region = r
	clans.append(c)
	return c


func org_clan(id: String) -> Clan:
	for c: Clan in clans:
		if c.alive and c.org == id:
			return c
	return null


func fig_alive(key: String) -> Unit:
	for u: Unit in units:
		if u.hp > 0.0 and u.fig == key:
			return u
	return null


func can_place(x: int, y: int, w: int, h: int, m: int) -> bool:
	for yy: int in range(y - m, y + h + m):
		for xx: int in range(x - m, x + w + m):
			if not world.in_map(xx, yy):
				return false
			var i: int = yy * W + xx
			if world.bmap[i] >= 0:
				return false
			if xx >= x and xx < x + w and yy >= y and yy < y + h:
				if not GuData.buildable(world.tile[i]):
					return false
				if world.temp_snow[i] == 1 or world.temp_snow[i] == 2:
					return false   # zugefrorenes Meer (Frostodem) taut wieder auf
				var f: int = world.feat[i]
				if f == GuData.F_ROCK or f == GuData.F_ORE or f == GuData.F_SPRING:
					return false
				if fire.has(i):
					return false
	return true


func place_building(v: Village, type: String, x: int, y: int) -> Building:
	var s: Vector2i = GuData.BSIZE[type]
	var b: Building = Building.new()
	b.id = buildings.size()
	b.type = type
	b.x = x
	b.y = y
	b.w = s.x
	b.h = s.y
	b.v = v.id
	b.hp = GuData.BHP[type]
	buildings.append(b)
	v.b.append(b.id)
	for yy: int in range(y, y + b.h):
		for xx: int in range(x, x + b.w):
			var i: int = yy * W + xx
			world.bmap[i] = b.id
			if world.feat[i] != 0:
				world.feat[i] = 0
				world.mark_area(xx, yy)
	for yy: int in range(y + b.h, mini(H, y + b.h + 8)):
		for xx: int in range(x - 2, x + b.w + 2):
			if xx < 0 or xx >= W:
				continue
			var i2: int = yy * W + xx
			if GuData.is_tree(world.feat[i2]) and randf() < 0.6:
				world.feat[i2] = 0
				world.mark_area(xx, yy)
	recount(v)
	puff(x + b.w / 2.0, y + b.h / 2.0, Color("#d8c8a0"), 8)
	terr_dirty = true
	return b


func recount(v: Village) -> void:
	v.houses = 0
	v.farms = 0
	v.forge = false
	v.towers = 0
	var keep: PackedInt32Array = PackedInt32Array()
	for id: int in v.b:
		var b: Building = buildings[id]
		if b == null:
			continue
		keep.append(id)
		match b.type:
			"house":
				v.houses += 1
			"farm":
				v.farms += 1
			"forge":
				v.forge = true
			"tower":
				v.towers += 1
	v.b = keep
	v.cap = 4 + v.houses * 4


func remove_building(b: Building, quiet: bool = false) -> void:
	if buildings[b.id] == null:
		return
	buildings[b.id] = null
	for yy: int in range(b.y, b.y + b.h):
		for xx: int in range(b.x, b.x + b.w):
			var i: int = yy * W + xx
			if world.bmap[i] == b.id:
				world.bmap[i] = -1
	if not quiet:
		puff(b.x + b.w / 2.0, b.y + b.h / 2.0, Color("#6a5a4a"), 12)
	var v: Village = villages[b.v]
	recount(v)
	if b.type == "hall" and v.alive:
		abandon_village(v, "The ancestral hall of " + v.name + " has been destroyed.")
	terr_dirty = true


func abandon_village(v: Village, why: String) -> void:
	v.alive = false
	var c: Clan = clans[v.clan]
	for id: int in v.b.duplicate():
		var b: Building = buildings[id]
		if b != null:
			remove_building(b, true)
	for u: Unit in units:
		if u.k == "p" and u.vil == v.id:
			u.vil = -1
			u.col_clan = v.clan
	if why != "":
		log_event(why + " (" + c.name + ")", "war")
	terr_dirty = true


func village_at(tx: int, ty: int) -> Village:
	if world.in_map(tx, ty):
		var bi: int = world.bmap[ty * W + tx]
		if bi >= 0 and buildings[bi] != null:
			var vv: Village = villages[buildings[bi].v]
			if vv.alive:
				return vv
	var best: Village = null
	var bd: float = 1e9
	for v: Village in villages:
		if not v.alive:
			continue
		var d: float = Vector2(v.cx - tx, v.cy - ty).length()
		if d < 12.0 and d < bd:
			bd = d
			best = v
	return best


func site_ok(tx: int, ty: int, reg: int) -> bool:
	if not can_place(tx - 3, ty - 2, 7, 4, 2):
		return false
	if reg >= 0 and world.region[ty * W + tx] != reg:
		return false
	for v: Village in villages:
		if v.alive and Vector2(v.cx - tx, v.cy - ty).length() < 28.0:
			return false
	return true


func find_site(x: float, y: float, min_d: float, max_d: float, reg: int) -> Vector2:
	for k: int in range(50):
		var a: float = randf() * TAU
		var d: float = min_d + randf() * (max_d - min_d)
		var tx: int = roundi(x + cos(a) * d)
		var ty: int = roundi(y + sin(a) * d)
		if site_ok(tx, ty, reg):
			return Vector2(tx + 0.5, ty + 0.5)
	return Vector2(-1, -1)


func near_feat(x: float, y: float, r: int, f: int) -> bool:
	for dy: int in range(-r, r + 1):
		for dx: int in range(-r, r + 1):
			var xx: int = int(x) + dx
			var yy: int = int(y) + dy
			if world.in_map(xx, yy) and world.feat[yy * W + xx] == f:
				return true
	return false


func found_village(u: Unit, clan_id: int) -> bool:
	var tx: int = int(u.x)
	var ty: int = int(u.y)
	if not site_ok(tx, ty, -1):
		return false
	var c: Clan = null
	if clan_id >= 0 and clan_id < clans.size() and clans[clan_id].alive:
		c = clans[clan_id]
	var is_new: bool = c == null
	if is_new:
		c = new_clan(world.region[ty * W + tx], u.sur, u.race)
		if u.rank > 0:
			c.align = u.align
		elif randf() < 0.2:
			c.align = 1
	var v: Village = Village.new()
	v.id = villages.size()
	v.clan = c.id
	v.x = tx - 3
	v.y = ty - 2
	v.cx = tx + 0.5
	v.cy = ty + 0.5
	v.name = village_name(u.race)
	v.race = u.race
	v.born = year()
	v.spring = near_feat(tx, ty, 12, GuData.F_SPRING)
	v.reg = world.region[ty * W + tx]
	villages.append(v)
	place_building(v, "hall", tx - 3, ty - 2)
	u.vil = v.id
	u.clan = c.id
	u.col_clan = -1
	u.col_to = Vector2(-1, -1)
	u.boat = false
	if c.cap < 0 or c.cap >= villages.size() or not villages[c.cap].alive or villages[c.cap].clan != c.id:
		c.cap = v.id
	if is_new:
		log_event(("The " if c.kind == "Sekte" else "") + c.name + " is founded in " + v.name + " (" + GuData.REGN[v.reg] + ").", "jade", true)
	elif randf() < 0.5:
		log_event(c.name + " settles " + v.name + ".", "jade")
	terr_dirty = true
	return true


func join_village(u: Unit, v: Village) -> void:
	u.vil = v.id
	u.clan = v.clan
	u.col_clan = -1
	u.col_to = Vector2(-1, -1)
	u.job = ""
	u.boat = false


func nearest_village(x: float, y: float, r: float, pred: Callable = Callable()) -> Village:
	var best: Village = null
	var bd: float = 1e9
	for v: Village in villages:
		if not v.alive:
			continue
		var d: float = Vector2(v.cx - x, v.cy - y).length()
		if d < r and d < bd and (not pred.is_valid() or pred.call(v)):
			bd = d
			best = v
	return best


func try_build(v: Village, type: String) -> bool:
	var s: Vector2i = GuData.BSIZE[type]
	var r0: float = 6.0 + mini(10, v.houses) * 1.4
	for k: int in range(40):
		var a: float = randf() * TAU
		var d: float = 5.0 + randf() * r0
		var x: int = roundi(v.cx + cos(a) * d - s.x / 2.0)
		var y: int = roundi(v.cy + sin(a) * d * 0.85 - s.y / 2.0)
		if can_place(x, y, s.x, s.y, 1) and world.region[y * W + x] == v.reg:
			place_building(v, type, x, y)
			return true
	return false


func pick_sur(v: Village) -> String:
	var c: Clan = clans[v.clan]
	if c.sur != "":
		return c.sur
	if v.race >= 4:
		return GuData.RACE_SUR[v.race].pick_random()[0]
	if c.kind != "Sekte" and c.org == "":
		return c.name.replace("Clan ", "").replace("Stamm ", "").replace(" (Branch)", "")
	return rand_sur(v.reg)


# ---------------- Kultivierung ----------------

const APTM: Dictionary = {"X": 4.0, "A": 2.0, "B": 1.4, "C": 1.0, "D": 0.6}


func awaken(u: Unit, force: bool = false) -> void:
	var q: float = randf()
	u.apt = "X" if q < 0.01 else ("A" if q < 0.07 else ("B" if q < 0.25 else ("C" if q < 0.6 else "D")))
	if force and u.apt == "D" and randf() < 0.5:
		u.apt = "C"
	if u.apt == "X":
		u.phys_x = true
	var r: int = villages[u.vil].reg if u.vil >= 0 else region_at(u.x, u.y)
	var rp: Array = GuData.RACE_PATHS[u.race]
	u.path = int(rp.pick_random()) if (not rp.is_empty() and randf() < 0.5) else int(GuData.REGPATH[r].pick_random())
	u.path = ven.pick_path(u.path, u.x, u.y)   # Pfad-Blüte der Ehrwürdigen
	u.align = 1 if randf() < 0.3 else 0
	if u.clan >= 0 and clans[u.clan].align == 1 and randf() < 0.6:
		u.align = 1
	u.rank = 1
	u.stage = 0
	u.prog = 0.0
	u.awk = true
	u.gus = PackedStringArray([Lore.start_gu(u.path)])
	u.life += GuData.LIFEB[1]
	u.job = ""
	set_stats(u, true)
	if u.phys_x:
		log_event(u.pname() + " awakens with one of the Ten Extreme Physiques – without an immortal's help, they will die at 20.", "violet", true)


func gain_gu(u: Unit) -> String:
	var pool: PackedStringArray = Lore.mgu(u.path) if u.path >= 0 else GuData.GU_LOW
	if randf() < 0.3:
		pool = GuData.GU_MID if u.rank >= 3 else GuData.GU_LOW
	for k: int in range(5):
		var g: String = pool[randi() % pool.size()]
		if not u.gus.has(g):
			u.gus.append(g)
			if u.gus.size() > 9:
				u.gus.remove_at(1)
			return g
	return ""


func cultivate(u: Unit) -> void:
	if (u.rank >= 9 and u.stage >= 3) or not laws["cult"]:
		return
	var v: Village = villages[u.vil] if u.vil >= 0 else null
	var am: float = APTM.get(u.apt, 1.0)
	var yps: float = pow(u.rank, 1.15) / am if u.rank <= 5 else 6.0 * pow(u.rank - 5, 1.5) / am
	var rate: float = 1.0 / (yps * 12.0) * float(age_data()["cult"])
	if u.rank <= 5:
		var need: float = 0.04 * u.rank
		if v != null and v.stones >= need:
			v.stones -= need
		elif not u.rogue:
			rate *= 0.35
	if u.luck > 0.0:
		rate *= 2.2
	rate *= u.ig_cult
	if u.bless != 0:
		rate *= 1.4 if u.bless > 0 else 0.5
	if u.pb_t > sim_time:
		rate *= u.pb
	if u.ow:
		rate *= 2.5
	rate *= ven.cult_mul(u) * cheats.cult
	u.prog += rate * (0.7 + randf() * 0.6)
	if u.prog >= 1.0:
		u.prog = 0.0
		stage_up(u)


func stage_up(u: Unit) -> void:
	if u.rank >= 9 and u.stage >= 3:
		return
	if u.stage < 3:
		u.stage += 1
		if randf() < (0.8 if (u.igf & F_REFINE) else 0.35):
			gain_gu(u)
		set_stats(u, false)
		float_txt(u, GuData.STAGE[u.stage], GuData.ESS_COL[u.rank])
		return
	rank_up(u)


func rank_up(u: Unit) -> void:
	var r: int = u.rank
	var nm: String = u.pname()
	if r == 5:
		if not laws["immortal"]:
			u.prog = 0.6
			return
		var ch: float = 0.38 + (0.45 if u.luck > 0.0 else 0.0) + (0.1 if u.apt == "A" else 0.0) + (0.2 if u.phys_x else 0.0)
		u.luck = 0.0
		if randf() < ch:
			ascend(u, 6)
			log_event(nm + " breaks through to Gu Immortal (rank 6) – the immortal gate opens.", "gold", true)
			pillar(u.x, u.y, GuData.ESS_COL[6])
			bolt(u.x, u.y, 0.0, false)
		else:
			log_event(nm + " fails the ascension to Gu Immortal and dies.", "red", true)
			bolt(u.x, u.y, 0.0, false)
			u.dreason = "failed ascension"
			u.hp = 0.0
		return
	if r == 8:
		for o: Unit in units:
			if o.k == "p" and o.rank == 9 and o.hp > 0.0:
				u.prog = 0.5
				return
		if randf() < (0.18 + (0.4 if u.luck > 0.0 else 0.0)) * ven.ascend_mul():
			ascend(u, 9)
			u.title = ("Demon Venerable" if u.align == 1 else "Immortal Venerable") + " of the " + GuData.PATH_NAME[u.path] + " Path"
			log_event(nm + " becomes the rank 9 " + u.title + "! The world trembles.", "gold", true)
			pillar(u.x, u.y, GuData.ESS_COL[9])
			shake = 1.0
			ven.register(u, {})
		else:
			u.prog = 0.3
		u.luck = 0.0
		return
	ascend(u, r + 1)
	if r + 1 >= 4 and r + 1 <= 5:
		log_event(nm + " reaches " + rank_title(r + 1) + ".", "info")
	if r + 1 >= 7:
		log_event(nm + " reaches " + rank_title(r + 1) + ".", "violet", true)


func ascend(u: Unit, nr: int) -> void:
	u.rank = nr
	u.stage = 0
	u.prog = 0.0
	u.life += GuData.LIFEB[nr] - GuData.LIFEB[nr - 1]
	if nr >= 6:
		u.next_trib = uage(u) + 10.0 + randf() * 12.0
	gain_gu(u)
	set_stats(u, true)
	float_txt(u, "Rank %d" % nr, GuData.ESS_COL[nr])
	if nr < 6:
		pillar(u.x, u.y, GuData.ESS_COL[nr], 0.6)


func tribulation(u: Unit) -> void:
	var nm: String = u.pname()
	u.next_trib = uage(u) + 12.0 + randf() * 16.0
	if u.notrib:
		return
	if u.prot > sim_time:
		float_txt(u, "Heavenly Protection", Color("#bfe8ff"))
		ring(u.x, u.y - 2.0, 4.0, Color("#bfe8ff"), 0.8)
		u.prog = minf(0.99, u.prog + 0.1)
		return
	for k: int in range(6):
		later(k * 0.25, func() -> void:
			if u.hp > 0.0:
				bolt(u.x + (randf() - 0.5) * 6.0, u.y + (randf() - 0.5) * 6.0, 0.0, true))
	later(1.6, func() -> void:
		if u.hp <= 0.0:
			return
		var ch: float = 0.06 + 0.04 * (u.rank - 6) - (0.05 if u.luck > 0.0 else 0.0)
		bolt(u.x, u.y, 0.0, true)
		var dies: bool = randf() < ch
		if dies and use_fortune(u):
			dies = false
			log_event(nm + " survives the tribulation thanks to the Heaven-Defying Luck Gu.", "gold", true)
		if dies:
			u.dreason = "heavenly tribulation"
			u.hp = 0.0
			log_event(nm + " dies in a heavenly tribulation.", "red", true)
		else:
			u.prog = minf(0.99, u.prog + 0.3)
			if u.rank >= 7:
				log_event(nm + " survives an earthly calamity and heavenly tribulation.", "violet"))


func go_rogue(u: Unit) -> void:
	u.rogue = true
	u.vil = -1
	u.clan = -1
	u.job = ""
	log_event(u.pname() + " (" + rank_title(u.rank) + ") turns to the demonic path and leaves the clan.", "war", u.rank >= 4)


# ---------------- Krieg ----------------

func declare_war(a: Clan, b: Clan, quiet: bool = false) -> void:
	if a == null or b == null or a == b or not a.alive or not b.alive or a.war.has(b.id):
		return
	a.ally.erase(b.id)
	b.ally.erase(a.id)
	a.war[b.id] = sim_time   # Wert = Kriegsbeginn (nach dem Laden true)
	b.war[a.id] = sim_time
	a.war_start = sim_time
	b.war_start = sim_time
	for u: Unit in units:
		if u.k == "p" and (u.clan == a.id or u.clan == b.id) and u.rank == 0 and uage(u) >= 16.0 and uage(u) < 55.0:
			u.militia = randf() < 0.45
	log_event(a.name + " declares a feud on " + b.name + "!", "war", not quiet)


func make_peace(a: Clan, b: Clan, quiet: bool = false) -> void:
	if a == null or b == null:
		return
	a.war.erase(b.id)
	b.war.erase(a.id)
	a.calm = sim_time + 72.0
	b.calm = sim_time + 72.0
	if not quiet:
		log_event(a.name + " and " + b.name + " make peace.", "jade", true)
	for u: Unit in units:
		if u.k == "p" and (u.clan == a.id or u.clan == b.id) and clans[u.clan].war.is_empty():
			u.militia = false


func make_ally(a: Clan, b: Clan) -> void:
	if a == null or b == null or a == b:
		return
	make_peace(a, b, true)
	a.ally[b.id] = true
	b.ally[a.id] = true
	log_event(a.name + " and " + b.name + " forge an alliance.", "jade", true)
	for e: int in a.war.keys():
		declare_war(b, clans[e], true)
	for e: int in b.war.keys():
		declare_war(a, clans[e], true)


func kill_clan(c: Clan, why: String) -> void:
	if not c.alive:
		return
	c.alive = false
	for o: Clan in clans:
		o.war.erase(c.id)
		o.ally.erase(c.id)
	for u: Unit in units:
		if u.k == "p" and u.clan == c.id and u.vil < 0:
			u.clan = -1
	log_event(c.name + " " + why, "red", true)


func capture(v: Village, nc: Clan) -> void:
	var oc: Clan = clans[v.clan]
	v.clan = nc.id
	v.capt = sim_time
	v.loy = 35.0
	if oc.cap == v.id:
		oc.cap = -1
	for u: Unit in units:
		if u.k == "p" and u.vil == v.id:
			u.clan = nc.id
			u.militia = false
	log_event(nc.name + " conquers " + v.name + " from " + oc.name + ".", "war", true)
	terr_dirty = true


# ---------------- Feuer ----------------

func ignite(i: int, v: float) -> void:
	if presim:
		return  # In der Vorgeschichte brennt nichts ab (sonst verascht der Zentralkontinent durch Drangsal-Blitze).
	var t: int = world.tile[i]
	if t == GuData.DEEP or t == GuData.SHAL or t == GuData.WALL or t == GuData.SNOW or t == GuData.LAVA:
		return
	if fire.size() > 6000:
		return
	fire[i] = maxf(fire.get(i, 0.0), v)


func fire_step() -> void:
	var wt: String = weather.get("type", "")
	var rain: bool = wt == "rain"
	var dry: bool = wt == "drought"
	var add: Array[int] = []
	for i: int in fire.keys():
		var v: float = fire[i] - (0.5 if rain else 0.09)
		var t: int = world.tile[i]
		var f: int = world.feat[i]
		if GuData.is_tree(f):
			v += 0.04
		if not rain:
			var x: int = i % W
			var y: int = i / W
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var xx: int = x + dx
					var yy: int = y + dy
					if not world.in_map(xx, yy):
						continue
					var j: int = yy * W + xx
					if fire.has(j):
						continue
					var tj: int = world.tile[j]
					var fl: float = 0.3 if GuData.is_tree(world.feat[j]) else (0.045 if tj == GuData.GRASS else (0.06 if tj == GuData.STEP else 0.0))
					if world.bmap[j] >= 0:
						fl = 0.2
					if not laws["fire"]:
						fl *= 0.15
					if dry:
						fl *= 2.0
					if randf() < fl:
						add.append(j)
		var bi: int = world.bmap[i]
		if bi >= 0 and buildings[bi] != null:
			buildings[bi].hp -= 3.0
			if buildings[bi].hp <= 0.0:
				remove_building(buildings[bi])
		if v <= 0.0:
			fire.erase(i)
			if f != 0 and (GuData.is_tree(f) or f == GuData.F_SHRUB or f == GuData.F_TUFT or f == GuData.F_FLOWER):
				world.feat[i] = 0
			if t == GuData.GRASS or t == GuData.STEP or t == GuData.SOIL:
				world.tile[i] = GuData.ASH
			world.mark_area(i % W, i / W)
		else:
			fire[i] = v
	for j: int in add:
		ignite(j, 1.0)


# ---------------- Schaden ----------------

func hurt(t: Unit, dmg: float, src: Unit) -> void:
	if t.hp <= 0.0 or (t.ch != 0 and Cheats.blocks(t, dmg)):
		return
	if src != null and src != t:
		dmg *= dmg_mul(src, t)
	t.hp -= dmg
	t.flash = 0.12
	if t.hp > 0.0 and (t.igf & F_HEAL) != 0 and t.hp < t.mhp * 0.3 and sim_time >= t.heal_cd:
		t.hp = t.mhp
		t.heal_cd = sim_time + 12.0
		float_txt(t, "Fully healed", GuData.PATH_COL[10])
		spark(t.x, t.y - 2.0, GuData.PATH_COL[10], 10, 5.0)
	if src != null and src != t:
		t.aggro = src
		if t.k == "p" and t.st == "work":
			t.st = "idle"
	if t.hp <= 0.0:
		t.hp = 0.0
		if src != null:
			src.kills += 1
			on_kill(src, t)


func on_kill(s: Unit, t: Unit) -> void:
	if s.k == "p":
		if s.rank >= 1:
			# Nur würdige Gegner bringen Fortschritt – wer Ameisen zertritt, wächst nicht
			s.prog += 0.03 * (1 + t.rank) * (3.0 if (s.rogue or s.align == 1) else 1.0) * minf(1.0, might(t) / might(s))
			if s.prog >= 1.0:
				s.prog = 0.0
				stage_up(s)
		if t.k == "a" and (t.beh == GuData.B_PREY or t.beh == GuData.B_BOAR) and s.vil >= 0:
			villages[s.vil].food += 7.0 if t.beh == GuData.B_BOAR else 5.0
		if t.k == "a" and s.rank > 0:
			var bg: String = str(GuData.SPEC[t.sp].get("gu", ""))
			if bg != "" and not s.gus.has(bg) and randf() < 0.6:
				s.gus.append(bg)
				float_txt(s, "+" + bg, Color("#cfe8ff"))
		if t.k == "p" and s.clan >= 0:
			clans[s.clan].kills += 1
		if t.k == "p":
			loot(s, t)
	elif s.beh == GuData.B_PRED or s.beh == GuData.B_KING:
		s.hungry = 0.0
	if t.k == "p" and t.dreason == "":
		t.dreason = "killed by " + s.pname() if s.k == "p" else "mauled by " + s.pname()


## Beute: Unsterbliche, Dämonische und Diebe nehmen dem Besiegten Unsterbliche Gu, Gu und Lebenszeit ab.
func loot(s: Unit, t: Unit) -> void:
	if (s.igf & F_STEAL) != 0:
		s.life += 10.0
		float_txt(s, "+10 years", GuData.PATH_COL[41])
	if (s.igf & F_THIEF) != 0 and t.gus.size() > 0:
		var g: String = t.gus[randi() % t.gus.size()]
		if not s.gus.has(g):
			s.gus.append(g)
			if s.gus.size() > 9:
				s.gus.remove_at(1)
	if t.igu.is_empty() or s.rank < 6:
		return
	if not (s.rogue or s.align == 1 or (s.igf & F_THIEF) != 0 or randf() < 0.35):
		return
	var cands: PackedStringArray = PackedStringArray()
	for id: String in t.igu:
		var fxs: String = str(Lore.igu(id).get("fx", ""))
		if fxs != "revive" and fxs != "rez":
			cands.append(id)
	if cands.is_empty():
		return
	var id2: String = cands[randi() % cands.size()]
	t.igu.remove_at(t.igu.find(id2))
	give_igu(s, id2)
	log_event(s.pname() + " seizes " + Lore.igu_name(id2) + " from " + t.pname() + ".", "violet", true)


## Verbraucht ein Himmelstrotzendes-Glück-Gu (true, wenn vorhanden).
func use_fortune(u: Unit) -> bool:
	if (u.igf & F_FORTUNE) == 0:
		return false
	for k: int in range(u.igu.size()):
		if str(Lore.igu(u.igu[k]).get("fx", "")) == "fortune":
			u.igu.remove_at(k)
			break
	apply_igu(u)
	pillar(u.x, u.y, GuData.PATH_COL[24], 0.8)
	return true


func boom(x: float, y: float, r: float, dmg: float, o: Dictionary = {}) -> void:
	for ty: int in range(floori(y - r), ceili(y + r) + 1):
		for tx: int in range(floori(x - r), ceili(x + r) + 1):
			if not world.in_map(tx, ty):
				continue
			var d: float = Vector2(tx + 0.5 - x, ty + 0.5 - y).length()
			if d > r:
				continue
			var i: int = ty * W + tx
			var t: int = world.tile[i]
			if o.get("lake", false) and d < r * 0.28:
				world.set_tile(i, GuData.DEEP if d < r * 0.15 else GuData.SHAL)
				_after_set_tile(i)
				continue
			if o.get("ash", false) and d < r * 0.8 and t != GuData.WALL and not GuData.is_water(t):
				if t == GuData.MOUNT and d < r * 0.5:
					world.set_tile(i, GuData.HILL)
				elif t != GuData.MOUNT and t != GuData.HILL:
					world.set_tile(i, GuData.ASH if randf() < 0.85 else GuData.SOIL)
				_after_set_tile(i)
				var f: int = world.feat[i]
				if f != 0 and f != GuData.F_ORE and f != GuData.F_ROCK:
					world.feat[i] = 0
					world.mark_area(tx, ty)
			if randf() < float(o.get("burn", 0.0)):
				ignite(i, 1.0)
			var bi: int = world.bmap[i]
			if bi >= 0 and buildings[bi] != null:
				buildings[bi].hp -= dmg * (1.0 - d / (r + 1.0)) * 0.4 + 5.0
				if buildings[bi].hp <= 0.0:
					remove_building(buildings[bi])
	for u: Unit in near_units(x, y, r + 1.0):
		var d2: float = Vector2(u.x - x, u.y - y).length()
		hurt(u, dmg * (1.0 - 0.6 * d2 / (r + 1.0)), null)
	var c: Color = o.get("c", Color("#ffd27a"))
	ring(x, y, r, c, 0.7)
	ring(x, y, r * 0.6, Color.WHITE, 0.4)
	spark(x, y, c, mini(70, int(12 + r * 4)), 6.0 + r * 1.5)
	for k: int in range(int(r * 2)):
		puff(x + (randf() - 0.5) * r, y + (randf() - 0.5) * r, Color("#5a4a40"), 1)
	if r >= 5.0:
		shake = minf(1.2, shake + r * 0.03)
	flash(0.12 + r * 0.005)


## Nach einer Geländeänderung: Gebäude auf unbebaubarem Grund abreißen, Feuer im Wasser löschen.
func _after_set_tile(i: int) -> void:
	var t: int = world.tile[i]
	if fire.has(i) and (GuData.is_water(t) or t == GuData.WALL):
		fire.erase(i)
	var bi: int = world.bmap[i]
	if bi >= 0 and not GuData.buildable(t) and buildings[bi] != null:
		remove_building(buildings[bi])
	terr_dirty = true


func set_tile(i: int, t: int) -> void:
	world.set_tile(i, t)
	_after_set_tile(i)


# ---------------- Monat und Jahr ----------------

func monthly() -> void:
	for v: Village in villages:
		v.pop = 0
		v.adults = 0
		v.gm = 0
	var n_persons: int = 0
	for u: Unit in units:
		if u.k != "p" or u.hp <= 0.0:
			continue
		n_persons += 1
		if u.vil < 0:
			continue
		var v: Village = villages[u.vil]
		if not v.alive:
			u.vil = -1
			continue
		v.pop += 1
		if uage(u) >= 14.0:
			v.adults += 1
		if u.rank > 0:
			v.gm += 1
	var ad: Dictionary = age_data()
	for v: Village in villages:
		if not v.alive:
			continue
		var c: Clan = clans[v.clan]
		if v.pop == 0:
			if randf() < 0.08:
				abandon_village(v, v.name + " lies abandoned.")
			continue
		v.food += v.farms * 0.55 * float(ad["grow"]) + 0.25 - v.pop * 0.07
		if v.food < 0.0:
			v.food = 0.0
			if laws["hunger"] and randf() < 0.05:
				for u: Unit in units:
					if u.k == "p" and u.vil == v.id and u.rank == 0 and u.hp > 0.0:
						u.dreason = "starvation"
						u.hp = 0.0
						break
		v.food = minf(v.food, 60.0 + v.pop * 3.0)
		if v.spring:
			v.stones += 0.6
		if v.lvl == 0 and v.pop >= 10:
			v.lvl = 1
		if laws["growth"] and v.pop < v.cap and v.food > v.pop * 0.35 and n_persons < GuData.MAXU:
			if randf() < minf(0.5, 0.02 * v.adults + 0.03) * float(ad["grow"]) * GuData.RACE_GROW[v.race]:
				var kid: Unit = mk_person(v.cx + randf() * 2.0 - 1.0, v.cy + 2.5, v.race, 0.0, pick_sur(v))
				join_village(kid, v)
				v.food -= 2.0
		if v.wood >= 10.0 and v.houses < 12 and v.pop >= v.cap - 3:
			if try_build(v, "house"):
				v.wood -= 10.0
		elif v.wood >= 6.0 and v.farms < ceili(v.pop / 7.0):
			if try_build(v, "farm"):
				v.wood -= 6.0
		elif not v.forge and v.gm > 0 and v.wood >= 12.0:
			if try_build(v, "forge"):
				v.wood -= 12.0
		elif not c.war.is_empty() and v.towers < 2 and v.wood >= 12.0 and v.pop > 10:
			if try_build(v, "tower"):
				v.wood -= 12.0
		if laws["expand"] and v.pop >= mini(v.cap, 40) - 1 and v.houses >= (4 if v.reg == 3 else 6) and randf() < (0.05 if v.reg == 3 else 0.035):
			colonize(v)
	for u: Unit in units:
		if u.hp <= 0.0:
			continue
		if u.k == "p":
			person_month(u)
		else:
			animal_month(u)
	if not arena:
		ven.month()
	for c: Clan in clans:
		if not c.alive:
			continue
		var vs: Array[Village] = []
		for v: Village in villages:
			if v.alive and v.clan == c.id:
				vs.append(v)
		if vs.is_empty():
			var any: bool = false
			for u: Unit in units:
				if u.k == "p" and u.hp > 0.0 and u.clan == c.id:
					any = true
					break
			if not any:
				kill_clan(c, "has perished.")
			continue
		c.wt = -1
		# Hauptstadt: bleibt, solange sie dem Clan gehört; sonst das größte Dorf
		if c.cap < 0 or c.cap >= villages.size() or not villages[c.cap].alive or villages[c.cap].clan != c.id:
			var big: Village = vs[0]
			for v: Village in vs:
				if v.pop > big.pop:
					big = v
			if c.cap >= 0 and vs.size() > 1:
				log_event(c.name + " makes " + big.name + " its new capital.", "info")
			c.cap = big.id
		var capv: Village = villages[c.cap]
		c.exh = minf(100.0, c.exh + 1.2 + 0.4 * c.war.size()) if not c.war.is_empty() else maxf(0.0, c.exh - 2.5)
		if not c.war.is_empty():
			var bd: float = 1e9
			for v: Village in villages:
				if not v.alive or not c.war.has(v.clan):
					continue
				var d: float = Vector2(v.cx - capv.cx, v.cy - capv.cy).length()
				if d < bd:
					bd = d
					c.wt = v.id
		if laws["war"] and randf() < 0.006 * float(ad["war"]) and not (c.calm > sim_time):
			var cands: Array[Clan] = []
			for o: Clan in clans:
				if not o.alive or o == c or o.calm > sim_time or c.war.has(o.id) or c.ally.has(o.id) or has_plan(c, "war", o.id):
					continue
				var close: bool = false
				for v: Village in villages:
					if v.alive and v.clan == o.id:
						for w2: Village in vs:
							if v.reg == w2.reg and Vector2(v.cx - w2.cx, v.cy - w2.cy).length() < 110.0:
								close = true
				if close:
					cands.append(o)
			if not cands.is_empty():
				add_plan(c, "war", cands.pick_random(), 3.0 + randf() * 6.0)
		for e: int in c.war.keys():
			var o2: Clan = clans[e]
			if not o2.alive:
				c.war.erase(e)
				continue
			# Die Seite mit dem höheren Spitzenrang beherrscht den Krieg: gegen einen Unsterblichen (und erst recht
			# einen Ehrwürdigen) gibt der Schwächere bald auf, statt sich abschlachten zu lassen.
			var tc: int = top_rank(c)
			var to: int = top_rank(o2)
			if not arena and to >= 6 and to > tc and randf() < (0.3 if to >= 9 else (0.12 if tc < 6 else 0.06)):
				capitulate(c, o2)
				continue
			if (sim_time - c.war_start > 36.0 and randf() < 0.012) or (not laws["war"] and randf() < 0.2) or randf() < 0.0005 * (c.exh + o2.exh):
				if c.exh > 60.0 and randf() < 0.5:
					log_event(c.name + " is weary of war and asks " + o2.name + " for peace.", "jade")
				make_peace(c, o2)
		if laws["diplo"] and randf() < 0.0015:
			var cands2: Array[Clan] = []
			for o: Clan in clans:
				if o.alive and o != c and not c.war.has(o.id) and not c.ally.has(o.id) and not has_plan(c, "ally", o.id):
					cands2.append(o)
			if not cands2.is_empty():
				add_plan(c, "ally", cands2.pick_random(), 2.0 + randf() * 4.0)
		run_plans(c)
	loyalty_month()
	for v: Village in villages:
		if not v.alive:
			continue
		var c: Clan = clans[v.clan]
		if c.war.is_empty():
			continue
		var att: int = 0
		var def: int = 0
		var tally: Dictionary = {}
		for u: Unit in near_units(v.cx, v.cy, 14.0):
			if u.k != "p":
				continue
			var d: float = Vector2(u.x - v.cx, u.y - v.cy).length()
			if u.clan == v.clan:
				def += 1
			elif c.war.has(u.clan) and d < 10.0:
				att += 1
				tally[u.clan] = tally.get(u.clan, 0) + 1
		if att >= 2 and def == 0:
			var best: int = -1
			var bn: int = 0
			for kk: int in tally.keys():
				if tally[kk] > bn:
					bn = tally[kk]
					best = kk
			if best >= 0:
				capture(v, clans[best])
	if int(sim_time) % 12 == 0:
		yearly()
	place_month()
	nature_spawns()
	update_leaders()
	cheats.month()
	terr_dirty = true


func colonize(v: Village) -> void:
	# Im Ostmeer (oder wenn das eigene Land voll ist) segeln Siedler zu einer anderen Insel derselben Region.
	var sea: bool = v.reg == 3 and randf() < 0.6
	var s: Vector2 = Vector2(-1, -1) if sea else find_site(v.cx, v.cy, 32.0, 64.0, v.reg)
	if s.x < 0.0:
		s = find_site(v.cx, v.cy, 40.0, 110.0, v.reg)
		sea = true
	if s.x < 0.0:
		return
	var n: int = 0
	for u: Unit in units:
		if n >= 4:
			break
		if u.k == "p" and u.vil == v.id and u.hp > 0.0 and uage(u) >= 16.0 and uage(u) < 50.0 and u.rank < 6:
			u.vil = -1
			u.col_clan = v.clan
			u.col_to = s + (Vector2(randf() * 3.0 - 1.5, randf() * 3.0 - 1.5) if n > 0 else Vector2.ZERO)
			u.st = "idle"
			u.tgt = null
			u.job = ""
			u.boat = true   # Boote: über tiefes Wasser, aber nie durch Regionswände
			u.fxm = true
			n += 1
	if sea and n > 0 and randf() < 0.5:
		log_event("Settlers from " + v.name + " set sail.", "jade")


func person_month(u: Unit) -> void:
	var a: float = uage(u)
	if u.undead:
		if a > u.life:
			u.dreason = "zerfallen"
			u.hp = 0.0
		return
	if a > u.life and (laws["age"] or u.rank == 0 and a > u.life * 3.0):
		u.dreason = "old age"
		u.hp = 0.0
		return
	if u.phys_x and u.rank < 6 and a > 20.0:
		u.dreason = "Extremkonstitution"
		u.hp = 0.0
		log_event(u.pname() + " dies of the extreme physique.", "red")
		return
	if not u.awk and a >= 14.0:
		u.awk = true
		if randf() < GuData.RACE_AWK[u.race]:
			awaken(u)
	if u.rank > 0:
		cultivate(u)
	if (u.igf & F_LUCK) != 0:
		u.luck = 1.0
	elif u.luck > 0.0:
		u.luck = maxf(0.0, u.luck - 1.0 / 48.0)
	if (u.igf & F_STONES) != 0 and u.vil >= 0:
		villages[u.vil].stones += 2.0
	if u.rank >= 6 and u.rank < 9 and laws["trib"] and a >= u.next_trib:
		tribulation(u)
	if u.rank >= 2 and u.rank < 9 and u.align == 1 and not u.rogue and randf() < 0.0014:
		go_rogue(u)
	if u.rank == 0 and a >= 14.0 and u.vil >= 0 and (u.job == "" or randf() < 0.03):
		assign_job(u)
	u.hp = minf(u.mhp, u.hp + u.mhp * (0.35 if u.race == 10 else 0.1))


func assign_job(u: Unit) -> void:
	var v: Village = villages[u.vil]
	var w: Array = [["wood", 0.4 if v.wood < 25.0 else 0.2], ["farm", 0.3 if v.farms > 0 else 0.0], ["gather", 0.3 if v.food < v.pop else 0.12], ["mine", 0.16], ["hunt", 0.12]]
	var s: float = 0.0
	for e: Array in w:
		s += e[1]
	var q: float = randf() * s
	for e: Array in w:
		q -= e[1]
		if q <= 0.0:
			u.job = e[0]
			return
	u.job = "wood"


func animal_month(u: Unit) -> void:
	var s: String = u.sp
	if laws["age"] and u.beh != GuData.B_GU and u.beh != GuData.B_IGU and u.rank < 6 and uage(u) > u.life:
		u.hp = 0.0
		return
	u.hp = minf(u.mhp, u.hp + u.mhp * 0.15)
	if laws["growth"] and laws["animals"] and u.rank == 0 and u.beh != GuData.B_GU and u.beh != GuData.B_IGU and u.ldr == null and randf() < 0.006 and sp_count.get(s, 0) < int(GuData.SPEC[s]["cap"] * GuData.len_f()) / 2:
		mk_animal(u.x + (randf() - 0.5) * 2.0, u.y + (randf() - 0.5) * 2.0, s)


func random_tile(pred: Callable, tries: int = 80) -> Vector2:
	for k: int in range(tries):
		var i: int = randi() % N
		if pred.call(i):
			return Vector2(i % W + 0.5, i / W + 0.5)
	return Vector2(-1, -1)


func nature_spawns() -> void:
	sp_count = {}
	for u: Unit in units:
		if u.k == "a" and u.hp > 0.0:
			sp_count[u.sp] = sp_count.get(u.sp, 0) + 1
	wild_igu = int(sp_count.get("wildimm", 0))
	if not laws["growth"]:
		return
	var tries: Array = [["deer", [GuData.GRASS, GuData.STEP], [0, 1, 4]], ["boar", [GuData.GRASS], [1, 4]], ["wolf", [GuData.STEP, GuData.SNOW, GuData.GRASS], [0, 1]], ["monkey", [GuData.GRASS], [1, 4, 3]], ["crane", [GuData.GRASS, GuData.SAND], [3, 4]],
		["white_boar", [GuData.GRASS, GuData.HILL], [1]], ["black_boar", [GuData.GRASS, GuData.HILL], [1]], ["lightning_wolf", [GuData.GRASS], [1]], ["thousand_li_earthwolf_spider", [GuData.GRASS, GuData.SOIL], [1]]]
	for e: Array in tries:
		var s: String = e[0]
		if laws["animals"] and sp_count.get(s, 0) < int(GuData.SPEC[s]["cap"]) * 0.12 * GuData.len_f() and randf() < 0.25:
			var ts: Array = e[1]
			var rs: Array = e[2]
			var p: Vector2 = random_tile(func(i: int) -> bool: return world.tile[i] in ts and world.region[i] in rs)
			if p.x >= 0.0:
				mk_animal(p.x, p.y, s)
	if laws["animals"] and sp_count.get("wildgu", 0) < 50.0 * GuData.len_f() and randf() < 0.6:
		var p2: Vector2 = random_tile(func(i: int) -> bool: return (world.tile[i] == GuData.GRASS or world.tile[i] == GuData.HILL or world.tile[i] == GuData.STEP or world.tile[i] == GuData.DES) and world.region[i] != 3)
		if p2.x >= 0.0:
			var pth: int = int(GuData.REGPATH[region_at(p2.x, p2.y)].pick_random())
			for k: int in range(randi_range(1, 3)):
				spawn_wild_gu(p2.x + (randf() - 0.5) * 4.0, p2.y + (randf() - 0.5) * 4.0, pth)


## Wilder sterblicher Gu eines Pfades (Name aus Lore.mgu).
func spawn_wild_gu(x: float, y: float, pth: int) -> Unit:
	var g: Unit = mk_animal(x, y, "wildgu")
	g.path = pth
	g.gname = Lore.mgu(pth)[randi() % Lore.mgu(pth).size()]
	return g


## Wildes Unsterbliches Gu (id leer = zufällig).
func spawn_wild_igu(x: float, y: float, id: String = "") -> Unit:
	if id == "":
		id = Lore.igu_random()
	var g: Unit = mk_animal(x, y, "wildimm")
	wild_igu += 1
	g.gname = id
	g.path = int(Lore.igu(id).get("p", 0))
	return g


func count_sp(s: String) -> int:
	var n: int = 0
	for u: Unit in units:
		if u.hp > 0.0 and u.sp == s:
			n += 1
	return n


func yearly() -> void:
	if not laws["ages"]:
		age_off += 1
	var y: int = age_year()
	if laws["ages"] and (y - 1) % GuData.AGE_YEARS == 0 and y > 1:
		log_event("The " + str(age_data()["n"]) + " begins.", "violet", true)
	if laws["tide"] and randf() < 0.06:
		var vs: Array[Village] = []
		for v: Village in villages:
			if v.alive and v.pop >= 8 and v.reg in [0, 1, 4]:
				vs.append(v)
		if not vs.is_empty():
			beast_tide(vs.pick_random(), Vector2(-1, -1))
	if laws["will"] and randf() < 0.04 * ven.will_mul():
		var top: Array[Unit] = strongest(1)
		if not top.is_empty() and top[0].rank >= 7:
			heavens_will(top[0])
	ven.yearly()
	if laws["growth"] and laws["animals"] and randf() < 0.05:
		wild_beast_king()
	if laws["disaster"] and not presim and randf() < 0.14:
		random_disaster()


## Seltene natürliche Bestienkönige und Ödbestien in ihrer Heimatregion.
func wild_beast_king() -> void:
	var kings: int = 0
	for u: Unit in units:
		if u.k == "a" and u.hp > 0.0 and u.rank >= 3:
			kings += 1
	if kings >= 4:
		return
	var s: String = ["bk100", "bk100", "bk10000", "stone_monkey_king", "crocodile_king", "earth_chief", "peach_wolf", "turtle_jade_wolf", "flying_bear", "iron_crown_eagle", "moon_demon_bat", "star_desolate_hound", "qi_grand_lion", "desolate"].pick_random()
	var S: Dictionary = GuData.SPEC[s]
	var rg: int = int(S.get("reg", [0, 1, 4].pick_random()))
	var p: Vector2 = random_tile(func(i: int) -> bool: return world.region[i] == rg and (world.tile[i] == GuData.GRASS or world.tile[i] == GuData.STEP or world.tile[i] == GuData.HILL or world.tile[i] == GuData.SNOW) and world.bmap[i] < 0, 200)
	if p.x < 0.0 or nearest_village(p.x, p.y, 30.0) != null:
		return
	spawn_beast(p.x, p.y, s)
	log_event("Beast sighted: %s in %s." % [str(S["n"]), GuData.REGN_DAT[rg]], "war", int(S.get("tier", 0)) >= 5)


func strongest(n: int) -> Array[Unit]:
	var arr: Array[Unit] = []
	for u: Unit in units:
		if u.k == "p" and u.hp > 0.0 and u.rank > 0:
			arr.append(u)
	var pw: Dictionary = {}
	for u: Unit in arr:
		pw[u] = power(u) * (1.0 + 0.1 * u.prog)
	arr.sort_custom(func(a: Unit, b: Unit) -> bool: return float(pw[a]) > float(pw[b]))
	return arr.slice(0, n)


func beast_tide(v: Village, at: Vector2) -> void:
	var p: Vector2 = at
	if p.x < 0.0:
		for k: int in range(50):
			var a: float = randf() * TAU
			var d: float = 36.0 + randf() * 16.0
			var x: float = v.cx + cos(a) * d
			var y: float = v.cy + sin(a) * d
			if x < 2 or y < 2 or x >= W - 2 or y >= H - 2:
				continue
			var i: int = int(y) * W + int(x)
			if GuData.is_land(world.tile[i]) and world.tile[i] != GuData.WALL and world.region[i] == v.reg:
				p = Vector2(x, y)
				break
	if p.x < 0.0:
		return
	var n: int = mini(30, 10 + v.pop / 3)
	var ws: String = "lightning_wolf" if (v.reg == 1 and randf() < 0.5) else "wolf"
	for k: int in range(n):
		var w: Unit = mk_animal(p.x + (randf() - 0.5) * 8.0, p.y + (randf() - 0.5) * 8.0, ws)
		w.tide = true
		w.tide_v = v.id
		w.hungry = 1.0
	var kw: Unit = mk_animal(p.x, p.y, "kingwolf")
	kw.tide = true
	kw.tide_v = v.id
	log_event("Wolf tide! A Thunder Crown Wolf leads %d %s against %s (%s)." % [n, "lightning wolves" if ws == "lightning_wolf" else "wolves", v.name, clans[v.clan].name], "war", true)


func heavens_will(u: Unit) -> void:
	var nm: String = u.pname()
	if (u.igf & F_FATE) != 0:
		ring(u.x, u.y - 2.0, 6.0, GuData.PATH_COL[28], 1.0)
		float_txt(u, "Fate Gu", GuData.PATH_COL[28])
		log_event("Heaven's Will spares " + nm + " – the guardian of the Fate Gu.", "violet", true)
		return
	if u.prot > sim_time:
		bolt(u.x + 3.0, u.y - 2.0, 0.0, false)
		ring(u.x, u.y - 2.0, 6.0, Color("#bfe8ff"), 1.0)
		float_txt(u, "Heavenly Protection", Color("#bfe8ff"))
		log_event("Heaven's Will rebounds off the heavenly protection of " + nm + ".", "violet", true)
		return
	log_event("Heaven's Will turns against " + nm + ".", "violet", true)
	for k: int in range(9):
		later(k * 0.18, func() -> void:
			if u.hp > 0.0:
				bolt(u.x + (randf() - 0.5) * 10.0, u.y + (randf() - 0.5) * 10.0, 0.0, true))
	later(1.9, func() -> void:
		if u.hp <= 0.0:
			return
		bolt(u.x, u.y, 0.0, true)
		ring(u.x, u.y, 12.0, Color("#b98cff"), 1.0)
		var ch: float = (0.12 if u.rank >= 9 else (0.3 if u.rank >= 8 else 0.45)) * ven.will_kill_mul()
		var dies: bool = randf() < ch
		if dies and use_fortune(u):
			dies = false
			log_event(nm + " defies Heaven's Will thanks to the Heaven-Defying Luck Gu.", "gold", true)
		if dies:
			u.dreason = "Heaven's Will"
			u.hp = 0.0
			log_event(nm + " is erased by Heaven's Will.", "red", true)
		else:
			u.hp = maxf(1.0, u.hp * 0.25)
			log_event(nm + " defies Heaven's Will.", "gold", true))


func update_leaders() -> void:
	for v: Village in villages:
		v.lead = null
	var old: Dictionary = {}
	for c: Clan in clans:
		if c.lead != null:
			old[c.id] = c.lead
		c.lead = null
	for u: Unit in units:
		if u.k != "p" or u.hp <= 0.0 or u.undead:
			continue
		if u.clan >= 0 and not u.rogue:
			var c2: Clan = clans[u.clan]
			var CL: Unit = c2.lead
			if CL == null or u.rank * 4 + u.stage > CL.rank * 4 + CL.stage or (u.rank == CL.rank and u.stage == CL.stage and uage(u) > uage(CL)):
				c2.lead = u
		if u.vil < 0:
			continue
		var v: Village = villages[u.vil]
		if not v.alive:
			continue
		var L: Unit = v.lead
		if L == null or u.rank * 4 + u.stage > L.rank * 4 + L.stage or (u.rank == L.rank and u.stage == L.stage and uage(u) > uage(L)):
			v.lead = u
	if presim:
		return
	for c3: Clan in clans:
		var prev: Unit = old.get(c3.id, null)
		var nl: Unit = c3.lead
		if c3.alive and nl != null and prev != null and prev != nl and prev.hp <= 0.0 and nl.rank >= 3:
			log_event(nl.pname() + " (" + rank_title(nl.rank) + ") becomes the new clan leader of " + c3.name + ".", "jade", nl.rank >= 6)


# ---------------- Denken ----------------

func go_to(u: Unit, x: float, y: float) -> void:
	u.tx = clampf(x, 0.5, W - 0.5)
	u.ty = clampf(y, 0.5, H - 0.5)


func wander(u: Unit, r: float) -> void:
	var rg: int = region_at(u.x, u.y)
	for k: int in range(6):
		var x: float = u.x + (randf() - 0.5) * 2.0 * r
		var y: float = u.y + (randf() - 0.5) * 2.0 * r
		if x < 0 or y < 0 or x >= W or y >= H:
			continue
		if passable(u, int(x), int(y)) and (u.fly or world.region[int(y) * W + int(x)] == rg):
			go_to(u, x, y)
			return


func wander_near(u: Unit, cx: float, cy: float, r: float) -> void:
	for k: int in range(6):
		var x: float = cx + (randf() - 0.5) * 2.0 * r
		var y: float = cy + (randf() - 0.5) * 2.0 * r
		if x < 0 or y < 0 or x >= W or y >= H:
			continue
		if passable(u, int(x), int(y)):
			go_to(u, x, y)
			return


func flee(u: Unit, e: Unit, v: Village) -> void:
	if v != null and Vector2(v.cx - u.x, v.cy - u.y).length() > 6.0:
		go_to(u, v.cx + randf() * 4.0 - 2.0, v.cy + randf() * 4.0 - 2.0)
	else:
		var d: Vector2 = Vector2(u.x - e.x, u.y - e.y)
		if d.length() < 0.01:
			d = Vector2(1, 0)
		d = d.normalized() * 12.0
		go_to(u, u.x + d.x, u.y + d.y)
	u.st = "idle"


func find_feat(cx: float, cy: float, r: float, pred: Callable) -> int:
	var best: int = -1
	var bd: float = 1e9
	for k: int in range(90):
		var x: int = roundi(cx + (randf() - 0.5) * 2.0 * r)
		var y: int = roundi(cy + (randf() - 0.5) * 2.0 * r)
		if not world.in_map(x, y):
			continue
		var i: int = y * W + x
		if pred.call(world.feat[i]) and world.bmap[i] < 0 and not fire.has(i):
			var d: float = (x - cx) * (x - cx) + (y - cy) * (y - cy)
			if d < bd:
				bd = d
				best = i
	return best


func work_at(u: Unit, i: int, t: float, type: String) -> void:
	var x: float = i % W + 0.5
	var y: float = i / W + 0.5
	if Vector2(x - u.x, y - u.y).length() < 1.6:
		u.st = "work"
		u.wt = t
		u.wtype = type
		u.wi = i
		u.face = 1 if x > u.x else -1
	else:
		go_to(u, x + (-1.2 if randf() < 0.5 else 1.2), y + 0.3)


func finish_work(u: Unit) -> void:
	u.st = "idle"
	if u.vil < 0:
		return
	var v: Village = villages[u.vil]
	var i: int = u.wi
	if i < 0:
		return
	var x: int = i % W
	var y: int = i / W
	match u.wtype:
		"wood":
			if GuData.is_tree(world.feat[i]):
				world.feat[i] = 0
				world.mark_area(x, y)
				v.wood += 4.0
				puff(x + 0.5, y - 4.0, Color("#7a9a3a"), 6)
		"mine":
			if world.feat[i] == GuData.F_ORE:
				v.stones += 1.4
				spark(x + 0.5, y, Color("#dff6ec"), 4, 4.0)
				if randf() < 0.07:
					world.feat[i] = GuData.F_ROCK
					world.mark_area(x, y)
		"farm":
			v.food += 2.2
		"gather":
			v.food += 1.1


func think_p(u: Unit) -> void:
	if u.undead:
		undead_think(u)
		return
	if u.rank >= 9 and not arena and ven.think(u):
		return
	var v: Village = villages[u.vil] if u.vil >= 0 else null
	var a: float = uage(u)
	var c: Clan = clans[u.clan] if u.clan >= 0 else null
	var sight: float = (22.0 if u.rank >= 6 else 10.0 + u.rank * 1.2) if not arena else 40.0
	var imm: bool = u.rank >= 6
	if not arena and u.tgt != null and u.tgt.hp > 0.0 and ((not imm and is_imm(u.tgt) and u.igu.is_empty()) or (u.rank > 0 and power(u.tgt) > power(u) * FLEE_P)):
		# Sinnloser Kampf (z. B. Sterblicher gegen Unsterblichen): abbrechen und fliehen
		var ft: Unit = u.tgt
		u.tgt = null
		flee(u, ft, v)
		return
	if u.tgt == null or randf() < 0.25:
		# Unsterbliche verschwenden keine Zeit mit Ameisen: Zivilisten (Rang 0 ohne Miliz) greifen sie nicht an
		var e: Unit = nearest(u, sight, func(o: Unit) -> bool: return hostile(u, o) and not (imm and o.k == "p" and o.rank == 0 and not o.militia and not o.rogue))
		if e != null:
			if not arena:
				if a < 14.0 or (u.rank == 0 and not u.militia and u.job != "hunt" and power(e) > power(u) * 1.5):
					flee(u, e, v)
					return
				# Furcht: ein feindlicher Unsterblicher (bzw. ein weit Stärkerer) in Sicht – Sterbliche ohne Unsterbliche Gu fliehen
				var fe: Unit = e
				if not imm and not is_imm(e) and u.igu.is_empty():
					var ie: Unit = nearest(u, sight + 6.0, func(o: Unit) -> bool: return is_imm(o) and hostile(o, u))
					if ie != null:
						fe = ie
				if (not imm and is_imm(fe) and u.igu.is_empty()) or (u.rank > 0 and power(fe) > power(u) * FLEE_P):
					flee(u, fe, v)
					return
			u.tgt = e
			u.st = "idle"
			return
	if u.tgt != null:
		return
	if u.lure_t > sim_time:
		go_to(u, u.lx, u.ly)
		u.st = "idle"
		return
	if u.notrib and u.hx >= 0.0 and Vector2(u.hx - u.x, u.hy - u.y).length() > 22.0:
		go_to(u, u.hx + randf() * 8.0 - 4.0, u.hy + randf() * 8.0 - 4.0)
		return
	if u.rank >= 5 and wild_igu > 0 and catch_igu_think(u):
		return
	if u.rogue:
		if u.rank >= 6 and randf() < 0.3:
			var rich: Unit = nearest(u, 60.0, func(o: Unit) -> bool: return o.k == "p" and not o.igu.is_empty() and power(o) < power(u) * 1.5)
			if rich != null:
				u.tgt = rich
				return
		# Dämonische Unsterbliche jagen nur Gu-Meister ab Rang 3 (Gu und Unsterbliche Gu als Beute), keine Ameisen
		var prey: Unit = nearest(u, 24.0, func(o: Unit) -> bool: return o.k == "p" and not o.rogue and power(o) < power(u) * 1.3 and (u.rank < 6 or o.rank >= 3))
		if prey != null:
			u.tgt = prey
			return
		var g0: Unit = nearest(u, 14.0, func(o: Unit) -> bool: return o.beh == GuData.B_GU)
		if g0 != null and u.rank > 0:
			if Vector2(g0.x - u.x, g0.y - u.y).length() < 1.8:
				catch_wild_gu(u, g0)
			else:
				go_to(u, g0.x, g0.y)
			return
		wander(u, 20.0)
		return
	if v == null:
		if arena:
			wander(u, 3.0)
			return
		lone_think(u, a)
		return
	if a < 14.0:
		if randf() < 0.7:
			wander_near(u, v.cx, v.cy + 3.0, 7.0)
		return
	if c != null and not c.war.is_empty() and (u.rank > 0 or u.militia) and c.wt >= 0:
		var ev: Village = villages[c.wt]
		# Sterbliche ziehen nicht gegen einen Clan, den ein Unsterblicher schützt, solange der eigene keinen hat
		if ev.alive and c.war.has(ev.clan) and (imm or arena or top_rank(clans[ev.clan]) < 6 or top_rank(c) >= 6):
			go_to(u, ev.cx + randf() * 8.0 - 4.0, ev.cy + randf() * 8.0 - 4.0)
			u.st = "idle"
			return
	if u.st == "work":
		return
	if u.rank > 0:
		var g: Unit = nearest(u, 18.0, func(o: Unit) -> bool: return o.beh == GuData.B_GU)
		if g != null and randf() < 0.6:
			if Vector2(g.x - u.x, g.y - u.y).length() < 1.8:
				catch_wild_gu(u, g)
			else:
				go_to(u, g.x, g.y)
			return
		if randf() < 0.42:
			wander_near(u, v.cx, v.cy, 12.0 + v.houses * 1.5 + (18.0 if u.rank >= 6 else 0.0))
		else:
			var hx: float = v.cx
			var hy: float = v.cy + 4.0
			for id: int in v.b:
				var b: Building = buildings[id]
				if b != null and b.type == "forge":
					hx = b.x + 3.0
					hy = b.y + 4.5
			go_to(u, hx + randf() * 6.0 - 3.0, hy + randf() * 3.0)
		return
	do_job(u, v)


func do_job(u: Unit, v: Village) -> void:
	match u.job:
		"wood":
			var i: int = u.wi
			if i < 0 or not GuData.is_tree(world.feat[i]):
				i = find_feat(v.cx, v.cy, 30.0, func(f: int) -> bool: return GuData.is_tree(f))
			if i < 0:
				u.job = "gather"
				return
			u.wi = i
			work_at(u, i, 2.4, "wood")
		"mine":
			var i: int = u.wi
			if i < 0 or world.feat[i] != GuData.F_ORE:
				i = find_feat(v.cx, v.cy, 38.0, func(f: int) -> bool: return f == GuData.F_ORE)
			if i < 0:
				u.job = "wood"
				return
			u.wi = i
			work_at(u, i, 3.0, "mine")
		"farm":
			var fs: Array[Building] = []
			for id: int in v.b:
				var b: Building = buildings[id]
				if b != null and b.type == "farm":
					fs.append(b)
			if fs.is_empty():
				u.job = "gather"
				return
			var bb: Building = fs.pick_random()
			work_at(u, (bb.y + randi_range(1, bb.h - 2)) * W + bb.x + randi_range(1, bb.w - 2), 3.0, "farm")
		"gather":
			var i: int = find_feat(v.cx, v.cy, 20.0, func(f: int) -> bool: return GuData.is_tree(f) or f == GuData.F_SHRUB or f == GuData.F_TUFT)
			if i < 0:
				wander_near(u, v.cx, v.cy, 10.0)
				return
			work_at(u, i, 2.0, "gather")
		"hunt":
			var p: Unit = nearest(u, 28.0, func(o: Unit) -> bool: return o.beh == GuData.B_PREY or (o.beh == GuData.B_BOAR and o.rank == 0))
			if p != null and Vector2(p.x - v.cx, p.y - v.cy).length() < 36.0:
				u.tgt = p
			else:
				u.job = "wood"
		_:
			wander_near(u, v.cx, v.cy, 10.0)


func lone_think(u: Unit, a: float) -> void:
	if u.has_col_target():
		var d: float = (u.col_to - Vector2(u.x, u.y)).length()
		if d < 3.0:
			var cc: int = u.col_clan
			var nv: Village = nearest_village(u.x, u.y, 12.0, func(v: Village) -> bool: return v.clan == cc)
			if nv != null:
				join_village(u, nv)
				return
			if not found_village(u, u.col_clan):
				u.col_to = find_site(u.x, u.y, 3.0, 20.0, region_at(u.x, u.y))
		else:
			go_to(u, u.col_to.x, u.col_to.y)
		return
	var rg: int = region_at(u.x, u.y)
	var cc2: int = u.col_clan
	var race: int = u.race
	var vv: Village = nearest_village(u.x, u.y, 44.0 if cc2 >= 0 else 20.0, func(v: Village) -> bool: return (v.clan == cc2 if cc2 >= 0 else v.race == race) and v.reg == rg)
	if vv != null and a >= 4.0:
		if Vector2(vv.cx - u.x, vv.cy - u.y).length() < 6.0:
			join_village(u, vv)
		else:
			go_to(u, vv.cx, vv.cy)
		return
	if a >= 16.0 and randf() < 0.3:
		if found_village(u, u.col_clan):
			return
	wander(u, 16.0)


func think_a(u: Unit) -> void:
	var bh: int = u.beh
	if bh == GuData.B_GU or bh == GuData.B_IGU:
		wander(u, 6.0 if bh == GuData.B_GU else 10.0)
		return
	var L: Unit = u.ldr
	if L != null and L.hp <= 0.0:
		u.ldr = null
		L = null
	if bh == GuData.B_PREY or bh == GuData.B_SHY:
		var th: Unit = nearest(u, 8.0, func(o: Unit) -> bool: return o != L and ((o.k == "p" and o.job == "hunt") or o.beh == GuData.B_PRED or (o.beh == GuData.B_KING and o.ldr != L)))
		if th != null:
			var d: Vector2 = Vector2(u.x - th.x, u.y - th.y)
			if d.length() < 0.01:
				d = Vector2(1, 0)
			d = d.normalized() * 12.0
			go_to(u, u.x + d.x, u.y + d.y)
		elif L != null:
			wander_near(u, L.x, L.y, 5.0)
		elif randf() < 0.6:
			wander(u, 10.0)
		return
	if u.tgt == null:
		var r: float = 14.0 if u.rank >= 6 else (18.0 if (u.rank >= 3 or u.tide) else 10.0)
		var e: Unit = nearest(u, r, func(o: Unit) -> bool: return hostile(u, o))
		if e != null:
			u.tgt = e
			return
		if L != null and L.tgt != null and L.tgt.hp > 0.0:
			u.tgt = L.tgt
			return
	if u.tgt != null:
		return
	if u.tide and u.tide_v >= 0:
		var v: Village = villages[u.tide_v]
		if v.alive:
			go_to(u, v.cx + randf() * 8.0 - 4.0, v.cy + randf() * 8.0 - 4.0)
			return
		u.tide = false
	if L != null:
		wander_near(u, L.x, L.y, 5.0)
		return
	if u.rank >= 6 and u.hx >= 0.0:
		# Revierbestie: streift durchs Revier und überfällt nahe Dörfer
		if u.lure_t > sim_time:
			go_to(u, u.lx + randf() * 6.0 - 3.0, u.ly + randf() * 6.0 - 3.0)
			return
		if randf() < 0.1:
			var hv: Village = nearest_village(u.hx, u.hy, 34.0)
			if hv != null:
				u.lure_t = sim_time + 8.0
				u.lx = hv.cx
				u.ly = hv.cy
				return
		wander_near(u, u.hx, u.hy, 22.0)
		return
	wander(u, 20.0 if u.rank >= 6 else 12.0)


## Fängt einen wilden sterblichen Gu: Gu-Name in die Liste, Fortschritt.
func catch_wild_gu(u: Unit, g: Unit) -> void:
	g.hp = 0.0
	g.caught = true
	var gain: float = 0.12 * (1.6 if u.race == 1 else 1.0) * (1.5 if g.path == u.path else 1.0)
	u.prog += gain
	var nm: String = g.gname
	if nm == "" or u.gus.has(nm):
		nm = gain_gu(u)
	else:
		u.gus.append(nm)
		if u.gus.size() > 9:
			u.gus.remove_at(1)
	var gc: Color = GuData.PATH_COL[g.path] if g.path >= 0 else Color("#cfe8ff")
	float_txt(u, ("+" + nm) if nm != "" else "+Gu", gc)
	spark(g.x, g.y, gc, 8, 5.0)
	if u.prog >= 1.0:
		u.prog = 0.0
		stage_up(u)


## Unsterbliche (und Rang 5 für den Fötus) jagen wilde Unsterbliche Gu. true = beschäftigt.
func catch_igu_think(u: Unit) -> bool:
	var imm: bool = u.rank >= 6
	var g: Unit = nearest(u, 40.0, func(o: Unit) -> bool: return o.beh == GuData.B_IGU and (imm or o.gname == "sovereign_immortal_fetus"))
	if g == null or randf() > 0.8:
		return false
	if Vector2(g.x - u.x, g.y - u.y).length() < 2.2:
		g.hp = 0.0
		g.caught = true
		var nm: String = Lore.igu_name(g.gname)
		pillar(g.x, g.y, GuData.PATH_COL[g.path], 0.8)
		spark(g.x, g.y, Color("#ffe8a0"), 16, 6.0)
		float_txt(u, "+" + nm, Color("#ffe27a"))
		log_event(u.pname() + " captures the Immortal Gu " + nm + ".", "violet", true)
		give_igu(u, g.gname)
	else:
		go_to(u, g.x, g.y)
	return true


# ---------------- Schritt ----------------

func move_unit(u: Unit, dt: float) -> void:
	var dx: float = u.tx - u.x
	var dy: float = u.ty - u.y
	var d: float = sqrt(dx * dx + dy * dy)
	if d < 0.2:
		u.moving = false
		return
	var ti: int = int(u.y) * W + int(u.x)
	var mul: float = sp_mul(u, world.tile[ti])
	if world.feat[ti] == GuData.F_ROAD and not u.fly:
		mul *= 1.3
	if _sand and not u.fly:
		mul *= 0.6
	var spd: float = minf(u.speed * mul * dt, d)
	var ang: float = atan2(dy, dx)
	var cur_ok: bool = passable(u, int(u.x), int(u.y))
	for off: float in MOVE_OFFS:
		var a: float = ang + off
		var nx: float = u.x + cos(a) * spd
		var ny: float = u.y + sin(a) * spd
		if nx < 0 or ny < 0 or nx >= W or ny >= H:
			continue
		if not cur_ok or passable(u, int(nx), int(ny)):
			u.x = nx
			u.y = ny
			u.moving = true
			if absf(dx) > 0.05:
				u.face = 1 if dx > 0 else -1
			if off != 0.0:
				u.stuck += dt * 0.5
			else:
				u.stuck = maxf(0.0, u.stuck - dt)
			if u.stuck > 2.5:
				u.stuck = 0.0
				u.tgt = null
				wander(u, 12.0)
			return
	u.stuck += dt * 3.0
	u.moving = false
	if u.stuck > 2.0:
		u.stuck = 0.0
		u.tgt = null
		u.col_to = Vector2(-1, -1)
		wander(u, 12.0)


func attack(u: Unit, e: Unit) -> void:
	u.cd = (1.1 if u.rank >= 6 else 0.9) if u.k == "p" else (1.6 if u.rank >= 6 else 0.85)
	u.face = 1 if e.x > u.x else -1
	if u.k == "p" and u.rank >= 6 and not is_imm(e):
		finger_snap(u, e)
		return
	if u.k == "p" and u.rank >= 6 and u.km_cd <= 0.0 and u.path >= 0 and randf() < 0.3:
		u.km_cd = 9.0 + randf() * 8.0
		u.cd = 1.4
		killer_move(u, e.x, e.y)
		return
	if (u.igf & F_BOLT) != 0 and randf() < 0.3:
		bolt(e.x, e.y, u.atk * 0.6, false, u)
	if u.undead and e.k == "p" and not e.undead and e.rank < 6 and e.zin < 0.0 and randf() < 0.45:
		e.zin = sim_time + 1.0 + randf() * 2.0
		e.fxm = true
	if u.rng > 3.0:
		var c: Color = GuData.PATH_COL[u.path] if (u.k == "p" and u.path >= 0) else Color(str(GuData.SPEC[u.sp].get("pc", "#ff6a3a")) if u.k == "a" else "#ff6a3a")
		projs.append({"x": u.x, "y": u.y - 1.5, "t": e, "sp": 30.0 if u.rank >= 6 else 22.0, "dmg": u.atk * (0.85 + randf() * 0.3), "src": u, "c": c, "aoe": u.aoe, "path": u.path if u.k == "p" else -1, "big": u.rank >= 6, "l": 3.0, "a": 0.0, "ign": (u.igf & F_FIRE) != 0})
	else:
		hurt(e, u.atk * (0.8 + randf() * 0.4), u)
		spark(e.x, e.y - 1.0, Color("#ffe0b0"), 2, 3.0)
		if u.aoe > 0.0:
			for o: Unit in near_units(e.x, e.y, u.aoe):
				if o != e and hostile(u, o):
					hurt(o, u.atk * 0.5, u)


func step_unit(u: Unit, dt: float) -> void:
	u.anim += dt
	if u.flash > 0.0:
		u.flash -= dt
	if u.cd > 0.0:
		u.cd -= dt
	var ti: int = clampi(int(u.y), 0, H - 1) * W + clampi(int(u.x), 0, W - 1)
	var t: int = world.tile[ti]
	if u.fxm and _special(u, dt, t):
		return
	if t == GuData.DEEP and not u.swim and not u.fly and not u.boat:
		hurt(u, 4.0 * dt, null)
	if not u.fly and fire.has(ti):
		hurt(u, 3.0 * dt, null)
	if t == GuData.LAVA and not u.fly:
		hurt(u, (20.0 + u.mhp * 0.2) * dt, null)
		if randf() < dt * 4.0:
			spark(u.x, u.y - 1.0, Color("#ff8a2a"), 2, 3.0)
	if u.sick > 0.0 and not u.undead:
		u.sick -= dt
		hurt(u, (0.15 if u.rank >= 3 else 1.1) * dt, null)
		if randf() < dt * 0.6:
			var o: Unit = nearest(u, 2.5, func(q: Unit) -> bool: return q.k == u.k and q.sick <= 0.0)
			if o != null and not (o.k == "p" and o.rank >= 5):
				o.sick = 18.0 + randf() * 12.0
		if randf() < dt * 3.0:
			parts.append({"x": u.x, "y": u.y - 3.0, "vx": 0.0, "vy": -2.0, "l": 0.6, "ml": 0.6, "c": Color("#86e04a"), "s": 0.6, "g": 0.0})
	if u.k == "a":
		if u.beh == GuData.B_PRED or u.beh == GuData.B_KING:
			u.hungry = minf(1.0, u.hungry + dt * 0.006)
		if u.rank >= 6 and world.bmap[ti] >= 0:
			var b: Building = buildings[world.bmap[ti]]
			if b != null:
				b.hp -= 60.0 * dt
				if b.hp <= 0.0:
					remove_building(b)
	elif u.km_cd > 0.0:
		u.km_cd -= dt
	u.think -= dt
	if u.think <= 0.0:
		u.think = 0.35 + randf() * 0.45
		if u.poss:
			poss_think(u)
		elif u.k == "p":
			think_p(u)
		else:
			think_a(u)
	if u.tgt != null:
		var e: Unit = u.tgt
		if e.hp <= 0.0:
			u.tgt = null
		else:
			var d: float = Vector2(e.x - u.x, e.y - u.y).length()
			if d > (44.0 if u.rank >= 6 else 32.0):
				u.tgt = null
			elif d <= u.rng:
				u.tx = u.x
				u.ty = u.y
				u.moving = false
				if u.cd <= 0.0:
					attack(u, e)
				return
			else:
				u.tx = e.x
				u.ty = e.y
				if u.st == "work":
					u.st = "idle"
	if u.st == "work":
		u.wt -= dt
		u.moving = false
		if u.wt <= 0.0:
			finish_work(u)
	else:
		move_unit(u, dt)
	if u.k == "p" and u.rank > 0 and not u.moving and u.tgt == null and randf() < dt * 0.5:
		parts.append({"x": u.x + (randf() - 0.5) * 2.0, "y": u.y - 2.0, "vx": 0.0, "vy": -2.5, "l": 0.9, "ml": 0.9, "c": GuData.ESS_COL[u.rank], "s": 0.5, "g": 0.0})


func step(dt: float) -> void:
	sim_time += dt
	_sand = weather.get("type", "") == "sand"
	if parts.size() > 4000:
		parts = parts.slice(parts.size() - 2000)
	var m: int = int(sim_time)
	if m != last_month:
		last_month = m
		monthly()
	rebuild_grid()
	for k: int in range(units.size()):
		var u: Unit = units[k]
		if u.hp > 0.0:
			step_unit(u, dt)
	var pi: int = projs.size() - 1
	while pi >= 0:
		var p: Dictionary = projs[pi]
		var tu: Unit = p["t"]
		var tx: float = tu.x
		var ty: float = tu.y - 1.2
		var dx: float = tx - p["x"]
		var dy: float = ty - p["y"]
		var d: float = sqrt(dx * dx + dy * dy)
		var s: float = p["sp"] * dt
		p["l"] -= dt
		if d <= s + 0.4 or tu.hp <= 0.0 or p["l"] <= 0.0:
			if tu.hp > 0.0:
				hurt(tu, p["dmg"], p["src"])
			if p["aoe"] > 0.0:
				for o: Unit in near_units(tu.x, tu.y, p["aoe"]):
					if o != tu and hostile(p["src"], o):
						hurt(o, p["dmg"] * 0.6, p["src"])
				ring(tu.x, tu.y, p["aoe"], p["c"], 0.45)
				if p["big"]:
					var i: int = clampi(int(tu.y), 0, H - 1) * W + clampi(int(tu.x), 0, W - 1)
					if p["path"] == 2 or p["path"] == 5 or p.get("ign", false):
						ignite(i, 1.0)
					elif randf() < 0.25 and (world.tile[i] == GuData.GRASS or world.tile[i] == GuData.STEP):
						world.tile[i] = GuData.SOIL
						if GuData.is_tree(world.feat[i]):
							world.feat[i] = 0
						world.mark_area(i % W, i / W)
			spark(p["x"], p["y"], p["c"], 10 if p["big"] else 4, 8.0 if p["big"] else 4.0)
			projs.remove_at(pi)
		else:
			p["x"] += dx / d * s
			p["y"] += dy / d * s
			p["a"] = atan2(dy, dx)
		pi -= 1
	var si: int = sched.size() - 1
	while si >= 0:
		if si < sched.size() and sched[si]["t"] <= sim_time:
			var fn: Callable = sched[si]["fn"]
			sched.remove_at(si)
			fn.call()
		si -= 1
	_fire_acc += dt
	if _fire_acc >= 0.25:
		_fire_acc = 0.0
		fire_step()
	if not (lava.is_empty() and volcs.is_empty() and goo.is_empty() and seeds.is_empty()):
		_nat_acc += dt
		if _nat_acc >= 0.15:
			_nat_acc = 0.0
			nature_tick()
	if not (storms.is_empty() and acids.is_empty() and mines.is_empty()):
		forces_step(dt)
	env_step(dt)
	var dead: bool = false
	for u: Unit in units:
		if u.hp <= 0.0:
			dead = true
			break
	if dead:
		var alive: Array[Unit] = []
		for u: Unit in units:
			if u.hp > 0.0:
				alive.append(u)
			elif try_revive(u):
				alive.append(u)
			elif rise_dead(u):
				alive.append(u)
			else:
				if u == possessed:
					possessed = null
				on_death(u)
		units = alive


func on_death(u: Unit) -> void:
	unit_died.emit(u)
	ven.on_death(u)
	if u.k == "a" and u.rank >= 6 and not presim and randf() < 0.35:
		var g: Unit = spawn_wild_igu(u.x, u.y)
		log_event("From the body of " + u.pname() + " escapes the Immortal Gu " + g.pname() + ".", "violet", true)
	if u.k == "p":
		if not u.caught:
			puff(u.x, u.y - 1.0, Color("#7a2020"), 3)
		if u.rank >= 4 and not (u.dreason in ["Heaven's Will", "Himmelswille", "failed ascension", "heavenly tribulation"]):
			log_event("%s (%s) has died – %s." % [u.pname(), rank_title(u.rank), u.dreason if u.dreason != "" else "in battle"], "red" if u.rank >= 6 else "info", u.rank >= 6)
		if u.rank == 9:
			log_event("The " + u.title + " has fallen. An era ends.", "red", true)


func plant_for(i: int) -> int:
	var t: int = world.tile[i]
	var r: int = world.region[i]
	if t == GuData.SNOW:
		return GuData.F_PINE
	if t == GuData.SAND or t == GuData.DES:
		return GuData.F_PALM
	if t == GuData.HILL:
		return GuData.F_PINE if r == 0 else GuData.F_TREE
	if r == 1 and randf() < 0.3:
		return GuData.F_BAMB
	return GuData.F_TREE


func land_for(i: int) -> int:
	var r: int = world.region[i]
	return GuData.STEP if r == 0 else (GuData.DES if r == 2 else GuData.GRASS)


func env_step(dt: float) -> void:
	var wt: String = weather.get("type", "")
	if not weather.is_empty():
		weather["t"] -= dt
		if weather["t"] <= 0.0:
			weather = {}
	var rain: bool = wt == "rain"
	var dry: bool = wt == "drought"
	var snow: bool = wt == "snow" or age_index() == 7
	var grow: float = float(age_data()["grow"])
	# Stichproben je Schritt wachsen mit der Kartenfläche (gleiches Tempo je Kachel)
	var af: float = GuData.area_f()
	var n: int = roundi((26 if rain else 10) * af)
	for k: int in range(n):
		var i: int = randi() % N
		var t: int = world.tile[i]
		var x: int = i % W
		var y: int = i / W
		if laws["growth"] and laws["trees"] and not dry and (t == GuData.GRASS or t == GuData.STEP) and world.feat[i] == 0 and world.bmap[i] < 0:
			var near: int = 0
			for dd: int in [2, 5]:
				if x >= dd and GuData.is_tree(world.feat[i - dd]):
					near += 1
				if x < W - dd and GuData.is_tree(world.feat[i + dd]):
					near += 1
				if y >= dd and GuData.is_tree(world.feat[i - dd * W]):
					near += 1
				if y < H - dd and GuData.is_tree(world.feat[i + dd * W]):
					near += 1
			if (near > 0 and randf() < 0.012 * grow) or randf() < 0.0004 * grow:
				world.feat[i] = plant_for(i)
				world.mark_area(x, y)
		elif t == GuData.SOIL and laws["grass"] and not dry and world.bmap[i] < 0 and randf() < 0.08:
			world.tile[i] = land_for(i)
			world.mark_dirty(x, y)
		elif t == GuData.ASH and laws["grass"] and randf() < 0.05:
			world.tile[i] = GuData.SOIL
			world.mark_dirty(x, y)
		elif t == GuData.SNOW and world.temp_snow[i] > 0 and not snow and randf() < 0.3:
			world.tile[i] = world.temp_snow[i] - 1
			world.temp_snow[i] = 0
			world.mark_dirty(x, y)
	if snow:
		for k: int in range(roundi((40 if wt == "snow" else 6) * af)):
			var i: int = randi() % N
			var t: int = world.tile[i]
			if (t == GuData.GRASS or t == GuData.STEP or t == GuData.SOIL or t == GuData.DES) and world.bmap[i] < 0:
				world.temp_snow[i] = t + 1
				world.tile[i] = GuData.SNOW
				world.mark_dirty(i % W, i / W)
	if dry:
		for k: int in range(roundi(16 * af)):
			var i: int = randi() % N
			if world.tile[i] == GuData.GRASS and randf() < 0.4:
				world.tile[i] = GuData.DES if world.region[i] == 2 else GuData.SOIL
				world.mark_dirty(i % W, i / W)
			if GuData.is_tree(world.feat[i]) and randf() < 0.01:
				ignite(i, 1.0)
	if rain:
		for i: int in fire.keys():
			fire[i] -= dt


# ---------------- Welt starten ----------------

func reset_state() -> void:
	_sync_size()
	units.clear()
	villages.clear()
	clans.clear()
	buildings.clear()
	projs.clear()
	fx.clear()
	parts.clear()
	sched.clear()
	log_entries.clear()
	fire.clear()
	places.clear()
	lava.clear()
	volcs.clear()
	storms.clear()
	acids.clear()
	goo.clear()
	goo_left = 0
	mines = PackedInt32Array()
	seeds.clear()
	possessed = null
	age_off = 0
	ven.reset()
	cheats.reset_world()
	next_pid = 1
	sim_time = 0.0
	last_month = 0
	next_id = 1
	weather = {}


## Startdörfer und Tiere; canon = false lässt auf der Gu-Weltkarte die kanonischen Mächte weg (dann wie bei der Zufallswelt).
func seed_life(canon: bool = true) -> void:
	var plan: Array = [[0, 2], [1, 3], [2, 1], [3, 1], [4, 3]]
	if world.map_mode == "gu" and canon:
		seed_canon()
		plan = [[0, 1], [1, 1], [3, 1]]
	for e: Array in plan:
		var r: int = e[0]
		# auf großen Karten mehr Startdörfer (mit der Kantenlänge, nicht der Fläche – es bleibt viel freies Land)
		for k: int in range(roundi(int(e[1]) * GuData.len_f())):
			var p: Vector2 = random_tile(func(i: int) -> bool: return world.region[i] == r and GuData.buildable(world.tile[i]) and world.tile[i] != GuData.SAND and site_ok(i % W, i / W, r), 900)
			if p.x < 0.0:
				continue
			var race: int = seed_race(r)
			var sur: String = GuData.RACE_SUR[race].pick_random()[0] if race >= 4 else (rand_sur(4) if r == 4 else GuData.SURN[r].pick_random()[0])
			var lead: Unit = mk_person(p.x, p.y, race, 24.0, sur)
			lead.awk = true
			awaken(lead)
			ascend(lead, 2)
			if not found_village(lead, -1):
				continue
			var v: Village = villages[lead.vil]
			for j: int in range(8):
				var u: Unit = mk_person(p.x + (randf() - 0.5) * 6.0, p.y + 2.0 + (randf() - 0.5) * 4.0, race, 6.0 if j < 1 else 15.0 + randf() * 15.0, sur)
				u.awk = j >= 1
				join_village(u, v)
	nature_only()


## Volk eines Startdorfs je Region (Variant-Menschen in ihren Heimatregionen).
func seed_race(r: int) -> int:
	var q: float = randf()
	match r:
		0:
			return 5 if q < 0.35 else 0
		1:
			return 1 if q < 0.15 else (2 if q < 0.25 else (8 if q < 0.32 else (10 if q < 0.39 else (9 if q < 0.45 else 0))))
		2:
			return 4 if q < 0.45 else (2 if q < 0.7 else 0)
		3:
			return 6 if q < 0.4 else 3
	return 1 if q < 0.3 else 0


func _landmark(nm: String) -> Vector2:
	for l: Dictionary in world.landmarks:
		if l["name"] == nm:
			return Vector2(float(l["x"]) + 0.5, float(l["y"]) + 0.5)
	return Vector2(-1, -1)


## Kanonische Mächte der Gu-Weltkarte an ihren Orten.
func seed_canon() -> void:
	var spots: Array = [["heavenly_court", "Heavenly Court"], ["immortal_crane_sect", "Immortal Crane Sect"], ["spirit_affinity_house", "Spirit Affinity House"],
		["gu_yue_clan", "Gu Yue Village"], ["shang_clan", "Shang Clan City"], ["bai_clan", "Bai Gu Mountain"], ["western_desert_families", "Great Oasis"],
		["huang_jin_tribes", ""], ["hei_tribe", ""], ["eastern_sea_clans", ""]]
	for e: Array in spots:
		var o: Dictionary = Lore.org(e[0])
		var p: Vector2 = _landmark(e[1]) if e[1] != "" else Vector2(-1, -1)
		if p.x < 0.0:
			var rg: int = int(o["reg"])
			p = random_tile(func(i: int) -> bool: return world.region[i] == rg and GuData.buildable(world.tile[i]) and world.tile[i] != GuData.SAND and site_ok(i % W, i / W, rg), 900)
		if p.x >= 0.0:
			found_org(o, p.x, p.y, true)
	var central: Array[Clan] = []
	for id: String in ["heavenly_court", "immortal_crane_sect", "spirit_affinity_house"]:
		var c: Clan = org_clan(id)
		if c != null:
			central.append(c)
	for a: Clan in central:
		a.calm = sim_time + 240.0
		for b: Clan in central:
			if a != b:
				a.ally[b.id] = true
	for e2: Array in [["langya", "Lang Ya Blessed Land"], ["imperial", "Imperial Court Blessed Land"]]:
		var lp: Vector2 = _landmark(e2[1])
		if lp.x >= 0.0 and place_ok(e2[0], lp.x, lp.y) == "":
			add_place(e2[0], lp.x, lp.y, true)


func nature_only() -> void:
	for e: Array in [["deer", 22], ["boar", 10], ["wolf", 12], ["monkey", 8], ["crane", 8], ["wildgu", 36], ["white_boar", 3], ["black_boar", 3], ["lightning_wolf", 4]]:
		var s: String = e[0]
		var rg: int = int(GuData.SPEC[s].get("reg", -1))
		for k: int in range(roundi(int(e[1]) * GuData.len_f())):
			var p: Vector2 = random_tile(func(i: int) -> bool:
				var t: int = world.tile[i]
				if rg >= 0 and world.region[i] != rg:
					return false
				if s == "crane" or s == "wildgu":
					return GuData.is_land(t) and t != GuData.WALL
				return t == GuData.GRASS or t == GuData.STEP or t == GuData.SNOW, 300)
			if p.x >= 0.0:
				if s == "wildgu":
					spawn_wild_gu(p.x, p.y, int(GuData.REGPATH[region_at(p.x, p.y)].pick_random()))
				else:
					mk_animal(p.x, p.y, s)


## Neue Welt. live = true: Clans, Tiere und Vorgeschichte (Standard); live = false: nur Tiere, auf leeren Karten gar nichts.
## opts (optional, überschreibt live):
##   "life": "full" (Dörfer, Clans und Tiere), "animals" (nur Tiere und wilde Gu) oder "none" (kein Leben,
##           auch kein Tier-Spawn – das Weltgesetz „Tier-Spawn“ wird dann ausgeschaltet),
##   "canon": false – auf der Gu-Weltkarte ohne die kanonischen Mächte,
##   "presim": false – ohne Vorgeschichte, die Welt beginnt sofort in Jahr 1.
func new_world(live: bool, mode: String = "gu", opts: Dictionary = {}) -> void:
	GuData.set_size(int(opts.get("size", GuData.W)))
	reset_state()
	seed_val = randi()
	world.generate(seed_val, mode)
	var life: String = str(opts.get("life", "full" if live else ("none" if World.is_blank(world.map_mode) else "animals")))
	presim = life == "full" and bool(opts.get("presim", true))
	laws["animals"] = life != "none"
	match life:
		"full":
			seed_life(bool(opts.get("canon", true)))
		"animals":
			nature_only()


## Läuft die Vorgeschichte in Häppchen; gibt den Fortschritt 0..1 zurück.
func presim_chunk(budget_ms: int, target_years: float) -> float:
	var total: float = target_years * 12.0
	var t0: int = Time.get_ticks_msec()
	while sim_time < total and Time.get_ticks_msec() - t0 < budget_ms:
		step(0.1)
	if sim_time >= total:
		presim = false
		log_event("The world awakens. Year %d." % year(), "jade")
		return 1.0
	return sim_time / total


# ---------------- Speichern ----------------

func serialize() -> Dictionary:
	var hb: PackedByteArray = world.hgt.to_byte_array()
	var us: Array = []
	for u: Unit in units:
		if u.hp > 0.0:
			us.append(u.to_dict())
	var vs: Array = []
	for v: Village in villages:
		vs.append(v.to_dict())
	var cs: Array = []
	for c: Clan in clans:
		cs.append(c.to_dict())
	var bs: Array = []
	for b: Building in buildings:
		bs.append(b.to_dict() if b != null else null)
	var fr: Array = []
	for i: int in fire.keys():
		fr.append([i, fire[i]])
	var ps: Array = []
	for p: Place in places:
		if p.alive:
			ps.append(p.to_dict())
	var lv: Array = []
	for i: int in lava.keys():
		lv.append([i, snappedf(float(lava[i]), 0.01)])
	return {"v": 6, "size": W, "ven": ven.to_dict(), "cheat": cheats.to_dict(), "age_off": age_off, "lava": lv, "mines": Array(mines), "layer": world.layer, "seed": seed_val, "sim_time": sim_time, "next_id": next_id, "map_mode": world.map_mode, "places": ps, "next_pid": next_pid,
		"tile": Marshalls.raw_to_base64(world.tile), "feat": Marshalls.raw_to_base64(world.feat), "region": Marshalls.raw_to_base64(world.region),
		"hgt": Marshalls.raw_to_base64(hb), "ts": Marshalls.raw_to_base64(world.temp_snow),
		"units": us, "villages": vs, "clans": cs, "buildings": bs, "laws": laws, "log": log_entries.slice(0, 120), "fire": fr}


func deserialize(d: Dictionary) -> bool:
	var ver: int = int(d.get("v", 0))
	if ver < 1 or ver > 6:
		return false
	# Kartengröße: ab v6 gespeichert, ältere Spielstände haben immer 256 × 256
	var sz: int = int(d.get("size", 256))
	var tl: PackedByteArray = Marshalls.base64_to_raw(d["tile"])
	if tl.size() != sz * sz:
		return false
	GuData.set_size(sz)
	reset_state()
	world.alloc()
	world.tile = tl
	world.feat = Marshalls.base64_to_raw(d["feat"])
	world.region = Marshalls.base64_to_raw(d["region"])
	world.hgt = Marshalls.base64_to_raw(d["hgt"]).to_float32_array()
	world.temp_snow = Marshalls.base64_to_raw(d["ts"])
	seed_val = int(d["seed"])
	sim_time = d["sim_time"]
	last_month = int(sim_time)
	next_id = int(d["next_id"])
	world._set_landmarks(str(d.get("map_mode", "random")), ver < 6)
	next_pid = int(d.get("next_pid", 1))
	for e: Dictionary in d.get("places", []):
		places.append(Place.from_dict(e))
	for e: Dictionary in d["units"]:
		var u: Unit = Unit.from_dict(e)
		if u.k == "a":
			if not GuData.SPEC.has(u.sp):
				continue
			init_animal(u)
		elif not u.igu.is_empty():
			apply_igu(u)
		units.append(u)
	for e: Dictionary in d["villages"]:
		villages.append(Village.from_dict(e))
	for e: Dictionary in d["clans"]:
		clans.append(Clan.from_dict(e))
	for e: Variant in d["buildings"]:
		buildings.append(Building.from_dict(e) if e != null else null)
	for k: String in d["laws"].keys():
		laws[k] = d["laws"][k]
	for e: Dictionary in d["log"]:
		log_entries.append(e)
	for e: Array in d["fire"]:
		fire[int(e[0])] = float(e[1])
	for e: Array in d.get("lava", []):
		lava[int(e[0])] = float(e[1])
	for e: Variant in d.get("mines", []):
		mines.append(int(e))
	world.layer = int(d.get("layer", 0))
	age_off = int(d.get("age_off", 0))
	ven.from_dict(d.get("ven", {}))
	cheats.from_dict(d.get("cheat", {}))
	for i: int in range(N):
		if world.tile[i] == GuData.LAVA and not lava.has(i):
			lava[i] = 0.3
	for b: Building in buildings:
		if b == null:
			continue
		for y: int in range(b.y, b.y + b.h):
			for x: int in range(b.x, b.x + b.w):
				world.bmap[y * W + x] = b.id
	for v: Village in villages:
		recount(v)
	world.compute_water()
	world.render_all()
	update_leaders()
	terr_dirty = true
	return true


# =====================================================================
# Gu-Welt: Wiedergeburt, Mordzüge, Gu-Meister, Ehrwürdige, Figuren, Organisationen, Orte, Ereignisse
# =====================================================================

## Frühling-Herbst-Zikade (jung wiedergeboren) oder Auferstehung von den Toten. true = lebt weiter.
func try_revive(u: Unit) -> bool:
	if cheats.keep_alive(u):
		return true
	if u.k != "p" or u.dreason in ["göttliche Auslöschung", "divine annihilation"] or (u.igf & (F_REVIVE | F_REZ)) == 0:
		return false
	var rez: bool = (u.igf & F_REVIVE) == 0
	var want: String = "rez" if rez else "revive"
	for k: int in range(u.igu.size()):
		if str(Lore.igu(u.igu[k]).get("fx", "")) == want:
			u.igu.remove_at(k)
			break
	apply_igu(u)
	var nm: String = u.pname()
	u.dreason = ""
	u.tgt = null
	u.aggro = null
	u.sick = 0.0
	u.st = "idle"
	if rez:
		set_stats(u, true)
		u.hp = u.mhp * 0.5
		log_event(nm + " rises from the dead through resurrection.", "violet", true)
		pillar(u.x, u.y, GuData.PATH_COL[32], 0.9)
		return true
	u.birth = sim_time - 15.0 * 12.0
	u.life = maxf(u.life, 15.0 + GuData.RACE_LIFE[u.race] * 0.8 + GuData.LIFEB[u.rank])
	if u.apt == "B" or u.apt == "C" or u.apt == "D":
		u.apt = "A"
	if u.rank > 0:
		u.prog = minf(0.99, u.prog + 0.5)
	var rg: int = region_at(u.x, u.y)
	var p: Vector2 = random_tile(func(i: int) -> bool: return world.region[i] == rg and GuData.buildable(world.tile[i]) and world.bmap[i] < 0, 200)
	if p.x >= 0.0:
		u.x = p.x
		u.y = p.y
		u.tx = p.x
		u.ty = p.y
	if u.vil >= 0:
		u.col_clan = u.clan
		u.vil = -1
	set_stats(u, true)
	log_event(nm + " dies – but the Spring Autumn Cicada turns back time: " + nm + " awakens as a 15-year-old, with all memories intact.", "violet", true)
	pillar(u.x, u.y, GuData.PATH_COL[10], 1.2)
	ring(u.x, u.y, 8.0, GuData.PATH_COL[10], 1.0)
	return true


## Pfad-Mordzug eines Unsterblichen: Flächenschaden, Effekt und Name in der Farbe des Pfades.
func killer_move(u: Unit, x: float, y: float) -> void:
	var p: int = clampi(u.path, 0, GuData.PATH_NAME.size() - 1)
	var c: Color = GuData.PATH_COL[p]
	var r: float = 3.0 + u.rank * 0.8
	var dmg: float = u.atk * 2.5
	var nm: String = Lore.km_name(p)
	fx.append({"k": "km", "x": x, "y": y, "r": r, "c": c, "p": p, "l": 1.1, "ml": 1.1})
	fx.append({"k": "txt", "x": u.x, "y": u.y - 7.0, "t": nm, "c": c.lightened(0.3), "l": 2.0, "ml": 2.0})
	for o: Unit in near_units(x, y, r):
		if o != u and hostile(u, o):
			var d: float = Vector2(o.x - x, o.y - y).length()
			hurt(o, dmg * (1.0 - 0.5 * d / r), u)
	if p == 1:
		fx.append({"k": "cres", "x": x, "y": y, "r": r, "a": randf() * TAU, "l": 0.9, "ml": 0.9})
	if p == 5 or p == 17 or p == 28:
		for k: int in range(3):
			bolt(x + (randf() - 0.5) * r, y + (randf() - 0.5) * r, 0.0, p == 5)
	for k: int in range(int(r * 2.0)):
		var tx: int = int(x + (randf() - 0.5) * r * 1.4)
		var ty: int = int(y + (randf() - 0.5) * r * 1.4)
		if not world.in_map(tx, ty):
			continue
		var i: int = ty * W + tx
		var t: int = world.tile[i]
		if not GuData.is_land(t) or t == GuData.WALL:
			continue
		match p:
			2, 5:
				if k < 3:
					ignite(i, 1.0)
			7, 12:
				if t != GuData.MOUNT and world.bmap[i] < 0:
					if world.feat[i] != 0 and world.feat[i] != GuData.F_SPRING and world.feat[i] != GuData.F_ORE:
						world.feat[i] = 0
					set_tile(i, GuData.SOIL)
			14, 15:
				if world.bmap[i] < 0 and (t == GuData.GRASS or t == GuData.STEP or t == GuData.SOIL or t == GuData.DES):
					world.temp_snow[i] = t + 1
					world.tile[i] = GuData.SNOW
					world.mark_dirty(tx, ty)
			6:
				if world.feat[i] == 0 and world.bmap[i] < 0 and (t == GuData.GRASS or t == GuData.STEP or t == GuData.SOIL):
					world.feat[i] = plant_for(i)
					world.mark_area(tx, ty)
	spark(x, y, c, 30, 9.0)
	ring(x, y, r, c, 0.8)
	ring(x, y, r * 0.5, Color.WHITE, 0.5)
	if u.rank >= 8:
		shake = minf(1.2, shake + 0.35)
		log_event(u.pname() + " unleashes " + nm + ".", "violet")


## „Fingerschnipsen“: ein Unsterblicher gegen Sterbliche – jeder Schlag ist ein kleiner Mordzug, der alle
## feindlichen Kämpfer (Gu-Meister, Miliz, Bestien) im Umkreis auslöscht. Zivilisten bleiben verschont.
func finger_snap(u: Unit, e: Unit) -> void:
	var p: int = clampi(u.path, 0, GuData.PATH_NAME.size() - 1)
	var c: Color = GuData.PATH_COL[p]
	var r: float = snap_r(u)
	u.cd = 1.0 if u.rank < 9 else 0.7
	fx.append({"k": "km", "x": e.x, "y": e.y, "r": r, "c": c, "p": p, "l": 0.8, "ml": 0.8})
	ring(u.x, u.y - 2.0, 2.5, GuData.ESS_COL[clampi(u.rank, 0, 9)], 0.4)
	var n: int = 0
	for o: Unit in near_units(e.x, e.y, r):
		if o == u or not hostile(u, o) or is_imm(o):
			continue
		if o != e and o.k == "p" and o.rank == 0 and not o.militia and not o.rogue:
			continue
		hurt(o, u.atk * 2.0, u)
		n += 1
	if n >= 6 and u.km_cd <= 0.0:
		u.km_cd = 6.0
		fx.append({"k": "txt", "x": u.x, "y": u.y - 7.0, "t": Lore.km_name(p), "c": c.lightened(0.3), "l": 1.6, "ml": 1.6})
		shake = minf(1.0, shake + 0.08 * (u.rank - 5))
	spark(e.x, e.y, c, 10 + n * 2, 7.0)


## Reichweite des Fingerschnipsens: Rang 6 sechs Kacheln, Rang 9 zwölf.
func snap_r(u: Unit) -> float:
	return 6.0 + (u.rank - 6) * 1.5 + (3.0 if u.rank >= 9 else 0.0)


## Höchster Rang eines Clans (Clan-Oberhaupt).
func top_rank(c: Clan) -> int:
	if c == null or c.lead == null or c.lead.hp <= 0.0 or c.lead.clan != c.id:
		return 0
	return c.lead.rank


## Der schwächere Clan unterwirft sich der Übermacht: das Dorf, das dem Sieger am nächsten liegt, geht über, dann Frieden.
func capitulate(c: Clan, o: Clan) -> void:
	var oc: Village = villages[o.cap] if o.cap >= 0 and o.cap < villages.size() else null
	var best: Village = null
	var bd: float = 1e9
	var n: int = 0
	for v: Village in villages:
		if not v.alive or v.clan != c.id:
			continue
		n += 1
		var d: float = Vector2(v.cx - oc.cx, v.cy - oc.cy).length() if oc != null else randf()
		if v.id == c.cap:
			d += 60.0
		if d < bd:
			bd = d
			best = v
	var tr: int = top_rank(o)
	log_event("%s yields to the overwhelming might of %s (%s)%s." % [c.name, o.name, rank_title(tr), (" and cedes " + best.name) if best != null and n > 1 else ""], "war", true)
	if best != null and n > 1:
		capture(best, o)
	make_peace(c, o, true)


# ---------------- Gu-Meister, Unsterbliche, Ehrwürdige, Figuren ----------------

func _race_for_region(rg: int) -> int:
	var opts: Array[int] = []
	for i: int in range(1, GuData.RACE_NAME.size()):
		if GuData.RACE_REG[i] == rg:
			opts.append(i)
	return opts.pick_random() if not opts.is_empty() else 0


## Gu-Meister von Rang 1..5: schließt sich einem nahen Dorf an, Pfad passend zur Region.
func spawn_gm(x: float, y: float, rank: int) -> Unit:
	var v: Village = nearest_village(x, y, 24.0)
	var race: int = v.race if v != null else (_race_for_region(region_at(x, y)) if randf() < 0.35 else 0)
	var u: Unit = mk_person(x, y, race, 14.0 + rank * 5.0 + randf() * 10.0, pick_sur(v) if v != null else "")
	if v != null:
		join_village(u, v)
	u.awk = true
	awaken(u, true)
	for r: int in range(2, rank + 1):
		ascend(u, r)
	u.stage = [0, 0, 0, 1, 1, 2, 3].pick_random()
	set_stats(u, true)
	u.life = maxf(u.life, uage(u) + 25.0 + GuData.LIFEB[rank])
	pillar(x, y, GuData.ESS_COL[rank], 0.6)
	return u


## Wandernder Gu-Unsterblicher von Rang 6..8 (manchmal mit Unsterblichem Gu).
func spawn_immortal(x: float, y: float, rank: int) -> Unit:
	var u: Unit = mk_person(x, y, 0 if randf() < 0.7 else _race_for_region(region_at(x, y)), 100.0 + rank * 40.0 + randf() * 80.0)
	u.awk = true
	awaken(u, true)
	for r: int in range(2, rank + 1):
		ascend(u, r)
	u.stage = [0, 0, 1, 1, 2, 3].pick_random()
	set_stats(u, true)
	u.life = uage(u) + GuData.LIFEB[rank] * 0.8 + randf() * 200.0
	u.next_trib = uage(u) + 8.0 + randf() * 10.0
	if randf() < 0.15 + 0.2 * (rank - 6):
		give_igu(u, Lore.igu_random())
	pillar(x, y, GuData.ESS_COL[rank])
	log_event("A wandering %s appears: %s (%s Path)." % [rank_title(rank), u.pname(), GuData.PATH_NAME[u.path]], "violet", true)
	return u


## Einer der elf Ehrwürdigen (nur einer je Ehrwürdigem zur selben Zeit). Gibt einen Hinweis zurück oder "".
func spawn_venerable(vd: Dictionary, x: float, y: float) -> String:
	var key: String = vd["fig"]
	if cheats.is_on("uniq") and fig_alive(key) != null:
		return str(vd["t"]) + " is already alive."
	if not cheats.room():
		return cheats.full_msg()
	var dup: String = cheats.fig_suffix(key)   # weitere Exemplare: „Riesensonne II“
	var u: Unit = mk_person(x, y, 0, 600.0 + randf() * 900.0)
	u.sur = ""
	u.given = str(vd["n"]) + dup
	u.awk = true
	awaken(u, true)
	u.path = int(vd["p"])
	u.align = int(vd["al"])
	u.apt = "A"
	u.gus = PackedStringArray([Lore.start_gu(u.path)])
	for r: int in range(2, 10):
		ascend(u, r)
	u.title = vd["t"]
	u.fig = key
	u.life = uage(u) + (float(vd["life"]) * (0.8 + randf() * 0.5) if vd.has("life") else 3000.0 + randf() * 2000.0)
	give_igu(u, vd["igu"])
	u.hp = u.mhp
	log_event("The " + u.title + " descends! The world trembles.", "gold", true)
	pillar(x, y, GuData.ESS_COL[9], 1.6)
	ring(x, y, 16.0, Color(str(vd["col"])), 1.2)
	shake = 1.0
	ven.register(u, vd)
	return ""


## Höchster Großmeister nach Wahl: Rang-9-Ehrwürdiger eines beliebigen Pfades (einer je Pfad), Sitz und Blutlinie nahe (x, y).
func spawn_custom_venerable(p: int, al: int, x: float, y: float) -> String:
	p = clampi(p, 0, GuData.PATH_NAME.size() - 1)
	var key: String = "ven9_%d" % p
	var pn: String = GuData.PATH_NAME[p]
	var title: String = pn + (" Demon Venerable" if al == 1 else " Immortal Venerable")
	if cheats.is_on("uniq") and fig_alive(key) != null:
		return "The " + title + " is already alive."
	if not cheats.room():
		return cheats.full_msg()
	var dup: String = cheats.fig_suffix(key)
	var u: Unit = mk_person(x, y, 0, 600.0 + randf() * 900.0)
	u.sur = ""
	u.given = pn + Venerables.EPITHET[randi() % Venerables.EPITHET.size()] + dup
	u.awk = true
	awaken(u, true)
	u.path = p
	u.align = al
	u.apt = "A"
	u.gus = PackedStringArray([Lore.start_gu(p)])
	for r: int in range(2, 10):
		ascend(u, r)
	u.title = title
	u.fig = key
	u.life = uage(u) + 3000.0 + randf() * 2000.0
	var own: Array[String] = []
	for e: Dictionary in Lore.IGU:
		if int(e["p"]) == p and int(e["r"]) >= 7 and not e.get("norand", false):
			own.append(str(e["id"]))
	if not own.is_empty():
		give_igu(u, own.pick_random())
	u.hp = u.mhp
	log_event("%s, the %s, descends – Supreme Grandmaster of the %s Path! The world trembles." % [u.given, title, pn], "gold", true)
	pillar(x, y, GuData.ESS_COL[9], 1.6)
	ring(x, y, 16.0, GuData.PATH_COL[p], 1.2)
	shake = 1.0
	ven.register(u, {})
	return ""


## Einflussgebiete der Ehrwürdigen für die Gebietsanzeige: [{name, title, col, x, y, r (Kacheln), region, path, clan, uid}].
func ven_dominions() -> Array:
	return ven.dominions()


## „Ära des <Pfad>-Pfades – <Name>“ des Höchsten (leer ohne Ehrwürdige).
func era_text() -> String:
	return ven.era_text()


## Benannte Figur aus der Geschichte (einzigartig). Gibt einen Hinweis zurück oder "".
func spawn_figure(fd: Dictionary, x: float, y: float) -> String:
	var nm: String = (str(fd["sur"]) + " " + str(fd["given"])).strip_edges()
	if cheats.is_on("uniq") and fig_alive(fd["id"]) != null:
		return nm + " is already alive."
	if not cheats.room():
		return cheats.full_msg()
	var dup: String = cheats.fig_suffix(str(fd["id"]))
	var rank: int = int(fd["r"])
	var u: Unit = mk_person(x, y, int(fd.get("race", 0)), float(fd["age"]), str(fd["sur"]))
	u.sur = fd["sur"]
	u.given = str(fd["given"]) + dup
	var oc: Clan = org_clan(str(fd["org"])) if str(fd["org"]) != "" else null
	if oc != null:
		var bv: Village = nearest_village(x, y, 9999.0, func(v: Village) -> bool: return v.clan == oc.id)
		if bv != null:
			join_village(u, bv)
	u.awk = true
	awaken(u, true)
	u.apt = fd["apt"]
	u.phys_x = u.apt == "X"
	u.path = int(fd["p"])
	u.align = int(fd["al"])
	u.gus = PackedStringArray([Lore.start_gu(u.path)])
	for r: int in range(2, rank + 1):
		ascend(u, r)
	u.fig = fd["id"]
	u.life = maxf(u.life, uage(u) + 40.0 + GuData.LIFEB[rank])
	if rank >= 6:
		u.next_trib = uage(u) + 10.0 + randf() * 10.0
	# Figuren der Handlung stehen meist weit oben in ihrem Rang (Herzog Long: Rang 8 Spitze = Quasi-Rang 9)
	u.stage = 3 if u.fig == "duke_long" else 1 + randi() % 3
	for id: Variant in fd["igu"]:
		give_igu(u, str(id))
	set_stats(u, true)
	u.hp = u.mhp
	pillar(x, y, GuData.ESS_COL[rank], 0.9)
	log_event(u.pname() + " enters the world (" + rank_title(rank) + (", " + oc.name if oc != null else "") + ").", "gold", true)
	return ""


# ---------------- Organisationen ----------------

## Gründet eine Organisation aus Lore.ORGS am Ort (x, y). Gibt einen Hinweis zurück oder "".
func found_org(o: Dictionary, x: float, y: float, quiet: bool = false) -> String:
	var nm: String = o["n"]
	var canon: bool = cheats.is_on("uniq")
	if canon and org_clan(o["id"]) != null:
		return nm + " already exists."
	if not world.in_map(int(x), int(y)):
		return ""
	var reg: int = region_at(x, y)
	var oreg: int = int(o.get("reg", -1))
	if canon and oreg >= 0 and reg != oreg:
		return nm + " belongs in " + GuData.REGN_DAT[oreg] + "."
	var tx: int = int(x)
	var ty: int = int(y)
	if not site_ok(tx, ty, -1):
		var s: Vector2 = find_site(x, y, 2.0, 22.0, reg)
		if s.x < 0.0:
			s = find_site(x, y, 2.0, 22.0, reg)
		if s.x < 0.0:
			return "There is no room here for " + nm + "."
		tx = int(s.x)
		ty = int(s.y)
	var race: int = int(o.get("race", 0))
	if race == -2:
		race = [1, 2, 4, 6].pick_random()
	var sur: String = str(o.get("sur", ""))
	if sur == "":
		sur = GuData.RACE_SUR[race].pick_random()[0] if race >= 4 else rand_sur(reg)
	var lr: int = int(o.get("lead", 4))
	var al: int = int(o.get("al", 0))
	var lead: Unit = mk_person(tx + 0.5, ty + 0.5, race, 30.0 + lr * 6.0, sur)
	lead.awk = true
	awaken(lead, true)
	lead.align = al
	for r: int in range(2, lr + 1):
		ascend(lead, r)
	lead.life = maxf(lead.life, uage(lead) + 40.0 + GuData.LIFEB[lr] * 0.5)
	var c: Clan = new_org_clan(o, reg)
	if not found_village(lead, c.id):
		lead.hp = 0.0
		c.alive = false
		return "There is no room here for " + nm + "."
	var v: Village = villages[lead.vil]
	var k: String = o["k"]
	if k == "Clan" and c.sur != "":
		v.name = c.sur.replace(" ", "-") + " Village"
	elif k == "Stamm" and c.sur != "":
		v.name = c.sur.replace(" ", "-") + " Camp"
	v.food = 30.0
	v.wood = 30.0
	v.stones = 25.0
	var elders: Array = {"Hof": [7, 6, 6], "Sekte": [5, 3, 3, 2], "Allianz": [5, 4, 3], "Clan": [3, 2, 2], "Stamm": [3, 2, 2]}.get(k, [2])
	if o["id"] == "heavenly_court":
		elders = [7, 7, 6, 6]
	for j: int in range(9):
		var u: Unit = mk_person(tx + (randf() - 0.5) * 6.0, ty + 2.0 + (randf() - 0.5) * 4.0, race, 6.0 if j == 0 else 16.0 + randf() * 20.0, sur)
		u.awk = j >= 1
		join_village(u, v)
		if j >= 1 and j - 1 < elders.size():
			awaken(u, true)
			u.align = al if randf() < 0.85 else 1 - al
			for r: int in range(2, int(elders[j - 1]) + 1):
				ascend(u, r)
			if u.rank >= 6:
				u.life = maxf(u.life, uage(u) + 200.0)
	if o.get("spring", false):
		for t: int in range(60):
			var sx: int = tx + randi_range(-10, 10)
			var sy: int = ty + randi_range(-8, 8)
			if not world.in_map(sx, sy):
				continue
			var si: int = sy * W + sx
			if GuData.is_land(world.tile[si]) and world.tile[si] != GuData.WALL and world.tile[si] != GuData.MOUNT and world.feat[si] == 0 and world.bmap[si] < 0 and absi(sx - tx) + absi(sy - ty) > 5:
				world.feat[si] = GuData.F_SPRING
				world.mark_area(sx, sy)
				v.spring = true
				break
	if o["id"] == "heavenly_court" and find_place("court") == null:
		add_place("court", tx + 0.5, ty - 16.0, true)
	if k == "Allianz":
		var n: int = 0
		for oc: Clan in clans:
			if n >= 3:
				break
			if oc.alive and oc != c and (oreg < 0 or oc.region == oreg) and not c.war.has(oc.id) and oc.align == c.align:
				oc.ally[c.id] = true
				c.ally[oc.id] = true
				n += 1
	log_event(("The " if k in ["Sekte", "Allianz", "Clan", "Stamm", "Hof"] else "") + nm + " is founded in " + v.name + " (" + GuData.REGN[reg] + ").", "jade", not quiet)
	terr_dirty = true
	return ""


## Krieg Rechtschaffen gegen Dämonisch: alle rechtschaffenen Clans gegen alle dämonischen.
func rd_war() -> String:
	var tally: Dictionary = {}
	for u: Unit in units:
		if u.k == "p" and u.hp > 0.0 and u.rank > 0 and u.clan >= 0:
			tally[u.clan] = int(tally.get(u.clan, 0)) + (1 if u.align == 1 else -1)
	var good: Array[Clan] = []
	var bad: Array[Clan] = []
	for c: Clan in clans:
		if not c.alive:
			continue
		if c.align == 1 or int(tally.get(c.id, 0)) > 0:
			c.align = 1
			bad.append(c)
		else:
			good.append(c)
	if bad.is_empty() and good.size() >= 2:
		good.shuffle()
		for k: int in range(maxi(1, good.size() / 3)):
			var c2: Clan = good.pop_back()
			c2.align = 1
			bad.append(c2)
			log_event(c2.name + " turns to the demonic path.", "war")
	if bad.is_empty() or good.is_empty():
		return "There are not enough clans for such a war."
	for a: Clan in good:
		for b: Clan in bad:
			a.ally.erase(b.id)
			b.ally.erase(a.id)
			declare_war(a, b, true)
	for a2: Clan in good:
		for b2: Clan in good:
			if a2 != b2:
				a2.war.erase(b2.id)
				a2.ally[b2.id] = true
	log_event("War between the righteous and demonic paths! %d righteous against %d demonic powers." % [good.size(), bad.size()], "war", true)
	return ""


## Fremdweltdämon: fremde Seele, lernt mehrere Pfade ohne Konflikt, kultiviert rasend schnell und wird von allen gejagt.
func ow_demon(x: float, y: float) -> Unit:
	var u: Unit = mk_person(x, y, 0, 16.0)
	u.awk = true
	awaken(u, true)
	u.ow = true
	u.apt = "A"
	u.title = "Otherworldly Demon"
	ascend(u, 2)
	ascend(u, 3)
	for k: int in range(3):
		var g: String = Lore.mgu(randi() % GuData.PATH_NAME.size())[0]
		if not u.gus.has(g):
			u.gus.append(g)
	set_stats(u, true)
	pillar(x, y, Color("#c04aff"), 1.0)
	log_event("An Otherworldly Demon appears: " + u.pname() + " – a foreign soul unknown to fate. All powers hunt him.", "war", true)
	return u


## Irdische Kalamität für einen Unsterblichen: Erdstöße um ihn, Bestehen gibt Dao-Male (Fortschritt).
func earthly_calamity(u: Unit) -> void:
	var nm: String = u.pname()
	for k: int in range(5):
		later(k * 0.2, func() -> void:
			if u.hp > 0.0:
				boom(u.x + (randf() - 0.5) * 14.0, u.y + (randf() - 0.5) * 14.0, 3.0, 40.0, {"ash": true, "burn": 0.2, "c": Color("#c9a46a")}))
	later(1.3, func() -> void:
		if u.hp <= 0.0:
			return
		var dies: bool = not u.notrib and u.prot <= sim_time and randf() < 0.04 + 0.03 * (u.rank - 6)
		if dies and use_fortune(u):
			dies = false
		if dies:
			u.dreason = "earthly calamity"
			u.hp = 0.0
			log_event(nm + " dies in an earthly calamity.", "red", true)
		else:
			u.prog = minf(0.99, u.prog + 0.25)
			float_txt(u, "+Dao marks", Color("#e8c070"))
			log_event(nm + " survives an earthly calamity and gains Dao marks.", "violet"))


# ---------------- Orte ----------------

func find_place(type: String) -> Place:
	for p: Place in places:
		if p.alive and p.type == type:
			return p
	return null


## Ort unter einem Tipp (null = keiner).
func place_at(x: float, y: float) -> Place:
	var best: Place = null
	var bd: float = 1e9
	for p: Place in places:
		if not p.alive:
			continue
		var d: float = Vector2(p.x - x, p.y - 2.0 - y).length()
		if d < maxf(5.0, Sprites.place_size(p.type) * 0.45) and d < bd:
			bd = d
			best = p
	return best


func unit_by_id(id: int) -> Unit:
	for u: Unit in units:
		if u.id == id and u.hp > 0.0:
			return u
	return null


func count_race(r: int) -> int:
	var n: int = 0
	for u: Unit in units:
		if u.k == "p" and u.hp > 0.0 and u.race == r:
			n += 1
	return n


## Prüft, ob ein Ort hier entstehen darf. "" = ja, sonst der Hinweis.
func place_ok(type: String, x: float, y: float) -> String:
	var D: Dictionary = Lore.PLACE[type]
	var nm: String = D["n"]
	if not world.in_map(int(x), int(y)):
		return ""
	var canon: bool = cheats.is_on("uniq")
	if canon and D.get("uniq", false) and find_place(type) != null:
		return nm + " already exists."
	var t: int = world.tile[int(y) * W + int(x)]
	if type == "palace":
		if t != GuData.DEEP and t != GuData.SHAL:
			return "The Dragon Palace must stand in the sea."
	elif not GuData.is_land(t) or t == GuData.WALL:
		return nm + " needs solid ground."
	if canon and type == "court" and region_at(x, y) != 4:
		return "Heavenly Court belongs in the Central Continent."
	for p: Place in places:
		if p.alive and Vector2(p.x - x, p.y - y).length() < (12.0 if canon else 4.0):
			return "Too close to " + p.name + "."
	return ""


func add_place(type: String, x: float, y: float, quiet: bool = false) -> Place:
	var p: Place = Place.new()
	p.id = next_pid
	next_pid += 1
	p.type = type
	p.x = x
	p.y = y
	p.born = sim_time
	p.name = str(Lore.PLACE[type]["n"]) + (cheats.place_suffix(type) if Lore.PLACE[type].get("uniq", false) else "")
	if type == "inherit":
		p.name = Lore.INHERIT_NAMES[randi() % Lore.INHERIT_NAMES.size()]
	var life: float = float(Lore.PLACE[type].get("life", 0.0))
	if life > 0.0:
		p.until = sim_time + life
	places.append(p)
	pillar(x, y, Color("#fff1c0"), 0.9)
	ring(x, y, Sprites.place_size(type) * 0.6, Color("#fff1c0"), 0.8)
	if not quiet:
		log_event(p.name + " appears in " + GuData.REGN_DAT[region_at(x, y)] + ".", "violet", true)
	if type == "court" and org_clan("heavenly_court") == null and not presim:
		found_org(Lore.org("heavenly_court"), x, y + 16.0, true)
	return p


func _boost(p: Place, f: float, minr: int, skip_demonic: bool) -> void:
	for u: Unit in near_units(p.x, p.y, p.radius()):
		if u.k == "p" and u.rank >= minr:
			if skip_demonic and (u.rogue or u.align == 1):
				continue
			u.pb = f
			u.pb_t = sim_time + 1.5


func _lure(p: Place, rmin: int, rmax: int) -> void:
	for u: Unit in near_units(p.x, p.y, p.lure()):
		if u.k == "p" and u.rank >= rmin and u.rank <= rmax and u.tgt == null and not u.has_col_target():
			u.lure_t = sim_time + 2.0
			u.lx = p.x + (randf() - 0.5) * 3.0
			u.ly = p.y + (randf() - 0.3) * 3.0


func place_month() -> void:
	if places.is_empty():
		return
	var i: int = places.size() - 1
	while i >= 0:
		var p: Place = places[i]
		if p.until > 0.0 and sim_time >= p.until:
			p.alive = false
			log_event(p.name + " fades away.", "violet")
		else:
			p.t += 1.0
			_place_tick(p)
		if not p.alive:
			places.remove_at(i)
		i -= 1


func _place_tick(p: Place) -> void:
	var r: float = p.radius()
	match p.type:
		"blessed", "grotto", "hu":
			var minr: int = 8 if p.type == "grotto" else 6
			if p.owner >= 0 and unit_by_id(p.owner) == null:
				p.owner = -1
				p.name = str(Lore.PLACE[p.type]["n"]) + " (ownerless)"
			if p.type == "hu" and not p.used:
				_lure(p, 5, 5)
				for u: Unit in near_units(p.x, p.y, 5.0):
					if u.k == "p" and u.rank == 5:
						ascend(u, 6)
						p.owner = u.id
						p.used = true
						log_event(u.pname() + " takes over " + p.name + " and becomes a Gu Immortal!", "gold", true)
						pillar(u.x, u.y, GuData.ESS_COL[6])
						break
			elif p.owner < 0:
				for u2: Unit in near_units(p.x, p.y, r):
					if u2.k == "p" and u2.rank >= minr:
						p.owner = u2.id
						p.name = u2.given + (" Grotto-Heaven" if p.type == "grotto" else " Blessed Land")
						log_event(u2.pname() + " takes possession of the " + str(Lore.PLACE[p.type]["n"]) + ": " + p.name + ".", "violet", true)
						break
			_boost(p, 3.0 if p.type == "grotto" else 2.0, 6, false)
			if p.type == "grotto":
				for v: Village in villages:
					if v.alive and Vector2(v.cx - p.x, v.cy - p.y).length() < 40.0:
						v.stones += 1.0
			if randf() < (0.03 if p.type == "grotto" else 0.012) and count_sp("wildimm") < 8:
				var g: Unit = spawn_wild_igu(p.x + (randf() - 0.5) * 10.0, p.y + 3.0 + randf() * 4.0)
				log_event("In " + p.name + " the Immortal Gu " + g.pname() + ".", "violet", true)
		"court":
			_boost(p, 2.0, 6, true)
			if randf() < 0.4:
				for u: Unit in near_units(p.x, p.y, r):
					if u.k == "p" and u.rank >= 2 and (u.rogue or u.ow or (u.align == 1 and u.rank >= 6)):
						bolt(u.x, u.y, 600.0 + u.mhp * 0.3, false)
						ring(u.x, u.y, 5.0, Color("#fff1c0"), 0.6)
						if randf() < 0.3:
							log_event("The Heaven Surveillance Tower punishes " + u.pname() + ".", "violet")
						break
			if randf() < 0.02 and count_sp("wildimm") < 8:
				spawn_wild_igu(p.x + (randf() - 0.5) * 12.0, p.y + 4.0 + randf() * 6.0)
		"langya":
			for u: Unit in near_units(p.x, p.y, r):
				if u.k == "p" and u.rank >= 1 and randf() < 0.05:
					var g2: String = gain_gu(u)
					if g2 != "":
						float_txt(u, "Swap: " + g2, Color("#e8c070"))
			for v: Village in villages:
				if v.alive and Vector2(v.cx - p.x, v.cy - p.y).length() < r:
					v.stones += 0.5
		"imperial":
			_lure(p, 2, 6)
			var near: Array[Unit] = []
			for u: Unit in near_units(p.x, p.y, r + 6.0):
				if u.k == "p" and u.rank >= 1:
					near.append(u)
			if int(p.t) % 12 == 0:
				var cs: Array[int] = []
				for u: Unit in near:
					if u.clan >= 0 and not cs.has(u.clan):
						cs.append(u.clan)
				if cs.size() >= 2:
					cs.shuffle()
					var a: Clan = clans[cs[0]]
					var b: Clan = clans[cs[1]]
					if not a.ally.has(b.id):
						log_event("Strife over " + p.name + "!", "war")
						declare_war(a, b)
			if int(p.t) % 18 == 0 and not near.is_empty():
				var w: Unit = near.pick_random()
				stage_up(w)
				stage_up(w)
				gain_gu(w)
				log_event(w.pname() + " recovers a treasure in " + p.name + ".", "gold", true)
		"dream":
			_lure(p, 1, 8)
			for u: Unit in near_units(p.x, p.y, r):
				if u.k != "p" or u.rank <= 0:
					continue
				var safe: bool = (u.igf & F_DREAM) != 0 or u.path == 39
				if randf() < 0.55:
					u.prog += 0.35 * (2.0 if safe else 1.0)
					spark(u.x, u.y - 3.0, GuData.PATH_COL[39], 4, 3.0)
					if u.prog >= 1.0:
						u.prog = 0.0
						stage_up(u)
				elif not safe and randf() < 0.07:
					u.dreason = "soul damage in the dream realm"
					u.hp = 0.0
		"inherit":
			_lure(p, 2, 6)
			for u: Unit in near_units(p.x, p.y, r):
				if u.k != "p" or u.rank < 1:
					continue
				if randf() < 0.25:
					u.dreason = "trap in " + p.name
					u.hp = 0.0
					log_event(u.pname() + " walks into a deadly trap in " + p.name + ".", "red")
				else:
					if u.rank < 5:
						ascend(u, u.rank + 1)
						gain_gu(u)
						gain_gu(u)
					else:
						give_igu(u, Lore.igu_random())
					log_event(u.pname() + " opens " + p.name + " and receives its legacy.", "gold", true)
					pillar(p.x, p.y, Color("#ffe27a"), 0.8)
					p.alive = false
				break
		"fragment":
			_lure(p, 6, 9)
			for u: Unit in near_units(p.x, p.y, r):
				if u.k == "p" and u.rank >= 6:
					u.notrib = true
					u.hx = p.x
					u.hy = p.y
					log_event(u.pname() + " absorbs the heaven fragment – no tribulation strikes them any more, but they remain bound to it forever.", "violet", true)
					pillar(p.x, p.y, Color("#cfe0ff"), 1.0)
					p.alive = false
					break
		"palace":
			if randf() < 0.1 and count_race(6) < 40:
				for t: int in range(30):
					var lx2: float = p.x + (randf() - 0.5) * 50.0
					var ly2: float = p.y + (randf() - 0.5) * 50.0
					if not world.in_map(int(lx2), int(ly2)):
						continue
					var tt: int = world.tile[int(ly2) * W + int(lx2)]
					if GuData.buildable(tt):
						for j: int in range(3):
							var dm: Unit = mk_person(lx2 + (randf() - 0.5) * 3.0, ly2 + (randf() - 0.5) * 3.0, 6, 16.0 + randf() * 14.0)
							dm.awk = true
							if j == 0:
								awaken(dm, true)
								ascend(dm, 2)
						log_event("Dragon humans leave the Dragon Palace.", "info")
						break
		"mushroom":
			if (p.t <= 1.0 or int(p.t) % 12 == 0) and count_race(8) < 30:
				for j: int in range(4):
					var mx: float = p.x + (randf() - 0.5) * 10.0
					var my: float = p.y + 2.0 + (randf() - 0.5) * 6.0
					if world.in_map(int(mx), int(my)) and GuData.is_land(world.tile[int(my) * W + int(mx)]):
						var pm: Unit = mk_person(mx, my, 8, 14.0 + randf() * 10.0)
						pm.awk = randf() < 0.5
		"yitian":
			_lure(p, 4, 5)
			for u: Unit in near_units(p.x, p.y, r):
				if u.k == "p" and u.rank >= 4:
					u.duel_t = sim_time + 1.5
			if not p.used and p.t >= 24.0:
				spawn_wild_igu(p.x, p.y - 1.0, "sovereign_immortal_fetus")
				p.used = true
				log_event("The Sovereign Immortal Fetus Gu appears on Yi Tian Mountain!", "gold", true)
		"crazed":
			_lure(p, 7, 9)
			for u: Unit in near_units(p.x, p.y, r):
				if u.k == "p" and u.rank >= 7:
					u.duel_t = sim_time + 1.5


# =====================================================================
# Gottkräfte-Parität (WorldBox): Lava und Erdfeuer-Vulkane, Wirbel, Giftregen, Gu-Schwarm, Minen,
# Biom-Samen, Mordzug-Leiter, Schicksals-Münze, Leichen-Seuche, Besessenheit, Loyalität und Aufstände,
# Pläne, Straßen, zufällige Katastrophen
# =====================================================================

const _N4X: PackedInt32Array = [1, -1, 0, 0]
const _N4Y: PackedInt32Array = [0, 0, 1, -1]


## Seltene Zustände eines Wesens (Unit.fxm gesetzt): gehalten, fliegend, eingefroren, angesteckt, Merker.
## true = dieser Schritt ist für das Wesen beendet.
func _special(u: Unit, dt: float, t: int) -> bool:
	if u.held:
		return true
	if u.air > 0.0:
		_air_step(u, dt)
		return true
	var on: bool = false
	if u.bless != 0 or u.boat or u.poss or u.zin > 0.0 or u.prot > sim_time:
		_marks(u, dt, t)
		on = true
	if u.zin > 0.0 and sim_time >= u.zin and u.k == "p":
		raise_undead(u)
	if u.frz > sim_time:
		u.moving = false
		if randf() < dt * 3.0:
			parts.append({"x": u.x + (randf() - 0.5) * 2.0, "y": u.y - randf() * 3.0, "vx": 0.0, "vy": -0.5, "l": 0.5, "ml": 0.5, "c": Color("#d8f4ff"), "s": 0.6, "g": 0.0})
		return true
	if not on:
		u.fxm = false
	return false


## Sichtbare Merker über Wesen (Segen, Fluch, Himmelsschutz, Besessenheit, Ansteckung) und Boote.
func _marks(u: Unit, dt: float, t: int) -> void:
	if u.boat:
		if t <= GuData.SHAL:
			var bc: Color = Color("#7a4a26")
			for bx: float in [-1.6, -0.5, 0.6]:
				parts.append({"x": u.x + bx, "y": u.y - 0.7, "vx": 0.0, "vy": 0.0, "l": 0.09, "ml": 0.09, "c": bc, "s": 1.1, "g": 0.0})
			parts.append({"x": u.x - 0.6, "y": u.y - 0.1, "vx": 0.0, "vy": 0.0, "l": 0.09, "ml": 0.09, "c": bc.darkened(0.3), "s": 1.1, "g": 0.0})
		elif not u.has_col_target() and t != GuData.WALL:
			u.boat = false
	if randf() > dt * 3.0:
		return
	var c: Color
	if u.poss:
		c = Color("#c070ff")
	elif u.zin > 0.0:
		c = Color("#86e04a")
	elif u.bless > 0:
		c = Color("#ffe27a")
	elif u.bless < 0:
		c = Color("#5a2a6a")
	elif u.prot > sim_time:
		c = Color("#bfe8ff")
	else:
		return
	var down: bool = u.bless < 0 and not u.poss and u.zin <= 0.0
	parts.append({"x": u.x + (randf() - 0.5) * 2.0, "y": u.y - (5.0 if down else 6.5) - randf(), "vx": 0.0, "vy": 1.6 if down else -1.8, "l": 0.6, "ml": 0.6, "c": c, "s": 0.6, "g": 0.0})


## Durch die Luft geschleudert (Wirbel, Druckwelle): fliegt, landet mit Schaden.
func _air_step(u: Unit, dt: float) -> void:
	u.air -= dt
	var nx: float = clampf(u.x + u.kvx * dt, 0.5, W - 0.5)
	var ny: float = clampf(u.y + u.kvy * dt, 0.5, H - 0.5)
	if world.tile[int(ny) * W + int(nx)] == GuData.WALL and u.rank < 6:
		u.air = 0.0
	else:
		u.x = nx
		u.y = ny
	u.tx = u.x
	u.ty = u.y
	u.moving = true
	if randf() < 0.4:
		parts.append({"x": u.x, "y": u.y - 1.0, "vx": 0.0, "vy": 0.0, "l": 0.3, "ml": 0.3, "c": Color(0.85, 0.8, 0.7, 0.6), "s": 0.8, "g": 0.0})
	if u.air <= 0.0:
		u.air = 0.0
		hurt(u, 4.0 + u.mhp * 0.12, null)
		puff(u.x, u.y, Color("#c8b89a"), 3)


## Schleudert ein Wesen von (cx, cy) weg. Unsterbliche und Ödbestien stemmen sich dagegen.
func fling(u: Unit, cx: float, cy: float, pw: float, swirl: float = 0.0) -> void:
	if u.held or u.hp <= 0.0 or (u.k == "a" and u.rank >= 6):
		return
	var d: Vector2 = Vector2(u.x - cx, u.y - cy)
	if d.length() < 0.05:
		d = Vector2.from_angle(randf() * TAU)
	d = d.normalized()
	d = d.rotated(swirl)
	if u.rank >= 6:
		pw *= 0.25
	u.kvx = d.x * pw
	u.kvy = d.y * pw
	u.air = 0.12 + randf() * 0.12
	u.fxm = true
	u.tgt = null
	u.st = "idle"


## Ein Ort ohne Wasser, Wand und Lava? (für Katastrophen-Ziele)
func _solid(i: int) -> bool:
	var t: int = world.tile[i]
	return GuData.is_land(t) and t != GuData.WALL and t != GuData.LAVA


## Ändert das Gelände ohne Wasser-Neuberechnung (für viele kleine Änderungen wie erstarrende Lava im Meer).
func _raw_tile(i: int, t: int) -> void:
	world.tile[i] = t
	world.hgt[i] = maxf(world.hgt[i], GuData.DEFH[t])
	world.temp_snow[i] = 0
	world.feat[i] = 0
	world.mark_area(i % W, i / W)
	_after_set_tile(i)


## Taut zugefrorenes Wasser oder Schnee auf (Frostodem, Sonnenstrahl).
func thaw(i: int) -> void:
	if world.tile[i] == GuData.SNOW and world.temp_snow[i] > 0:
		world.tile[i] = world.temp_snow[i] - 1
		world.temp_snow[i] = 0
		world.mark_dirty(i % W, i / W)
		_after_set_tile(i)
	elif world.tile[i] == GuData.SNOW:
		set_tile(i, land_for(i))


# ---------------- Lava und Erdfeuer-Vulkan ----------------

func set_lava(j: int, h: float) -> void:
	var t: int = world.tile[j]
	if t == GuData.WALL:
		return
	if GuData.is_water(t) or (t == GuData.SNOW and world.temp_snow[j] in [1, 2]):
		_raw_tile(j, GuData.HILL)
		return
	if t != GuData.LAVA:
		if GuData.is_tree(world.feat[j]):
			ignite(j, 1.0)
		world.tile[j] = GuData.LAVA
		world.temp_snow[j] = 0
		world.feat[j] = 0
		fire.erase(j)
		world.mark_area(j % W, j / W)
		_after_set_tile(j)
	lava[j] = maxf(float(lava.get(j, 0.0)), h)


## Lava erkaltet zu dunklem Fels (Hügel, manchmal mit Felsbrocken).
func cool_lava(i: int) -> void:
	lava.erase(i)
	if world.tile[i] != GuData.LAVA:
		return
	set_tile(i, GuData.HILL)
	if randf() < 0.12:
		world.feat[i] = GuData.F_ROCK
	if randf() < 0.1:
		puff(i % W + 0.5, i / W, Color(0.5, 0.5, 0.5, 0.6), 1)


func lava_tick() -> void:
	var add: Dictionary = {}
	var cool: Array[int] = []
	var big: bool = lava.size() > 2400
	for i: int in lava.keys():
		var h: float = float(lava[i]) - 0.022
		var x: int = i % W
		var y: int = i / W
		if h > 0.3 and not big and randf() < 0.55:
			var k: int = randi() % 4
			var xx: int = x + _N4X[k]
			var yy: int = y + _N4Y[k]
			if world.in_map(xx, yy):
				var j: int = yy * W + xx
				var tj: int = world.tile[j]
				if tj != GuData.WALL and tj != GuData.LAVA and not add.has(j) and world.hgt[j] <= world.hgt[i] + 0.015:
					if GuData.is_water(tj):
						_raw_tile(j, GuData.HILL)
						for q: int in range(2):
							parts.append({"x": xx + randf(), "y": yy - randf(), "vx": (randf() - 0.5) * 2.0, "vy": -4.0, "l": 0.9, "ml": 0.9, "c": Color(0.92, 0.95, 1.0, 0.7), "s": 1.2, "g": 0.0})
						h -= 0.25
					else:
						add[j] = h * 0.85
						h -= 0.06
		if randf() < 0.06:
			var k2: int = randi() % 4
			var x2: int = x + _N4X[k2]
			var y2: int = y + _N4Y[k2]
			if world.in_map(x2, y2):
				ignite(y2 * W + x2, 1.0)
		if randf() < 0.012:
			parts.append({"x": x + randf(), "y": y, "vx": 0.0, "vy": -2.5, "l": 0.7, "ml": 0.7, "c": Color("#ffd27a"), "s": 0.6, "g": 0.0})
		if h <= 0.0:
			cool.append(i)
		else:
			lava[i] = h
	for i2: int in cool:
		cool_lava(i2)
	for j2: int in add.keys():
		set_lava(j2, add[j2])


## Erdfeuer-Vulkan: türmt einen Kegel auf und speit einige Monate lang Lava, Lavabomben, Asche und Rauch.
func volcano(x: float, y: float) -> void:
	var cx: int = clampi(int(x), 7, W - 8)
	var cy: int = clampi(int(y), 7, H - 8)
	for dy: int in range(-6, 7):
		for dx: int in range(-6, 7):
			var d: float = sqrt(float(dx * dx + dy * dy))
			if d > 6.4:
				continue
			var i: int = (cy + dy) * W + cx + dx
			var t: int = world.tile[i]
			if t == GuData.WALL:
				continue
			if d <= 1.5:
				if GuData.is_water(t):
					set_tile(i, GuData.HILL)
				set_lava(i, 2.5)
			elif d <= 3.6:
				set_tile(i, GuData.MOUNT)
				world.feat[i] = 0
			elif t != GuData.MOUNT:
				set_tile(i, GuData.HILL)
				if world.feat[i] != 0 and world.feat[i] != GuData.F_ORE:
					world.feat[i] = 0
			world.hgt[i] = 0.99 - d * 0.045
	volcs.append({"x": cx + 0.5, "y": cy + 0.5, "t": 6.0 + randf() * 3.0})
	shake = minf(1.2, shake + 0.8)
	ring(cx + 0.5, cy + 0.5, 10.0, Color("#ff7a2e"), 1.0)
	log_event("An earth-fire volcano erupts in " + GuData.REGN_DAT[region_at(x, y)] + "!", "war", true)


func _volc_tick(vo: Dictionary) -> void:
	vo["t"] = float(vo["t"]) - 0.15
	var x: float = vo["x"]
	var y: float = vo["y"]
	var cx: int = int(x)
	var cy: int = int(y)
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var i: int = (cy + dy) * W + cx + dx
			if world.tile[i] != GuData.WALL:
				set_lava(i, 2.2)
	# Lavabomben fliegen im Bogen und schlagen ein
	if randf() < 0.5:
		var a: float = randf() * TAU
		var d: float = 4.0 + randf() * 11.0
		var tx: float = x + cos(a) * d
		var ty: float = y + sin(a) * d * 0.8
		var T: float = 0.7
		parts.append({"x": x, "y": y - 3.0, "vx": (tx - x) / T, "vy": (ty - y + 3.0) / T - 15.0 * T, "l": T, "ml": T, "c": Color("#ff9a2a"), "s": 1.3, "g": 30.0})
		later(T, func() -> void:
			var ix: int = int(tx)
			var iy: int = int(ty)
			if world.in_map(ix, iy):
				boom(tx, ty, 1.8, 35.0, {"burn": 0.5, "c": Color("#ff7a2e")})
				set_lava(iy * W + ix, 0.9))
	for k: int in range(3):
		parts.append({"x": x + (randf() - 0.5) * 2.0, "y": y - 3.0, "vx": (randf() - 0.3) * 2.0, "vy": -5.0 - randf() * 4.0, "l": 2.2, "ml": 1.2, "c": Color(0.3, 0.27, 0.26, 0.7), "s": 2.0 + randf() * 1.5, "g": 0.0})
	spark(x, y - 2.0, Color("#ffb43a"), 2, 6.0)
	# Asche regnet auf das Umland
	var ai: int = clampi(int(y + (randf() - 0.5) * 24.0), 0, H - 1) * W + clampi(int(x + (randf() - 0.5) * 24.0), 0, W - 1)
	var at: int = world.tile[ai]
	if (at == GuData.GRASS or at == GuData.STEP or at == GuData.SOIL) and world.bmap[ai] < 0 and randf() < 0.5:
		world.tile[ai] = GuData.ASH
		if world.feat[ai] == GuData.F_TUFT or world.feat[ai] == GuData.F_FLOWER:
			world.feat[ai] = 0
		world.mark_area(ai % W, ai / W)
	if randf() < 0.1:
		shake = minf(0.5, shake + 0.2)


# ---------------- Wirbel, Giftregen, Minen ----------------

func tornado(x: float, y: float, quiet: bool = false) -> void:
	if storms.size() >= 5:
		storms.pop_front()
	storms.append({"x": x, "y": y, "a": randf() * TAU, "t": 4.0 + randf() * 2.0})
	if not quiet:
		log_event("A Wind Path whirlwind sweeps across " + GuData.REGN_IN[region_at(x, y)] + ".", "war", true)


func acid_rain(x: float, y: float, quiet: bool = false) -> void:
	if acids.size() >= 5:
		acids.pop_front()
	acids.append({"x": x, "y": y, "a": randf() * TAU, "t": 4.0})
	if not quiet:
		log_event("Poison rain of the Poison Path drifts across " + GuData.REGN_IN[region_at(x, y)] + ".", "war", true)


func add_mine(i: int) -> void:
	if mines.size() < 150 and not mines.has(i) and _solid(i):
		mines.append(i)


var _mine_acc: int = 0


func forces_step(dt: float) -> void:
	var k: int = storms.size() - 1
	while k >= 0:
		var s: Dictionary = storms[k]
		s["t"] = float(s["t"]) - dt
		s["a"] = float(s["a"]) + (randf() - 0.5) * dt * 8.0
		var x: float = float(s["x"]) + cos(float(s["a"])) * 7.0 * dt
		var y: float = float(s["y"]) + sin(float(s["a"])) * 7.0 * dt
		if float(s["t"]) <= 0.0 or x < 1 or y < 1 or x >= W - 1 or y >= H - 1:
			storms.remove_at(k)
			k -= 1
			continue
		s["x"] = x
		s["y"] = y
		_storm(x, y, dt)
		k -= 1
	k = acids.size() - 1
	while k >= 0:
		var c: Dictionary = acids[k]
		c["t"] = float(c["t"]) - dt
		c["a"] = float(c["a"]) + (randf() - 0.5) * dt * 2.0
		var ax: float = clampf(float(c["x"]) + cos(float(c["a"])) * 2.5 * dt, 2.0, W - 2.0)
		var ay: float = clampf(float(c["y"]) + sin(float(c["a"])) * 2.5 * dt, 2.0, H - 2.0)
		if float(c["t"]) <= 0.0:
			acids.remove_at(k)
			k -= 1
			continue
		c["x"] = ax
		c["y"] = ay
		_acid(ax, ay, dt)
		k -= 1
	if mines.is_empty():
		return
	_mine_acc += 1
	if _mine_acc % 2 != 0:
		return
	var mi: int = mines.size() - 1
	while mi >= 0:
		var i: int = mines[mi]
		var mx: float = i % W + 0.5
		var my: float = i / W + 0.5
		if randf() < 0.03:
			parts.append({"x": mx - 0.3, "y": my - 0.6, "vx": 0.0, "vy": 0.0, "l": 0.25, "ml": 0.25, "c": Color("#ff3a2a"), "s": 0.7, "g": 0.0})
		var hit: bool = not _solid(i)
		if not hit:
			for u: Unit in near_units(mx, my, 1.2):
				if not u.fly and not u.held and u.air <= 0.0:
					hit = true
					break
		if hit:
			mines.remove_at(mi)
			if _solid(i):
				boom(mx, my, 4.0, 160.0, {"burn": 0.3, "c": Color("#ffd27a")})
		mi -= 1


func _storm(x: float, y: float, dt: float) -> void:
	var tn: float = sim_time * 40.0
	var wet: bool = GuData.is_water(world.tile[int(y) * W + int(x)])
	# Trichter: je Höhenstufe ein kreisendes Teilchen, unten Staub (über Wasser Gischt)
	var h: float = 0.0
	while h < 19.0:
		var rad: float = 0.4 + h * h * 0.018 + h * 0.08
		var an: float = tn * (1.0 + h * 0.03) + h * 0.9 + randf() * 0.6
		var lite: bool = int(h * 2.0) % 3 != 0
		var col: Color = (Color(0.86, 0.94, 1.0, 0.95) if lite else Color(0.55, 0.7, 0.85, 0.95)) if wet else (Color(0.88, 0.89, 0.9, 0.95) if lite else Color(0.55, 0.57, 0.6, 0.95))
		if h < 3.0 and not wet:
			col = Color(0.62, 0.52, 0.38, 0.95)
		for side: float in [0.0, PI]:
			parts.append({"x": x + cos(an + side) * rad - 0.5, "y": y - h + sin(an + side) * rad * 0.2, "vx": -sin(an + side) * minf(rad, 3.0), "vy": 0.0, "l": 0.25, "ml": 0.12, "c": col, "s": 1.0 + h * 0.06, "g": 0.0})
		h += 1.2
	if randf() < 0.6:
		var a2: float = randf() * TAU
		parts.append({"x": x + cos(a2) * 2.5, "y": y + sin(a2) * 0.8, "vx": cos(a2) * 4.0, "vy": -1.0, "l": 0.5, "ml": 0.5, "c": Color(0.62, 0.52, 0.38, 0.8) if not wet else Color(0.86, 0.94, 1.0, 0.8), "s": 1.0, "g": 0.0})
	for u: Unit in near_units(x, y, 3.2):
		if u.air <= 0.0 and not u.held:
			fling(u, x, y, 45.0 + randf() * 35.0, 1.2)
			hurt(u, 3.0, null)
	for q2: int in range(3):
		var tx: int = int(x + (randf() - 0.5) * 6.0)
		var ty: int = int(y + (randf() - 0.5) * 6.0)
		if not world.in_map(tx, ty):
			continue
		var i: int = ty * W + tx
		var f: int = world.feat[i]
		if (GuData.is_tree(f) or f == GuData.F_SHRUB or f == GuData.F_TUFT or f == GuData.F_FLOWER) and randf() < 0.5:
			world.feat[i] = 0
			world.mark_area(tx, ty)
			for q3: int in range(3):
				parts.append({"x": tx + 0.5, "y": ty - 3.0, "vx": (randf() - 0.5) * 14.0, "vy": -6.0 - randf() * 6.0, "l": 0.8, "ml": 0.8, "c": Color("#5a8a32"), "s": 0.7, "g": 8.0})
		var bi: int = world.bmap[i]
		if bi >= 0 and buildings[bi] != null:
			buildings[bi].hp -= 260.0 * dt
			if buildings[bi].hp <= 0.0:
				remove_building(buildings[bi])
		if fire.has(i):
			ignite(clampi(i + (randi() % 3 - 1) * (1 + W * (randi() % 2)), 0, N - 1), 1.0)


func _acid(x: float, y: float, dt: float) -> void:
	# Wolke aus dicken Ballen, darunter grüner Regen
	for q: int in range(5):
		var cx: float = x + (randf() - 0.5) * 14.0
		var top: float = absf(cx - x) / 7.0
		parts.append({"x": cx, "y": y - 14.0 + top * 2.0 + (randf() - 0.5) * 2.5, "vx": 0.6, "vy": 0.0, "l": 0.7, "ml": 0.3, "c": Color(0.36, 0.42, 0.2, 0.95) if randf() < 0.6 else Color(0.62, 0.72, 0.3, 0.95), "s": 2.6 + randf() * 1.6, "g": 0.0})
	for q2: int in range(5):
		parts.append({"x": x + (randf() - 0.5) * 12.0, "y": y - 11.0, "vx": -1.0, "vy": 22.0, "l": 0.5, "ml": 0.25, "c": Color(0.7, 1.0, 0.3, 1.0), "s": 0.6, "g": 0.0})
	for q3: int in range(3):
		var tx: int = int(x + (randf() - 0.5) * 14.0)
		var ty: int = int(y + (randf() - 0.5) * 12.0)
		if not world.in_map(tx, ty):
			continue
		var i: int = ty * W + tx
		var t: int = world.tile[i]
		fire.erase(i)
		if (t == GuData.GRASS or t == GuData.STEP) and world.bmap[i] < 0 and randf() < 0.6:
			world.tile[i] = GuData.SOIL
			world.mark_dirty(tx, ty)
		var f: int = world.feat[i]
		if f != 0 and f != GuData.F_ORE and f != GuData.F_ROCK and f != GuData.F_SPRING and f != GuData.F_ROAD and randf() < 0.25:
			world.feat[i] = GuData.F_SHRUB if GuData.is_tree(f) and randf() < 0.4 else 0
			world.mark_area(tx, ty)
		var bi: int = world.bmap[i]
		if bi >= 0 and buildings[bi] != null:
			buildings[bi].hp -= 40.0 * dt
			if buildings[bi].hp <= 0.0:
				remove_building(buildings[bi])
	for u: Unit in near_units(x, y, 7.0):
		if u.beh == GuData.B_IGU:
			continue
		hurt(u, (2.5 + u.mhp * 0.06) * dt * (0.15 if u.rank >= 3 else 1.0), null)
		if u.hp <= 0.0 and u.k == "p" and u.dreason == "":
			u.dreason = "poison rain"


# ---------------- Verzehrender Gu-Schwarm, Biom-Samen ----------------

func goo_swarm(x: float, y: float) -> void:
	goo_left = mini(goo_left + 1400, 4000)
	var i0: int = clampi(int(y), 0, H - 1) * W + clampi(int(x), 0, W - 1)
	for k: int in range(5):
		goo.append({"i": clampi(i0 + randi_range(-2, 2) + randi_range(-2, 2) * W, 0, N - 1), "e": 4})
	log_event("A devouring Gu swarm hatches in " + GuData.REGN_DAT[region_at(x, y)] + " and consumes the land.", "war", true)


func _goo_tick() -> void:
	var nxt: Array[Dictionary] = []
	var seen: Dictionary = {}
	for c: Dictionary in goo:
		var i: int = c["i"]
		if not _solid(i) or goo_left <= 0:
			continue
		var x: int = i % W
		var y: int = i / W
		var t: int = world.tile[i]
		if t != GuData.ASH:
			set_tile(i, GuData.HILL if t == GuData.MOUNT else GuData.ASH)
			goo_left -= 1
		if world.feat[i] != 0:
			world.feat[i] = 0
			world.mark_area(x, y)
		var bi: int = world.bmap[i]
		if bi >= 0 and buildings[bi] != null:
			remove_building(buildings[bi])
		fire.erase(i)
		if randf() < 0.35:
			for u: Unit in near_units(x + 0.5, y + 0.5, 1.6):
				if u.beh != GuData.B_IGU:
					u.dreason = "devoured by a Gu swarm"
					hurt(u, 30.0 + u.mhp * 0.08, null)
		for q: int in range(2):
			parts.append({"x": x + randf(), "y": y + randf() - 0.5, "vx": (randf() - 0.5) * 3.0, "vy": (randf() - 0.5) * 3.0, "l": 0.35, "ml": 0.35, "c": Color("#3a1a4a") if q == 0 else Color("#8a5aa8"), "s": 0.6, "g": 0.0})
		var e: int = c["e"]
		if e <= 0:
			continue
		var kids: int = 1 + (1 if randf() < 0.45 else 0)
		for k: int in range(kids):
			var dx: int = randi_range(-1, 1)
			var dy: int = randi_range(-1, 1)
			if not world.in_map(x + dx, y + dy):
				continue
			var j: int = (y + dy) * W + x + dx
			if seen.has(j) or not _solid(j) or world.tile[j] == GuData.ASH:
				continue
			seen[j] = true
			nxt.append({"i": j, "e": e if randf() < 0.85 else e - 1})
	if nxt.size() > 260:
		nxt.shuffle()
		nxt.resize(260)
	goo = nxt
	if goo_left <= 0:
		goo.clear()


func plant_seed(x: float, y: float, tt: int) -> void:
	if seeds.size() >= 8:
		seeds.pop_front()
	seeds.append({"x": x, "y": y, "tt": tt, "r": 2.0, "n": 40})


func _seed_tick(sd: Dictionary) -> void:
	sd["n"] = int(sd["n"]) - 1
	var r: float = minf(15.0, float(sd["r"]) + 0.4)
	sd["r"] = r
	var tt: int = sd["tt"]
	var x: float = sd["x"]
	var y: float = sd["y"]
	for k: int in range(10):
		var a: float = randf() * TAU
		var d: float = sqrt(randf()) * r
		var tx: int = int(x + cos(a) * d)
		var ty: int = int(y + sin(a) * d)
		if not world.in_map(tx, ty):
			continue
		var i: int = ty * W + tx
		var t: int = world.tile[i]
		if not _solid(i) or t == GuData.MOUNT or (t == GuData.SAND and tt == GuData.GRASS):
			continue
		var f: int = world.feat[i]
		if t != tt and t != GuData.HILL:
			if tt == GuData.SNOW and world.bmap[i] < 0:
				world.temp_snow[i] = 0
				set_tile(i, GuData.SNOW)
			elif tt != GuData.SNOW:
				set_tile(i, tt)
		var q: float = randf()
		if tt == GuData.GRASS:
			if f == 0 and world.bmap[i] < 0 and q < 0.08:
				world.feat[i] = plant_for(i) if q < 0.05 else GuData.F_FLOWER
		elif tt == GuData.DES:
			if GuData.is_tree(f) and q < 0.5:
				world.feat[i] = GuData.F_SHRUB
			elif f == 0 and world.bmap[i] < 0 and q < 0.02:
				world.feat[i] = GuData.F_PALM if q < 0.01 else GuData.F_ROCK
		elif tt == GuData.SNOW:
			if GuData.is_tree(f) and f != GuData.F_PINE and q < 0.4:
				world.feat[i] = GuData.F_PINE
			elif f == 0 and world.bmap[i] < 0 and q < 0.04:
				world.feat[i] = GuData.F_PINE
		world.mark_area(tx, ty)
	if randf() < 0.6:
		var pc: Color = Color("#9affb0") if tt == GuData.GRASS else (Color("#ffe0a0") if tt == GuData.DES else Color("#ffffff"))
		spark(x + (randf() - 0.5) * r, y + (randf() - 0.5) * r, pc, 2, 2.0)


func nature_tick() -> void:
	if not lava.is_empty():
		lava_tick()
	var k: int = volcs.size() - 1
	while k >= 0:
		_volc_tick(volcs[k])
		if float(volcs[k]["t"]) <= 0.0:
			log_event("The earth-fire volcano falls quiet.", "info")
			volcs.remove_at(k)
		k -= 1
	if not goo.is_empty():
		_goo_tick()
	k = seeds.size() - 1
	while k >= 0:
		_seed_tick(seeds[k])
		if int(seeds[k]["n"]) <= 0:
			seeds.remove_at(k)
		k -= 1


# ---------------- Mordzug-Leiter (Bomben), Leere, Feuerregen, Schicksals-Münze ----------------

## Druckwelle: Wesen zwischen r0 und r1 werden fortgeschleudert, Bäume knicken, Gebäude bröckeln.
func shockwave(x: float, y: float, r0: float, r1: float, pw: float) -> void:
	for u: Unit in near_units(x, y, r1):
		var d: float = Vector2(u.x - x, u.y - y).length()
		if d < r0:
			continue
		var f: float = 1.0 - (d - r0) / maxf(1.0, r1 - r0)
		fling(u, x, y, pw * (0.4 + f))
		hurt(u, 8.0 + 30.0 * f, null)
	for ty: int in range(floori(y - r1), ceili(y + r1) + 1):
		for tx: int in range(floori(x - r1), ceili(x + r1) + 1):
			if not world.in_map(tx, ty):
				continue
			var d2: float = Vector2(tx + 0.5 - x, ty + 0.5 - y).length()
			if d2 < r0 or d2 > r1:
				continue
			var i: int = ty * W + tx
			var f2: float = 1.0 - (d2 - r0) / maxf(1.0, r1 - r0)
			if GuData.is_tree(world.feat[i]) and randf() < 0.55 * f2:
				world.feat[i] = 0
				world.mark_area(tx, ty)
			var bi: int = world.bmap[i]
			if bi >= 0 and buildings[bi] != null:
				buildings[bi].hp -= 120.0 * f2
				if buildings[bi].hp <= 0.0:
					remove_building(buildings[bi])
	ring(x, y, r1, Color(1, 1, 1, 0.9), 1.0)
	ring(x, y, (r0 + r1) * 0.5, Color("#ffe8b0"), 0.8)


## Pilzwolke aus Partikeln (Rang-8- und Ehrwürdigen-Mordzug).
func mushroom(x: float, y: float, sc: float) -> void:
	# Stamm: aufsteigende Glut, die zu Rauch wird
	for k: int in range(int(50 * sc)):
		var T: float = 1.6 + randf() * 1.2
		parts.append({"x": x + (randf() - 0.5) * 3.0 * sc, "y": y - randf() * 3.0, "vx": (randf() - 0.5) * 1.2, "vy": -(14.0 + randf() * 6.0) * sc / T, "l": T, "ml": T * 0.4, "c": Color("#ffb43a").lerp(Color("#5a4a44"), randf() * 0.8), "s": 1.5 + randf() * sc, "g": 0.0})
	# Hut: eine breite, wogende Wolke
	for k2: int in range(int(70 * sc)):
		var a: float = randf() * TAU
		var r: float = sqrt(randf())
		var T2: float = 2.2 + randf() * 1.4
		parts.append({"x": x + cos(a) * r * 11.0 * sc, "y": y - 20.0 * sc + sin(a) * r * 5.0 * sc, "vx": cos(a) * 2.0, "vy": -1.5, "l": T2, "ml": T2 * 0.4, "c": Color("#ffd27a").lerp(Color("#9a8a80"), r * 0.9 + randf() * 0.1), "s": 2.0 + randf() * 2.0 * sc, "g": 0.0})


## Mordzug-Leiter wie die WorldBox-Bomben: 0 Donnerkugel-Gu, 1 Rang-6-, 2 Rang-8-, 3 Ehrwürdigen-Mordzug.
func ladder_move(x: float, y: float, tier: int) -> void:
	match tier:
		0:
			boom(x, y, 3.5, 90.0, {"burn": 0.25, "c": Color("#fff27a")})
		1:
			fx.append({"k": "txt", "x": x, "y": y - 6.0, "t": "Rank 6 killer move", "c": GuData.ESS_COL[6], "l": 1.6, "ml": 1.6})
			pillar(x, y, GuData.ESS_COL[6], 0.6)
			later(0.35, func() -> void:
				boom(x, y, 8.0, 700.0, {"ash": true, "burn": 0.35, "c": GuData.ESS_COL[6]})
				shockwave(x, y, 8.0, 15.0, 35.0))
		2:
			fx.append({"k": "txt", "x": x, "y": y - 8.0, "t": "Rank 8 killer move", "c": GuData.ESS_COL[8], "l": 2.0, "ml": 2.0})
			pillar(x, y, GuData.ESS_COL[8], 1.2)
			ring(x, y, 18.0, GuData.ESS_COL[8], 0.6)
			later(0.6, func() -> void:
				boom(x, y, 17.0, 6000.0, {"ash": true, "lake": true, "burn": 0.5, "c": Color("#fff1d8")})
				shockwave(x, y, 17.0, 32.0, 55.0)
				flash(0.5)
				mushroom(x, y, 1.0)
				shake = 1.2
				log_event("A rank 8 killer move devastates " + GuData.REGN_IN[region_at(x, y)] + ".", "red", true))
		3:
			fx.append({"k": "txt", "x": x, "y": y - 10.0, "t": "Venerable killer move", "c": GuData.ESS_COL[9], "l": 2.4, "ml": 2.4})
			pillar(x, y, GuData.ESS_COL[9], 2.0)
			for k: int in range(3):
				ring(x, y, 34.0 - k * 9.0, GuData.ESS_COL[9], 0.9)
			later(0.9, func() -> void:
				boom(x, y, 32.0, 99999.0, {"ash": true, "lake": true, "burn": 0.6, "c": Color("#ffd24a")})
				shockwave(x, y, 32.0, 62.0, 80.0)
				flash(1.0)
				mushroom(x, y, 2.0)
				shake = 1.2
				log_event("A Venerable killer move wipes out part of " + ["the Northern Plains", "the Southern Border", "the Western Desert", "the Eastern Sea", "the Central Continent"][region_at(x, y)] + ".", "red", true))


## Raum-Pfad: Leere-Mordzug (Antimaterie) – alles im Umkreis wird vom Raum verschlungen, zurück bleibt Meer.
func void_move(x: float, y: float) -> void:
	var r: float = 13.0
	for k: int in range(70):
		var a: float = randf() * TAU
		var d: float = r * (1.2 + randf() * 0.5)
		parts.append({"x": x + cos(a) * d, "y": y + sin(a) * d, "vx": -cos(a) * d / 0.6, "vy": -sin(a) * d / 0.6, "l": 0.6, "ml": 0.6, "c": Color("#7c4dff") if k % 3 else Color("#e8e0ff"), "s": 1.0, "g": 0.0})
	ring(x, y, r * 1.5, Color("#7c4dff"), 0.6)
	later(0.6, func() -> void:
		for u: Unit in near_units(x, y, r):
			u.dreason = "swallowed by space"
			u.hp = 0.0
		for ty: int in range(floori(y - r), ceili(y + r) + 1):
			for tx: int in range(floori(x - r), ceili(x + r) + 1):
				if not world.in_map(tx, ty):
					continue
				var d2: float = Vector2(tx + 0.5 - x, ty + 0.5 - y).length()
				if d2 > r:
					continue
				var i: int = ty * W + tx
				if world.tile[i] == GuData.WALL:
					continue
				lava.erase(i)
				fire.erase(i)
				world.feat[i] = 0
				var bi: int = world.bmap[i]
				if bi >= 0 and buildings[bi] != null:
					remove_building(buildings[bi], true)
				set_tile(i, GuData.DEEP if d2 < r * 0.75 else GuData.SHAL)
		ring(x, y, r, Color("#2a1050"), 0.9)
		ring(x, y, r * 0.5, Color("#e8e0ff"), 0.6)
		spark(x, y, Color("#b39dff"), 40, 14.0)
		flash(0.35)
		shake = 1.0
		log_event("A void killer move of the Space Path tears a hole in " + GuData.REGN_IN[region_at(x, y)] + ".", "red", true))


## Feuerregen-Mordzug (Napalm): eine Reihe von Feuereinschlägen, die alles in Brand setzt.
func napalm(x: float, y: float) -> void:
	var a: float = randf() * TAU
	for k: int in range(9):
		var px: float = x + cos(a) * (k - 4) * 3.2
		var py: float = y + sin(a) * (k - 4) * 3.2
		parts.append({"x": px - 20.0, "y": py - 30.0, "vx": 20.0 / (0.1 + k * 0.08), "vy": 30.0 / (0.1 + k * 0.08), "l": 0.1 + k * 0.08, "ml": 0.1 + k * 0.08, "c": Color("#ff7a2e"), "s": 1.4, "g": 0.0})
		later(0.1 + k * 0.08, func() -> void:
			if not world.in_map(int(px), int(py)):
				return
			boom(px, py, 2.8, 60.0, {"burn": 1.0, "c": Color("#ff7a2e")})
			for dy: int in range(-3, 4):
				for dx: int in range(-3, 4):
					if dx * dx + dy * dy <= 9 and world.in_map(int(px) + dx, int(py) + dy):
						ignite((int(py) + dy) * W + int(px) + dx, 1.5))


## Schicksals-Münze: Das Schicksals-Gu entscheidet – die Hälfte aller Lebewesen stirbt. Gibt die Zahl der Toten zurück.
func fate_coin() -> int:
	var live: Array[Unit] = []
	for u: Unit in units:
		if u.hp > 0.0 and u.beh != GuData.B_IGU:
			live.append(u)
	live.shuffle()
	var n: int = live.size() / 2
	for k: int in range(n):
		var u2: Unit = live[k]
		u2.dreason = "Fate Coin"
		u2.hp = 0.0
		if k < 150:
			spark(u2.x, u2.y - 2.0, Color("#ffd24a"), 3, 3.0)
	flash(0.6)
	shake = 0.6
	log_event("The Fate Coin falls: the Fate Gu decides every life – %d of %d beings die." % [n, live.size()], "red", true)
	return n


## Erdkatastrophe (Erdbeben): Risse im Boden, Gebäude stürzen ein.
func quake(x: float, y: float) -> void:
	shake = 1.3
	ring(x, y, 18.0, Color("#c9a46a"), 1.1)
	ring(x, y, 10.0, Color("#c9a46a"), 0.8)
	for k: int in range(6):
		var cx: float = x
		var cy: float = y
		var a: float = randf() * TAU
		for s: int in range(26):
			cx += cos(a)
			cy += sin(a)
			a += (randf() - 0.5) * 0.6
			var tx: int = int(cx)
			var ty: int = int(cy)
			if not world.in_map(tx, ty):
				break
			var i: int = ty * W + tx
			var t: int = world.tile[i]
			if GuData.is_land(t) and t != GuData.WALL and t != GuData.LAVA:
				if t == GuData.HILL and randf() < 0.5:
					set_tile(i, GuData.MOUNT)
				elif t != GuData.MOUNT:
					set_tile(i, GuData.SOIL)
				if world.feat[i] != 0 and randf() < 0.6:
					world.feat[i] = 0
					world.mark_area(tx, ty)
	for b: Building in buildings:
		if b != null and Vector2(b.x + b.w / 2.0 - x, b.y + b.h / 2.0 - y).length() < 18.0:
			b.hp -= 120.0 if b.type == "hall" else 70.0
			if b.hp <= 0.0:
				remove_building(b)
	for u: Unit in near_units(x, y, 18.0):
		if not u.fly:
			hurt(u, 8.0, null)


# ---------------- Leichen-Seuche ----------------

func _make_undead(u: Unit) -> void:
	u.undead = true
	u.rogue = true
	u.vil = -1
	u.clan = -1
	u.job = ""
	u.st = "idle"
	u.militia = false
	u.col_to = Vector2(-1, -1)
	u.col_clan = -1
	u.boat = false
	u.zin = -1.0
	u.luck = 0.0
	u.bless = 0
	u.sick = 9999.0
	u.tgt = null
	u.life = uage(u) + 4.0 + randf() * 4.0
	set_stats(u, true)
	float_txt(u, "Walking Corpse", Color("#86e04a"))
	puff(u.x, u.y - 1.0, Color("#86e04a"), 4)


## Angesteckter Lebender verwandelt sich.
func raise_undead(u: Unit) -> void:
	if u.undead or u.rank >= 6:
		u.zin = -1.0
		return
	_make_undead(u)


## Ein Angesteckter stirbt und erhebt sich als Leiche. true = lebt (untot) weiter.
func rise_dead(u: Unit) -> bool:
	if u.k != "p" or u.undead or u.zin <= 0.0 or u.rank >= 6 or u.dreason in ["göttliche Auslöschung", "divine annihilation", "Fate Coin", "swallowed by space"]:
		return false
	u.dreason = ""
	_make_undead(u)
	return true


func undead_think(u: Unit) -> void:
	if u.tgt != null and u.tgt.hp > 0.0:
		return
	var e: Unit = nearest(u, 14.0, func(o: Unit) -> bool: return o.k == "p" and not o.undead)
	if e != null:
		u.tgt = e
		return
	if randf() < 0.35:
		var v: Village = nearest_village(u.x, u.y, 70.0)
		if v != null:
			go_to(u, v.cx + randf() * 8.0 - 4.0, v.cy + randf() * 6.0 - 3.0)
			return
	wander(u, 10.0)


# ---------------- Seelenbesitz ----------------

func set_possessed(u: Unit) -> void:
	if possessed != null:
		possessed.poss = false
	possessed = u
	if u != null:
		u.poss = true
		u.fxm = true
		u.st = "idle"
		u.tgt = null
		u.tx = u.x
		u.ty = u.y
		pillar(u.x, u.y, Color("#c070ff"), 0.5)


## Besessene Wesen denken nicht selbst; nur wer am Ziel steht, wehrt sich gegen Feinde in Reichweite.
func poss_think(u: Unit) -> void:
	if u.tgt != null or u.moving:
		return
	var e: Unit = nearest(u, maxf(u.rng, 3.0) + 2.0, func(o: Unit) -> bool: return hostile(u, o))
	if e != null:
		u.tgt = e


# ---------------- Pläne, Loyalität, Aufstände, Straßen ----------------

func has_plan(c: Clan, k: String, o: int) -> bool:
	for p: Dictionary in c.plans:
		if str(p["k"]) == k and int(p["o"]) == o:
			return true
	return false


## Ein Clan plant Krieg oder Bündnis und handelt erst nach einigen Monaten.
func add_plan(c: Clan, k: String, o: Clan, months: float) -> void:
	if c.plans.size() >= 4 or o == null or o == c:
		return
	c.plans.append({"k": k, "o": o.id, "t": sim_time + months, "s": sim_time})
	if not presim:
		if k == "war":
			log_event(c.name + " draws up war plans against " + o.name + ".", "war")
		else:
			log_event(c.name + " sends envoys to " + o.name + " – an alliance is being prepared.", "jade")


func run_plans(c: Clan) -> void:
	var i: int = c.plans.size() - 1
	while i >= 0:
		var p: Dictionary = c.plans[i]
		var oi: int = int(p["o"])
		var o: Clan = clans[oi] if oi >= 0 and oi < clans.size() else null
		var war: bool = str(p["k"]) == "war"
		var ok: bool = o != null and o.alive and o != c
		if ok:
			ok = (laws["war"] and not c.ally.has(oi) and not c.war.has(oi)) if war else (laws["diplo"] and not c.war.has(oi) and not c.ally.has(oi))
		if not ok:
			c.plans.remove_at(i)
		elif sim_time >= float(p["t"]):
			c.plans.remove_at(i)
			if war:
				declare_war(c, o)
			else:
				make_ally(c, o)
		i -= 1


const REBEL_MSG: PackedStringArray = [
	"The elders of %s complain that primeval stones flow only to the capital: the village breaks away from %s and becomes %s.",
	"Betrayal in %s! The Gu Masters renounce %s and found %s – the clan leader swears revenge.",
	"Far from the clan leader and weary of war, %s breaks away from %s. Henceforth %s rules there.",
]


## Ein Dorf sagt sich von seinem Clan los und gründet einen eigenen (mit Fehde gegen den alten Clan).
func rebel(v: Village) -> Clan:
	var c: Clan = clans[v.clan]
	var L: Unit = v.lead
	var sur: String = L.sur if (L != null and L.sur != "") else rand_sur(v.reg)
	var nc: Clan = new_clan(v.reg, sur, v.race)
	nc.align = L.align if (L != null and L.rank > 0) else c.align
	v.clan = nc.id
	nc.cap = v.id
	v.loy = 90.0
	v.capt = -999.0
	for u: Unit in units:
		if u.k == "p" and u.vil == v.id:
			u.clan = nc.id
			u.militia = false
	var msg: String
	if nc.align == 1 and c.align == 0:
		msg = "In %s, whispers of the demonic path spread: the village leaves %s and calls itself %s." % [v.name, c.name, nc.name]
	else:
		msg = REBEL_MSG[randi() % REBEL_MSG.size()] % [v.name, c.name, nc.name]
	log_event(msg, "war", true)
	declare_war(nc, c, true)
	terr_dirty = true
	return nc


## Monatlich: Loyalität jedes Dorfes (Entfernung zur Hauptstadt, Kriegsmüdigkeit, Stärke des Clan-Oberhaupts …) und Aufstände.
func loyalty_month() -> void:
	var nv: Dictionary = {}
	for v: Village in villages:
		if v.alive:
			nv[v.clan] = int(nv.get(v.clan, 0)) + 1
	var rebels: Array[Village] = []
	for v: Village in villages:
		if not v.alive:
			continue
		var c: Clan = clans[v.clan]
		if c.cap == v.id or c.cap < 0 or c.cap >= villages.size():
			v.loy = 100.0
			continue
		var cv: Village = villages[c.cap]
		var target: float = 82.0
		target -= minf(36.0, Vector2(v.cx - cv.cx, v.cy - cv.cy).length() * 0.3)
		target -= c.exh * 0.35
		target -= (int(nv.get(c.id, 1)) - 1) * 2.0
		var L: Unit = c.lead
		if L != null and L.hp > 0.0:
			target += L.rank * 3.5
		var vl: Unit = v.lead
		if vl != null and vl != L and vl.rank >= 3 and (L == null or vl.rank >= L.rank):
			target -= 15.0
		if sim_time - v.capt < 72.0:
			target -= 25.0
		if v.race != cv.race:
			target -= 8.0
		if v.reg != cv.reg:
			target -= 10.0
		if vl != null and vl.rank >= 2 and vl.align != c.align:
			target -= 8.0
		target = clampf(target, 0.0, 100.0)
		v.loy += (target - v.loy) * 0.15
		if laws["rebel"] and v.loy < 25.0 and int(nv.get(c.id, 1)) >= 2 and v.pop >= 3 and randf() < 0.025 + (25.0 - v.loy) * 0.002:
			rebels.append(v)
	for v2: Village in rebels:
		if v2.alive and int(nv.get(v2.clan, 1)) >= 2:
			nv[v2.clan] = int(nv.get(v2.clan, 1)) - 1
			rebel(v2)
	if randf() < 0.3:
		build_road()


## Straße von der Hauptstadt zu einem Dorf desselben Clans (Brücken über Wasser bleiben Lücken).
func build_road() -> void:
	var cands: Array[Village] = []
	for v: Village in villages:
		if v.alive and not v.road:
			var c: Clan = clans[v.clan]
			if c.cap >= 0 and c.cap != v.id and c.cap < villages.size() and villages[c.cap].alive and villages[c.cap].reg == v.reg:
				cands.append(v)
	if cands.is_empty():
		return
	var v2: Village = cands.pick_random()
	v2.road = true
	var cv: Village = villages[clans[v2.clan].cap]
	var a: Vector2 = Vector2(cv.cx, cv.cy + 3.0)
	var b: Vector2 = Vector2(v2.cx, v2.cy + 3.0)
	var d: float = a.distance_to(b)
	if d > 110.0 or d < 8.0:
		return
	var nrm: Vector2 = (b - a).orthogonal().normalized() * (randf() - 0.5) * d * 0.25
	var tiles: PackedInt32Array = PackedInt32Array()
	var last: int = -1
	var n: int = int(d * 2.5)
	for k: int in range(n + 1):
		var f: float = float(k) / n
		var p: Vector2 = a.lerp(b, f) + nrm * sin(f * PI)
		var tx: int = int(p.x)
		var ty: int = int(p.y)
		if not world.in_map(tx, ty):
			return
		var i: int = ty * W + tx
		if i == last:
			continue
		# 4er-Nachbarschaft: bei diagonalem Schritt eine Ecke einfügen
		if last >= 0 and last % W != tx and last / W != ty:
			var ci: int = (last / W) * W + tx
			if _road_ok(ci):
				tiles.append(ci)
		last = i
		if world.tile[i] == GuData.WALL:
			return
		if _road_ok(i):
			tiles.append(i)
	for i2: int in tiles:
		world.feat[i2] = GuData.F_ROAD
		world.mark_area(i2 % W, i2 / W)


func _road_ok(i: int) -> bool:
	var t: int = world.tile[i]
	if not GuData.buildable(t) and t != GuData.HILL:
		return false
	if world.bmap[i] >= 0 or world.temp_snow[i] in [1, 2]:
		return false
	var f: int = world.feat[i]
	return f == 0 or GuData.is_tree(f) or f == GuData.F_SHRUB or f == GuData.F_TUFT or f == GuData.F_FLOWER or f == GuData.F_ROAD


# ---------------- Zufällige Katastrophen (Weltgesetz „Katastrophen“) ----------------

func random_disaster() -> void:
	var opts: Array[String] = ["quake", "volcano", "tornado", "acid", "meteor", "plague", "dunes"]
	match opts.pick_random():
		"quake":
			var vs: Array[Village] = []
			for v: Village in villages:
				if v.alive:
					vs.append(v)
			var p: Vector2 = random_tile(_solid)
			if not vs.is_empty():
				var vv: Village = vs.pick_random()
				p = Vector2(clampf(vv.cx + randf_range(-15, 15), 1, W - 2), clampf(vv.cy + randf_range(-15, 15), 1, H - 2))
			if p.x >= 0.0:
				quake(p.x, p.y)
				log_event("Disaster: an earthquake shakes " + GuData.REGN_IN[region_at(p.x, p.y)] + ".", "war", true)
		"volcano":
			var p2: Vector2 = random_tile(func(i: int) -> bool: return (world.tile[i] == GuData.HILL or world.tile[i] == GuData.MOUNT) and i % W > 8 and i % W < W - 8 and i / W > 8 and i / W < H - 8, 200)
			if p2.x >= 0.0 and nearest_village(p2.x, p2.y, 16.0) == null:
				volcano(p2.x, p2.y)
		"tornado":
			var p3: Vector2 = random_tile(func(i: int) -> bool: return world.tile[i] == GuData.GRASS or world.tile[i] == GuData.STEP or world.tile[i] == GuData.DES, 200)
			if p3.x >= 0.0:
				tornado(p3.x, p3.y)
		"acid":
			var p4: Vector2 = random_tile(_solid, 200)
			if p4.x >= 0.0:
				acid_rain(p4.x, p4.y)
		"meteor":
			var p5: Vector2 = random_tile(_solid, 200)
			if p5.x >= 0.0:
				fx.append({"k": "met", "x": p5.x, "y": p5.y, "l": 0.7, "ml": 0.7, "big": false})
				later(0.7, func() -> void: boom(p5.x, p5.y, 9.0, 400.0, {"ash": true, "burn": 0.4, "c": Color("#ff9a3a")}))
				log_event("Disaster: a starfall strikes " + GuData.REGN_DAT[region_at(p5.x, p5.y)] + ".", "war", true)
		"plague":
			var ps: Array[Unit] = []
			for u: Unit in units:
				if u.k == "p" and u.hp > 0.0 and u.vil >= 0:
					ps.append(u)
			if not ps.is_empty():
				var pu: Unit = ps.pick_random()
				for o: Unit in near_units(pu.x, pu.y, 5.0):
					if o.k == "p":
						o.sick = 22.0 + randf() * 10.0
				log_event("Disaster: a plague breaks out in " + (villages[pu.vil].name if pu.vil >= 0 else "the wilderness") + ".", "war", true)
		"dunes":
			dune_migration()


## Dünenwanderung (Westwüste): Sand begräbt eine Oase.
func dune_migration() -> void:
	var p: Vector2 = random_tile(func(i: int) -> bool: return world.region[i] == 2 and world.tile[i] == GuData.GRASS, 400)
	if p.x < 0.0:
		return
	for dy: int in range(-10, 11):
		for dx: int in range(-10, 11):
			if dx * dx + dy * dy > 100:
				continue
			var tx: int = int(p.x) + dx
			var ty: int = int(p.y) + dy
			if not world.in_map(tx, ty):
				continue
			var i: int = ty * W + tx
			var t: int = world.tile[i]
			if (t == GuData.GRASS or t == GuData.SOIL) and world.region[i] == 2 and randf() < 0.8:
				set_tile(i, GuData.DES)
				if GuData.is_tree(world.feat[i]) and randf() < 0.6:
					world.feat[i] = GuData.F_SHRUB
	log_event("Disaster: the Impassable Dunes shift and bury an oasis of the Western Desert.", "war", true)


# =====================================================================
# Sandkasten: Regionen malen, Welt-Aktionen, Zeitalter frei wählen
# =====================================================================

## Meeresspiegel für „Welt fluten“ / „Kontinente heben“ (wie bei der Generierung: Höhe < 0,375 = Meer).
const SEA_H: float = 0.375
## Höhenänderung je Knopfdruck.
const SEA_STEP: float = 0.045


## Setzt die Region einer Kachel (Gras- und Baumfarben hängen davon ab). true = geändert.
func set_region(i: int, r: int) -> bool:
	if world.region[i] == r:
		return false
	world.region[i] = r
	if world.feat[i] != 0:
		world.mark_area(i % W, i / W)
	else:
		world.mark_dirty(i % W, i / W)
	return true


## Nach dem Umfärben von Regionen: Dörfer (und Clans über ihre Hauptstadt) gehören zur Region ihres Mittelpunkts.
func sync_village_regions() -> void:
	for v: Village in villages:
		if not v.alive:
			continue
		var r: int = region_at(v.cx, v.cy)
		if r == v.reg:
			continue
		v.reg = r
		var c: Clan = clans[v.clan]
		if c.cap == v.id:
			c.region = r
	terr_dirty = true


## Setzt das aktuelle Zeitalter (Anfang des Zeitalters k).
func set_age(k: int) -> void:
	k = clampi(k, 0, GuData.AGES.size() - 1)
	age_off = year() - 1 - k * GuData.AGE_YEARS
	log_event("Heaven turns the age: the " + str(age_data()["n"]) + " begins.", "violet", true)


## Geländewechsel ohne Höhenänderung (für die Welt-Aktionen; die Bilder werden danach ganz neu gezeichnet).
func _sb_set(i: int, t: int) -> void:
	if world.tile[i] == t:
		return
	world.tile[i] = t
	world.temp_snow[i] = 0
	var f: int = world.feat[i]
	if f != 0 and (GuData.is_water(t) or (t == GuData.MOUNT and GuData.is_tree(f))):
		world.feat[i] = 0
	if t != GuData.LAVA:
		lava.erase(i)
	_after_set_tile(i)


## Nach einer Welt-Aktion: Wasser neu einteilen, alles neu zeichnen, Ertrinkende sterben.
func _sb_finish() -> void:
	world.refresh_water()
	world.render_all()
	var mi: int = mines.size() - 1
	while mi >= 0:
		if not GuData.is_land(world.tile[mines[mi]]):
			mines.remove_at(mi)
		mi -= 1
	for u: Unit in units:
		if u.hp <= 0.0 or u.held:
			continue
		var tx: int = clampi(int(u.x), 0, W - 1)
		var ty: int = clampi(int(u.y), 0, H - 1)
		if not passable(u, tx, ty) and world.tile[ty * W + tx] != GuData.WALL:
			u.dreason = "drowned in the floods" if GuData.is_water(world.tile[ty * W + tx]) else "stranded on dry land"
			u.hp = 0.0
	for v: Village in villages:
		if v.alive:
			recount(v)
	terr_dirty = true


## „Alles Leben auslöschen“: alle Wesen, Dörfer, Clans und Gebäude verschwinden; Land, Orte und Naturgewalten bleiben.
func wipe_life() -> int:
	var n: int = 0
	for u: Unit in units:
		if u.hp > 0.0:
			n += 1
			if n < 300:
				spark(u.x, u.y - 1.0, Color.WHITE, 2, 3.0)
		u.hp = 0.0
		u.held = false
		u.tgt = null
		u.aggro = null
		u.dreason = "divine annihilation"
		unit_died.emit(u)
	units.clear()
	possessed = null
	for v: Village in villages:
		v.alive = false
		v.lead = null
	for c: Clan in clans:
		c.alive = false
		c.lead = null
		c.war.clear()
		c.ally.clear()
		c.plans.clear()
	villages.clear()
	clans.clear()
	buildings.clear()
	world.bmap.fill(-1)
	world.terr.fill(-1)
	projs.clear()
	sched.clear()
	sp_count.clear()
	wild_igu = 0
	for p: Place in places:
		p.owner = -1
	rebuild_grid()
	terr_dirty = true
	flash(0.5)
	shake = 0.5
	log_event("Heaven wipes out all life: %d beings, all villages and clans vanish. The world is empty." % n, "red", true)
	return n


## „Welt einebnen“: alles Land wird flaches Grasland (Nordebenen: Steppe); Wasser und Regionswände bleiben.
func flatten_world() -> int:
	var n: int = 0
	for i: int in range(N):
		var t: int = world.tile[i]
		if t == GuData.WALL or GuData.is_water(t):
			continue
		if t == GuData.SNOW and world.temp_snow[i] > 0:
			world.tile[i] = world.temp_snow[i] - 1
			world.temp_snow[i] = 0
			continue
		var nt: int = GuData.STEP if world.region[i] == 0 else GuData.GRASS
		if world.feat[i] == GuData.F_ROCK:
			world.feat[i] = 0
		# flach, aber Küsten bleiben etwas tiefer als das Landesinnere (damit „Welt fluten“ danach schrittweise wirkt)
		world.hgt[i] = clampf(lerpf(world.hgt[i], 0.5, 0.6), 0.42, 0.62)
		if t != nt:
			_sb_set(i, nt)
			n += 1
	_sb_finish()
	log_event("The world is levelled: mountains, hills, deserts and snow give way to flat land.", "gold", true)
	return n


## Abstand jeder Kachel zur anderen Seite der Küste (Land: zum Wasser, Wasser: zum Land), höchstens 12.
func _coast_dist() -> PackedByteArray:
	var d: PackedByteArray = PackedByteArray()
	d.resize(N)
	d.fill(255)
	var q: PackedInt32Array = PackedInt32Array()
	q.resize(N)
	var qt: int = 0
	var wet: PackedByteArray = PackedByteArray()
	wet.resize(N)
	for i: int in range(N):
		var t: int = world.tile[i]
		wet[i] = 1 if GuData.is_water(t) or (t == GuData.SNOW and world.temp_snow[i] > 0) else 0
	for i: int in range(N):
		var x: int = i % W
		var y: int = i / W
		var c: int = wet[i]
		if (x > 0 and wet[i - 1] != c) or (x < W - 1 and wet[i + 1] != c) or (y > 0 and wet[i - W] != c) or (y < H - 1 and wet[i + W] != c):
			d[i] = 1
			q[qt] = i
			qt += 1
	var qh: int = 0
	while qh < qt:
		var i2: int = q[qh]
		qh += 1
		var dd: int = d[i2]
		if dd >= 12:
			continue
		var x2: int = i2 % W
		var y2: int = i2 / W
		for j: int in [i2 - 1 if x2 > 0 else -1, i2 + 1 if x2 < W - 1 else -1, i2 - W if y2 > 0 else -1, i2 + W if y2 < H - 1 else -1]:
			if j >= 0 and d[j] == 255 and wet[j] == wet[i2]:
				d[j] = dd + 1
				q[qt] = j
				qt += 1
	return d


## „Welt fluten“ (dir = -1) bzw. „Kontinente heben“ (dir = 1): Das Meer frisst einige Kacheln Küste bzw. gibt sie frei,
## alle Höhen sinken bzw. steigen um eine Stufe; Gebirge werden zu Hügeln bzw. hohe Ebenen zu Hügeln und Hügel zu Gebirgen.
func shift_sea(dir: int) -> int:
	var n: int = 0
	var dh: float = SEA_STEP * dir
	var cd: PackedByteArray = _coast_dist()
	var salt: int = randi() % 1000
	for i: int in range(N):
		var t: int = world.tile[i]
		if t == GuData.WALL:
			continue
		var h: float = clampf(world.hgt[i] + dh, 0.0, 1.0)
		world.hgt[i] = h
		if t == GuData.SNOW and world.temp_snow[i] > 0:
			continue
		var band: bool = cd[i] <= 2 + int(GuData.hash2(i % W, i / W, salt) * 3.0)
		var nt: int = t
		if GuData.is_water(t):
			if dir > 0 and (band or h >= SEA_H):
				nt = GuData.SAND
				world.hgt[i] = maxf(h, SEA_H + 0.03)
		elif dir < 0:
			if band or h < SEA_H:
				nt = GuData.HILL if t == GuData.MOUNT else (GuData.SAND if t == GuData.HILL else GuData.SHAL)
				if nt == GuData.SHAL:
					world.hgt[i] = minf(h, SEA_H - 0.03)
			elif t == GuData.MOUNT and h < 0.74:
				nt = GuData.HILL
			elif t == GuData.HILL and h < 0.56:
				nt = land_for(i)
		else:
			if t == GuData.HILL and h >= 0.9:
				nt = GuData.MOUNT
			elif (t == GuData.GRASS or t == GuData.STEP or t == GuData.DES or t == GuData.SOIL) and h >= 0.8:
				nt = GuData.HILL
		if nt != t:
			_sb_set(i, nt)
			n += 1
	# Küsten neu: Land am Wasser wird Strand, Strand ohne Wasser in der Nähe wird wieder Land
	for i2: int in range(N):
		var t2: int = world.tile[i2]
		if not GuData.is_land(t2) or t2 == GuData.WALL:
			continue
		var x: int = i2 % W
		var y: int = i2 / W
		var coast: bool = (x > 0 and GuData.is_water(world.tile[i2 - 1])) or (x < W - 1 and GuData.is_water(world.tile[i2 + 1])) or (y > 0 and GuData.is_water(world.tile[i2 - W])) or (y < H - 1 and GuData.is_water(world.tile[i2 + W]))
		if coast and (t2 == GuData.GRASS or t2 == GuData.STEP or t2 == GuData.SOIL or t2 == GuData.ASH):
			_sb_set(i2, GuData.SAND)
		elif not coast and t2 == GuData.SAND and dir > 0:
			var near: bool = false
			for dy: int in range(-2, 3):
				for dx: int in range(-2, 3):
					if world.in_map(x + dx, y + dy) and GuData.is_water(world.tile[(y + dy) * W + x + dx]):
						near = true
			if not near:
				_sb_set(i2, land_for(i2))
	_sb_finish()
	if dir < 0:
		log_event("The seas rise and swallow the coasts (%d tiles)." % n, "war", true)
	else:
		log_event("The continents rise from the sea: %d tiles change." % n, "jade", true)
	return n
