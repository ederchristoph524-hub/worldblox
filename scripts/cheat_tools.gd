class_name CheatTools
extends RefCounted
## Reiter 7 „Cheats“: Werkzeugliste, Tipp-/Pinsel-/Sofort-Wirkungen, Auswahlfenster (Links `c:…` in GuMain._on_meta),
## Cheat-Menü und Entwickler-Test (`--cheattest`, `--cheatshots=<ordner>`). Die Wirkung selbst steckt in `Cheats` (Sim.cheats).

const TAB: int = 7

var sim: Sim
var _pw: WeakRef               ## Powers hält dieses Objekt – nur schwach zurückverweisen (sonst Speicherleck)
var powers: Powers:
	get:
		return _pw.get_ref() as Powers
var m: GuMain = null          ## Hauptszene (für Fenster und Hinweise), von GuMain gesetzt
# Auswahl der Werkzeuge mit Auswahlfenster
var rank_sel: int = 9
var stage_sel: int = 0
var path_sel: int = 24
var apt_sel: String = "X"
var give_sel: String = "i:spring_autumn_cicada"
var give_open: int = -1       ## im Gu-Fenster aufgeklappter Pfad (sterbliche Gu)
var grave_sel: int = 0
var army_n: int = 25
var army_r: int = 3
# Zwei-Tipp-Werkzeuge
var sel_unit: Unit = null
var sel_vil: Village = null


func _init(s: Sim, p: Powers) -> void:
	sim = s
	_pw = weakref(p)


## Werkzeuge des Reiters „Cheats“ (Gruppen = Trennstriche in der Leiste).
static func add_tools(L: Array) -> void:
	var T: int = TAB
	L.append_array([
		# 0: Schalter
		{"id": "c_menu", "tab": T, "g": 0, "n": "Cheat Menu", "d": "All cheat switches (uniqueness, infinite primeval essence, instant cultivation, no tribulations …), spawn amount and instant actions.", "m": "act"},
		{"id": "c_mult", "tab": T, "g": 0, "n": "Spawn Amount", "d": "How many beings each spawn tool places at once: ×1, ×5, ×10 or ×50.", "m": "act"},
		{"id": "c_uniq", "tab": T, "g": 0, "n": "Uniqueness", "d": "Off (default): place Venerables, figures, places and organizations as often as you like – even five Giant Suns. On: canonical limits.", "m": "act"},
		# 1: Rang, Pfad, Gesinnung
		{"id": "c_rup", "tab": T, "g": 1, "n": "Rank +1", "d": "Tap a human: they rise a full rank (mortals are awakened). Up to Rank 9.", "m": "tap"},
		{"id": "c_rdown", "tab": T, "g": 1, "n": "Rank −1", "d": "Tap a Gu Master: they drop one rank (down to mortal).", "m": "tap"},
		{"id": "c_rset", "tab": T, "g": 1, "n": "Set Rank", "d": "Choose Rank 0–9 and stage (initial, middle, upper, peak), then tap humans.", "m": "tap", "pick": true},
		{"id": "c_path", "tab": T, "g": 1, "n": "Change Path", "d": "Choose one of the 48 paths, then tap Gu Masters – Venerables switch their path (and their era) too.", "m": "tap", "pick": true},
		{"id": "c_align", "tab": T, "g": 1, "n": "Flip Alignment", "d": "Righteous becomes demonic and vice versa.", "m": "tap"},
		{"id": "c_apt", "tab": T, "g": 1, "n": "Set Aptitude", "d": "Choose Extreme Physique or A–D, then tap humans.", "m": "tap", "pick": true},
		# 2: Leben und Tod
		{"id": "c_imm", "tab": T, "g": 2, "n": "Immortal", "d": "Tap a being (again = off): it does not age and never dies of old age, tribulation, Heaven's Will or calamity.", "m": "tap"},
		{"id": "c_inv", "tab": T, "g": 2, "n": "Invulnerable", "d": "Tap a being (again = off): it takes no damage. Only “Annihilate” still hits it.", "m": "tap"},
		{"id": "c_god", "tab": T, "g": 2, "n": "God Mode", "d": "Immortal and invulnerable at once, full heal (again = off).", "m": "tap"},
		{"id": "c_heal", "tab": T, "g": 2, "n": "Full Heal", "d": "Fully heals every being under the brush, including plague and corpse plague.", "m": "paint"},
		{"id": "c_young", "tab": T, "g": 2, "n": "Rejuvenate", "d": "Tap a being: it is 18 years old again, and its lifespan grows accordingly.", "m": "tap"},
		{"id": "c_old", "tab": T, "g": 2, "n": "Age", "d": "Tap a being: 50 years older.", "m": "tap"},
		{"id": "c_clone", "tab": T, "g": 2, "n": "Clone", "d": "Tap a being: an exact copy with rank, path, Gu and Immortal Gu appears next to it (Venerables too).", "m": "tap"},
		{"id": "c_revive", "tab": T, "g": 2, "n": "Revive", "d": "Choose a dead Gu Master, Immortal or Venerable (default: most recently deceased), then tap where they should return.", "m": "tap", "pick": true},
		# 3: Gu und Seele
		{"id": "c_soul", "tab": T, "g": 3, "n": "Soul Search", "d": "Tap a being: everything about its soul – stats, Gu, Immortal Gu, states, plans.", "m": "tap"},
		{"id": "c_give", "tab": T, "g": 3, "n": "Give Gu", "d": "Choose an Immortal or mortal Gu, then tap humans – no limit.", "m": "tap", "pick": true},
		{"id": "c_strip", "tab": T, "g": 3, "n": "Take All Gu", "d": "Tap a Gu Master: they lose all Gu and Immortal Gu.", "m": "tap"},
		{"id": "c_name", "tab": T, "g": 3, "n": "Rename", "d": "Tap a human and give them a new name.", "m": "tap"},
		{"id": "c_luck", "tab": T, "g": 3, "n": "Eternal Luck", "d": "Tap a human (again = off): great luck that never fades.", "m": "tap"},
		{"id": "c_possess", "tab": T, "g": 3, "n": "Possession", "d": "Tap a being to possess it; afterwards every tap steers it (like “Soul Possession”).", "m": "tap"},
		# 4: Clans und Dörfer
		{"id": "c_join", "tab": T, "g": 4, "n": "Add to Clan", "d": "Tap a human first, then a village: from now on they belong to that clan.", "m": "pair"},
		{"id": "c_lead", "tab": T, "g": 4, "n": "Make Clan Leader", "d": "Tap a clan member: they become clan leader, even if not the strongest.", "m": "tap"},
		{"id": "c_war", "tab": T, "g": 4, "n": "Declare War", "d": "Tap two villages of different clans: immediate war.", "m": "pair"},
		{"id": "c_peace", "tab": T, "g": 4, "n": "Make Peace", "d": "Tap two villages: their clans make peace.", "m": "pair"},
		{"id": "c_ally", "tab": T, "g": 4, "n": "Forge Alliance", "d": "Tap two villages: their clans become allies.", "m": "pair"},
		{"id": "c_take", "tab": T, "g": 4, "n": "Take Over Village", "d": "Tap a village of the new lord first, then the village that should belong to them – without war.", "m": "pair"},
		{"id": "c_disband", "tab": T, "g": 4, "n": "Disband Clan", "d": "Tap a village: its clan breaks apart – every village becomes its own clan; a clan with only one village dissolves completely.", "m": "tap"},
		{"id": "c_vmax", "tab": T, "g": 4, "n": "Max Out Village", "d": "Tap a village: ancestral hall, twelve huts, fields, Gu refinement, towers and full supplies.", "m": "tap"},
		{"id": "c_res", "tab": T, "g": 4, "n": "Infinite Supplies", "d": "Tap a village (again = off): food, wood and primeval stones never run out.", "m": "tap"},
		{"id": "c_clanup", "tab": T, "g": 4, "n": "Clan +1 Rank", "d": "Tap a village: all Gu Masters of its clan (Rank 1–7) rise one rank.", "m": "tap"},
		{"id": "c_pop", "tab": T, "g": 4, "n": "Population Boost", "d": "Tap a village: 20 new adult residents.", "m": "tap"},
		# 5: Masse
		{"id": "c_army", "tab": T, "g": 5, "n": "Place Army", "d": "Choose size and rank, then tap the map: a whole army of Gu Masters for the nearest village.", "m": "tap", "pick": true},
		{"id": "c_r9rain", "tab": T, "g": 5, "n": "Rank 9 Rain", "d": "Five Venerables of random paths descend all over the world (× spawn amount, at most 60).", "m": "act"},
		{"id": "c_worldup", "tab": T, "g": 5, "n": "World Enlightenment", "d": "Every Gu Master in the world (Rank 1–7) rises one rank.", "m": "act"},
		# 6: Zeit
		{"id": "c_j1", "tab": T, "g": 6, "n": "Time Skip +1 Year", "d": "The world runs one year ahead in fast motion.", "m": "act", "jump": 1},
		{"id": "c_j10", "tab": T, "g": 6, "n": "Time Skip +10 Years", "d": "Ten years in fast motion, with a progress display at the top left.", "m": "act", "jump": 10},
		{"id": "c_j100", "tab": T, "g": 6, "n": "Time Skip +100 Years", "d": "A hundred years in fast motion – clans rise and fall, Venerables rule.", "m": "act", "jump": 100},
		{"id": "c_age", "tab": T, "g": 6, "n": "Set Age", "d": "Opens the ten ages: tap one to start it immediately.", "m": "act"},
		{"id": "c_freeze", "tab": T, "g": 6, "n": "Freeze Beings", "d": "All beings freeze in place (again = thaw); time keeps running.", "m": "act"},
		# 7: Himmel und Schicksal
		{"id": "c_will", "tab": T, "g": 7, "n": "Heaven's Will on Target", "d": "Tap a Gu Master: Heaven's Will turns against them.", "m": "tap"},
		{"id": "c_trib", "tab": T, "g": 7, "n": "Trigger Tribulation", "d": "Tap a Gu Master: a heavenly tribulation descends on them.", "m": "tap"},
		{"id": "c_ward", "tab": T, "g": 7, "n": "Ward Off Tribulation", "d": "Tap a Gu Master: 100 years without tribulation, Heaven's Will or calamity.", "m": "tap"},
		{"id": "c_fatebreak", "tab": T, "g": 7, "n": "Destroy Fate Gu", "d": "Fate Gu shatters wherever it is – Rank 9 lies open, Heaven's Will grows weaker.", "m": "act"},
		{"id": "c_fatefix", "tab": T, "g": 7, "n": "Restore Fate Gu", "d": "Tap the map: a new Fate Gu appears there, and the shackles of fate are bound again.", "m": "tap"},
	])


