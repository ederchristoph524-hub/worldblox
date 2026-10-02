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
		{"id": "c_menu", "tab": T, "g": 0, "n": "Cheat-Menü", "d": "Alle Cheat-Schalter (Einzigartigkeit, unendliche Urstein-Essenz, Sofort-Kultivierung, keine Drangsale …), Spawn-Menge und Sofort-Aktionen.", "m": "act"},
		{"id": "c_mult", "tab": T, "g": 0, "n": "Spawn-Menge", "d": "Wie viele Wesen jedes Setz-Werkzeug auf einmal setzt: ×1, ×5, ×10 oder ×50.", "m": "act"},
		{"id": "c_uniq", "tab": T, "g": 0, "n": "Einzigartigkeit", "d": "Aus (Standard): Ehrwürdige, Figuren, Orte und Organisationen beliebig oft setzen – auch fünfmal Riesensonne. An: kanonische Grenzen.", "m": "act"},
		# 1: Rang, Pfad, Gesinnung
		{"id": "c_rup", "tab": T, "g": 1, "n": "Rang +1", "d": "Tippe auf einen Menschen: Er steigt einen ganzen Rang auf (Sterbliche werden erweckt). Bis Rang 9.", "m": "tap"},
		{"id": "c_rdown", "tab": T, "g": 1, "n": "Rang −1", "d": "Tippe auf einen Gu-Meister: Er fällt einen Rang zurück (bis zum Sterblichen).", "m": "tap"},
		{"id": "c_rset", "tab": T, "g": 1, "n": "Rang setzen", "d": "Wähle Rang 0–9 und Stufe (Anfang, Mitte, Ober, Gipfel), dann tippe auf Menschen.", "m": "tap", "pick": true},
		{"id": "c_path", "tab": T, "g": 1, "n": "Pfad ändern", "d": "Wähle einen der 48 Pfade, dann tippe auf Gu-Meister – auch Ehrwürdige wechseln ihren Pfad (und ihre Ära).", "m": "tap", "pick": true},
		{"id": "c_align", "tab": T, "g": 1, "n": "Gesinnung umdrehen", "d": "Rechtschaffen wird dämonisch und umgekehrt.", "m": "tap"},
		{"id": "c_apt", "tab": T, "g": 1, "n": "Begabung setzen", "d": "Wähle Extremkonstitution oder A–D, dann tippe auf Menschen.", "m": "tap", "pick": true},
		# 2: Leben und Tod
		{"id": "c_imm", "tab": T, "g": 2, "n": "Unsterblich", "d": "Tippe auf ein Wesen (noch einmal = aus): Es altert nicht und stirbt nie an Alter, Drangsal, Himmelswille oder Kalamität.", "m": "tap"},
		{"id": "c_inv", "tab": T, "g": 2, "n": "Unverwundbar", "d": "Tippe auf ein Wesen (noch einmal = aus): Es nimmt keinen Schaden. Nur „Auslöschen“ trifft es noch.", "m": "tap"},
		{"id": "c_god", "tab": T, "g": 2, "n": "Gottmodus", "d": "Unsterblich und unverwundbar zugleich, volle Heilung (noch einmal = aus).", "m": "tap"},
		{"id": "c_heal", "tab": T, "g": 2, "n": "Volle Heilung", "d": "Heilt jedes Wesen im Pinsel vollständig, auch von Seuche und Leichen-Seuche.", "m": "paint"},
		{"id": "c_young", "tab": T, "g": 2, "n": "Verjüngen", "d": "Tippe auf ein Wesen: Es ist wieder 18 Jahre alt, die Lebensspanne wächst mit.", "m": "tap"},
		{"id": "c_old", "tab": T, "g": 2, "n": "Altern", "d": "Tippe auf ein Wesen: 50 Jahre älter.", "m": "tap"},
		{"id": "c_clone", "tab": T, "g": 2, "n": "Klonen", "d": "Tippe auf ein Wesen: Eine genaue Kopie mit Rang, Pfad, Gu und Unsterblichen Gu erscheint daneben (auch Ehrwürdige).", "m": "tap"},
		{"id": "c_revive", "tab": T, "g": 2, "n": "Wiederbeleben", "d": "Wähle einen gestorbenen Gu-Meister, Unsterblichen oder Ehrwürdigen (Standard: zuletzt gestorben), dann tippe dorthin, wo er zurückkehren soll.", "m": "tap", "pick": true},
		# 3: Gu und Seele
		{"id": "c_soul", "tab": T, "g": 3, "n": "Seelensuche", "d": "Tippe auf ein Wesen: alles über seine Seele – Werte, Gu, Unsterbliche Gu, Zustände, Pläne.", "m": "tap"},
		{"id": "c_give", "tab": T, "g": 3, "n": "Gu geben", "d": "Wähle ein Unsterbliches oder sterbliches Gu, dann tippe auf Menschen – ohne Obergrenze.", "m": "tap", "pick": true},
		{"id": "c_strip", "tab": T, "g": 3, "n": "Alle Gu nehmen", "d": "Tippe auf einen Gu-Meister: Er verliert alle Gu und Unsterblichen Gu.", "m": "tap"},
		{"id": "c_name", "tab": T, "g": 3, "n": "Namen ändern", "d": "Tippe auf einen Menschen und gib ihm einen neuen Namen.", "m": "tap"},
		{"id": "c_luck", "tab": T, "g": 3, "n": "Ewiges Glück", "d": "Tippe auf einen Menschen (noch einmal = aus): Großes Glück, das nie vergeht.", "m": "tap"},
		{"id": "c_possess", "tab": T, "g": 3, "n": "Besessenheit", "d": "Tippe ein Wesen an, um es zu besetzen; danach lenkt jedes Tippen es (wie „Seelenbesitz“).", "m": "tap"},
		# 4: Clans und Dörfer
		{"id": "c_join", "tab": T, "g": 4, "n": "Zu Clan hinzufügen", "d": "Tippe zuerst auf einen Menschen, dann auf ein Dorf: Er gehört fortan zu diesem Clan.", "m": "pair"},
		{"id": "c_lead", "tab": T, "g": 4, "n": "Zum Clanführer machen", "d": "Tippe auf ein Clan-Mitglied: Es wird Clan-Oberhaupt, auch wenn es nicht das stärkste ist.", "m": "tap"},
		{"id": "c_war", "tab": T, "g": 4, "n": "Krieg erklären", "d": "Tippe zwei Dörfer verschiedener Clans an: sofortiger Krieg.", "m": "pair"},
		{"id": "c_peace", "tab": T, "g": 4, "n": "Frieden schließen", "d": "Tippe zwei Dörfer an: Ihre Clans schließen Frieden.", "m": "pair"},
		{"id": "c_ally", "tab": T, "g": 4, "n": "Bündnis schmieden", "d": "Tippe zwei Dörfer an: Ihre Clans verbünden sich.", "m": "pair"},
		{"id": "c_take", "tab": T, "g": 4, "n": "Dorf übernehmen", "d": "Tippe zuerst auf ein Dorf des neuen Herrn, dann auf das Dorf, das ihm gehören soll – ohne Krieg.", "m": "pair"},
		{"id": "c_disband", "tab": T, "g": 4, "n": "Clan auflösen", "d": "Tippe auf ein Dorf: Sein Clan zerfällt – jedes Dorf wird ein eigener Clan, ein Clan mit nur einem Dorf löst sich ganz auf.", "m": "tap"},
		{"id": "c_vmax", "tab": T, "g": 4, "n": "Dorf voll ausbauen", "d": "Tippe auf ein Dorf: Ahnenhalle, zwölf Hütten, Felder, Gu-Veredelung, Türme und volle Vorräte.", "m": "tap"},
		{"id": "c_res", "tab": T, "g": 4, "n": "Unendliche Vorräte", "d": "Tippe auf ein Dorf (noch einmal = aus): Nahrung, Holz und Ursteine gehen nie aus.", "m": "tap"},
		{"id": "c_clanup", "tab": T, "g": 4, "n": "Clan +1 Rang", "d": "Tippe auf ein Dorf: Alle Gu-Meister seines Clans (Rang 1–7) steigen einen Rang auf.", "m": "tap"},
		{"id": "c_pop", "tab": T, "g": 4, "n": "Bevölkerungs-Schub", "d": "Tippe auf ein Dorf: 20 neue erwachsene Bewohner.", "m": "tap"},
		# 5: Masse
		{"id": "c_army", "tab": T, "g": 5, "n": "Armee setzen", "d": "Wähle Größe und Rang, dann tippe auf die Karte: eine ganze Armee von Gu-Meistern für das nächste Dorf.", "m": "tap", "pick": true},
		{"id": "c_r9rain", "tab": T, "g": 5, "n": "Rang-9-Regen", "d": "Fünf Ehrwürdige zufälliger Pfade steigen überall in der Welt herab (× Spawn-Menge, höchstens 60).", "m": "act"},
		{"id": "c_worldup", "tab": T, "g": 5, "n": "Weltweite Erleuchtung", "d": "Jeder Gu-Meister der Welt (Rang 1–7) steigt einen Rang auf.", "m": "act"},
		# 6: Zeit
		{"id": "c_j1", "tab": T, "g": 6, "n": "Zeitsprung +1 Jahr", "d": "Die Welt läuft ein Jahr im Zeitraffer weiter.", "m": "act", "jump": 1},
		{"id": "c_j10", "tab": T, "g": 6, "n": "Zeitsprung +10 Jahre", "d": "Zehn Jahre im Zeitraffer, mit Fortschrittsanzeige oben links.", "m": "act", "jump": 10},
		{"id": "c_j100", "tab": T, "g": 6, "n": "Zeitsprung +100 Jahre", "d": "Hundert Jahre im Zeitraffer – Clans steigen auf und fallen, Ehrwürdige herrschen.", "m": "act", "jump": 100},
		{"id": "c_age", "tab": T, "g": 6, "n": "Zeitalter setzen", "d": "Öffnet die zehn Zeitalter: Tippe eines an, um es sofort beginnen zu lassen.", "m": "act"},
		{"id": "c_freeze", "tab": T, "g": 6, "n": "Wesen einfrieren", "d": "Alle Wesen erstarren (noch einmal = auftauen); die Zeit läuft weiter.", "m": "act"},
		# 7: Himmel und Schicksal
		{"id": "c_will", "tab": T, "g": 7, "n": "Himmelswille auf Ziel", "d": "Tippe auf einen Gu-Meister: Der Himmelswille richtet sich gegen ihn.", "m": "tap"},
		{"id": "c_trib", "tab": T, "g": 7, "n": "Drangsal auslösen", "d": "Tippe auf einen Gu-Meister: Eine Himmelsdrangsal kommt über ihn.", "m": "tap"},
		{"id": "c_ward", "tab": T, "g": 7, "n": "Drangsal abwenden", "d": "Tippe auf einen Gu-Meister: 100 Jahre keine Drangsal, kein Himmelswille, keine Kalamität.", "m": "tap"},
		{"id": "c_fatebreak", "tab": T, "g": 7, "n": "Schicksals-Gu zerstören", "d": "Das Schicksals-Gu zerbricht, wo immer es ist – Rang 9 steht offen, der Himmelswille wird schwächer.", "m": "act"},
		{"id": "c_fatefix", "tab": T, "g": 7, "n": "Schicksals-Gu wiederherstellen", "d": "Tippe auf die Karte: Ein neues Schicksals-Gu erscheint dort, die Fesseln des Schicksals sind wieder geknüpft.", "m": "tap"},
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
				return "Tippe auf ein Dorf."
			var c: Clan = sim.clans[v.clan]
			match id:
				"c_disband":
					return C.disband(c)
				"c_vmax":
					return C.village_max(v)
				"c_res":
					if C.inf_v.has(v.id):
						C.inf_v.erase(v.id)
						return v.name + ": Vorräte wieder endlich."
					C.inf_v[v.id] = true
					C.month_villages()
					sim.pillar(v.cx, v.cy, Color("#ffd23a"), 0.7)
					return v.name + ": unendliche Vorräte."
				"c_clanup":
					var n: int = C.rank_all(c.id)
					sim.pillar(v.cx, v.cy, Color("#fff3c0"), 1.0)
					sim.log_event("Alle %d Gu-Meister von %s steigen durch Götterhand auf." % [n, c.name], "gold", true)
					return "%d Gu-Meister von %s steigen auf." % [n, c.name]
				_:
					return C.populate(v, 20)
		"c_army":
			return C.army(wx, wy, army_n, army_r)
		"c_revive":
			if C.grave.is_empty():
				return "Noch ist kein bemerkenswertes Wesen gestorben."
			if not sim.world.in_map(int(wx), int(wy)):
				return ""
			var r: Unit = C.revive(grave_sel, wx, wy)
			grave_sel = 0
			if r == null:
				return C.full_msg()
			return r.pname() + " lebt wieder (" + GuData.rank_title(r.rank) + ")."
		"c_fatefix":
			return C.fate_fix(wx, wy)
		"c_possess":
			return powers.possess_tap(wx, wy, false)
	var persons: bool = not (id in ["c_imm", "c_inv", "c_god", "c_young", "c_old", "c_clone", "c_soul"])
	var u: Unit = unit_at(wx, wy, persons)
	if u == null:
		return "Tippe auf einen Menschen." if persons else "Tippe auf ein Wesen."
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
			sim.float_txt(u, "Unsterblich" if on else "sterblich", Color("#ffd23a"))
			sim.ring(u.x, u.y - 2.0, 3.0, Color("#ffd23a"), 0.6)
			return u.pname() + (" ist unsterblich." if on else " ist wieder sterblich.")
		"c_inv":
			var on2: bool = C.toggle_ch(u, Cheats.CH_INV)
			sim.float_txt(u, "Unverwundbar" if on2 else "verwundbar", Color("#7ef0ff"))
			sim.ring(u.x, u.y - 2.0, 3.0, Color("#7ef0ff"), 0.6)
			return u.pname() + (" ist unverwundbar." if on2 else " ist wieder verwundbar.")
		"c_god":
			var on3: bool = C.god(u)
			sim.float_txt(u, "Gottmodus" if on3 else "Gottmodus aus", Color("#ffe27a"))
			sim.pillar(u.x, u.y, Color("#ffe27a"), 0.6)
			return u.pname() + (": Gottmodus an." if on3 else ": Gottmodus aus.")
		"c_young":
			return C.rejuvenate(u)
		"c_old":
			return C.age_up(u, 50.0)
		"c_clone":
			var c2: Unit = C.clone(u)
			return C.full_msg() if c2 == null else c2.pname() + " ist geklont."
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
			return u.pname() + (": ewiges Glück." if on4 else ": Glück wie alle anderen.")
		"c_lead":
			return C.make_leader(u)
		"c_will":
			if u.rank <= 0:
				return "Der Himmelswille richtet sich nur gegen Gu-Meister."
			sim.heavens_will(u)
			return ""
		"c_trib":
			if u.rank <= 0:
				return "Nur Gu-Meister erleiden Drangsale."
			sim.tribulation(u)
			return ""
		"c_ward":
			u.prot = sim.sim_time + 1200.0
			u.next_trib = maxf(u.next_trib, sim.uage(u) + 100.0)
			u.fxm = true
			sim.ring(u.x, u.y - 2.0, 4.0, Color("#bfe8ff"), 0.8)
			sim.float_txt(u, "Himmelsschutz 100 Jahre", Color("#bfe8ff"))
			return u.pname() + " steht 100 Jahre unter Himmelsschutz."
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
		return "Tippe auf ein Dorf."
	if sel_vil == null or not sel_vil.alive:
		sel_vil = v
		return sim.clans[v.clan].name + " gewählt – jetzt das zweite Dorf antippen."
	var a: Clan = sim.clans[sel_vil.clan]
	var b: Clan = sim.clans[v.clan]
	sel_vil = null
	if id == "c_take":
		return sim.cheats.take_village(a, v)
	if a == b:
		return "Wähle zwei verschiedene Clans."
	match id:
		"c_war":
			sim.declare_war(a, b)
			return a.name + " und " + b.name + " sind im Krieg."
		"c_peace":
			sim.make_peace(a, b)
			a.plans = a.plans.filter(func(p: Dictionary) -> bool: return int(p["o"]) != b.id)
			b.plans = b.plans.filter(func(p: Dictionary) -> bool: return int(p["o"]) != a.id)
			return a.name + " und " + b.name + " leben in Frieden."
		_:
			sim.make_ally(a, b)
			return a.name + " und " + b.name + " sind verbündet."


