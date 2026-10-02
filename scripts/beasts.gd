class_name Beasts
extends RefCounted
## Tiere, Bestien und Ödbestien der Nahansicht als hochaufgelöste Pixel-Sprites (gleicher Stil wie Bäume
## und Gebäude: Licht von links oben, Rampen-Schattierung, dunkle Kontur, Bodenschatten).
##
## Jede Art (GuData.SPEC, Körperbau "arch") bekommt 4 Laufbilder + 1 Standbild, Flieger zusätzlich 4
## Flugbilder; dazu weiße Silhouetten fürs Treffer-Aufblitzen. Erzeugt im Hintergrund über
## Sprites._hd_jobs (eine Art je Auftrag-Bild), angefordert beim ersten Zeichnen (get_set).
## Ein Sprite-Pixel = 0,5 Figur-Einheiten (bei ss 1) – große Bestien bekommen mehr Pixel (k = 2·ss),
## damit das Pixelraster auf dem Bildschirm für alle Tiere gleich fein bleibt.
##
## Einheiten wie Sprites.draw_animal: x nach vorne (Kopf), y nach unten, Füße bei y = 0.

const K1: float = 2.0
const WALK: int = 4
## Arten ohne HD-Bild (winzige leuchtende Gu bleiben Rechteck-Figuren)
const SKIP: Array[String] = ["gu", "igu"]
## Körperbau-Arten, die beim Fliegen eigene Flugbilder haben
const FLYERS: Array[String] = ["crane", "eagle", "bat"]

static var _sets: Dictionary = {}
static var _pending: Dictionary = {}

var im: Image
var k: float
var ux0: float
var uy0: float
var w: int
var h: int
## Kopfoberseite für die Krone (Einheiten), Augenpunkt
var crown_at: Vector2 = Vector2.INF


func _init(x0: float, y0: float, x1: float, y1: float, kk: float) -> void:
	k = kk
	ux0 = x0
	uy0 = y0
	w = ceili((x1 - x0) * k)
	h = ceili((y1 - y0) * k)
	im = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)


# ---------------- Abfrage ----------------

## Bildsatz einer Art: {"walk": [5 Texturen, Index 4 = Stand], "fly": [4] (Flieger), "white": [..], "fwhite": [..],
## "foot": Vector2 (Pixel), "px": Einheiten je Pixel}. Leer, solange noch nicht erzeugt (dann eingereiht).
static func get_set(sp: String) -> Dictionary:
	var d: Variant = _sets.get(sp)
	if d != null:
		return d
	if not _pending.has(sp):
		_pending[sp] = true
		_queue(sp, true)
	return {}


## Alle Arten vorab im Hintergrund erzeugen (nach den Objekten der Nahansicht).
static func prefetch() -> void:
	for sp: String in GuData.SPEC.keys():
		if not _pending.has(sp) and not SKIP.has(str(GuData.SPEC[sp].get("arch", ""))):
			_pending[sp] = true
			_queue(sp, false)
	for sp2: String in ["sheep", "pig", "chicken"]:
		if not _pending.has(sp2):
			_pending[sp2] = true
			_queue(sp2, false)


static func _arch_of(sp: String) -> String:
	if sp == "sheep" or sp == "pig" or sp == "chicken":
		return sp
	return str(GuData.SPEC[sp].get("arch", "wolf"))


static func _ss_of(sp: String) -> float:
	if not GuData.SPEC.has(sp):
		return 1.0
	return float(GuData.SPEC[sp].get("ss", 1.0))


## Aufträge: je Bild einer, das Ergebnis wird erst am Ende eingetragen (kein halbfertiger Satz).
static func _queue(sp: String, front: bool) -> void:
	var arch: String = _arch_of(sp)
	if SKIP.has(arch):
		_sets[sp] = {}
		return
	var res: Dictionary = {"walk": [], "white": [], "fly": [], "fwhite": []}
	var jobs: Array[Callable] = []
	var nwalk: int = WALK + 1
	for f: int in range(nwalk):
		jobs.append(func() -> void:
			var e: Array = make(sp, f, false)
			(res["walk"] as Array).append(e[0])
			(res["white"] as Array).append(e[1])
			res["foot"] = e[2]
			res["px"] = e[3])
	if FLYERS.has(arch) or (GuData.SPEC.has(sp) and GuData.SPEC[sp].get("wings", false)):
		for f2: int in range(WALK):
			jobs.append(func() -> void:
				var e2: Array = make(sp, f2, true)
				(res["fly"] as Array).append(e2[0])
				(res["fwhite"] as Array).append(e2[1]))
	jobs.append(func() -> void:
		_sets[sp] = res)
	if front:
		for i: int in range(jobs.size() - 1, -1, -1):
			Sprites._hd_jobs.push_front(jobs[i])
	else:
		Sprites._hd_jobs.append_array(jobs)


## Ein Bild einer Art erzeugen: [Textur, weiße Silhouette, Fußpunkt (Pixel), Einheiten je Pixel].
static func make(sp: String, f: int, fly: bool) -> Array:
	var img: Image = make_image(sp, f, fly)
	var foot: Vector2 = img.get_meta("foot")
	var px: float = img.get_meta("px")
	var wh: Image = _white(img)
	img.generate_mipmaps()
	wh.generate_mipmaps()
	return [ImageTexture.create_from_image(img), ImageTexture.create_from_image(wh), foot, px]


static func make_image(sp: String, f: int, fly: bool) -> Image:
	var arch: String = _arch_of(sp)
	var ss: float = _ss_of(sp)
	var b: Array = _bounds(arch)
	var kk: float = K1 * ss
	var q: Beasts = Beasts.new(b[0], b[1], b[2], b[3], kk)
	q._paint(sp, arch, f, fly)
	var cols: Array = _pal(sp)
	var oc: Color = Color(0.09, 0.07, 0.08).lerp(cols[0] as Color, 0.18)
	Sprites._hd_outline(q.im, oc)
	if arch == "whale":
		q._whale_water(f)
	elif not fly:
		q._shadow()
	q.im.set_meta("foot", Vector2(-q.ux0 * q.k, -q.uy0 * q.k))
	# ein Sprite-Pixel = ss / k = 0,5 Figur-Einheiten (große Bestien: mehr Pixel, gleiche Pixelgröße)
	q.im.set_meta("px", ss / q.k)
	return q.im


## Zeichenfläche je Körperbau in Einheiten: [x0, y0, x1, y1]
static func _bounds(arch: String) -> Array:
	match arch:
		"deer":
			return [-4.0, -9.0, 4.5, 1.0]
		"crane":
			return [-5.5, -9.5, 5.5, 1.0]
		"monkey":
			return [-4.5, -7.0, 3.5, 1.0]
		"croc":
			return [-8.0, -4.5, 6.5, 1.0]
		"spider":
			return [-4.5, -5.5, 4.5, 1.0]
		"whale":
			return [-8.0, -6.5, 6.5, 1.0]
		"eagle", "bat":
			return [-6.0, -10.0, 6.0, 1.0]
		"dragon":
			return [-8.5, -9.0, 7.0, 1.0]
		"turtle":
			return [-5.0, -6.5, 5.5, 1.0]
		"bear":
			return [-6.5, -11.0, 6.0, 1.0]
		"behemoth", "horned", "ancient":
			return [-6.0, -9.5, 6.0, 1.0]
		"sheep", "pig", "chicken":
			return [-3.0, -5.0, 3.5, 1.0]
	return [-5.5, -7.5, 5.5, 1.0]


static func _pal(sp: String) -> Array:
	match sp:
		"deer":
			return [Color("#b47c48"), Color("#ecd8b4"), Color("#5a3a22")]
		"crane":
			return [Color("#f2f2ee"), Color("#ffffff"), Color("#1e1e22")]
		"ancient":
			return [Color("#6a2026"), Color("#9a3a3a"), Color("#e6d6ae")]
		"sheep":
			return [Color("#f2f0e8"), Color("#ffffff"), Color("#3a3230")]
		"pig":
			return [Color("#eaa0a0"), Color("#f8c8c4"), Color("#b86a6a")]
		"chicken":
			return [Color("#f8f4ec"), Color("#ffffff"), Color("#e03a2a")]
	return Sprites._pal(sp)


## Fünfstufige Rampe: tief, dunkel, Grund, hell, Glanz (Schatten leicht kühl, Licht leicht warm).
static func ramp(c: Color) -> Array:
	var cool: Color = Color(0.12, 0.08, 0.26)
	var warm: Color = Color(1.0, 0.95, 0.78)
	return [c.darkened(0.5).lerp(cool, 0.2), c.darkened(0.25).lerp(cool, 0.1), c, c.lightened(0.17).lerp(warm, 0.08), c.lightened(0.36).lerp(warm, 0.16)]