func clear_sel() -> void:
	sel_unit = null
	sel_vil = null


func has_sel() -> bool:
	return sel_unit != null or sel_vil != null


## Für die Leiste: leuchtet ein Schalter-Knopf (an) oder eine Auswahl?
func is_on(id: String) -> bool:
	match id:
		"c_uniq":
			return sim.cheats.is_on("uniq")
		"c_freeze":
			return sim.cheats.is_on("freeze")
		"c_mult":
			return sim.cheats.mult > 1
	return false


# ---------------- Tippen und Malen ----------------

## Wesen unter einem Tipp (persons = nur Menschen).
func unit_at(wx: float, wy: float, persons: bool = false) -> Unit:
	var best: Unit = null
	var bd: float = 4.0
	for u: Unit in sim.near_units(wx, wy + 1.5, 4.5):
		if persons and u.k != "p":
			continue
		var d: float = Vector2(u.x - wx, u.y - 1.5 - wy).length()
		if d < bd and not u.held:
			bd = d
			best = u
	return best


func _vil_at(wx: float, wy: float) -> Village:
	var v: Village = sim.village_at(int(wx), int(wy))
	if v == null:
		v = sim.nearest_village(wx, wy, 7.0)
	return v


## Tipp-Werkzeuge des Reiters. Gibt einen Hinweistext zurück.
func tap(t: Dictionary, wx: float, wy: float) -> String:
	var id: String = t["id"]
	var C: Cheats = sim.cheats
	match id:
		"c_war", "c_peace", "c_ally", "c_take":
			return _pair_clans(id, wx, wy)
		"c_join":
			return _join(wx, wy)
		"c_disband", "c_vmax", "c_res", "c_clanup", "c_pop":
			var v: Village = _vil_at(wx, wy)
			if v == null:
				return "Tap a village."
			var c: Clan = sim.clans[v.clan]
			match id:
				"c_disband":
					return C.disband(c)
				"c_vmax":
					return C.village_max(v)
				"c_res":
					if C.inf_v.has(v.id):
						C.inf_v.erase(v.id)
						return v.name + ": supplies are finite again."
					C.inf_v[v.id] = true
					C.month_villages()
					sim.pillar(v.cx, v.cy, Color("#ffd23a"), 0.7)
					return v.name + ": infinite supplies."
				"c_clanup":
					var n: int = C.rank_all(c.id)
					sim.pillar(v.cx, v.cy, Color("#fff3c0"), 1.0)
					sim.log_event("All %d Gu Masters of %s ascend by divine hand." % [n, c.name], "gold", true)
					return "%d Gu Masters of %s ascend." % [n, c.name]
				_:
					return C.populate(v, 20)
		"c_army":
			return C.army(wx, wy, army_n, army_r)
		"c_revive":
			if C.grave.is_empty():
				return "No notable being has died yet."
			if not sim.world.in_map(int(wx), int(wy)):
				return ""
			var r: Unit = C.revive(grave_sel, wx, wy)
			grave_sel = 0
			if r == null:
				return C.full_msg()
			return r.pname() + " lives again (" + GuData.rank_title(r.rank) + ")."
		"c_fatefix":
			return C.fate_fix(wx, wy)
		"c_possess":
			return powers.possess_tap(wx, wy, false)
	var persons: bool = not (id in ["c_imm", "c_inv", "c_god", "c_young", "c_old", "c_clone", "c_soul"])
	var u: Unit = unit_at(wx, wy, persons)
	if u == null:
		return "Tap a human." if persons else "Tap a being."
	match id:
		"c_rup":
			return C.rank_step(u, 1)
		"c_rdown":
			return C.rank_step(u, -1)
		"c_rset":
			return C.set_rank(u, rank_sel, stage_sel)
		"c_path":
			return C.set_path(u, path_sel)
		"c_align":
			return C.flip_align(u)
		"c_apt":
			return C.set_apt(u, apt_sel)
		"c_imm":
			var on: bool = C.toggle_ch(u, Cheats.CH_IMM)
			sim.float_txt(u, "Immortal" if on else "mortal", Color("#ffd23a"))
			sim.ring(u.x, u.y - 2.0, 3.0, Color("#ffd23a"), 0.6)
			return u.pname() + (" is immortal." if on else " is mortal again.")
		"c_inv":
			var on2: bool = C.toggle_ch(u, Cheats.CH_INV)
			sim.float_txt(u, "Invulnerable" if on2 else "vulnerable", Color("#7ef0ff"))
			sim.ring(u.x, u.y - 2.0, 3.0, Color("#7ef0ff"), 0.6)
			return u.pname() + (" is invulnerable." if on2 else " is vulnerable again.")
		"c_god":
			var on3: bool = C.god(u)
			sim.float_txt(u, "God Mode" if on3 else "God Mode off", Color("#ffe27a"))
			sim.pillar(u.x, u.y, Color("#ffe27a"), 0.6)
			return u.pname() + (": God Mode on." if on3 else ": God Mode off.")
		"c_young":
			return C.rejuvenate(u)
		"c_old":
			return C.age_up(u, 50.0)
		"c_clone":
			var c2: Unit = C.clone(u)
			return C.full_msg() if c2 == null else c2.pname() + " has been cloned."
		"c_soul":
			_open_soul(u)
			return ""
		"c_give":
			return C.give(u, give_sel)
		"c_strip":
			return C.strip(u)
		"c_name":
			_open_rename(u)
			return ""
		"c_luck":
			var on4: bool = C.toggle_ch(u, Cheats.CH_LUCK)
			sim.spark(u.x, u.y - 2.0, Color("#9aff7a"), 8, 4.0)
			return u.pname() + (": eternal luck." if on4 else ": luck like everyone else.")
		"c_lead":
			return C.make_leader(u)
		"c_will":
			if u.rank <= 0:
				return "Heaven's Will only turns against Gu Masters."
			sim.heavens_will(u)
			return ""
		"c_trib":
			if u.rank <= 0:
				return "Only Gu Masters suffer tribulations."
			sim.tribulation(u)
			return ""
		"c_ward":
			u.prot = sim.sim_time + 1200.0
			u.next_trib = maxf(u.next_trib, sim.uage(u) + 100.0)
			u.fxm = true
			sim.ring(u.x, u.y - 2.0, 4.0, Color("#bfe8ff"), 0.8)
			sim.float_txt(u, "Heaven's Protection 100 years", Color("#bfe8ff"))
			return u.pname() + " is under Heaven's Protection for 100 years."
	return ""