func _join(wx: float, wy: float) -> String:
	if sel_unit == null or sel_unit.hp <= 0.0:
		var u: Unit = unit_at(wx, wy, true)
		if u == null:
			return "Tippe zuerst auf einen Menschen."
		sel_unit = u
		sim.ring(u.x, u.y - 1.5, 2.0, Color("#ffe27a"), 0.6)
		return u.pname() + " gewählt – jetzt das Dorf antippen."
	var v: Village = _vil_at(wx, wy)
	if v == null:
		return "Tippe auf ein Dorf."
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
			_hint(t["n"], C.toggle("uniq") + (" – kanonische Grenzen." if C.is_on("uniq") else " – alles beliebig oft setzbar."))
		"c_r9rain":
			m._end_presim()
			_hint(t["n"], C.r9_rain(mini(60, 5 * C.mult)))
		"c_worldup":
			m._end_presim()
			_hint(t["n"], "%d Gu-Meister steigen auf." % C.rank_all(-1))
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
	_hint("Zeitsprung", "+%d Jahre im Zeitraffer – bis Jahr %d." % [int(years), sim.year() + int(sim.cheats.jump_left / 12.0)])


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
	return "[color=#5fbf8a][b]● AN[/b][/color]" if on else "[color=#c74634][b]○ AUS[/b][/color]"


