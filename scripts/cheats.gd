class_name Cheats
extends RefCounted
## Cheats (`Sim.cheats`): globale Cheat-Schalter, Merker an Wesen (`Unit.ch`), Friedhof bemerkenswerter Toter,
## Zeitsprung in Häppchen und alle Eingriffe der Cheat-Werkzeuge (Rang, Pfad, Klonen, Wiederbeleben, Armeen …).
## Gespeichert in `Sim.serialize` unter dem optionalen Schlüssel "cheat" (fehlt er, gelten die Standardwerte).

const CH_IMM: int = 1    ## unsterblich: altert nicht, stirbt nicht an Alter, Drangsal, Himmelswille, Kalamität
const CH_INV: int = 2    ## unverwundbar: nimmt keinen Schaden und stirbt nur durch göttliche Auslöschung
const CH_LUCK: int = 4   ## ewiges Glück
const HARD_MAX: int = 3000   ## technische Obergrenze für Wesen (darüber wird nichts mehr gesetzt)
const MULTS: PackedInt32Array = [1, 5, 10, 50]
const GRAVE_MAX: int = 40
## Todesursachen, vor denen „Unsterblich“ schützt.
const IMM_SAVE: PackedStringArray = ["old age", "heavenly tribulation", "Heaven's Will", "earthly calamity", "failed ascension", "extreme physique", "starvation", "crumbled"]
## Globale Schalter für das Cheat-Menü: [Schlüssel, Name, Beschreibung]. „walls“ ist das Weltgesetz „Regionswände“ (umgekehrt).
const SWITCHES: Array = [
	["uniq", "Uniqueness", "On: canonical limits – every Venerable, figure, unique place and organization only once, organizations only in their region, places kept apart. Off (default): everything any number of times and anywhere."],
	["stones", "Infinite Primeval Essence", "Every village always has enough primeval stones – Gu Masters never cultivate at a slowed pace."],
	["res", "Infinite Supplies", "All villages always have full food, wood and primeval stones."],
	["cult10", "Instant Cultivation ×10", "All Gu Masters cultivate ten times as fast."],
	["notrib", "No Tribulations", "Immortals are no longer struck by tribulations; nobody dies of tribulation or Earthly Calamity."],
	["nowill", "Merciful Heaven's Will", "Heaven's Will still strikes, but kills no one."],
	["noage", "No Lifespan", "Nobody dies of old age or of an Extreme Physique."],
	["walls", "Open Region Walls", "Everyone can cross the region walls (world law “Region Walls” off)."],
	["freeze", "Freeze Beings", "All beings freeze in place; time keeps running (age, cultivation, villages)."],
]
const ROMAN: PackedStringArray = ["", "", " II", " III", " IV", " V", " VI", " VII", " VIII", " IX", " X"]

var sim: Sim
var flags: Dictionary = {"uniq": false, "stones": false, "res": false, "cult10": false, "notrib": false, "nowill": false, "noage": false, "freeze": false}
var mult: int = 1            ## Spawn-Menge: so viele Wesen setzt jedes Setz-Werkzeug auf einmal
var cult: float = 1.0        ## Kultivierungsfaktor (Sim.cultivate)
var grave: Array = []        ## [{u: Unit-Dictionary, y: Jahr, why: Todesursache}] – neueste zuerst
var leads: Dictionary = {}   ## Clan-Id -> Unit-Id (erzwungenes Clan-Oberhaupt)
var inf_v: Dictionary = {}   ## Dorf-Id -> true (unendliche Vorräte für dieses Dorf)
var jump_left: float = 0.0   ## Zeitsprung: verbleibende Monate
var jump_total: float = 0.0
var jump_y0: int = 0


func _init(s: Sim) -> void:
	sim = s
	s.unit_died.connect(_on_died)


## Neue Welt / Laden: weltbezogene Daten verwerfen, Schalter behalten.
func reset_world() -> void:
	grave.clear()
	leads.clear()
	inf_v.clear()
	jump_left = 0.0
	jump_total = 0.0


# ---------------- Schalter ----------------

func is_on(k: String) -> bool:
	if k == "walls":
		return not bool(sim.laws.get("walls", true))
	return bool(flags.get(k, false))


func set_switch(k: String, on: bool) -> void:
	if k == "walls":
		sim.laws["walls"] = not on
		return
	flags[k] = on
	cult = 10.0 if bool(flags["cult10"]) else 1.0
	if k == "freeze":
		for u: Unit in sim.units:
			if on:
				u.frz = sim.sim_time + 1e6
				u.fxm = true
			elif u.frz > sim.sim_time + 1e5:
				u.frz = -1.0
	if k == "stones" or k == "res":
		month_villages()


## Schaltet um und gibt den Hinweistext zurück.
func toggle(k: String) -> String:
	set_switch(k, not is_on(k))
	for s: Array in SWITCHES:
		if s[0] == k:
			return "%s: %s" % [s[1], "on" if is_on(k) else "off"]
	return ""


func set_mult(n: int) -> void:
	mult = clampi(n, 1, 100)


