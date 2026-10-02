class_name Venerables
extends RefCounted
## Rang-9-Ehrwürdige als Weltmacht: Pfad-Blüte (Ära des Pfades), Herrschaftsgebiete, Blutlinien, Vasallen und die
## Agenden der bekannten Ehrwürdigen (Lore.VEN: goal/seat/lin/court/ag). Dazu das Schicksals-Gu als Weltzustand.
## Zustand je Ehrwürdigem in `st` (Unit-Id -> Dictionary), gespeichert in Sim.serialize unter "ven" (ab Spielstand v5).

## Kartengröße (zur Laufzeit umstellbar, siehe GuData.set_size)
var W: int:
	get:
		return GuData.W
var H: int:
	get:
		return GuData.H
## Siegel neuer Blutlinien je Pfad (Index = Pfad-Id).
const PATH_GLYPH: String = "力月火水风雷木土血魂宙智骨金冰雪云光暗影星宇情魅运律幻禁天人气奴变炼阵毒剑刀兵梦虚盗食丹画信音杀"
const EPITHET: PackedStringArray = ["kaiser", "ahn", "fürst", "weiser", "herr", "souverän"]
const UNITE_MSG: PackedStringArray = ["Die Stämme der Nordebenen unterwerfen sich %s.", "Die Clans der Südgrenze beugen sich %s.",
	"Die Oasenclans der Westwüste huldigen %s.", "Die Inselclans des Ostmeers erkennen %s als Herrn an.", "Die Sekten des Zentralkontinents unterwerfen sich %s."]
const R_MIN: float = 30.0
const R_MAX: float = 110.0

var sim: Sim
var st: Dictionary = {}                 # Unit-Id -> Zustand (siehe register)
var fate_broken: bool = false           # das Schicksals-Gu wurde zerstört (gespeichert)
var fate_on: bool = false               # abgeleitet: irgendwo existiert ein Schicksals-Gu
var boost: PackedFloat32Array = PackedFloat32Array()   # Kultivierungsfaktor je Pfad (Pfad-Blüte)
var supreme: int = -1                   # Unit-Id des Höchsten (stärkster Ehrwürdiger)
var awk_paths: Dictionary = {}          # Statistik: Pfad -> erweckte Gu-Meister (nicht gespeichert)


func _init(s: Sim) -> void:
	sim = s
	boost.resize(GuData.PATH_NAME.size())
	boost.fill(1.0)


func reset() -> void:
	st.clear()
	fate_broken = false
	fate_on = false
	supreme = -1
	boost.fill(1.0)
	awk_paths.clear()


# ---------------- Abfragen ----------------

func any() -> bool:
	return not st.is_empty()


func state(u: Unit) -> Dictionary:
	return st.get(u.id, {})


func _clan(id: int) -> Clan:
	if id < 0 or id >= sim.clans.size():
		return null
	var c: Clan = sim.clans[id]
	return c if c.alive else null


func _vd(s: Dictionary) -> Dictionary:
	var vid: String = str(s.get("vid", ""))
	if vid == "":
		return {}
	for vd: Dictionary in Lore.VEN:
		if vd["id"] == vid:
			return vd
	return {}


func vname(u: Unit) -> String:
	return u.pname()


func radius(s: Dictionary) -> float:
	if float(s["sx"]) < 0.0 or str(s["ph"]) != "rule":
		return 14.0 if str(s["ph"]) == "travel" else 22.0
	# Herrschaftsgebiet wächst mit der Kartengröße mit (gleicher Anteil an der Welt)
	var k: float = GuData.len_f()
	return clampf((R_MIN + 3.0 * (sim.sim_time - float(s["seat_t"])) / 12.0) * k, R_MIN * k, R_MAX * k)


func col(s: Dictionary) -> Color:
	var vd: Dictionary = _vd(s)
	if not vd.is_empty():
		return Color(str(vd["col"]))
	return GuData.PATH_COL[clampi(int(s["p"]), 0, GuData.PATH_COL.size() - 1)]


## Kultivierungsfaktor der Pfad-Blüte.
func cult_mul(u: Unit) -> float:
	if u.path < 0 or u.path >= boost.size():
		return 1.0
	return boost[u.path]


## Rang 8 → 9: Das Schicksals-Gu legt die Schicksale fest, ohne es herrscht Chaos.
func ascend_mul() -> float:
	return 0.4 if fate_on else (1.6 if fate_broken else 1.0)


## Häufigkeit des Himmelswillens.
func will_mul() -> float:
	return 1.6 if fate_on else (0.6 if fate_broken else 1.0)


## Tödlichkeit des Himmelswillens.
func will_kill_mul() -> float:
	return 1.3 if fate_on else (0.7 if fate_broken else 1.0)


## Pfad eines neu erweckten Gu-Meisters: Die Pfade der Ehrwürdigen blühen (in ihrem Reich besonders).
func pick_path(cur: int, x: float, y: float) -> int:
	var p: int = cur
	if not st.is_empty():
		var rg: int = sim.region_at(x, y)
		var keys: Array = st.keys()
		keys.shuffle()
		for uid: int in keys:
			var s: Dictionary = st[uid]
			var w: float = 0.2 + (0.12 if uid == supreme else 0.0)
			if rg == int(s["goal"]) or (float(s["sx"]) >= 0.0 and Vector2(float(s["sx"]) - x, float(s["sy"]) - y).length() < radius(s)):
				w += 0.4
			if randf() < w:
				p = int(s["p"])
				break
	awk_paths[p] = int(awk_paths.get(p, 0)) + 1
	return p


func era_text() -> String:
	if supreme < 0 or not st.has(supreme):
		return ""
	var u: Unit = sim.unit_by_id(supreme)
	if u == null:
		return ""
	return "Ära des %s-Pfades – %s" % [GuData.PATH_NAME[clampi(u.path, 0, GuData.PATH_NAME.size() - 1)], u.pname()]


## Einflussgebiete aller lebenden Ehrwürdigen (für die Gebietsanzeige).
func dominions() -> Array:
	var out: Array = []
	for uid: int in st.keys():
		var s: Dictionary = st[uid]
		var u: Unit = sim.unit_by_id(uid)
		if u == null:
			continue
		var seated: bool = float(s["sx"]) >= 0.0 and str(s["ph"]) == "rule"
		var x: float = float(s["sx"]) if seated else u.x
		var y: float = float(s["sy"]) if seated else u.y
		out.append({"name": u.pname(), "title": u.title, "col": col(s), "x": x, "y": y, "r": radius(s),
			"region": int(s["goal"]) if seated else sim.region_at(u.x, u.y), "path": u.path, "clan": int(s["clan"]) if _clan(int(s["clan"])) != null else -1, "uid": uid})
	return out


