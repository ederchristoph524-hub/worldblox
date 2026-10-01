class_name MapGu
extends RefCounted
## Handgestaltete Weltkarte der Gu-Welt (Reverend Insanity).
## Großform fest (feste Rauschsamen, Polygone, Splines), der Spielsamen ändert nur kleine Details
## (Küstenrauschen, Inselchen, Höhen). Füllt tile/region/hgt; Strände, Wände, Pflanzen macht World._finish.

const W: int = World.W
const H: int = World.H
const N: int = World.N

## Mittelpunkt des Zentralkontinents
const CX: float = 128.0
const CY: float = 126.0
## Sektorgrenzen außerhalb des Zentralkontinents (Bogenmaß, y zeigt nach unten)
const A_NE: float = -0.68
const A_SE: float = 0.66
const A_SW: float = 2.42
const A_NW: float = -2.46

## Inseln im Ostmeer: [x, y, Halbachse a, Halbachse b, Drehung]
const ISLANDS: Array = [
	[208.0, 96.0, 12.0, 8.0, 0.8], [222.0, 126.0, 15.0, 10.0, 1.77], [206.0, 156.0, 12.0, 8.0, -0.7]]

## Gebirgszüge im Zentralkontinent (Kontrollpunkte für Splines)
const RANGES_C: Array = [
	[Vector2(78, 100), Vector2(88, 90), Vector2(102, 82), Vector2(118, 76)],
	[Vector2(84, 136), Vector2(88, 152), Vector2(98, 166), Vector2(112, 174)],
	[Vector2(150, 172), Vector2(162, 160), Vector2(170, 146)],
	[Vector2(140, 84), Vector2(150, 92), Vector2(156, 104)]]

## Flüsse: Kontrollpunkte von der Quelle bis zur Mündung
const RIVERS: Array = [
	# Zentralkontinent
	[Vector2(104, 86), Vector2(112, 100), Vector2(126, 112), Vector2(146, 116), Vector2(164, 120), Vector2(184, 122)],
	[Vector2(96, 160), Vector2(110, 156), Vector2(126, 150), Vector2(140, 150)],
	[Vector2(160, 158), Vector2(152, 152)],
	# Südgrenze: Roter, Jade- und Gelber Drachenfluss treffen sich und fließen nach Süden
	[Vector2(44, 206), Vector2(62, 214), Vector2(84, 222), Vector2(104, 224), Vector2(124, 228)],
	[Vector2(212, 204), Vector2(190, 212), Vector2(168, 218), Vector2(146, 222), Vector2(124, 228)],
	[Vector2(130, 196), Vector2(122, 206), Vector2(128, 216), Vector2(124, 228)],
	[Vector2(124, 228), Vector2(130, 238), Vector2(126, 250)],
	# Nordebenen
	[Vector2(118, 26), Vector2(110, 36), Vector2(98, 44)],
	[Vector2(124, 70), Vector2(112, 60), Vector2(100, 52)],
	[Vector2(178, 70), Vector2(184, 52), Vector2(178, 36), Vector2(184, 18)]]

## Seen: [x, y, Radius x, Radius y]
const LAKES: Array = [
	[90.0, 46.0, 11.0, 7.0], [146.0, 150.0, 7.0, 5.0], [98.0, 120.0, 4.0, 3.0], [176.0, 98.0, 3.0, 2.5],
	[140.0, 38.0, 4.0, 2.5], [186.0, 60.0, 3.0, 2.0], [168.0, 84.0, 2.5, 2.0]]

## Oasen der Westwüste: [x, y, Wasserradius]
const OASES: Array = [
	[44.0, 102.0, 3.0], [28.0, 128.0, 2.0], [58.0, 140.0, 2.5], [52.0, 174.0, 2.0], [64.0, 116.0, 1.6], [34.0, 86.0, 1.6]]

## Buchten (+) und Halbinseln (-) am Weltrand: [x, y, Radius, Stärke]
const BAYS: Array = [
	[8.0, 150.0, 30.0, 0.75], [82.0, 246.0, 16.0, 0.55], [128.0, 254.0, 10.0, 0.4], [178.0, 14.0, 14.0, 0.5],
	[56.0, 32.0, 18.0, 0.5], [226.0, 222.0, 18.0, -0.45], [150.0, 6.0, 14.0, -0.25]]

## Einzelne Berge: [x, y, Radius]
const PEAKS: Array = [[80.0, 205.0, 4.0], [176.0, 230.0, 3.5]]