## Pinsel-Werkzeuge des Reiters. true = behandelt.
func paint(t: Dictionary, wx: float, wy: float, stroke_id: int) -> bool:
	if t["id"] != "c_heal":
		return false
	for u: Unit in sim.near_units(wx, wy, powers.brush_r() + 1.5):
		if u.stroke_mark == stroke_id:
			continue
		u.stroke_mark = stroke_id
		sim.cheats.heal(u)
		sim.spark(u.x, u.y - 2.0, Color("#5ad86a"), 3, 3.0)
	return true


func _pair_clans(id: String, wx: float, wy: float) -> String:
	var v: Village = _vil_at(wx, wy)
	if v == null:
		return "Tap a village."
	if sel_vil == null or not sel_vil.alive:
		sel_vil = v
		return sim.clans[v.clan].name + " selected – now tap the second village."
	var a: Clan = sim.clans[sel_vil.clan]
	var b: Clan = sim.clans[v.clan]
	sel_vil = null
	if id == "c_take":
		return sim.cheats.take_village(a, v)
	if a == b:
		return "Choose two different clans."
	match id:
		"c_war":
			sim.declare_war(a, b)
			return a.name + " and " + b.name + " are at war."
		"c_peace":
			sim.make_peace(a, b)
			a.plans = a.plans.filter(func(p: Dictionary) -> bool: return int(p["o"]) != b.id)
			b.plans = b.plans.filter(func(p: Dictionary) -> bool: return int(p["o"]) != a.id)
			return a.name + " and " + b.name + " live in peace."
		_:
			sim.make_ally(a, b)
			return a.name + " and " + b.name + " are allied."


