class_name PerfTest
extends RefCounted
## Entwickler-Messung `-- --fresh --perftest`: baut die Standardwelt (Gu-Weltkarte 512), misst die Vorgeschichte,
## danach N Simulationsschritte mit Zeit je Teilsystem (Sim.prof), Gebiets- und Einfluss-Berechnung und einen
## Zeitsprung. Optionen: `--perfsteps=600` (Schritte zu Sim.DT), `--perfjump=20` (Jahre, 0 = aus),
## `--perfseeds=1,2,3` (Vorgeschichte je Seed mit Weltstatistik, zum Vergleich vorher/nachher), `--perfsize=512`.
## Endet mit `PERFTEST DONE`.


static func run(m: GuMain) -> void:
	while m.loading:
		await m.get_tree().process_frame
	m._end_presim()
	var steps: int = 600
	var jump_y: float = 20.0
	var seeds: PackedInt32Array = [1]
	var size: int = GuData.SIZE_DEF
	var detail: bool = "--perfprof" in OS.get_cmdline_user_args()
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--perfsteps="):
			steps = int(a.substr(12))
		elif a.begins_with("--perfjump="):
			jump_y = float(a.substr(11))
		elif a.begins_with("--perfseeds="):
			seeds = PackedInt32Array()
			for s: String in a.substr(12).split(","):
				seeds.append(int(s))
		elif a.begins_with("--perfsize="):
			size = int(a.substr(11))
	var sim: Sim = m.sim
	if "--perfloop" in OS.get_cmdline_user_args():
		await _loop(m, jump_y)
		return
	var presim_ms: Array[float] = []
	for sd: int in seeds:
		seed(sd)
		await m._start_new_world(true, "gu", {"size": size})
		var t0: int = Time.get_ticks_usec()
		sim.prof = detail
		sim.prof_reset()
		while sim.presim_chunk(1000000, GuMain.PRESIM_YEARS) < 1.0:
			pass
		var pms: float = (Time.get_ticks_usec() - t0) / 1000.0
		sim.prof = false
		presim_ms.append(pms)
		m._end_presim()
		print("PERF presim seed=%d size=%d %.0f ms · %s" % [sd, size, pms, census(sim)])
		if detail:
			_print_prof(sim, "presim seed=%d" % sd, maxi(1, int(GuMain.PRESIM_YEARS * 12.0 / Sim.FAST_DT)))
	if "--perfmicro" in OS.get_cmdline_user_args():
		_micro(sim)
	# Laufender Betrieb wie GuMain._process: Tempo 1 (DT), Tempo 2 (DT, gestaffelt), Tempo 5/10 (2·DT, gestaffelt)
	var fl_us: int = 0
	var flushes: int = 0
	for mode: int in range(3):
		sim.stagger = mode >= 1
		var dt: float = Sim.DT * (2.0 if mode == 2 else 1.0)
		var n: int = steps if mode < 2 else steps / 2
		var t1: int = Time.get_ticks_usec()
		var tmax: int = 0
		var fl0: int = fl_us
		for k: int in range(n):
			var ts: int = Time.get_ticks_usec()
			sim.step(dt)
			tmax = maxi(tmax, Time.get_ticks_usec() - ts)
			if k % 3 == 2:
				var tf: int = Time.get_ticks_usec()
				sim.world.flush_dirty(4)
				fl_us += Time.get_ticks_usec() - tf
				flushes += 1
		var run_us: int = Time.get_ticks_usec() - t1 - (fl_us - fl0)
		print("PERF step %s: %d steps · %.3f ms/step · %.1f ms per sim month · max %.1f ms · %s" % [["speed1 DT", "speed2 DT+stagger", "speed5 2DT+stagger"][mode], n, run_us / 1000.0 / n, run_us / 1000.0 / (n * dt), tmax / 1000.0, census(sim)])
	sim.stagger = false
	print("PERF flush_dirty %.3f ms per call" % [fl_us / 1000.0 / maxf(1.0, flushes)])
	for st: bool in [false, true]:
		sim.stagger = st
		sim.prof = true
		sim.prof_reset()
		for k: int in range(steps):
			sim.step(Sim.DT)
		sim.prof = false
		_print_prof(sim, "step DT stagger=%s" % str(st), steps)
	sim.stagger = false
	# Gebiete und Einfluss
	var ti: int = Time.get_ticks_usec()
	for k: int in range(5):
		Influence.compute(sim)
	var infl_ms: float = (Time.get_ticks_usec() - ti) / 5000.0
	ti = Time.get_ticks_usec()
	sim.world.update_territory(sim.villages, sim.clans, Influence.head)
	var terr_ms: float = (Time.get_ticks_usec() - ti) / 1000.0
	ti = Time.get_ticks_usec()
	sim.world.begin_territory(sim.villages, sim.clans, Influence.head)
	var n_chunks: int = 0
	while sim.world.territory_busy():
		sim.world.territory_step(4000)
		n_chunks += 1
	var terr2_ms: float = (Time.get_ticks_usec() - ti) / 1000.0
	print("PERF territory full %.1f ms · chunked %.1f ms in %d chunks · influence %.2f ms · phases µs %s (init, claim, keys, colors, borders, pixels, finish)" % [terr_ms, terr2_ms, n_chunks, infl_ms, str(Array(sim.world.terr_phase_us))])
	# Zeitsprung
	if jump_y > 0.0:
		var y0: int = sim.year()
		sim.prof = detail
		sim.prof_reset()
		var tj: int = Time.get_ticks_usec()
		sim.cheats.jump(jump_y)
		var chunks: int = 0
		while sim.cheats.jump_chunk(50) < 1.0:
			chunks += 1
		var jms: float = (Time.get_ticks_usec() - tj) / 1000.0
		sim.prof = false
		print("PERF jump +%d years: %.0f ms (%.1f s per 100 years, %d chunks à 50 ms) · year %d→%d · %s" % [int(jump_y), jms, jms / jump_y * 100.0 / 1000.0, chunks, y0, sim.year(), census(sim)])
		if detail:
			_print_prof(sim, "jump", maxi(1, int(jump_y * 12.0 / Sim.JUMP_DT)))
	var avg: float = 0.0
	for p: float in presim_ms:
		avg += p
	print("PERF summary presim avg %.0f ms over %d seeds" % [avg / maxf(1.0, presim_ms.size()), presim_ms.size()])
	print("PERFTEST DONE")
	m.get_tree().quit()