## Ehrwürdiger, dem ein Clan als Blutlinie oder Vasall gehört (oder null).
func overlord_of(clan_id: int) -> Dictionary:
	for uid: int in st.keys():
		var s: Dictionary = st[uid]
		if int(s["clan"]) == clan_id:
			return {"uid": uid, "k": "lin"}
		if (s["vas"] as Array).has(clan_id):
			return {"uid": uid, "k": "vas"}
	return {}


func lineage_size(s: Dictionary) -> int:
	var cid: int = int(s["clan"])
	if _clan(cid) == null:
		return 0
	var n: int = 0
	for o: Unit in sim.units:
		if o.k == "p" and o.hp > 0.0 and o.clan == cid:
			n += 1
	return n


# ---------------- Anmelden ----------------

## Meldet einen Rang-9-Ehrwürdigen an (vd = Eintrag aus Lore.VEN, leer = eigener Pfad, Sitz in seiner Region).
func register(u: Unit, vd: Dictionary) -> void:
	if st.has(u.id):
		return
	var here: int = sim.region_at(u.x, u.y)
	var goal: int = int(vd.get("goal", here))
	if goal >= 0 and not _region_exists(goal):
		goal = here
	var s: Dictionary = {"uid": u.id, "vid": str(vd.get("id", "")), "ag": str(vd.get("ag", "generic")), "p": u.path, "al": u.align,
		"goal": goal, "sx": -1.0, "sy": -1.0, "ph": "roam" if goal < 0 else "travel", "clan": -1, "lin": str(vd.get("lin", "")),
		"court": str(vd.get("court", "")), "vas": [], "t": sim.sim_time + 6.0, "seat_t": sim.sim_time, "tgt": -1, "act": "",
		"doing": "", "united": false, "done": false, "abs": 0, "desc": 0, "feast": sim.sim_time + 60.0 + randf() * 36.0,
		"att": "Höchster Großmeister des %s-Pfades" % GuData.PATH_NAME[clampi(u.path, 0, GuData.PATH_NAME.size() - 1)]}
	st[u.id] = s
	var nm: String = u.pname()
	if goal < 0:
		s["doing"] = "Zieht umher und sucht die Stärksten"
		sim.log_event("%s zieht los, um die stärksten Wesen der Welt herauszufordern." % nm, "gold", true)
		return
	var p: Vector2 = _pick_seat(goal, str(vd.get("seat", "")), u, vd.is_empty())
	s["sx"] = p.x
	s["sy"] = p.y
	if goal != here:
		s["doing"] = "Zieht in " + GuData.REGN_IN[goal]
		sim.log_event("%s zieht in %s, um dort %s Sitz zu errichten." % [nm, GuData.REGN_IN[goal], "ihren" if u.fig == "star_constellation" else "seinen"], "gold", true)
	else:
		s["doing"] = "Errichtet den Sitz"


func _region_exists(r: int) -> bool:
	for k: int in range(0, GuData.N, 97):
		if sim.world.region[k] == r and GuData.is_land(sim.world.tile[k]) and sim.world.tile[k] != GuData.WALL:
			return true
	return false


func _region_center(r: int) -> Vector2:
	var sx: float = 0.0
	var sy: float = 0.0
	var n: int = 0
	var w: int = GuData.W
	var st: int = maxi(4, w / 64)
	for y: int in range(2, GuData.H, st):
		for x: int in range(2, w, st):
			var i: int = y * w + x
			if sim.world.region[i] == r and GuData.is_land(sim.world.tile[i]) and sim.world.tile[i] != GuData.WALL:
				sx += x
				sy += y
				n += 1
	return Vector2(sx / n, sy / n) if n > 0 else Vector2(-1, -1)


func _land_ok(i: int, r: int) -> bool:
	var t: int = sim.world.tile[i]
	return sim.world.region[i] == r and GuData.buildable(t) and t != GuData.SAND


func _pick_seat(goal: int, lm: String, u: Unit, near: bool) -> Vector2:
	if lm != "":
		var lp: Vector2 = sim._landmark(lm)
		if lp.x >= 0.0 and sim.region_at(lp.x, lp.y) == goal:
			return lp
	if near and sim.region_at(u.x, u.y) == goal:
		var s: Vector2 = sim.find_site(u.x, u.y, 0.0, 26.0, goal)
		return s if s.x >= 0.0 else Vector2(u.x, u.y)
	var c: Vector2 = _region_center(goal)
	var best: Vector2 = Vector2(-1, -1)
	var bd: float = 1e9
	for k: int in range(10):
		var p: Vector2 = sim.random_tile(func(i: int) -> bool: return _land_ok(i, goal) and sim.site_ok(i % W, i / W, goal), 300)
		if p.x < 0.0:
			continue
		var d: float = p.distance_to(c) if c.x >= 0.0 else 0.0
		if d < bd:
			bd = d
			best = p
	if best.x < 0.0:
		best = sim.random_tile(func(i: int) -> bool: return _land_ok(i, goal), 900)
	if best.x < 0.0:
		best = c if c.x >= 0.0 else Vector2(u.x, u.y)
	return best


# ---------------- Denken (aus Sim.think_p) ----------------