func _modal(s: String, done: bool = true) -> void:
	if m == null:
		return
	m.hud.open_modal(s, [["Fertig", func() -> void: m.hud.close_modal(), "jade"]] if done else [])


## Cheat-Menü: alle globalen Schalter, Spawn-Menge, Sofort-Aktionen.
func open_menu() -> void:
	var C: Cheats = sim.cheats
	var s: String = _h("Cheat-Menü") + "Die Schalter gelten für die ganze Welt und werden mit ihr gespeichert. Tippe zum Umschalten.\n"
	s += _h3("Schalter")
	for e: Array in Cheats.SWITCHES:
		s += "[url=c:sw:%s]%s  [b]%s[/b][/url]\n    [color=#9db09e]%s[/color]\n" % [e[0], _switch(C.is_on(str(e[0]))), e[1], e[2]]
	s += _h3("Spawn-Menge")
	var it: PackedStringArray = PackedStringArray()
	for n: int in Cheats.MULTS:
		it.append("[url=c:x:%d]%s [b]×%d[/b][/url]" % [n, _mark(C.mult == n), n])
	s += "    ".join(it) + "\n[color=#9db09e]Jedes Setz-Werkzeug (Völker, Tiere, Gu-Meister, Ehrwürdige, Figuren, Gu) setzt so viele auf einmal.[/color]\n"
	s += _h3("Sofort")
	var acts: Array = [["j1", "+1 Jahr"], ["j10", "+10 Jahre"], ["j100", "+100 Jahre"], ["r9", "Rang-9-Regen"], ["up", "Weltweite Erleuchtung"],
		["heal", "Alle heilen"], ["peace", "Weltfrieden"], ["war", "Alle gegen alle"], ["godall", "Alle Ehrwürdigen im Gottmodus"], ["fate", "Schicksals-Gu zerstören"]]
	var al: PackedStringArray = PackedStringArray()
	for a: Array in acts:
		al.append("[url=c:do:%s][color=#9fd0ff]»[/color] [b]%s[/b][/url]" % [a[0], a[1]])
	s += "\n".join(al) + "\n"
	s += "\n[color=#9db09e]Wesen: %d / %d (technische Grenze) · Tote im Friedhof: %d · Ehrwürdige: %d[/color]" % [sim.units.size(), Cheats.HARD_MAX, C.grave.size(), sim.ven.st.size()]
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
			_hint("Rang-9-Regen", C.r9_rain(mini(60, 5 * C.mult)))
		"up":
			m._end_presim()
			_hint("Weltweite Erleuchtung", "%d Gu-Meister steigen auf." % C.rank_all(-1))
		"heal":
			var n: int = 0
			for u: Unit in sim.units:
				if u.hp > 0.0:
					C.heal(u)
					n += 1
			_hint("Alle heilen", "%d Wesen sind geheilt." % n)
		"peace":
			var n2: int = 0
			for a: Clan in sim.clans:
				for e: int in a.war.keys():
					sim.make_peace(a, sim.clans[e], true)
					n2 += 1
				a.plans = a.plans.filter(func(p: Dictionary) -> bool: return str(p["k"]) != "war")
			sim.log_event("Weltfrieden: Alle Fehden enden.", "jade", true)
			_hint("Weltfrieden", "%d Fehden beendet." % (n2 / 2))
		"war":
			var live: Array[Clan] = []
			for c: Clan in sim.clans:
				if c.alive:
					live.append(c)
			for i: int in range(live.size()):
				for j: int in range(i + 1, live.size()):
					sim.declare_war(live[i], live[j], true)
			sim.log_event("Alle Clans erklären einander die Fehde!", "war", true)
			_hint("Alle gegen alle", "%d Clans im Krieg." % live.size())
		"godall":
			var n3: int = 0
			for u2: Unit in sim.units:
				if u2.k == "p" and u2.hp > 0.0 and u2.rank >= 9:
					u2.ch |= Cheats.CH_IMM | Cheats.CH_INV
					n3 += 1
			_hint("Gottmodus", "%d Ehrwürdige sind unsterblich und unverwundbar." % n3)
		"fate":
			_hint("Schicksals-Gu", C.fate_break())


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
	var s: String = _h("Rang setzen") + "Wähle Rang und Stufe, dann tippe auf Menschen.\n" + _h3("Rang")
	var it: PackedStringArray = PackedStringArray()
	for r: int in range(0, 10):
		var lbl: String = "Sterblich" if r == 0 else "%d" % r
		it.append("[url=c:r:%d]%s [color=#%s]■[/color] %s[/url]" % [r, _mark(rank_sel == r), GuData.ESS_COL[r].to_html(false) if r > 0 else "c8c0b0", ("[b][u]%s[/u][/b]" if rank_sel == r else "%s") % lbl])
	s += it[0] + "\n" + "    ".join(it.slice(1, 6)) + "\n" + "    ".join(it.slice(6)) + "\n"
	s += "[color=#9db09e]%s[/color]\n" % GuData.rank_title(rank_sel)
	s += _h3("Stufe")
	var st: PackedStringArray = PackedStringArray()
	for k: int in range(4):
		st.append("[url=c:s:%d]%s %s[/url]" % [k, _mark(stage_sel == k), GuData.STAGE[k]])
	s += "    ".join(st.slice(0, 2)) + "\n" + "    ".join(st.slice(2)) + "\n[color=#9db09e]Rang 9 hat keine Stufen. Neue Ehrwürdige errichten ihren Sitz und lassen ihren Pfad erblühen.[/color]"
	_modal(s)