static func _nz(sd: int, freq: float, oct: int) -> FastNoiseLite:
	var n: FastNoiseLite = FastNoiseLite.new()
	n.seed = sd
	n.noise_type = FastNoiseLite.TYPE_VALUE_CUBIC
	n.frequency = freq
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves = oct
	return n


static func _n01(n: FastNoiseLite, x: float, y: float) -> float:
	return clampf(n.get_noise_2d(x, y) * 0.5 + 0.5, 0.0, 1.0)


## Radius des Zentralkontinents in Richtung a
static func _rc(a: float) -> float:
	return 58.0 + 4.5 * sin(3.0 * a + 0.7) + 3.0 * sin(5.0 * a + 2.1) + 2.0 * sin(2.0 * a + 1.0)


## Wellige Verschiebung einer Sektorgrenze in Abhängigkeit vom Abstand zur Mitte
static func _wob(nb: FastNoiseLite, r: float, k: int) -> float:
	return 0.05 * sin(r * 0.07 + k * 1.9) + nb.get_noise_2d(r * 1.4, k * 97.0) * 0.16


static func base_land(reg: int) -> int:
	match reg:
		0:
			return GuData.STEP
		2:
			return GuData.DES
		_:
			return GuData.GRASS


## Baut die Karte in w.tile/w.region/w.hgt. Rückgabe: Maske „offenes Außenmeer“ (1 = Wand darf entfallen, wenn weit von Land).
static func build(w: World, S: int) -> PackedByteArray:
	var nwx: FastNoiseLite = _nz(9101, 0.011, 3)
	var nwy: FastNoiseLite = _nz(9102, 0.011, 3)
	var nb: FastNoiseLite = _nz(9103, 0.02, 2)
	var nc: FastNoiseLite = _nz(9104, 0.026, 5)
	var nmi: FastNoiseLite = _nz(S + 17, 0.07, 3)
	var nr: FastNoiseLite = _nz(9105, 0.042, 3)
	nr.noise_type = FastNoiseLite.TYPE_PERLIN
	nr.frequency = 0.03
	var nd: FastNoiseLite = _nz(9106, 0.022, 2)
	var ne: FastNoiseLite = _nz(S + 3, 0.035, 4)
	var nis: FastNoiseLite = _nz(S + 41, 0.1, 2)
	# Wellen der vier Sektorgrenzen, vorab je ganzzahligem Radius
	var wob: Array[PackedFloat32Array] = []
	for k: int in range(4):
		var row: PackedFloat32Array = PackedFloat32Array()
		row.resize(220)
		for ri: int in range(220):
			row[ri] = _wob(nb, float(ri), k)
		wob.append(row)
	var outer: PackedByteArray = PackedByteArray()
	outer.resize(N)
	var tile: PackedByteArray = w.tile
	var region: PackedByteArray = w.region
	var hgt: PackedFloat32Array = w.hgt
	for y: int in range(H):
		for x: int in range(W):
			var i: int = y * W + x
			var fx: float = x + (_n01(nwx, x, y) - 0.5) * 16.0
			var fy: float = y + (_n01(nwy, x, y) - 0.5) * 16.0
			var dx: float = fx - CX
			var dy: float = fy - CY
			var r: float = sqrt(dx * dx + dy * dy)
			var a: float = atan2(dy, dx)
			var rc: float = _rc(a)
			var ri2: int = mini(int(r), 219)
			var bne: float = A_NE + wob[0][ri2]
			var bse: float = A_SE + wob[1][ri2]
			var bsw: float = A_SW + wob[2][ri2]
			var bnw: float = A_NW + wob[3][ri2]
			var reg: int
			if r < rc:
				reg = 4
			elif a > bne and a < bse:
				reg = 3
			elif a >= bse and a < bsw:
				reg = 1
			elif a > bnw and a <= bne:
				reg = 0
			else:
				reg = 2
			region[i] = reg
			# Umriss der ganzen Welt: Superellipse mit Küstenrauschen
			var ox: float = absf(fx - 128.0) / 114.0
			var oy: float = absf(fy - 128.0) / 113.0
			var s: float = pow(ox, 2.4) + pow(oy, 2.4)
			var cm: float = _n01(nc, x, y)
			var coast: float = s + (cm - 0.5) * 1.15 + (_n01(nmi, x, y) - 0.5) * 0.16
			for bb: Array in BAYS:
				var bx: float = fx - float(bb[0])
				var by: float = fy - float(bb[1])
				var br: float = bb[2]
				if absf(bx) > br or absf(by) > br:
					continue
				var bd: float = sqrt(bx * bx + by * by) / br
				if bd < 1.0:
					coast += (1.0 - bd) * (1.0 - bd) * float(bb[3]) * 3.0
			outer[i] = 1 if s > 1.0 else 0
			var land: bool = coast < 1.0
			var e: float = _n01(ne, x, y)
			var t: int = base_land(reg)
			var h: float = 0.45 + e * 0.2
			if reg == 4:
				var ca: float = cos(a)
				if ca > 0.4:
					var cut: float = (ca - 0.4) / 0.6 * (1.0 + _n01(nc, x, y + 500.0) * 5.0)
					land = land and r < rc - cut
				if land:
					var dm4: float = _n01(nd, x + 400.0, y)
					var rd4: float = 1.0 - absf(_n01(nr, x + 200.0, y) * 2.0 - 1.0)
					if dm4 > 0.62 and rd4 > 0.965:
						t = GuData.MOUNT
						h = 0.86
					elif dm4 > 0.58 and rd4 > 0.94:
						t = GuData.HILL
						h = 0.76
			elif reg == 3:
				var strip: float = minf((a - bne) * r, (bse - a) * r)
				var isl: bool = land and strip < 3.0 + _n01(nc, x + 300.0, y) * 11.0
				if not isl:
					land = false
					if s < 0.97 and r > rc + 9.0 and _n01(nis, x, y) > 0.78:
						land = true
				elif cm > 0.62 and e > 0.62:
					t = GuData.HILL
					h = 0.76
			elif land:
				match reg:
					0:
						var sl: float = 30.0 + (cm - 0.5) * 30.0 + (e - 0.5) * 4.0
						var tg: float = _n01(nd, x + 700.0, y)
						var rdn: float = 1.0 - absf(_n01(nr, x + 300.0, y) * 2.0 - 1.0)
						if fy < sl:
							t = GuData.SNOW
						if tg > 0.55 and rdn > 0.955 and fy < sl + 25.0:
							t = GuData.HILL
							h = 0.76
					1:
						var dm: float = _n01(nd, x, y)
						var rd: float = 1.0 - absf(_n01(nr, x, y) * 2.0 - 1.0)
						var tm: float = 0.95 - dm * 0.06
						if rd > tm + 0.03:
							t = GuData.MOUNT
							h = minf(0.91, 0.84 + (rd - tm) * 1.5)
						elif rd > tm:
							t = GuData.HILL
							h = 0.76
					2:
						var dd: float = Vector2(fx - 34.0, fy - 166.0).length()
						if dd < 30.0 + (e - 0.5) * 10.0:
							var st: float = sin((fx * 0.62 + fy * 0.9 + cm * 30.0) * 0.75)
							if st > 0.55:
								t = GuData.SAND
						elif _n01(nr, x + 900.0, y) > 0.86 and e > 0.5:
							t = GuData.SAND
			if not land and reg != 3 and reg != 4 and coast < 1.3 and coast > 1.06 and _n01(nis, x, y) > 0.8:
				land = true
			if not land:
				t = GuData.DEEP
				h = 0.3 - clampf(coast - 1.0, 0.0, 0.3) * 0.5
			tile[i] = t
			hgt[i] = h
	_islands(w, nc)
	_ranges(w)
	_peaks(w)
	_lakes(w, nc)
	_oases(w, nc)
	_rivers(w)
	_clearings(w)
	return outer