static func _white(src: Image) -> Image:
	var d: PackedByteArray = src.get_data()
	var n: int = d.size()
	var i: int = 0
	while i < n:
		if d[i + 3] > 200:
			d[i] = 255
			d[i + 1] = 255
			d[i + 2] = 255
			d[i + 3] = 255
		else:
			d[i + 3] = 0
		i += 4
	return Image.create_from_data(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8, d)


# ---------------- Malwerkzeug (Einheiten-Koordinaten) ----------------

func _lit(nx: float, ny: float) -> int:
	var nz: float = sqrt(maxf(0.0, 1.0 - nx * nx - ny * ny))
	var s: float = -0.45 * nx - 0.65 * ny + 0.62 * nz
	if s > 0.93:
		return 4
	if s > 0.68:
		return 3
	if s > 0.2:
		return 2
	if s > -0.22:
		return 1
	return 0


func _px0(x: float) -> int:
	return clampi(floori((x - ux0) * k), 0, w - 1)


func _py0(y: float) -> int:
	return clampi(floori((y - uy0) * k), 0, h - 1)


## Schattierte Ellipse. sep: dunkle Trennkante unten rechts, wo sie über anderen Teilen liegt.
## ymax: nichts unterhalb (z. B. Panzerkante); flat < 1 schwächt die Wölbung.
func ell(cx: float, cy: float, rx: float, ry: float, rmp: Array, sep: bool = true, flat: float = 1.0, ymax: float = 999.0, clip: bool = false) -> void:
	var x0: int = _px0(cx - rx)
	var x1: int = _px0(cx + rx)
	var y0: int = _py0(cy - ry)
	var y1: int = _py0(minf(cy + ry, ymax))
	var ex: float = 1.0 / (k * rx)
	var ey: float = 1.0 / (k * ry)
	for py: int in range(y0, y1 + 1):
		var uy: float = uy0 + (py + 0.5) / k
		if uy > ymax:
			continue
		var ny: float = (uy - cy) / ry
		if absf(ny) > 1.0:
			continue
		for px: int in range(x0, x1 + 1):
			var ux: float = ux0 + (px + 0.5) / k
			var nx: float = (ux - cx) / rx
			var d2: float = nx * nx + ny * ny
			if d2 > 1.0:
				continue
			if clip and im.get_pixel(px, py).a < 0.5:
				continue
			var li: int = _lit(nx * flat, ny * flat)
			if sep and li <= 2:
				var xo: float = nx + ex
				var yo: float = ny + ey
				if (xo * xo + ny * ny > 1.0 and px + 1 < w and im.get_pixel(px + 1, py).a > 0.5) or (nx * nx + yo * yo > 1.0 and py + 1 < h and im.get_pixel(px, py + 1).a > 0.5):
					li = 0
			im.set_pixel(px, py, rmp[li])


## Schattierte Kapsel (Beine, Hälse, Schwänze): Radius von r0 nach r1.
func cap(ax: float, ay: float, bx: float, by: float, r0: float, r1: float, rmp: Array, sep: bool = true, clip: bool = false) -> void:
	var rm: float = maxf(r0, r1)
	var x0: int = _px0(minf(ax, bx) - rm)
	var x1: int = _px0(maxf(ax, bx) + rm)
	var y0: int = _py0(minf(ay, by) - rm)
	var y1: int = _py0(maxf(ay, by) + rm)
	var dx: float = bx - ax
	var dy: float = by - ay
	var ll: float = maxf(1e-5, dx * dx + dy * dy)
	for py: int in range(y0, y1 + 1):
		var uy: float = uy0 + (py + 0.5) / k
		for px: int in range(x0, x1 + 1):
			var ux: float = ux0 + (px + 0.5) / k
			var t: float = clampf(((ux - ax) * dx + (uy - ay) * dy) / ll, 0.0, 1.0)
			var r: float = lerpf(r0, r1, t)
			var nx: float = (ux - (ax + dx * t)) / r
			var ny: float = (uy - (ay + dy * t)) / r
			var d2: float = nx * nx + ny * ny
			if d2 > 1.0:
				continue
			if clip and im.get_pixel(px, py).a < 0.5:
				continue
			var li: int = _lit(nx, ny)
			if sep and li <= 2 and d2 > 0.55 and nx + ny > 0.3:
				if (px + 1 < w and im.get_pixel(px + 1, py).a > 0.5 and nx > 0.4) or (py + 1 < h and im.get_pixel(px, py + 1).a > 0.5 and ny > 0.4):
					li = 0
			im.set_pixel(px, py, rmp[li])


## Vieleck mit sanftem Verlauf (hell links oben); base = Grundstufe der Rampe.
func poly(pts: PackedVector2Array, rmp: Array, base: int = 2, clip: bool = false) -> void:
	var mn: Vector2 = pts[0]
	var mx: Vector2 = pts[0]
	for p: Vector2 in pts:
		mn = mn.min(p)
		mx = mx.max(p)
	var sz: Vector2 = (mx - mn).max(Vector2(0.01, 0.01))
	for py: int in range(_py0(mn.y), _py0(mx.y) + 1):
		var uy: float = uy0 + (py + 0.5) / k
		for px: int in range(_px0(mn.x), _px0(mx.x) + 1):
			var ux: float = ux0 + (px + 0.5) / k
			var p2: Vector2 = Vector2(ux, uy)
			if not Geometry2D.is_point_in_polygon(p2, pts):
				continue
			if clip and im.get_pixel(px, py).a < 0.5:
				continue
			var g: float = ((ux - mn.x) / sz.x + (uy - mn.y) / sz.y) * 0.5
			var li: int = clampi(base + (1 if g < 0.28 else (-1 if g > 0.78 else 0)), 0, 4)
			im.set_pixel(px, py, rmp[li])


## Einzelner Pixel (Augen, Nasen) – n × n Pixel.
func dot(x: float, y: float, c: Color, n: int = 1) -> void:
	var px: int = floori((x - ux0) * k)
	var py: int = floori((y - uy0) * k)
	for yy: int in range(n):
		for xx: int in range(n):
			if px + xx >= 0 and py + yy >= 0 and px + xx < w and py + yy < h:
				im.set_pixel(px + xx, py + yy, c)


## Pixel-Linie (Geweihe, Schnurrhaare, Streifen).
func line(ax: float, ay: float, bx: float, by: float, c: Color, clip: bool = false) -> void:
	var n: int = maxi(1, ceili(maxf(absf(bx - ax), absf(by - ay)) * k * 1.4))
	for i: int in range(n + 1):
		var t: float = float(i) / n
		var px: int = floori((lerpf(ax, bx, t) - ux0) * k)
		var py: int = floori((lerpf(ay, by, t) - uy0) * k)
		if px >= 0 and py >= 0 and px < w and py < h:
			if clip and im.get_pixel(px, py).a < 0.5:
				continue
			im.set_pixel(px, py, c)


## Auge: dunkle Pupille, bei großen Tieren mit Glanzpunkt; glow = leuchtendes Auge.
func eye(x: float, y: float, glow: Color = Color.TRANSPARENT) -> void:
	var n: int = 1 if k < 4.0 else 2
	if glow.a > 0.0:
		dot(x, y, glow, n)
		if k >= 4.0:
			dot(x + 1.0 / k, y, glow.lightened(0.5), 1)
		return
	dot(x, y, Color("#141012"), n)
	if k >= 3.6:
		dot(x, y, Color(1, 1, 1, 0.85), 1)


## Bein von der Hüfte zum Boden mit Knie; ph = Laufphase (NAN = stehen), amp Schrittweite.
func leg(hx: float, hy: float, ph: float, amp: float, rmp: Array, r0: float, r1: float, hoof: Color = Color.TRANSPARENT, bend: float = 0.25) -> void:
	var sw: float = 0.0
	var lift: float = 0.0
	if not is_nan(ph):
		sw = sin(ph) * amp
		lift = maxf(0.0, cos(ph)) * amp * 0.5
	var fx: float = hx + sw
	var fy: float = -r1 - lift
	var kx: float = hx + sw * 0.45 + bend
	var ky: float = (hy + fy) * 0.5
	cap(hx, hy, kx, ky, r0, (r0 + r1) * 0.55, rmp, false)
	cap(kx, ky, fx, fy, (r0 + r1) * 0.5, r1, rmp, false)
	if hoof.a > 0.0:
		ell(fx + r1 * 0.15, fy + r1 * 0.35, r1 * 1.05, r1 * 0.7, ramp(hoof), false)


func _shadow() -> void:
	# weicher Bodenschatten unter den Füßen (nur auf leere Pixel)
	var cx: float = 0.0
	var rx: float = (ux0 * -0.55)
	var ry: float = 0.55
	for py: int in range(_py0(-ry), _py0(ry) + 1):
		var uy: float = uy0 + (py + 0.5) / k
		for px: int in range(_px0(cx - rx), _px0(cx + rx) + 1):
			var ux: float = ux0 + (px + 0.5) / k
			var nx: float = (ux - cx) / rx
			var ny: float = uy / ry
			if nx * nx + ny * ny <= 1.0 and im.get_pixel(px, py).a < 0.1:
				im.set_pixel(px, py, Color(0.03, 0.08, 0.03, 0.3))