## true = der Ehrwürdige wurde gelenkt, think_p endet.
func think(u: Unit) -> bool:
	var s: Dictionary = st.get(u.id, {})
	if s.is_empty():
		return false
	var tg: int = int(s["tgt"])
	if tg >= 0:
		var o: Unit = sim.unit_by_id(tg)
		if o == null or o == u:
			s["tgt"] = -1
		else:
			u.st = "idle"
			if Vector2(o.x - u.x, o.y - u.y).length() < 3.0:
				_act(u, s, o)
			else:
				u.tgt = null
				sim.go_to(u, o.x, o.y)
			return true
	match str(s["ph"]):
		"travel":
			u.tgt = null
			u.st = "idle"
			var sx: float = float(s["sx"])
			var sy: float = float(s["sy"])
			if Vector2(sx - u.x, sy - u.y).length() < 4.0:
				establish(u, s)
			else:
				sim.go_to(u, sx, sy)
			return true
		"roam":
			if u.tgt != null:
				return true
			var e: Unit = sim.nearest(u, 24.0, func(o: Unit) -> bool: return sim.hostile(u, o))
			if e != null:
				u.tgt = e
			elif not u.moving or randf() < 0.05:
				var p: Vector2 = sim.random_tile(func(i: int) -> bool: return GuData.is_land(sim.world.tile[i]) and sim.world.tile[i] != GuData.WALL, 60)
				if p.x >= 0.0:
					sim.go_to(u, p.x, p.y)
			return true
		"rule":
			if u.vil >= 0:
				return false
			if u.tgt != null:
				return true
			var e2: Unit = sim.nearest(u, 22.0, func(o: Unit) -> bool: return sim.hostile(u, o))
			if e2 != null:
				u.tgt = e2
			elif randf() < 0.5:
				sim.wander_near(u, float(s["sx"]), float(s["sy"]), 10.0)
			return true
	return false


## Ankunft am Sitz: Blutlinie gründen oder übernehmen.
func establish(u: Unit, s: Dictionary) -> void:
	s["ph"] = "rule"
	s["seat_t"] = sim.sim_time
	s["t"] = sim.sim_time + 8.0 + randf() * 6.0
	var nm: String = u.pname()
	var goal: int = int(s["goal"])
	var lin: String = str(s["lin"])
	var ag: String = str(s["ag"])
	if ag == "order":
		s["doing"] = "Plant in der Abgeschiedenheit"
		sim.log_event("%s zieht sich in %s zurück und beginnt, die Welt zu ordnen." % [nm, GuData.REGN_IN[goal]], "gold", true)
		return
	var c: Clan = null
	if lin != "":
		var o: Dictionary = Lore.org(lin)
		c = sim.org_clan(lin)
		if c != null:
			var capv: Village = sim.villages[c.cap] if c.cap >= 0 and c.cap < sim.villages.size() and sim.villages[c.cap].alive else null
			if capv != null and capv.reg == goal and Vector2(capv.cx - float(s["sx"]), capv.cy - float(s["sy"])).length() < 60.0:
				sim.join_village(u, capv)
				_move_seat(u, s, capv)
				sim.log_event("%s nimmt Sitz in %s und erhebt %s zu %s Blutlinie." % [nm, capv.name, c.name, "ihrer" if u.fig == "star_constellation" else "seiner"], "gold", true)
			elif _found_here(u, s, c):
				c.cap = u.vil
				sim.log_event("%s verlegt den Sitz von %s nach %s (%s)." % [nm, c.name, sim.villages[u.vil].name, GuData.REGN[goal]], "gold", true)
			else:
				c = null
		elif not o.is_empty() and (int(o.get("reg", -1)) < 0 or int(o["reg"]) == goal):
			if sim.found_org(o, float(s["sx"]), float(s["sy"])) == "":
				c = sim.org_clan(lin)
				if c != null:
					var v: Village = sim.villages[c.cap] if c.cap >= 0 else null
					if v != null:
						sim.join_village(u, v)
						_move_seat(u, s, v)
					sim.log_event("%s gründet %s – %s Blutlinie herrscht nun über %s." % [nm, c.name, "ihre" if u.fig == "star_constellation" else "seine", GuData.REGN_IN[goal]], "gold", true)
	if c == null:
		c = _own_lineage(u, s)
	if c != null:
		s["clan"] = c.id
		c.align = u.align
		s["doing"] = "Herrscht über " + GuData.REGN_IN[goal]
	else:
		s["doing"] = "Herrscht allein über " + GuData.REGN_IN[goal]
	sim.terr_dirty = true


func _move_seat(u: Unit, s: Dictionary, v: Village) -> void:
	s["sx"] = v.cx
	s["sy"] = v.cy


## Gründet am Sitz ein Dorf des Clans c (true bei Erfolg); der Ehrwürdige springt dafür an einen freien Platz.
func _found_here(u: Unit, s: Dictionary, c: Clan) -> bool:
	var goal: int = int(s["goal"])
	var p: Vector2 = Vector2(float(s["sx"]), float(s["sy"]))
	if not sim.site_ok(int(p.x), int(p.y), goal):
		p = sim.find_site(p.x, p.y, 2.0, 30.0, goal)
	if p.x < 0.0:
		return false
	u.x = p.x
	u.y = p.y
	u.tx = p.x
	u.ty = p.y
	if not sim.found_village(u, c.id):
		return false
	var v: Village = sim.villages[u.vil]
	v.food = 30.0
	v.wood = 30.0
	v.stones = 25.0
	_move_seat(u, s, v)
	return true


## Eigene Blutlinie: neuer Clan, Stamm oder Sekte mit dem Ehrwürdigen als Ahnherrn.
func _own_lineage(u: Unit, s: Dictionary) -> Clan:
	var goal: int = int(s["goal"])
	var c: Clan = Clan.new()
	c.kind = "Stamm" if goal == 0 else ("Sekte" if goal == 4 else "Clan")
	var base: String = u.given if u.sur == "" else u.sur
	c.name = base.replace(" ", "-") + "-" + c.kind
	var pi: int = clampi(u.path, 0, PATH_GLYPH.length() - 1)
	c.glyph = PATH_GLYPH[pi]
	c.col = col(s)
	c.align = u.align
	c.sur = u.sur if u.sur != "" else sim.rand_sur(goal)
	c.id = sim.clans.size()
	c.born = sim.year()
	c.region = goal
	sim.clans.append(c)
	var ok: bool = _found_here(u, s, c)
	if not ok:
		# kein freier Platz: das nächste Dorf der Region unterwirft sich und wird Sitz der Linie
		var v: Village = sim.nearest_village(float(s["sx"]), float(s["sy"]), 60.0, func(vv: Village) -> bool: return vv.reg == goal)
		if v != null:
			absorb_village(v, c)
			sim.join_village(u, v)
			c.cap = v.id
			_move_seat(u, s, v)
			ok = true
	if not ok:
		c.alive = false
		sim.log_event("%s findet keinen Platz für eine Blutlinie und herrscht allein." % u.pname(), "violet")
		return null
	var v2: Village = sim.villages[u.vil]
	v2.name = base.replace(" ", "-") + "-" + ("Lager" if goal == 0 else ("Palast" if goal == 4 else "Sitz"))
	for k: int in range(5):
		var m: Unit = sim.mk_person(v2.cx + (randf() - 0.5) * 6.0, v2.cy + 2.0 + (randf() - 0.5) * 4.0, u.race, 18.0 + randf() * 30.0, c.sur)
		sim.join_village(m, v2)
		m.awk = true
		sim.awaken(m, true)
		m.align = u.align
		if randf() < 0.6:
			_set_path(m, u.path)
		for r: int in range(2, [5, 4, 3, 3, 2][k] + 1):
			sim.ascend(m, r)
	sim.log_event("%s begründet %s in %s (%s) – eine neue Blutlinie des %s-Pfades." % [u.pname(), c.name, v2.name, GuData.REGN[goal], GuData.PATH_NAME[pi]], "gold", true)
	return c


