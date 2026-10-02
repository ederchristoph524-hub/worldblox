class_name GfxFx
extends RefCounted
## Effekte und Leben der Nahansicht (gezeichnet aus EntityLayer, nur lesend auf die Simulation):
## Kampf (Hiebe, Treffer-Funken, Essenz-Blitze in Pfadfarbe), Mordzüge je Pfad (Schwertregen,
## Feuersäulen, Blitze, Eis, Ranken, Runenkreise …), Fingerschnipsen-Druckwelle, Blitze und Säulen,
## Geschosse mit Schweif; Umgebung: Vögel, springende Fische, Rauch aus Häusern, wogende Felder,
## Boote, Kriegsbanner. Alles ohne Zustand in der Simulation – Treffer und Hiebe werden an hp/cd der
## sichtbaren Wesen erkannt. Umgebungs-Partikel nur nahe der Kamera.

## lokale Effekte: {k, x, y, l, ml, c, a, s}
var loc: Array[Dictionary] = []
var prev: Dictionary = {}
var nxt: Dictionary = {}
var birds: Array[Dictionary] = []
var fish: Array[Dictionary] = []
var spawn_t: float = 0.0
static var _boat: ImageTexture = null
static var _circ: PackedVector2Array = PackedVector2Array()
## eigener Zufall fürs Zeichnen (verändert den Simulations-Zufall nicht – Vergleichsbilder bleiben gleich)
static var RNG: RandomNumberGenerator = RandomNumberGenerator.new()


# ---------------- Hilfen ----------------

static func rnd(sd: float, i: int) -> float:
	var v: float = sin(sd * 12.9898 + i * 78.233) * 43758.5453
	return v - floorf(v)


static func circ() -> PackedVector2Array:
	if _circ.is_empty():
		for i: int in range(20):
			var a: float = i * TAU / 20.0
			_circ.append(Vector2(cos(a), sin(a)))
	return _circ


## Gefüllte Ellipse (Boden-Abdrücke in Schrägsicht).
static func ell(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	if col.a <= 0.003 or rx <= 0.06 or ry <= 0.04:
		return
	var pts: PackedVector2Array = PackedVector2Array()
	for v: Vector2 in circ():
		pts.append(c + Vector2(v.x * rx, v.y * ry))
	ci.draw_colored_polygon(pts, col)


## Ellipsenring.
static func ering(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, wd: float, n: int = 32) -> void:
	if col.a <= 0.003 or rx <= 0.01:
		return
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(n + 1):
		var a: float = i * TAU / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_polyline(pts, col, wd)


## Gezackter Blitzstrahl von a nach b (Punkte deterministisch aus sd).
static func zigzag(a: Vector2, b: Vector2, sd: float, n: int, amp: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	var d: Vector2 = b - a
	var nr: Vector2 = d.orthogonal().normalized()
	for i: int in range(n + 1):
		var t: float = float(i) / n
		var j: float = 0.0 if (i == 0 or i == n) else (rnd(sd, i) - 0.5) * 2.0 * amp
		pts.append(a + d * t + nr * j)
	return pts


static func glow_line(ci: CanvasItem, pts: PackedVector2Array, c: Color, al: float, wd: float) -> void:
	ci.draw_polyline(pts, Color(c, 0.22 * al), wd * 3.2)
	ci.draw_polyline(pts, Color(c.lightened(0.3), 0.75 * al), wd * 1.4)
	ci.draw_polyline(pts, Color(1, 1, 1, al), wd * 0.55)


## Runder Klecks im Texel-Raster der Nahansicht (¼ Kachel): Kreuz aus zwei Rechtecken – wirkt wie Pixel-Art.
static func pxblob(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var q: float = 0.25
	var x0: float = roundf((c.x - r) / q) * q
	var x1: float = roundf((c.x + r) / q) * q
	var y0: float = roundf((c.y - r) / q) * q
	var y1: float = roundf((c.y + r) / q) * q
	var e: float = maxf(q, roundf(r * 0.3 / q) * q)
	if x1 - x0 < q * 2.0:
		ci.draw_rect(Rect2(x0, y0, maxf(q, x1 - x0), maxf(q, y1 - y0)), col)
		return
	ci.draw_rect(Rect2(x0, y0 + e, x1 - x0, y1 - y0 - 2.0 * e), col)
	ci.draw_rect(Rect2(x0 + e, y0, x1 - x0 - 2.0 * e, e), col)
	ci.draw_rect(Rect2(x0 + e, y1 - e, x1 - x0 - 2.0 * e, e), col)


## Vier-Zacken-Stern (Funkeln).
static func star4(ci: CanvasItem, p: Vector2, r: float, c: Color) -> void:
	if r < 0.06 or c.a <= 0.003:
		return
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.22, -r * 0.22), p + Vector2(r, 0), p + Vector2(r * 0.22, r * 0.22), p + Vector2(0, r), p + Vector2(-r * 0.22, r * 0.22), p + Vector2(-r, 0), p + Vector2(-r * 0.22, -r * 0.22)]), c)


# ---------------- Kampf (lokale Effekte) ----------------

## Je sichtbarem Wesen und Bild: Treffer (hp sinkt) und Angriffe (cd springt hoch) erkennen.
func track(u: Unit, sc: float, sim: Sim) -> void:
	if u.tgt == null and u.flash <= 0.0:
		return
	var p: Variant = prev.get(u.id)
	nxt[u.id] = Vector2(u.hp, u.cd)
	var hit: bool = u.flash > 0.0
	if p != null:
		var pv: Vector2 = p
		hit = u.hp < pv.x - 0.0001
		if u.cd > pv.y + 0.25 and u.tgt != null and is_instance_valid(u.tgt):
			var tg: Unit = u.tgt
			var d: Vector2 = Vector2(tg.x - u.x, tg.y - u.y)
			if d.length() < 4.0 and not (u.k == "p" and u.rank >= 6):
				var c: Color = Color(1, 0.97, 0.88)
				if u.k == "p" and u.rank > 0 and u.path >= 0:
					c = GuData.PATH_COL[u.path]
				elif u.k == "a":
					c = Color(1.0, 0.85, 0.75)
				loc.append({"k": "slash", "x": u.x, "y": u.y - 1.3 * sc, "a": d.angle(), "l": 0.22, "ml": 0.22, "c": c, "s": sc, "an": u.k == "a"})
	if hit and u.hp < u.mhp:
		var hc: Color = Color(1.0, 0.93, 0.7)
		var src: Unit = u.aggro
		if src != null and is_instance_valid(src) and src.k == "p" and src.rank > 0 and src.path >= 0:
			hc = GuData.PATH_COL[src.path]
		var big: bool = p != null and ((p as Vector2).x - u.hp) > u.mhp * 0.25
		loc.append({"k": "hit", "x": u.x + (RNG.randf() - 0.5) * 0.6, "y": u.y - 1.4 * sc + (RNG.randf() - 0.5) * 0.6, "l": 0.26 if not big else 0.36, "ml": 0.26 if not big else 0.36, "c": hc, "s": sc * (1.5 if big else 1.0), "a": RNG.randf() * TAU})
		if loc.size() > 160:
			loc.remove_at(0)