## Catmull-Rom-Spline durch die Kontrollpunkte, Abtastabstand step
static func _spline(pts: Array, step: float) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var n: int = pts.size()
	for k: int in range(n - 1):
		var p0: Vector2 = pts[maxi(k - 1, 0)]
		var p1: Vector2 = pts[k]
		var p2: Vector2 = pts[k + 1]
		var p3: Vector2 = pts[mini(k + 2, n - 1)]
		var segs: int = maxi(2, int(p1.distance_to(p2) / step))
		for sg: int in range(segs):
			var t: float = float(sg) / segs
			var t2: float = t * t
			var t3: float = t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(pts[n - 1])
	return out


## Seitliches Mäandern entlang einer abgetasteten Linie
static func _meander(pts: PackedVector2Array, n: FastNoiseLite, amp: float, off: float) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	out.resize(pts.size())
	var acc: float = 0.0
	for k: int in range(pts.size()):
		var a: Vector2 = pts[maxi(k - 1, 0)]
		var b: Vector2 = pts[mini(k + 1, pts.size() - 1)]
		var d: Vector2 = (b - a).normalized()
		if k > 0:
			acc += pts[k].distance_to(pts[k - 1])
		var nrm: Vector2 = Vector2(-d.y, d.x)
		var fade: float = minf(1.0, minf(k, pts.size() - 1 - k) / 8.0)
		out[k] = pts[k] + nrm * n.get_noise_2d(acc * 1.0, off) * amp * fade
	return out