func _set_path(m: Unit, p: int) -> void:
	m.path = p
	m.gus = PackedStringArray([Lore.start_gu(p)])


## Ein Dorf wechselt ohne Krieg zum Clan c.
func absorb_village(v: Village, c: Clan) -> void:
	var oc: Clan = sim.clans[v.clan]
	if oc == c:
		return
	v.clan = c.id
	v.capt = sim.sim_time
	v.loy = 70.0
	if oc.cap == v.id:
		oc.cap = -1
	for o: Unit in sim.units:
		if o.k == "p" and o.vil == v.id:
			o.clan = c.id
			o.militia = false
	sim.terr_dirty = true


# ---------------- Monatlich / jährlich ----------------

func month() -> void:
	# Rang-9-Wesen ohne Zustand (natürlicher Aufstieg, alte Spielstände) anmelden, Tote entfernen
	var alive: Dictionary = {}
	var fate: bool = false
	for u: Unit in sim.units:
		if u.hp <= 0.0:
			continue
		if u.k == "a":
			if u.gname == "fate_gu":
				fate = true
			continue
		if u.igu.has("fate_gu"):
			fate = true
		if u.rank >= 9 and not u.undead:
			alive[u.id] = u
			if not st.has(u.id):
				register(u, _vd_for(u))
	fate_on = fate
	for uid: int in st.keys():
		if not alive.has(uid):
			st.erase(uid)
	boost.fill(1.0)
	var prev: int = supreme
	supreme = -1
	var best: float = -1.0
	for uid: int in st.keys():
		var u: Unit = alive[uid]
		var s: Dictionary = st[uid]
		s["p"] = u.path
		boost[clampi(u.path, 0, boost.size() - 1)] = maxf(boost[clampi(u.path, 0, boost.size() - 1)], 1.5)
		var pw: float = sim.power(u) * (1.15 if uid == prev else 1.0)   # der bisherige Höchste behält den Titel, bis ihn jemand klar übertrifft
		if pw > best:
			best = pw
			supreme = uid
		_vassals(s)
		if str(s["ag"]) == "farm" and str(s["ph"]) == "rule":
			_farm_month(u, s)
		if sim.sim_time >= float(s["t"]):
			s["t"] = sim.sim_time + 10.0 + randf() * 5.0
			agenda(u, s)
	if supreme >= 0:
		var su: Unit = alive[supreme]
		boost[clampi(su.path, 0, boost.size() - 1)] = 1.8


func _vd_for(u: Unit) -> Dictionary:
	for vd: Dictionary in Lore.VEN:
		if vd["fig"] == u.fig and u.fig != "" and (u.fig != "fang_yuan" or u.rank >= 9):
			return vd
	return {}


func yearly() -> void:
	if not sim.laws["will"] or sim.presim:
		return
	for uid: int in st.keys():
		if randf() < 0.025 * will_mul():
			var u: Unit = sim.unit_by_id(uid)
			if u != null:
				sim.heavens_will(u)
			return


func on_death(u: Unit) -> void:
	if u.k == "a":
		if u.gname == "fate_gu" and not u.caught:
			_fate_shatter("Das Schicksals-Gu zerbricht!")
		return
	if u.igu.has("fate_gu"):
		var g: Unit = sim.spawn_wild_igu(u.x, u.y, "fate_gu")
		g.hp = g.mhp
		sim.log_event("Das Schicksals-Gu entgleitet dem toten " + u.pname() + " und sucht einen neuen Hüter.", "violet", true)
	if not st.has(u.id):
		return
	var s: Dictionary = st[u.id]
	var vas: Array = s["vas"]
	var c: Clan = _clan(int(s["clan"]))
	if not vas.is_empty():
		sim.log_event("Mit %s endet die Ära des %s-Pfades – %d Vasallen sagen sich los." % [u.pname(), GuData.PATH_NAME[clampi(u.path, 0, GuData.PATH_NAME.size() - 1)], vas.size()], "red", true)
		for id: Variant in vas:
			var o: Clan = _clan(int(id))
			if o != null and c != null:
				o.ally.erase(c.id)
				c.ally.erase(o.id)
	if str(s["ag"]) == "inherit":
		sim.log_event("Der Rote Lotus ist gefallen – sein Erbe ruht auf dem Qing-Mao-Berg.", "red", true)
	st.erase(u.id)


func _fate_shatter(msg: String) -> void:
	fate_broken = true
	fate_on = false
	sim.log_event(msg + " Die Fesseln des Schicksals sind gesprengt – eine Ära des Chaos beginnt, und Rang 9 steht wieder offen.", "gold", true)
	sim.flash(0.6)
	sim.shake = 0.8


## Vasallen bleiben im Frieden mit der Blutlinie und untereinander.
func _vassals(s: Dictionary) -> void:
	var c: Clan = _clan(int(s["clan"]))
	var vas: Array = s["vas"]
	if c == null:
		vas.clear()
		return
	var keep: Array = []
	for id: Variant in vas:
		var o: Clan = _clan(int(id))
		if o != null and o != c:
			keep.append(o.id)
	s["vas"] = keep
	var grp: Array = keep.duplicate()
	grp.append(c.id)
	for id2: int in grp:
		var o2: Clan = sim.clans[id2]
		for id3: int in grp:
			if id3 != id2 and o2.war.has(id3):
				sim.make_peace(o2, sim.clans[id3], true)
		var np: Array = []
		for p: Dictionary in o2.plans:
			if not (str(p["k"]) == "war" and grp.has(int(p["o"]))):
				np.append(p)
		o2.plans = np


