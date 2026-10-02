class_name RankTest
extends RefCounted
## Entwickler-Test `-- --fresh --ranktest`: Arenakämpfe zwischen den Rängen (Machtmodell aus Sim.might/dmg_mul)
## und danach 50 Jahre Weltsimulation mit Bevölkerungs-Übersicht. Endet mit RANKTEST DONE.


static func run(m: GuMain, arena: bool = true, health: bool = true) -> void:
	while m.loading or m.presim_on:
		await m.get_tree().process_frame
	var t0: int = Time.get_ticks_msec()
	if health:
		world_health(m.sim, 50)
	if arena:
		arena_all(m.sim)
	print("RANKTEST DONE ms ", Time.get_ticks_msec() - t0)
	m.get_tree().quit()


## Bevölkerung, Dörfer, Clans, Ränge und Kriege alle 10 Jahre.
static func world_health(sim: Sim, years: int) -> void:
	print("--- Weltgesundheit über %d Jahre ---" % years)
	var why: Dictionary = {}
	var cb: Callable = func(u: Unit) -> void:
		if u.k == "p":
			var r: String = u.dreason
			if r.begins_with("getötet von "):
				r = "getötet"
			why[r] = int(why.get(r, 0)) + 1
	sim.unit_died.connect(cb)
	var l0: int = sim.log_entries.size()
	_census(sim, "start")
	for yr: int in range(years):
		for k: int in range(120):
			sim.step(0.1)
		if yr % 10 == 9:
			_census(sim, "J+%d" % (yr + 1))
	sim.unit_died.disconnect(cb)
	print("Todesursachen (Menschen): ", why)
	var caps: int = 0
	for e: Dictionary in sim.log_entries:
		var t: String = str(e["t"])
		if t.contains("beugt sich"):
			caps += 1
			if caps <= 6:
				print("  J%d %s" % [int(e["y"]), t])
	print("Unterwerfungen: ", caps)


static func _census(sim: Sim, tag: String) -> void:
	var ranks: PackedInt32Array = PackedInt32Array()
	ranks.resize(10)
	var pers: int = 0
	var anim: int = 0
	for u: Unit in sim.units:
		if u.hp <= 0.0:
			continue
		if u.k == "p":
			pers += 1
			ranks[clampi(u.rank, 0, 9)] += 1
		else:
			anim += 1
	var vil: int = 0
	for v: Village in sim.villages:
		if v.alive:
			vil += 1
	var cl: int = 0
	var wars: int = 0
	for c: Clan in sim.clans:
		if c.alive:
			cl += 1
			wars += c.war.size()
	print("%-6s Jahr %4d · Menschen %4d · Tiere %4d · Dörfer %3d · Clans %3d · Kriege %2d · Ränge %s" % [tag, sim.year(), pers, anim, vil, cl, wars / 2, str(Array(ranks))])


# ---------------- Arena ----------------