static func _disc(w: World, c: Vector2, rad: float, t: int, h: float, only_land: bool) -> void:
	var r2: float = rad * rad
	var ri: int = int(ceil(rad))
	var cx: int = roundi(c.x)
	var cy: int = roundi(c.y)
	for yy: int in range(cy - ri, cy + ri + 1):
		for xx: int in range(cx - ri, cx + ri + 1):
			if xx < 0 or yy < 0 or xx >= W or yy >= H:
				continue
			var ddx: float = xx - c.x
			var ddy: float = yy - c.y
			if ddx * ddx + ddy * ddy > r2:
				continue
			var i: int = yy * W + xx
			if only_land and not GuData.is_land(w.tile[i]):
				continue
			if t == GuData.HILL and w.tile[i] == GuData.MOUNT:
				continue
			w.tile[i] = t
			w.hgt[i] = h


## Inselbögen des Ostmeers: feste Liste aus festem Zufallssamen, Form durch Rauschen
static func _island_list() -> Array:
	var out: Array = []
	for d: Array in ISLANDS:
		out.append(d)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4242
	for arc: float in [82.0, 96.0, 110.0]:
		var a0: float = A_NE + 0.14
		var a1: float = A_SE - 0.14
		var n: int = 7 if arc < 90.0 else (8 if arc < 100.0 else 7)
		for k: int in range(n):
			var a: float = lerpf(a0, a1, (k + 0.5) / n) + rng.randf_range(-0.07, 0.07)
			var rr: float = arc + rng.randf_range(-4.0, 4.0)
			var x: float = CX + cos(a) * rr
			var y: float = CY + sin(a) * rr
			var big: bool = rng.randf() < 0.35
			var la: float = rng.randf_range(6.0, 10.0) if big else rng.randf_range(3.0, 5.5)
			var lb: float = la * rng.randf_range(0.35, 0.6)
			out.append([x, y, la, lb, a + PI * 0.5 + rng.randf_range(-0.5, 0.5)])
	return out


static func _islands(w: World, nc: FastNoiseLite) -> void:
	var nd: FastNoiseLite = _nz(9108, 0.12, 2)
	for d: Array in _island_list():
		var cx: float = d[0]
		var cy: float = d[1]
		var la: float = d[2]
		var lb: float = d[3]
		var cr: float = cos(float(d[4]))
		var sr: float = sin(float(d[4]))
		var ri: int = int(la * 1.5) + 2
		for yy: int in range(int(cy) - ri, int(cy) + ri + 1):
			for xx: int in range(int(cx) - ri, int(cx) + ri + 1):
				if xx < 1 or yy < 1 or xx >= W - 1 or yy >= H - 1:
					continue
				var i: int = yy * W + xx
				if w.region[i] != 3 or w.tile[i] != GuData.DEEP:
					continue
				var ux: float = xx - cx + (_n01(nd, xx * 0.5, yy * 0.5 + 300.0) - 0.5) * la * 0.9
				var uy: float = yy - cy + (_n01(nd, xx * 0.5 + 300.0, yy * 0.5) - 0.5) * la * 0.9
				var u: float = (ux * cr + uy * sr) / la
				var v: float = (-ux * sr + uy * cr) / lb
				var q: float = u * u + v * v + (_n01(nd, xx, yy) - 0.5) * 1.2 + (_n01(nc, xx * 2.0, yy * 2.0) - 0.5) * 0.5
				if q < 1.0:
					w.tile[i] = GuData.GRASS
					w.hgt[i] = 0.5
					if la >= 6.0 and absf(v + (_n01(nd, xx + 50.0, yy) - 0.5) * 0.6) < 0.1 and absf(u) < 0.6:
						w.tile[i] = GuData.HILL
						w.hgt[i] = 0.76