func _join(wx: float, wy: float) -> String:
	if sel_unit == null or sel_unit.hp <= 0.0:
		var u: Unit = unit_at(wx, wy, true)
		if u == null:
			return "Tap a human first."
		sel_unit = u
		sim.ring(u.x, u.y - 1.5, 2.0, Color("#ffe27a"), 0.6)
		return u.pname() + " selected – now tap the village."
	var v: Village = _vil_at(wx, wy)
	if v == null:
		return "Tap a village."
	var msg: String = sim.cheats.join_clan(sel_unit, v)
	sel_unit = null
	return msg


# ---------------- Sofort-Aktionen ----------------

func act(t: Dictionary) -> void:
	var id: String = t["id"]
	var C: Cheats = sim.cheats
	if t.has("jump"):
		start_jump(float(t["jump"]))
		return
	match id:
		"c_menu":
			open_menu()
		"c_mult":
			open_picker("c_mult")
		"c_uniq":
			_hint(t["n"], C.toggle("uniq") + (" – canonical limits." if C.is_on("uniq") else " – everything can be placed any number of times."))
		"c_r9rain":
			m._end_presim()
			_hint(t["n"], C.r9_rain(mini(60, 5 * C.mult)))
		"c_worldup":
			m._end_presim()
			_hint(t["n"], "%d Gu Masters ascend." % C.rank_all(-1))
		"c_age":
			m._open_ages()
		"c_freeze":
			_hint(t["n"], C.toggle("freeze"))
		"c_fatebreak":
			_hint(t["n"], C.fate_break())
	_refresh_bar()


func start_jump(years: float) -> void:
	m._end_presim()
	sim.cheats.jump(years)
	_hint("Time Skip", "+%d years in fast motion – until year %d." % [int(years), sim.year() + int(sim.cheats.jump_left / 12.0)])


func _hint(n: String, d: String) -> void:
	if m != null:
		m.hud.show_hint(n, d)


func _refresh_bar() -> void:
	if m != null:
		m.hud.refresh_tools(m.tool_id, sim.weather.get("type", ""))


# ---------------- Fenster ----------------

func _h(t: String) -> String:
	return Hud.H_PREFIX + t + "[/b][/color][/font_size]\n\n"


func _h3(t: String) -> String:
	return "\n[color=#e8c70a][b]%s[/b][/color]\n" % t.to_upper()


func _mark(on: bool) -> String:
	return "[color=#ffd24a]●[/color]" if on else "[color=#9db09e]○[/color]"


func _switch(on: bool) -> String:
	return "[color=#5fbf8a][b]● ON[/b][/color]" if on else "[color=#c74634][b]○ OFF[/b][/color]"


func _modal(s: String, done: bool = true) -> void:
	if m == null:
		return
	m.hud.open_modal(s, [["Done", func() -> void: m.hud.close_modal(), "jade"]] if done else [])


## Cheat-Menü: alle globalen Schalter, Spawn-Menge, Sofort-Aktionen.
func open_menu() -> void:
	var C: Cheats = sim.cheats
	var s: String = _h("Cheat Menu") + "The switches apply to the whole world and are saved with it. Tap to toggle.\n"
	s += _h3("Switches")
	for e: Array in Cheats.SWITCHES:
		s += "[url=c:sw:%s]%s  [b]%s[/b][/url]\n    [color=#9db09e]%s[/color]\n" % [e[0], _switch(C.is_on(str(e[0]))), e[1], e[2]]
	s += _h3("Spawn Amount")
	var it: PackedStringArray = PackedStringArray()
	for n: int in Cheats.MULTS:
		it.append("[url=c:x:%d]%s [b]×%d[/b][/url]" % [n, _mark(C.mult == n), n])
	s += "    ".join(it) + "\n[color=#9db09e]Every spawn tool (races, animals, Gu Masters, Venerables, figures, Gu) places this many at once.[/color]\n"
	s += _h3("Instant")
	var acts: Array = [["j1", "+1 Year"], ["j10", "+10 Years"], ["j100", "+100 Years"], ["r9", "Rank 9 Rain"], ["up", "World Enlightenment"],
		["heal", "Heal All"], ["peace", "World Peace"], ["war", "All Against All"], ["godall", "All Venerables in God Mode"], ["fate", "Destroy Fate Gu"]]
	var al: PackedStringArray = PackedStringArray()
	for a: Array in acts:
		al.append("[url=c:do:%s][color=#9fd0ff]»[/color] [b]%s[/b][/url]" % [a[0], a[1]])
	s += "\n".join(al) + "\n"
	s += "\n[color=#9db09e]Beings: %d / %d (technical limit) · Dead in graveyard: %d · Venerables: %d[/color]" % [sim.units.size(), Cheats.HARD_MAX, C.grave.size(), sim.ven.st.size()]
	_modal(s)


func _menu_do(k: String) -> void:
	var C: Cheats = sim.cheats
	m.hud.close_modal()
	match k:
		"j1":
			start_jump(1.0)
		"j10":
			start_jump(10.0)
		"j100":
			start_jump(100.0)
		"r9":
			m._end_presim()
			_hint("Rank 9 Rain", C.r9_rain(mini(60, 5 * C.mult)))
		"up":
			m._end_presim()
			_hint("World Enlightenment", "%d Gu Masters ascend." % C.rank_all(-1))
		"heal":
			var n: int = 0
			for u: Unit in sim.units:
				if u.hp > 0.0:
					C.heal(u)
					n += 1
			_hint("Heal All", "%d beings healed." % n)
		"peace":
			var n2: int = 0
			for a: Clan in sim.clans:
				for e: int in a.war.keys():
					sim.make_peace(a, sim.clans[e], true)
					n2 += 1
				a.plans = a.plans.filter(func(p: Dictionary) -> bool: return str(p["k"]) != "war")
			sim.log_event("World peace: all feuds end.", "jade", true)
			_hint("World Peace", "%d feuds ended." % (n2 / 2))
		"war":
			var live: Array[Clan] = []
			for c: Clan in sim.clans:
				if c.alive:
					live.append(c)
			for i: int in range(live.size()):
				for j: int in range(i + 1, live.size()):
					sim.declare_war(live[i], live[j], true)
			sim.log_event("All clans declare feud on one another!", "war", true)
			_hint("All Against All", "%d clans at war." % live.size())
		"godall":
			var n3: int = 0
			for u2: Unit in sim.units:
				if u2.k == "p" and u2.hp > 0.0 and u2.rank >= 9:
					u2.ch |= Cheats.CH_IMM | Cheats.CH_INV
					n3 += 1
			_hint("God Mode", "%d Venerables are immortal and invulnerable." % n3)
		"fate":
			_hint("Fate Gu", C.fate_break())


