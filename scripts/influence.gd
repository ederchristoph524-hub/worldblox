class_name Influence
extends RefCounted
## Einflusssphären: wer über ein Gebiet herrscht. Ein Clan folgt seinem deutlich stärkeren Verbündeten
## (Vormacht); alle, die derselben obersten Vormacht folgen, bilden einen Bund; Rang-9-Ehrwürdige beherrschen mit ihrem Herrschaftsgebiet
## (Sim.ven_dominions) alle Clans, deren Hauptstadt darin liegt. Statische Daten, neu berechnet mit den Clan-Gebieten.

## je Clan-Id: Vormacht (Clan-Id; sich selbst, wenn unabhängig; -1 = ohne Gebiet)
static var head: PackedInt32Array = PackedInt32Array()
## je Clan-Id: Stärke, Dörfer, Seelen, Index des beherrschenden Ehrwürdigen in doms (-1 = keiner)
static var power: PackedFloat32Array = PackedFloat32Array()
static var nvil: PackedInt32Array = PackedInt32Array()
static var pop: PackedInt32Array = PackedInt32Array()
static var ven_of: PackedInt32Array = PackedInt32Array()
## Herrschaftsgebiete der Ehrwürdigen (wie Sim.ven_dominions)
static var doms: Array = []
## Mächte (Vormacht-Clan-Ids) nach Gesamtstärke ihres Blocks, stärkste zuerst
static var tops: Array[int] = []
## je Vormacht-Id: {"n": Mitglieder, "v": Dörfer, "p": Stärke, "pop": Seelen}
static var bloc: Dictionary = {}
static var stamp: int = 0  ## zählt jede Neuberechnung (Legende baut sich nur bei Änderung neu)


static func compute(sim: Sim) -> void:
	var n: int = sim.clans.size()
	head.resize(n)
	head.fill(-1)
	power.resize(n)
	power.fill(0.0)
	nvil.resize(n)
	nvil.fill(0)
	pop.resize(n)
	pop.fill(0)
	ven_of.resize(n)
	ven_of.fill(-1)
	for v: Village in sim.villages:
		if v.alive and v.clan >= 0 and v.clan < n:
			nvil[v.clan] += 1
	for u: Unit in sim.units:
		if u.k == "p" and u.hp > 0.0 and u.clan >= 0 and u.clan < n:
			pop[u.clan] += 1
	for c: Clan in sim.clans:
		if not c.alive or nvil[c.id] == 0:
			continue
		var p: float = nvil[c.id] * 10.0 + pop[c.id] * 0.4
		if c.lead != null and c.lead.hp > 0.0:
			p += c.lead.rank * c.lead.rank * 4.0
		if c.org != "":
			var k: String = str(Lore.org(c.org).get("k", ""))
			p += 60.0 if k == "Hof" else (20.0 if k == "Sekte" else 6.0)
		power[c.id] = p
	# Vormacht: jeder Clan folgt seinem stärksten direkten Verbündeten, wenn der deutlich stärker ist
	# (> 1,25 ×); dessen Vormacht ist dann auch seine. Die Stärke steigt entlang der Kette, also keine Kreise.
	var parent: PackedInt32Array = PackedInt32Array()
	parent.resize(n)
	for c: Clan in sim.clans:
		parent[c.id] = c.id if power[c.id] > 0.0 else -1
		if power[c.id] <= 0.0:
			continue
		var best: int = c.id
		for e: Variant in c.ally.keys():
			var b: int = int(e)
			if b >= 0 and b < n and b != c.id and not c.war.has(b) and power[b] > power[c.id] * 1.25 and power[b] > power[best]:
				best = b
		parent[c.id] = best
	bloc.clear()
	for c3: Clan in sim.clans:
		var h: int = parent[c3.id]
		if h < 0:
			continue
		var guard: int = 0
		while parent[h] != h and guard < 64:
			h = parent[h]
			guard += 1
		head[c3.id] = h
		var bd0: Dictionary = bloc.get(h, {"n": 0, "v": 0, "p": 0.0, "pop": 0})
		bd0["n"] = int(bd0["n"]) + 1
		bd0["v"] = int(bd0["v"]) + nvil[c3.id]
		bd0["p"] = float(bd0["p"]) + power[c3.id]
		bd0["pop"] = int(bd0["pop"]) + pop[c3.id]
		bloc[h] = bd0
	# Ehrwürdige: ihr Clan (samt Block) und jede Hauptstadt in ihrem Herrschaftsgebiet
	doms = sim.ven_dominions()
	for di: int in range(doms.size()):
		var d: Dictionary = doms[di]
		var dc: int = int(d.get("clan", -1))
		if dc >= 0 and dc < n and head[dc] >= 0:
			var hd: int = head[dc]
			for k2: int in range(n):
				if head[k2] == hd:
					ven_of[k2] = di
	for c2: Clan in sim.clans:
		if head[c2.id] < 0 or ven_of[c2.id] >= 0:
			continue
		var cp: Vector2 = capital_pos(sim, c2)
		var bd: float = 1e9
		for di2: int in range(doms.size()):
			var d2: Dictionary = doms[di2]
			var dd: float = Vector2(float(d2["x"]) - cp.x, float(d2["y"]) - cp.y).length()
			if dd < float(d2["r"]) and dd < bd:
				bd = dd
				ven_of[c2.id] = di2
	tops.clear()
	for h: Variant in bloc.keys():
		tops.append(int(h))
	tops.sort_custom(func(a: int, b: int) -> bool: return float(bloc[a]["p"]) > float(bloc[b]["p"]))
	stamp += 1