static func _ranges(w: World) -> void:
	var nm: FastNoiseLite = _nz(9201, 0.08, 2)
	var k: int = 0
	for pts: Array in RANGES_C:
		var line: PackedVector2Array = _meander(_spline(pts, 0.5), nm, 3.0, k * 50.0)
		for j: int in range(line.size()):
			var wv: float = _n01(nm, j * 0.7, k * 31.0 + 200.0)
			_disc(w, line[j], 1.6 + wv * 1.6, GuData.HILL, 0.76, true)
		for j: int in range(line.size()):
			var wv2: float = _n01(nm, j * 0.7, k * 31.0 + 200.0)
			_disc(w, line[j], 0.6 + wv2 * 1.1, GuData.MOUNT, 0.85 + wv2 * 0.06, true)
		# Seitengrate
		for j: int in range(8, line.size() - 8, 22):
			var p: Vector2 = line[j]
			var dir: Vector2 = (line[j + 1] - line[j - 1]).normalized()
			var side: float = 1.0 if (j / 22) % 2 == 0 else -1.0
			var sp: Vector2 = Vector2(-dir.y, dir.x) * side
			for m: int in range(10):
				var q: Vector2 = p + sp * m * 0.8 + dir * m * 0.35
				_disc(w, q, 1.2, GuData.HILL, 0.76, true)
				if m < 6:
					_disc(w, q, 0.6, GuData.MOUNT, 0.86, true)
		k += 1


static func _peaks(w: World) -> void:
	for p: Array in PEAKS:
		var c: Vector2 = Vector2(p[0], p[1])
		var r: float = p[2]
		_disc(w, c, r + 3.0, GuData.HILL, 0.76, true)
		_disc(w, c, r, GuData.MOUNT, 0.95, true)


static func _blob(w: World, c: Vector2, rx: float, ry: float, nc: FastNoiseLite, t: int, h: float) -> void:
	var ri: int = int(ceil(maxf(rx, ry) * 1.3)) + 1
	for yy: int in range(int(c.y) - ri, int(c.y) + ri + 1):
		for xx: int in range(int(c.x) - ri, int(c.x) + ri + 1):
			if xx < 0 or yy < 0 or xx >= W or yy >= H:
				continue
			var u: float = (xx - c.x) / rx
			var v: float = (yy - c.y) / ry
			var q: float = u * u + v * v + (_n01(nc, xx * 3.0, yy * 3.0) - 0.5) * 0.8
			if q < 1.0:
				var i: int = yy * W + xx
				w.tile[i] = t
				w.hgt[i] = h


static func _lakes(w: World, nc: FastNoiseLite) -> void:
	for l: Array in LAKES:
		_blob(w, Vector2(l[0], l[1]), l[2], l[3], nc, GuData.DEEP, 0.3)


static func _oases(w: World, nc: FastNoiseLite) -> void:
	for o: Array in OASES:
		var c: Vector2 = Vector2(o[0], o[1])
		var r: float = o[2]
		_blob(w, c, r + 2.5, r * 0.8 + 2.0, nc, GuData.GRASS, 0.5)
		_blob(w, c, r, r * 0.8, nc, GuData.DEEP, 0.3)


static func _rivers(w: World) -> void:
	var nm: FastNoiseLite = _nz(9301, 0.12, 2)
	var k: int = 0
	for pts: Array in RIVERS:
		var line: PackedVector2Array = _meander(_spline(pts, 0.4), nm, 2.2, k * 40.0)
		var n: int = line.size()
		for j: int in range(n):
			var f: float = float(j) / maxf(1.0, n - 1)
			_disc(w, line[j], 0.75 + f * 0.75, GuData.SHAL, 0.34, false)
		k += 1


## Bauland um die Orte, an denen Siedlungen stehen
static func _clearings(w: World) -> void:
	for l: Dictionary in World.LANDMARKS:
		if l.get("kind", "") != "siedlung":
			continue
		var cx: int = int(l["x"])
		var cy: int = int(l["y"])
		var t: int = base_land(int(l["region"]))
		for yy: int in range(cy - 4, cy + 5):
			for xx: int in range(cx - 5, cx + 6):
				if xx < 0 or yy < 0 or xx >= W or yy >= H:
					continue
				var i: int = yy * W + xx
				var tt: int = w.tile[i]
				if tt == GuData.HILL or tt == GuData.MOUNT or tt == GuData.SAND:
					w.tile[i] = t
					w.hgt[i] = 0.5