# ---------------- Agenden ----------------

func agenda(u: Unit, s: Dictionary) -> void:
	var ph: String = str(s["ph"])
	var ag: String = str(s["ag"])
	if ph == "travel":
		return
	if ph == "roam":
		_hunt(u, s)
		return
	var c: Clan = _clan(int(s["clan"]))
	if c == null and ag != "order" and int(s["clan"]) >= 0:
		s["clan"] = -1
		s["ph"] = "travel"   # Blutlinie untergegangen: neu gründen
		s["doing"] = "Gründet die Blutlinie neu"
		return
	if c != null:
		_subjugate(u, s, c)
	match ag:
		"descend":
			_descendants(u, s, 2 + randi() % 3, true)
			_court(u, s)
		"generic":
			if randf() < 0.45:
				_descendants(u, s, 1 + randi() % 2, false)
		"fate_guard":
			_fate_guard(u, s)
		"humans":
			_humans(u, s)
		"order":
			_order(u, s)
		"inherit":
			_inherit(u, s)
		"forest":
			_forest(u, s)
		"steal":
			_steal(u, s)
		"farm":
			_feast(u, s)
		"bless":
			_bless(u, s)
		"refine":
			_refine(u, s)
		"hunt":
			_hunt(u, s)


## Clans im Herrschaftsgebiet unterwerfen sich: schwache gehen in der Blutlinie auf, die übrigen werden Vasallen.
func _subjugate(u: Unit, s: Dictionary, c: Clan) -> void:
	var goal: int = int(s["goal"])
	var R: float = radius(s)
	var sx: float = float(s["sx"])
	var sy: float = float(s["sy"])
	var vas: Array = s["vas"]
	var inside: Dictionary = {}   # Clan-Id -> Zahl der Dörfer im Gebiet
	var total: Dictionary = {}
	for v: Village in sim.villages:
		if not v.alive:
			continue
		total[v.clan] = int(total.get(v.clan, 0)) + 1
		if v.reg == goal and Vector2(v.cx - sx, v.cy - sy).length() < R:
			inside[v.clan] = int(inside.get(v.clan, 0)) + 1
	var cands: Array[Clan] = []
	for id: int in inside.keys():
		var o: Clan = _clan(id)
		if o != null and o != c and not vas.has(id) and overlord_of(id).is_empty():
			cands.append(o)
	var nm: String = u.pname()
	if cands.is_empty():
		if not bool(s["united"]) and vas.size() + int(s["abs"]) >= 2:
			s["united"] = true
			sim.log_event(UNITE_MSG[clampi(goal, 0, 4)] % nm, "gold", true)
		return
	cands.shuffle()
	for k: int in range(mini(cands.size(), 1 + (1 if randf() < 0.4 else 0))):
		var o: Clan = cands[k]
		var strong: bool = o.lead != null and o.lead.hp > 0.0 and o.lead.rank >= 5
		if int(total.get(o.id, 0)) <= 1 and not strong and o.org == "" and randf() < 0.55:
			for v: Village in sim.villages:
				if v.alive and v.clan == o.id:
					absorb_village(v, c)
			s["abs"] = int(s["abs"]) + 1
			sim.log_event(("%s wird von %s unterworfen und geht in %s auf." if u.align == 1 else "%s unterwirft sich %s und geht in %s auf.") % [o.name, nm, c.name], "jade", true)
		else:
			sim.make_peace(c, o, true)
			c.ally[o.id] = true
			o.ally[c.id] = true
			vas.append(o.id)
			sim.log_event("%s beugt sich %s und wird Vasall von %s." % [o.name, nm, c.name], "jade", true)
	sim.terr_dirty = true


## Nachkommen des Ehrwürdigen in der Hauptstadt seiner Blutlinie.
func _descendants(u: Unit, s: Dictionary, n: int, lucky: bool) -> int:
	var c: Clan = _clan(int(s["clan"]))
	if c == null or sim.units.size() >= GuData.MAXU - 20:
		return 0
	var v: Village = sim.villages[c.cap] if c.cap >= 0 and c.cap < sim.villages.size() and sim.villages[c.cap].alive else null
	if v == null:
		return 0
	var sur: String = c.sur if c.sur != "" else u.sur
	for k: int in range(n):
		var kid: Unit = sim.mk_person(v.cx + (randf() - 0.5) * 6.0, v.cy + 2.0 + (randf() - 0.5) * 4.0, u.race, 15.0 + randf() * 6.0, sur)
		sim.join_village(kid, v)
		kid.awk = true
		sim.awaken(kid, true)
		kid.align = u.align
		if randf() < 0.65:
			_set_path(kid, u.path)
		kid.apt = "A" if randf() < 0.5 else "B"
		if lucky:
			kid.luck = 1.0
		for r: int in range(2, 2 + randi() % 3):
			sim.ascend(kid, r)
	s["desc"] = int(s["desc"]) + n
	if lucky:
		sim.log_event("%s zeugt neue Nachkommen (%s): %d Kinder erwachen mit goldenen Augen und Großem Glück." % [u.pname(), c.name, n], "gold", int(s["desc"]) <= n)
	return n


## Riesensonne: der Langlebigkeitshimmel als zweite Macht neben der Blutlinie.
func _court(u: Unit, s: Dictionary) -> void:
	var cid: String = str(s["court"])
	if cid == "" or bool(s["done"]) or sim.sim_time - float(s["seat_t"]) < 36.0:
		return
	var c: Clan = _clan(int(s["clan"]))
	var oc: Clan = sim.org_clan(cid)
	if oc == null:
		var p: Vector2 = sim.find_site(float(s["sx"]), float(s["sy"]), 30.0, 70.0, int(s["goal"]))
		if p.x < 0.0 or sim.found_org(Lore.org(cid), p.x, p.y) != "":
			return
		oc = sim.org_clan(cid)
		if oc == null:
			return
		sim.log_event("%s ruft %s ins Leben – %s Nachkommen sollen ewig leben." % [u.pname(), oc.name, "ihre" if u.fig == "star_constellation" else "seine"], "gold", true)
	s["done"] = true
	if c != null and oc != c and not (s["vas"] as Array).has(oc.id):
		sim.make_peace(c, oc, true)
		c.ally[oc.id] = true
		oc.ally[c.id] = true
		(s["vas"] as Array).append(oc.id)