## Darf noch etwas gesetzt werden? (technische Obergrenze)
func room(n: int = 1) -> bool:
	return sim.units.size() + n <= HARD_MAX


func full_msg() -> String:
	return "The world is full: %d beings – the simulation cannot take more (limit %d)." % [sim.units.size(), HARD_MAX]


# ---------------- Mehrfache Einzigartige ----------------

static func roman(n: int) -> String:
	if n < ROMAN.size():
		return ROMAN[n]
	return " %d." % n


func count_fig(key: String) -> int:
	var n: int = 0
	for u: Unit in sim.units:
		if u.hp > 0.0 and u.fig == key:
			n += 1
	return n


## Namenszusatz für das nächste Exemplar einer Figur („Riesensonne II“).
func fig_suffix(key: String) -> String:
	var n: int = count_fig(key)
	return roman(n + 1) if n > 0 else ""


func org_suffix(id: String) -> String:
	var n: int = 0
	for c: Clan in sim.clans:
		if c.alive and c.org == id:
			n += 1
	return roman(n + 1) if n > 0 else ""


func place_suffix(type: String) -> String:
	var n: int = 0
	for p: Place in sim.places:
		if p.alive and p.type == type:
			n += 1
	return roman(n + 1) if n > 0 else ""


# ---------------- Laufend ----------------

## Am Ende jedes Monats (Sim.monthly).
func month() -> void:
	month_villages()
	var nt: bool = bool(flags["notrib"])
	var fr: bool = bool(flags["freeze"])
	for u: Unit in sim.units:
		if u.hp <= 0.0:
			continue
		if u.ch != 0:
			if (u.ch & CH_IMM) != 0:
				u.birth += 1.0   # altert nicht
				if u.k == "p":
					u.life = maxf(u.life, sim.uage(u) + 1.0)
			if (u.ch & CH_LUCK) != 0:
				u.luck = 1.0
		if nt and u.k == "p" and u.rank >= 6:
			u.next_trib = maxf(u.next_trib, sim.uage(u) + 50.0)
		if fr and u.frz < sim.sim_time + 1e5:
			u.frz = sim.sim_time + 1e6
			u.fxm = true
	for cid: int in leads.keys():
		var L: Unit = sim.unit_by_id(int(leads[cid]))
		if cid >= sim.clans.size() or L == null or L.clan != cid or not sim.clans[cid].alive:
			leads.erase(cid)
			continue
		sim.clans[cid].lead = L
		if L.vil >= 0 and L.vil < sim.villages.size():
			sim.villages[L.vil].lead = L


func month_villages() -> void:
	var st: bool = bool(flags["stones"])
	var res: bool = bool(flags["res"])
	if not st and not res and inf_v.is_empty():
		return
	for v: Village in sim.villages:
		if not v.alive:
			continue
		if res or inf_v.has(v.id):
			v.food = maxf(v.food, 60.0 + v.pop * 3.0)
			v.wood = maxf(v.wood, 200.0)
			v.stones = maxf(v.stones, 200.0)
		elif st:
			v.stones = maxf(v.stones, 60.0)


## Aus Sim.try_revive: true = das Wesen bleibt am Leben (Cheat-Schutz).
func keep_alive(u: Unit) -> bool:
	var why: String = u.dreason
	if why == "divine annihilation" or u.caught:
		return false
	var save: bool = false
	if (u.ch & CH_INV) != 0:
		save = true
	elif (u.ch & CH_IMM) != 0 and why in IMM_SAVE:
		save = true
	elif u.k == "p":
		if bool(flags["noage"]) and (why == "old age" or why == "extreme physique"):
			save = true
		elif bool(flags["notrib"]) and (why == "heavenly tribulation" or why == "earthly calamity"):
			save = true
		elif bool(flags["nowill"]) and why == "Heaven's Will":
			save = true
	if not save:
		return false
	u.hp = maxf(1.0, u.mhp)
	u.dreason = ""
	u.sick = 0.0
	if why == "old age" or why == "crumbled":
		u.life = sim.uage(u) + 30.0
	if why == "extreme physique":
		u.phys_x = false
	return true


## Darf ein Treffer Schaden machen? (aus Sim.hurt; göttliche Auslöschung trifft immer)
static func blocks(u: Unit, dmg: float) -> bool:
	return (u.ch & CH_INV) != 0 and dmg < 1e8


func _on_died(u: Unit) -> void:
	if u.k != "p" or (u.rank < 1 and u.fig == ""):
		return
	grave.push_front({"u": u.to_dict(), "y": sim.year(), "why": u.dreason})
	if grave.size() > GRAVE_MAX:
		grave.resize(GRAVE_MAX)


# ---------------- Zeitsprung ----------------

func jump(years: float) -> void:
	if jump_left <= 0.0:
		jump_total = 0.0
		jump_y0 = sim.year()
	jump_left += years * 12.0
	jump_total += years * 12.0


func jumping() -> bool:
	return jump_left > 0.0


