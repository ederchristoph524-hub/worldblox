class_name MapGu
extends RefCounted
## Handgestaltete Weltkarte der Gu-Welt (Reverend Insanity) – in jeder Kartengröße gleich geformt.
## Entworfen in Bezugskoordinaten 0..REF (256): Kachel (x, y) liegt bei ((x + 0.5) · REF / W, (y + 0.5) · REF / H).
## Großform fest (feste Rauschsamen, Ring, Sektoren, Splines), der Spielsamen ändert nur Details (Küstenrauschen,
## Inselchen, Höhen). Fünf deutlich getrennte Regionen: der Zentralkontinent in der Mitte, rundum ein Meeresgraben;
## Nordebenen, Südgrenze, Westwüste und Ostmeer in vier Sektoren, getrennt durch Meeresstraßen entlang der
## Diagonalen. Die Regionswände (World._finish) stehen mitten in diesen Gräben.
## Füllt tile/region/hgt; Strände, Wände, Pflanzen macht World._finish.

const REF: float = 256.0
## Mittelpunkt des Zentralkontinents
const CX: float = 128.0
const CY: float = 128.0
## Grundradius des Zentralkontinents und Breite der Meeresgräben zwischen den Regionen (Bezugskoordinaten)
const RC0: float = 62.0
const GAP: float = 14.0
## Halbachse des Weltumrisses (Superellipse) der Außenregionen
const OUTER: float = 127.0
## Sektorgrenzen außerhalb des Zentralkontinents (Bogenmaß, y zeigt nach unten)
const A_NE: float = -0.70
const A_SE: float = 0.68
const A_SW: float = 2.44
const A_NW: float = -2.44

## Große Inseln im Ostmeer: [x, y, Halbachse a, Halbachse b, Drehung]
const ISLANDS: Array = [
	[206.0, 98.0, 13.0, 8.0, 0.8], [226.0, 128.0, 15.0, 10.0, 1.77], [206.0, 160.0, 12.0, 8.0, -0.7], [236.0, 96.0, 7.0, 4.5, 0.3], [238.0, 162.0, 8.0, 5.0, 2.4]]

## Gebirgszüge (Kontrollpunkte für Splines): Zentralkontinent und Südgrenze
const RANGES_C: Array = [
	[Vector2(84, 98), Vector2(92, 86), Vector2(104, 78), Vector2(120, 72)],
	[Vector2(82, 134), Vector2(86, 150), Vector2(96, 164), Vector2(110, 172)],
	[Vector2(152, 170), Vector2(164, 158), Vector2(172, 144)],
	[Vector2(142, 80), Vector2(152, 90), Vector2(160, 102)]]
const RANGES_S: Array = [
	[Vector2(60, 224), Vector2(70, 216), Vector2(84, 212), Vector2(96, 216)],
	[Vector2(160, 216), Vector2(172, 222), Vector2(186, 220), Vector2(198, 212)],
	[Vector2(108, 238), Vector2(118, 244), Vector2(132, 246)]]
## Grate in den Nordebenen
const RANGES_N: Array = [
	[Vector2(70, 40), Vector2(84, 46), Vector2(98, 44)],
	[Vector2(160, 46), Vector2(174, 40), Vector2(188, 44)]]

## Flüsse: Kontrollpunkte von der Quelle bis zur Mündung
const RIVERS: Array = [
	# Zentralkontinent
	[Vector2(106, 84), Vector2(114, 100), Vector2(128, 110), Vector2(148, 114), Vector2(168, 120), Vector2(188, 124)],
	[Vector2(94, 158), Vector2(108, 156), Vector2(124, 152), Vector2(140, 156), Vector2(150, 176), Vector2(146, 190)],
	[Vector2(84, 112), Vector2(74, 118), Vector2(64, 120)],
	# Südgrenze: Roter, Jade- und Gelber Drachenfluss treffen sich und fließen nach Süden
	[Vector2(52, 214), Vector2(66, 222), Vector2(86, 228), Vector2(106, 230), Vector2(124, 232)],
	[Vector2(204, 210), Vector2(188, 216), Vector2(168, 224), Vector2(146, 228), Vector2(124, 232)],
	[Vector2(128, 210), Vector2(122, 218), Vector2(128, 226), Vector2(124, 232)],
	[Vector2(124, 232), Vector2(128, 242), Vector2(126, 254)],
	# Nordebenen
	[Vector2(118, 26), Vector2(110, 36), Vector2(98, 40), Vector2(86, 30)],
	[Vector2(178, 50), Vector2(184, 36), Vector2(178, 24), Vector2(184, 6)]]