func _pick_path() -> void:
	var s: String = _h("Pfad ändern") + "Tippe auf einen Pfad, dann auf Gu-Meister.\n"
	for g: Array in Lore.PATH_GROUPS:
		s += _h3(str(g[0]))
		var items: PackedStringArray = PackedStringArray()
		for p: int in g[1]:
			items.append("[url=c:p:%d][color=#%s]■[/color] %s[/url]" % [p, GuData.PATH_COL[p].to_html(false), ("[b][u]%s[/u][/b]" if p == path_sel else "%s") % GuData.PATH_NAME[p]])
		s += "   ".join(items) + "\n"
	_modal(s)


func _pick_apt() -> void:
	var s: String = _h("Begabung setzen") + "Tippe auf eine Begabung, dann auf Menschen. Sterbliche werden dabei erweckt.\n\n"
	for a: Array in [["X", "Extremkonstitution", "Kultivierung ×4; Sterbliche Gu-Meister sterben ohne Hilfe mit 20"], ["A", "A-Grad", "×2"], ["B", "B-Grad", "×1,4"], ["C", "C-Grad", "×1"], ["D", "D-Grad", "×0,6"]]:
		s += "[url=c:a:%s]%s [b]%s[/b][/url]  [color=#9db09e]%s[/color]\n" % [a[0], _mark(apt_sel == a[0]), a[1], a[2]]
	_modal(s)