## Sternbild: hütet das Schicksals-Gu und bekämpft dämonische Ehrwürdige.
func _fate_guard(u: Unit, s: Dictionary) -> void:
	s["doing"] = "Hütet " + ("das Schicksals-Gu" if fate_on else "den Himmelshof")
	if fate_on and not u.igu.has("fate_gu"):
		for o: Unit in sim.units:
			if o.hp > 0.0 and ((o.k == "a" and o.gname == "fate_gu") or (o.k == "p" and o.igu.has("fate_gu"))):
				s["tgt"] = o.id
				s["act"] = "duel" if o.k == "p" and o.rank >= 9 and o.align == 1 else "catch"
				s["doing"] = "Holt das Schicksals-Gu in ihre Obhut"
				return
	var c: Clan = _clan(int(s["clan"]))
	for uid: int in st.keys():
		var s2: Dictionary = st[uid]
		if uid == u.id or int(s2["al"]) != 1:
			continue
		var c2: Clan = _clan(int(s2["clan"]))
		if c != null and c2 != null and not c.war.has(c2.id):
			sim.declare_war(c, c2)
		var o2: Unit = sim.unit_by_id(uid)
		if o2 != null and Vector2(o2.x - float(s["sx"]), o2.y - float(s["sy"])).length() < radius(s):
			s["tgt"] = uid
			s["act"] = "duel"
			s["doing"] = "Stellt " + o2.pname()
			return
	for m: Unit in sim.units:
		if m.k == "p" and m.hp > 0.0 and c != null and m.clan == c.id and m.rank >= 1 and m.rank < 9:
			m.prog = minf(0.99, m.prog + 0.05)


## Urursprung: Menschen herrschen über die Variant-Menschen.
func _humans(u: Unit, s: Dictionary) -> void:
	var c: Clan = _clan(int(s["clan"]))
	s["doing"] = "Erhebt die Menschheit über die Variant-Menschen"
	var R: float = radius(s) * 1.4
	var vs: Array[Village] = []
	for v: Village in sim.villages:
		if v.alive and v.race != 0 and Vector2(v.cx - float(s["sx"]), v.cy - float(s["sy"])).length() < R and (c == null or v.clan != c.id):
			vs.append(v)
	if vs.is_empty():
		return
	var v2: Village = vs.pick_random()
	if c != null and randf() < 0.5:
		absorb_village(v2, c)
		sim.log_event("Die %s von %s unterwerfen sich %s und dienen nun der Menschheit." % [GuData.RACE_PL[v2.race], v2.name, u.pname()], "jade", true)
	else:
		var n: int = 0
		for o: Unit in sim.units:
			if n < 3 and o.k == "p" and o.hp > 0.0 and o.vil == v2.id and o.rank == 0:
				o.dreason = "vertrieben"
				o.hp = 0.0
				n += 1
		v2.food *= 0.5
		sim.log_event("Die %s von %s weichen vor der Macht der Menschen zurück." % [GuData.RACE_PL[v2.race], v2.name], "war")


## Grenzenlos: In seinem Reich herrscht Ordnung – Fehden enden.
func _order(u: Unit, s: Dictionary) -> void:
	s["doing"] = "Ordnet die Welt nach seinen Regeln"
	var R: float = radius(s)
	var done: Dictionary = {}
	var n: int = 0
	for v: Village in sim.villages:
		if not v.alive or done.has(v.clan) or Vector2(v.cx - float(s["sx"]), v.cy - float(s["sy"])).length() > R:
			continue
		done[v.clan] = true
		var c: Clan = sim.clans[v.clan]
		for e: int in c.war.keys():
			sim.make_peace(c, sim.clans[e], true)
			n += 1
		c.plans.clear()
		c.calm = sim.sim_time + 24.0
	if n > 0:
		sim.log_event("Im Reich von %s herrschen Regel und Ordnung: %d Fehden enden auf einen Schlag." % [u.pname(), n], "jade", true)


## Roter Lotus: hinterlässt ein wahres Erbe auf dem Qing-Mao-Berg.
func _inherit(u: Unit, s: Dictionary) -> void:
	s["doing"] = "Bereitet sein wahres Erbe vor" if not bool(s["done"]) else "Wacht über sein Erbe"
	if bool(s["done"]) or sim.sim_time - float(s["seat_t"]) < 60.0:
		return
	var p: Vector2 = sim._landmark("Qing-Mao-Berg")
	if p.x < 0.0:
		p = Vector2(float(s["sx"]) + 6.0, float(s["sy"]) - 8.0)
	for k: int in range(12):
		var q: Vector2 = p + Vector2((randf() - 0.5) * 10.0, (randf() - 0.5) * 10.0) * float(k)
		if sim.place_ok("inherit", q.x, q.y) == "":
			var pl: Place = sim.add_place("inherit", q.x, q.y, true)
			pl.name = "Erbe des Roten Lotus"
			s["done"] = true
			sim.log_event("%s hinterlässt auf dem Qing-Mao-Berg ein wahres Erbe – es wartet auf einen würdigen Nachfahren." % u.pname(), "gold", true)
			return


## Ursprungslotus: Wälder breiten sich um seinen Sitz aus.
func _forest(u: Unit, s: Dictionary) -> void:
	s["doing"] = "Lässt Wälder wachsen"
	var R: float = radius(s)
	var n: int = 0
	for k: int in range(400):
		if n >= 70:
			break
		var a: float = randf() * TAU
		var d: float = 6.0 + randf() * R
		var x: int = int(float(s["sx"]) + cos(a) * d)
		var y: int = int(float(s["sy"]) + sin(a) * d)
		if not sim.world.in_map(x, y):
			continue
		var i: int = y * W + x
		var t: int = sim.world.tile[i]
		if (t == GuData.GRASS or t == GuData.STEP or t == GuData.SOIL) and sim.world.feat[i] == GuData.F_NONE and sim.world.bmap[i] < 0 and sim.village_at(x, y) == null:
			if t == GuData.SOIL:
				sim.set_tile(i, GuData.GRASS)
			sim.world.feat[i] = sim.plant_for(i)
			sim.world.mark_area(x, y)
			n += 1
	if n > 0 and not bool(s["done"]):
		s["done"] = true
		sim.log_event("Um den Sitz von %s sprießen Wälder – der Holzpfad blüht." % u.pname(), "jade", true)