## Seen: [x, y, Radius x, Radius y]
const LAKES: Array = [
	[92.0, 32.0, 9.0, 5.0], [146.0, 150.0, 6.0, 4.0], [100.0, 120.0, 4.0, 3.0], [172.0, 100.0, 3.5, 2.5],
	[140.0, 28.0, 4.0, 2.5], [196.0, 52.0, 3.0, 2.0], [74.0, 236.0, 3.0, 2.0], [178.0, 236.0, 3.5, 2.0]]

## Oasen der Westwüste: [x, y, Wasserradius]
const OASES: Array = [
	[36.0, 110.0, 3.4], [22.0, 132.0, 2.0], [46.0, 150.0, 2.4], [30.0, 176.0, 1.8], [44.0, 92.0, 1.6], [20.0, 92.0, 1.6], [16.0, 158.0, 1.4]]

## Buchten (+) und Halbinseln (-) an den Außenküsten: [x, y, Radius, Stärke]
const BAYS: Array = [
	[4.0, 140.0, 20.0, 0.6], [86.0, 252.0, 12.0, 0.5], [170.0, 254.0, 10.0, 0.4], [150.0, 2.0, 12.0, 0.45],
	[60.0, 6.0, 14.0, 0.4], [214.0, 30.0, 14.0, -0.35], [44.0, 236.0, 12.0, -0.3]]

## Buchten des Zentralkontinents (Winkel, Tiefe in Bezugskoordinaten, Breite in Bogenmaß)
const C_BAYS: Array = [[0.15, 13.0, 0.22], [2.2, 8.0, 0.18], [-1.25, 7.0, 0.16], [1.35, 6.0, 0.14], [-2.75, 9.0, 0.2]]

## Einzelne Berge: [x, y, Radius]
const PEAKS: Array = [[80.0, 205.0, 4.5], [176.0, 230.0, 4.0]]


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
	return RC0 + 4.5 * sin(3.0 * a + 0.7) + 3.0 * sin(5.0 * a + 2.1) + 2.0 * sin(2.0 * a + 1.0)


## Wellige Verschiebung einer Sektorgrenze in Abhängigkeit vom Abstand zur Mitte
static func _wob(nb: FastNoiseLite, r: float, k: int) -> float:
	return 0.03 * sin(r * 0.07 + k * 1.9) + nb.get_noise_2d(r * 1.4, k * 97.0) * 0.08


static func base_land(reg: int) -> int:
	match reg:
		0:
			return GuData.STEP
		2:
			return GuData.DES
		_:
			return GuData.GRASS


## Kachel → Bezugskoordinaten und zurück
static func _kr() -> float:
	return REF / GuData.W


static func to_tile(p: Vector2) -> Vector2:
	return p * (GuData.W / REF)


## Rauschfeld in Kachel-Auflösung (nativ über Noise.get_image, ein Byte je Kachel = _n01 · 255), abgetastet an den
## Bezugskoordinaten der Kachelmitten plus Verschiebung (ox, oy) in Bezugseinheiten. tile_units: Frequenz in Kacheln.
## div > 1: in 1/div der Auflösung berechnet und weich hochskaliert (für glatte, großräumige Felder – spart Zeit).
static func _field(n: FastNoiseLite, ox: float = 0.0, oy: float = 0.0, tile_units: bool = false, div: int = 1) -> PackedByteArray:
	var kr: float = (1.0 if tile_units else _kr()) * div
	var f0: float = n.frequency
	n.frequency = f0 * kr
	n.offset = Vector3(0.5 + ox / kr, 0.5 + oy / kr, 0.0) if not tile_units else Vector3(ox, oy, 0.0)
	var im: Image = n.get_image(ceili(float(GuData.W) / div), ceili(float(GuData.H) / div), false, false, false)
	n.frequency = f0
	n.offset = Vector3.ZERO
	if div > 1:
		im.resize(GuData.W, GuData.H, Image.INTERPOLATE_BILINEAR)
	return im.get_data()


