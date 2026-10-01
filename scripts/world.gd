class_name World
extends RefCounted
## Kartendaten der Gu-Welt (eine Kachel = ein Pixel) und ihre Bilder für nah, fern und Clan-Gebiete.

const W: int = GuData.W
const H: int = GuData.H
const N: int = GuData.N
const CHK: int = 32
const CXN: int = W / CHK

var tile: PackedByteArray
var feat: PackedByteArray
var region: PackedByteArray
var hgt: PackedFloat32Array
var bmap: PackedInt32Array
var terr: PackedInt32Array
var temp_snow: PackedByteArray
var wdist: PackedByteArray

## Benannte Orte der kanonischen Gu-Weltkarte (Modus "gu"); kind: siedlung (Bauland), berg, fluss, ort, gebiet.
const LANDMARKS: Array = [
	{"name": "Himmlischer Hof", "x": 124, "y": 130, "region": 4, "kind": "siedlung"},
	{"name": "Unsterblicher-Kranich-Sekte", "x": 154, "y": 134, "region": 4, "kind": "siedlung"},
	{"name": "Geistaffinitätshaus", "x": 110, "y": 140, "region": 4, "kind": "siedlung"},
	{"name": "Gu-Yue-Dorf", "x": 78, "y": 213, "region": 1, "kind": "siedlung"},
	{"name": "Qing-Mao-Berg", "x": 80, "y": 205, "region": 1, "kind": "berg"},
	{"name": "Shang-Clan-Stadt", "x": 142, "y": 233, "region": 1, "kind": "siedlung"},
	{"name": "Bai-Gu-Berg", "x": 176, "y": 230, "region": 1, "kind": "berg"},
	{"name": "Roter Drachenfluss", "x": 62, "y": 214, "region": 1, "kind": "fluss"},
	{"name": "Gelber Drachenfluss", "x": 124, "y": 208, "region": 1, "kind": "fluss"},
	{"name": "Jadedrachenfluss", "x": 190, "y": 212, "region": 1, "kind": "fluss"},
	{"name": "Kaiserhof-Gesegnetes-Land", "x": 150, "y": 52, "region": 0, "kind": "siedlung"},
	{"name": "Lang-Ya-Gesegnetes-Land", "x": 86, "y": 58, "region": 0, "kind": "ort"},
	{"name": "Große Oase", "x": 50, "y": 104, "region": 2, "kind": "siedlung"},
	{"name": "Unpassierbare Dünen", "x": 34, "y": 166, "region": 2, "kind": "gebiet"},
]

## Kartenart der aktuellen Welt ("gu" oder "random") und ihre benannten Orte (leer bei "random").
var map_mode: String = "gu"
var landmarks: Array[Dictionary] = []

var near_img: Image
var far_img: Image
var terr_img: Image
var near_tex: ImageTexture
var far_tex: ImageTexture
var terr_tex: ImageTexture
var dirty: PackedByteArray
var water_dirty: bool = false


func _init() -> void:
	Sprites.init()
	_set_landmarks("gu")
	alloc()
	near_img = Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	far_img = Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	terr_img = Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	near_tex = ImageTexture.create_from_image(near_img)
	far_tex = ImageTexture.create_from_image(far_img)
	terr_tex = ImageTexture.create_from_image(terr_img)
	dirty = PackedByteArray()
	dirty.resize(CXN * CXN)


func alloc() -> void:
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


func compute_water() -> void:
	wdist.fill(255)
	var q: PackedInt32Array = PackedInt32Array()
	q.resize(N)
	var qh: int = 0
	var qt: int = 0
	for i: int in range(N):
		if not GuData.is_water(tile[i]):
			wdist[i] = 0
			q[qt] = i
			qt += 1
	while qh < qt:
		var i: int = q[qh]
		qh += 1
		var d: int = wdist[i]
		if d >= 40:
			continue
		var x: int = i % W
		var y: int = i / W
		for j: int in [i - 1 if x > 0 else -1, i + 1 if x < W - 1 else -1, i - W if y > 0 else -1, i + W if y < H - 1 else -1]:
			if j >= 0 and wdist[j] == 255:
				wdist[j] = d + 1
				q[qt] = j
				qt += 1


func _set_landmarks(mode: String) -> void:
	map_mode = mode
	landmarks.clear()
	if mode == "gu":
		for l: Dictionary in LANDMARKS:
			landmarks.append(l.duplicate())


## mode "gu": kanonische Gu-Weltkarte (Form fest, Samen ändert nur Details); "random": Zufallswelt.
func generate(S: int, mode: String = "gu") -> void:
	alloc()
	var open_sea: PackedByteArray = PackedByteArray()
	if mode == "random":
		_base_random(S)
	else:
		mode = "gu"
		open_sea = MapGu.build(self, S)
	_set_landmarks(mode)
	_finish(S, open_sea)