func _pick_gu() -> void:
	var s: String = _h("Gu geben") + "Tippe auf ein Gu, dann auf Menschen. Ohne Obergrenze.\n"
	for r: int in [10, 9, 8, 7, 6]:
		var items: PackedStringArray = PackedStringArray()
		for e: Dictionary in Lore.IGU:
			if int(e["r"]) == r:
				var on: bool = give_sel == "i:" + str(e["id"])
				items.append("[url=c:gi:%s][color=#%s]■[/color] %s[/url]" % [e["id"], GuData.PATH_COL[int(e["p"])].to_html(false), ("[b][u]%s[/u][/b]" if on else "%s") % str(e["n"])])
		if not items.is_empty():
			s += _h3("Unsterbliche Gu · Rang %d" % r) + "   ".join(items) + "\n"
	s += _h3("Sterbliche Gu nach Pfad") + "[color=#9db09e]Tippe auf einen Pfad, um seine Gu zu zeigen.[/color]\n"
	var ps: PackedStringArray = PackedStringArray()
	for p: int in range(GuData.PATH_NAME.size()):
		ps.append("[url=c:gp:%d][color=#%s]■[/color] %s[/url]" % [p, GuData.PATH_COL[p].to_html(false), ("[b][u]%s[/u][/b]" if p == give_open else "%s") % GuData.PATH_NAME[p]])
	s += "   ".join(ps) + "\n"
	if give_open >= 0:
		var mg: PackedStringArray = Lore.mgu(give_open)
		var gi: PackedStringArray = PackedStringArray()
		for k: int in range(mg.size()):
			gi.append("[url=c:gm:%d:%d]%s[/url]" % [give_open, k, ("[b][u]%s[/u][/b]" if give_sel == "m:" + mg[k] else "%s") % mg[k]])
		s += "\n[color=#%s][b]%s-Pfad:[/b][/color] " % [GuData.PATH_COL[give_open].to_html(false), GuData.PATH_NAME[give_open]] + "   ".join(gi) + "\n"
	_modal(s)