## Baut die Karte in w.tile/w.region/w.hgt. Rückgabe: leer (Regionswände durchgehend bis zum Kartenrand).
static func build(w: World, S: int) -> PackedByteArray:
	var W: int = GuData.W
	var H: int = GuData.H
	var kr: float = _kr()
	const B: float = 1.0 / 255.0
	var nb: FastNoiseLite = _nz(9103, 0.02, 2)
	var nc: FastNoiseLite = _nz(9104, 0.026, 5)
	var nr: FastNoiseLite = _nz(9105, 0.042, 3)
	nr.noise_type = FastNoiseLite.TYPE_PERLIN
	nr.frequency = 0.03
	var nd: FastNoiseLite = _nz(9106, 0.022, 2)
	# Rauschfelder (Bezugskoordinaten; nmi fein in Kacheln, gleich fein in jeder Kartengröße)
	var tf0: int = Time.get_ticks_usec()
	# großräumige Felder in halber (Verwacklung: Viertel-)Auflösung, auf kleinen Karten voll
	var dv: int = 2 if GuData.W > 300 else 1
	var f_wx: PackedByteArray = _field(_nz(9101, 0.011, 3), 0.0, 0.0, false, dv * 2)
	var f_wy: PackedByteArray = _field(_nz(9102, 0.011, 3), 0.0, 0.0, false, dv * 2)
	var f_c: PackedByteArray = _field(nc, 0.0, 0.0, false, dv)
	var f_e: PackedByteArray = _field(_nz(S + 3, 0.035, 4), 0.0, 0.0, false, dv)
	var f_mi: PackedByteArray = _field(_nz(S + 17, 0.07, 3), 0.0, 0.0, true)
	var f_d4: PackedByteArray = _field(nd, 400.0, 0.0, false, dv)
	var f_r4: PackedByteArray = _field(nr, 200.0, 0.0, false, dv)
	var f_d0: PackedByteArray = _field(nd, 700.0, 0.0, false, dv)
	var f_r0: PackedByteArray = _field(nr, 300.0, 0.0, false, dv)
	var f_d1: PackedByteArray = _field(nd, 0.0, 0.0, false, dv)
	var f_r1: PackedByteArray = _field(nr, 0.0, 0.0, false, dv)
	var f_r2: PackedByteArray = _field(nr, 900.0, 0.0, false, dv)
	w.gen_ms["gu_fields"] = (Time.get_ticks_usec() - tf0) / 1000.0
	# Wellen der vier Sektorgrenzen, vorab je ganzzahligem Radius
	var wob: PackedFloat32Array = PackedFloat32Array()
	wob.resize(800)
	for k: int in range(4):
		for ri: int in range(200):
			wob[k * 200 + ri] = _wob(nb, float(ri), k)
	# Radius des Zentralkontinents samt Buchten je Winkel (Tabelle)
	const AB: int = 1024
	var rct: PackedFloat32Array = PackedFloat32Array()
	var rcb: PackedFloat32Array = PackedFloat32Array()
	rct.resize(AB + 1)
	rcb.resize(AB + 1)
	for k: int in range(AB + 1):
		var a: float = -PI + TAU * k / AB
		rct[k] = _rc(a)
		var rr: float = 0.0
		for cb: Array in C_BAYS:
			var da: float = absf(angle_difference(a, float(cb[0])))
			if da < float(cb[2]):
				var f0: float = 1.0 - da / float(cb[2])
				rr += float(cb[1]) * f0 * f0
		rcb[k] = rr
	# Buchten und Halbinseln der Außenküsten als Zusatzfeld
	var bayf: PackedFloat32Array = PackedFloat32Array()
	bayf.resize(W * H)
	for bb: Array in BAYS:
		var c: Vector2 = to_tile(Vector2(bb[0], bb[1]))
		var br: float = float(bb[2]) / kr
		var bri: int = ceili(br)
		for yy: int in range(maxi(0, int(c.y) - bri), mini(H, int(c.y) + bri + 1)):
			for xx: int in range(maxi(0, int(c.x) - bri), mini(W, int(c.x) + bri + 1)):
				var bd: float = Vector2(xx - c.x, yy - c.y).length() / br
				if bd < 1.0:
					bayf[yy * W + xx] += (1.0 - bd) * (1.0 - bd) * float(bb[3]) * 3.0
	var tile: PackedByteArray = w.tile
	var region: PackedByteArray = w.region
	var hgt: PackedFloat32Array = w.hgt
	var g2: float = GAP * 0.5
	var ka: float = AB / TAU
	for y: int in range(H):
		var py: float = (y + 0.5) * kr
		for x: int in range(W):
			var i: int = y * W + x
			var px: float = (x + 0.5) * kr
			# leicht verwackelte Lage für die Großform
			var fx: float = px + (f_wx[i] * B - 0.5) * 12.0
			var fy: float = py + (f_wy[i] * B - 0.5) * 12.0
			var dx: float = fx - CX
			var dy: float = fy - CY
			var r: float = sqrt(dx * dx + dy * dy)
			var a: float = atan2(dy, dx)
			var ak: int = int((a + PI) * ka)
			var rc: float = rct[ak]
			# Region: Ring um den Zentralkontinent (Wand mitten im Graben), außen vier Sektoren
			var reg: int = 4
			var strip: float = 99.0   # Abstand zur nächsten Sektorgrenze (Bezugseinheiten)
			if r >= rc + g2:
				var ri2: int = mini(int(r), 199)
				var bne: float = A_NE + wob[ri2]
				var bse: float = A_SE + wob[200 + ri2]
				var bsw: float = A_SW + wob[400 + ri2]
				var bnw: float = A_NW + wob[600 + ri2]
				if a > bne and a < bse:
					reg = 3
					strip = minf(a - bne, bse - a) * r
				elif a >= bse and a < bsw:
					reg = 1
					strip = minf(a - bse, bsw - a) * r
				elif a > bnw and a <= bne:
					reg = 0
					strip = minf(a - bnw, bne - a) * r
				else:
					reg = 2
					var aa: float = a if a > 0.0 else a + TAU
					strip = minf(aa - bsw, bnw + TAU - aa) * r
			region[i] = reg
			var cm: float = f_c[i] * B
			var mi: float = f_mi[i] * B - 0.5
			var e: float = f_e[i] * B
			var land: bool
			var coast: float  # > 1 = Meer
			if reg == 4:
				# Zentralkontinent: Küste innerhalb des Rings, mit Buchten
				var rr: float = rc - 2.0 - (cm - 0.5) * 7.0 - mi * 1.2 - rcb[ak]
				coast = r / maxf(1.0, rr)
				land = coast < 1.0
			else:
				# Außenregionen: Land erst jenseits des Grabens, Abstand zu den Diagonalstraßen, Weltumriss
				var ox: float = absf(fx - 128.0) / OUTER
				var oy: float = absf(fy - 128.0) / OUTER
				coast = pow(ox, 3.4) + pow(oy, 3.4) + (cm - 0.5) * 0.5 + mi * 0.08 + bayf[i]
				var inner: float = r - (rc + GAP) - (cm - 0.5) * 6.0 - mi * 1.5
				var side: float = strip - g2 - (cm - 0.5) * 5.0 - mi * 1.5
				land = coast < 1.0 and inner > 0.0 and side > 0.0 and reg != 3
				if not land and coast < 1.0:
					coast = maxf(coast, 1.0 + clampf(minf(-inner, -side) / 12.0, 0.0, 0.5))
			var t: int = base_land(reg)
			var h: float = 0.45 + e * 0.2
			if land:
				match reg:
					4:
						var dm4: float = f_d4[i] * B
						var rd4: float = 1.0 - absf(f_r4[i] * B * 2.0 - 1.0)
						if dm4 > 0.62 and rd4 > 0.965:
							t = GuData.MOUNT
							h = 0.86
						elif dm4 > 0.58 and rd4 > 0.94:
							t = GuData.HILL
							h = 0.76
					0:
						var sl: float = 22.0 + (cm - 0.5) * 22.0 + (e - 0.5) * 4.0
						var tg: float = f_d0[i] * B
						var rdn: float = 1.0 - absf(f_r0[i] * B * 2.0 - 1.0)
						if fy < sl:
							t = GuData.SNOW
						if tg > 0.55 and rdn > 0.955 and fy < sl + 22.0:
							t = GuData.HILL
							h = 0.76
					1:
						var dm: float = f_d1[i] * B
						var rd: float = 1.0 - absf(f_r1[i] * B * 2.0 - 1.0)
						var tm: float = 0.966 - dm * 0.06
						if rd > tm + 0.03:
							t = GuData.MOUNT
							h = minf(0.91, 0.84 + (rd - tm) * 1.5)
						elif rd > tm:
							t = GuData.HILL
							h = 0.76
					2:
						var ddx: float = fx - 30.0
						var ddy: float = fy - 168.0
						if ddx * ddx + ddy * ddy < pow(26.0 + (e - 0.5) * 10.0, 2.0):
							var st: float = sin((fx * 0.62 + fy * 0.9 + cm * 30.0) * 0.75)
							if st > 0.55:
								t = GuData.SAND
						elif f_r2[i] * B > 0.86 and e > 0.5:
							t = GuData.SAND
			else:
				t = GuData.DEEP
				h = 0.3 - clampf(coast - 1.0, 0.0, 0.3) * 0.5
			tile[i] = t
			hgt[i] = h
	var tm: int = Time.get_ticks_usec()
	w.gen_ms["gu_loop"] = (tm - tf0) / 1000.0 - float(w.gen_ms["gu_fields"])
	_islands(w, nc, S)
	var t1: int = Time.get_ticks_usec()
	_ranges(w, RANGES_C, 0)
	_ranges(w, RANGES_S, 10)
	_ranges(w, RANGES_N, 20, false)
	_peaks(w)
	var t2: int = Time.get_ticks_usec()
	_lakes(w, nc)
	_oases(w, nc)
	_rivers(w)
	_clearings(w)
	var t3: int = Time.get_ticks_usec()
	w.gen_ms["gu_isl_rng_riv"] = [(t1 - tm) / 1000.0, (t2 - t1) / 1000.0, (t3 - t2) / 1000.0]
	return PackedByteArray()