## Grundgelände der Zufallswelt (Regionen, Höhen, Kacheln) – unveränderter Algorithmus.
func _base_random(S: int) -> void:
	var nw: FastNoiseLite = _noise(S + 5, 0.022, 4)
	var nw2: FastNoiseLite = _noise(S + 9, 0.022, 4)
	var ne: FastNoiseLite = _noise(S, 0.025, 5)
	var ne2: FastNoiseLite = _noise(S + 33, 0.06, 3)
	var nedge: FastNoiseLite = _noise(S + 123, 0.03, 3)
	var nr1: FastNoiseLite = _noise(S + 71, 0.028, 4)
	var nr4: FastNoiseLite = _noise(S + 91, 0.022, 4)
	var nisl: FastNoiseLite = _noise(S + 201, 0.05, 4)
	for y: int in range(H):
		for x: int in range(W):
			var i: int = y * W + x
			var wob: float = (n01(nw, x, y) - 0.5) * 46.0
			var wob2: float = (n01(nw2, x + 40, y) - 0.5) * 40.0
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
func _finish(S: int, open_sea: PackedByteArray) -> void:
	compute_water()
	for i: int in range(N):
		if tile[i] == GuData.DEEP and wdist[i] <= 8:
			tile[i] = GuData.SHAL
	# Regionswände
	for y: int in range(H):
		for x: int in range(W):
			var i: int = y * W + x
			var r: int = region[i]
			var b: bool = (x > 0 and region[i - 1] != r) or (x < W - 1 and region[i + 1] != r)
			if not b and y > 0:
				var k: int = i - W
				b = region[k] != r or (x > 0 and region[k - 1] != r) or (x < W - 1 and region[k + 1] != r)
			if not b and y < H - 1:
				var k2: int = i + W
				b = region[k2] != r or (x > 0 and region[k2 - 1] != r) or (x < W - 1 and region[k2 + 1] != r)
			if b and (open_sea.is_empty() or open_sea[i] == 0 or wdist[i] <= 10):
				tile[i] = GuData.WALL
	# Strand mit Zacken
	var sand: PackedByteArray = PackedByteArray()
	sand.resize(N)
	for y: int in range(H):
		for x: int in range(W):
			var i: int = y * W + x
			var t: int = tile[i]
			if not GuData.is_land(t) or t == GuData.WALL or t == GuData.SNOW:
				continue
			# Wasser = DEEP (0) oder SHAL (1)
			var w: bool = (x > 0 and tile[i - 1] <= GuData.SHAL) or (x < W - 1 and tile[i + 1] <= GuData.SHAL)
			if not w and y > 0:
				var k: int = i - W
				w = tile[k] <= GuData.SHAL or (x > 0 and tile[k - 1] <= GuData.SHAL) or (x < W - 1 and tile[k + 1] <= GuData.SHAL)
			if not w and y < H - 1:
				var k2: int = i + W
				w = tile[k2] <= GuData.SHAL or (x > 0 and tile[k2 - 1] <= GuData.SHAL) or (x < W - 1 and tile[k2 + 1] <= GuData.SHAL)
			if w:
				sand[i] = 1
	for i: int in range(N):
		if sand[i] == 1 and tile[i] != GuData.DES and tile[i] != GuData.MOUNT:
			tile[i] = GuData.SAND
			var x: int = i % W
			var y: int = i / W
			if GuData.hash2(x, y, S + 3) < 0.3 and y > 1 and tile[i - W] != GuData.WALL and GuData.is_land(tile[i - W]) and sand[i - W] == 0:
				tile[i - W] = GuData.SAND
				if GuData.hash2(x, y, S + 4) < 0.45 and GuData.is_land(tile[i - 2 * W]) and tile[i - 2 * W] != GuData.WALL:
					tile[i - 2 * W] = GuData.SAND
	compute_water()
	# Pflanzen, Felsen, Adern
	var nf: FastNoiseLite = _noise(S + 55, 0.045, 3)
	for y: int in range(H):
		for x: int in range(W):
			var i: int = y * W + x
			var t: int = tile[i]
			var r: int = region[i]
			var f: float = n01(nf, x, y)
			var q: float = GuData.hash2(x, y, S + 999)
			var q2: float = GuData.hash2(x, y, S + 4)
			var ft: int = 0
			if t == GuData.GRASS:
				if r == 1:
					if f > 0.47:
						if q < 0.011:
							ft = GuData.F_BAMB if (f > 0.62 and q2 < 0.45) else GuData.F_TREE
					elif q < 0.006:
						ft = GuData.F_TREE
					if q > 0.9995:
						ft = GuData.F_SPRING
				elif r == 4:
					if f > 0.5:
						if q < 0.008:
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
			feat[i] = ft


# ---------------- Zeichnen ----------------

var _fbm_water: FastNoiseLite = null