func _pick_grave() -> void:
	var C: Cheats = sim.cheats
	var s: String = _h("Wiederbeleben") + "Wähle einen Toten, dann tippe auf die Karte. Ohne Wahl kehrt der zuletzt Gestorbene zurück.\n\n"
	if C.grave.is_empty():
		s += "[color=#9db09e]Noch ist kein Gu-Meister, Unsterblicher oder Ehrwürdiger gestorben.[/color]"
	for k: int in range(C.grave.size()):
		var e: Dictionary = C.grave[k]
		var d: Dictionary = e["u"]
		var nm: String = (str(d.get("sur", "")) + " " + str(d.get("given", ""))).strip_edges()
		var rk: int = int(d.get("rank", 0))
		s += "[url=c:d:%d]%s [color=#%s]■[/color] [b]%s[/b][/url] [color=#9db09e]%s · %s-Pfad · gestorben Jahr %d%s[/color]\n" % [k, _mark(grave_sel == k), GuData.ESS_COL[rk].to_html(false), nm, str(d.get("title", "")) if rk >= 9 and str(d.get("title", "")) != "" else GuData.rank_title(rk), GuData.PATH_NAME[clampi(int(d.get("path", 0)), 0, GuData.PATH_NAME.size() - 1)], int(e.get("y", 0)), (" – " + str(e["why"])) if str(e.get("why", "")) != "" else ""]
	_modal(s)