## Himmelsdieb: stiehlt anderen Unsterblichen ihre Unsterblichen Gu.
func _steal(u: Unit, s: Dictionary) -> void:
	s["doing"] = "Späht nach fremden Unsterblichen Gu"
	if randf() > 0.35:
		return
	var c: int = int(s["clan"])
	var cands: Array[Unit] = []
	for o: Unit in sim.units:
		if o != u and o.k == "p" and o.hp > 0.0 and o.rank >= 6 and not o.igu.is_empty() and (c < 0 or o.clan != c) and (o.rank < 9 or randf() < 0.15):
			cands.append(o)
	if cands.is_empty():
		return
	var t: Unit = cands.pick_random()
	s["tgt"] = t.id
	s["act"] = "steal"
	s["doing"] = "Will " + t.pname() + " bestehlen"


## Geisterseele: Menschenfarmen wachsen schnell …
func _farm_month(u: Unit, s: Dictionary) -> void:
	var R: float = radius(s)
	for v: Village in sim.villages:
		if v.alive and v.reg == int(s["goal"]) and Vector2(v.cx - float(s["sx"]), v.cy - float(s["sy"])).length() < R:
			v.food += 1.2
			if v.pop < v.cap + 4 and sim.units.size() < GuData.MAXU - 20 and randf() < 0.12:
				var kid: Unit = sim.mk_person(v.cx + randf() * 2.0 - 1.0, v.cy + 2.5, v.race, 0.0, sim.pick_sur(v))
				sim.join_village(kid, v)


## … bis er ihre Seelen verschlingt.
func _feast(u: Unit, s: Dictionary) -> void:
	s["doing"] = "Mästet seine Menschenfarmen"
	if sim.sim_time < float(s["feast"]):
		return
	s["feast"] = sim.sim_time + 72.0 + randf() * 48.0
	var R: float = radius(s)
	var c: int = int(s["clan"])
	var n: int = 0
	for o: Unit in sim.units:
		if o.k != "p" or o.hp <= 0.0 or o.rank >= 6 or o.clan == c or o.vil < 0:
			continue
		var v: Village = sim.villages[o.vil]
		if v.reg == int(s["goal"]) and Vector2(v.cx - float(s["sx"]), v.cy - float(s["sy"])).length() < R and randf() < 0.4:
			o.dreason = "Seele verschlungen"
			o.hp = 0.0
			n += 1
			if n % 6 == 0:
				sim.spark(o.x, o.y - 1.0, GuData.PATH_COL[9], 3, 6.0)
	if n == 0:
		return
	u.life += n * 0.5
	u.atk *= 1.04
	u.hp = u.mhp
	sim.ring(u.x, u.y, 18.0, GuData.PATH_COL[9], 1.2)
	sim.pillar(u.x, u.y, GuData.PATH_COL[9], 1.2)
	sim.shake = 0.6
	sim.log_event("%s verschlingt die Seelen von %d Menschen aus seinen Menschenfarmen und wird noch mächtiger!" % [u.pname(), n], "red", true)


## Paradieserde: segnet Land und Dörfer, heilt Kranke.
func _bless(u: Unit, s: Dictionary) -> void:
	s["doing"] = "Segnet das Land"
	var R: float = radius(s)
	var sx: float = float(s["sx"])
	var sy: float = float(s["sy"])
	var nv: int = 0
	for v: Village in sim.villages:
		if v.alive and Vector2(v.cx - sx, v.cy - sy).length() < R:
			v.food += 15.0
			v.stones += 3.0
			nv += 1
	for o: Unit in sim.near_units(sx, sy, R):
		if o.k == "p":
			o.sick = 0.0
			o.hp = o.mhp
	var n: int = 0
	for k: int in range(300):
		if n >= 50:
			break
		var a: float = randf() * TAU
		var d: float = randf() * R
		var x: int = int(sx + cos(a) * d)
		var y: int = int(sy + sin(a) * d)
		if not sim.world.in_map(x, y):
			continue
		var i: int = y * W + x
		var t: int = sim.world.tile[i]
		if t == GuData.SOIL or t == GuData.ASH or t == GuData.DES:
			sim.set_tile(i, sim.land_for(i))
			n += 1
		elif (t == GuData.GRASS or t == GuData.STEP) and sim.world.feat[i] == GuData.F_NONE and sim.world.bmap[i] < 0 and randf() < 0.3:
			sim.world.feat[i] = GuData.F_FLOWER
			sim.world.mark_area(x, y)
			n += 1
	if nv > 0 and randf() < 0.35:
		sim.log_event("%s segnet das Land: %d Dörfer ernten reichlich, Kranke genesen, Blumen blühen." % [u.pname(), nv], "jade", true)


## Fang Yuan: veredelt Unsterbliche Gu und zerstört das Schicksals-Gu.
func _refine(u: Unit, s: Dictionary) -> void:
	s["doing"] = "Veredelt Unsterbliche Gu"
	if fate_on:
		for o: Unit in sim.units:
			if o.hp > 0.0 and o != u and ((o.k == "a" and o.gname == "fate_gu") or (o.k == "p" and o.igu.has("fate_gu"))):
				s["tgt"] = o.id
				s["act"] = "fate"
				s["doing"] = "Jagt das Schicksals-Gu"
				return
	if u.igu.has("fate_gu"):
		u.igu.remove_at(u.igu.find("fate_gu"))
		sim.apply_igu(u)
		_fate_shatter(u.pname() + " zerschmettert das Schicksals-Gu!")
		return
	if randf() < 0.5:
		var id: String = Lore.igu_random()
		var c: Clan = _clan(int(s["clan"]))
		var to: Unit = u
		if c != null:
			for m: Unit in sim.units:
				if m.k == "p" and m.hp > 0.0 and m.clan == c.id and m.rank >= 6 and m != u and randf() < 0.5:
					to = m
					break
		sim.give_igu(to, id)
		sim.spark(u.x, u.y - 2.0, GuData.PATH_COL[33], 12, 6.0)
		sim.log_event("%s veredelt das Unsterbliche Gu %s%s." % [u.pname(), Lore.igu_name(id), "" if to == u else " für " + to.pname()], "violet", true)