func flush() -> void:
	var t: Dictionary = prev
	prev = nxt
	nxt = t
	nxt.clear()


func draw_local(ci: CanvasItem, rdt: float, z: float) -> void:
	var i: int = loc.size() - 1
	while i >= 0:
		var e: Dictionary = loc[i]
		e["l"] = float(e["l"]) - rdt
		if float(e["l"]) <= 0.0:
			loc.remove_at(i)
			i -= 1
			continue
		var t: float = 1.0 - float(e["l"]) / float(e["ml"])
		var p: Vector2 = Vector2(e["x"], e["y"])
		var c: Color = e["c"]
		var sc: float = e["s"]
		match str(e["k"]):
			"slash":
				var a: float = e["a"]
				var r: float = 1.5 * sc / 0.27
				if bool(e["an"]):
					# Krallenhieb: drei kurze Striche quer über das Ziel
					var cp: Vector2 = p + Vector2(cos(a), sin(a)) * r * 0.8
					var dd: Vector2 = Vector2(cos(a + 1.2), sin(a + 1.2))
					for k: int in range(3):
						var o: Vector2 = Vector2(cos(a), sin(a)) * (k - 1) * 0.35
						var len: float = 1.1 * minf(1.0, t * 3.0)
						ci.draw_line(cp + o - dd * len * 0.5, cp + o + dd * len * 0.5, Color(c, 1.0 - t), maxf(0.12, 1.2 / z))
				else:
					# Klingenbogen: schwingt in 0,2 s durch, heller Kern, farbiger Saum
					var sw: float = minf(1.0, t * 2.2)
					var a0: float = a - 1.2
					var a1: float = a0 + 2.4 * sw
					var al: float = 1.0 - maxf(0.0, t - 0.35) / 0.65
					ci.draw_arc(p, r, a0 + 2.4 * maxf(0.0, sw - 0.55), a1, 12, Color(c, 0.5 * al), maxf(0.35, 4.0 / z))
					ci.draw_arc(p, r, a0 + 2.4 * maxf(0.0, sw - 0.4), a1, 12, Color(1, 1, 1, 0.9 * al), maxf(0.15, 1.6 / z))
			"hit":
				var al2: float = 1.0 - t
				var rr: float = (0.5 + t * 1.3) * sc / 0.27 * 0.55
				ci.draw_circle(p, rr * 0.9 * (1.0 - t * 0.5), Color(c, 0.3 * al2))
				var a2: float = e["a"]
				for k2: int in range(5):
					var an: float = a2 + k2 * TAU / 5.0
					var dv: Vector2 = Vector2(cos(an), sin(an))
					ci.draw_line(p + dv * rr * 0.35, p + dv * rr * (1.0 + 0.4 * (k2 % 2)), Color(c.lightened(0.4), al2), maxf(0.1, 1.3 / z))
				if t < 0.4:
					star4(ci, p, rr * 0.7 * (1.0 - t * 2.0), Color(1, 1, 1, 0.95))
		i -= 1


# ---------------- Mordzüge ----------------

## Art des Mordzugs je Pfad (Darstellung).
static func km_style(p: int) -> String:
	match p:
		0, 7, 12, 29, 32:
			return "quake"
		1:
			return "moon"
		2, 33:
			return "fire"
		3:
			return "water"
		4, 16, 30:
			return "wind"
		5, 17:
			return "bolt"
		6, 42:
			return "wood"
		8, 35, 47:
			return "blood"
		9, 22, 23, 26, 39, 40:
			return "soul"
		10, 21, 25, 27, 28, 31, 34:
			return "rune"
		11, 45, 46:
			return "wave"
		13, 36, 37, 38:
			return "swords"
		14, 15:
			return "ice"
		18, 19:
			return "dark"
		20:
			return "star"
	return "spark"