func _pick_army() -> void:
	var s: String = _h("Armee setzen") + "Wähle Größe und Rang, dann tippe auf die Karte. Die Armee schließt sich dem nächsten Dorf an (sonst gründet sie einen Clan).\n" + _h3("Größe")
	var it: PackedStringArray = PackedStringArray()
	for n: int in [5, 10, 25, 50, 100, 250]:
		it.append("[url=c:an:%d]%s [b]%d[/b][/url]" % [n, _mark(army_n == n), n])
	s += "   ".join(it) + "\n" + _h3("Rang")
	var rk: PackedStringArray = PackedStringArray()
	for r: int in range(1, 9):
		rk.append("[url=c:ar:%d]%s [color=#%s]■[/color] %d[/url]" % [r, _mark(army_r == r), GuData.ESS_COL[r].to_html(false), r])
	s += "   ".join(rk) + "\n[color=#9db09e]%d × %s[/color]" % [army_n, GuData.rank_title(army_r)]
	_modal(s)


func _pick_mult() -> void:
	var s: String = _h("Spawn-Menge") + "Wie viele Wesen setzt jedes Setz-Werkzeug auf einmal?\n\n"
	for n: int in Cheats.MULTS:
		s += "[url=c:x:%d]%s [b]×%d[/b][/url]\n" % [n, _mark(sim.cheats.mult == n), n]
	s += "\n[color=#9db09e]Obergrenze der Simulation: %d Wesen (jetzt %d).[/color]" % [Cheats.HARD_MAX, sim.units.size()]
	_modal(s)