## --perfloop: wie im Spiel (GuMain._process mit Zeichnen): Vorgeschichte im Hintergrund und Zeitsprung je Bild.
static func _loop(m: GuMain, jump_y: float) -> void:
	var sim: Sim = m.sim
	var t0: int = Time.get_ticks_msec()
	var fr: int = 0
	await m._start_new_world(true, "gu", {"size": GuData.SIZE_DEF})
	while m.presim_on:
		await m.get_tree().process_frame
		fr += 1
	print("PERF loop presim %d ms (%d frames) · %s" % [Time.get_ticks_msec() - t0, fr, census(sim)])
	if jump_y > 0.0:
		var y0: int = sim.year()
		t0 = Time.get_ticks_msec()
		fr = 0
		sim.cheats.jump(jump_y)
		while sim.cheats.jumping():
			await m.get_tree().process_frame
			fr += 1
		print("PERF loop jump +%d years %d ms (%d frames) · year %d→%d · %s" % [int(jump_y), Time.get_ticks_msec() - t0, fr, y0, sim.year(), census(sim)])
	print("PERFTEST DONE")
	m.get_tree().quit()


## Kurze Weltstatistik (zum Vergleich vor/nach Optimierungen).
static func census(sim: Sim) -> String:
	var ranks: PackedInt32Array = PackedInt32Array()
	ranks.resize(10)
	var pers: int = 0
	var anim: int = 0
	var vpop: int = 0
	for u: Unit in sim.units:
		if u.hp <= 0.0:
			continue
		if u.k == "p":
			pers += 1
			ranks[clampi(u.rank, 0, 9)] += 1
			if u.vil >= 0:
				vpop += 1
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
	return "year %d · persons %d (in villages %d) · animals %d · villages %d · clans %d · wars %d · ranks %s" % [sim.year(), pers, vpop, anim, vil, cl, wars / 2, str(Array(ranks))]


static func _print_prof(sim: Sim, tag: String, steps: int) -> void:
	var tot: int = 0
	for k: int in [Sim.P_MONTH, Sim.P_GRID, Sim.P_UNITS, Sim.P_PROJ, Sim.P_SCHED, Sim.P_FIRE, Sim.P_NATURE, Sim.P_ENV, Sim.P_DEAD]:
		tot += sim.pacc[k]
	var s: String = "PERF prof %s (ms total / µs per step):" % tag
	for k: int in range(Sim.PK.size()):
		if sim.pacc[k] > 0:
			s += "\n   %-9s %8.1f ms  %7.1f µs  %4.1f %%  %8d calls  %6.2f µs/call" % [Sim.PK[k], sim.pacc[k] / 1000.0, float(sim.pacc[k]) / steps, 100.0 * sim.pacc[k] / maxf(1.0, tot), sim.pcnt[k], float(sim.pacc[k]) / maxf(1.0, sim.pcnt[k])]
	print(s)
	if "tp" in sim:
		var tpd: Dictionary = sim.get("tp")
		var ks: Array = tpd.keys()
		ks.sort()
		for k2: String in ks:
			if not k2.ends_with("#"):
				print("   tp %-22s %9.1f ms %8d calls %7.1f µs" % [k2, tpd[k2] / 1000.0, tpd[k2 + "#"], float(tpd[k2]) / tpd[k2 + "#"]])
		tpd.clear()