## Mordzug (ml 1,1) bzw. Fingerschnipsen (ml 0,8) eines Unsterblichen.
static func km(ci: CanvasItem, e: Dictionary, t: float, z: float, sim: Sim) -> void:
	var c: Color = e["c"]
	var p: int = e["p"]
	var cen: Vector2 = Vector2(e["x"], e["y"])
	var R: float = e["r"]
	var sd: float = float(e["x"]) * 1.37 + float(e["y"]) * 0.71
	var lw: float = maxf(0.25, 2.2 / z)
	if absf(float(e["ml"]) - 0.8) < 0.01:
		snap(ci, cen, R, c, t, z, sd)
		return
	# bleibt lange kräftig, verblasst erst zum Schluss
	var al: float = 1.0 - t * t
	# gemeinsamer Bodenschein und Druckwelle
	ell(ci, cen, R * 0.75 * (0.6 + t * 0.4), R * 0.42 * (0.6 + t * 0.4), Color(c, 0.2 * al))
	if t < 0.45:
		var tw: float = t / 0.45
		ering(ci, cen, R * (0.3 + tw * 0.9), R * 0.55 * (0.3 + tw * 0.9), Color(c.lightened(0.4), 1.0 - tw), lw * 2.0)
	if not e.has("_i"):
		e["_i"] = true
		for k: int in range(16):
			var an: float = RNG.randf() * TAU
			var v: float = 4.0 + RNG.randf() * 6.0
			sim.parts.append({"x": cen.x, "y": cen.y - 0.5, "vx": cos(an) * v, "vy": sin(an) * v * 0.6 - 3.0, "l": 0.5 + RNG.randf() * 0.5, "ml": 1.0, "c": c.lightened(RNG.randf() * 0.5), "s": 0.4 + RNG.randf() * 0.4, "g": 6.0})
	match km_style(p):
		"quake":
			for k: int in range(8):
				var an2: float = k * TAU / 8.0 + rnd(sd, k) * 0.6
				var ln: float = R * (0.55 + 0.45 * rnd(sd, k + 9)) * minf(1.0, t * 4.0)
				var pts: PackedVector2Array = zigzag(cen, cen + Vector2(cos(an2), sin(an2) * 0.6) * ln, sd + k, 5, 0.5)
				ci.draw_polyline(pts, Color(0.16, 0.1, 0.06, al), lw * 1.8)
				ci.draw_polyline(pts, Color(c.lightened(0.2), al * 0.9), lw * 0.7)
			for k2: int in range(10):
				var an3: float = rnd(sd, k2 + 20) * TAU
				var dv: Vector2 = Vector2(cos(an3), sin(an3) * 0.6)
				var q: Vector2 = cen + dv * R * t * (0.4 + 0.6 * rnd(sd, k2 + 40)) - Vector2(0, sin(minf(1.0, t * 1.3) * PI) * R * 0.45)
				var s: float = 0.35 + rnd(sd, k2 + 60) * 0.4
				ci.draw_rect(Rect2(q - Vector2(s, s) * 0.5, Vector2(s, s)), Color(0.42, 0.33, 0.24, al))
				ci.draw_rect(Rect2(q - Vector2(s, s) * 0.5, Vector2(s, s * 0.35)), Color(0.62, 0.52, 0.4, al))
		"moon":
			for k: int in range(3):
				var a: float = t * 7.0 + k * TAU / 3.0
				var q2: Vector2 = cen + Vector2(cos(a), sin(a) * 0.6) * R * (0.25 + t * 0.7) - Vector2(0, R * 0.25)
				_crescent(ci, q2, R * 0.42, a + PI * 0.5, Color(0.93, 0.97, 1.0, al), Color(c, al * 0.7))
			var a4: float = sd + t * 2.0
			_earc(ci, cen - Vector2(0, R * 0.3), R * 0.9, R * 0.5, a4, a4 + 2.2 * minf(1.0, t * 3.0), Color(0.93, 0.97, 1.0, al), lw * 3.0)
			_earc(ci, cen - Vector2(0, R * 0.3), R * 0.9, R * 0.5, a4, a4 + 2.2 * minf(1.0, t * 3.0), Color(c, al * 0.4), lw * 7.0)
		"fire":
			var n: int = 7
			for k: int in range(n):
				var q3: Vector2 = cen + Vector2((rnd(sd, k) - 0.5) * 1.6, (rnd(sd, k + 7) - 0.5) * 0.9) * R
				var st: float = rnd(sd, k + 14) * 0.25
				var tt: float = clampf((t - st) / 0.75, 0.0, 1.0)
				if tt <= 0.0:
					continue
				var hh: float = R * (0.9 + rnd(sd, k + 21) * 0.8) * sin(tt * PI)
				var wd: float = 0.9 + rnd(sd, k + 28) * 0.8
				_flame(ci, q3, wd, hh, tt, k)
		"water":
			for k: int in range(3):
				var tk: float = clampf(t * 1.4 - k * 0.2, 0.0, 1.0)
				if tk <= 0.0:
					continue
				var rr: float = R * (0.3 + tk * 0.8)
				ering(ci, cen, rr, rr * 0.55, Color(0.85, 0.95, 1.0, (1.0 - tk) * 0.9), lw * 2.2)
				ering(ci, cen + Vector2(0, -0.3), rr * 0.97, rr * 0.53, Color(c, (1.0 - tk) * 0.6), lw * 3.5)
			for k2: int in range(12):
				var an4: float = k2 * TAU / 12.0
				var q4: Vector2 = cen + Vector2(cos(an4), sin(an4) * 0.55) * R * (0.3 + t * 0.6)
				var up: float = sin(minf(1.0, t * 1.6) * PI) * R * 0.5 * (0.6 + rnd(sd, k2) * 0.6)
				ci.draw_line(q4, q4 - Vector2(0, up), Color(c.lightened(0.3), al * 0.8), lw * 1.6)
				ci.draw_circle(q4 - Vector2(0, up), lw * 1.2, Color(1, 1, 1, al))
		"wind":
			for k: int in range(4):
				var a0: float = -t * 14.0 + k * 1.6
				var rr2: float = R * (0.25 + k * 0.22) * (0.7 + t * 0.4)
				var hy: float = -k * R * 0.18 * t
				_earc(ci, cen + Vector2(0, hy), rr2, rr2 * 0.5, a0, a0 + 3.4, Color(c, al * 0.35), lw * (6.0 - k))
				_earc(ci, cen + Vector2(0, hy), rr2, rr2 * 0.5, a0, a0 + 3.4, Color(c.lightened(0.5), al * (1.0 - k * 0.12)), lw * (2.6 - k * 0.3))
			for k2: int in range(10):
				var a3: float = -t * 10.0 + k2 * 0.63
				var rr3: float = R * (0.3 + rnd(sd, k2) * 0.7)
				ci.draw_rect(Rect2(cen + Vector2(cos(a3) * rr3, sin(a3) * rr3 * 0.5 - t * R * 0.6 * rnd(sd, k2 + 3)), Vector2(0.45, 0.45)), Color(0.85, 0.95, 0.75, al))
		"bolt":
			var flick: int = int(t * 14.0)
			for k: int in range(5):
				if rnd(sd + flick, k) < 0.35:
					continue
				var q5: Vector2 = cen + Vector2((rnd(sd, k) - 0.5) * 1.6, (rnd(sd, k + 5) - 0.5) * 0.9) * R
				var pts2: PackedVector2Array = zigzag(q5 + Vector2((rnd(sd, k + 9) - 0.5) * 6.0, -R * 3.0 - 10.0), q5, sd + flick * 3 + k, 9, 1.2)
				glow_line(ci, pts2, c, al, lw * 1.4)
				ell(ci, q5, 1.4, 0.7, Color(1, 1, 0.85, al * 0.7))
		"wood":
			ell(ci, cen, R * 0.9, R * 0.5, Color(c.darkened(0.4), 0.3 * al))
			var wl: Array[Vector3] = []
			for k: int in range(18):
				var an5: float = rnd(sd, k) * TAU
				var dd: float = R * (0.2 + 0.8 * rnd(sd, k + 3))
				wl.append(Vector3(cen.x + cos(an5) * dd, cen.y + sin(an5) * dd * 0.55, k))
			wl.sort_custom(func(a5: Vector3, b5: Vector3) -> bool: return a5.y < b5.y)
			for v: Vector3 in wl:
				var k6: int = int(v.z)
				var gr: float = sin(clampf(t * 1.5 - rnd(sd, k6 + 6) * 0.25, 0.0, 1.0) * PI)
				var hh2: float = (2.2 + rnd(sd, k6 + 8) * 2.6) * gr * R / 6.0
				_spike(ci, Vector2(v.x, v.y), 0.32 * R / 6.0 + 0.3, hh2, Color(0.2, 0.42, 0.12), c.lightened(0.3), al)
				if k6 % 3 == 0 and hh2 > 1.0:
					ci.draw_rect(Rect2(v.x + 0.2, v.y - hh2 * 0.6, 0.5, 0.35), Color(c.lightened(0.4), al))
		"blood":
			ell(ci, cen, R * 0.9, R * 0.5, Color(c.darkened(0.3), 0.4 * al))
			ell(ci, cen - Vector2(0, R * 0.25), R * 0.75 * (0.6 + t * 0.5), R * 0.45 * (0.6 + t * 0.5), Color(c, 0.18 * al))
			for k: int in range(10):
				var an6: float = rnd(sd, k) * TAU
				var q7: Vector2 = cen + Vector2(cos(an6), sin(an6) * 0.55) * R * (0.2 + 0.7 * rnd(sd, k + 3))
				var gr2: float = sin(clampf(t * 1.8 - rnd(sd, k + 6) * 0.4, 0.0, 1.0) * PI)
				_spike(ci, q7, 0.4 + R * 0.05, (1.8 + rnd(sd, k + 8) * 2.2) * gr2 * R / 5.0, c.darkened(0.45), c.lightened(0.2), al)
			for k2: int in range(8):
				var a7: float = rnd(sd, k2 + 30) * TAU
				var q8: Vector2 = cen + Vector2(cos(a7), sin(a7) * 0.6) * R * t * 0.9 - Vector2(0, sin(t * PI) * R * 0.5)
				ci.draw_circle(q8, 0.28, Color(c, al))
		"soul":
			for k: int in range(7):
				var a8: float = t * 5.0 + k * TAU / 7.0
				var rr4: float = R * (0.6 - t * 0.35)
				var hh3: float = t * R * 0.9 + rnd(sd, k) * 1.5
				for j: int in range(4):
					var a9: float = a8 - j * 0.25
					var q9: Vector2 = cen + Vector2(cos(a9) * rr4, sin(a9) * rr4 * 0.5 - hh3 + j * 0.3)
					ci.draw_circle(q9, (0.8 - j * 0.15) * (R / 7.0 + 0.5), Color(c.lightened(0.15 * (3 - j)), al * (0.95 - j * 0.2)))
			ell(ci, cen, R * 0.7, R * 0.4, Color(c, 0.2 * al))
		"rune":
			var rr5: float = R * (0.85 if t < 0.75 else 0.85 * (1.0 - (t - 0.75) * 3.0))
			var a10: float = t * 3.0
			var al3: float = minf(1.0, t * 5.0) * al
			ering(ci, cen, rr5, rr5 * 0.55, Color(c.lightened(0.3), al3), lw * 1.4, 40)
			ering(ci, cen, rr5 * 0.78, rr5 * 0.78 * 0.55, Color(c, al3 * 0.8), lw, 40)
			for k: int in range(12):
				var a11: float = a10 + k * TAU / 12.0
				var q10: Vector2 = cen + Vector2(cos(a11), sin(a11) * 0.55) * rr5 * 0.89
				ci.draw_rect(Rect2(q10 - Vector2(0.3, 0.2), Vector2(0.6 if k % 3 else 0.3, 0.4)), Color(1, 1, 1, al3))
			var hex: PackedVector2Array = PackedVector2Array()
			for k2: int in range(7):
				var a12: float = -a10 * 1.5 + k2 * TAU / 6.0 * 2.0
				hex.append(cen + Vector2(cos(a12), sin(a12) * 0.55) * rr5 * 0.72)
			ci.draw_polyline(hex, Color(c.lightened(0.5), al3 * 0.8), lw)
			if t > 0.7:
				ci.draw_rect(Rect2(cen.x - 0.5 * (1.0 - t) * 6.0, cen.y - 40.0, (1.0 - t) * 6.0, 40.0), Color(c.lightened(0.5), (1.0 - t) * 2.0))
		"wave":
			for k: int in range(4):
				var tk2: float = fposmod(t * 2.0 - k * 0.25, 1.0)
				var rr6: float = R * (0.2 + tk2 * 0.9)
				ering(ci, cen - Vector2(0, 1.0), rr6, rr6 * 0.6, Color(c, (1.0 - tk2) * al * 0.4), lw * 5.0)
				ering(ci, cen - Vector2(0, 1.0), rr6, rr6 * 0.6, Color(c.lightened(0.5), (1.0 - tk2) * al), lw * 1.8)
		"swords":
			for k: int in range(14):
				var q11: Vector2 = cen + Vector2((rnd(sd, k) - 0.5) * 1.8, (rnd(sd, k + 14) - 0.5) * 1.0) * R
				var st2: float = rnd(sd, k + 28) * 0.45
				var tf: float = clampf((t - st2) / 0.22, 0.0, 1.0)
				if t < st2:
					continue
				var fall: float = (1.0 - tf) * 18.0
				_sword(ci, q11 - Vector2(fall * 0.25, fall), c, 1.0 - maxf(0.0, t - 0.75) * 4.0, R / 7.0 + 0.5)
				if tf >= 1.0 and t - st2 < 0.4:
					ell(ci, q11, 0.9, 0.4, Color(1, 1, 1, 0.6 * (1.0 - (t - st2) / 0.4)))
		"ice":
			ell(ci, cen, R * 0.95, R * 0.55, Color(0.85, 0.95, 1.0, 0.3 * al))
			for k: int in range(12):
				var an7: float = rnd(sd, k) * TAU
				var q12: Vector2 = cen + Vector2(cos(an7), sin(an7) * 0.55) * R * (0.15 + 0.8 * rnd(sd, k + 3))
				var gr3: float = minf(1.0, t * 4.0 - rnd(sd, k + 6) * 0.8)
				if gr3 <= 0.0:
					continue
				var hh4: float = (1.5 + rnd(sd, k + 8) * 2.0) * gr3 * R / 6.0
				_shard(ci, q12, 0.5 + R * 0.04, hh4, (rnd(sd, k + 11) - 0.5) * 0.6, al)
		"dark":
			var rr7: float = R * (1.0 - t * 0.7)
			ell(ci, cen - Vector2(0, R * 0.2), rr7 * 1.25, rr7, Color(c, 0.25 * al))
			ell(ci, cen - Vector2(0, R * 0.2), rr7, rr7 * 0.8, Color(0.04, 0.01, 0.08, 0.8 * minf(1.0, t * 4.0) * al))
			ering(ci, cen - Vector2(0, R * 0.2), rr7, rr7 * 0.8, Color(c.lightened(0.3), al), lw * 1.6)
			for k: int in range(10):
				var a13: float = rnd(sd, k) * TAU + t * 3.0
				var d2: float = R * 1.3 * (1.0 - fposmod(t * 1.5 + rnd(sd, k + 3), 1.0))
				ci.draw_rect(Rect2(cen + Vector2(cos(a13) * d2, sin(a13) * d2 * 0.8 - R * 0.2), Vector2(0.35, 0.35)), Color(c.lightened(0.5), al))
		"star":
			for k: int in range(6):
				var q13: Vector2 = cen + Vector2((rnd(sd, k) - 0.5) * 1.6, (rnd(sd, k + 6) - 0.5) * 0.9) * R
				var st3: float = rnd(sd, k + 12) * 0.4
				var tf2: float = clampf((t - st3) / 0.3, 0.0, 1.0)
				if t < st3:
					continue
				var head: Vector2 = q13 + Vector2(14.0, -22.0) * (1.0 - tf2)
				ci.draw_line(head, head + Vector2(5.0, -8.0), Color(c, 0.5 * al), lw * 2.4)
				ci.draw_line(head, head + Vector2(2.5, -4.0), Color(1, 1, 1, al), lw)
				star4(ci, head, 0.9, Color(1, 1, 1, al))
				if tf2 >= 1.0:
					star4(ci, q13, 1.6 * (1.0 - (t - st3 - 0.3) * 2.0), Color(c.lightened(0.5), al))
		_:
			for k: int in range(12):
				var a14: float = k * TAU / 12.0 + t
				var q14: Vector2 = cen + Vector2(cos(a14), sin(a14) * 0.6) * R * (0.2 + t * 0.8) - Vector2(0, sin(t * PI) * R * 0.3)
				ci.draw_circle(q14, 0.9, Color(c, 0.3 * al))
				star4(ci, q14, 1.4 * (1.0 - t * 0.5), Color(c.lightened(0.5), al))