func _open_soul(u: Unit) -> void:
	if m == null:
		return
	m.hud.open_modal(_h("Seelensuche: " + u.pname()) + sim.cheats.soul_text(u), [
		["Folgen", func() -> void:
			m.hud.close_modal()
			m.sel_unit = u
			m.follow = true
			m._open_unit(), "jade"],
		["Schließen", func() -> void: m.hud.close_modal(), ""]])


func _open_rename(u: Unit) -> void:
	if m == null:
		return
	m.hud.open_input(_h("Namen ändern") + "Neuer Name für [b]%s[/b] (Familienname und Vorname, durch ein Leerzeichen getrennt):" % Hud._esc(u.pname()), u.pname(), "Umbenennen", func(txt: String) -> void:
		if u.hp > 0.0:
			sim.cheats.rename(u, txt)
			_hint("Namen ändern", u.pname()))


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
			if m.hud.modal_title.text == "Spawn-Menge":
				_pick_mult()
			else:
				open_menu()
			_hint("Spawn-Menge", "×%d – jedes Setz-Werkzeug setzt %d Wesen." % [C.mult, C.mult])
			_refresh_bar()
		"do":
			_menu_do(v)
		"r":
			rank_sel = clampi(int(v), 0, 9)
			_select("c_rset")
			_pick_rank()
			_hint("Rang setzen", GuData.rank_title(rank_sel) + (" · " + GuData.STAGE[stage_sel] if rank_sel > 0 and rank_sel < 9 else "") + ". Tippe auf Menschen.")
		"s":
			stage_sel = clampi(int(v), 0, 3)
			_select("c_rset")
			_pick_rank()
		"p":
			path_sel = clampi(int(v), 0, GuData.PATH_NAME.size() - 1)
			_select("c_path")
			m.hud.close_modal()
			_hint("Pfad ändern", GuData.PATH_NAME[path_sel] + "-Pfad. Tippe auf Gu-Meister.")
		"a":
			apt_sel = v
			_select("c_apt")
			m.hud.close_modal()
			_hint("Begabung setzen", ("Extremkonstitution" if v == "X" else v + "-Grad") + ". Tippe auf Menschen.")
		"gi":
			give_sel = "i:" + v
			_select("c_give")
			m.hud.close_modal()
			_hint("Gu geben", Lore.igu_name(v) + ". Tippe auf Menschen.")
		"gp":
			give_open = -1 if give_open == int(v) else clampi(int(v), 0, GuData.PATH_NAME.size() - 1)
			_pick_gu()
		"gm":
			var mg: PackedStringArray = Lore.mgu(clampi(int(v), 0, GuData.PATH_NAME.size() - 1))
			var idx: int = clampi(int(parts[2]) if parts.size() > 2 else 0, 0, mg.size() - 1)
			give_sel = "m:" + mg[idx]
			_select("c_give")
			m.hud.close_modal()
			_hint("Gu geben", mg[idx] + ". Tippe auf Menschen.")
		"d":
			grave_sel = clampi(int(v), 0, maxi(0, C.grave.size() - 1))
			_select("c_revive")
			m.hud.close_modal()
			_hint("Wiederbeleben", "Tippe auf die Karte, wo der Tote zurückkehren soll.")
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
			print("  jump … Jahr %d · %d Wesen · %d ms" % [sim.year(), sim.units.size(), Time.get_ticks_msec() - tj])
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