## Läuft den Zeitsprung im Zeitbudget weiter; gibt den Fortschritt 0..1 zurück (1 = fertig).
func jump_chunk(budget_ms: int) -> float:
	var t0: int = Time.get_ticks_msec()
	while jump_left > 0.0 and Time.get_ticks_msec() - t0 < budget_ms:
		var dt: float = minf(0.1, jump_left)
		sim.step(dt)
		jump_left -= dt
		if jump_left < 0.001:
			jump_left = 0.0
	if sim.fx.size() > 300:
		sim.fx = sim.fx.slice(sim.fx.size() - 150)
	if sim.parts.size() > 1500:
		sim.parts = sim.parts.slice(sim.parts.size() - 600)
	if jump_left <= 0.0:
		jump_left = 0.0
		sim.terr_dirty = true
		return 1.0
	return clampf(1.0 - jump_left / maxf(1.0, jump_total), 0.0, 0.999)


# ---------------- Eingriffe in Wesen ----------------

func _vd(u: Unit) -> Dictionary:
	return sim.ven._vd_for(u)


func _ven_title(u: Unit) -> String:
	return ("Demon Venerable" if u.align == 1 else "Immortal Venerable") + " of the " + GuData.PATH_NAME[clampi(u.path, 0, GuData.PATH_NAME.size() - 1)] + " Path"


## Rang (0..9) und Stufe (0..3) direkt setzen. Gibt einen Hinweistext zurück.
func set_rank(u: Unit, r: int, stage: int = 0) -> String:
	if u.k != "p":
		return "Only humans and variant humans have a rank."
	if u.undead:
		return "Walking corpses do not cultivate."
	r = clampi(r, 0, 9)
	var old: int = u.rank
	if r == 0:
		if old >= 9:
			sim.ven.st.erase(u.id)
		u.rank = 0
		u.stage = 0
		u.prog = 0.0
		u.gus = PackedStringArray()
		if not u.ow:
			u.title = ""
		u.fly = GuData.RACE_FLY[u.race]
		sim.set_stats(u, false)
		sim.float_txt(u, "Mortal", Color("#c8c0b0"))
		return u.pname() + " is a mortal again."
	if old == 0:
		u.awk = true
		sim.awaken(u, true)
		old = 1
	if r > old:
		for rr: int in range(old + 1, r + 1):
			sim.ascend(u, rr)
	elif r < old:
		if old >= 9:
			sim.ven.st.erase(u.id)
			if not u.ow and (u.fig == "" or u.fig.begins_with("ven9_") or not _vd(u).is_empty()):
				u.title = ""
		u.rank = r
		u.prog = 0.0
		u.fly = GuData.RACE_FLY[u.race]
		if r >= 6:
			u.next_trib = maxf(u.next_trib, sim.uage(u) + 10.0)
		sim.float_txt(u, "Rank %d" % r, GuData.ESS_COL[r])
	u.stage = clampi(stage, 0, 3) if r < 9 else 0
	u.prog = 0.0
	sim.set_stats(u, false)
	u.hp = maxf(u.hp, u.mhp * 0.5)
	if r >= 9 and old < 9:
		if u.title == "" or u.title == "Otherworldly Demon":
			u.title = _ven_title(u)
		u.life = maxf(u.life, sim.uage(u) + 1000.0)
		sim.pillar(u.x, u.y, GuData.ESS_COL[9], 1.2)
		sim.ven.register(u, _vd(u))
		sim.log_event(u.pname() + " becomes a Rank 9 " + u.title + " by divine hand.", "gold", true)
	sim.terr_dirty = true
	return "%s: %s%s" % [u.pname(), GuData.rank_title(r), (" · " + GuData.STAGE[u.stage]) if r < 9 else ""]


func rank_step(u: Unit, d: int) -> String:
	if u.k != "p":
		return "Only humans and variant humans have a rank."
	return set_rank(u, clampi(u.rank + d, 0, 9), 0)


func set_path(u: Unit, p: int) -> String:
	if u.k != "p" or u.rank <= 0:
		return "Only awakened Gu Masters have a path."
	p = clampi(p, 0, GuData.PATH_NAME.size() - 1)
	u.path = p
	if u.gus.is_empty():
		u.gus = PackedStringArray([Lore.start_gu(p)])
	else:
		u.gus[0] = Lore.start_gu(p)
	if u.rank >= 9:
		if _vd(u).is_empty() and not u.ow:
			u.title = _ven_title(u)
		var s: Dictionary = sim.ven.state(u)
		if not s.is_empty():
			s["p"] = p
			s["att"] = "Supreme Grandmaster of the %s Path" % GuData.PATH_NAME[p]
	sim.spark(u.x, u.y - 2.0, GuData.PATH_COL[p], 10, 5.0)
	sim.float_txt(u, GuData.PATH_NAME[p] + " Path", GuData.PATH_COL[p])
	sim.terr_dirty = true
	return u.pname() + " now follows the " + GuData.PATH_NAME[p] + " Path."