func _crown(gold: Color) -> void:
	if crown_at == Vector2.INF:
		return
	var cx: float = crown_at.x
	var cy: float = crown_at.y
	var g: Array = ramp(gold)
	poly(PackedVector2Array([Vector2(cx - 1.0, cy), Vector2(cx - 1.0, cy - 1.1), Vector2(cx - 0.55, cy - 0.55), Vector2(cx, cy - 1.35), Vector2(cx + 0.55, cy - 0.55), Vector2(cx + 1.0, cy - 1.1), Vector2(cx + 1.0, cy)]), g, 3)
	dot(cx - 0.05, cy - 0.5, Color("#e8303a"))


# ---------------- Körperbau ----------------

func _paint(sp: String, arch: String, f: int, fly: bool) -> void:
	var S: Dictionary = GuData.SPEC.get(sp, {})
	var cols: Array = _pal(sp)
	var b: Color = cols[0]
	var l: Color = cols[1]
	var d: Color = cols[2]
	var stand: bool = f >= WALK
	var ph: float = NAN if stand else f * TAU / WALK
	var bob: float = 0.0 if stand else (-0.22 if f % 2 == 1 else 0.0)
	match arch:
		"wolf":
			_wolf(S, sp, b, l, d, ph, bob)
		"boar":
			_boar(b, l, d, ph, bob)
		"deer":
			_deer(b, l, d, ph, bob)
		"monkey":
			_monkey(b, l, d, ph, bob)
		"crane":
			_crane(b, d, ph, fly, f)
		"tiger":
			_tiger(S, b, l, d, ph, bob)
		"lion":
			_lion(b, l, d, ph, bob)
		"bear":
			_bear(S, b, l, d, ph, bob, fly, f)
		"horned":
			_horned(b, l, d, ph, bob)
		"behemoth":
			_behemoth(b, l, d, ph, bob)
		"ancient":
			_ancient(b, l, d, ph, bob)
		"croc":
			_croc(b, l, d, ph, bob)
		"spider":
			_spider(b, l, d, ph, bob, f)
		"whale":
			_whale(b, l, d, f)
		"eagle":
			_eagle(b, l, d, ph, fly, f)
		"dragon":
			_dragon(b, l, d, f)
		"turtle":
			_turtle(b, l, d, ph, bob)
		"bat":
			_bat(b, l, d, f)
		"sheep":
			_sheep(b, d, ph, bob)
		"pig":
			_pig(b, l, d, ph, bob)
		"chicken":
			_chicken(b, d, ph, bob)
	if S.get("crown", false):
		_crown(Color("#ffd23a") if sp != "bk10000" else d)


## Vierbeiner-Gangart: Trab (diagonale Paare gleichzeitig).
func _legs4(bx: float, fx: float, hy: float, ph: float, amp: float, rn: Array, rf: Array, r0: float, r1: float, hoof: Color, far: bool) -> void:
	var p2: float = ph + PI if not is_nan(ph) else NAN
	if far:
		leg(bx + 0.35, hy, p2, amp, rf, r0, r1, hoof.darkened(0.2) if hoof.a > 0.0 else hoof)
		leg(fx + 0.35, hy, ph, amp, rf, r0, r1, hoof.darkened(0.2) if hoof.a > 0.0 else hoof, -0.15)
	else:
		leg(bx, hy, ph, amp, rn, r0, r1, hoof)
		leg(fx, hy, p2, amp, rn, r0, r1, hoof, -0.15)


func _wolf(S: Dictionary, sp: String, b: Color, l: Color, d: Color, ph: float, bob: float) -> void:
	var rb: Array = ramp(b)
	var rl: Array = ramp(l)
	var rd: Array = ramp(d)
	var rf: Array = ramp(b.darkened(0.25))
	var stars: bool = S.has("stars")
	var wag: float = 0.0 if is_nan(ph) else sin(ph) * 0.35
	_legs4(-1.7, 1.5, -2.6, ph, 0.75, rb, rf, 0.42, 0.3, Color.TRANSPARENT, true)
	# buschiger Schwanz
	cap(-2.5, -3.3 + bob, -4.3, -2.3 + bob + wag, 0.6, 0.38, rb)
	cap(-3.9, -2.5 + bob + wag, -4.5, -2.1 + bob + wag, 0.36, 0.25, rl, false)
	ell(-0.3, -3.0 + bob, 2.5, 1.05, rb)
	ell(1.4, -3.1 + bob, 1.25, 1.2, rb)
	ell(-0.2, -2.35 + bob, 1.9, 0.42, rl, false, 0.6, 999.0, true)
	if not stars:
		ell(-0.5, -3.75 + bob, 1.9, 0.38, rd, false, 0.6, 999.0, true)
	_legs4(-1.7, 1.5, -2.6, ph, 0.75, rb, rf, 0.42, 0.3, Color.TRANSPARENT, false)
	cap(1.8, -3.4 + bob, 2.6, -4.2 + bob, 0.95, 0.75, rb)
	ell(3.0, -4.35 + bob, 1.05, 0.85, rb)
	cap(3.5, -4.05 + bob, 4.6, -3.85 + bob, 0.5, 0.36, rb)
	cap(3.6, -3.7 + bob, 4.4, -3.6 + bob, 0.28, 0.22, rl, false)
	poly(PackedVector2Array([Vector2(2.35, -4.9 + bob), Vector2(2.65, -6.1 + bob), Vector2(3.2, -4.95 + bob)]), rb, 2)
	poly(PackedVector2Array([Vector2(2.6, -5.0 + bob), Vector2(2.7, -5.6 + bob), Vector2(2.95, -5.0 + bob)]), rd, 1)
	dot(4.75, -4.05 + bob, Color("#141012"), 1 if k < 4.0 else 2)
	var glow: Color = Color("#ffdf4a") if (S.get("crown", false) or sp == "lightning_wolf" or stars) else Color.TRANSPARENT
	eye(3.3, -4.55 + bob, glow)
	if S.get("shell", false):
		for i: int in range(4):
			ell(-1.9 + i * 1.15, -3.75 + bob, 0.7, 0.5, rd, true)
	if stars:
		for i: int in range(6):
			dot(-2.0 + i * 0.75, -3.3 + bob + (i % 2) * 0.55, l.lightened(0.4), 1 if k < 5.0 else 2)
	if sp == "lightning_wolf":
		line(-2.0, -3.9 + bob, -1.4, -3.2 + bob, d, true)
		line(-1.4, -3.2 + bob, -0.9, -3.8 + bob, d, true)
		line(-0.4, -3.9 + bob, 0.2, -3.2 + bob, d, true)
		line(0.2, -3.2 + bob, 0.7, -3.8 + bob, d, true)
	crown_at = Vector2(2.9, -5.25 + bob)


func _boar(b: Color, l: Color, d: Color, ph: float, bob: float) -> void:
	var rb: Array = ramp(b)
	var rl: Array = ramp(l)
	var rf: Array = ramp(b.darkened(0.25))
	var hoof: Color = Color("#2a2020")
	_legs4(-1.6, 1.3, -1.9, ph, 0.55, rb, rf, 0.45, 0.32, hoof, true)
	cap(-2.6, -2.9 + bob, -3.2, -2.4 + bob, 0.22, 0.14, rb, false)
	ell(-0.4, -2.65 + bob, 2.5, 1.3, rb)
	ell(1.0, -3.0 + bob, 1.55, 1.45, rb)
	# Borstenkamm
	for i: int in range(6):
		var x: float = -1.8 + i * 0.6
		poly(PackedVector2Array([Vector2(x - 0.35, -3.6 + bob - (0.3 if i > 2 else 0.0)), Vector2(x, -4.5 + bob - (0.3 if i > 2 else 0.0)), Vector2(x + 0.35, -3.6 + bob - (0.3 if i > 2 else 0.0))]), rl, 1)
	_legs4(-1.6, 1.3, -1.9, ph, 0.55, rb, rf, 0.45, 0.32, hoof, false)
	ell(2.5, -2.6 + bob, 1.15, 1.0, rb)
	cap(3.1, -2.4 + bob, 3.9, -2.1 + bob, 0.6, 0.5, rb)
	ell(4.15, -2.1 + bob, 0.25, 0.45, ramp(Color("#c08a7a")), false)
	poly(PackedVector2Array([Vector2(2.0, -3.3 + bob), Vector2(2.2, -4.2 + bob), Vector2(2.7, -3.4 + bob)]), rb, 2)
	cap(3.4, -1.8 + bob, 3.85, -2.75 + bob, 0.2, 0.13, ramp(Color("#f0e6d0")), false)
	eye(2.85, -2.85 + bob)
	crown_at = Vector2(2.4, -3.55 + bob)