## Fingerschnipsen: harte, schnelle Druckwelle mit weißem Kern und Speedlines.
static func snap(ci: CanvasItem, cen: Vector2, R: float, c: Color, t: float, z: float, sd: float) -> void:
	var lw: float = maxf(0.18, 1.6 / z)
	var al: float = 1.0 - t
	if t < 0.18:
		var tf: float = t / 0.18
		ci.draw_circle(cen - Vector2(0, 1.0), 1.0 + tf * 2.0, Color(1, 1, 1, 0.9 * (1.0 - tf)))
		ci.draw_circle(cen - Vector2(0, 1.0), 2.0 + tf * 4.0, Color(c, 0.4 * (1.0 - tf)))
	var e1: float = 1.0 - pow(1.0 - minf(1.0, t * 1.6), 3.0)
	var rr: float = R * e1
	ell(ci, cen, rr, rr * 0.55, Color(c, 0.12 * al))
	ering(ci, cen, rr, rr * 0.55, Color(1, 1, 1, al), lw * 2.4 * (1.0 - t * 0.6), 36)
	ering(ci, cen, rr * 0.93, rr * 0.93 * 0.55, Color(c.lightened(0.2), al * 0.8), lw * 3.5, 36)
	var rr2: float = R * 0.7 * clampf(t * 1.6 - 0.25, 0.0, 1.0)
	if rr2 > 0.0:
		ering(ci, cen, rr2, rr2 * 0.55, Color(c, al * 0.6), lw * 1.4, 28)
	for k: int in range(10):
		var a: float = k * TAU / 10.0 + rnd(sd, k) * 0.4
		var dv: Vector2 = Vector2(cos(a), sin(a) * 0.55)
		ci.draw_line(cen + dv * rr * 0.65, cen + dv * rr * 1.08, Color(1, 1, 1, al * 0.8), lw)