func flip_align(u: Unit) -> String:
	if u.k != "p":
		return "Tap a human."
	u.align = 1 - u.align
	if u.align == 0 and u.rogue:
		u.rogue = false
	if u.rank >= 9 and _vd(u).is_empty() and not u.ow:
		u.title = _ven_title(u)
	var s: Dictionary = sim.ven.state(u)
	if not s.is_empty():
		s["al"] = u.align
	sim.float_txt(u, "demonic" if u.align == 1 else "righteous", Color("#ff8a7a") if u.align == 1 else Color("#9fe0b0"))
	return u.pname() + " is now " + ("demonic." if u.align == 1 else "righteous.")


func set_apt(u: Unit, a: String) -> String:
	if u.k != "p":
		return "Tap a human."
	if u.rank == 0:
		u.awk = true
		sim.awaken(u, true)
	u.apt = a
	u.phys_x = a == "X"
	sim.float_txt(u, "Extreme Physique" if a == "X" else a + "-grade", Color("#ffe27a"))
	return u.pname() + ": aptitude " + ("Extreme Physique" if a == "X" else a + "-grade") + "."


## Schaltet einen Merker (CH_*) um; true = jetzt an.
func toggle_ch(u: Unit, bit: int) -> bool:
	u.ch ^= bit
	var on: bool = (u.ch & bit) != 0
	if bit == CH_LUCK and on:
		u.luck = 1.0
	if bit == CH_IMM and on and u.k == "p":
		u.life = maxf(u.life, sim.uage(u) + 1.0)
	return on


func god(u: Unit) -> bool:
	var on: bool = (u.ch & (CH_IMM | CH_INV)) != (CH_IMM | CH_INV)
	if on:
		u.ch |= CH_IMM | CH_INV
		heal(u)
	else:
		u.ch &= ~(CH_IMM | CH_INV)
	return on


func heal(u: Unit) -> void:
	u.hp = u.mhp
	u.sick = 0.0
	u.zin = -1.0
	if u.frz < sim.sim_time + 1e5:
		u.frz = -1.0


func rejuvenate(u: Unit) -> String:
	if u.k != "p":
		u.birth = sim.sim_time
		return u.pname() + " is young again."
	var a: float = sim.uage(u)
	var na: float = 18.0 if a > 18.0 else maxf(0.0, a - 5.0)
	u.birth = sim.sim_time - na * 12.0
	u.life = maxf(u.life, na + GuData.RACE_LIFE[u.race] * 0.8 + GuData.LIFEB[u.rank])
	if u.phys_x and u.rank < 6:
		u.life = maxf(u.life, 40.0)
	sim.pillar(u.x, u.y, Color("#9affb0"), 0.5)
	sim.float_txt(u, "%d years young" % int(na), Color("#9affb0"))
	return "%s is now %d years old." % [u.pname(), int(na)]


func age_up(u: Unit, years: float) -> String:
	u.birth -= years * 12.0
	sim.float_txt(u, "+%d years" % int(years), Color("#c8c0b0"))
	return "%s is now %d years old (lifespan %d)." % [u.pname(), int(sim.uage(u)), int(u.life)]


## Genaue Kopie eines Wesens neben dem Original.
func clone(u: Unit) -> Unit:
	if not room():
		return null
	var c: Unit = Unit.from_dict(u.to_dict())
	c.id = sim.next_id
	sim.next_id += 1
	var nx: float = u.x + (randf() - 0.5) * 3.0
	var ny: float = u.y + 1.0 + randf()
	if sim.world.in_map(int(nx), int(ny)):
		c.x = nx
		c.y = ny
	c.tx = c.x
	c.ty = c.y
	c.hp = u.hp
	if c.k == "a":
		sim.init_animal(c)
		c.ldr = u.ldr
	else:
		if not c.igu.is_empty():
			sim.apply_igu(c)
		if c.fig != "":
			c.given += fig_suffix(c.fig)
	c.fxm = true
	sim.units.append(c)
	if c.k == "p" and c.rank >= 9:
		sim.ven.register(c, _vd(c))
	sim.puff(c.x, c.y - 1.0, Color("#e0d0ff"), 6)
	sim.ring(c.x, c.y - 1.0, 2.5, Color("#c8a0ff"), 0.5)
	return c


## Bemerkenswerter Toter idx (0 = zuletzt gestorben) kehrt an (x, y) zurück.
func revive(idx: int, x: float, y: float) -> Unit:
	if grave.is_empty() or not room():
		return null
	idx = clampi(idx, 0, grave.size() - 1)
	var e: Dictionary = grave[idx]
	grave.remove_at(idx)
	var u: Unit = Unit.from_dict(e["u"])
	u.id = sim.next_id
	sim.next_id += 1
	u.x = clampf(x, 0.5, sim.W - 0.5)
	u.y = clampf(y, 0.5, sim.H - 0.5)
	u.tx = u.x
	u.ty = u.y
	u.dreason = ""
	u.caught = false
	u.held = false
	u.poss = false
	u.sick = 0.0
	if u.vil >= sim.villages.size() or (u.vil >= 0 and not sim.villages[u.vil].alive):
		u.vil = -1
	if u.clan >= sim.clans.size() or (u.clan >= 0 and not sim.clans[u.clan].alive):
		u.clan = -1
	if u.vil >= 0:
		u.clan = sim.villages[u.vil].clan
	if not u.igu.is_empty():
		sim.apply_igu(u)
	sim.set_stats(u, true)
	u.life = maxf(u.life, sim.uage(u) + 30.0)
	if u.rank >= 6:
		u.next_trib = sim.uage(u) + 10.0
	if u.fig != "":
		u.given = u.given.trim_suffix(" II").trim_suffix(" III") + fig_suffix(u.fig)
	sim.units.append(u)
	if u.rank >= 9:
		sim.ven.register(u, _vd(u))
	sim.pillar(x, y, Color("#e8e0ff"), 1.0)
	sim.ring(x, y, 5.0, Color("#e8e0ff"), 0.8)
	sim.log_event(u.pname() + " (" + GuData.rank_title(u.rank) + ") is brought back from the dead.", "violet", true)
	return u