## Rücksichtsloser Wilder: jagt die stärksten Wesen der Welt.
func _hunt(u: Unit, s: Dictionary) -> void:
	s["doing"] = "Zieht umher"
	var best: Unit = null
	var bp: float = 0.0
	for o: Unit in sim.units:
		if o == u or o.hp <= 0.0:
			continue
		if (o.k == "p" and o.rank >= 7) or (o.k == "a" and o.rank >= 6 and o.beh != GuData.B_IGU and o.beh != GuData.B_GU):
			var pw: float = sim.power(o) * (0.6 + randf() * 0.8)
			if pw > bp:
				bp = pw
				best = o
	if best != null:
		s["tgt"] = best.id
		s["act"] = "duel"
		s["doing"] = "Jagt " + best.pname()


## Ziel erreicht: Aktion ausführen.
func _act(u: Unit, s: Dictionary, o: Unit) -> void:
	var act: String = str(s["act"])
	s["tgt"] = -1
	s["act"] = ""
	var nm: String = u.pname()
	match act:
		"duel":
			u.duel_t = sim.sim_time + 8.0
			o.duel_t = sim.sim_time + 8.0
			u.tgt = o
			o.tgt = u
			if str(s["ag"]) == "hunt":
				u.hp = minf(u.mhp, u.hp + u.mhp * 0.4)
				sim.float_txt(u, "Verwandlung!", GuData.PATH_COL[32])
				sim.ring(u.x, u.y, 8.0, GuData.PATH_COL[0], 0.8)
			sim.log_event("%s stellt %s zum Kampf!" % [nm, o.pname()], "war", true)
		"steal":
			if o.k != "p" or o.igu.is_empty():
				return
			var id: String = o.igu[randi() % o.igu.size()]
			o.igu.remove_at(o.igu.find(id))
			sim.apply_igu(o)
			sim.set_stats(o, false)
			sim.give_igu(u, id)
			sim.spark(o.x, o.y - 2.0, GuData.PATH_COL[41], 14, 6.0)
			sim.float_txt(u, "+" + Lore.igu_name(id), Color("#ffe27a"))
			sim.log_event("%s stiehlt %s aus der Blende von %s!" % [nm, Lore.igu_name(id), o.pname()], "violet", true)
		"fate":
			if o.k == "a" and o.gname == "fate_gu":
				o.caught = true
				o.hp = 0.0
			elif o.k == "p" and o.igu.has("fate_gu"):
				o.igu.remove_at(o.igu.find("fate_gu"))
				sim.apply_igu(o)
				sim.set_stats(o, false)
			else:
				return
			sim.pillar(o.x, o.y, GuData.PATH_COL[28], 1.4)
			_fate_shatter(nm + " zerschmettert das Schicksals-Gu!")
		"catch":
			if o.k == "a" and o.gname == "fate_gu":
				o.caught = true
				o.hp = 0.0
			elif o.k == "p" and o.igu.has("fate_gu"):
				o.igu.remove_at(o.igu.find("fate_gu"))
				sim.apply_igu(o)
				sim.set_stats(o, false)
			else:
				return
			sim.give_igu(u, "fate_gu")
			sim.pillar(o.x, o.y, GuData.PATH_COL[28], 1.0)
			sim.log_event("%s nimmt das Schicksals-Gu in ihre Obhut." % nm, "gold", true)


# ---------------- Inspektor ----------------

func unit_lines(u: Unit) -> String:
	var s: Dictionary = st.get(u.id, {})
	if s.is_empty():
		return ""
	var pn: String = GuData.PATH_NAME[clampi(u.path, 0, GuData.PATH_NAME.size() - 1)]
	var out: String = "\n[color=#ffd24a]%s[/color]" % str(s["att"])
	if u.id == supreme:
		out += "\n[color=#ffd24a]Der Höchste – Ära des %s-Pfades[/color] [color=#9db09e](Kultivierung +80 %%)[/color]" % pn
	else:
		out += "\n[color=#e8c070]Pfad-Blüte: %s-Pfad[/color] [color=#9db09e](Kultivierung +50 %%)[/color]" % pn
	if str(s["ph"]) == "rule":
		out += "\n[color=#9db09e]Herrschaft[/color]  %s · Umkreis %d · %d Vasallen" % [GuData.REGN[clampi(int(s["goal"]), 0, 4)], int(radius(s)), (s["vas"] as Array).size()]
	out += "\n[color=#9db09e]Ziel[/color]  " + str(s["doing"])
	var vd: Dictionary = _vd(s)
	if not vd.is_empty():
		out += "\n[color=#9db09e]Agenda[/color]  " + str(vd["agenda"])
	var c: Clan = _clan(int(s["clan"]))
	if c != null:
		out += "\n[color=#9db09e]Blutlinie[/color]  [color=#%s]■[/color] %s · %d Mitglieder%s" % [c.col.to_html(false), c.name, lineage_size(s), (" · %d Nachkommen gezeugt" % int(s["desc"])) if int(s["desc"]) > 0 else ""]
	return out


func village_line(clan_id: int) -> String:
	var o: Dictionary = overlord_of(clan_id)
	if o.is_empty():
		return ""
	var u: Unit = sim.unit_by_id(int(o["uid"]))
	if u == null:
		return ""
	return "[color=#9db09e]%s[/color]  [color=#ffd24a]%s[/color]\n" % ["Blutlinie von" if str(o["k"]) == "lin" else "Vasall von", u.pname()]


# ---------------- Speichern ----------------

func to_dict() -> Dictionary:
	return {"st": st.values(), "fb": fate_broken}


func from_dict(d: Dictionary) -> void:
	reset()
	fate_broken = bool(d.get("fb", false))
	for e: Variant in d.get("st", []):
		var s: Dictionary = (e as Dictionary).duplicate(true)
		for k: String in ["uid", "p", "al", "goal", "clan", "tgt", "abs", "desc"]:
			s[k] = int(s.get(k, -1))
		for k2: String in ["sx", "sy", "t", "seat_t", "feast"]:
			s[k2] = float(s.get(k2, -1.0))
		var vas: Array = []
		for id: Variant in s.get("vas", []):
			vas.append(int(id))
		s["vas"] = vas
		st[int(s["uid"])] = s