## Catmull-Rom-Spline durch die Kontrollpunkte (Bezugskoordinaten, Ergebnis in Kacheln), Abtastabstand step (Kacheln)
static func _spline(pts: Array, step: float) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var n: int = pts.size()
	var k2: float = 1.0 / _kr()
	for k: int in range(n - 1):
		var p0: Vector2 = pts[maxi(k - 1, 0)] * k2
		var p1: Vector2 = pts[k] * k2
		var p2: Vector2 = pts[k + 1] * k2
		var p3: Vector2 = pts[mini(k + 2, n - 1)] * k2
		var segs: int = maxi(2, int(p1.distance_to(p2) / step))
		for sg: int in range(segs):
			var t: float = float(sg) / segs
			var t2: float = t * t
			var t3: float = t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(Vector2(pts[n - 1]) * k2)
	return out


## Seitliches Mäandern entlang einer abgetasteten Linie (Kacheln); amp in Kacheln
static func _meander(pts: PackedVector2Array, n: FastNoiseLite, amp: float, off: float) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	out.resize(pts.size())
	var acc: float = 0.0
	var kr: float = _kr()
	for k: int in range(pts.size()):
		var a: Vector2 = pts[maxi(k - 1, 0)]
		var b: Vector2 = pts[mini(k + 1, pts.size() - 1)]
		var d: Vector2 = (b - a).normalized()
		if k > 0:
			acc += pts[k].distance_to(pts[k - 1])
		var nrm: Vector2 = Vector2(-d.y, d.x)
		var fade: float = minf(1.0, minf(k, pts.size() - 1 - k) / 8.0)
		out[k] = pts[k] + nrm * n.get_noise_2d(acc * kr, off) * amp * fade
	return out