## Gu geben: sel = "i:<Id>" (Unsterbliches Gu, ohne Obergrenze) oder "m:<Name>" (sterbliches Gu).
func give(u: Unit, sel: String) -> String:
	if u.k != "p":
		return "Only humans can carry Gu."
	if sel.begins_with("m:"):
		var g: String = sel.substr(2)
		if u.rank == 0:
			u.awk = true
			sim.awaken(u, true)
		if not u.gus.has(g):
			u.gus.append(g)
		sim.float_txt(u, "+" + g, Color("#cfe8ff"))
		return u.pname() + " receives " + g + "."
	var id: String = sel.substr(2)
	var e: Dictionary = Lore.igu(id)
	if e.is_empty():
		return "Choose a Gu first."
	if str(e["fx"]) in ["fetus", "destiny", "life", "eternal"] or u.igu.size() < 6:
		sim.give_igu(u, id)
	elif not u.igu.has(id):
		u.igu.append(id)
		sim.apply_igu(u)
		sim.set_stats(u, false)
	if id == "fate_gu":
		sim.ven.fate_on = true
	sim.float_txt(u, str(e["n"]), GuData.PATH_COL[int(e.get("p", 0))])
	sim.pillar(u.x, u.y, GuData.PATH_COL[int(e.get("p", 0))], 0.5)
	return u.pname() + " receives " + str(e["n"]) + "."


func strip(u: Unit) -> String:
	if u.k != "p":
		return "Tap a human."
	var n: int = u.gus.size() + u.igu.size()
	u.gus = PackedStringArray()
	u.igu = PackedStringArray()
	sim.apply_igu(u)
	sim.set_stats(u, false)
	sim.puff(u.x, u.y - 2.0, Color("#6a5a7a"), 6)
	return "%s loses %d Gu." % [u.pname(), n]


func rename(u: Unit, text: String) -> void:
	var t: String = text.strip_edges()
	if t == "":
		return
	var sp: int = t.find(" ")
	if sp > 0 and u.sur != "":
		u.sur = t.substr(0, sp)
		u.given = t.substr(sp + 1)
	else:
		u.sur = ""
		u.given = t
	sim.float_txt(u, u.pname(), Color("#ffe27a"))


func join_clan(u: Unit, v: Village) -> String:
	if u.k != "p":
		return "Only humans join clans."
	u.rogue = false
	sim.join_village(u, v)
	u.tgt = null
	u.st = "idle"
	sim.go_to(u, v.cx, v.cy)
	var c: Clan = sim.clans[v.clan]
	sim.ring(u.x, u.y, 3.0, c.col, 0.6)
	sim.terr_dirty = true
	return u.pname() + " now belongs to " + c.name + " (" + v.name + ")."


func make_leader(u: Unit) -> String:
	if u.k != "p" or u.clan < 0 or u.clan >= sim.clans.size():
		return "Tap a clan member."
	var c: Clan = sim.clans[u.clan]
	leads[c.id] = u.id
	c.lead = u
	if u.vil >= 0 and u.vil < sim.villages.size():
		sim.villages[u.vil].lead = u
	sim.pillar(u.x, u.y, c.col, 0.7)
	sim.log_event(u.pname() + " becomes leader of " + c.name + " by divine hand.", "jade", true)
	return u.pname() + " now leads " + c.name + "."


# ---------------- Masse ----------------

## Gu-Meister oder -Unsterblicher eines Ranges, ohne Meldung (für Armeen).
func make_master(x: float, y: float, rank: int, race: int, sur: String = "") -> Unit:
	var u: Unit = sim.mk_person(x, y, race, 16.0 + rank * (4.0 if rank <= 5 else 30.0) + randf() * 10.0, sur)
	u.awk = true
	sim.awaken(u, true)
	for r: int in range(2, rank + 1):
		sim.ascend(u, r)
	u.life = maxf(u.life, sim.uage(u) + 25.0 + GuData.LIFEB[rank])
	u.hp = u.mhp
	return u


