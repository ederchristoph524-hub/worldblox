class_name World
extends RefCounted
## Kartendaten der Gu-Welt (eine Kachel = ein Pixel) und ihre Bilder für nah, fern und Clan-Gebiete.

## Kartengröße (aus GuData, in alloc nachgezogen – Größe ist zur Laufzeit umstellbar)
var W: int = GuData.W
var H: int = GuData.H
var N: int = GuData.N
const CHK: int = 32
## Blöcke je Zeile (W / CHK)
var CXN: int = W / CHK

var tile: PackedByteArray
var feat: PackedByteArray
var region: PackedByteArray
var hgt: PackedFloat32Array
var bmap: PackedInt32Array
var terr: PackedInt32Array
## Einflusszone: Clan-Id je herrenloser Kachel rund um Dörfer (-1 = keine), siehe update_territory
var infl: PackedInt32Array
var temp_snow: PackedByteArray
var wdist: PackedByteArray

## Benannte Orte der kanonischen Gu-Weltkarte (Modus "gu"); kind: siedlung (Bauland), berg, fluss, ort, gebiet.
## x/y in Bezugskoordinaten 0..256 (MapGu.REF); landmarks enthält sie in Kacheln der aktuellen Kartengröße.
const LANDMARKS: Array = [
	{"name": "Heavenly Court", "x": 124, "y": 126, "region": 4, "kind": "siedlung"},
	{"name": "Immortal Crane Sect", "x": 158, "y": 136, "region": 4, "kind": "siedlung"},
	{"name": "Spirit Affinity House", "x": 100, "y": 142, "region": 4, "kind": "siedlung"},
	{"name": "Gu Yue Village", "x": 78, "y": 214, "region": 1, "kind": "siedlung"},
	{"name": "Qing Mao Mountain", "x": 80, "y": 205, "region": 1, "kind": "berg"},
	{"name": "Shang Clan City", "x": 140, "y": 238, "region": 1, "kind": "siedlung"},
	{"name": "Bai Gu Mountain", "x": 176, "y": 230, "region": 1, "kind": "berg"},
	{"name": "Red Dragon River", "x": 66, "y": 222, "region": 1, "kind": "fluss"},
	{"name": "Yellow Dragon River", "x": 126, "y": 214, "region": 1, "kind": "fluss"},
	{"name": "Jade Dragon River", "x": 190, "y": 216, "region": 1, "kind": "fluss"},
	{"name": "Imperial Court Blessed Land", "x": 154, "y": 30, "region": 0, "kind": "siedlung"},
	{"name": "Lang Ya Blessed Land", "x": 104, "y": 26, "region": 0, "kind": "ort"},
	{"name": "Great Oasis", "x": 36, "y": 112, "region": 2, "kind": "siedlung"},
	{"name": "Impassable Dunes", "x": 30, "y": 168, "region": 2, "kind": "gebiet"},
]

## Lage der Orte auf der alten 256er-Gu-Karte (Spielstände bis v5, Kacheln)
const LANDMARKS_V5: Dictionary = {"Heavenly Court": [124, 130], "Immortal Crane Sect": [154, 134], "Spirit Affinity House": [110, 140],
	"Gu Yue Village": [78, 213], "Qing Mao Mountain": [80, 205], "Shang Clan City": [142, 233], "Bai Gu Mountain": [176, 230], "Red Dragon River": [62, 214],
	"Yellow Dragon River": [124, 208], "Jade Dragon River": [190, 212], "Imperial Court Blessed Land": [150, 52], "Lang Ya Blessed Land": [86, 58],
	"Great Oasis": [50, 104], "Impassable Dunes": [34, 166]}

## Leere Startwelten zum freien Bauen (ohne Regionswände, ohne benannte Orte, kaum Pflanzen).
const BLANK_MODES: PackedStringArray = ["ocean", "flat", "island", "continents"]

## Kartenart der aktuellen Welt ("gu", "random" oder eine aus BLANK_MODES) und ihre benannten Orte (nur bei "gu").
var map_mode: String = "gu"
var landmarks: Array[Dictionary] = []

var near_img: Image
var far_img: Image
var terr_img: Image
var war_img: Image  ## umkämpfte Grenzen (rot gestrichelt, pulsiert in TerrOverlay)
var fill_img: Image  ## Nahansicht: nur Gebietsflächen und Einflusszonen, ohne Kachel-Ränder
var edge_img: Image  ## Nahansicht: feine Doppel-Grenzlinien in EDGE_S-facher Auflösung
var near_tex: ImageTexture
var far_tex: ImageTexture
var terr_tex: ImageTexture
var war_tex: ImageTexture
var fill_tex: ImageTexture
var edge_tex: ImageTexture
## Auflösung der Grenzlinien-Textur je Kachel (Außenlinie, Farblinie, frei)
const EDGE_S: int = 3
var dirty: PackedByteArray
## Je Block das geänderte Rechteck (x0, y0, x1, y1 in Kacheln, x1/y1 exklusiv); x0 >= x1 = ganzer Block.
## flush_dirty zeichnet nur dieses Rechteck neu (ein gefällter Baum: ~13 × 17 statt bis zu 4 × 32 × 32 Kacheln).
var drect: PackedInt32Array
var _upl_pending: bool = false
var _upl_ms: int = 0
## Version je 32er-Block: steigt bei jedem Neuzeichnen (flush_dirty, render_all); die Nahansicht (Detail) backt danach neu.
var dver: PackedInt32Array
var water_dirty: bool = false
## Kartenebene der Gebietsanzeige: 0 Clan-Gebiete, 1 Dorf-Gebiete, 2 Regionen, 3 Einflusssphären (Mächte).
var layer: int = 0
const LAYER_NAME: PackedStringArray = ["Clan Territories", "Village Territories", "Regions", "Spheres of Influence"]
## Breite der verblassenden Einflusszone jenseits des Dorfgebiets (Kacheln)
const INF_R: int = 12
## Beschriftungspunkte nach dem letzten update_territory: Clan-Id -> Vector3(x, y, Kacheln);
## der Punkt liegt immer im eigenen Gebiet des Clans.
var terr_center: Dictionary = {}
var terr_ms: float = 0.0  ## Dauer des letzten update_territory (Entwickler)
var gen_ms: Dictionary = {}  ## Entwickler: Zeiten der letzten Generierung (ms)
var terr_phase_us: PackedInt32Array = [0, 0, 0, 0, 0, 0, 0]  ## Entwickler: Rechenzeit je Phase der letzten Gebiets-Berechnung
const REG_COL: Array[Color] = [Color("#e8e0a0"), Color("#5ac85a"), Color("#e8a040"), Color("#40a8e8"), Color("#c070e8")]


func _init() -> void:
	Sprites.init()
	_set_landmarks("gu")
	alloc()


## Bilder, Texturen und Block-Listen in der aktuellen Kartengröße anlegen. Die Textur-Objekte bleiben dieselben
## (set_image), damit Sprites in main.gd sie behalten, auch wenn sich die Größe ändert.
func _alloc_images() -> void:
	near_img = Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	far_img = Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	terr_img = Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	war_img = Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	fill_img = Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	edge_img = Image.create_empty(W * EDGE_S, H * EDGE_S, false, Image.FORMAT_RGBA8)
	if near_tex == null:
		near_tex = ImageTexture.create_from_image(near_img)
		far_tex = ImageTexture.create_from_image(far_img)
		terr_tex = ImageTexture.create_from_image(terr_img)
		war_tex = ImageTexture.create_from_image(war_img)
		fill_tex = ImageTexture.create_from_image(fill_img)
		edge_tex = ImageTexture.create_from_image(edge_img)
	else:
		near_tex.set_image(near_img)
		far_tex.set_image(far_img)
		terr_tex.set_image(terr_img)
		war_tex.set_image(war_img)
		fill_tex.set_image(fill_img)
		edge_tex.set_image(edge_img)
	dirty = PackedByteArray()
	dirty.resize(CXN * CXN)
	drect = PackedInt32Array()
	drect.resize(CXN * CXN * 4)
	dver = PackedInt32Array()
	dver.resize(CXN * CXN)
	_jphase = -1