static func _earc(ci: CanvasItem, c: Vector2, rx: float, ry: float, a0: float, a1: float, col: Color, wd: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(13):
		var a: float = lerpf(a0, a1, i / 12.0)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_polyline(pts, col, wd)


static func _crescent(ci: CanvasItem, p: Vector2, r: float, a: float, col: Color, glow: Color) -> void:
	ci.draw_circle(p, r * 1.25, Color(glow, glow.a * 0.4))
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(11):
		var b: float = a - PI * 0.5 + PI * i / 10.0
		pts.append(p + Vector2(cos(b), sin(b)) * r)
	for i2: int in range(10, -1, -1):
		var b2: float = a - PI * 0.5 + PI * i2 / 10.0
		pts.append(p + Vector2(cos(a), sin(a)) * r * 0.32 + Vector2(cos(b2), sin(b2)) * r * 0.62)
	ci.draw_colored_polygon(pts, col)


static func _flame(ci: CanvasItem, base: Vector2, wd: float, hh: float, tt: float, k: int) -> void:
	if hh <= 0.1:
		return
	var al: float = minf(1.0, (1.0 - tt) * 3.0)
	ell(ci, base, wd * 1.3, wd * 0.5, Color(1.0, 0.5, 0.1, 0.35 * al))
	var cols: Array[Color] = [Color(0.85, 0.18, 0.08, al), Color(1.0, 0.5, 0.1, al), Color(1.0, 0.85, 0.35, al), Color(1, 1, 0.85, al)]
	for j: int in range(4):
		var ww: float = wd * (1.0 - j * 0.24)
		var h2: float = hh * (1.0 - j * 0.18)
		var sway: float = sin(tt * 20.0 + k + j) * ww * 0.25
		ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-ww * 0.5, 0), base + Vector2(-ww * 0.42, -h2 * 0.55), base + Vector2(sway, -h2), base + Vector2(ww * 0.42, -h2 * 0.55), base + Vector2(ww * 0.5, 0)]), cols[j])


static func _spike(ci: CanvasItem, base: Vector2, wd: float, hh: float, dk: Color, lt: Color, al: float) -> void:
	if hh <= 0.15:
		return
	ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-wd, 0), base + Vector2(0, -hh), base + Vector2(wd, 0)]), Color(dk, al))
	ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-wd, 0), base + Vector2(0, -hh), base + Vector2(-wd * 0.1, 0)]), Color(lt, al))


static func _shard(ci: CanvasItem, base: Vector2, wd: float, hh: float, lean: float, al: float) -> void:
	if hh <= 0.15:
		return
	var tip: Vector2 = base + Vector2(lean * hh, -hh)
	var mid: float = hh * 0.25
	ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-wd, -mid * 0.3), tip, base + Vector2(wd, -mid * 0.3), base + Vector2(0, mid * 0.2)]), Color(0.55, 0.8, 0.98, 0.9 * al))
	ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-wd, -mid * 0.3), tip, base + Vector2(0, mid * 0.2)]), Color(0.88, 0.97, 1.0, 0.95 * al))