func _deer(b: Color, l: Color, d: Color, ph: float, bob: float) -> void:
	var rb: Array = ramp(b)
	var rl: Array = ramp(l)
	var rf: Array = ramp(b.darkened(0.25))
	var hoof: Color = Color("#2e2018")
	_legs4(-1.6, 1.3, -3.0, ph, 0.8, rb, rf, 0.36, 0.2, hoof, true)
	ell(-0.2, -3.45 + bob, 2.2, 0.95, rb)
	ell(1.0, -3.55 + bob, 1.1, 1.0, rb)
	ell(-0.2, -2.85 + bob, 1.6, 0.32, rl, false, 0.6, 999.0, true)
	for i: int in range(4):
		dot(-1.4 + i * 0.75, -3.75 + bob + (i % 2) * 0.35, l.lightened(0.2))
	ell(-2.3, -3.8 + bob, 0.38, 0.45, rl, false)
	_legs4(-1.6, 1.3, -3.0, ph, 0.8, rb, rf, 0.36, 0.2, hoof, false)
	cap(1.5, -3.8 + bob, 2.3, -5.5 + bob, 0.6, 0.42, rb)
	ell(2.6, -5.75 + bob, 0.75, 0.55, rb)
	cap(2.9, -5.65 + bob, 3.65, -5.35 + bob, 0.38, 0.27, rb)
	dot(3.75, -5.45 + bob, Color("#1a1210"))
	poly(PackedVector2Array([Vector2(2.0, -6.0 + bob), Vector2(1.5, -6.6 + bob), Vector2(2.3, -6.2 + bob)]), rb, 2)
	var ac: Color = Color("#e8dcb8")
	line(2.4, -6.2 + bob, 2.1, -8.0 + bob, ac)
	line(2.2, -7.2 + bob, 1.6, -7.7 + bob, ac)
	line(2.15, -7.7 + bob, 2.6, -8.4 + bob, ac)
	line(2.7, -6.2 + bob, 2.9, -7.6 + bob, ac.darkened(0.2))
	eye(2.75, -5.9 + bob)


func _monkey(b: Color, l: Color, d: Color, ph: float, bob: float) -> void:
	var rb: Array = ramp(b)
	var rd: Array = ramp(d)
	var rf: Array = ramp(b.darkened(0.25))
	var sw: float = 0.0 if is_nan(ph) else sin(ph) * 0.5
	# Ringelschwanz
	cap(-1.0, -2.2 + bob, -2.4, -2.8 + bob, 0.3, 0.26, rb, false)
	cap(-2.4, -2.8 + bob, -3.0, -4.0 + bob, 0.26, 0.24, rb, false)
	cap(-3.0, -4.0 + bob, -2.5, -4.7 + bob, 0.24, 0.2, rb, false)
	leg(-0.6, -2.0 + bob, ph, 0.5, rf, 0.4, 0.3)
	cap(0.4, -3.5 + bob, 1.3 - sw, -0.3, 0.32, 0.26, rf, false)
	ell(-0.1, -2.75 + bob, 1.3, 1.45, rb)
	ell(0.3, -2.6 + bob, 0.7, 0.9, ramp(l), false, 0.6, 999.0, true)
	leg(0.0, -1.8 + bob, ph + PI if not is_nan(ph) else NAN, 0.5, rb, 0.42, 0.3)
	ell(0.65, -4.75 + bob, 1.05, 0.95, rb)
	ell(-0.25, -4.8 + bob, 0.38, 0.4, rd, false)
	ell(1.0, -4.65 + bob, 0.62, 0.62, rd, false)
	cap(0.6, -3.6 + bob, 1.5 + sw, -0.3, 0.32, 0.26, rb, false)
	eye(1.2, -4.95 + bob)
	dot(1.55, -4.4 + bob, d.darkened(0.5))
	crown_at = Vector2(0.6, -5.6 + bob)


func _crane(b: Color, d: Color, ph: float, fly: bool, f: int) -> void:
	var rb: Array = ramp(b)
	var rd: Array = ramp(d)
	var lg: Array = ramp(Color("#3a3a40"))
	var beak: Array = ramp(Color("#c8b060"))
	if fly:
		var fl: float = FLAP[f % 4]
		_feather_wing(-0.4, -5.0, fl, 4.4, ramp(b.darkened(0.14)), true, rd)
		cap(-1.6, -4.9, -4.6, -4.4, 0.12, 0.1, lg, false)
		ell(-0.6, -5.0, 1.9, 0.7, rb)
		poly(PackedVector2Array([Vector2(-2.4, -5.25), Vector2(-3.4, -5.0), Vector2(-2.3, -4.65)]), rd, 2)
		cap(1.0, -5.2, 3.2, -5.7, 0.3, 0.24, rb, false)
		ell(3.5, -5.75, 0.45, 0.36, rb)
		dot(3.45, -6.1, Color("#d8302a"), 2 if k >= 4.0 else 1)
		cap(3.8, -5.7, 5.0, -5.6, 0.14, 0.08, beak, false)
		eye(3.6, -5.85)
		_feather_wing(0.0, -5.1, fl, 4.6, rb, false, rd)
		return
	var p2: float = ph + PI if not is_nan(ph) else NAN
	leg(-0.2, -3.6, p2, 0.7, lg, 0.14, 0.12, Color.TRANSPARENT, 0.3)
	ell(-0.6, -4.3, 1.8, 0.95, rb)
	poly(PackedVector2Array([Vector2(-1.9, -4.7), Vector2(-3.1, -4.0), Vector2(-2.6, -3.6), Vector2(-1.6, -3.7)]), rd, 2)
	ell(-0.6, -4.4, 1.1, 0.55, ramp(b.darkened(0.08)), false, 0.5, 999.0, true)
	leg(-0.5, -3.6, ph, 0.7, lg, 0.15, 0.12, Color.TRANSPARENT, 0.3)
	cap(0.8, -4.6, 1.3, -6.2, 0.38, 0.3, rb)
	cap(1.3, -6.2, 1.0, -7.0, 0.3, 0.28, rb, false)
	ell(1.25, -7.25, 0.52, 0.42, rb)
	dot(1.0, -7.75, Color("#d8302a"), 2 if k >= 4.0 else 1)
	cap(1.6, -7.2, 2.95, -7.0, 0.16, 0.09, beak, false)
	eye(1.4, -7.35)


func _tiger(S: Dictionary, b: Color, l: Color, d: Color, ph: float, bob: float) -> void:
	var rb: Array = ramp(b)
	var rl: Array = ramp(l)
	var rf: Array = ramp(b.darkened(0.25))
	var spots: bool = S.get("spots", false)
	var wag: float = 0.0 if is_nan(ph) else sin(ph) * 0.3
	_legs4(-1.9, 1.6, -2.6, ph, 0.8, rb, rf, 0.5, 0.36, Color.TRANSPARENT, true)
	cap(-2.8, -3.2 + bob, -4.4, -3.9 + bob + wag, 0.36, 0.28, rb)
	cap(-4.4, -3.9 + bob + wag, -4.9, -5.0 + bob + wag, 0.28, 0.24, rb, false)
	ell(-0.4, -3.05 + bob, 2.75, 1.1, rb)
	ell(1.4, -3.15 + bob, 1.3, 1.2, rb)
	ell(-0.3, -2.4 + bob, 2.1, 0.42, rl, false, 0.6, 999.0, true)
	if spots:
		for i: int in range(7):
			var sx: float = -2.4 + i * 0.75
			var sy: float = -3.5 + bob + (i % 2) * 0.55
			ell(sx, sy, 0.26, 0.22, ramp(d), false, 0.3, 999.0, true)
			dot(sx, sy, l)
	else:
		for i: int in range(5):
			var sx2: float = -2.4 + i * 0.95
			cap(sx2, -4.1 + bob, sx2 + 0.35, -2.85 + bob, 0.2, 0.1, ramp(d), false, true)
	_legs4(-1.9, 1.6, -2.6, ph, 0.8, rb, rf, 0.5, 0.36, Color.TRANSPARENT, false)
	ell(2.9, -4.15 + bob, 1.15, 1.0, rb)
	ell(3.6, -3.75 + bob, 0.65, 0.5, rl, false)
	ell(2.5, -5.05 + bob, 0.36, 0.34, rb, false)
	ell(3.3, -5.1 + bob, 0.34, 0.32, rb, false)
	if not spots:
		line(2.4, -4.6 + bob, 2.8, -4.4 + bob, d, true)
		line(2.3, -4.1 + bob, 2.7, -4.0 + bob, d, true)
	dot(4.15, -3.95 + bob, Color("#2a1a18"), 1 if k < 4.0 else 2)
	eye(3.35, -4.35 + bob, Color("#ffe04a"))
	crown_at = Vector2(2.9, -5.2 + bob)