## Auswahlfenster eines Werkzeugs (beim Wählen des Werkzeugs).
func open_picker(id: String) -> void:
	match id:
		"c_rset":
			_pick_rank()
		"c_path":
			_pick_path()
		"c_apt":
			_pick_apt()
		"c_give":
			_pick_gu()
		"c_revive":
			_pick_grave()
		"c_army":
			_pick_army()
		"c_mult":
			_pick_mult()


func _pick_rank() -> void:
	var s: String = _h("Set Rank") + "Choose rank and stage, then tap humans.\n" + _h3("Rank")
	var it: PackedStringArray = PackedStringArray()
	for r: int in range(0, 10):
		var lbl: String = "Mortal" if r == 0 else "%d" % r
		it.append("[url=c:r:%d]%s [color=#%s]■[/color] %s[/url]" % [r, _mark(rank_sel == r), GuData.ESS_COL[r].to_html(false) if r > 0 else "c8c0b0", ("[b][u]%s[/u][/b]" if rank_sel == r else "%s") % lbl])
	s += it[0] + "\n" + "    ".join(it.slice(1, 6)) + "\n" + "    ".join(it.slice(6)) + "\n"
	s += "[color=#9db09e]%s[/color]\n" % GuData.rank_title(rank_sel)
	s += _h3("Stage")
	var st: PackedStringArray = PackedStringArray()
	for k: int in range(4):
		st.append("[url=c:s:%d]%s %s[/url]" % [k, _mark(stage_sel == k), GuData.STAGE[k]])
	s += "    ".join(st.slice(0, 2)) + "\n" + "    ".join(st.slice(2)) + "\n[color=#9db09e]Rank 9 has no stages. New Venerables establish their seat and make their path flourish.[/color]"
	_modal(s)


func _pick_path() -> void:
	var s: String = _h("Change Path") + "Tap a path, then Gu Masters.\n"
	for g: Array in Lore.PATH_GROUPS:
		s += _h3(str(g[0]))
		var items: PackedStringArray = PackedStringArray()
		for p: int in g[1]:
			items.append("[url=c:p:%d][color=#%s]■[/color] %s[/url]" % [p, GuData.PATH_COL[p].to_html(false), ("[b][u]%s[/u][/b]" if p == path_sel else "%s") % GuData.PATH_NAME[p]])
		s += "   ".join(items) + "\n"
	_modal(s)


func _pick_apt() -> void:
	var s: String = _h("Set Aptitude") + "Tap an aptitude, then humans. Mortals are awakened in the process.\n\n"
	for a: Array in [["X", "Extreme Physique", "Cultivation ×4; mortal Gu Masters die at 20 without help"], ["A", "A-grade", "×2"], ["B", "B-grade", "×1.4"], ["C", "C-grade", "×1"], ["D", "D-grade", "×0.6"]]:
		s += "[url=c:a:%s]%s [b]%s[/b][/url]  [color=#9db09e]%s[/color]\n" % [a[0], _mark(apt_sel == a[0]), a[1], a[2]]
	_modal(s)


func _pick_gu() -> void:
	var s: String = _h("Give Gu") + "Tap a Gu, then humans. No limit.\n"
	for r: int in [10, 9, 8, 7, 6]:
		var items: PackedStringArray = PackedStringArray()
		for e: Dictionary in Lore.IGU:
			if int(e["r"]) == r:
				var on: bool = give_sel == "i:" + str(e["id"])
				items.append("[url=c:gi:%s][color=#%s]■[/color] %s[/url]" % [e["id"], GuData.PATH_COL[int(e["p"])].to_html(false), ("[b][u]%s[/u][/b]" if on else "%s") % str(e["n"])])
		if not items.is_empty():
			s += _h3("Immortal Gu · Rank %d" % r) + "   ".join(items) + "\n"
	s += _h3("Mortal Gu by Path") + "[color=#9db09e]Tap a path to show its Gu.[/color]\n"
	var ps: PackedStringArray = PackedStringArray()
	for p: int in range(GuData.PATH_NAME.size()):
		ps.append("[url=c:gp:%d][color=#%s]■[/color] %s[/url]" % [p, GuData.PATH_COL[p].to_html(false), ("[b][u]%s[/u][/b]" if p == give_open else "%s") % GuData.PATH_NAME[p]])
	s += "   ".join(ps) + "\n"
	if give_open >= 0:
		var mg: PackedStringArray = Lore.mgu(give_open)
		var gi: PackedStringArray = PackedStringArray()
		for k: int in range(mg.size()):
			gi.append("[url=c:gm:%d:%d]%s[/url]" % [give_open, k, ("[b][u]%s[/u][/b]" if give_sel == "m:" + mg[k] else "%s") % mg[k]])
		s += "\n[color=#%s][b]%s Path:[/b][/color] " % [GuData.PATH_COL[give_open].to_html(false), GuData.PATH_NAME[give_open]] + "   ".join(gi) + "\n"
	_modal(s)


func _pick_grave() -> void:
	var C: Cheats = sim.cheats
	var s: String = _h("Revive") + "Choose a dead one, then tap the map. Without a choice, the most recently deceased returns.\n\n"
	if C.grave.is_empty():
		s += "[color=#9db09e]No Gu Master, Immortal or Venerable has died yet.[/color]"
	for k: int in range(C.grave.size()):
		var e: Dictionary = C.grave[k]
		var d: Dictionary = e["u"]
		var nm: String = (str(d.get("sur", "")) + " " + str(d.get("given", ""))).strip_edges()
		var rk: int = int(d.get("rank", 0))
		s += "[url=c:d:%d]%s [color=#%s]■[/color] [b]%s[/b][/url] [color=#9db09e]%s · %s Path · died in year %d%s[/color]\n" % [k, _mark(grave_sel == k), GuData.ESS_COL[rk].to_html(false), nm, str(d.get("title", "")) if rk >= 9 and str(d.get("title", "")) != "" else GuData.rank_title(rk), GuData.PATH_NAME[clampi(int(d.get("path", 0)), 0, GuData.PATH_NAME.size() - 1)], int(e.get("y", 0)), (" – " + str(e["why"])) if str(e.get("why", "")) != "" else ""]
	_modal(s)