## Kartenfelder in der aktuellen Größe (GuData.W/H) leeren; bei geänderter Größe auch Bilder und Blöcke neu anlegen.
func alloc() -> void:
	var resized: bool = near_img == null or W != GuData.W or H != GuData.H
	W = GuData.W
	H = GuData.H
	N = GuData.N
	CXN = ceili(float(W) / CHK)
	if resized:
		_alloc_images()
	_jphase = -1
	_veil = PackedInt32Array()
	tile = PackedByteArray()
	tile.resize(N)
	feat = PackedByteArray()
	feat.resize(N)
	region = PackedByteArray()
	region.resize(N)
	hgt = PackedFloat32Array()
	hgt.resize(N)
	bmap = PackedInt32Array()
	bmap.resize(N)
	bmap.fill(-1)
	terr = PackedInt32Array()
	terr.resize(N)
	terr.fill(-1)
	infl = PackedInt32Array()
	infl.resize(N)
	infl.fill(-1)
	temp_snow = PackedByteArray()
	temp_snow.resize(N)
	wdist = PackedByteArray()
	wdist.resize(N)


func region_at(x: float, y: float) -> int:
	return region[clampi(int(y), 0, H - 1) * W + clampi(int(x), 0, W - 1)]


func in_map(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < W and y < H


# ---------------- Generierung ----------------

func _noise(sd: int, freq: float, oct: int) -> FastNoiseLite:
	var n: FastNoiseLite = FastNoiseLite.new()
	n.seed = sd
	n.noise_type = FastNoiseLite.TYPE_VALUE_CUBIC
	n.frequency = freq
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves = oct
	return n


static func n01(n: FastNoiseLite, x: float, y: float) -> float:
	return clampf(n.get_noise_2d(x, y) * 0.5 + 0.5, 0.0, 1.0)


## Wasserabstand (wdist): 0 an Land, sonst Schritte (4er-Nachbarschaft) bis zum nächsten Land, höchstens 40 (sonst 255).
func compute_water() -> void:
	var wd: PackedByteArray = PackedByteArray()
	wd.resize(N)
	wd.fill(255)
	var tl: PackedByteArray = tile
	var q: PackedInt32Array = PackedInt32Array()
	q.resize(N)
	var qh: int = 0
	var qt: int = 0
	for i: int in range(N):
		if tl[i] > GuData.SHAL:
			wd[i] = 0
			q[qt] = i
			qt += 1
	var w1: int = W - 1
	var lim: int = N - W
	while qh < qt:
		var i: int = q[qh]
		qh += 1
		var d: int = wd[i]
		if d >= 40:
			continue
		var nd: int = d + 1
		var x: int = i % W
		if x > 0 and wd[i - 1] == 255:
			wd[i - 1] = nd
			q[qt] = i - 1
			qt += 1
		if x < w1 and wd[i + 1] == 255:
			wd[i + 1] = nd
			q[qt] = i + 1
			qt += 1
		if i >= W and wd[i - W] == 255:
			wd[i - W] = nd
			q[qt] = i - W
			qt += 1
		if i < lim and wd[i + W] == 255:
			wd[i + W] = nd
			q[qt] = i + W
			qt += 1
	wdist = wd


func _set_landmarks(mode: String, legacy: bool = false) -> void:
	map_mode = mode
	landmarks.clear()
	if mode == "gu":
		var k: float = W / MapGu.REF
		for l: Dictionary in LANDMARKS:
			var d: Dictionary = l.duplicate()
			d["x"] = clampi(int((float(l["x"]) + 0.5) * k), 0, W - 1)
			d["y"] = clampi(int((float(l["y"]) + 0.5) * k), 0, H - 1)
			if legacy and LANDMARKS_V5.has(l["name"]):
				d["x"] = int(LANDMARKS_V5[l["name"]][0])
				d["y"] = int(LANDMARKS_V5[l["name"]][1])
			landmarks.append(d)


## Verdickung der Regionswände (Kacheln je Seite über die zwei Grenzkacheln hinaus): 256 → 4 Kacheln breit,
## ab 448 → 6 Kacheln breit.
func wall_r() -> float:
	return 1.0 if W < 448 else 2.0


static func is_blank(mode: String) -> bool:
	return mode in BLANK_MODES


## mode "gu": kanonische Gu-Weltkarte (Form fest, Samen ändert nur Details); "random": Zufallswelt;
## "ocean", "flat", "island", "continents": leere Welt zum freien Bauen.
func generate(S: int, mode: String = "gu") -> void:
	var t0: int = Time.get_ticks_usec()
	gen_ms.clear()
	alloc()
	var open_sea: PackedByteArray = PackedByteArray()
	var blank: bool = is_blank(mode)
	if mode == "random":
		_base_random(S)
	elif blank:
		_base_blank(S, mode)
	else:
		mode = "gu"
		open_sea = MapGu.build(self, S)
	gen_ms["base"] = (Time.get_ticks_usec() - t0) / 1000.0
	_set_landmarks(mode)
	_finish(S, open_sea, blank)
	gen_ms["gen"] = (Time.get_ticks_usec() - t0) / 1000.0
	if blank:
		# Höhen passend zu den Kacheln, damit Heben/Senken und Lava sich wie gewohnt verhalten
		for i: int in range(N):
			hgt[i] = GuData.DEFH[tile[i]] + (GuData.hash2(i, 7, 5) - 0.5) * 0.06


## Grundgelände der leeren Welten: eine einzige Region (Zentralkontinent), also keine Regionswände.
## Land ist Grasland (Höhe 0,5), Wasser tiefes Meer (Höhe 0,2); Flachwasser und Strand setzt _finish.
func _base_blank(S: int, mode: String) -> void:
	region.fill(4)
	# Rauschen in Bezugsgröße 256 (gleiche Formen in jeder Kartengröße)
	var kf: float = 256.0 / W
	var nw: FastNoiseLite = _noise(S + 17, 0.035 * kf, 3)
	var nc: FastNoiseLite = _noise(S + 29, 0.011 * kf, 4)
	var cx: float = (W - 1) * 0.5
	var cy: float = (H - 1) * 0.5
	var rad: float = W * 0.22
	for y: int in range(H):
		for x: int in range(W):
			var i: int = y * W + x
			var land: bool = false
			match mode:
				"flat":
					# eine Ebene bis auf einen schmalen, leicht welligen Meeressaum
					var edge: float = minf(minf(x, W - 1 - x), minf(y, H - 1 - y)) * kf
					land = edge >= 6.0 + (n01(nw, x, y) - 0.5) * 5.0
				"island":
					# eine runde, organisch gewellte Insel in der Mitte
					var d: float = Vector2(x - cx, y - cy).length() / rad
					land = d + (n01(nw, x, y) - 0.5) * 0.55 + (n01(nc, x * 3.0, y * 3.0) - 0.5) * 0.25 < 1.0
				"continents":
					# einige große Landmassen, zum Rand hin Meer (Schwelle unten über den Landanteil)
					var e: float = minf(minf(x, W - 1 - x), minf(y, H - 1 - y)) / (W * 0.5)
					var fall: float = clampf((0.3 - e) / 0.3, 0.0, 1.0)
					hgt[i] = n01(nc, x, y) - fall * 0.45 + (n01(nw, x, y) - 0.5) * 0.12
			tile[i] = GuData.GRASS if land else GuData.DEEP
	if mode == "continents":
		# immer etwa 40 % Land, unabhängig vom Samen
		var sorted: PackedFloat32Array = hgt.duplicate()
		sorted.sort()
		var thr: float = sorted[int(N * 0.6)]
		for i: int in range(N):
			tile[i] = GuData.GRASS if hgt[i] > thr else GuData.DEEP


## Grundgelände der Zufallswelt (Regionen, Höhen, Kacheln) – unveränderter Algorithmus.
func _base_random(S: int) -> void:
	# Frequenzen und Verwacklung in Bezugsgröße 256: die Welt sieht in jeder Kartengröße gleich gegliedert aus
	var kf: float = 256.0 / W
	var nw: FastNoiseLite = _noise(S + 5, 0.022 * kf, 4)
	var nw2: FastNoiseLite = _noise(S + 9, 0.022 * kf, 4)
	var ne: FastNoiseLite = _noise(S, 0.025 * kf, 5)
	var ne2: FastNoiseLite = _noise(S + 33, 0.06 * kf, 3)
	var nedge: FastNoiseLite = _noise(S + 123, 0.03 * kf, 3)
	var nr1: FastNoiseLite = _noise(S + 71, 0.028 * kf, 4)
	var nr4: FastNoiseLite = _noise(S + 91, 0.022 * kf, 4)
	var nisl: FastNoiseLite = _noise(S + 201, 0.05 * kf, 4)
	for y: int in range(H):
		for x: int in range(W):
			var i: int = y * W + x
			var wob: float = (n01(nw, x, y) - 0.5) * 46.0 / kf
			var wob2: float = (n01(nw2, x + 40 / kf, y) - 0.5) * 40.0 / kf
			var r: int
			if y < H * 0.26 + wob:
				r = 0
			elif y > H * 0.74 + wob:
				r = 1
			elif x < W * 0.3 + wob2:
				r = 2
			elif x > W * 0.7 + wob2:
				r = 3
			else:
				r = 4
			region[i] = r
			var e: float = n01(ne, x, y)
			var e2: float = n01(ne2, x, y)
			var edge: float = minf(minf(x, W - 1 - x) / (W * 0.5), minf(y, H - 1 - y) / (H * 0.5)) + (n01(nedge, x, y) - 0.5) * 0.22
			var fall: float = (0.24 - edge) / 0.24 if edge < 0.24 else 0.0
			var h: float
			match r:
				0:
					h = 0.5 + (e - 0.5) * 0.45
				1:
					var rd: float = 1.0 - absf(n01(nr1, x, y) * 2.0 - 1.0)
					h = 0.45 + (e - 0.5) * 0.6 + rd * rd * 0.36 - 0.06
				2:
					h = 0.49 + (e - 0.5) * 0.35
				3:
					h = 0.27 + (n01(nisl, x, y) - 0.5) * 1.5
				_:
					var rd4: float = 1.0 - absf(n01(nr4, x, y) * 2.0 - 1.0)
					h = 0.48 + (e - 0.5) * 0.7 + pow(rd4, 4.0) * 0.32 - 0.03
			h -= fall * 0.55
			hgt[i] = h
			var t: int
			if h < 0.375:
				t = GuData.DEEP
			elif r == 0:
				t = GuData.SNOW if y < H * 0.115 + wob * 0.3 else (GuData.HILL if h > 0.7 else GuData.STEP)
			elif r == 1:
				t = GuData.MOUNT if h > 0.83 else (GuData.HILL if h > 0.75 else GuData.GRASS)
			elif r == 2:
				t = GuData.HILL if h > 0.66 else GuData.DES
				if e2 > 0.76 and h < 0.62:
					t = GuData.DEEP if e2 > 0.82 else GuData.GRASS
			elif r == 3:
				t = GuData.HILL if h > 0.7 else GuData.GRASS
			else:
				t = GuData.MOUNT if h > 0.82 else (GuData.HILL if h > 0.76 else GuData.GRASS)
			tile[i] = t


## Gemeinsamer Abschluss: Flachwasser, Regionswände, Strände, Pflanzen.
## open_sea[i] == 1: offenes Außenmeer – dort entfällt die Wand, wenn sie mehr als 10 Kacheln von Land entfernt ist.
## blank: leere Welt – keine Regionswände, nur vereinzelte Bäume und Grasbüschel.
func _finish(S: int, open_sea: PackedByteArray, blank: bool = false) -> void:
	compute_water()
	for i: int in range(N):
		if tile[i] == GuData.DEEP and wdist[i] <= 8:
			tile[i] = GuData.SHAL
	# Regionswände: Grenzkacheln (Nachbar in anderer Region, 8er-Nachbarschaft), auf großen Karten zu einem
	# breiteren Band verdickt. Jedes Paar verschiedener Nachbarn wird einmal (nach rechts/unten) geprüft.
	var wr: float = wall_r()
	var wri: int = ceili(wr)
	var wr2: float = wr * wr
	var bm: PackedByteArray = PackedByteArray()
	bm.resize(N)
	var rg: PackedByteArray = region
	for y: int in range(0 if blank else H):
		var row: int = y * W
		var last: bool = y == H - 1
		for x: int in range(W):
			var i: int = row + x
			var r: int = rg[i]
			if x < W - 1 and rg[i + 1] != r:
				bm[i] = 1
				bm[i + 1] = 1
			if not last:
				var k: int = i + W
				if rg[k] != r:
					bm[i] = 1
					bm[k] = 1
				if x < W - 1 and rg[k + 1] != r:
					bm[i] = 1
					bm[k + 1] = 1
				if x > 0 and rg[k - 1] != r:
					bm[i] = 1
					bm[k - 1] = 1
	var tl: PackedByteArray = tile
	for i: int in range(N if not blank else 0):
		if bm[i] == 0 or not (open_sea.is_empty() or open_sea[i] == 0 or wdist[i] <= 10):
			continue
		tl[i] = GuData.WALL
		if wri <= 0:
			continue
		var x: int = i % W
		var y: int = i / W
		for dy: int in range(maxi(-wri, -y), mini(wri, H - 1 - y) + 1):
			for dx: int in range(maxi(-wri, -x), mini(wri, W - 1 - x) + 1):
				if dx * dx + dy * dy <= wr2:
					tl[i + dy * W + dx] = GuData.WALL
	# Strand mit Zacken: Land (ohne Wand/Schnee) neben Wasser (8er-Nachbarschaft); gesucht wird vom Ufer-Wasser
	# aus (wdist == 1 aus der Wasserberechnung vor den Wänden)
	var sand: PackedByteArray = PackedByteArray()
	sand.resize(N)
	var wd: PackedByteArray = wdist
	for i: int in range(N):
		if wd[i] != 1 or tl[i] > GuData.SHAL:
			continue
		var x: int = i % W
		var y: int = i / W
		for dy: int in range(-1 if y > 0 else 0, 2 if y < H - 1 else 1):
			for dx: int in range(-1 if x > 0 else 0, 2 if x < W - 1 else 1):
				var j: int = i + dy * W + dx
				var t: int = tl[j]
				if t > GuData.SHAL and t != GuData.WALL and t != GuData.SNOW:
					sand[j] = 1
	for i: int in range(N):
		if sand[i] == 1 and tl[i] != GuData.DES and tl[i] != GuData.MOUNT:
			tl[i] = GuData.SAND
			var x: int = i % W
			var y: int = i / W
			if GuData.hash2(x, y, S + 3) < 0.3 and y > 1 and tl[i - W] != GuData.WALL and GuData.is_land(tl[i - W]) and sand[i - W] == 0:
				tl[i - W] = GuData.SAND
				if GuData.hash2(x, y, S + 4) < 0.45 and GuData.is_land(tl[i - 2 * W]) and tl[i - 2 * W] != GuData.WALL:
					tl[i - 2 * W] = GuData.SAND
	tile = tl
	compute_water()
	if blank:
		_blank_plants(S)
		return
	# Pflanzen, Felsen, Adern (Wasser, Wände und die vielen Kacheln ohne Objekt früh überspringen);
	# Waldflecken wachsen mit der Karte mit
	var nf: FastNoiseLite = _noise(S + 55, 0.045 * 256.0 / W, 3)
	for y: int in range(H):
		for x: int in range(W):
			var i: int = y * W + x
			var t: int = tl[i]
			if t <= GuData.SHAL or t == GuData.WALL:
				continue
			var q: float = GuData.hash2(x, y, S + 999)
			if q >= 0.05 and q <= 0.94:
				continue
			var r: int = region[i]
			var f: float = n01(nf, x, y)
			var q2: float = GuData.hash2(x, y, S + 4)
			var ft: int = 0
			if t == GuData.GRASS:
				if r == 1:
					if f > 0.47:
						if q < (0.045 if f > 0.56 else 0.011):
							ft = GuData.F_BAMB if (f > 0.62 and q2 < 0.45) else GuData.F_TREE
					elif q < 0.006:
						ft = GuData.F_TREE
					if q > 0.9995:
						ft = GuData.F_SPRING
				elif r == 4:
					if f > 0.5:
						if q < (0.04 if f > 0.58 else 0.008):
							ft = GuData.F_TREE
					elif q < 0.0045:
						ft = GuData.F_TREE
					if q > 0.9994:
						ft = GuData.F_SPRING
					elif ft == 0 and q > 0.997:
						ft = GuData.F_FLOWER
				elif r == 3:
					if q < 0.008:
						ft = GuData.F_PALM if q2 < 0.5 else GuData.F_TREE
					elif q > 0.994:
						ft = GuData.F_FLOWER
				elif r == 2:
					if q < 0.02:
						ft = GuData.F_PALM
				elif q < 0.004:
					ft = GuData.F_TREE
				if ft == 0 and q > 0.965 and q < 0.975:
					ft = GuData.F_TUFT
			elif t == GuData.STEP:
				if q < 0.003:
					ft = GuData.F_TREE
				elif q > 0.998:
					ft = GuData.F_ROCK
				elif q > 0.94:
					ft = GuData.F_TUFT
			elif t == GuData.SNOW:
				if q < 0.008:
					ft = GuData.F_PINE
			elif t == GuData.DES:
				if q < 0.004:
					ft = GuData.F_ROCK
				elif q > 0.993:
					ft = GuData.F_SHRUB
			elif t == GuData.SAND:
				if r != 0 and q < 0.006:
					ft = GuData.F_PALM
			elif t == GuData.HILL:
				if q < 0.008:
					ft = GuData.F_ROCK
				elif q < 0.014:
					ft = GuData.F_ORE
				elif q < 0.05 and r != 2:
					ft = GuData.F_PINE if r == 0 else GuData.F_TREE
			elif t == GuData.MOUNT:
				if q < 0.006:
					ft = GuData.F_ORE
			if ft != 0:
				feat[i] = ft


## Leere Welt: ganz vereinzelte Baumgruppen, Grasbüschel und Blumen auf dem Grasland.
func _blank_plants(S: int) -> void:
	var nf: FastNoiseLite = _noise(S + 55, 0.04, 3)
	for i: int in range(N):
		if tile[i] != GuData.GRASS:
			continue
		var x: int = i % W
		var y: int = i / W
		var q: float = GuData.hash2(x, y, S + 999)
		var f: float = n01(nf, x, y)
		if (f > 0.66 and q < 0.006) or q < 0.0004:
			feat[i] = GuData.F_TREE
		elif q > 0.9985:
			feat[i] = GuData.F_FLOWER
		elif q > 0.985:
			feat[i] = GuData.F_TUFT


# ---------------- Zeichnen ----------------

## Wasserrauschen je Kachel (einmal je Kartengröße, nativ über Noise.get_image): Tiefenränder und Meeresflecken
var _wf1: PackedByteArray
var _wf2: PackedByteArray


func _water_fields() -> void:
	var n: FastNoiseLite = _noise(11, 0.09, 2)
	_wf1 = n.get_image(W, H, false, false, false).get_data()
	n.frequency = 0.09 * 0.8
	n.offset = Vector3(375.0, 0.0, 0.0)
	_wf2 = n.get_image(W, H, false, false, false).get_data()


func tile_color(x: int, y: int) -> Color:
	var i: int = y * W + x
	var t: int = tile[i]
	var n: float = GuData.hash2(x, y, 13)
	var k: int = 0 if n < 0.4 else (1 if n < 0.75 else 2)
	var c: Color
	if t == GuData.DEEP or t == GuData.SHAL:
		if _wf1.size() != N:
			_water_fields()
		var nn: float = GuData.hash2(x >> 1, y >> 1, 5)
		var d: float = wdist[i] + (_wf1[i] / 255.0 - 0.5) * 9.0
		if wdist[i] <= 1:
			c = Color8(104, 202, 244)
		elif d <= 6:
			c = Color8(84, 186, 238)
		elif d <= 9:
			c = Color8(84, 186, 238) if nn < 0.5 else Color8(66, 156, 228)
		elif d <= 15:
			c = Color8(52, 124, 212) if nn < (d - 9.0) / 7.0 else Color8(66, 156, 228)
		else:
			var b: float = _wf2[i] / 255.0
			c = Color8(38, 94, 184) if b > 0.6 else (Color8(42, 102, 192) if (b > 0.55 and nn < 0.5) else Color8(46, 110, 200))
		if n > 0.985:
			c = c.lightened(0.1)
	elif t == GuData.GRASS:
		c = GuData.GRASSP[region[i]][k]
	elif t == GuData.WALL:
		# Regionswand: violetter Saum, heller schimmernder Kern mit schrägen Lichtstreifen (auch im Fernblick klar)
		var rim: bool = (x > 0 and tile[i - 1] != t) or (x < W - 1 and tile[i + 1] != t) or (y > 0 and tile[i - W] != t) or (y < H - 1 and tile[i + W] != t)
		if rim:
			c = Color8(146, 112, 226) if n < 0.8 else Color8(168, 136, 238)
		else:
			var st: int = (x + y * 2) % 9
			c = Color8(250, 248, 255) if st < 2 else (Color8(214, 204, 252) if st < 5 else Color8(232, 226, 255))
			if n > 0.93:
				c = Color8(255, 236, 250)
	elif t == GuData.MOUNT:
		c = GuData.PAL[t][k]
		if hgt[i] > 0.92 and n > 0.55:
			c = Color8(200, 204, 208)
		var edge: bool = (x > 0 and tile[i - 1] != t) or (x < W - 1 and tile[i + 1] != t) or (y > 0 and tile[i - W] != t) or (y < H - 1 and tile[i + W] != t)
		if edge:
			c = Color8(34, 36, 38)
	elif t == GuData.HILL:
		c = GuData.PAL[t][1 if n < 0.85 else k]
	else:
		c = GuData.PAL[t][k]
	if t == GuData.SAND and y < H - 1 and GuData.is_water(tile[i + W]):
		c = Color8(244, 240, 196)
	elif t == GuData.LAVA:
		# glühende Adern und dunkle Kruste am Rand
		var edge2: bool = (x > 0 and tile[i - 1] != t) or (x < W - 1 and tile[i + 1] != t) or (y > 0 and tile[i - W] != t) or (y < H - 1 and tile[i + W] != t)
		if edge2:
			c = Color8(120, 40, 24)
		elif n > 0.9:
			c = Color8(255, 222, 120)
	return c


func _far_dot(i: int) -> void:
	var f: int = feat[i]
	if f == 0:
		return
	var x: int = i % W
	var y: int = i / W
	var a: Color
	var b: Color
	if GuData.is_tree(f):
		if f == GuData.F_PINE:
			a = Color8(36, 80, 58)
			b = Color8(90, 154, 106)
		elif f == GuData.F_PALM:
			a = Color8(46, 122, 42)
			b = Color8(122, 208, 74)
		elif f == GuData.F_BAMB:
			a = Color8(78, 128, 48)
			b = Color8(168, 216, 96)
		else:
			var p: Array = GuData.TREEPAL[Sprites.tree_variant(x, y, region[i]) / 2]
			a = Color(p[1])
			b = Color(p[0])
		far_img.set_pixel(x, y, a)
		if y > 0:
			far_img.set_pixel(x, y - 1, b)
		if x + 1 < W:
			far_img.set_pixel(x + 1, y, a.darkened(0.4))
	elif f == GuData.F_ROCK:
		far_img.set_pixel(x, y, Color8(150, 146, 140))
	elif f == GuData.F_ORE:
		far_img.set_pixel(x, y, Color8(220, 240, 232))
	elif f == GuData.F_SPRING:
		far_img.set_pixel(x, y, Color8(120, 220, 240))
	elif f == GuData.F_FLOWER:
		far_img.set_pixel(x, y, Color8(232, 122, 200))
	elif f == GuData.F_ROAD:
		far_img.set_pixel(x, y, Color8(176, 142, 96))


func _render_rect(x0: int, y0: int, x1: int, y1: int) -> void:
	# Geländefarben in einen Puffer, dann auf einmal in beide Bilder
	var rw: int = x1 - x0
	var rh: int = y1 - y0
	var buf: PackedInt32Array = PackedInt32Array()
	buf.resize(rw * rh)
	var k: int = 0
	for y: int in range(y0, y1):
		for x: int in range(x0, x1):
			buf[k] = tile_color(x, y).to_abgr32()
			k += 1
	var im0: Image = Image.create_from_data(rw, rh, false, Image.FORMAT_RGBA8, buf.to_byte_array())
	near_img.blit_rect(im0, Rect2i(0, 0, rw, rh), Vector2i(x0, y0))
	far_img.blit_rect(im0, Rect2i(0, 0, rw, rh), Vector2i(x0, y0))
	var clip: Rect2i = Rect2i(x0, y0, x1 - x0, y1 - y0)
	for y: int in range(maxi(0, y0 - 1), mini(H, y1 + 16)):
		for x: int in range(maxi(0, x0 - 7), mini(W, x1 + 7)):
			var i: int = y * W + x
			var f: int = feat[i]
			if f == 0:
				continue
			var im: Image = Sprites.feat_image(f, x, y, region[i])
			var dst: Rect2i = Rect2i(x - (im.get_width() >> 1), y + 1 - im.get_height(), im.get_width(), im.get_height())
			var inter: Rect2i = dst.intersection(clip)
			if inter.size.x <= 0 or inter.size.y <= 0:
				continue
			near_img.blend_rect(im, Rect2i(inter.position - dst.position, inter.size), inter.position)
			if y >= y0 and y < y1 and x >= x0 and x < x1:
				_far_dot(i)


func render_all() -> void:
	var t0: int = Time.get_ticks_usec()
	_render_rect(0, 0, W, H)
	near_tex.update(near_img)
	far_tex.update(far_img)
	dirty.fill(0)
	drect.fill(0)
	_upl_pending = false
	for c: int in range(dver.size()):
		dver[c] += 1
	gen_ms["render"] = (Time.get_ticks_usec() - t0) / 1000.0


## Kachel (x, y) neu zeichnen (mit den Nachbarn im selben Block – Ränder hängen von ihnen ab).
func mark_dirty(x: int, y: int) -> void:
	if not in_map(x, y):
		return
	var c: int = (y / CHK) * CXN + (x / CHK)
	var bx: int = (x / CHK) * CHK
	var by: int = (y / CHK) * CHK
	_mark_in(c, maxi(bx, x - 1), maxi(by, y - 1), mini(mini(bx + CHK, W), x + 2), mini(mini(by + CHK, H), y + 2))


## Ein Objekt auf (x, y) ragt nach oben und zur Seite – betroffene Blöcke (nur das Rechteck darin) neu zeichnen.
func mark_area(x: int, y: int) -> void:
	mark_rect(x - 6, y - 15, x + 7, y + 2)


## Rechteck [x0, x1) × [y0, y1) neu zeichnen.
func mark_rect(x0: int, y0: int, x1: int, y1: int) -> void:
	x0 = maxi(0, x0)
	y0 = maxi(0, y0)
	x1 = mini(W, x1)
	y1 = mini(H, y1)
	if x1 <= x0 or y1 <= y0:
		return
	for cy: int in range(y0 / CHK, (y1 - 1) / CHK + 1):
		for cx: int in range(x0 / CHK, (x1 - 1) / CHK + 1):
			var bx: int = cx * CHK
			var by: int = cy * CHK
			_mark_in(cy * CXN + cx, maxi(x0, bx), maxi(y0, by), mini(x1, bx + CHK), mini(y1, by + CHK))


func _mark_in(c: int, x0: int, y0: int, x1: int, y1: int) -> void:
	var k: int = c * 4
	if dirty[c] == 0:
		dirty[c] = 1
		drect[k] = x0
		drect[k + 1] = y0
		drect[k + 2] = x1
		drect[k + 3] = y1
	elif drect[k] < drect[k + 2]:   # sonst schon der ganze Block
		drect[k] = mini(drect[k], x0)
		drect[k + 1] = mini(drect[k + 1], y0)
		drect[k + 2] = maxi(drect[k + 2], x1)
		drect[k + 3] = maxi(drect[k + 3], y1)


## Geänderte Blöcke neu zeichnen (höchstens limit je Aufruf). Die Texturen werden höchstens alle 50 ms hochgeladen
## (je Upload 2 × W·H·4 Byte – auf Handys und im Browser teuer); was noch aussteht, folgt beim nächsten Aufruf.
func flush_dirty(limit: int = 12) -> void:
	var n: int = 0
	for c: int in range(dirty.size()):
		if dirty[c] == 1:
			dirty[c] = 0
			var cx: int = (c % CXN) * CHK
			var cy: int = (c / CXN) * CHK
			var k: int = c * 4
			if drect[k] < drect[k + 2]:
				_render_rect(drect[k], drect[k + 1], drect[k + 2], drect[k + 3])
			else:
				_render_rect(cx, cy, mini(W, cx + CHK), mini(H, cy + CHK))
			drect[k] = 0
			drect[k + 2] = 0
			dver[c] += 1
			n += 1
			if n >= limit:
				break
	if n > 0:
		_upl_pending = true
	if _upl_pending and Time.get_ticks_msec() - _upl_ms >= 50:
		_upl_pending = false
		_upl_ms = Time.get_ticks_msec()
		near_tex.update(near_img)
		far_tex.update(far_img)


func refresh_water() -> void:
	compute_water()
	for i: int in range(N):
		var t: int = tile[i]
		if GuData.is_water(t):
			tile[i] = GuData.SHAL if wdist[i] <= 4 else GuData.DEEP
	dirty.fill(1)
	drect.fill(0)
	water_dirty = false


func set_tile(i: int, t: int) -> int:
	## Gibt die alte Geländeart zurück.
	var old: int = tile[i]
	if old == t:
		return old
	tile[i] = t
	hgt[i] = GuData.DEFH[t] + (GuData.hash2(i, 7, 5) - 0.5) * 0.06
	var f: int = feat[i]
	if f != 0 and (GuData.is_water(t) or t == GuData.WALL):
		feat[i] = 0
	if t == GuData.MOUNT and GuData.is_tree(f):
		feat[i] = 0
	temp_snow[i] = 0
	var x: int = i % W
	var y: int = i / W
	mark_area(x, y)
	mark_dirty(x, y - 1)
	mark_dirty(x, y + 1)
	if GuData.is_water(t) != GuData.is_water(old):
		water_dirty = true
	return old


## Clan-Gebiete neu berechnen und zeichnen – auf einmal (Tests, Ladevorgänge). Im Spiel läuft dasselbe
## verteilt über mehrere Bilder: begin_territory, dann territory_step je Bild (Web-Build ist Single-Threaded).
## Jede Kachel gehört dem nächstgelegenen Dorf (Abstand relativ zum Dorfradius); jenseits davon liegt eine
## verblassende Einflusszone (infl). Ebenen: 0 Clan-Farbe, 1 Dörfer, 3 Mächte (Farbe der Vormacht, Rest abgedunkelt).
## Ränder wie bei WorldBox: dunkle Außenlinie, helle Innenlinie; bei Ebene 0 ist die Außenlinie in der
## Farbe der Vormacht, wenn der Clan einer folgt. Umkämpfte Grenzen landen gestrichelt in war_img.
## head: je Clan-Id die Vormacht (Influence.head); leer = jeder Clan ist seine eigene Macht.
func update_territory(villages: Array, clans: Array, head: PackedInt32Array = PackedInt32Array()) -> void:
	begin_territory(villages, clans, head)
	while not territory_step(1 << 30):
		pass


# Zustand der laufenden Gebiets-Berechnung (Arbeitskopien, erst am Ende nach terr/infl übernommen)
var _jv: Array = []
var _jc: Array = []
var _jhd: PackedInt32Array
var _jphase: int = -1  ## -1 = nichts zu tun
var _jpos: int = 0
var _jus: int = 0  ## verbrauchte Rechenzeit (µs)
var _jterr: PackedInt32Array
var _jinfl: PackedInt32Array
var _jbest: PackedInt32Array
var _jinf_s: PackedInt32Array
var _jvclan: PackedInt32Array
var _jK: PackedInt32Array
var _jCL: PackedInt32Array
var _jbk: PackedByteArray
var _jimg: PackedInt32Array
var _jfill: PackedInt32Array
var _jedge: PackedInt32Array
var _jwar: PackedInt32Array
var _jany_war: bool = false
var _jcsx: PackedFloat32Array
var _jcsy: PackedFloat32Array
var _jcn: PackedInt32Array
var _jc_fill: PackedInt32Array
var _jc_out: PackedInt32Array
var _jc_in: PackedInt32Array
var _jc_hatch: PackedInt32Array
var _jc_soft: PackedInt32Array
var _jc_csoft: PackedInt32Array
var _jc_infl: PackedInt32Array
var _jveil: int = 0
var _jlayer: int = 0


func territory_busy() -> bool:
	return _jphase >= 0


## Neue Gebiets-Berechnung beginnen (eine laufende wird verworfen).
func begin_territory(villages: Array, clans: Array, head: PackedInt32Array = PackedInt32Array()) -> void:
	_jv = villages.duplicate()
	_jc = clans.duplicate()
	var nc: int = clans.size()
	_jhd = head.duplicate()
	if _jhd.size() != nc:
		_jhd.resize(nc)
		for k: int in range(nc):
			_jhd[k] = k
	_jlayer = layer
	_jphase = 0
	_jpos = 0
	_jus = 0
	terr_phase_us.fill(0)


## Ein Stück der Gebiets-Berechnung (höchstens etwa budget_us Mikrosekunden); true = fertig und hochgeladen.
func territory_step(budget_us: int) -> bool:
	if _jphase < 0:
		return true
	var t0: int = Time.get_ticks_usec()
	var tend: int = t0 + budget_us
	while _jphase >= 0 and Time.get_ticks_usec() < tend:
		var tp: int = Time.get_ticks_usec()
		var ph: int = _jphase
		match _jphase:
			0:
				_job_init()
			1:
				_job_claim(tend)
			2:
				_job_keys(tend)
			3:
				_job_colors()
			4:
				_job_borders(tend)
			5:
				_job_pixels(tend)
			6:
				_job_finish()
		terr_phase_us[ph] += Time.get_ticks_usec() - tp
	_jus += Time.get_ticks_usec() - t0
	if _jphase < 0:
		terr_ms = _jus / 1000.0
		return true
	return false


func _job_init() -> void:
	if _jlayer == 2:
		terr.fill(-1)
		infl.fill(-1)
		terr_center.clear()
		war_img.fill(Color(0, 0, 0, 0))
		war_tex.update(war_img)
		fill_img.fill(Color(0, 0, 0, 0))
		fill_tex.update(fill_img)
		edge_img.fill(Color(0, 0, 0, 0))
		edge_tex.update(edge_img)
		terr_img.fill(Color(0, 0, 0, 0))
		_region_layer()
		terr_tex.update(terr_img)
		_jphase = -1
		return
	_jterr = PackedInt32Array()
	_jterr.resize(N)
	_jterr.fill(-1)
	_jinfl = PackedInt32Array()
	_jinfl.resize(N)
	_jinfl.fill(-1)
	_jbest = PackedInt32Array()
	_jbest.resize(N)
	_jbest.fill(1 << 30)
	_jinf_s = PackedInt32Array()
	_jinf_s.resize(N)
	# Rechteck um alle Dorfgebiete samt Einflusszone: nur dort arbeiten die folgenden Phasen Kachel für Kachel
	_jbx0 = W
	_jby0 = H
	_jbx1 = -1
	_jby1 = -1
	_jcm = PackedByteArray()
	_jcm.resize(CXN * CXN)
	_jvclan = PackedInt32Array()
	_jvclan.resize(_jv.size())
	for v: Village in _jv:
		if v != null:
			_jvclan[v.id] = v.clan
	_jphase = 1
	_jpos = 0


## 1) Besitz: nächstes Dorf (Abstand / Radius); Einflusszone = stärkste Nähe außerhalb jedes Gebiets.
func _job_claim(tend: int) -> void:
	var tt: PackedInt32Array = _jterr
	var best: PackedInt32Array = _jbest
	var ii: PackedInt32Array = _jinfl
	var iss: PackedInt32Array = _jinf_s
	while _jpos < _jv.size():
		var v: Village = _jv[_jpos]
		_jpos += 1
		if v == null or not v.alive:
			continue
		var r: int = terr_radius(v)
		var R: int = r + INF_R
		var r2: int = r * r
		var R2: int = R * R
		var cx: int = clampi(int(v.cx), 0, W - 1)
		var cy: int = clampi(int(v.cy), 0, H - 1)
		var rg: int = region[cy * W + cx]
		var vid: int = v.id
		var vcl: int = v.clan
		var kinf: float = 255.0 / INF_R
		_jbx0 = mini(_jbx0, maxi(0, cx - R - 1))
		_jby0 = mini(_jby0, maxi(0, cy - R - 1))
		_jbx1 = maxi(_jbx1, mini(W - 1, cx + R + 1))
		_jby1 = maxi(_jby1, mini(H - 1, cy + R + 1))
		for mcy: int in range(maxi(0, cy - R - 1) / CHK, mini(H - 1, cy + R + 1) / CHK + 1):
			for mcx: int in range(maxi(0, cx - R - 1) / CHK, mini(W - 1, cx + R + 1) / CHK + 1):
				_jcm[mcy * CXN + mcx] = 1
		for dy: int in range(maxi(-R, -cy), mini(R, H - 1 - cy) + 1):
			var dy2: int = dy * dy
			var span: int = int(sqrt(float(R2 - dy2)))
			var row: int = (cy + dy) * W + cx
			for dx: int in range(maxi(-span, -cx), mini(span, W - 1 - cx) + 1):
				var i: int = row + dx
				if region[i] != rg:
					continue
				var tl: int = tile[i]
				if tl <= GuData.SHAL or tl == GuData.WALL:
					continue
				var d2: int = dx * dx + dy2
				if d2 <= r2:
					var sc: int = d2 * 1024 / r2
					if sc < best[i]:
						best[i] = sc
						tt[i] = vid
				else:
					var s: int = 255 - int((sqrt(float(d2)) - r) * kinf)
					if s > iss[i]:
						iss[i] = s
						ii[i] = vcl
		if Time.get_ticks_usec() >= tend:
			return
	var nc: int = _jc.size()
	_jK = PackedInt32Array()
	_jK.resize(N)
	_jK.fill(-1)
	_jCL = PackedInt32Array()
	_jCL.resize(N)
	_jCL.fill(-1)
	_jcsx = PackedFloat32Array()
	_jcsx.resize(nc)
	_jcsy = PackedFloat32Array()
	_jcsy.resize(nc)
	_jcn = PackedInt32Array()
	_jcn.resize(nc)
	_jphase = 2
	_jpos = _jby0


## 2) Schlüssel je Kachel (Ebene 0: Clan, 1: Dorf, 3: Vormacht), Clan je Kachel, Schwerpunkte.
func _job_keys(tend: int) -> void:
	var by_vil: bool = _jlayer == 1
	var by_head: bool = _jlayer == 3
	var tt: PackedInt32Array = _jterr
	var ii: PackedInt32Array = _jinfl
	var hd: PackedInt32Array = _jhd
	var vc: PackedInt32Array = _jvclan
	while _jpos <= _jby1:
		var y: int = _jpos
		_jpos += 1
		var row: int = y * W
		var cyr: int = (y / CHK) * CXN
		for cx: int in range(CXN):
			if _jcm[cyr + cx] == 0:
				continue
			for x: int in range(cx * CHK, mini(W, cx * CHK + CHK)):
				var i: int = row + x
				var t: int = tt[i]
				if t < 0:
					var ik: int = ii[i]
					if ik >= 0 and hd[ik] < 0:
						ii[i] = -1
					continue
				ii[i] = -1
				var k: int = vc[t]
				_jCL[i] = k
				var key: int = t if by_vil else (hd[k] if by_head else k)
				if key < 0:
					key = k
				_jK[i] = key
				_jcsx[k] += x
				_jcsy[k] += y
				_jcn[k] += 1
		if Time.get_ticks_usec() >= tend:
			return
	_jphase = 3


## 3) Beschriftungspunkte und Farben je Schlüssel.
func _job_colors() -> void:
	var by_vil: bool = _jlayer == 1
	var by_head: bool = _jlayer == 3
	var nc: int = _jc.size()
	var hd: PackedInt32Array = _jhd
	terr_center.clear()
	for ck2: int in range(nc):
		if _jcn[ck2] == 0:
			continue
		var pos: Vector2i = _snap_own(int(_jcsx[ck2] / _jcn[ck2]), int(_jcsy[ck2] / _jcn[ck2]), ck2, _jCL)
		terr_center[ck2] = Vector3(pos.x, pos.y, _jcn[ck2])
	var nk: int = _jv.size() if by_vil else nc
	_jc_fill = PackedInt32Array()
	_jc_fill.resize(nk)
	_jc_out = PackedInt32Array()
	_jc_out.resize(nk)
	_jc_in = PackedInt32Array()
	_jc_in.resize(nk)
	_jc_hatch = PackedInt32Array()
	_jc_hatch.resize(nk)
	_jc_soft = PackedInt32Array()
	_jc_soft.resize(nk)
	for key2: int in range(nk):
		var cc: Clan
		var col: Color
		if by_vil:
			var vv: Village = _jv[key2]
			if vv == null:
				continue
			cc = _jc[vv.clan]
			col = cc.col.lightened(0.22) if key2 % 2 == 0 else cc.col.darkened(0.18)
		else:
			cc = _jc[key2]
			col = cc.col
		col = vivid(col)
		var outer: Color = col.darkened(0.55)
		if not by_vil and not by_head and hd[key2] >= 0 and hd[key2] != key2:
			outer = vivid((_jc[hd[key2]] as Clan).col).darkened(0.12)
		if by_vil and cc.cap == key2:
			outer = Color("#ffd24a")
		_jc_fill[key2] = _rgba(col, 0.66 if by_head else 0.58)
		_jc_hatch[key2] = _rgba(col.darkened(0.6), 0.62) if (by_head and cc.align == 1) else _jc_fill[key2]
		_jc_out[key2] = _rgba(outer, 1.0)
		_jc_in[key2] = _rgba(col.lightened(0.45), 0.92)
		_jc_soft[key2] = _rgba(col.lightened(0.5), 0.6)
	# herrenloses Land: leicht (Mächte-Ebene stärker) abgedunkelt; die Einflusszone geht in die Clanfarbe über
	var veil_c: Color = Color(0.06, 0.08, 0.1)
	var va: float = 0.42 if by_head else 0.16
	_jveil = _rgba(veil_c, va)
	_jc_csoft = PackedInt32Array()
	_jc_csoft.resize(nc)
	_jc_infl = PackedInt32Array()
	_jc_infl.resize(nc * 8)
	for k3: int in range(nc):
		var cl3: Clan = _jc[k3]
		_jc_csoft[k3] = _rgba(vivid(cl3.col).lightened(0.25), 0.8)
		var ic: Color = vivid((_jc[hd[k3]] as Clan).col if (by_head and hd[k3] >= 0) else cl3.col)
		for q: int in range(8):
			var f: float = (q + 1) / 8.0
			_jc_infl[k3 * 8 + q] = _rgba(veil_c.lerp(ic, f), lerpf(va, 0.34, f))
	_jbk = PackedByteArray()
	_jbk.resize(N)
	_jany_war = false
	_jphase = 4
	_jpos = _jby0


## 4) Rand-Art je Kachel: 1 Außenrand, 2 weiche Innengrenze (Clans derselben Macht bzw. Dörfer eines Clans), 3 Kriegsgrenze.
func _job_borders(tend: int) -> void:
	var by_vil: bool = _jlayer == 1
	var by_head: bool = _jlayer == 3
	var K: PackedInt32Array = _jK
	var CL: PackedInt32Array = _jCL
	while _jpos <= _jby1:
		var y: int = _jpos
		_jpos += 1
		var row: int = y * W
		var cyr: int = (y / CHK) * CXN
		for cx: int in range(CXN):
			if _jcm[cyr + cx] == 0:
				continue
			for x: int in range(cx * CHK, mini(W, cx * CHK + CHK)):
				var i: int = row + x
				var key: int = K[i]
				if key < 0:
					continue
				# vier Nachbarn; außerhalb der Karte zählt als fremd
				var kl: int = K[i - 1] if x > 0 else -1
				var kr: int = K[i + 1] if x < W - 1 else -1
				var ku: int = K[i - W] if y > 0 else -1
				var kd: int = K[i + W] if y < H - 1 else -1
				if kl == key and kr == key and ku == key and kd == key:
					if by_head:
						var ki0: int = CL[i]
						if CL[i - 1] != ki0 or CL[i + 1] != ki0 or CL[i - W] != ki0 or CL[i + W] != ki0:
							_jbk[i] = 2
					continue
				var ki: int = CL[i]
				var war: Dictionary = (_jc[ki] as Clan).war
				var b: int = 0
				for j: int in [i - 1 if x > 0 else -1, i + 1 if x < W - 1 else -1, i - W if y > 0 else -1, i + W if y < H - 1 else -1]:
					var kj: int = K[j] if j >= 0 else -1
					if kj == key:
						continue
					if kj < 0:
						b = maxi(b, 1)
						continue
					var cj: int = CL[j]
					if cj != ki and war.has(cj):
						b = 3
					elif by_vil and cj == ki:
						b = maxi(b, 2)
					else:
						b = maxi(b, 1)
				_jbk[i] = b
				if b == 3:
					_jany_war = true
		if Time.get_ticks_usec() >= tend:
			return
	_jfill = PackedInt32Array()
	_jfill.resize(N)
	_jedge = PackedInt32Array()
	_jedge.resize(N * EDGE_S * EDGE_S)
	_jwar = PackedInt32Array()
	if _jany_war:
		_jwar.resize(N)
	_jphase = 5
	_jpos = 0
	_jvstate = 0


## Schleier über herrenlosem Land (ohne Wände): zwischengespeichert, je Berechnung nur ein Streifen aufgefrischt
## (große Karten); ändert sich die Farbe (Ebene), wird er ganz neu aufgebaut – alles in Häppchen.
var _veil: PackedInt32Array
var _veil_c: int = 0
var _veil_y: int = 0
var _veil_full: bool = false
var _jvstate: int = 0
var _jvy1: int = 0
## Blöcke (CHK × CHK), die ein Dorfgebiet samt Einflusszone berühren – nur dort wird Kachel für Kachel gerechnet
var _jcm: PackedByteArray
var _jbx0: int = 0
var _jby0: int = 0
var _jbx1: int = -1
var _jby1: int = -1


## true = Schleier für diese Berechnung fertig (dann liegt eine Kopie in _jimg).
func _veil_step(tend: int) -> bool:
	if _jvstate == 0:
		if _veil.size() != N or _veil_c != _jveil:
			_veil = PackedInt32Array()
			_veil.resize(N)
			_veil_c = _jveil
			_veil_y = 0
			_veil_full = false
		_jvy1 = mini(H, _veil_y + maxi(16, H / 8)) if _veil_full else H
		_jvstate = 1
	var vl: PackedInt32Array = _veil
	var tl: PackedByteArray = tile
	var vc: int = _veil_c
	while _veil_y < _jvy1:
		var row: int = _veil_y * W
		_veil_y += 1
		for i: int in range(row, row + W):
			var t: int = tl[i]
			vl[i] = vc if (t > GuData.SHAL and t != GuData.WALL) else 0
		if Time.get_ticks_usec() >= tend:
			return false
	if _veil_y >= H:
		_veil_y = 0
		_veil_full = true
	_jimg = _veil.duplicate()
	_jvstate = 2
	_jpos = _jby0
	return true


## 5) Pixel: Rand, Innenlinie, Fläche (Mächte-Ebene: dämonische Mächte schraffiert), Einflusszone, Schleier.
func _job_pixels(tend: int) -> void:
	if _jvstate < 2 and not _veil_step(tend):
		return
	var by_head: bool = _jlayer == 3
	var K: PackedInt32Array = _jK
	var bk: PackedByteArray = _jbk
	var img: PackedInt32Array = _jimg
	var fl: PackedInt32Array = _jfill
	var ii: PackedInt32Array = _jinfl
	var w_on: int = _rgba(Color("#ff3b2a"), 1.0)
	var w_off: int = _rgba(Color("#3a0806"), 0.85)
	var w_glow: int = _rgba(Color("#ff5a3a"), 0.45)
	while _jpos <= _jby1:
		var y: int = _jpos
		_jpos += 1
		var row: int = y * W
		var cyr: int = (y / CHK) * CXN
		for cx: int in range(CXN):
			if _jcm[cyr + cx] == 0:
				continue
			for x: int in range(cx * CHK, mini(W, cx * CHK + CHK)):
				var i: int = row + x
				var key: int = K[i]
				if key < 0:
					var ik: int = ii[i]
					if ik >= 0:
						img[i] = _jc_infl[ik * 8 + mini(7, _jinf_s[i] >> 5)]
					elif tile[i] > GuData.SHAL and tile[i] != GuData.WALL:
						img[i] = _jveil
					else:
						img[i] = 0
					continue
				var b: int = bk[i]
				fl[i] = _jc_fill[key]
				if b != 0:
					_edge_tile(x, y, i, key, by_head)
				if b == 1 or b == 3:
					img[i] = _jc_out[key]
					if b == 3:
						_jwar[i] = w_on if (((x + y) >> 1) & 1) == 0 else w_off
					continue
				if b == 2:
					img[i] = _jc_csoft[_jCL[i]] if by_head else _jc_soft[key]
					continue
				# Innenlinie neben einem Außenrand
				var nb: int = 0
				if x > 0:
					nb = bk[i - 1]
				if x < W - 1:
					nb = maxi(nb, bk[i + 1])
				if y > 0:
					nb = maxi(nb, bk[i - W])
				if y < H - 1:
					nb = maxi(nb, bk[i + W])
				if nb == 1 or nb == 3:
					img[i] = _jc_in[key]
					if nb == 3:
						_jwar[i] = w_glow
				elif by_head and (x + y) % 5 == 0:
					img[i] = _jc_hatch[key]
				else:
					img[i] = _jc_fill[key]
		if Time.get_ticks_usec() >= tend:
			return
	_jphase = 6


## Feine Grenzlinien einer Randkachel in edge_img: je fremder Seite außen dunkel (Krieg: rot gestrichelt),
## innen in Clanfarbe; Grenzen innerhalb einer Macht bzw. eines Clans nur als zarte Farblinie.
func _edge_tile(x: int, y: int, i: int, key: int, by_head: bool) -> void:
	var by_vil: bool = _jlayer == 1
	var K: PackedInt32Array = _jK
	var ki: int = _jCL[i]
	var war: Dictionary = (_jc[ki] as Clan).war
	var ES: int = EDGE_S
	var EW: int = W * ES
	var X0: int = x * ES
	var Y0: int = y * ES
	var c_o: int = _jc_out[key]
	var c_i: int = _jc_in[key]
	var c_s: int = _jc_csoft[ki] if by_head else _jc_soft[key]
	var w_on: int = _rgba(Color("#ff3b2a"), 1.0)
	var w_off: int = _rgba(Color("#2a0604"), 1.0)
	for side: int in 4:
		var j: int = -1
		if side == 0 and x > 0:
			j = i - 1
		elif side == 1 and x < W - 1:
			j = i + 1
		elif side == 2 and y > 0:
			j = i - W
		elif side == 3 and y < H - 1:
			j = i + W
		var kj: int = K[j] if j >= 0 else -1
		var kind: int = 0  # 0 nichts, 1 Außengrenze, 2 zart, 3 Krieg
		if kj != key:
			kind = 1
			if kj >= 0:
				var cj: int = _jCL[j]
				if cj != ki and war.has(cj):
					kind = 3
				elif by_vil and cj == ki:
					kind = 2
		elif by_head and _jCL[j] != ki:
			kind = 2
		if kind == 0:
			continue
		for k: int in ES:
			# o: äußerste Linie an der Kante, n: Linie eine Stufe nach innen
			var o: int
			var n: int
			if side == 0:
				o = (Y0 + k) * EW + X0
				n = o + 1
			elif side == 1:
				o = (Y0 + k) * EW + X0 + ES - 1
				n = o - 1
			elif side == 2:
				o = Y0 * EW + X0 + k
				n = o + EW
			else:
				o = (Y0 + ES - 1) * EW + X0 + k
				n = o - EW
			if kind == 2:
				_jedge[o] = c_s
				continue
			if kind == 3:
				_jedge[o] = w_on if (((X0 + Y0 + k) >> 1) & 1) == 0 else w_off
			else:
				_jedge[o] = c_o
			if _jedge[n] == 0:
				_jedge[n] = c_i


func _job_finish() -> void:
	terr = _jterr
	infl = _jinfl
	terr_img.set_data(W, H, false, Image.FORMAT_RGBA8, _jimg.to_byte_array())
	terr_tex.update(terr_img)
	fill_img.set_data(W, H, false, Image.FORMAT_RGBA8, _jfill.to_byte_array())
	fill_tex.update(fill_img)
	edge_img.set_data(W * EDGE_S, H * EDGE_S, false, Image.FORMAT_RGBA8, _jedge.to_byte_array())
	edge_tex.update(edge_img)
	if _jany_war:
		war_img.set_data(W, H, false, Image.FORMAT_RGBA8, _jwar.to_byte_array())
	else:
		war_img.fill(Color(0, 0, 0, 0))
	war_tex.update(war_img)
	# Arbeitskopien freigeben
	_jv = []
	_jc = []
	_jbest = PackedInt32Array()
	_jinf_s = PackedInt32Array()
	_jK = PackedInt32Array()
	_jCL = PackedInt32Array()
	_jbk = PackedByteArray()
	_jimg = PackedInt32Array()
	_jfill = PackedInt32Array()
	_jedge = PackedInt32Array()
	_jwar = PackedInt32Array()
	_jphase = -1


## Kräftigere Fassung einer Clanfarbe für die Gebietsfläche (blasse und dunkle Farben gehen sonst im Gelände unter).
static func vivid(c: Color) -> Color:
	return Color.from_hsv(c.h, clampf(c.s * 1.25, 0.0, 1.0) if c.s > 0.12 else c.s, clampf(c.v, 0.62, 0.98))


## Gebietsradius eines Dorfs in Kacheln (wächst mit Hütten, Türmen und Ahnenhalle).
static func terr_radius(v: Village) -> int:
	return clampi(int(16 + v.houses * 1.5 + v.towers * 3 + v.lvl * 3), 16, 34)


## Farbe als RGBA8-Wert für PackedInt32Array.to_byte_array() (Bytes r, g, b, a).
static func _rgba(c: Color, a: float) -> int:
	var v: int = int(c.r8) | (int(c.g8) << 8) | (int(c.b8) << 16) | (clampi(int(a * 255.0), 0, 255) << 24)
	if v >= 0x80000000:
		v -= 0x100000000
	return v


## Nächste Kachel mit owner[i] == key um (px, py) (Spirale bis 40 Kacheln), sonst (px, py).
func _snap_own(px: int, py: int, key: int, owner: PackedInt32Array) -> Vector2i:
	px = clampi(px, 0, W - 1)
	py = clampi(py, 0, H - 1)
	if owner[py * W + px] == key:
		return Vector2i(px, py)
	for rr: int in range(1, 40):
		for k: int in range(-rr, rr + 1):
			for p: Vector2i in [Vector2i(px + k, py - rr), Vector2i(px + k, py + rr), Vector2i(px - rr, py + k), Vector2i(px + rr, py + k)]:
				if in_map(p.x, p.y) and owner[p.y * W + p.x] == key:
					return p
	return Vector2i(px, py)


## Ebene „Regionen“: die fünf Regionen in eigenen Farben mit Rand.
func _region_layer() -> void:
	_region_px(0, 0, W, H)


## Regionen-Ebene nur in einem Rechteck neu zeichnen (Regionen-Pinsel); wirkt nur, wenn die Ebene „Regionen“ aktiv ist.
func region_layer_rect(x0: int, y0: int, x1: int, y1: int) -> void:
	if layer != 2:
		return
	x0 = clampi(x0, 0, W)
	y0 = clampi(y0, 0, H)
	x1 = clampi(x1, 0, W)
	y1 = clampi(y1, 0, H)
	if x1 <= x0 or y1 <= y0:
		return
	terr_img.fill_rect(Rect2i(x0, y0, x1 - x0, y1 - y0), Color(0, 0, 0, 0))
	_region_px(x0, y0, x1, y1)
	terr_tex.update(terr_img)


func _region_px(x0: int, y0: int, x1: int, y1: int) -> void:
	for y: int in range(y0, y1):
		for x: int in range(x0, x1):
			var i: int = y * W + x
			if tile[i] == GuData.WALL:
				continue
			var r: int = region[i]
			var border: bool = (x > 0 and region[i - 1] != r) or (x < W - 1 and region[i + 1] != r) or (y > 0 and region[i - W] != r) or (y < H - 1 and region[i + W] != r)
			if not border and x > 1 and x < W - 2 and y > 1 and y < H - 2:
				border = tile[i - 1] == GuData.WALL or tile[i + 1] == GuData.WALL or tile[i - W] == GuData.WALL or tile[i + W] == GuData.WALL
			var col: Color = REG_COL[r]
			col.a = 0.95 if border else (0.12 if GuData.is_water(tile[i]) else 0.42)
			terr_img.set_pixel(x, y, col)