static func _sword(ci: CanvasItem, tip: Vector2, c: Color, al: float, s: float) -> void:
	if al <= 0.0:
		return
	var d: Vector2 = Vector2(-0.24, -1.0).normalized()
	var nr: Vector2 = d.orthogonal()
	var L: float = 2.6 * s
	ci.draw_line(tip, tip + d * L * 1.05, Color(c, 0.35 * al), 0.9 * s)
	ci.draw_colored_polygon(PackedVector2Array([tip, tip + d * L + nr * 0.22 * s, tip + d * L - nr * 0.22 * s]), Color(0.92, 0.95, 1.0, al))
	ci.draw_line(tip + d * L * 0.15, tip + d * L, Color(c.lightened(0.5), al), 0.08 * s)
	ci.draw_line(tip + d * L - nr * 0.55 * s, tip + d * L + nr * 0.55 * s, Color(0.85, 0.7, 0.3, al), 0.22 * s)
	ci.draw_line(tip + d * L, tip + d * L * 1.3, Color(0.4, 0.25, 0.15, al), 0.2 * s)


# ---------------- Blitze, Säulen, Ringe, Geschosse ----------------

## Blitz (Drangsal, Gottkraft): Wolke, Leuchtstrahl mit Ästen, Einschlag.
static func bolt(ci: CanvasItem, e: Dictionary, z: float) -> void:
	var pts: PackedVector2Array = e["pts"]
	var al: float = float(e["l"]) / float(e["ml"])
	var lw: float = maxf(0.25, 1.8 / z)
	var top: Vector2 = pts[0]
	var bot: Vector2 = pts[pts.size() - 1]
	var sd: float = top.x * 3.1 + bot.y
	# Gewitterwolke
	for k: int in range(6):
		var o: Vector2 = Vector2((rnd(sd, k) - 0.5) * 14.0, (rnd(sd, k + 6) - 0.5) * 3.0)
		ci.draw_circle(top + o, 3.5 + rnd(sd, k + 12) * 3.0, Color(0.12, 0.1, 0.2, 0.35 * al))
	ci.draw_circle(top, 5.0, Color(0.75, 0.65, 1.0, 0.25 * al))
	glow_line(ci, pts, Color(0.75, 0.6, 1.0), al, lw)
	# Äste
	for b: int in [3, 5, 7]:
		var a: Vector2 = pts[b]
		var side: float = 1.0 if rnd(sd, b) > 0.5 else -1.0
		var end: Vector2 = a + Vector2(side * (3.0 + rnd(sd, b + 3) * 4.0), 5.0 + rnd(sd, b + 5) * 6.0)
		glow_line(ci, zigzag(a, end, sd + b, 4, 0.8), Color(0.75, 0.6, 1.0), al * 0.7, lw * 0.6)
	# Einschlag
	ell(ci, bot, 3.0 * (1.5 - al * 0.5), 1.4 * (1.5 - al * 0.5), Color(1, 1, 0.85, 0.5 * al))
	ell(ci, bot, 1.2, 0.6, Color(1, 1, 1, al))
	ering(ci, bot, 4.5 * (1.2 - al * 0.6), 2.1 * (1.2 - al * 0.6), Color(0.85, 0.75, 1.0, al), lw)


## Lichtsäule (Durchbruch, Mordzug-Leiter): Strahl mit weichem Rand, Bodenschein, aufsteigende Funken.
static func pillar(ci: CanvasItem, e: Dictionary, t: float, z: float) -> void:
	var c: Color = e["c"]
	var x: float = e["x"]
	var y: float = e["y"]
	var w: float = 3.0 * float(e["w"])
	var al: float = (1.0 - t) * minf(1.0, t * 8.0 + 0.3)
	var H: float = 70.0
	ell(ci, Vector2(x, y), w * 2.2, w * 0.9, Color(c, 0.3 * al))
	for j: int in range(4):
		var ww: float = w * (1.6 - j * 0.42)
		ci.draw_rect(Rect2(x - ww / 2.0, y - H, ww, H), Color(c.lightened(j * 0.15), (0.12 + j * 0.16) * al))
	ci.draw_rect(Rect2(x - w * 0.09, y - H, w * 0.18, H), Color(1, 1, 1, 0.95 * al))
	var sd: float = x * 0.37 + y
	for k: int in range(10):
		var py: float = y - fposmod(t * 40.0 + rnd(sd, k) * H, H)
		var px: float = x + (rnd(sd, k + 10) - 0.5) * w * 1.6
		star4(ci, Vector2(px, py), 0.5 + rnd(sd, k + 20) * 0.6, Color(1, 1, 0.9, al))


static func ring(ci: CanvasItem, e: Dictionary, t: float, z: float) -> void:
	var c: Color = e["c"]
	var cen: Vector2 = Vector2(e["x"], e["y"])
	var r: float = maxf(0.1, float(e["r"]) * (0.3 + t * 0.8))
	var lw: float = maxf(0.4, 1.8 / z)
	ell(ci, cen, r, r * 0.6, Color(c, 0.08 * (1.0 - t)))
	ering(ci, cen, r, r * 0.6, Color(c, 1.0 - t), lw * 1.6, 40)
	ering(ci, cen, r * 0.9, r * 0.9 * 0.6, Color(1, 1, 1, (1.0 - t) * 0.6), lw * 0.7, 40)


## Geschoss mit leuchtendem Schweif in Pfadfarbe (Mondpfad: Sichel).
static func proj(ci: CanvasItem, p: Dictionary, z: float, tnow: float) -> void:
	var c2: Color = p["c"]
	var big2: bool = p["big"]
	var pos: Vector2 = Vector2(p["x"], p["y"])
	var dir: Vector2 = Vector2.RIGHT
	var tg: Variant = p.get("t")
	if tg is Unit and is_instance_valid(tg):
		var tu: Unit = tg
		dir = (Vector2(tu.x, tu.y - 1.0) - pos).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
	if int(p["path"]) == 1:
		_crescent(ci, pos, 1.6 if big2 else 1.0, dir.angle(), Color(0.92, 0.97, 1.0), Color(c2, 0.5))
		return
	var r: float = 1.1 if big2 else 0.6
	for k: int in range(5):
		var q: Vector2 = pos - dir * (k + 1) * r * 0.8
		ci.draw_circle(q, r * (0.9 - k * 0.15), Color(c2, 0.35 - k * 0.06))
	ci.draw_circle(pos, r * 1.6, Color(c2, 0.25))
	ci.draw_circle(pos, r, Color(c2.lightened(0.3), 0.9))
	ci.draw_circle(pos, r * 0.45, Color.WHITE)


# ---------------- Rang 9 ----------------