func _lion(b: Color, l: Color, d: Color, ph: float, bob: float) -> void:
	var rb: Array = ramp(b)
	var rd: Array = ramp(d)
	var rf: Array = ramp(b.darkened(0.25))
	var wag: float = 0.0 if is_nan(ph) else sin(ph) * 0.3
	_legs4(-1.9, 1.5, -2.6, ph, 0.75, rb, rf, 0.5, 0.36, Color.TRANSPARENT, true)
	cap(-2.8, -3.2 + bob, -4.3, -2.6 + bob + wag, 0.3, 0.22, rb)
	ell(-4.45, -2.5 + bob + wag, 0.42, 0.38, rd, false)
	ell(-0.4, -3.05 + bob, 2.7, 1.1, rb)
	ell(-0.3, -2.4 + bob, 2.0, 0.4, ramp(b.lightened(0.2)), false, 0.6, 999.0, true)
	_legs4(-1.9, 1.5, -2.6, ph, 0.75, rb, rf, 0.5, 0.36, Color.TRANSPARENT, false)
	# Mähne in Zotteln
	ell(1.9, -4.0 + bob, 1.75, 1.85, rd)
	for i: int in range(7):
		var a: float = PI * 0.55 + i * 0.36
		ell(1.9 + cos(a) * 1.7, -4.0 + bob - sin(a) * 1.75, 0.5, 0.5, rd, false)
	ell(2.85, -4.0 + bob, 1.0, 0.9, rb)
	cap(3.3, -3.7 + bob, 3.9, -3.55 + bob, 0.48, 0.4, ramp(b.lightened(0.15)), false)
	dot(4.05, -3.8 + bob, Color("#2a1a18"), 1 if k < 4.0 else 2)
	eye(3.25, -4.25 + bob, l)
	crown_at = Vector2(2.6, -5.6 + bob)


func _bear(S: Dictionary, b: Color, l: Color, d: Color, ph: float, bob: float, fly: bool, f: int) -> void:
	var rb: Array = ramp(b)
	var rl: Array = ramp(l)
	var rf: Array = ramp(b.darkened(0.25))
	var wings: bool = S.get("wings", false)
	var fl: float = FLAP[f % 4] if fly else 0.35
	if fly:
		ph = NAN
		bob = 0.0
	var wc: Array = ramp(d)
	if wings:
		_feather_wing(-0.6, -4.6 + bob, fl, 4.6, ramp(d.darkened(0.18)), true)
	_legs4(-2.1, 1.5, -2.6, ph, 0.6, rb, rf, 0.72, 0.52, Color.TRANSPARENT, true)
	ell(-0.4, -3.35 + bob, 3.0, 1.65, rb)
	ell(1.0, -3.9 + bob, 1.75, 1.55, rb)
	ell(-0.3, -2.4 + bob, 2.2, 0.5, ramp(b.lightened(0.12)), false, 0.6, 999.0, true)
	_legs4(-2.1, 1.5, -2.6, ph, 0.6, rb, rf, 0.72, 0.52, Color.TRANSPARENT, false)
	ell(3.0, -4.05 + bob, 1.2, 1.05, rb)
	ell(2.45, -5.0 + bob, 0.42, 0.4, rb, false)
	ell(2.5, -4.95 + bob, 0.2, 0.2, rl, false)
	cap(3.6, -3.75 + bob, 4.3, -3.6 + bob, 0.55, 0.45, rl, false)
	dot(4.55, -3.8 + bob, Color("#1a1210"), 1 if k < 4.0 else 2)
	eye(3.35, -4.35 + bob, Color("#ffd24a") if S.get("crown", false) else Color.TRANSPARENT)
	if wings:
		_feather_wing(-0.2, -4.8 + bob, fl, 4.8, wc, false)
	crown_at = Vector2(2.95, -5.1 + bob)


## Federschwinge in Seitenansicht: Ansatz (x, y), Spanne len, fl = Schlag (1 oben … -1 unten), far = hinterer
## Flügel (dunkler, leicht versetzt); tipc = Rampe für dunkle Schwungfedern an der Spitze (leer = keine).
func _feather_wing(x: float, y: float, fl: float, len: float, rmp: Array, far: bool, tipc: Array = []) -> void:
	var o: float = 0.5 if far else 0.0
	var rf: Vector2 = Vector2(x + 0.9 - o, y)
	var rb: Vector2 = Vector2(x - 1.1 - o, y + 0.35)
	var elbow: Vector2 = Vector2(x + 0.35 - o, y - len * 0.5 * fl)
	var tip: Vector2 = Vector2(x - len * 0.42 - o, y - len * 0.95 * fl - 0.2)
	var pts: PackedVector2Array = PackedVector2Array([rf, elbow, tip])
	# Hinterkante mit Federzacken
	var nrm: Vector2 = (rb - tip).orthogonal().normalized()
	if nrm.x > 0.0:
		nrm = -nrm
	for i: int in range(1, 5):
		var t: float = i / 5.0
		var p: Vector2 = tip.lerp(rb, t)
		pts.append(p + nrm * (0.45 if i % 2 == 1 else 0.0) * (1.0 - t * 0.5))
	pts.append(rb)
	poly(pts, rmp, 2 if far else 3)
	# Federlinien vom Arm zur Hinterkante
	for i2: int in range(1, 4):
		var t2: float = i2 / 4.0
		var a: Vector2 = elbow.lerp(tip, t2 * 0.8)
		var c: Vector2 = rb.lerp(tip, 1.0 - t2 * 0.9)
		line(a.x, a.y, a.lerp(c, 0.8).x, a.lerp(c, 0.8).y, rmp[1] as Color, true)
	# heller Vorderrand
	line(rf.x, rf.y - 0.1, elbow.x, elbow.y, rmp[4 if not far else 3] as Color, true)
	line(elbow.x, elbow.y, tip.x, tip.y, rmp[3 if not far else 2] as Color, true)
	if not tipc.is_empty():
		var q: Vector2 = tip.lerp(rb, 0.4)
		poly(PackedVector2Array([tip + Vector2(0.4, 0.0), tip, q, elbow.lerp(tip, 0.6)]), tipc, 2, true)


const FLAP: Array[float] = [1.0, 0.3, -0.75, 0.3]


func _horned(b: Color, l: Color, d: Color, ph: float, bob: float) -> void:
	var rb: Array = ramp(b)
	var rl: Array = ramp(l)
	var rd: Array = ramp(d)
	var rf: Array = ramp(b.darkened(0.25))
	_legs4(-2.0, 1.3, -2.7, ph, 0.55, rb, rf, 0.75, 0.55, Color("#1e1418"), true)
	cap(-3.0, -3.6 + bob, -4.3, -2.8 + bob, 0.4, 0.2, rb)
	ell(-0.5, -3.55 + bob, 2.9, 1.6, rb)
	ell(0.9, -4.1 + bob, 1.9, 1.75, rb)
	# Kristall-Stacheln auf dem Rücken
	for i: int in range(5):
		var x: float = -2.2 + i * 0.9
		var hh: float = 1.0 + (0.5 if i == 3 else 0.0)
		poly(PackedVector2Array([Vector2(x - 0.35, -4.6 + bob - (0.4 if i > 2 else 0.0)), Vector2(x + 0.1, -4.6 + bob - hh - (0.4 if i > 2 else 0.0)), Vector2(x + 0.4, -4.55 + bob - (0.4 if i > 2 else 0.0))]), rl, 2)
	_legs4(-2.0, 1.3, -2.7, ph, 0.55, rb, rf, 0.75, 0.55, Color("#1e1418"), false)
	ell(2.85, -3.25 + bob, 1.3, 1.15, rb)
	cap(3.4, -2.9 + bob, 4.2, -2.7 + bob, 0.65, 0.5, rb)
	# Hörner nach vorne oben
	cap(2.7, -4.1 + bob, 3.6, -5.6 + bob, 0.38, 0.22, rd)
	cap(3.6, -5.6 + bob, 4.3, -6.0 + bob, 0.22, 0.1, rd, false)
	cap(2.3, -4.0 + bob, 2.1, -5.2 + bob, 0.3, 0.14, rd)
	eye(3.4, -3.5 + bob, Color("#ffcf3a"))
	crown_at = Vector2(2.6, -4.6 + bob)