## Scheibe in Kachel-Koordinaten
static func _disc(w: World, c: Vector2, rad: float, t: int, h: float, only_land: bool) -> void:
	var W: int = GuData.W
	var H: int = GuData.H
	var r2: float = rad * rad
	var ri: int = int(ceil(rad))
	var cx: int = roundi(c.x)
	var cy: int = roundi(c.y)
	for yy: int in range(maxi(0, cy - ri), mini(H, cy + ri + 1)):
		for xx: int in range(maxi(0, cx - ri), mini(W, cx + ri + 1)):
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


## Inselbögen des Ostmeers: feste Liste aus festem Zufallssamen (Bezugskoordinaten), Form durch Rauschen
static func _island_list(S: int) -> Array:
	var out: Array = []
	for d: Array in ISLANDS:
		out.append(d)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4242
	for arc: float in [90.0, 102.0, 114.0, 126.0, 140.0]:
		var a0: float = A_NE + 0.2 + (arc - 90.0) * 0.0015
		var a1: float = A_SE - 0.2 - (arc - 90.0) * 0.0015
		var n: int = 7 if arc < 95.0 else (9 if arc < 130.0 else 6)
		for k: int in range(n):
			var a: float = lerpf(a0, a1, (k + 0.5) / n) + rng.randf_range(-0.07, 0.07)
			var rr: float = arc + rng.randf_range(-4.0, 4.0)
			var x: float = CX + cos(a) * rr
			var y: float = CY + sin(a) * rr
			var big: bool = rng.randf() < 0.3
			var la: float = rng.randf_range(5.0, 9.0) if big else rng.randf_range(2.5, 5.0)
			var lb: float = la * rng.randf_range(0.35, 0.6)
			out.append([x, y, la, lb, a + PI * 0.5 + rng.randf_range(-0.5, 0.5)])
	# Inselchen je nach Spielsamen
	var r2: RandomNumberGenerator = RandomNumberGenerator.new()
	r2.seed = S + 77
	for k: int in range(16):
		var a: float = r2.randf_range(A_NE + 0.22, A_SE - 0.22)
		var rr: float = r2.randf_range(86.0, 136.0)
		var la: float = r2.randf_range(1.6, 3.2)
		out.append([CX + cos(a) * rr, CY + sin(a) * rr, la, la * 0.6, r2.randf() * PI])
	return out