func tile_color(x: int, y: int) -> Color:
	var i: int = y * W + x
	var t: int = tile[i]
	var n: float = GuData.hash2(x, y, 13)
	var k: int = 0 if n < 0.4 else (1 if n < 0.75 else 2)
	var c: Color
	if t == GuData.DEEP or t == GuData.SHAL:
		if _fbm_water == null:
			_fbm_water = _noise(11, 0.09, 2)
		var nn: float = GuData.hash2(x >> 1, y >> 1, 5)
		var d: float = wdist[i] + (n01(_fbm_water, x, y) - 0.5) * 9.0
		if wdist[i] <= 1:
			c = Color8(104, 202, 244)
		elif d <= 6:
			c = Color8(84, 186, 238)
		elif d <= 9:
			c = Color8(84, 186, 238) if nn < 0.5 else Color8(66, 156, 228)
		elif d <= 15:
			c = Color8(52, 124, 212) if nn < (d - 9.0) / 7.0 else Color8(66, 156, 228)
		else:
			var b: float = n01(_fbm_water, x * 0.8 + 300, y * 0.8)
			c = Color8(38, 94, 184) if b > 0.6 else (Color8(42, 102, 192) if (b > 0.55 and nn < 0.5) else Color8(46, 110, 200))
		if n > 0.985:
			c = c.lightened(0.1)
	elif t == GuData.GRASS:
		c = GuData.GRASSP[region[i]][k]
	elif t == GuData.WALL:
		var s: float = 1.18 if (x + y * 2) % 7 < 2 else 1.0
		c = Color8(int(176 * s), int(160 * s), mini(255, int(232 * s)))
		if n > 0.9:
			c = Color8(220, 210, 255)
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


func _render_rect(x0: int, y0: int, x1: int, y1: int) -> void:
	for y: int in range(y0, y1):
		for x: int in range(x0, x1):
			var c: Color = tile_color(x, y)
			near_img.set_pixel(x, y, c)
			far_img.set_pixel(x, y, c)
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
	_render_rect(0, 0, W, H)
	near_tex.update(near_img)
	far_tex.update(far_img)
	dirty.fill(0)


func mark_dirty(x: int, y: int) -> void:
	if not in_map(x, y):
		return
	dirty[(y / CHK) * CXN + (x / CHK)] = 1


## Ein Objekt auf (x, y) ragt nach oben und zur Seite – betroffene Blöcke neu zeichnen.
func mark_area(x: int, y: int) -> void:
	mark_dirty(x, y)
	mark_dirty(x, y - 15)
	mark_dirty(x - 6, y)
	mark_dirty(x + 6, y)
	mark_dirty(x, y + 1)
	mark_dirty(x - 6, y - 15)
	mark_dirty(x + 6, y - 15)


func flush_dirty(limit: int = 12) -> void:
	var n: int = 0
	for c: int in range(dirty.size()):
		if dirty[c] == 1:
			dirty[c] = 0
			var cx: int = (c % CXN) * CHK
			var cy: int = (c / CXN) * CHK
			_render_rect(cx, cy, cx + CHK, cy + CHK)
			n += 1
			if n >= limit:
				break
	if n > 0:
		near_tex.update(near_img)
		far_tex.update(far_img)


func refresh_water() -> void:
	compute_water()
	for i: int in range(N):
		var t: int = tile[i]
		if GuData.is_water(t):
			tile[i] = GuData.SHAL if wdist[i] <= 4 else GuData.DEEP
	dirty.fill(1)
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


func update_territory(villages: Array, clans: Array) -> void:
	terr.fill(-1)
	for v: Village in villages:
		if v == null or not v.alive:
			continue
		var r: int = mini(30, int(13 + v.houses * 1.4 + v.towers * 3))
		var cx: int = int(v.cx)
		var cy: int = int(v.cy)
		var rg: int = region[cy * W + cx]
		for dy: int in range(-r, r + 1):
			for dx: int in range(-r, r + 1):
				if dx * dx + dy * dy > r * r:
					continue
				var x: int = cx + dx
				var y: int = cy + dy
				if not in_map(x, y):
					continue
				var i: int = y * W + x
				if terr[i] < 0 and tile[i] != GuData.DEEP and tile[i] != GuData.WALL and region[i] == rg:
					terr[i] = v.id
	terr_img.fill(Color(0, 0, 0, 0))
	for y: int in range(H):
		for x: int in range(W):
			var i: int = y * W + x
			var t: int = terr[i]
			if t < 0:
				continue
			var v: Village = villages[t]
			var k: int = v.clan
			var cl: Clan = clans[k]
			var border: bool = (x == 0 or _clan_of(i - 1, villages) != k) or (x == W - 1 or _clan_of(i + 1, villages) != k) or (y == 0 or _clan_of(i - W, villages) != k) or (y == H - 1 or _clan_of(i + W, villages) != k)
			var col: Color = cl.col
			col.a = 0.9 if border else 0.13
			terr_img.set_pixel(x, y, col)
	terr_tex.update(terr_img)


func _clan_of(i: int, villages: Array) -> int:
	var t: int = terr[i]
	if t < 0:
		return -1
	return (villages[t] as Village).clan