func _behemoth(b: Color, l: Color, d: Color, ph: float, bob: float) -> void:
	var rb: Array = ramp(b)
	var rd: Array = ramp(d)
	var rf: Array = ramp(b.darkened(0.25))
	_legs4(-2.2, 1.6, -3.0, ph, 0.5, rb, rf, 0.85, 0.65, Color("#120c10"), true)
	cap(-3.2, -3.9 + bob, -4.9, -2.6 + bob, 0.55, 0.25, rb)
	ell(-0.5, -3.95 + bob, 3.3, 1.95, rb)
	ell(1.1, -4.5 + bob, 2.0, 2.0, rb)
	# glühende Lavarisse
	var lc: Color = l
	line(-2.6, -4.6 + bob, -1.7, -3.6 + bob, lc, true)
	line(-1.7, -3.6 + bob, -1.9, -2.8 + bob, lc, true)
	line(-0.6, -5.2 + bob, 0.1, -4.0 + bob, lc, true)
	line(0.1, -4.0 + bob, 0.9, -3.4 + bob, lc, true)
	line(1.3, -5.6 + bob, 1.6, -4.6 + bob, lc, true)
	line(-1.0, -3.0 + bob, 0.0, -2.6 + bob, lc, true)
	for i: int in range(5):
		var x: float = -2.6 + i * 1.05
		poly(PackedVector2Array([Vector2(x - 0.4, -5.3 + bob - (0.5 if i > 2 else 0.0)), Vector2(x + 0.15, -6.6 + bob - (0.6 if i > 2 else 0.0)), Vector2(x + 0.45, -5.25 + bob - (0.5 if i > 2 else 0.0))]), rd, 2)
	_legs4(-2.2, 1.6, -3.0, ph, 0.5, rb, rf, 0.85, 0.65, Color("#120c10"), false)
	ell(3.2, -4.0 + bob, 1.5, 1.3, rb)
	cap(3.8, -3.5 + bob, 4.7, -3.3 + bob, 0.7, 0.55, rb)
	line(3.9, -3.0 + bob, 4.8, -2.9 + bob, lc)
	cap(3.0, -5.0 + bob, 4.3, -6.6 + bob, 0.42, 0.18, rd)
	cap(2.5, -5.0 + bob, 2.6, -6.4 + bob, 0.36, 0.14, rd)
	eye(3.7, -4.45 + bob, lc.lightened(0.3))
	crown_at = Vector2(3.0, -5.4 + bob)


func _ancient(b: Color, l: Color, d: Color, ph: float, bob: float) -> void:
	var rb: Array = ramp(b)
	var rl: Array = ramp(l)
	var rd: Array = ramp(d)
	var rf: Array = ramp(b.darkened(0.25))
	_legs4(-2.0, 1.5, -2.8, ph, 0.6, rb, rf, 0.75, 0.55, Color("#200a0c"), true)
	cap(-3.0, -3.7 + bob, -4.8, -2.4 + bob, 0.5, 0.2, rb)
	for i: int in range(3):
		poly(PackedVector2Array([Vector2(-3.4 - i * 0.5, -3.5 + bob + i * 0.4), Vector2(-3.6 - i * 0.5, -4.3 + bob + i * 0.4), Vector2(-3.1 - i * 0.5, -3.6 + bob + i * 0.4)]), rd, 2)
	ell(-0.4, -3.7 + bob, 3.0, 1.7, rb)
	ell(1.0, -4.2 + bob, 1.8, 1.7, rb)
	for i2: int in range(4):
		var x: float = -2.0 + i2 * 1.0
		poly(PackedVector2Array([Vector2(x - 0.4, -5.0 + bob - (0.4 if i2 > 1 else 0.0)), Vector2(x + 0.05, -6.0 + bob - (0.4 if i2 > 1 else 0.0)), Vector2(x + 0.45, -4.95 + bob - (0.4 if i2 > 1 else 0.0))]), rl, 2)
	_legs4(-2.0, 1.5, -2.8, ph, 0.6, rb, rf, 0.75, 0.55, Color("#200a0c"), false)
	ell(3.0, -3.8 + bob, 1.35, 1.15, rb)
	cap(3.5, -3.4 + bob, 4.4, -3.2 + bob, 0.6, 0.48, rb)
	for t: int in range(3):
		dot(3.7 + t * 0.3, -2.85 + bob, Color("#f0e8d8"))
	cap(2.6, -4.8 + bob, 3.2, -6.4 + bob, 0.32, 0.12, rd)
	cap(3.4, -4.8 + bob, 4.2, -6.0 + bob, 0.3, 0.12, rd)
	eye(3.5, -4.15 + bob, Color("#ffcf3a"))
	crown_at = Vector2(2.9, -5.0 + bob)


func _croc(b: Color, l: Color, d: Color, ph: float, bob: float) -> void:
	var rb: Array = ramp(b)
	var rl: Array = ramp(l)
	var rd: Array = ramp(d)
	var rf: Array = ramp(b.darkened(0.25))
	var sw: float = 0.0 if is_nan(ph) else sin(ph) * 0.35
	leg(-1.6, -1.2, ph + PI if not is_nan(ph) else NAN, 0.45, rf, 0.38, 0.3, Color.TRANSPARENT, 0.4)
	leg(1.6, -1.2, ph, 0.45, rf, 0.38, 0.3, Color.TRANSPARENT, 0.4)
	cap(-2.6, -1.5 + bob, -4.8, -1.1 + bob + sw * 0.5, 0.95, 0.55, rb)
	cap(-4.8, -1.1 + bob + sw * 0.5, -7.2, -0.8 + bob - sw, 0.55, 0.18, rb, false)
	ell(-0.2, -1.55 + bob, 2.9, 0.95, rb)
	for i: int in range(8):
		var x: float = -5.6 + i * 0.95
		dot(x, -2.35 + bob + (0.6 if x < -3.0 else 0.0) + (0.25 if x < -5.0 else 0.0), l.lightened(0.15), 1 if k < 4.0 else 2)
	ell(-0.2, -1.0 + bob, 2.4, 0.3, ramp(d), false, 0.5, 999.0, true)
	leg(-1.3, -1.2, ph, 0.45, rb, 0.4, 0.3, Color.TRANSPARENT, 0.4)
	leg(1.9, -1.2, ph + PI if not is_nan(ph) else NAN, 0.45, rb, 0.4, 0.3, Color.TRANSPARENT, 0.4)
	cap(2.3, -1.65 + bob, 5.6, -1.25 + bob, 0.8, 0.42, rb)
	cap(2.6, -1.1 + bob, 5.5, -0.95 + bob, 0.35, 0.26, rd, false)
	for t: int in range(4):
		dot(3.2 + t * 0.6, -1.3 + bob, Color("#f4f0e0"))
	ell(2.9, -2.35 + bob, 0.45, 0.38, rb, false)
	eye(3.0, -2.45 + bob, Color("#ffd23a"))
	crown_at = Vector2(2.9, -2.8 + bob)


func _spider(b: Color, l: Color, d: Color, ph: float, bob: float, f: int) -> void:
	var rb: Array = ramp(b)
	var rd: Array = ramp(d)
	var rfd: Array = ramp(d.darkened(0.3))
	# hintere Beine (4)
	for i: int in range(4):
		var hx: float = -0.6 + i * 0.55
		var s: float = (i - 1.5) * 1.2
		var o: float = 0.0 if is_nan(ph) else sin(ph + i * PI * 0.5) * 0.35
		var kx: float = hx + s * 0.9 + 0.3
		var fx: float = hx + s * 1.55 + o + 0.35
		cap(hx, -2.5 + bob, kx, -3.9 + bob, 0.17, 0.14, rfd, false)
		cap(kx, -3.9 + bob, fx, -0.15 - maxf(0.0, o) * 0.6, 0.14, 0.1, rfd, false)
	ell(-1.4, -2.7 + bob, 1.6, 1.35, rb)
	ell(-1.6, -3.0 + bob, 0.9, 0.55, ramp(l), false, 0.5, 999.0, true)
	dot(-1.9, -2.6 + bob, l.lightened(0.3), 1 if k < 4.0 else 2)
	dot(-1.1, -2.2 + bob, l.lightened(0.3), 1 if k < 4.0 else 2)
	ell(0.65, -2.45 + bob, 1.0, 0.85, rb)
	for i2: int in range(4):
		var hx2: float = -0.3 + i2 * 0.5
		var s2: float = (i2 - 1.5) * 1.3
		var o2: float = 0.0 if is_nan(ph) else sin(ph + i2 * PI * 0.5 + PI) * 0.35
		var kx2: float = hx2 + s2 * 0.9
		var fx2: float = hx2 + s2 * 1.6 + o2
		cap(hx2, -2.2 + bob, kx2, -3.7 + bob, 0.19, 0.16, rd, false)
		cap(kx2, -3.7 + bob, fx2, -0.12 - maxf(0.0, o2) * 0.6, 0.16, 0.11, rd, false)
	dot(1.3, -2.7 + bob, Color("#ff4a2a"))
	dot(1.55, -2.45 + bob, Color("#ff4a2a"))
	dot(1.2, -2.35 + bob, Color("#ff6a3a"))
	cap(1.45, -2.0 + bob, 1.7, -1.4 + bob, 0.15, 0.08, ramp(Color("#e8e0d0")), false)