## Szenarien: [Name, Einzelkämpfer [Rang, Stufe], Gruppe [Rang, Stufe, Anzahl], Wiederholungen, Erwartung]
const SCEN: Array = [
	["a) R6 Anfang vs 50 R5 Spitze", [6, 0], [5, 3, 50], 3, "R6 gewinnt"],
	["b) R5 Anfang vs 8 R4 Anfang", [5, 0], [4, 0, 8], 6, "R5 gewinnt"],
	["b2) R5 Anfang vs 5 R4 Spitze", [5, 0], [4, 3, 5], 6, "R5 meist"],
	["b3) R5 Anfang vs 14 R4 Anfang", [5, 0], [4, 0, 14], 6, "Grenze"],
	["m1) R2 Anfang vs 6 R1 Anfang", [2, 0], [1, 0, 6], 6, "R2 gewinnt"],
	["m2) R3 Anfang vs 6 R2 Anfang", [3, 0], [2, 0, 6], 6, "R3 gewinnt"],
	["m3) R4 Anfang vs 6 R3 Anfang", [4, 0], [3, 0, 6], 6, "R4 gewinnt"],
	["m4) R3 Anfang vs 14 R2 Anfang", [3, 0], [2, 0, 14], 6, "Grenze"],
	["c) R7 Anfang vs 5 R6 Anfang", [7, 0], [6, 0, 5], 6, "R7 gewinnt"],
	["c2) R7 Anfang vs 10 R6 Anfang", [7, 0], [6, 0, 10], 4, "Grenze"],
	["c3) R7 Anfang vs 20 R6 Anfang", [7, 0], [6, 0, 20], 3, "Grenze"],
	["d) R8 Anfang vs 8 R7 Anfang", [8, 0], [7, 0, 8], 4, "R8 gewinnt"],
	["d2) R8 Anfang vs 16 R7 Anfang", [8, 0], [7, 0, 16], 3, "Grenze"],
	["e) R9 vs 20 R8 Spitze", [9, 0], [8, 3, 20], 2, "R9 ohne Schaden"],
	["e2) R9 vs 300 R5 Spitze", [9, 0], [5, 3, 300], 1, "R9 ohne Schaden"],
	["f) R9 vs R9", [9, 0], [9, 0, 1], 3, "lang"],
	["g) R3 Spitze vs R3 Anfang", [3, 3], [3, 0, 1], 20, "Spitze meist"],
	["g2) R5 Spitze vs R5 Anfang", [5, 3], [5, 0, 1], 20, "Spitze meist"],
	["g3) R6 Spitze vs R6 Anfang", [6, 3], [6, 0, 1], 12, "Spitze meist"],
	["g4) R5 Spitze vs R5 Mittel", [5, 3], [5, 1, 1], 20, "Spitze meist"],
]


static func arena_all(sim: Sim) -> void:
	print("--- Arena (Machtmodell) ---")
	var laws0: Dictionary = sim.laws.duplicate()
	for k: String in ["trib", "will", "disaster", "tide", "growth", "animals", "expand", "diplo", "hunger", "revolt"]:
		if sim.laws.has(k):
			sim.laws[k] = false
	sim.wipe_life()
	sim.log_entries.clear()
	sim.arena = true
	var c: Vector2 = _spot(sim)
	print("Arena bei (%d, %d)" % [int(c.x), int(c.y)])
	print("%-34s | Siege Einzel | Ø Dauer (Mon.) | Ø Überlebende Gruppe | Ø HP-Verlust Einzel (min HP) | Erwartung" % "Szenario")
	for sc: Array in SCEN:
		var wins: int = 0
		var dur: float = 0.0
		var surv: float = 0.0
		var lost: float = 0.0
		var reps: int = int(sc[3])
		for k: int in range(reps):
			var r: Dictionary = fight(sim, c, sc[1], sc[2])
			if r["solo_won"]:
				wins += 1
			dur += float(r["t"])
			surv += float(r["grp_left"])
			lost += float(r["lost"])
		print("%-34s | %2d / %-2d      | %6.1f         | %5.1f                | %5.1f %%                     | %s" % [sc[0], wins, reps, dur / reps, surv / reps, 100.0 * lost / reps, sc[4]])
	sim.arena = false
	sim.laws = laws0
	sim.wipe_life()


## Ein Kampf: Einzelner (Clan A) gegen Gruppe (Clan B) bis eine Seite tot ist (höchstens 80 Monate).
static func fight(sim: Sim, c: Vector2, solo: Array, grp: Array) -> Dictionary:
	for u: Unit in sim.units:
		u.hp = 0.0
	sim.units.clear()
	sim.projs.clear()
	sim.sched.clear()
	var ca: Clan = sim.new_clan(4, "")
	var cb: Clan = sim.new_clan(4, "")
	sim.declare_war(ca, cb, true)
	var s: Unit = _mk(sim, c.x - 4.0, c.y, int(solo[0]), int(solo[1]), ca)
	var g: Array[Unit] = []
	var n: int = int(grp[2])
	for k: int in range(n):
		var a: float = randf() * TAU
		var rr: float = sqrt(randf()) * (2.0 + sqrt(float(n)) * 0.9)
		g.append(_mk(sim, c.x + 4.0 + cos(a) * rr, c.y + sin(a) * rr, int(grp[0]), int(grp[1]), cb))
	var t: float = 0.0
	var minhp: float = 1.0
	while t < 80.0:
		sim.step(0.05)
		t += 0.05
		minhp = minf(minhp, s.hp / s.mhp)
		var left: int = 0
		for o: Unit in g:
			if o.hp > 0.0:
				left += 1
		if s.hp <= 0.0 or left == 0:
			break
	var gl: int = 0
	for o: Unit in g:
		if o.hp > 0.0:
			gl += 1
			if t >= 80.0 and gl <= 3:
				print("  DBG left d=%.1f tgt=%s st=%s hp=%.0f solo tgt=%s st=%s pos=(%.0f,%.0f) solo=(%.0f,%.0f) wt=%s moving=%s" % [Vector2(o.x - s.x, o.y - s.y).length(), str(o.tgt != null), o.st, o.hp, str(s.tgt != null), s.st, o.x, o.y, s.x, s.y, o.wtype, str(o.moving)])
	ca.alive = false
	cb.alive = false
	return {"solo_won": s.hp > 0.0 and gl == 0, "t": t, "grp_left": gl, "lost": 1.0 - minhp if s.hp > 0.0 else 1.0}