static func _islands(w: World, nc: FastNoiseLite, S: int) -> void:
	var W: int = GuData.W
	var H: int = GuData.H
	var kr: float = _kr()
	var k2: float = 1.0 / kr
	var nd: FastNoiseLite = _nz(9108, 0.12, 2)
	for d: Array in _island_list(S):
		var cx: float = float(d[0]) * k2
		var cy: float = float(d[1]) * k2
		var la: float = float(d[2]) * k2
		var lb: float = float(d[3]) * k2
		var cr: float = cos(float(d[4]))
		var sr: float = sin(float(d[4]))
		var ri: int = int(la * 1.5) + 2
		for yy: int in range(maxi(1, int(cy) - ri), mini(H - 1, int(cy) + ri + 1)):
			for xx: int in range(maxi(1, int(cx) - ri), mini(W - 1, int(cx) + ri + 1)):
				var i: int = yy * W + xx
				if w.region[i] != 3 or w.tile[i] != GuData.DEEP:
					continue
				var qx: float = xx * kr
				var qy: float = yy * kr
				var ux: float = xx - cx + (_n01(nd, qx * 0.5, qy * 0.5 + 300.0) - 0.5) * la * 0.9
				var uy: float = yy - cy + (_n01(nd, qx * 0.5 + 300.0, qy * 0.5) - 0.5) * la * 0.9
				var u: float = (ux * cr + uy * sr) / la
				var v: float = (-ux * sr + uy * cr) / lb
				var q: float = u * u + v * v + (_n01(nd, qx, qy) - 0.5) * 1.2 + (_n01(nc, qx * 2.0, qy * 2.0) - 0.5) * 0.5
				if q < 1.0:
					w.tile[i] = GuData.GRASS
					w.hgt[i] = 0.5
					if la >= 6.0 * k2 and absf(v + (_n01(nd, qx + 50.0, qy) - 0.5) * 0.6) < 0.1 and absf(u) < 0.6:
						w.tile[i] = GuData.HILL
						w.hgt[i] = 0.76