func _whale(b: Color, l: Color, d: Color, f: int) -> void:
	var rb: Array = ramp(b)
	var rl: Array = ramp(l)
	var wv: float = sin(f * TAU / WALK) * 0.25
	cap(-4.6, -1.8 + wv, -6.4, -2.9 - wv, 0.7, 0.3, rb)
	poly(PackedVector2Array([Vector2(-6.4, -2.9 - wv), Vector2(-7.4, -4.0 - wv), Vector2(-6.8, -2.9 - wv), Vector2(-7.5, -2.0 - wv)]), rb, 2)
	ell(-0.4, -1.9 + wv * 0.5, 4.6, 1.75, rb)
	ell(-0.3, -1.1 + wv * 0.5, 4.0, 0.6, rl, false, 0.5, 999.0, true)
	poly(PackedVector2Array([Vector2(-1.4, -3.4 + wv * 0.5), Vector2(-2.2, -4.4 + wv * 0.5), Vector2(-0.6, -3.55 + wv * 0.5)]), rb, 1)
	for i: int in range(5):
		line(1.0 + i * 0.45, -0.9, 0.6 + i * 0.45, -0.5, d.darkened(0.1), true)
	eye(2.9, -1.9 + wv * 0.5)


## Wasserlinie (nach der Kontur): alles darunter im Wasser getönt, Schaumkrone.
func _whale_water(f: int) -> void:
	var wl: int = _py0(-0.75)
	var wc: Color = Color(0.2, 0.5, 0.8)
	for py: int in range(wl, h):
		for px: int in range(w):
			var c: Color = im.get_pixel(px, py)
			if c.a > 0.5:
				im.set_pixel(px, py, Color(c.lerp(wc, 0.6), 0.55))
	for px2: int in range(w):
		if im.get_pixel(px2, wl - 1).a > 0.5 or im.get_pixel(px2, wl).a > 0.3:
			if (px2 + f) % 3 != 0:
				im.set_pixel(px2, wl, Color(0.92, 0.97, 1.0, 0.95))


func _eagle(b: Color, l: Color, d: Color, ph: float, fly: bool, f: int) -> void:
	var rb: Array = ramp(b)
	var rl: Array = ramp(l)
	var rd: Array = ramp(d)
	var rw: Array = ramp(b.darkened(0.15))
	if fly:
		var fl: float = FLAP[f % 4]
		_feather_wing(0.2, -5.1, fl, 5.4, ramp(b.darkened(0.3)), true)
		poly(PackedVector2Array([Vector2(-1.6, -5.2), Vector2(-3.4, -5.5), Vector2(-3.3, -4.6), Vector2(-1.6, -4.7)]), rw, 2)
		ell(0.0, -5.0, 1.9, 0.8, rb)
		ell(2.0, -5.3, 0.75, 0.65, rl)
		poly(PackedVector2Array([Vector2(2.6, -5.5), Vector2(3.4, -5.2), Vector2(3.1, -4.85), Vector2(2.6, -5.0)]), rd, 2)
		eye(2.3, -5.45, Color.TRANSPARENT)
		_feather_wing(0.5, -5.2, fl, 5.6, rw, false)
		crown_at = Vector2(1.95, -5.95)
		return
	cap(-0.3, -1.4, -0.2, -0.2, 0.2, 0.16, rd, false)
	poly(PackedVector2Array([Vector2(-1.0, -2.6), Vector2(-2.6, -1.4), Vector2(-2.0, -1.0), Vector2(-0.6, -2.0)]), rw, 2)
	ell(0.0, -3.0, 1.2, 1.55, rb)
	ell(0.45, -2.9, 0.65, 1.1, ramp(b.lightened(0.12)), false, 0.5, 999.0, true)
	ell(-0.45, -3.0, 1.0, 1.25, rw, true, 0.7)
	cap(0.3, -1.4, 0.4, -0.2, 0.2, 0.16, rd, false)
	ell(0.6, -4.65, 0.8, 0.72, rl)
	poly(PackedVector2Array([Vector2(1.2, -4.95), Vector2(2.0, -4.6), Vector2(1.7, -4.2), Vector2(1.2, -4.35)]), rd, 2)
	eye(0.95, -4.85)
	crown_at = Vector2(0.55, -5.35)


func _dragon(b: Color, l: Color, d: Color, f: int) -> void:
	var rb: Array = ramp(b)
	var rl: Array = ramp(l)
	var rd: Array = ramp(d)
	var ph: float = f * TAU / WALK
	var pts: Array[Vector2] = []
	var n: int = 12
	for i: int in range(n):
		var x: float = -7.6 + i * 0.95
		pts.append(Vector2(x, -4.0 + sin(x * 0.75 + ph) * 1.1 - i * 0.08))
	# hintere Beine
	for li: int in [3, 8]:
		var p: Vector2 = pts[li]
		cap(p.x + 0.2, p.y, p.x + 0.6, p.y + 1.6, 0.26, 0.2, ramp(b.darkened(0.25)), false)
	for i2: int in range(n - 1):
		var r0: float = 0.25 + 0.75 * float(i2) / n
		var r1: float = 0.25 + 0.75 * float(i2 + 1) / n
		cap(pts[i2].x, pts[i2].y, pts[i2 + 1].x, pts[i2 + 1].y, r0, r1, rb, false)
	# Bauchschuppen und Rückenkamm
	for i3: int in range(1, n):
		var r: float = 0.25 + 0.75 * float(i3) / n
		dot(pts[i3].x, pts[i3].y + r * 0.6, l, 1 if k < 5.0 else 2)
		if i3 % 2 == 0:
			poly(PackedVector2Array([pts[i3] + Vector2(-0.35, -r * 0.85), pts[i3] + Vector2(-0.1, -r - 0.7), pts[i3] + Vector2(0.3, -r * 0.85)]), rd, 2)
	poly(PackedVector2Array([pts[0] + Vector2(0.2, -0.2), pts[0] + Vector2(-1.0, -0.9), pts[0] + Vector2(-0.6, 0.3)]), rl, 2)
	for li2: int in [2, 7]:
		var p2: Vector2 = pts[li2]
		cap(p2.x, p2.y, p2.x + 0.7, p2.y + 1.7, 0.28, 0.2, rb, false)
		dot(p2.x + 0.8, p2.y + 1.8, l)
	var hp: Vector2 = pts[n - 1] + Vector2(0.9, -0.5)
	cap(pts[n - 1].x, pts[n - 1].y, hp.x, hp.y, 1.0, 0.9, rb)
	ell(hp.x + 0.2, hp.y, 1.05, 0.85, rb)
	cap(hp.x + 0.6, hp.y + 0.1, hp.x + 2.0, hp.y + 0.35, 0.55, 0.4, rb, false)
	cap(hp.x + 0.7, hp.y + 0.55, hp.x + 1.8, hp.y + 0.8, 0.28, 0.22, rl, false)
	cap(hp.x - 0.2, hp.y - 0.6, hp.x - 1.3, hp.y - 2.0, 0.22, 0.1, rl, false)
	cap(hp.x + 0.3, hp.y - 0.7, hp.x - 0.4, hp.y - 2.2, 0.22, 0.1, rl, false)
	line(hp.x + 1.9, hp.y + 0.3, hp.x + 3.0, hp.y + 1.2 + sin(ph) * 0.3, l)
	line(hp.x + 1.8, hp.y + 0.1, hp.x + 2.9, hp.y - 0.4 + sin(ph) * 0.3, l)
	eye(hp.x + 0.6, hp.y - 0.25, Color("#ff3a2a"))
	# Flammenmähne
	for i4: int in range(4):
		var mp: Vector2 = pts[n - 2 - i4]
		poly(PackedVector2Array([mp + Vector2(-0.3, -0.7), mp + Vector2(-0.9, -1.6 - (i4 % 2) * 0.4), mp + Vector2(0.3, -0.8)]), ramp(Color("#ff8a2a")), 3)