static func _mk(sim: Sim, x: float, y: float, rank: int, stage: int, c: Clan) -> Unit:
	var u: Unit = sim.mk_person(x, y, 0, 30.0)
	sim.awaken(u, true)
	u.apt = "C"
	u.phys_x = false
	u.align = 0
	u.path = [0, 2, 5, 13, 36].pick_random()
	for r: int in range(2, rank + 1):
		sim.ascend(u, r)
	u.igu = PackedStringArray()
	sim.apply_igu(u)
	u.stage = stage
	u.clan = c.id
	u.vil = -1
	u.life = 5000.0
	u.next_trib = 1e9
	sim.set_stats(u, true)
	return u


## Freie, ebene Landfläche (Radius 16) ohne Wasser und Wände.
static func _spot(sim: Sim) -> Vector2:
	var W: int = GuData.W
	var H: int = GuData.H
	for k: int in range(400):
		var p: Vector2 = sim.random_tile(func(i: int) -> bool: return GuData.buildable(sim.world.tile[i]), 200)
		if p.x < 20 or p.y < 20 or p.x > W - 20 or p.y > H - 20:
			continue
		var ok: bool = true
		for dy: int in range(-16, 17, 2):
			for dx: int in range(-16, 17, 2):
				var t: int = sim.world.tile[(int(p.y) + dy) * W + int(p.x) + dx]
				if not GuData.is_land(t) or t == GuData.WALL or t == GuData.MOUNT or t == GuData.LAVA:
					ok = false
		if ok:
			return p
	return Vector2(GuData.W / 2.0, GuData.H / 2.0)


# ---------------- Bilder ----------------