## Armee: n Gu-Meister von Rang r, im nächsten Dorf (sonst gründen sie einen Clan).
func army(x: float, y: float, n: int, r: int) -> String:
	if not room():
		return full_msg()
	n = mini(n, HARD_MAX - sim.units.size())
	r = clampi(r, 1, 8)
	var v: Village = sim.nearest_village(x, y, 40.0)
	var race: int = v.race if v != null else 0
	var sur: String = sim.pick_sur(v) if v != null else ""
	var made: Array[Unit] = []
	for k: int in range(n):
		var a: float = randf() * TAU
		var d: float = sqrt(randf()) * (2.0 + sqrt(float(n)) * 0.9)
		var px: float = x + cos(a) * d
		var py: float = y + sin(a) * d
		if not sim.world.in_map(int(px), int(py)):
			px = x
			py = y
		var u: Unit = make_master(px, py, r, race, sur)
		made.append(u)
	if v == null and not made.is_empty() and sim.found_village(made[0], -1):
		v = sim.villages[made[0].vil]
	if v != null:
		for u2: Unit in made:
			sim.join_village(u2, v)
	sim.ring(x, y, 4.0 + sqrt(float(n)), GuData.ESS_COL[r], 0.9)
	sim.log_event("An army of %d %s appears%s." % [made.size(), "Gu Masters" if r <= 5 else "Gu Immortals", (" for " + sim.clans[v.clan].name) if v != null else ""], "war", true)
	sim.terr_dirty = true
	return "%d × %s%s" % [made.size(), GuData.rank_title(r), (" · " + sim.clans[v.clan].name) if v != null else ""]


## Rang-9-Regen: n Ehrwürdige zufälliger Pfade an zufälligen Orten.
func r9_rain(n: int) -> String:
	var got: int = 0
	var why: String = ""
	for k: int in range(n):
		if not room():
			why = full_msg()
			break
		var p: Vector2 = sim.random_tile(func(i: int) -> bool: return GuData.buildable(sim.world.tile[i]), 400)
		if p.x < 0.0:
			why = "No land for Venerables."
			break
		var msg: String = sim.spawn_custom_venerable(randi() % GuData.PATH_NAME.size(), randi() % 2, p.x, p.y)
		if msg == "":
			got += 1
	sim.flash(0.4)
	return "%d Venerables descend.%s" % [got, (" " + why) if why != "" else ""]


## Alle Gu-Meister (Rang 1–7) der Welt bzw. eines Clans (cid >= 0) steigen einen Rang auf.
func rank_all(cid: int = -1) -> int:
	var n: int = 0
	var list: Array[Unit] = []
	for u: Unit in sim.units:
		if u.k == "p" and u.hp > 0.0 and u.rank >= 1 and u.rank <= 7 and not u.undead and (cid < 0 or u.clan == cid):
			list.append(u)
	for u2: Unit in list:
		sim.ascend(u2, u2.rank + 1)
		n += 1
	if cid < 0 and n > 0:
		sim.flash(0.3)
		sim.log_event("A wave of enlightenment: %d Gu Masters ascend." % n, "gold", true)
	return n


func populate(v: Village, n: int) -> String:
	if not room():
		return full_msg()
	n = mini(n, HARD_MAX - sim.units.size())
	for k: int in range(n):
		var u: Unit = sim.mk_person(v.cx + (randf() - 0.5) * 8.0, v.cy + 2.0 + (randf() - 0.5) * 5.0, v.race, 15.0 + randf() * 20.0, sim.pick_sur(v))
		u.awk = randf() < 0.7
		sim.join_village(u, v)
	v.food += n * 2.0
	sim.puff(v.cx, v.cy, Color("#fff6d8"), 12)
	return "%d new residents in %s." % [n, v.name]


## Dorf auf die höchste Stufe: Ahnenhalle, volle Hütten und Felder, Gu-Veredelung, Türme, volle Vorräte.
func village_max(v: Village) -> String:
	v.lvl = 1
	v.food = maxf(v.food, 200.0)
	v.wood = maxf(v.wood, 200.0)
	v.stones = maxf(v.stones, 200.0)
	var guard: int = 0
	while v.farms < 6 and guard < 40:
		guard += 1
		sim.try_build(v, "farm")
		sim.recount(v)
	guard = 0
	while v.houses < 12 and guard < 30:
		guard += 1
		sim.try_build(v, "house")
		sim.recount(v)
	if not v.forge:
		sim.try_build(v, "forge")
	guard = 0
	while v.towers < 2 and guard < 10:
		guard += 1
		sim.try_build(v, "tower")
		sim.recount(v)
	sim.recount(v)
	sim.pillar(v.cx, v.cy, Color("#ffe27a"), 1.0)
	sim.terr_dirty = true
	return "%s: %d huts, %d fields%s, %d towers." % [v.name, v.houses, v.farms, ", Gu refinement" if v.forge else "", v.towers]