static func capital_pos(sim: Sim, c: Clan) -> Vector2:
	if c.cap >= 0 and c.cap < sim.villages.size():
		var v: Village = sim.villages[c.cap]
		if v.alive:
			return Vector2(v.cx, v.cy)
	for v2: Village in sim.villages:
		if v2.alive and v2.clan == c.id:
			return Vector2(v2.cx, v2.cy)
	return Vector2(-1, -1)


## Vormacht eines Clans (oder null, wenn er unabhängig ist bzw. kein Gebiet hat).
static func overlord(sim: Sim, c: Clan) -> Clan:
	if c == null or c.id >= head.size():
		return null
	var h: int = head[c.id]
	if h < 0 or h == c.id:
		return null
	return sim.clans[h]


static func top_of(sim: Sim, c: Clan) -> Clan:
	var o: Clan = overlord(sim, c)
	return o if o != null else c


static func dominion_of(c: Clan) -> Dictionary:
	if c == null or c.id >= ven_of.size() or ven_of[c.id] < 0 or ven_of[c.id] >= doms.size():
		return {}
	return doms[ven_of[c.id]]


## Bezeichnung einer Macht für Legende und Beschriftung: Bund, wenn sie Verbündete anführt.
static func bloc_name(c: Clan) -> String:
	var b: Dictionary = bloc.get(c.id, {})
	if int(b.get("n", 1)) > 1:
		return "Bund " + c.name
	return c.name


## Kurzer BBCode-Text: unter wessen Einfluss der Clan steht.
static func text(sim: Sim, c: Clan) -> String:
	var parts: PackedStringArray = []
	var o: Clan = overlord(sim, c)
	if o != null:
		parts.append("[color=#%s]■[/color] %s (Vormacht)" % [o.col.to_html(false), o.name])
	else:
		var b: Dictionary = bloc.get(c.id, {})
		if int(b.get("n", 1)) > 1:
			parts.append("führt einen Bund aus %d Clans" % int(b["n"]))
		else:
			parts.append("unabhängig")
	var d: Dictionary = dominion_of(c)
	if not d.is_empty():
		parts.append("[color=#%s]%s[/color]" % [(d["col"] as Color).lightened(0.2).to_html(false), ven_name(d)])
	return " · ".join(parts)


## Name eines Ehrwürdigen mit Titel („Urursprung-Unsterblicher-Ehrwürdiger“ statt doppelt).
static func ven_name(d: Dictionary) -> String:
	var nm: String = str(d["name"])
	var t: String = str(d.get("title", ""))
	if t == "" or t.contains(nm):
		return t if t != "" else nm
	return nm + ", " + t


## Zeile für den Inspektor: Gebiet und Einfluss an einer Kachel (leer, wenn niemandes Gebiet).
static func tile_text(sim: Sim, tx: int, ty: int) -> String:
	if not sim.world.in_map(tx, ty):
		return ""
	var i: int = ty * GuData.W + tx
	var t: int = sim.world.terr[i]
	var mt: String = "[color=#9db09e]"
	if t >= 0 and t < sim.villages.size():
		var v: Village = sim.villages[t]
		var c: Clan = sim.clans[v.clan]
		return mt + "Gebiet[/color]  [color=#%s]■[/color] %s (%s)\n" % [c.col.to_html(false), c.name, v.name] + mt + "Einfluss[/color]  " + text(sim, c) + "\n"
	var ic: int = sim.world.infl[i] if i < sim.world.infl.size() else -1
	if ic >= 0 and ic < sim.clans.size():
		var c2: Clan = sim.clans[ic]
		return mt + "Gebiet[/color]  herrenlos, im Einflussbereich von [color=#%s]■[/color] %s\n" % [c2.col.to_html(false), c2.name] + mt + "Einfluss[/color]  " + text(sim, c2) + "\n"
	for d: Dictionary in doms:
		if Vector2(float(d["x"]) - tx, float(d["y"]) - ty).length() < float(d["r"]):
			return mt + "Gebiet[/color]  herrenlos\n" + mt + "Einfluss[/color]  [color=#%s]%s[/color]\n" % [(d["col"] as Color).lightened(0.2).to_html(false), ven_name(d)]
	return mt + "Gebiet[/color]  herrenlos\n"