func _pick_army() -> void:
	var s: String = _h("Place Army") + "Choose size and rank, then tap the map. The army joins the nearest village (otherwise it founds a clan).\n" + _h3("Size")
	var it: PackedStringArray = PackedStringArray()
	for n: int in [5, 10, 25, 50, 100, 250]:
		it.append("[url=c:an:%d]%s [b]%d[/b][/url]" % [n, _mark(army_n == n), n])
	s += "   ".join(it) + "\n" + _h3("Rank")
	var rk: PackedStringArray = PackedStringArray()
	for r: int in range(1, 9):
		rk.append("[url=c:ar:%d]%s [color=#%s]■[/color] %d[/url]" % [r, _mark(army_r == r), GuData.ESS_COL[r].to_html(false), r])
	s += "   ".join(rk) + "\n[color=#9db09e]%d × %s[/color]" % [army_n, GuData.rank_title(army_r)]
	_modal(s)


func _pick_mult() -> void:
	var s: String = _h("Spawn Amount") + "How many beings should each spawn tool place at once?\n\n"
	for n: int in Cheats.MULTS:
		s += "[url=c:x:%d]%s [b]×%d[/b][/url]\n" % [n, _mark(sim.cheats.mult == n), n]
	s += "\n[color=#9db09e]Simulation limit: %d beings (now %d).[/color]" % [Cheats.HARD_MAX, sim.units.size()]
	_modal(s)


func _open_soul(u: Unit) -> void:
	if m == null:
		return
	m.hud.open_modal(_h("Soul Search: " + u.pname()) + sim.cheats.soul_text(u), [
		["Follow", func() -> void:
			m.hud.close_modal()
			m.sel_unit = u
			m.follow = true
			m._open_unit(), "jade"],
		["Close", func() -> void: m.hud.close_modal(), ""]])


func _open_rename(u: Unit) -> void:
	if m == null:
		return
	m.hud.open_input(_h("Rename") + "New name for [b]%s[/b] (surname and given name, separated by a space):" % Hud._esc(u.pname()), u.pname(), "Rename", func(txt: String) -> void:
		if u.hp > 0.0:
			sim.cheats.rename(u, txt)
			_hint("Rename", u.pname()))


## Links „c:…“ aus den Cheat-Fenstern.
func meta(mm: String) -> void:
	var parts: PackedStringArray = mm.split(":")
	var k: String = parts[0]
	var v: String = parts[1] if parts.size() > 1 else ""
	var C: Cheats = sim.cheats
	match k:
		"sw":
			C.toggle(v)
			open_menu()
			_refresh_bar()
		"x":
			C.set_mult(int(v))
			if m.hud.modal_title.text == "Spawn Amount":
				_pick_mult()
			else:
				open_menu()
			_hint("Spawn Amount", "×%d – each spawn tool places %d beings." % [C.mult, C.mult])
			_refresh_bar()
		"do":
			_menu_do(v)
		"r":
			rank_sel = clampi(int(v), 0, 9)
			_select("c_rset")
			_pick_rank()
			_hint("Set Rank", GuData.rank_title(rank_sel) + (" · " + GuData.STAGE[stage_sel] if rank_sel > 0 and rank_sel < 9 else "") + ". Tap humans.")
		"s":
			stage_sel = clampi(int(v), 0, 3)
			_select("c_rset")
			_pick_rank()
		"p":
			path_sel = clampi(int(v), 0, GuData.PATH_NAME.size() - 1)
			_select("c_path")
			m.hud.close_modal()
			_hint("Change Path", GuData.PATH_NAME[path_sel] + " Path. Tap Gu Masters.")
		"a":
			apt_sel = v
			_select("c_apt")
			m.hud.close_modal()
			_hint("Set Aptitude", ("Extreme Physique" if v == "X" else v + "-grade") + ". Tap humans.")
		"gi":
			give_sel = "i:" + v
			_select("c_give")
			m.hud.close_modal()
			_hint("Give Gu", Lore.igu_name(v) + ". Tap humans.")
		"gp":
			give_open = -1 if give_open == int(v) else clampi(int(v), 0, GuData.PATH_NAME.size() - 1)
			_pick_gu()
		"gm":
			var mg: PackedStringArray = Lore.mgu(clampi(int(v), 0, GuData.PATH_NAME.size() - 1))
			var idx: int = clampi(int(parts[2]) if parts.size() > 2 else 0, 0, mg.size() - 1)
			give_sel = "m:" + mg[idx]
			_select("c_give")
			m.hud.close_modal()
			_hint("Give Gu", mg[idx] + ". Tap humans.")
		"d":
			grave_sel = clampi(int(v), 0, maxi(0, C.grave.size() - 1))
			_select("c_revive")
			m.hud.close_modal()
			_hint("Revive", "Tap the map where the dead one should return.")
		"an":
			army_n = clampi(int(v), 1, 500)
			_select("c_army")
			_pick_army()
		"ar":
			army_r = clampi(int(v), 1, 8)
			_select("c_army")
			_pick_army()


## Wählt ein Werkzeug (ohne das Auswahlfenster erneut zu öffnen).
func _select(id: String) -> void:
	if m == null or m.tool_id == id:
		return
	var t: Dictionary = Powers.tool_by_id(id)
	if m.tab != TAB:
		m._apply_tab(TAB)
	m.tool_id = id
	powers.pair_sel = null
	clear_sel()
	m.hud.refresh_tools(id, sim.weather.get("type", ""))
	m.hud.show_hint(t["n"], t.get("d", ""))


# ---------------- Entwickler ----------------