## `-- --fresh --rankshots=<ordner>` (ohne --headless): Ränge 1–9 nebeneinander, Kleinstufen, Fingerschnipsen eines
## Rang-6 gegen ein Rang-5-Heer, Rang-9-Präsenz, Inspektor und Rangliste.
static func shots(m: GuMain, dir: String) -> void:
	while m.loading or m.presim_on:
		await m.get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(dir)
	var sim: Sim = m.sim
	for k: String in ["trib", "will", "disaster", "tide", "growth", "animals", "expand", "diplo", "hunger", "revolt"]:
		if sim.laws.has(k):
			sim.laws[k] = false
	sim.wipe_life()
	sim.arena = true
	m.paused = true
	var c: Vector2 = _spot(sim)
	var ca: Clan = sim.new_clan(4, "")
	var cb: Clan = sim.new_clan(4, "")
	ca.col = Color("#2f6fd6")
	cb.col = Color("#c23a2e")
	# 1) Ränge 1–9 nebeneinander, Kleinstufe wechselnd
	var xs: float = c.x - 26.0
	for r: int in range(1, 10):
		var u: Unit = _mk(sim, xs, c.y + (2.0 if r >= 6 else 0.0), r, (r + 1) % 4, ca)
		u.face = 1
		xs += 2.6 if r < 5 else (3.6 if r < 8 else 5.0)
	sim.rebuild_grid()
	sim.fx.clear()
	sim.parts.clear()
	m._set_ui_hidden(true)
	m.z = 10.0
	xs = c.x - 26.0 + 14.0
	m.cam = Vector2(xs, c.y - 2.0)
	m._clamp_cam()
	await _w(m, 0.8)
	await m._shot(dir + "/rank_lineup.png")
	m.z = 2.2
	m._clamp_cam()
	await _w(m, 0.5)
	await m._shot(dir + "/rank_lineup_far.png")
	# 2) Kleinstufen: Rang 5 Anfang bis Spitze
	sim.wipe_life()
	ca = sim.new_clan(4, "")
	cb = sim.new_clan(4, "")
	for st: int in range(4):
		_mk(sim, c.x - 4.5 + st * 3.0, c.y, 5, st, ca)
		_mk(sim, c.x - 4.5 + st * 3.0, c.y + 6.0, 7, st, ca)
	sim.rebuild_grid()
	sim.fx.clear()
	sim.parts.clear()
	m.z = 14.0
	m.cam = Vector2(c.x, c.y)
	m._clamp_cam()
	await _w(m, 0.6)
	await m._shot(dir + "/rank_stages.png")
	# 3) Fingerschnipsen: ein Rang-6 gegen 40 Rang-5-Spitze
	sim.wipe_life()
	ca = sim.new_clan(4, "")
	cb = sim.new_clan(4, "")
	sim.declare_war(ca, cb, true)
	var imm: Unit = _mk(sim, c.x - 6.0, c.y, 6, 0, ca)
	for k: int in range(40):
		var a: float = randf() * TAU
		var rr: float = sqrt(randf()) * 7.0
		_mk(sim, c.x + 5.0 + cos(a) * rr, c.y + sin(a) * rr, 5, 3, cb)
	sim.fx.clear()
	sim.parts.clear()
	m.z = 9.0
	m.cam = Vector2(c.x + 1.0, c.y)
	m._clamp_cam()
	var got: bool = false
	for k: int in range(200):
		sim.step(0.05)
		await m.get_tree().process_frame
		for e: Dictionary in sim.fx:
			if str(e["k"]) == "km" and float(e["l"]) > float(e["ml"]) * 0.55:
				got = true
		if got:
			break
	await m._shot(dir + "/rank6_snap.png")
	for k: int in range(60):
		sim.step(0.05)
	var left: int = 0
	for u: Unit in sim.units:
		if u.hp > 0.0 and u.clan == cb.id:
			left += 1
	print("rank6_snap: Rang-5 übrig ", left, " von 40, Rang 6 HP ", snappedf(imm.hp / imm.mhp * 100.0, 0.1), " %")
	# 4) Rang 9: Himmelsverdunkelung über einem Heer
	sim.wipe_life()
	ca = sim.new_clan(4, "")
	cb = sim.new_clan(4, "")
	var v9: Unit = _mk(sim, c.x, c.y, 9, 2, ca)
	v9.title = "Unsterblicher Ehrwürdiger des Kraft-Pfades"
	for k: int in range(30):
		var a2: float = randf() * TAU
		var r2: float = 10.0 + randf() * 14.0
		_mk(sim, c.x + cos(a2) * r2, c.y + sin(a2) * r2, [1, 2, 3, 4, 5, 6].pick_random(), randi() % 4, cb)
	sim.rebuild_grid()
	sim.fx.clear()
	sim.parts.clear()
	m.z = 4.5
	m.cam = Vector2(c.x, c.y - 2.0)
	m._clamp_cam()
	await _w(m, 0.6)
	await m._shot(dir + "/rank9_presence.png")
	# 5) Inspektor und Rangliste (mit Oberfläche)
	m._set_ui_hidden(false)
	var p5: Unit = null
	for u: Unit in sim.units:
		if u.rank == 5:
			p5 = u
			break
	if p5 == null:
		p5 = _mk(sim, c.x + 3.0, c.y, 5, 3, cb)
	p5.stage = 3
	sim.set_stats(p5, true)
	m.sel_unit = p5
	m._open_unit()
	await _w(m, 0.4)
	await m._shot(dir + "/rank_inspector_r5.png")
	m.sel_unit = v9
	m._open_unit()
	await _w(m, 0.4)
	await m._shot(dir + "/rank_inspector_r9.png")
	m._close_insp()
	m._open_rank()
	await _w(m, 0.4)
	await m._shot(dir + "/rank_list.png")
	print("RANKSHOTS DONE")
	m.get_tree().quit()


static func _w(m: GuMain, t: float) -> void:
	await m.get_tree().create_timer(t).timeout