## Gebirgszüge entlang der Splines: breite Hügel-Vorberge, Gebirgskamm mit Schneegipfeln (peaks = false: nur Hügel).
static func _ranges(w: World, list: Array, off: int, peaks: bool = true) -> void:
	var nm: FastNoiseLite = _nz(9201, 0.08, 2)
	var k2: float = 1.0 / _kr()
	var k: int = off
	for pts: Array in list:
		# Abtastung alle 0,5 Bezugseinheiten (gleiche Form in jeder Kartengröße)
		var line: PackedVector2Array = _meander(_spline(pts, 0.5 * k2), nm, 3.0 * k2, k * 50.0)
		var ls: int = line.size()
		for j: int in range(ls):
			var wv: float = _n01(nm, j * 0.7, k * 31.0 + 200.0)
			_disc(w, line[j], (2.2 + wv * 2.0) * k2, GuData.HILL, 0.76, true)
		if not peaks:
			k += 1
			continue
		for j: int in range(ls):
			var wv2: float = _n01(nm, j * 0.7, k * 31.0 + 200.0)
			_disc(w, line[j], (0.7 + wv2 * 1.2) * k2, GuData.MOUNT, 0.85 + wv2 * 0.1, true)
		# Seitengrate
		var stp: int = 22
		for j: int in range(8, ls - 8, stp):
			var p: Vector2 = line[j]
			var dir: Vector2 = (line[mini(j + 1, ls - 1)] - line[maxi(j - 1, 0)]).normalized()
			var side: float = 1.0 if (j / stp) % 2 == 0 else -1.0
			var sp: Vector2 = Vector2(-dir.y, dir.x) * side
			for m: int in range(10):
				var q: Vector2 = p + (sp * m * 0.8 + dir * m * 0.35) * k2
				_disc(w, q, 1.2 * k2, GuData.HILL, 0.76, true)
				if m < 6:
					_disc(w, q, 0.6 * k2, GuData.MOUNT, 0.86, true)
		k += 1


static func _peaks(w: World) -> void:
	var k2: float = 1.0 / _kr()
	for p: Array in PEAKS:
		var r: float = p[2]
		if r <= 0.0:
			continue
		var c: Vector2 = to_tile(Vector2(p[0], p[1]))
		_disc(w, c, (r + 3.0) * k2, GuData.HILL, 0.76, true)
		_disc(w, c, r * k2, GuData.MOUNT, 0.95, true)


## Ellipse mit Rauschrand (Mitte in Bezugskoordinaten, Radien in Bezugseinheiten)
static func _blob(w: World, cref: Vector2, rx0: float, ry0: float, nc: FastNoiseLite, t: int, h: float) -> void:
	var W: int = GuData.W
	var H: int = GuData.H
	var kr: float = _kr()
	var c: Vector2 = to_tile(cref)
	var rx: float = rx0 / kr
	var ry: float = ry0 / kr
	var ri: int = int(ceil(maxf(rx, ry) * 1.3)) + 1
	for yy: int in range(maxi(0, int(c.y) - ri), mini(H, int(c.y) + ri + 1)):
		for xx: int in range(maxi(0, int(c.x) - ri), mini(W, int(c.x) + ri + 1)):
			var u: float = (xx - c.x) / rx
			var v: float = (yy - c.y) / ry
			var q: float = u * u + v * v + (_n01(nc, xx * kr * 3.0, yy * kr * 3.0) - 0.5) * 0.8
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
	var k2: float = 1.0 / _kr()
	# Flüsse werden mit der Karte breiter, aber langsamer als sie (sonst wirken sie auf großen Karten wie Seen)
	var wk: float = sqrt(k2)
	var k: int = 0
	for pts: Array in RIVERS:
		var line: PackedVector2Array = _meander(_spline(pts, 0.4 * maxf(1.0, sqrt(k2))), nm, 2.2 * k2, k * 40.0)
		var n: int = line.size()
		for j: int in range(n):
			var f: float = float(j) / maxf(1.0, n - 1)
			_disc(w, line[j], (0.75 + f * 0.75) * wk, GuData.SHAL, 0.34, false)
		k += 1


## Bauland um die Orte, an denen Siedlungen stehen
static func _clearings(w: World) -> void:
	var W: int = GuData.W
	var H: int = GuData.H
	var k2: float = 1.0 / _kr()
	var rx: int = int(5.0 * k2)
	var ry: int = int(4.0 * k2)
	for l: Dictionary in World.LANDMARKS:
		if l.get("kind", "") != "siedlung":
			continue
		var c: Vector2 = to_tile(Vector2(float(l["x"]), float(l["y"])))
		var cx: int = int(c.x)
		var cy: int = int(c.y)
		var t: int = base_land(int(l["region"]))
		for yy: int in range(maxi(0, cy - ry), mini(H, cy + ry + 1)):
			for xx: int in range(maxi(0, cx - rx), mini(W, cx + rx + 1)):
				var i: int = yy * W + xx
				var tt: int = w.tile[i]
				if tt == GuData.HILL or tt == GuData.MOUNT or tt == GuData.SAND:
					w.tile[i] = t
					w.hgt[i] = 0.5