## Clan auflösen: jedes Dorf wird ein eigener Clan; ein Clan mit nur einem Dorf zerfällt ganz.
func disband(c: Clan) -> String:
	var vs: Array[Village] = []
	for v: Village in sim.villages:
		if v.alive and v.clan == c.id:
			vs.append(v)
	if vs.size() <= 1:
		for v2: Village in vs:
			sim.abandon_village(v2, "")
		for u: Unit in sim.units:
			if u.k == "p" and (u.clan == c.id or u.col_clan == c.id):
				u.clan = -1
				u.vil = -1
				u.col_clan = -1
		sim.kill_clan(c, "was dissolved by divine hand.")
		sim.terr_dirty = true
		return c.name + " has fallen apart; its members roam as clanless wanderers."
	for v3: Village in vs:
		var nc: Clan = sim.new_clan(v3.reg, sim.rand_sur(v3.reg), v3.race)
		nc.align = c.align
		v3.clan = nc.id
		nc.cap = v3.id
		for u2: Unit in sim.units:
			if u2.k == "p" and u2.vil == v3.id:
				u2.clan = nc.id
	for u3: Unit in sim.units:
		if u3.k == "p" and u3.clan == c.id:
			u3.clan = -1
			u3.col_clan = -1
	sim.kill_clan(c, "was dissolved by divine hand – %d villages go their own way." % vs.size())
	sim.terr_dirty = true
	return "%s splits into %d clans." % [c.name, vs.size()]


func take_village(c: Clan, v: Village) -> String:
	if v.clan == c.id:
		return v.name + " already belongs to " + c.name + "."
	var oc: Clan = sim.clans[v.clan]
	sim.ven.absorb_village(v, c)
	sim.pillar(v.cx, v.cy, c.col, 0.8)
	sim.log_event(v.name + " passes from " + oc.name + " to " + c.name + " by divine hand.", "war", true)
	return v.name + " now belongs to " + c.name + "."


# ---------------- Himmel ----------------

func fate_exists() -> bool:
	for u: Unit in sim.units:
		if u.hp > 0.0 and ((u.k == "a" and u.gname == "fate_gu") or (u.k == "p" and u.igu.has("fate_gu"))):
			return true
	return false


func fate_break() -> String:
	var n: int = 0
	for u: Unit in sim.units:
		if u.hp <= 0.0:
			continue
		if u.k == "a" and u.gname == "fate_gu":
			u.caught = true
			u.hp = 0.0
			n += 1
		elif u.k == "p" and u.igu.has("fate_gu"):
			u.igu.remove_at(u.igu.find("fate_gu"))
			sim.apply_igu(u)
			sim.set_stats(u, false)
			n += 1
	if n == 0 and sim.ven.fate_broken:
		return "Fate Gu was destroyed long ago."
	sim.ven._fate_shatter("Heaven itself shatters Fate Gu!")
	return "Fate Gu is destroyed – Rank 9 lies open."


func fate_fix(x: float, y: float) -> String:
	sim.ven.fate_broken = false
	if fate_exists():
		sim.ven.fate_on = true
		return "Fate Gu already exists – the shackles of fate are bound again."
	var g: Unit = sim.spawn_wild_igu(x, y, "fate_gu")
	g.hp = g.mhp
	sim.ven.fate_on = true
	sim.pillar(x, y, GuData.PATH_COL[28], 1.4)
	sim.log_event("Fate Gu is forged anew – fate binds the world once more.", "gold", true)
	return "Fate Gu is restored."


# ---------------- Texte ----------------

## Cheat-Merker im Wesen-Inspektor.
func unit_lines(u: Unit) -> String:
	var s: String = ""
	if (u.ch & CH_IMM) != 0 and (u.ch & CH_INV) != 0:
		s += "\n[color=#ffd23a]God Mode – immortal and invulnerable[/color]"
	elif (u.ch & CH_IMM) != 0:
		s += "\n[color=#ffd23a]Immortal – does not age, does not die of old age, tribulation or Heaven's Will[/color]"
	elif (u.ch & CH_INV) != 0:
		s += "\n[color=#7ef0ff]Invulnerable – takes no damage[/color]"
	if (u.ch & CH_LUCK) != 0:
		s += "\n[color=#9aff7a]Eternal Luck[/color]"
	if u.k == "p" and u.clan >= 0 and int(leads.get(u.clan, -1)) == u.id:
		s += "\n[color=#62d8a4]Clan leader appointed by divine hand[/color]"
	if u.frz > sim.sim_time + 1e5:
		s += "\n[color=#d8f4ff]Frozen (cheat)[/color]"
	return s


func village_line(v: Village) -> String:
	if inf_v.has(v.id) or bool(flags["res"]):
		return "[color=#9db09e]Cheat[/color]  [color=#ffd23a]Infinite Supplies[/color]\n"
	return ""