## Einzelmessungen typischer Abfragen (µs je Aufruf) über alle Menschen.
static func _micro(sim: Sim) -> void:
	sim.rebuild_grid()
	var ps: Array[Unit] = []
	for u: Unit in sim.units:
		if u.k == "p" and u.hp > 0.0:
			ps.append(u)
	var reps: int = 20
	var t: int = Time.get_ticks_usec()
	for r: int in range(reps):
		for u: Unit in ps:
			sim.nearest_hostile(u, 10.0, false)
	print("MICRO nearest_hostile %.2f µs" % (float(Time.get_ticks_usec() - t) / (reps * ps.size())))
	var nf: int = 0
	var why: Dictionary = {}
	for c: int in sim._gused:
		if sim._cell_spec(c) >= 2:
			nf += 1
			for o: Unit in sim._grid[c]:
				var k: String = ""
				if o.k == "p":
					if o.rogue or o.undead or o.ow:
						k = "p_rogue"
				elif o.beh == GuData.B_PRED:
					k = "pred_" + o.sp
				elif o.beh == GuData.B_KING:
					k = "king"
				elif o.tide:
					k = "tide"
				elif o.aggro != null:
					k = "aggro_" + o.sp
				if k != "":
					why[k] = int(why.get(k, 0)) + 1
	print("MICRO flagged cells %d of %d used · %s" % [nf, sim._gused.size(), str(why)])
	t = Time.get_ticks_usec()
	for r: int in range(reps):
		for u: Unit in ps:
			sim.nearest_beh(u, 18.0, GuData.B_GU)
	print("MICRO nearest_beh18 %.2f µs" % (float(Time.get_ticks_usec() - t) / (reps * ps.size())))
	t = Time.get_ticks_usec()
	for r: int in range(reps):
		for u: Unit in ps:
			sim.nearest(u, 40.0, func(o: Unit) -> bool: return o.beh == GuData.B_IGU)
	print("MICRO nearest_igu40 %.2f µs" % (float(Time.get_ticks_usec() - t) / (reps * ps.size())))
	t = Time.get_ticks_usec()
	for r: int in range(reps):
		for u: Unit in ps:
			sim.uage(u)
	print("MICRO uage %.2f µs" % (float(Time.get_ticks_usec() - t) / (reps * ps.size())))
	t = Time.get_ticks_usec()
	for r: int in range(reps):
		for u: Unit in ps:
			sim.power(u)
	print("MICRO power %.2f µs" % (float(Time.get_ticks_usec() - t) / (reps * ps.size())))
	t = Time.get_ticks_usec()
	for r: int in range(reps):
		for u: Unit in ps:
			sim.find_feat_k(u.x, u.y, 20.0, Sim.FF_GATHER)
	print("MICRO find_feat_k %.2f µs" % (float(Time.get_ticks_usec() - t) / (reps * ps.size())))
	t = Time.get_ticks_usec()
	for r: int in range(reps):
		for u: Unit in ps:
			sim.wander_near(u, u.x, u.y, 10.0)
	print("MICRO wander_near %.2f µs" % (float(Time.get_ticks_usec() - t) / (reps * ps.size())))
	var sv: Array = []
	for u: Unit in ps:
		sv.append([u.tx, u.ty, u.st, u.tgt, u.wi, u.job, u.think])
	var cnt: Dictionary = {}
	t = Time.get_ticks_usec()
	for u: Unit in ps:
		var t1: int = Time.get_ticks_usec()
		sim.think_p(u)
		var key: String = "r%d %s %s" % [mini(u.rank, 6), u.job, u.st]
		var e: Array = cnt.get(key, [0, 0])
		e[0] += 1
		e[1] += Time.get_ticks_usec() - t1
		cnt[key] = e
	print("MICRO think_p %.2f µs" % (float(Time.get_ticks_usec() - t) / ps.size()))
	for k: String in cnt.keys():
		print("   ", k, " n=", cnt[k][0], " µs=", float(cnt[k][1]) / cnt[k][0])
	t = Time.get_ticks_usec()
	for r: int in range(reps):
		sim.rebuild_grid()
	print("MICRO rebuild_grid %.1f µs (%d units)" % [float(Time.get_ticks_usec() - t) / reps, sim.units.size()])
	t = Time.get_ticks_usec()
	var n: int = 0
	for r: int in range(reps):
		for u: Unit in sim.units:
			if u.hp <= 0.0:
				n += 1
	print("MICRO loop units %.1f µs" % [float(Time.get_ticks_usec() - t) / reps])