## Gegenwart eines Ehrwürdigen: Lichtstrahl vom Himmel, rotierender Runenkreis am Boden, Verzerrungswellen,
## fallende Aprikosen-Lichter.
static func venerable(ci: CanvasItem, u: Unit, tnow: float, z: float, ec: Color) -> void:
	var c: Vector2 = Vector2(u.x, u.y)
	var lw: float = maxf(0.25, 1.4 / z)
	var pul: float = 0.5 + 0.5 * sin(tnow * 1.7 + u.id)
	ci.draw_rect(Rect2(c.x - 1.6, c.y - 60.0, 3.2, 58.0), Color(ec, 0.06 + 0.03 * pul))
	ci.draw_rect(Rect2(c.x - 0.5, c.y - 60.0, 1.0, 58.0), Color(1, 0.97, 0.8, 0.1 + 0.05 * pul))
	var a: float = tnow * 0.6
	ering(ci, c, 7.0, 3.6, Color(ec, 0.55), lw, 40)
	ering(ci, c, 5.6, 2.9, Color(ec.lightened(0.3), 0.35), lw, 40)
	for k: int in range(16):
		var b: float = a + k * TAU / 16.0
		var q: Vector2 = c + Vector2(cos(b) * 6.3, sin(b) * 3.25)
		ci.draw_rect(Rect2(q - Vector2(0.25, 0.15), Vector2(0.5 if k % 2 else 0.25, 0.3)), Color(1, 0.95, 0.7, 0.7))
	var tri: PackedVector2Array = PackedVector2Array()
	for k2: int in range(4):
		var b2: float = -a * 1.3 + k2 * TAU / 3.0
		tri.append(c + Vector2(cos(b2) * 5.4, sin(b2) * 2.8))
	ci.draw_polyline(tri, Color(ec, 0.4), lw)
	# Verzerrungswelle alle 2,5 s
	var wt: float = fposmod(tnow + u.id * 0.3, 2.5) / 2.5
	ering(ci, c, 6.0 + wt * 30.0, (6.0 + wt * 30.0) * 0.55, Color(1, 0.95, 0.75, 0.35 * (1.0 - wt)), lw * 1.5, 48)
	var sd: float = float(u.id)
	for k3: int in range(10):
		var ph: float = fposmod(tnow * 0.25 + rnd(sd, k3), 1.0)
		var q2: Vector2 = c + Vector2((rnd(sd, k3 + 10) - 0.5) * 30.0 + sin(tnow + k3) * 1.5, -30.0 + ph * 30.0 + (rnd(sd, k3 + 20) - 0.5) * 10.0)
		star4(ci, q2, 0.6, Color(1, 0.88, 0.4, 0.8 * sin(ph * PI)))


# ---------------- Umgebung ----------------

## Boot unter einem Siedler auf dem Wasser (Rumpf über den Beinen, Segel in Clanfarbe).
static func boat(ci: CanvasItem, x: float, y: float, f: int, col: Color, tnow: float, back: bool) -> void:
	var bob: float = sin(tnow * 2.5 + x) * 0.12
	var L: float = 1.7
	if back:
		# Kielwasser und Segel hinter der Figur
		ell(ci, Vector2(x - f * 2.2, y + 0.1), 1.4, 0.3, Color(1, 1, 1, 0.25))
		ci.draw_line(Vector2(x - f * 0.6, y - 0.4 + bob), Vector2(x - f * 0.6, y - 4.2 + bob), Color("#5a3a20"), 0.18)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - f * 0.5, y - 4.0 + bob), Vector2(x - f * 0.5, y - 1.4 + bob), Vector2(x - f * 2.0, y - 1.6 + bob)]), col.lightened(0.15))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - f * 0.5, y - 4.0 + bob), Vector2(x - f * 0.5, y - 3.3 + bob), Vector2(x - f * 1.0, y - 3.2 + bob)]), col.lightened(0.4))
		return
	var hull: PackedVector2Array = PackedVector2Array([Vector2(x - L, y - 0.95 + bob), Vector2(x + L, y - 0.95 + bob), Vector2(x + L * 0.75, y + 0.05 + bob), Vector2(x - L * 0.75, y + 0.05 + bob)])
	ci.draw_colored_polygon(hull, Color("#7a4e2a"))
	ci.draw_rect(Rect2(x - L, y - 0.95 + bob, L * 2.0, 0.28), Color("#b07a44"))
	ci.draw_rect(Rect2(x - L * 0.75, y - 0.18 + bob, L * 1.5, 0.22), Color("#4a2e18"))
	ci.draw_polyline(PackedVector2Array([hull[0], hull[1], hull[2], hull[3], hull[0]]), Color(0.1, 0.06, 0.04, 0.9), 0.12)
	ering(ci, Vector2(x, y + 0.1), L * 1.15, 0.35, Color(0.9, 0.97, 1.0, 0.45 + 0.2 * sin(tnow * 3.0)), 0.12, 20)


## Kriegsbanner an einer Stange über dem Kopf (Clanfarbe, flatternd).
static func banner(ci: CanvasItem, x: float, y: float, f: int, col: Color, tnow: float, s: float) -> void:
	var px: float = x - f * 0.9 * s / 0.27
	var top: float = y - 4.4 * s / 0.27
	ci.draw_line(Vector2(px, y - 0.6 * s / 0.27), Vector2(px, top), Color("#4a3018"), 0.16)
	var w: float = 1.4
	var hh: float = 0.9
	var pts: PackedVector2Array = PackedVector2Array()
	var bot: PackedVector2Array = PackedVector2Array()
	for i: int in range(5):
		var t: float = i / 4.0
		var wv: float = sin(tnow * 7.0 - t * 4.0 + x) * 0.18 * t
		pts.append(Vector2(px - f * w * t, top + 0.05 + wv))
		bot.append(Vector2(px - f * w * t, top + hh + wv - (0.25 if i == 4 else 0.0)))
	bot.reverse()
	pts.append_array(bot)
	ci.draw_colored_polygon(pts, col)
	ci.draw_polyline(pts, Color(0.08, 0.05, 0.05, 0.8), 0.08)
	ci.draw_rect(Rect2(px - 0.12, top - 0.25, 0.24, 0.25), Color("#e8c050"))


## Rauch aus dem Schornstein (deterministisch aus der Zeit, keine Partikel).
static func smoke(ci: CanvasItem, x: float, y: float, sd: int, tnow: float) -> void:
	for k: int in range(4):
		var ph: float = fposmod(tnow * 0.22 + k * 0.25 + sd * 0.137, 1.0)
		var px: float = x + ph * 2.6 + sin(ph * 6.0 + sd) * 0.35
		var py: float = y - ph * 6.5
		var r: float = 0.35 + ph * 0.9
		var a: float = 0.42 * sin(ph * PI) * (1.0 - ph * 0.4)
		pxblob(ci, Vector2(px, py), r, Color(0.8, 0.8, 0.83, a))