## -- --fresh --cheattest: 20 Ehrwürdige (5× Riesensonne), Klonen, Wiederbeleben, Rang setzen, Pfad ändern,
## alle Wesen-Werkzeuge, Clans, Zeitsprung +100 Jahre, Speichern/Laden im Speicher. Endet mit CHEATTEST DONE.
func dev_test() -> void:
	while m.loading or m.presim_on:
		await m.get_tree().process_frame
	var t0: int = Time.get_ticks_msec()
	var C: Cheats = sim.cheats
	print("uniq default ", C.is_on("uniq"), " units ", sim.units.size())
	var gs: Dictionary = {}
	for vd: Dictionary in Lore.VEN:
		if vd["id"] == "giant_sun":
			gs = vd
	var land: Callable = func(i: int) -> bool: return GuData.buildable(sim.world.tile[i])
	# 20 Ehrwürdige: 5× Riesensonne, 3× Roter Lotus, alle anderen einmal, dazu Rang 9 nach Wahl doppelt
	var placed: int = 0
	var fails: PackedStringArray = PackedStringArray()
	var plan: Array = []
	for k: int in range(5):
		plan.append(gs)
	for vd2: Dictionary in Lore.VEN:
		if vd2["id"] != "giant_sun":
			plan.append(vd2)
	for vd3: Dictionary in Lore.VEN:
		if vd3["id"] == "red_lotus":
			plan.append(vd3)
			plan.append(vd3)
	for vd4: Dictionary in plan:
		var p: Vector2 = sim.random_tile(land, 400)
		var msg: String = sim.spawn_venerable(vd4, p.x, p.y)
		if msg == "":
			placed += 1
		else:
			fails.append(msg)
	powers.v9_path = 2
	for k2: int in range(3):
		var p2: Vector2 = sim.random_tile(land, 400)
		if powers.spawn_at(Powers.tool_by_id("s_v9"), p2.x, p2.y) == "":
			placed += 1
	var suns: PackedStringArray = PackedStringArray()
	for u: Unit in sim.units:
		if u.fig == "giant_sun" and u.hp > 0.0:
			suns.append(u.pname())
	print("venerables placed ", placed, " fails ", fails, " states ", sim.ven.st.size(), " riesensonnen ", suns)
	# Einzigartigkeit an: Duplikate werden abgelehnt
	C.set_switch("uniq", true)
	var pp: Vector2 = sim.random_tile(land, 400)
	print("uniq on -> '", sim.spawn_venerable(gs, pp.x, pp.y), "' figure '", sim.spawn_figure(Lore.FIG[0], pp.x, pp.y), "' figure2 '", sim.spawn_figure(Lore.FIG[0], pp.x + 2.0, pp.y), "'")
	C.set_switch("uniq", false)
	# Orte und Organisationen mehrfach
	var pl_ok: int = 0
	for k3: int in range(3):
		var p3: Vector2 = sim.random_tile(land, 400)
		if sim.place_ok("court", p3.x, p3.y) == "":
			sim.add_place("court", p3.x, p3.y, true)
			pl_ok += 1
	var org_ok: int = 0
	for k4: int in range(3):
		var p4: Vector2 = sim.random_tile(land, 400)
		if sim.found_org(Lore.org("shang_clan"), p4.x, p4.y, true) == "":
			org_ok += 1
	var orgn: PackedStringArray = PackedStringArray()
	for c: Clan in sim.clans:
		if c.alive and c.org == "shang_clan":
			orgn.append(c.name)
	print("places court +", pl_ok, " orgs shang +", org_ok, " ", orgn)
	for k5: int in range(30):
		sim.step(0.1)
	# Spawn-Menge ×10
	C.set_mult(10)
	var n0: int = sim.units.size()
	var vp: Vector2 = sim.random_tile(land, 400)
	powers.spawn_at(Powers.tool_by_id("s_gm3"), vp.x, vp.y)
	powers.spawn_at(Powers.tool_by_id("s_wolf"), vp.x, vp.y)
	print("mult x10 spawned ", sim.units.size() - n0)
	C.set_mult(1)
	# Wesen-Werkzeuge über das Tippen (an einem Ort ohne andere Wesen)
	sim.rebuild_grid()
	var tp: Vector2 = vp
	for k8: int in range(200):
		var q: Vector2 = sim.random_tile(land, 400)
		if q.x >= 0.0 and sim.near_units(q.x, q.y, 8.0).is_empty():
			tp = q
			break
	var tgt: Unit = C.make_master(tp.x, tp.y, 2, 0)
	var vl: Village = sim.nearest_village(tp.x, tp.y, 9999.0)
	if vl != null:
		sim.join_village(tgt, vl)
	sim.rebuild_grid()
	var tapu: Callable = func(id: String) -> String:
		sim.rebuild_grid()
		return tap(Powers.tool_by_id(id), tgt.x, tgt.y - 1.5)
	rank_sel = 7
	stage_sel = 2
	print("rset ", tapu.call("c_rset"), " | rank ", tgt.rank, " stage ", tgt.stage)
	path_sel = 47
	print("path ", tapu.call("c_path"), " | ", GuData.PATH_NAME[tgt.path])
	print("rup ", tapu.call("c_rup"), " | rdown ", tapu.call("c_rdown"))
	for id: String in ["c_align", "c_apt", "c_imm", "c_inv", "c_god", "c_young", "c_old", "c_give", "c_strip", "c_luck", "c_lead", "c_ward", "c_trib", "c_will", "c_soul"]:
		print("  ", id, ": ", tapu.call(id))
		m.hud.close_modal()
	give_sel = "m:" + Lore.mgu(3)[1]
	print("  give mortal: ", tapu.call("c_give"))
	rank_sel = 9
	print("r9 ", tapu.call("c_rset"), " ven state ", not sim.ven.state(tgt).is_empty(), " title ", tgt.title)
	var cl: Unit = C.clone(tgt)
	print("clone ", cl.pname(), " rank ", cl.rank, " path ", GuData.PATH_NAME[cl.path], " igu ", cl.igu, " ven ", not sim.ven.state(cl).is_empty())
	# Unverwundbar / Unsterblich wirken
	tgt.ch = Cheats.CH_INV
	sim.hurt(tgt, 1e6, null)
	print("invulnerable hp ", tgt.hp > 0.0)
	tgt.ch = Cheats.CH_IMM
	tgt.dreason = "Himmelswille"
	tgt.hp = 0.0
	sim.step(Sim.DT)
	print("immortal survives will ", tgt.hp > 0.0, " in units ", sim.units.has(tgt))
	tgt.ch = 0
	# Tod und Wiederbeleben
	var victim: Unit = C.make_master(vp.x + 3.0, vp.y, 6, 0)
	victim.given = "Testopfer"
	victim.dreason = "Test"
	sim.hurt(victim, 1e9, null)
	sim.step(Sim.DT)
	print("grave ", C.grave.size(), " top ", str((C.grave[0] as Dictionary)["u"]["given"]))
	grave_sel = 0
	print("revive ", tapu.call("c_revive"))
	# Clans
	var vs: Array[Village] = []
	for v: Village in sim.villages:
		if v.alive:
			vs.append(v)
	if vs.size() >= 3:
		var a: Village = vs[0]
		var b: Village = vs[1]
		for id2: String in ["c_war", "c_peace", "c_ally", "c_take"]:
			tap(Powers.tool_by_id(id2), a.cx, a.cy)
			print("  ", id2, ": ", tap(Powers.tool_by_id(id2), b.cx, b.cy))
		var jn: Unit = C.make_master(a.cx + 2.0, a.cy + 2.0, 1, 0)
		sim.rebuild_grid()
		print("  c_join: ", tap(Powers.tool_by_id("c_join"), jn.x, jn.y - 1.5), " / ", tap(Powers.tool_by_id("c_join"), vs[2].cx, vs[2].cy), " clan ok ", jn.clan == vs[2].clan)
		for id3: String in ["c_vmax", "c_res", "c_clanup", "c_pop", "c_disband"]:
			print("  ", id3, ": ", tap(Powers.tool_by_id(id3), vs[2].cx, vs[2].cy))
	army_n = 50
	army_r = 4
	print("army ", tap(Powers.tool_by_id("c_army"), vp.x, vp.y))
	print("r9rain ", C.r9_rain(5))
	print("fate fix ", C.fate_fix(vp.x, vp.y), " | break ", C.fate_break())
	for sw: Array in Cheats.SWITCHES:
		C.toggle(str(sw[0]))
	print("switches on ", C.flags, " walls law ", sim.laws["walls"])
	for k6: int in range(60):
		sim.step(Sim.DT)
	for sw2: Array in Cheats.SWITCHES:
		C.toggle(str(sw2[0]))
	C.set_switch("notrib", true)
	C.set_switch("stones", true)
	# Fenster
	open_menu()
	for id4: String in ["c_rset", "c_path", "c_apt", "c_give", "c_revive", "c_army", "c_mult"]:
		open_picker(id4)
	meta("gp:5")
	meta("gm:5:1")
	meta("r:6")
	meta("s:3")
	meta("an:10")
	meta("x:5")
	meta("sw:cult10")
	meta("do:heal")
	m.hud.close_modal()
	C.set_mult(1)
	C.set_switch("cult10", false)
	_menu_do("godall")
	# Zeitsprung +100 Jahre
	var y0: int = sim.year()
	var tj: int = Time.get_ticks_msec()
	C.jump(100.0)
	var chunks: int = 0
	while C.jumping():
		C.jump_chunk(2000)
		chunks += 1
		if chunks % 10 == 0:
			print("  jump … year %d · %d beings · %d ms" % [sim.year(), sim.units.size(), Time.get_ticks_msec() - tj])
	var r9: int = 0
	var ss: int = 0
	for u2: Unit in sim.units:
		if u2.k == "p" and u2.rank >= 9:
			r9 += 1
		if u2.fig == "giant_sun":
			ss += 1
	print("jump year %d -> %d in %d ms (%d chunks) · units %d · rank9 %d · riesensonnen %d · era %s" % [y0, sim.year(), Time.get_ticks_msec() - tj, chunks, sim.units.size(), r9, ss, sim.era_text()])
	# Speichern / Laden
	var nch: int = 0
	for u3: Unit in sim.units:
		if u3.ch != 0:
			nch += 1
	var js: String = JSON.stringify(sim.serialize())
	var d: Variant = JSON.parse_string(js)
	var ok: bool = d is Dictionary and sim.deserialize(d)
	var nch2: int = 0
	for u4: Unit in sim.units:
		if u4.ch != 0:
			nch2 += 1
	print("save/load ok=%s v=%d flags=%s grave=%d cheat-units %d / %d ven %d" % [str(ok), int(d["v"]), str(C.flags), C.grave.size(), nch2, nch, sim.ven.st.size()])
	for k7: int in range(120):
		sim.step(0.1)
	print("after load +1y units ", sim.units.size())
	print("CHEATTEST DONE ms ", Time.get_ticks_msec() - t0)
	m.get_tree().quit()