func _turtle(b: Color, l: Color, d: Color, ph: float, bob: float) -> void:
	var rb: Array = ramp(b)
	var rl: Array = ramp(l)
	var rd: Array = ramp(d)
	var skin: Array = ramp(l.darkened(0.25))
	leg(-1.9, -1.0, ph + PI if not is_nan(ph) else NAN, 0.35, ramp(l.darkened(0.45)), 0.5, 0.42, Color.TRANSPARENT, 0.1)
	leg(1.8, -1.0, ph, 0.35, ramp(l.darkened(0.45)), 0.5, 0.42, Color.TRANSPARENT, 0.1)
	cap(-3.0, -1.2, -3.8, -0.9, 0.3, 0.15, skin, false)
	# Panzer: Kuppel mit Platten
	ell(-0.2, -1.4 + bob, 3.2, 3.0, rb, true, 1.0, -1.05 + bob)
	ell(-0.2, -1.3 + bob, 3.3, 0.4, rd, false, 0.4)
	for py: int in range(_py0(-4.4 + bob), _py0(-1.3 + bob) + 1):
		for px: int in range(_px0(-3.4), _px0(3.0) + 1):
			var c: Color = im.get_pixel(px, py)
			if c.a < 0.5:
				continue
			var ux: float = ux0 + (px + 0.5) / k
			var uy: float = uy0 + (py + 0.5) / k
			var gx: float = fposmod(ux + (0.55 if int(floorf(uy / 1.1)) % 2 == 0 else 0.0), 1.1)
			var gy: float = fposmod(uy, 1.1)
			if gx < 1.0 / k or gy < 1.0 / k:
				im.set_pixel(px, py, (rd[1] as Color))
			elif gx < 2.0 / k and gy > 0.3:
				im.set_pixel(px, py, c.lightened(0.08))
	leg(-1.4, -1.0, ph, 0.35, skin, 0.52, 0.44, Color.TRANSPARENT, 0.1)
	leg(2.3, -1.0, ph + PI if not is_nan(ph) else NAN, 0.35, skin, 0.52, 0.44, Color.TRANSPARENT, 0.1)
	cap(2.8, -1.5 + bob, 3.8, -2.2 + bob, 0.6, 0.55, skin)
	ell(4.2, -2.3 + bob, 0.85, 0.7, skin)
	eye(4.5, -2.5 + bob)
	crown_at = Vector2(4.1, -3.0 + bob)


func _bat(b: Color, l: Color, d: Color, f: int) -> void:
	var rb: Array = ramp(b)
	var rd: Array = ramp(d)
	var fl: float = sin(f * TAU / WALK)
	var y0: float = -5.0
	for side: int in [-1, 1]:
		var tip: Vector2 = Vector2(side * 5.4, y0 - 2.4 * fl - 0.4)
		var mid: Vector2 = Vector2(side * 2.8, y0 - 1.6 * fl - 0.8)
		var pts: PackedVector2Array = PackedVector2Array([Vector2(side * 0.5, y0 - 0.6), mid, tip, Vector2(side * 4.4, y0 + 0.6 - fl * 1.6), Vector2(side * 3.4, y0 + 0.1 - fl * 1.0), Vector2(side * 2.4, y0 + 0.9 - fl * 0.8), Vector2(side * 1.4, y0 + 0.4 - fl * 0.4), Vector2(side * 0.5, y0 + 0.8)])
		poly(pts, rd, 2 if side < 0 else 3)
		line(side * 0.5, y0 - 0.6, mid.x, mid.y, b.darkened(0.2))
		line(mid.x, mid.y, tip.x, tip.y, b.darkened(0.2))
		line(mid.x, mid.y, side * 3.4, y0 + 0.1 - fl * 1.0, b.darkened(0.2))
	ell(0.0, y0, 0.85, 1.25, rb)
	ell(0.0, y0 - 1.45, 0.7, 0.6, rb)
	poly(PackedVector2Array([Vector2(-0.6, y0 - 1.6), Vector2(-0.55, y0 - 2.6), Vector2(-0.15, y0 - 1.9)]), rb, 2)
	poly(PackedVector2Array([Vector2(0.15, y0 - 1.9), Vector2(0.55, y0 - 2.6), Vector2(0.6, y0 - 1.6)]), rb, 2)
	eye(-0.3, y0 - 1.5, l)
	eye(0.25, y0 - 1.5, l)


func _sheep(b: Color, d: Color, ph: float, bob: float) -> void:
	var rw: Array = ramp(b)
	var rd: Array = ramp(d)
	_legs4(-1.0, 0.9, -1.4, ph, 0.35, rd, ramp(d.darkened(0.2)), 0.22, 0.18, Color.TRANSPARENT, true)
	ell(-0.1, -2.1 + bob, 1.75, 1.0, rw)
	for i: int in range(5):
		ell(-1.2 + i * 0.6, -2.85 + bob + (i % 2) * 0.15, 0.55, 0.45, rw, false)
	_legs4(-1.0, 0.9, -1.4, ph, 0.35, rd, rd, 0.22, 0.18, Color.TRANSPARENT, false)
	ell(1.75, -2.4 + bob, 0.6, 0.5, rd)
	ell(1.4, -2.65 + bob, 0.3, 0.2, rd, false)
	eye(1.95, -2.55 + bob, Color("#f8f4ec"))


func _pig(b: Color, l: Color, d: Color, ph: float, bob: float) -> void:
	var rb: Array = ramp(b)
	_legs4(-1.0, 0.9, -1.3, ph, 0.3, rb, ramp(b.darkened(0.2)), 0.26, 0.2, Color.TRANSPARENT, true)
	cap(-1.8, -2.0 + bob, -2.3, -2.4 + bob, 0.14, 0.1, rb, false)
	ell(-0.1, -1.95 + bob, 1.8, 0.95, rb)
	_legs4(-1.0, 0.9, -1.3, ph, 0.3, rb, rb, 0.26, 0.2, Color.TRANSPARENT, false)
	ell(1.6, -2.05 + bob, 0.65, 0.6, rb)
	ell(2.25, -1.95 + bob, 0.2, 0.3, ramp(d), false)
	poly(PackedVector2Array([Vector2(1.2, -2.5 + bob), Vector2(1.35, -3.0 + bob), Vector2(1.6, -2.55 + bob)]), ramp(d), 2)
	eye(1.85, -2.25 + bob)


func _chicken(b: Color, d: Color, ph: float, bob: float) -> void:
	var rb: Array = ramp(b)
	var ly: Array = ramp(Color("#f0b030"))
	leg(-0.1, -0.8, ph, 0.25, ly, 0.08, 0.08)
	poly(PackedVector2Array([Vector2(-0.8, -1.6 + bob), Vector2(-1.5, -2.5 + bob), Vector2(-0.4, -1.9 + bob)]), rb, 2)
	ell(0.0, -1.35 + bob, 0.9, 0.65, rb)
	leg(0.15, -0.8, ph + PI if not is_nan(ph) else NAN, 0.25, ly, 0.08, 0.08)
	ell(0.65, -2.0 + bob, 0.42, 0.42, rb)
	dot(0.55, -2.55 + bob, d, 1)
	dot(0.7, -2.5 + bob, d, 1)
	poly(PackedVector2Array([Vector2(1.0, -2.1 + bob), Vector2(1.4, -1.95 + bob), Vector2(1.0, -1.8 + bob)]), ly, 2)
	eye(0.75, -2.1 + bob)


# ---------------- Entwickler ----------------

## Bogen aller Arten (Stand, Laufbilder, Flugbilder) – `--beastsheet=<datei.png>`.
static func sheet(path: String) -> void:
	var rows: Array = []
	var keys: Array = GuData.SPEC.keys()
	keys.append_array(["sheep", "pig", "chicken"])
	var t0: int = Time.get_ticks_usec()
	var tmax: int = 0
	for sp: String in keys:
		if SKIP.has(_arch_of(sp)):
			continue
		var row: Array[Image] = []
		for f: int in [WALK, 0, 1, 2, 3]:
			var t1: int = Time.get_ticks_usec()
			row.append(make_image(sp, f, false))
			tmax = maxi(tmax, Time.get_ticks_usec() - t1)
		if FLYERS.has(_arch_of(sp)) or GuData.SPEC.get(sp, {}).get("wings", false):
			for f2: int in range(WALK):
				row.append(make_image(sp, f2, true))
		rows.append(row)
	printerr("BEASTSHEET ms %.1f, longest image ms %.1f" % [(Time.get_ticks_usec() - t0) / 1000.0, tmax / 1000.0])
	var prow: Array[Image] = []
	for pt: String in ["inherit", "fragment", "palace", "mushroom", "yitian", "crazed", "blessed", "grotto", "court", "dream"]:
		var tp: int = Time.get_ticks_usec()
		var pim: Image = Sprites.place_image_hd(pt)
		printerr("PLACE %s ms %.1f" % [pt, (Time.get_ticks_usec() - tp) / 1000.0])
		if prow.size() < 6:
			prow.append(pim)
	rows.append(prow)
	var sc: int = 3
	var W2: int = 1800
	var out: Image = Image.create_empty(W2, 4000, false, Image.FORMAT_RGBA8)
	out.fill(Color8(76, 132, 46))
	var y: int = 4
	for row: Array[Image] in rows:
		var x: int = 4
		var rh: int = 0
		for im2: Image in row:
			var big: Image = im2.duplicate()
			big.resize(im2.get_width() * sc, im2.get_height() * sc, Image.INTERPOLATE_NEAREST)
			if x + big.get_width() > W2:
				break
			out.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(x, y))
			x += big.get_width() + 4
			rh = maxi(rh, big.get_height())
		y += rh + 4
		if y > 3900:
			break
	out.crop(W2, y)
	out.save_png(path)