## Wind über einem Feld: helle Wellenkämme laufen über die Ähren (Kämme direkt berechnet, keine Schleife je Feld-Kachel).
static func field_wind(ci: CanvasItem, r: Rect2, tnow: float) -> void:
	var per: float = TAU / 0.55
	var y: float = r.position.y + 0.5
	while y < r.end.y - 0.4:
		# Kamm bei x·0,55 − t·2,2 + y·0,35 = π/2 + 2πn
		var x: float = (PI * 0.5 + tnow * 2.2 - y * 0.35) / 0.55
		x = r.position.x + fposmod(x - r.position.x, per) - per
		while x < r.end.x:
			var a: float = maxf(x - 1.6, r.position.x)
			var b: float = minf(x + 1.6, r.end.x)
			if b > a:
				ci.draw_rect(Rect2(a, y, b - a, 0.3), Color(1.0, 0.98, 0.8, 0.1))
			var a2: float = maxf(x - 0.7, r.position.x)
			var b2: float = minf(x + 0.7, r.end.x)
			if b2 > a2:
				ci.draw_rect(Rect2(a2, y, b2 - a2, 0.3), Color(1.0, 0.98, 0.85, 0.14))
			x += per
		y += 1.0


## Vögel und springende Fische nahe der Kamera.
func ambient(ci: CanvasItem, sim: Sim, view: Rect2, rdt: float, z: float, tnow: float) -> void:
	spawn_t -= rdt
	var W: int = GuData.W
	var H: int = GuData.H
	if spawn_t <= 0.0:
		spawn_t = 0.35
		if birds.size() < 3 and RNG.randf() < 0.25:
			var left: bool = RNG.randf() < 0.5
			var vy: float = (RNG.randf() - 0.5) * 3.0
			var sp: float = 5.0 + RNG.randf() * 3.0
			var y0: float = view.position.y + RNG.randf() * view.size.y
			var x0: float = view.position.x - 6.0 if left else view.end.x + 6.0
			var n: int = 3 + RNG.randi() % 4
			var fl: Array[Vector2] = []
			for k: int in range(n):
				var row: int = (k + 1) / 2
				fl.append(Vector2(-row * 1.3, row * 0.9 * (1.0 if k % 2 == 0 else -1.0)))
			birds.append({"x": x0, "y": y0, "vx": sp if left else -sp, "vy": vy, "m": fl, "ph": RNG.randf() * 10.0, "c": Color(0.15, 0.13, 0.14) if RNG.randf() < 0.7 else Color(0.96, 0.96, 0.94)})
		if fish.size() < 4:
			for tries: int in range(6):
				var fx: int = int(view.position.x + RNG.randf() * view.size.x)
				var fy: int = int(view.position.y + RNG.randf() * view.size.y)
				if fx < 1 or fy < 1 or fx >= W - 1 or fy >= H - 1:
					continue
				var i: int = fy * W + fx
				if sim.world.wdist[i] >= 3 and sim.world.wdist[i] < 30:
					fish.append({"x": fx + RNG.randf(), "y": fy + RNG.randf(), "l": 1.1, "ml": 1.1, "f": 1 if RNG.randf() < 0.5 else -1})
					break
	# Vögel
	var bi: int = birds.size() - 1
	while bi >= 0:
		var b: Dictionary = birds[bi]
		b["x"] = float(b["x"]) + float(b["vx"]) * rdt
		b["y"] = float(b["y"]) + float(b["vy"]) * rdt
		var bx: float = b["x"]
		if bx < view.position.x - 20.0 or bx > view.end.x + 20.0:
			birds.remove_at(bi)
			bi -= 1
			continue
		var dir: float = signf(float(b["vx"]))
		var bc: Color = b["c"]
		for o: Vector2 in b["m"]:
			var p: Vector2 = Vector2(bx + o.x * dir, float(b["y"]) + o.y)
			var fl2: float = sin(tnow * 11.0 + float(b["ph"]) + o.x)
			# Schatten weit unten (die Vögel fliegen hoch)
			ci.draw_rect(Rect2(p.x - 0.4, p.y + 7.0, 0.8, 0.18), Color(0, 0, 0, 0.12))
			var wy: float = -0.35 * fl2
			ci.draw_line(p + Vector2(-0.55, wy), p, bc, 0.16)
			ci.draw_line(p, p + Vector2(0.55, wy), bc, 0.16)
			ci.draw_rect(Rect2(p.x - 0.1, p.y - 0.05, 0.2, 0.18), bc)
		bi -= 1
	# Fische: Sprung im Bogen, Spritzer beim Ein- und Austauchen
	var fi: int = fish.size() - 1
	while fi >= 0:
		var e: Dictionary = fish[fi]
		e["l"] = float(e["l"]) - rdt
		if float(e["l"]) <= 0.0:
			fish.remove_at(fi)
			fi -= 1
			continue
		var t: float = 1.0 - float(e["l"]) / float(e["ml"])
		var fx2: float = e["x"]
		var fy2: float = e["y"]
		var f: float = float(e["f"])
		if t < 0.15 or (t > 0.62 and t < 0.85):
			var st: float = (t if t < 0.15 else t - 0.62) / 0.2
			ering(ci, Vector2(fx2 + (1.6 * f if t > 0.5 else 0.0), fy2), 0.4 + st * 0.9, 0.2 + st * 0.4, Color(1, 1, 1, 0.8 * (1.0 - st)), 0.12, 14)
		if t < 0.7:
			var jt: float = t / 0.7
			var p2: Vector2 = Vector2(fx2 + jt * 1.6 * f, fy2 - sin(jt * PI) * 1.4)
			var ang: float = cos(jt * PI) * -0.9 * f
			var d: Vector2 = Vector2(cos(ang) * f, sin(ang) * f * -1.0 * f).normalized() if f != 0.0 else Vector2.RIGHT
			ci.draw_line(p2 - d * 0.35, p2 + d * 0.35, Color(0.75, 0.82, 0.9), 0.32)
			ci.draw_line(p2 - d * 0.55, p2 - d * 0.3, Color(0.55, 0.62, 0.72), 0.24)
			ci.draw_rect(Rect2(p2 + d * 0.15 - Vector2(0.05, 0.08), Vector2(0.1, 0.1)), Color(0.1, 0.1, 0.12))
		fi -= 1