## -- --fresh --cheatshots=<ordner>: Leiste des Reiters „Cheats“, Cheat-Menü, Auswahlfenster, Inspektor (ohne --headless).
func dev_shots(dir: String) -> void:
	while m.loading or m.presim_on:
		await m.get_tree().process_frame
	m._apply_tab(TAB)
	await m._wait(0.3)
	await m._shot(dir + "/bar7_a.png")
	for k: int in [1, 2, 3, 4]:
		m.hud.tools_scroll.scroll_horizontal = 330 * k
		await m._wait(0.2)
		await m._shot(dir + "/bar7_%d.png" % k)
	m.hud.tools_scroll.scroll_horizontal = 0
	open_menu()
	await m._wait(0.3)
	await m._shot(dir + "/menu.png")
	m.hud.close_modal()
	m._click_tool(Powers.tool_by_id("c_rset"))
	await m._wait(0.3)
	await m._shot(dir + "/pick_rank.png")
	m.hud.close_modal()
	m._click_tool(Powers.tool_by_id("c_give"))
	meta("gp:2")
	await m._wait(0.3)
	await m._shot(dir + "/pick_gu.png")
	m.hud.close_modal()
	var v: Village = null
	for vv: Village in sim.villages:
		if vv.alive:
			v = vv
			break
	if v != null:
		var u: Unit = sim.cheats.make_master(v.cx + 2.0, v.cy + 3.0, 7, 0)
		u.ch = Cheats.CH_IMM | Cheats.CH_INV | Cheats.CH_LUCK
		sim.cheats.make_leader(u)
		for k2: int in range(4):
			var gs: Dictionary = Lore.VEN[7]
			sim.spawn_venerable(gs, v.cx + 6.0 + k2 * 3.0, v.cy + 6.0)
		m.zoom_to(u.x, u.y, 6.0)
		m.sel_unit = u
		m._open_unit()
		await m._wait(0.5)
		await m._shot(dir + "/insp.png")
		m._close_insp()
		_open_soul(u)
		await m._wait(0.3)
		await m._shot(dir + "/soul.png")
		m.hud.close_modal()
		await m._wait(0.6)
		await m._shot(dir + "/suns.png")
	sim.cheats.jump(10.0)
	for k3: int in range(6):
		await m.get_tree().process_frame
	await m._shot(dir + "/jump.png")
	m.get_tree().quit()