## Seelensuche: alles über ein Wesen.
func soul_text(u: Unit) -> String:
	var mt: String = "[color=#9db09e]"
	var s: String = ""
	s += mt + "Id[/color]  %d · %s\n" % [u.id, "Human (" + GuData.RACE_NAME[u.race] + ")" if u.k == "p" else str(GuData.SPEC[u.sp]["n"])]
	s += mt + "Age[/color]  %.1f / %d years · born in year %d\n" % [sim.uage(u), int(u.life), int(u.birth / 12.0) + 1]
	s += mt + "Health[/color]  %d / %d · Attack %d · Range %.1f · Speed %.1f\n" % [int(u.hp), int(u.mhp), int(u.atk), u.rng, u.speed]
	if u.k == "p":
		s += mt + "Rank[/color]  %s%s · Progress %d %%\n" % [GuData.rank_title(u.rank), (" · " + GuData.STAGE[u.stage]) if u.rank > 0 and u.rank < 9 else "", int(u.prog * 100.0)]
		if u.rank > 0:
			s += mt + "Path[/color]  %s · Aptitude %s · %s\n" % [GuData.PATH_NAME[clampi(u.path, 0, GuData.PATH_NAME.size() - 1)], "Extreme Physique" if u.apt == "X" else u.apt, "demonic" if u.align == 1 or u.rogue else "righteous"]
		var c: Clan = sim.clans[u.clan] if u.clan >= 0 and u.clan < sim.clans.size() else null
		var v: Village = sim.villages[u.vil] if u.vil >= 0 and u.vil < sim.villages.size() else null
		s += mt + "Clan[/color]  %s%s%s\n" % [c.name if c != null else "no clan", (" · " + v.name) if v != null else "", " · rogue cultivator" if u.rogue else ""]
		if u.title != "":
			s += mt + "Title[/color]  " + u.title + "\n"
		if u.fig != "":
			s += mt + "Figure[/color]  " + u.fig + "\n"
		if u.rank >= 6:
			s += mt + "Tribulation[/color]  " + ("never (Heaven Fragment)" if u.notrib else "in %d years" % maxi(0, int(u.next_trib - sim.uage(u)))) + "\n"
		s += mt + "Luck[/color]  %d %% · Kills %d · Job %s\n" % [int(u.luck * 100.0), u.kills, u.job if u.job != "" else "–"]
		var mul: float = u.ig_cult * cult * sim.ven.cult_mul(u) * (2.2 if u.luck > 0.0 else 1.0)
		s += mt + "Cultivation[/color]  ×%.1f (Immortal Gu ×%.1f)\n" % [mul, u.ig_cult]
		s += "\n[color=#e8c70a][b]GU (%d)[/b][/color]\n" % u.gus.size() + (", ".join(u.gus) if not u.gus.is_empty() else "none") + "\n"
		s += "\n[color=#ffd24a][b]IMMORTAL GU (%d)[/b][/color]\n" % u.igu.size()
		for id: String in u.igu:
			var e: Dictionary = Lore.igu(id)
			s += "• %s [color=#9db09e](Rank %d, %s Path – %s)[/color]\n" % [str(e.get("n", id)), int(e.get("r", 6)), GuData.PATH_NAME[int(e.get("p", 0))], str(Lore.FX_TEXT.get(str(e.get("fx", "gen")), ""))]
		if u.igu.is_empty():
			s += "none\n"
		var st: Dictionary = sim.ven.state(u)
		if not st.is_empty():
			s += "\n[color=#ffd24a][b]VENERABLE[/b][/color]\n%s\nPhase %s · Region %s · Vassals %d · Bloodline %d members\n" % [str(st.get("doing", "")), str(st.get("ph", "")), GuData.REGN[clampi(int(st.get("goal", 4)), 0, GuData.REGN.size() - 1)] if int(st.get("goal", -1)) >= 0 else "–", (st.get("vas", []) as Array).size(), sim.ven.lineage_size(st)]
	var fl: PackedStringArray = PackedStringArray()
	if (u.ch & CH_IMM) != 0:
		fl.append("immortal")
	if (u.ch & CH_INV) != 0:
		fl.append("invulnerable")
	if (u.ch & CH_LUCK) != 0:
		fl.append("eternal luck")
	if u.bless > 0:
		fl.append("blessed")
	elif u.bless < 0:
		fl.append("cursed")
	if u.prot > sim.sim_time:
		fl.append("Heaven's Protection")
	if u.sick > 0.0:
		fl.append("plague")
	if u.undead:
		fl.append("walking corpse")
	if u.poss:
		fl.append("possessed")
	if u.ow:
		fl.append("Otherworld Demon")
	s += "\n" + mt + "States[/color]  " + (", ".join(fl) if not fl.is_empty() else "none")
	return s


# ---------------- Speichern ----------------

func to_dict() -> Dictionary:
	var gr: Array = []
	for e: Dictionary in grave:
		gr.append(e)
	var ld: Array = []
	for cid: int in leads.keys():
		ld.append([cid, int(leads[cid])])
	return {"flags": flags.duplicate(), "mult": mult, "grave": gr, "leads": ld, "inf_v": inf_v.keys()}


func from_dict(d: Dictionary) -> void:
	var fl: Dictionary = d.get("flags", {})
	for k: String in flags.keys():
		flags[k] = bool(fl.get(k, false))
	cult = 10.0 if bool(flags["cult10"]) else 1.0
	mult = clampi(int(d.get("mult", 1)), 1, 100)
	grave.clear()
	for e: Variant in d.get("grave", []):
		if e is Dictionary and (e as Dictionary).has("u"):
			grave.append(e)
	leads.clear()
	for e2: Variant in d.get("leads", []):
		var a: Array = e2
		leads[int(a[0])] = int(a[1])
	inf_v.clear()
	for e3: Variant in d.get("inf_v", []):
		inf_v[int(e3)] = true
