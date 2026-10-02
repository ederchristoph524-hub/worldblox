class_name Icons
extends RefCounted
## Pixel-Icons für Werkzeuge, Reiter und Knöpfe im WorldBox-Stil (dunkle Kontur, kräftige Farben).

static var _cache: Dictionary = {}

const Y: String = "#ffd23a"
const MINT: String = "#d2ecdb"


static func get_icon(id: String) -> ImageTexture:
	if _cache.has(id):
		return _cache[id]
	var px: Px = _make(id)
	var t: ImageTexture = px.tex()
	_cache[id] = t
	return t


static func _tile(t: int, extra: Callable = Callable()) -> Px:
	var q: Px = Px.new(24, 24)
	var pal: Array
	if t == GuData.GRASS:
		pal = GuData.GRASSP[2]
	elif t == GuData.DEEP:
		pal = [Color8(46, 110, 200), Color8(40, 100, 190), Color8(54, 128, 214)]
	elif t == GuData.SHAL:
		pal = [Color8(80, 184, 236), Color8(92, 196, 242), Color8(66, 154, 228)]
	elif t == GuData.WALL:
		pal = [Color8(176, 160, 232), Color8(200, 190, 250), Color8(160, 140, 220)]
	else:
		pal = GuData.PAL[t]
	for y: int in range(4, 20):
		for x: int in range(4, 20):
			if (x == 4 or x == 19) and (y == 4 or y == 19):
				continue
			var n: float = GuData.hash2(x, y, t * 7 + 1)
			q.p(x, y, 1, 1, pal[0 if n < 0.4 else (1 if n < 0.75 else 2)])
	q.p(5, 4, 14, 1, Color(1, 1, 1, 0.3))
	q.p(5, 19, 14, 1, Color(0, 0, 0, 0.3))
	if extra.is_valid():
		extra.call(q)
	return q.outline()


static func _cloud(q: Px, a: String, b: String) -> void:
	q.p(7, 5, 10, 3, a)
	q.p(4, 8, 16, 5, a)
	q.p(3, 10, 18, 3, a)
	q.p(5, 13, 14, 2, b)
	q.p(9, 4, 5, 1, a)


static func _make(id: String) -> Px:
	var q: Px = Px.new(24, 24)
	var gen: Px = _make_generated(id)
	if gen != null:
		return gen
	var par: Px = _make_parity(id)
	if par != null:
		return par
	var sb: Px = _make_sandbox(id)
	if sb != null:
		return sb
	match id:
		"t_deep":
			return _tile(GuData.DEEP)
		"t_shal":
			return _tile(GuData.SHAL)
		"t_sand":
			return _tile(GuData.SAND)
		"t_grass":
			return _tile(GuData.GRASS)
		"t_step":
			return _tile(GuData.STEP)
		"t_des":
			return _tile(GuData.DES)
		"t_soil":
			return _tile(GuData.SOIL)
		"t_snow":
			return _tile(GuData.SNOW)
		"t_hill":
			return _tile(GuData.GRASS, func(o: Px) -> void:
				for y: int in range(9, 19):
					var w: int = roundi((y - 8) * 0.9)
					o.p(12 - w, y, w * 2, 1, "#9a9c88" if y < 12 else "#7a7c6a"))
		"t_mount":
			return _tile(GuData.GRASS, func(o: Px) -> void:
				for y: int in range(4, 19):
					var w: int = roundi((y - 3) * 0.6)
					o.p(12 - w, y, w, 1, "#5a5d60")
					o.p(12, y, w, 1, "#46484b")
					if y < 8:
						o.p(12 - w, y, w * 2, 1, "#eef2f4"))
		"t_up":
			return _tile(GuData.GRASS, func(o: Px) -> void:
				o.p(11, 7, 3, 9, "#fff")
				o.p(8, 9, 9, 1, "#fff")
				o.p(9, 8, 7, 1, "#fff")
				o.p(10, 7, 5, 1, "#fff")
				o.p(11, 6, 3, 1, "#fff"))
		"t_down":
			return _tile(GuData.SHAL, func(o: Px) -> void:
				o.p(11, 6, 3, 9, "#fff")
				o.p(8, 13, 9, 1, "#fff")
				o.p(9, 14, 7, 1, "#fff")
				o.p(10, 15, 5, 1, "#fff")
				o.p(11, 16, 3, 1, "#fff"))
		"t_wall":
			q.p(8, 2, 8, 20, "#b8a6ee")
			q.p(8, 2, 3, 20, "#e0d6ff")
			q.p(14, 2, 2, 20, "#8a76c8")
			for y: int in range(4, 22, 5):
				q.p(9, y, 6, 1, "#f4f0ff")
			q.p(6, 20, 12, 2, "#7a68b0")
		"f_tree":
			q.draw_image(Sprites.tree_img[0], 1, 4)
			q.draw_image(Sprites.tree_img[7], 13, 9)
		"f_bamb":
			q.draw_image(Sprites.bamb_img, 7, 6)
		"f_ore":
			q.draw_image(_scaled(Sprites.ore_img, 3), 3, 6)
		"f_spring":
			q.draw_image(_scaled(Sprites.spring_img, 3), 3, 6)
		"f_clear":
			q.draw_image(Sprites.tree_img[0], 7, 4)
			for k: int in range(16):
				q.p(3 + k, 3 + k, 2, 2, "#e4503a")
				q.p(19 - k, 3 + k, 2, 2, "#e4503a")
		"winfo":
			q.d(10, 12, 8, "#2f7ad8")
			q.d(7, 9, 3, "#5ab84a")
			q.d(12, 15, 3, "#5ab84a")
			q.p(13, 7, 3, 2, "#5ab84a")
			for a: int in range(24):
				var an: float = a / 24.0 * TAU
				q.p(roundi(15 + cos(an) * 5), roundi(9 + sin(an) * 5), 2, 2, "#cfe8f0")
			q.p(18, 14, 2, 2, "#7a5030")
			q.p(20, 16, 2, 2, "#7a5030")
			q.p(21, 18, 2, 2, "#5a3a20")
		"help":
			q.p(2, 5, 10, 15, "#efe2b8")
			q.p(12, 5, 10, 15, "#e2d4a8")
			q.p(11, 5, 2, 16, "#b8a070")
			for y: int in range(8, 18, 2):
				q.p(4, y, 6, 1, "#9a8a60")
				q.p(14, y, 6, 1, "#9a8a60")
			q.p(1, 19, 22, 2, "#d4a83a")
		"chron":
			q.p(4, 13, 16, 8, "#b83a2a")
			q.p(4, 13, 16, 2, "#d65a3a")
			q.p(6, 15, 12, 1, "#f0c040")
			q.p(5, 20, 14, 1, "#7a2418")
			q.p(8, 2, 8, 2, "#c9a040")
			q.p(8, 10, 8, 2, "#c9a040")
			q.p(9, 4, 6, 2, "#e8f0f4")
			q.p(10, 6, 4, 2, "#e8c870")
			q.p(11, 8, 2, 2, "#e8c870")
		"laws":
			q.p(4, 4, 16, 16, "#efe2b8")
			q.p(3, 3, 18, 3, "#c8a060")
			q.p(3, 18, 18, 3, "#c8a060")
			for y: int in range(8, 16, 2):
				q.p(6, y, 10, 1, "#7a6a48")
			q.p(14, 13, 5, 5, "#c8402a")
			q.p(15, 14, 3, 3, "#f0d0c0")
		"disp":
			q.d(12, 12, 8, "#8e9890")
			q.d(12, 12, 4, "#4a5250")
			q.d(12, 12, 2, "#2a302e")
			for k: int in range(8):
				var a2: float = k * 0.785
				q.p(12 + roundi(cos(a2) * 9) - 1, 12 + roundi(sin(a2) * 9) - 1, 3, 3, "#8e9890")
		"rank":
			q.p(3, 9, 18, 9, Y)
			q.p(3, 4, 3, 6, Y)
			q.p(10, 3, 4, 7, Y)
			q.p(18, 4, 3, 6, Y)
			q.p(3, 17, 18, 3, "#c9962a")
			q.p(6, 12, 3, 3, "#e8303a")
			q.p(11, 12, 3, 3, "#4fb0ff")
			q.p(16, 12, 3, 3, "#43b38f")
			q.p(4, 9, 16, 1, "#fff0a0")
		"stats", "stats2":
			q.p(2, 3, 20, 14, "#e8ecdc")
			q.p(2, 3, 20, 2, "#c8ccbc")
			q.p(11, 17, 2, 5, "#5a4a3a")
			q.p(7, 21, 10, 1, "#5a4a3a")
			for pt: Vector2i in [Vector2i(4, 13), Vector2i(7, 10), Vector2i(10, 12), Vector2i(13, 7), Vector2i(16, 9)]:
				q.p(pt.x, pt.y, 3, 1, "#d8402a")
			for pt: Vector2i in [Vector2i(4, 9), Vector2i(7, 12), Vector2i(10, 8), Vector2i(13, 11), Vector2i(16, 12), Vector2i(19, 10)]:
				q.p(pt.x, pt.y, 3, 1, "#3a7ad8")
		"ages":
			q.d(12, 12, 9, "#1e2a50")
			q.d(8, 9, 4, "#ffd23a")
			q.d(16, 15, 3, "#d8e4ff")
			q.d(17, 14, 2, "#1e2a50")
			q.p(3, 19, 18, 3, "#5ab84a")
		"save":
			q.p(3, 3, 18, 18, "#4fae8f")
			q.p(3, 3, 18, 2, "#7ed4b4")
			q.p(6, 3, 12, 7, "#d8f0e8")
			q.p(14, 4, 3, 5, "#4fae8f")
			q.p(6, 13, 12, 7, "#2f7a64")
			q.p(8, 15, 8, 1, "#9fe0c8")
			q.p(8, 17, 6, 1, "#9fe0c8")
		"load":
			q.p(3, 7, 18, 14, "#4fae8f")
			q.p(3, 7, 18, 2, "#7ed4b4")
			q.p(10, 2, 4, 9, "#fff")
			q.p(7, 8, 10, 1, "#fff")
			q.p(8, 9, 8, 1, "#fff")
			q.p(9, 10, 6, 1, "#fff")
			q.p(6, 15, 12, 1, "#2f7a64")
		"new":
			q.d(12, 12, 8, "#2f7ad8")
			q.d(9, 10, 3, "#5ab84a")
			q.d(15, 15, 2, "#5ab84a")
			q.p(18, 2, 2, 6, Y)
			q.p(16, 4, 6, 2, Y)
			q.p(3, 17, 2, 4, Y)
			q.p(2, 18, 4, 2, Y)
		"hideui":
			q.p(4, 9, 16, 7, "#e8eef0")
			q.p(2, 11, 20, 3, "#e8eef0")
			q.p(9, 9, 6, 7, "#3a7ad8")
			q.p(11, 11, 2, 3, "#101414")
			for k: int in range(16):
				q.p(3 + k, 4 + k, 2, 2, "#e4503a")
		"inspect":
			var tx: Dictionary = Sprites.clan_textures(Color("#2f6fd6"))
			q.draw_image((tx["house"] as ImageTexture).get_image(), 4, 5)
			for a3: int in range(28):
				var an3: float = a3 / 28.0 * TAU
				q.p(roundi(10 + cos(an3) * 7), roundi(10 + sin(an3) * 7), 2, 2, "#cfe8f0")
			q.p(15, 16, 3, 3, "#8a5a30")
			q.p(18, 19, 3, 3, "#6a4428")
		"ally":
			q.p(2, 4, 6, 8, "#3a5ad8")
			q.p(16, 4, 6, 8, "#e8e8e8")
			q.p(3, 2, 4, 3, "#2a3a98")
			q.p(17, 2, 4, 3, "#a8a8a8")
			q.p(5, 10, 14, 6, "#e8b088")
			q.p(7, 9, 10, 2, "#f0c098")
			q.p(8, 12, 2, 2, "#c88a68")
			q.p(11, 12, 2, 2, "#c88a68")
			q.p(14, 12, 2, 2, "#c88a68")
			q.p(6, 16, 12, 2, "#b07a58")
		"feud":
			q.d(7, 9, 5, "#d0603a")
			q.d(16, 15, 5, "#d0603a")
			for pt: Vector2i in [Vector2i(5, 8), Vector2i(9, 8), Vector2i(14, 14), Vector2i(18, 14)]:
				q.p(pt.x, pt.y, 2, 1, "#2a1008")
			q.p(5, 11, 4, 1, "#2a1008")
			q.p(14, 17, 4, 1, "#2a1008")
			q.p(14, 2, 2, 6, "#d8d8d8")
			q.p(13, 7, 4, 1, "#7a5030")
			q.p(3, 17, 2, 5, "#d8d8d8")
			q.p(2, 16, 4, 1, "#7a5030")
		"discord":
			q.p(4, 3, 2, 19, "#7a5030")
			q.p(6, 4, 12, 9, "#c03a2a")
			q.p(6, 4, 12, 2, "#e05a3a")
			q.p(14, 2, 4, 4, "#ff9a2a")
			q.p(16, 1, 3, 3, Y)
			q.p(12, 6, 3, 3, Y)
			q.p(17, 8, 3, 4, "#ff6a1a")
		"peace":
			q.d(7, 10, 5, "#f0c850")
			q.d(16, 15, 5, "#f0c850")
			for pt: Vector2i in [Vector2i(5, 9), Vector2i(9, 9), Vector2i(14, 14), Vector2i(18, 14)]:
				q.p(pt.x, pt.y, 1, 2, "#3a2a10")
			q.p(5, 12, 4, 1, "#3a2a10")
			q.p(14, 17, 4, 1, "#3a2a10")
			q.p(17, 3, 2, 2, "#e8506a")
			q.p(20, 3, 2, 2, "#e8506a")
			q.p(17, 5, 5, 2, "#e8506a")
			q.p(18, 7, 3, 1, "#e8506a")
		"demon":
			q.p(10, 3, 4, 9, "#f4f0e0")
			q.p(11, 1, 2, 2, Y)
			q.p(5, 10, 14, 4, "#c02a2a")
			q.p(4, 14, 16, 4, "#a01e1e")
			q.p(6, 18, 12, 3, "#c02a2a")
			q.p(3, 7, 5, 5, "#d03a2a")
			q.p(4, 8, 1, 1, Y)
			q.p(2, 11, 3, 1, "#f4f0e0")
		"tide":
			var a4: Px = Px.new(20, 20)
			var sink: Callable = func(r: Rect2, c: Color) -> void: a4.p(roundi(r.position.x), roundi(r.position.y), maxi(1, roundi(r.size.x)), maxi(1, roundi(r.size.y)), c)
			Sprites.draw_animal(sink, 6.0, 9.0, 1.0, "wolf", 1, false, 1.0, false, true, 1)
			Sprites.draw_animal(sink, 13.0, 16.0, 1.0, "wolf", 1, false, 1.0, false, true, 2)
			a4.p(16, 1, 2, 5, "#e4503a")
			a4.p(16, 7, 2, 2, "#e4503a")
			return a4.outline()
		"s_wildgu":
			var g: Px = Px.new(20, 20)
			var gcs: Array[Color] = [GuData.PATH_COL[1], GuData.PATH_COL[2], GuData.PATH_COL[6], GuData.PATH_COL[8], GuData.PATH_COL[11]]
			var gi: int = 0
			for pt: Vector2i in [Vector2i(4, 6), Vector2i(11, 4), Vector2i(15, 11), Vector2i(7, 13), Vector2i(12, 16)]:
				g.p(pt.x - 1, pt.y - 1, 4, 4, Color(gcs[gi], 0.5))
				g.p(pt.x, pt.y, 2, 2, gcs[gi].lightened(0.5))
				gi += 1
			return g
		"w_rain":
			_cloud(q, "#9aa2ac", "#6a727c")
			for k: int in range(5):
				q.p(5 + k * 3, 16 + (k % 2) * 2, 1, 3, "#5ab0ff")
		"w_snow":
			_cloud(q, "#e4e8ee", "#aab2bc")
			for k: int in range(5):
				q.p(5 + k * 3, 16 + (k % 2) * 3, 2, 2, "#ffffff")
		"w_drought":
			q.d(12, 12, 5, "#ffb43a")
			q.d(11, 11, 2, "#fff0c0")
			for k: int in range(8):
				var a5: float = k * 0.785
				q.p(12 + roundi(cos(a5) * 9) - 1, 12 + roundi(sin(a5) * 9) - 1, 2, 2, "#ffd27a")
		"w_sand":
			var cols: Array[String] = ["#e8c080", "#d8a860", "#c89048", "#b88040"]
			for k: int in range(4):
				q.p(3 + k, 5 + k * 4, 16 - k * 2, 2, cols[k])
			q.p(16, 7, 4, 2, "#e8c080")
		"bloom":
			q.p(11, 12, 2, 9, "#4e8a36")
			q.p(6, 15, 5, 2, "#6aaa44")
			q.p(13, 14, 5, 2, "#6aaa44")
			q.p(8, 4, 8, 7, "#ff8ac0")
			q.p(9, 3, 6, 9, "#ff8ac0")
			q.p(11, 6, 2, 2, "#ffe27a")
		"bolt":
			for pt: Vector2i in [Vector2i(13, 1), Vector2i(12, 3), Vector2i(11, 5), Vector2i(10, 7), Vector2i(9, 9), Vector2i(12, 9), Vector2i(11, 11), Vector2i(10, 13), Vector2i(9, 15), Vector2i(8, 17), Vector2i(7, 19)]:
				q.p(pt.x, pt.y, 3, 2, "#fff27a")
			q.p(10, 9, 5, 1, "#fff27a")
		"quake":
			q.p(1, 9, 22, 12, "#8a6a42")
			q.p(1, 9, 22, 2, "#6aa046")
			for pt: Vector2i in [Vector2i(11, 10), Vector2i(12, 11), Vector2i(11, 12), Vector2i(12, 13), Vector2i(13, 14), Vector2i(12, 15), Vector2i(11, 16), Vector2i(12, 17), Vector2i(13, 18), Vector2i(12, 19)]:
				q.p(pt.x, pt.y, 2, 1, "#1a100a")
			q.p(4, 4, 2, 2, "#c9a46a")
			q.p(17, 3, 2, 2, "#c9a46a")
		"trib":
			_cloud(q, "#5a4a7a", "#3a2a5a")
			for pt: Vector2i in [Vector2i(11, 13), Vector2i(10, 15), Vector2i(12, 16), Vector2i(11, 18), Vector2i(10, 20)]:
				q.p(pt.x, pt.y, 3, 2, "#d8b8ff")
		"plague":
			q.p(8, 7, 8, 10, "#5aa83a")
			q.p(9, 6, 6, 1, "#5aa83a")
			q.p(10, 9, 1, 2, "#1a3a10")
			q.p(13, 9, 1, 2, "#1a3a10")
			q.p(5, 10, 3, 1, "#3a7a2a")
			q.p(16, 10, 3, 1, "#3a7a2a")
			q.p(5, 14, 3, 1, "#3a7a2a")
			q.p(16, 14, 3, 1, "#3a7a2a")
			q.p(3, 3, 2, 2, "#86e04a")
			q.p(18, 3, 2, 2, "#86e04a")
			q.p(19, 18, 2, 2, "#86e04a")
		"fire":
			for r: Array in [[11, 2, 2], [10, 4, 4], [8, 6, 7], [7, 8, 9], [6, 10, 11], [6, 12, 12], [6, 14, 12], [7, 16, 10], [8, 18, 8]]:
				q.p(r[0], r[1], r[2], 2, "#e4402a")
			for r: Array in [[11, 8, 2], [10, 10, 4], [9, 12, 6], [9, 14, 6], [10, 16, 4]]:
				q.p(r[0], r[1], r[2], 2, "#ff9a2a")
			q.p(11, 14, 2, 3, "#ffe27a")
		"det":
			for k: int in range(8):
				var a6: float = k * 0.785
				for dd: int in range(5, 10):
					q.p(12 + roundi(cos(a6) * dd) - 1, 12 + roundi(sin(a6) * dd) - 1, 2, 2, "#fff27a" if dd < 7 else "#ff8a3a")
			q.p(10, 8, 4, 8, "#9affb0")
			q.p(9, 9, 1, 6, "#e8fff0")
			q.p(14, 9, 1, 6, "#e8fff0")
		"cres":
			for y: int in range(24):
				for x: int in range(24):
					var in1: bool = Vector2(x - 12, y - 12).length() <= 9.0
					var in2: bool = Vector2(x - 16, y - 8).length() <= 8.0
					if in1 and not in2:
						q.p(x, y, 1, 1, "#d8eeff")
		"meteor":
			for k: int in range(8):
				q.p(2 + k, 2 + k, 3, 3, "#ffe27a" if k < 3 else "#ff8a3a")
			q.p(10, 10, 9, 9, "#6a5a50")
			q.p(11, 11, 4, 3, "#8a7a6e")
			q.p(16, 16, 2, 2, "#4a3a32")
		"wrath":
			q.d(12, 13, 9, "#ff6a2a")
			q.d(12, 13, 6, "#ffb43a")
			q.d(12, 13, 3, "#fff4c0")
			q.p(10, 2, 4, 4, "#ffb43a")
			q.p(3, 20, 18, 3, "#5a4a40")
		"will":
			q.p(3, 9, 18, 7, "#f4f0e0")
			q.p(1, 11, 22, 3, "#f4f0e0")
			q.p(9, 8, 6, 9, "#b98cff")
			q.p(11, 10, 2, 5, "#1a1020")
			for k: int in range(5):
				q.p(4 + k * 4, 3, 2, 3, Y)
			q.p(4, 19, 16, 2, Y)
		"smite":
			q.p(7, 10, 11, 10, "#f4f0e0")
			q.p(7, 4, 2, 8, "#f4f0e0")
			q.p(10, 2, 2, 9, "#f4f0e0")
			q.p(13, 3, 2, 8, "#f4f0e0")
			q.p(16, 5, 2, 7, "#f4f0e0")
			q.p(4, 11, 3, 5, "#f4f0e0")
			q.p(9, 18, 8, 2, "#d8d0b8")
		"hope":
			q.p(3, 3, 18, 18, Color(1, 0.89, 0.48, 0.4))
			q.p(10, 6, 4, 12, "#f4d26a")
			q.p(11, 5, 2, 1, "#f4d26a")
			q.p(6, 8, 4, 5, "#fff8e0")
			q.p(14, 8, 4, 5, "#fff8e0")
			q.p(11, 9, 2, 1, "#c89a3a")
			q.p(11, 13, 2, 1, "#c89a3a")
		"enlight":
			q.p(10, 4, 4, 8, "#ffb0d0")
			q.p(5, 8, 5, 6, "#ff90c0")
			q.p(14, 8, 5, 6, "#ff90c0")
			q.p(3, 13, 18, 3, "#f070a8")
			q.p(8, 16, 8, 3, "#4e8a36")
			q.p(11, 1, 2, 2, "#fff4c0")
			q.p(4, 4, 2, 2, "#fff4c0")
			q.p(18, 4, 2, 2, "#fff4c0")
		"luck":
			q.d(12, 12, 8, Y)
			q.d(12, 12, 6, "#f0b030")
			q.p(10, 10, 4, 4, "#3a2a10")
			q.p(7, 6, 3, 1, "#fff6c0")
		"life":
			q.d(12, 13, 8, "#ffb0a0")
			q.d(10, 11, 5, "#ffd0c0")
			q.p(12, 5, 1, 10, "#e88070")
			q.p(12, 2, 2, 4, "#6a4a2a")
			q.p(14, 3, 6, 3, "#5aa83a")
		"stones":
			for pt: Vector2i in [Vector2i(3, 13), Vector2i(10, 9), Vector2i(14, 15), Vector2i(7, 17)]:
				q.p(pt.x, pt.y, 7, 5, "#eef8f2")
				q.p(pt.x, pt.y + 4, 7, 1, "#a8c4b8")
				q.p(pt.x + 1, pt.y + 1, 2, 1, "#ffffff")
			q.p(5, 3, 1, 4, "#cfe8ff")
			q.p(12, 1, 1, 4, "#cfe8ff")
			q.p(18, 4, 1, 4, "#cfe8ff")
		# --- feste Knöpfe ---
		"back":
			var b: Px = Px.new(20, 20)
			for r: Array in [[1, 6, 3, 1], [2, 5, 3, 3], [3, 4, 3, 5], [4, 3, 2, 7], [5, 5, 10, 3], [14, 6, 3, 2], [16, 7, 3, 8], [15, 14, 3, 2], [7, 15, 10, 3], [5, 15, 3, 2]]:
				b.p(r[0], r[1], r[2], r[3], "#f6ecd4")
			return b.outline()
		"pause":
			var pz: Px = Px.new(22, 22)
			pz.p(5, 3, 5, 16, "#18a8d0")
			pz.p(13, 3, 5, 16, "#18a8d0")
			pz.p(5, 3, 2, 16, "#5ad8f8")
			pz.p(13, 3, 2, 16, "#5ad8f8")
			return pz.outline()
		"play":
			var pl: Px = Px.new(22, 22)
			for k: int in range(16):
				pl.p(6, 3 + k, roundi((k if k < 8 else 15 - k) * 1.3) + 1, 1, "#5ad89c")
			return pl.outline()
		"speed":
			var s: Px = Px.new(22, 22)
			s.p(4, 1, 14, 2, "#c99a45")
			s.p(4, 19, 14, 2, "#c99a45")
			s.p(5, 3, 12, 3, "#e8eef0")
			s.p(6, 6, 10, 2, "#e8eef0")
			s.p(8, 8, 6, 2, "#e8eef0")
			s.p(10, 10, 2, 1, "#e8eef0")
			s.p(8, 11, 6, 2, "#e8eef0")
			s.p(6, 13, 10, 3, "#e8eef0")
			s.p(5, 16, 12, 3, "#e8eef0")
			s.p(7, 15, 8, 4, "#e8c050")
			s.p(9, 6, 4, 2, "#e8c050")
			s.p(10, 10, 2, 4, "#e8c050")
			return s.outline()
		"x":
			var xx: Px = Px.new(22, 22)
			for k: int in range(14):
				xx.p(3 + k, 3 + k, 3, 3, "#e8361e")
				xx.p(16 - k, 3 + k, 3, 3, "#e8361e")
			return xx
		"star":
			for r: Array in [[11, 1, 2], [10, 3, 4], [10, 5, 4], [2, 7, 20], [4, 9, 16], [6, 11, 12], [6, 13, 12], [5, 15, 14], [4, 17, 6], [14, 17, 6], [3, 19, 4], [17, 19, 4]]:
				q.p(r[0], r[1], r[2], 2, "#ffd82a")
			q.p(4, 7, 16, 1, "#fff27a")
			q.p(9, 10, 2, 2, "#2a1a08")
			q.p(13, 10, 2, 2, "#2a1a08")
			q.p(9, 14, 6, 1, "#c8402a")
		"gift":
			q.p(4, 10, 16, 11, "#f3eadc")
			q.p(3, 7, 18, 4, "#ffffff")
			q.p(11, 7, 3, 14, "#d23a2a")
			q.p(4, 14, 16, 3, "#d23a2a")
			q.p(6, 3, 5, 4, "#d23a2a")
			q.p(13, 3, 5, 4, "#d23a2a")
			q.p(7, 4, 3, 2, "#f3eadc")
			q.p(14, 4, 3, 2, "#f3eadc")
			q.p(4, 20, 16, 1, "#c8bca8")
		# --- Reiter ---
		"tab0":
			var t0: Px = Px.new(32, 16)
			for m: Array in [[2, 14, 8], [11, 13, 10], [22, 14, 8]]:
				for y: int in range(m[2] + 3):
					var w: int = roundi(y * 0.85)
					t0.p(int(m[0] + m[2] / 1.3) - w, m[1] - m[2] + y, w * 2 + 1, 1, MINT)
			t0.p(0, 14, 32, 2, MINT)
			return t0
		"tab1":
			var t1: Px = Px.new(32, 16)
			for p2: Vector2i in [Vector2i(6, 0), Vector2i(16, -1), Vector2i(26, 0)]:
				t1.p(p2.x - 2, 6 + p2.y, 4, 3, MINT)
				t1.p(p2.x - 3, 10 + p2.y, 6, 6, MINT)
			t1.p(13, 1, 1, 2, MINT)
			t1.p(18, 1, 1, 2, MINT)
			t1.p(14, 0, 4, 1, MINT)
			return t1
		"tab2":
			var t2: Px = Px.new(32, 16)
			t2.p(8, 5, 14, 8, MINT)
			t2.p(7, 6, 16, 6, MINT)
			t2.p(21, 3, 6, 7, MINT)
			t2.p(26, 6, 3, 2, "#1a201c")
			t2.p(23, 5, 1, 1, "#1a201c")
			t2.p(9, 13, 2, 3, MINT)
			t2.p(19, 13, 2, 3, MINT)
			t2.p(5, 6, 2, 2, MINT)
			return t2
		"tab3":
			var t3: Px = Px.new(32, 16)
			t3.p(8, 3, 14, 3, MINT)
			t3.p(5, 6, 22, 6, MINT)
			t3.p(10, 2, 7, 1, MINT)
			t3.p(17, 8, 3, 2, "#1a201c")
			t3.p(15, 10, 3, 2, "#1a201c")
			t3.p(13, 12, 3, 2, MINT)
			t3.p(11, 14, 3, 2, MINT)
			return t3
		"tab4":
			var t4: Px = Px.new(32, 16)
			for p3: Vector2i in [Vector2i(5, 5), Vector2i(14, 4), Vector2i(23, 5)]:
				t4.p(p3.x, p3.y + 3, 5, 9, MINT)
				t4.p(p3.x + 2, p3.y, 1, 3, MINT)
				t4.p(p3.x + 1, p3.y + 6, 3, 1, "#1a201c")
			return t4
		"tab5":
			var t5: Px = Px.new(32, 16)
			t5.p(6, 6, 4, 4, MINT)
			t5.p(14, 6, 4, 4, MINT)
			t5.p(22, 6, 4, 4, MINT)
			return t5
		"tab6":
			var t6: Px = Px.new(32, 16)
			t6.p(14, 4, 4, 4, MINT)
			t6.p(12, 8, 8, 6, MINT)
			t6.p(13, 14, 2, 2, MINT)
			t6.p(17, 14, 2, 2, MINT)
			t6.p(13, 1, 1, 2, MINT)
			t6.p(15, 0, 2, 3, MINT)
			t6.p(18, 1, 1, 2, MINT)
			for k: int in range(3):
				t6.p(6 - k * 2, 5 + k * 3, 3, 1, MINT)
				t6.p(23 + k * 2, 5 + k * 3, 3, 1, MINT)
			return t6
		_:
			pass
	return q.outline()


static func _scaled(src: Image, f: int) -> Image:
	var im: Image = src.duplicate()
	im.resize(src.get_width() * f, src.get_height() * f, Image.INTERPOLATE_NEAREST)
	return im


# ---------------- Erzeugte Icons (Völker, Gu-Meister, Bestien, Gu, Orte, Organisationen, Ereignisse) ----------------

static func _sink(q: Px) -> Callable:
	return func(r: Rect2, c: Color) -> void: q.p(roundi(r.position.x), roundi(r.position.y), maxi(1, roundi(r.size.x)), maxi(1, roundi(r.size.y)), c)


## Zeichnet eine Figur so groß wie möglich in 24 × 24 (deckende Pixel bestimmen die Größe).
## draw: Callable(sink, X, Y, sc). fill: Zielgröße in Pixeln.
static func _fit(draw: Callable, fill: float = 21.0, max_sc: float = 2.4) -> Px:
	Sprites.no_aura = true
	var big: Px = Px.new(128, 128)
	draw.call(_sink(big), 64.0, 92.0, 4.0)
	var x0: int = 999
	var y0: int = 999
	var x1: int = -1
	var y1: int = -1
	for y: int in range(128):
		for x: int in range(128):
			if big.img.get_pixel(x, y).a > 0.6:
				x0 = mini(x0, x)
				y0 = mini(y0, y)
				x1 = maxi(x1, x)
				y1 = maxi(y1, y)
	if x1 < 0:
		Sprites.no_aura = false
		return Px.new(24, 24)
	var bw: float = x1 - x0 + 1
	var bh: float = y1 - y0 + 1
	var k: float = minf(minf(fill / bw, fill / bh) * 4.0, max_sc)
	var q: Px = Px.new(24, 24)
	var ox: float = 12.0 - ((x0 + x1 + 1) / 2.0 - 64.0) * k / 4.0
	var oy: float = 12.0 - ((y0 + y1 + 1) / 2.0 - 92.0) * k / 4.0
	draw.call(_sink(q), ox, oy, k)
	Sprites.no_aura = false
	return q


static func _person_fit(race: int, rank: int, col: Color, ow: bool = false) -> Px:
	return _fit(func(sk: Callable, X: float, Yp: float, sc: float) -> void:
		Sprites.draw_person(sk, X, Yp, sc, race, rank, col, 1, true, false, 0.0, false, false, false, false, false, 0.0, 0.0, ow), 21.0, 2.6)


static func _animal_fit(sp: String, pth: int = -1) -> Px:
	return _fit(func(sk: Callable, X: float, Yp: float, sc: float) -> void:
		Sprites.draw_animal(sk, X, Yp, sc / float(GuData.SPEC[sp].get("ss", 1.0)), sp, 1, false, 1.0, false, false, 3, 0.0, pth), 22.0, 2.6)


## Heiligenschein-Ring in einer Farbe hinter der Figur (nur auf freien Pixeln).
static func _ring_behind(q: Px, col: Color) -> void:
	for k: int in range(48):
		var a: float = k / 48.0 * TAU
		for rr: float in [10.5, 11.0]:
			var x: int = 12 + roundi(cos(a) * rr)
			var y: int = 12 + roundi(sin(a) * rr)
			if x >= 0 and y >= 0 and x < 24 and y < 24 and q.img.get_pixel(x, y).a < 0.1:
				q.img.set_pixel(x, y, Color(col, 0.9))


## Kleine 3×5-Ziffer mit dunklem Hintergrund (Rang-Abzeichen).
const DIGITS: Array = [["111", "101", "101", "101", "111"], ["010", "110", "010", "010", "111"], ["111", "001", "111", "100", "111"], ["111", "001", "111", "001", "111"],
	["101", "101", "111", "001", "001"], ["111", "100", "111", "001", "111"], ["111", "100", "111", "101", "111"], ["111", "001", "010", "010", "010"],
	["111", "101", "111", "101", "111"], ["111", "101", "111", "001", "111"]]


static func _badge(q: Px, n: int, col: Color) -> void:
	var x: int = 17
	var y: int = 16
	q.p(x - 1, y - 1, 5, 7, Color("#141a16"))
	var rows: Array = DIGITS[n % 10]
	for r: int in range(5):
		var row: String = rows[r]
		for c: int in range(3):
			if row[c] == "1":
				q.p(x + c, y + r, 1, 1, col)


## Wilder sterblicher Gu: Käfer in der Pfadfarbe mit Schein.
static func _gu_icon(c: Color) -> Px:
	var q: Px = Px.new(24, 24)
	q.d(12, 12, 10, Color(c, 0.2))
	q.d(12, 12, 7, Color(c, 0.25))
	q.p(4, 7, 6, 5, Color(1, 1, 1, 0.8))
	q.p(14, 7, 6, 5, Color(1, 1, 1, 0.8))
	q.p(5, 8, 4, 1, Color(c, 0.6))
	q.p(15, 8, 4, 1, Color(c, 0.6))
	q.d(12, 14, 4, c)
	q.p(9, 14, 7, 1, c.darkened(0.35))
	q.p(9, 16, 7, 1, c.darkened(0.35))
	q.p(10, 12, 2, 1, c.lightened(0.5))
	q.d(12, 9, 2, c.darkened(0.3))
	q.p(10, 4, 1, 3, c.darkened(0.5))
	q.p(13, 4, 1, 3, c.darkened(0.5))
	q.p(11, 9, 1, 1, Color("#ffffff"))
	q.p(13, 9, 1, 1, Color("#ffffff"))
	return q.outline()


## Unsterbliches Gu: Grundbild, ab Rang 9 mit eigenem Emblem; Gu-Häuser als Gebäude.
static func _igu_icon(id: String) -> Px:
	var e: Dictionary = Lore.igu(id)
	var fx: String = str(e.get("fx", "?"))
	if fx == "tower" or fx == "pool" or fx == "chess":
		return _gu_house_icon(fx)
	var q: Px = _igu_core(id)
	if int(e.get("r", 0)) >= 9:
		_r9_mark(q, id, int(e["r"]))
	return q.outline()


## Emblem der Rang-9- und Rang-10-Gu (5 × 5 im Kästchen unten rechts; a/b = Farben).
const R9_EMBLEM: Dictionary = {
	"spring_autumn_cicada": [["aa.bb", "aaabb", ".aab.", ".aab.", "..b.."], "#6fd24a", "#ff9a3a"],
	"wisdom_gu": [[".....", ".aaa.", "abbba", ".aaa.", "....."], "#ffffff", "#2ad0f0"],
	"love_gu": [[".a.a.", "aaaaa", "aaaaa", ".aaa.", "..a.."], "#ff5a8a", "#ff5a8a"],
	"sovereign_immortal_fetus": [[".aaa.", "aabaa", "abbba", "aabaa", ".aaa."], "#ffe8d0", "#f0b030"],
	"derivation_gu": [["a.a.a", ".aaa.", "..a..", "..a..", "..a.."], "#8a9aff", "#8a9aff"],
	"hatred_gu": [["a...a", ".a.a.", "..a..", ".a.a.", "a...a"], "#e02a3a", "#e02a3a"],
	"heavenly_secret": [[".bbb.", ".b.b.", ".bbb.", "..b..", "..bb."], "#ffffff", "#ffd23a"],
	"heavenly_web": [["a.a.a", ".aaa.", "aa.aa", ".aaa.", "a.a.a"], "#dfe8ec", "#dfe8ec"],
	"light_gu": [["a.a.a", ".bbb.", "abbba", ".bbb.", "a.a.a"], "#fff27a", "#ffffff"],
	"fire_gu": [["..a..", ".aa..", ".aba.", "abbba", ".aaa."], "#ff5a1a", "#ffd23a"],
	"strength_gu": [[".....", "aaaa.", "aaaaa", "aaaaa", ".aaa."], "#e0904a", "#e0904a"],
	"lightning_gu": [["...aa", "..aa.", ".aaa.", ".aa..", "aa..."], "#fff27a", "#fff27a"],
	"advance_refinement": [["b...b", "bbbbb", "baaab", "baaab", "bbbbb"], "#ff7043", "#b0bec5"],
	"change_form": [["a.a.a", ".....", ".aaa.", "aaaaa", ".aaa."], "#9ccc65", "#9ccc65"],
	"heavenly_essence_imperial_lotus": [["..a..", "a.a.a", "aaaaa", ".aaa.", "bbbbb"], "#ff8ac0", "#5ad86a"],
	"dog_shit_luck": [["aa.aa", "aa.aa", "..b..", "aa.aa", "aa.aa"], "#5ad86a", "#ffd23a"],
	"fate_gu": [[".aaa.", "a...a", "a.b.a", "a...a", ".aa.a"], "#ff3a3a", "#ffd23a"],
	"destiny_gu": [["..a..", ".aaa.", "aaaaa", ".b.b.", "b...b"], "#ffffff", "#c890ff"],
	"eternal_gu": [[".....", "aa.aa", "a.a.a", "aa.aa", "....."], "#7ef0ff", "#7ef0ff"],
}


static func _r9_mark(q: Px, id: String, r: int) -> void:
	var x0: int = 16
	var y0: int = 16
	q.p(x0, y0, 8, 8, Color("#c890ff") if r >= 10 else Color("#ffd23a"))
	q.p(x0 + 1, y0 + 1, 6, 6, Color("#141a16"))
	if not R9_EMBLEM.has(id):
		var rows: Array = DIGITS[r % 10]
		for yy: int in range(5):
			for xx: int in range(3):
				if str(rows[yy])[xx] == "1":
					q.p(x0 + 2 + xx, y0 + 1 + yy, 1, 1, Color("#ffd23a"))
		return
	var em: Array = R9_EMBLEM[id]
	var ca: Color = Color(str(em[1]))
	var cb: Color = Color(str(em[2]))
	for yy2: int in range(5):
		var row: String = em[0][yy2]
		for xx2: int in range(5):
			var ch: String = row[xx2]
			if ch == "a":
				q.p(x0 + 1 + xx2, y0 + 1 + yy2, 1, 1, ca)
			elif ch == "b":
				q.p(x0 + 1 + xx2, y0 + 1 + yy2, 1, 1, cb)


## Gu-Häuser (Rang 9): Himmelsaufsichtsturm, Blutveredelungsbecken, Sternbild-Schachbrett.
static func _gu_house_icon(fx: String) -> Px:
	var q: Px = Px.new(24, 24)
	match fx:
		"tower":
			q.p(3, 20, 18, 3, Color("#8a8478"))
			q.p(3, 20, 18, 1, Color("#b8b0a0"))
			q.p(7, 14, 10, 6, Color("#c0392b"))
			q.p(11, 16, 2, 4, Color("#3a1a10"))
			q.p(5, 12, 14, 2, Color("#ffd23a"))
			q.p(8, 8, 8, 4, Color("#c0392b"))
			q.p(9, 9, 2, 2, Color("#ffe8a0"))
			q.p(13, 9, 2, 2, Color("#ffe8a0"))
			q.p(6, 6, 12, 2, Color("#ffd23a"))
			q.p(9, 3, 6, 3, Color("#c0392b"))
			q.p(11, 4, 2, 1, Color("#7ef0ff"))
			q.p(8, 2, 8, 1, Color("#ffd23a"))
			q.p(11, 0, 2, 2, Color("#fff27a"))
		"pool":
			q.p(2, 8, 20, 13, Color("#8a8478"))
			q.p(2, 8, 20, 1, Color("#b8b0a0"))
			q.p(4, 10, 16, 9, Color("#a01c3a"))
			q.p(5, 11, 6, 1, Color("#e8506a"))
			q.p(12, 14, 5, 1, Color("#e8506a"))
			q.p(8, 16, 2, 2, Color("#ff8aa0"))
			q.p(14, 11, 2, 2, Color("#ff8aa0"))
			for k: int in range(4):
				var cx: int = 1 if k % 2 == 0 else 19
				var cy: int = 4 if k < 2 else 17
				q.p(cx, cy, 4, 5, [Color("#ff7a2e"), Color("#4fb0ff"), Color("#6fd24a"), Color("#caa46a")][k])
				q.p(cx, cy, 4, 1, Color(1, 1, 1, 0.45))
		"chess":
			q.p(2, 3, 20, 20, Color("#ffd23a"))
			q.p(3, 4, 18, 18, Color("#2a2440"))
			for k2: int in range(7):
				q.p(3 + k2 * 3, 4, 1, 18, Color("#6a4ab8"))
				q.p(3, 4 + k2 * 3, 18, 1, Color("#6a4ab8"))
			for pt: Vector2i in [Vector2i(6, 7), Vector2i(15, 7), Vector2i(9, 13), Vector2i(18, 16), Vector2i(6, 19)]:
				q.p(pt.x - 1, pt.y - 1, 2, 2, Color("#ffffff"))
			q.p(11, 15, 3, 3, Color("#7ef0ff"))
			q.p(12, 14, 1, 5, Color("#7ef0ff"))
			q.p(10, 16, 5, 1, Color("#7ef0ff"))
	_badge(q, 9, Color("#ffd23a"))
	return q.outline()


## Grundbild eines Unsterblichen Gu (ohne Kontur): goldener Kranz, Strahlen, Insekt in Pfadfarbe und ein Zeichen seiner Wirkung.
static func _igu_core(id: String) -> Px:
	var q: Px = Px.new(24, 24)
	var e: Dictionary = Lore.igu(id)
	var c: Color = GuData.PATH_COL[int(e.get("p", 0))] if not e.is_empty() else Color("#ffd24a")
	var fx: String = str(e.get("fx", "?"))
	for k: int in range(8):
		var a: float = k * TAU / 8.0
		q.p(12 + roundi(cos(a) * 10.0), 12 + roundi(sin(a) * 10.0), 2, 2, Color("#ffe27a"))
	for a2: int in range(32):
		var an: float = a2 / 32.0 * TAU
		q.p(12 + roundi(cos(an) * 8.0), 12 + roundi(sin(an) * 8.0), 1, 1, Color("#f0b030"))
	q.d(12, 12, 7, Color(c, 0.35))
	if fx == "revive":
		# Zikade: breite, durchscheinende Flügel
		q.p(3, 7, 8, 9, Color(0.9, 1.0, 0.95, 0.85))
		q.p(13, 7, 8, 9, Color(0.9, 1.0, 0.95, 0.85))
		for k2: int in range(3):
			q.p(4, 9 + k2 * 2, 6, 1, Color(c, 0.8))
			q.p(14, 9 + k2 * 2, 6, 1, Color(c, 0.8))
		q.p(10, 6, 4, 13, Color("#8a6a3a"))
		q.p(10, 6, 4, 3, c)
		q.p(10, 10, 4, 1, Color("#5a4428"))
		q.p(10, 13, 4, 1, Color("#5a4428"))
		return q
	q.p(5, 6, 6, 5, Color(1, 1, 0.92, 0.9))
	q.p(13, 6, 6, 5, Color(1, 1, 0.92, 0.9))
	q.d(12, 13, 4, c)
	q.p(9, 13, 7, 1, c.darkened(0.35))
	q.p(9, 15, 7, 1, c.darkened(0.35))
	q.d(12, 8, 2, c.darkened(0.3))
	q.p(11, 8, 1, 1, Color("#ffe24a"))
	q.p(13, 8, 1, 1, Color("#ffe24a"))
	# Zeichen der Wirkung unten links
	var sx: int = 1
	var sy: int = 16
	match fx:
		"wis", "cult", "refine":
			q.d(sx + 3, sy + 3, 3, Color("#7ef0ff"))
			q.p(sx + 2, sy + 2, 2, 2, Color("#ffffff"))
		"str", "str2":
			q.p(sx, sy + 1, 6, 5, Color("#d04030"))
			q.p(sx + 1, sy, 4, 2, Color("#e86050"))
		"move":
			for k3: int in range(3):
				q.p(sx, sy + k3 * 2, 6 - k3, 1, Color("#e8f4ff"))
		"heal":
			q.p(sx + 2, sy, 2, 6, Color("#5ad86a"))
			q.p(sx, sy + 2, 6, 2, Color("#5ad86a"))
		"life":
			q.p(sx, sy, 6, 1, Color("#e8c070"))
			q.p(sx + 1, sy + 1, 4, 2, Color("#fff0c0"))
			q.p(sx + 1, sy + 3, 4, 2, Color("#e8c070"))
			q.p(sx, sy + 5, 6, 1, Color("#e8c070"))
		"luck", "fortune":
			q.d(sx + 3, sy + 3, 3, Color("#ffd23a"))
			q.p(sx + 2, sy + 2, 2, 2, Color("#8a5a10"))
		"fire":
			q.p(sx + 1, sy + 2, 4, 4, Color("#ff6a2a"))
			q.p(sx + 2, sy, 2, 3, Color("#ffd23a"))
		"bolt":
			q.p(sx + 3, sy, 2, 2, Color("#fff27a"))
			q.p(sx + 2, sy + 2, 2, 2, Color("#fff27a"))
			q.p(sx + 1, sy + 4, 2, 2, Color("#fff27a"))
		"rez":
			q.p(sx + 2, sy, 2, 6, Color("#e8e0ff"))
			q.p(sx, sy + 1, 6, 2, Color("#e8e0ff"))
		"thief", "steal":
			q.p(sx, sy + 1, 6, 3, Color("#2a2a34"))
			q.p(sx + 1, sy + 2, 1, 1, Color("#ffffff"))
			q.p(sx + 4, sy + 2, 1, 1, Color("#ffffff"))
		"fetus":
			q.d(sx + 3, sy + 3, 3, Color("#ffd8c8"))
			q.p(sx + 3, sy + 2, 2, 2, Color("#e89880"))
		"range":
			for k4: int in range(6):
				q.p(sx + k4, sy + roundi(absf(k4 - 2.5) * 0.8), 1, 2, Color("#e8f4ff"))
		"dream":
			q.p(sx, sy, 3, 4, Color("#e8b0ff"))
			q.p(sx + 3, sy, 3, 4, Color("#c890ff"))
		_:
			q.p(sx + 1, sy + 1, 4, 4, Color("#ffd23a"))
	return q


## Organisation: Gebäude ihrer Art in der Organisationsfarbe (das Siegel legt die Leiste darüber).
static func _org_icon(o: Dictionary) -> Px:
	var q: Px = Px.new(24, 24)
	var col: Color = Color(str(o["col"]))
	var race: int = clampi(int(o.get("race", 0)), 0, 3)
	var tx: Dictionary = Sprites.clan_textures(col, race)
	var k: String = o["k"]
	match k:
		"Sekte", "Hof":
			var im: Image = (tx["hall2"] as ImageTexture).get_image()
			q.draw_image(im, 12 - im.get_width() / 2, 21 - im.get_height())
			if k == "Hof":
				q.p(6, 2, 12, 2, Color("#ffd23a"))
				q.p(6, 0, 2, 2, Color("#ffd23a"))
				q.p(11, 0, 2, 2, Color("#ffd23a"))
				q.p(16, 0, 2, 2, Color("#ffd23a"))
		"Clan":
			var im2: Image = (tx["hall1"] as ImageTexture).get_image()
			q.draw_image(im2, 12 - im2.get_width() / 2, 20 - im2.get_height())
			q.p(2, 2, 1, 12, Color("#6a4a2a"))
			q.p(3, 2, 6, 4, col)
		"Stamm":
			var im3: Image = (tx["tent"] as ImageTexture).get_image()
			q.draw_image(_scaled(im3, 2), 13 - im3.get_width(), 22 - im3.get_height() * 2)
			q.p(1, 1, 1, 13, Color("#6a4a2a"))
			q.p(2, 1, 6, 5, col)
			q.p(2, 1, 6, 1, col.lightened(0.3))
		_:
			for s: int in [0, 1]:
				var bx: int = 4 + s * 9
				q.p(bx + 2, 3, 1, 18, Color("#6a4a2a"))
				q.p(bx + 3, 3, 6, 6, col if s == 0 else col.lightened(0.3))
				q.p(bx + 3, 9, 3, 2, col.darkened(0.3) if s == 0 else col)
			q.p(2, 19, 20, 3, Color("#8a7a5a"))
	return q.outline()


## Ort: das Ortsbild, verkleinert auf die Icongröße.
static func _place_icon(type: String) -> Px:
	var im: Image = Sprites.place_image(type)
	var f: float = minf(22.0 / im.get_width(), 22.0 / im.get_height())
	if f < 1.0 or f > 1.2:
		im.resize(maxi(1, roundi(im.get_width() * f)), maxi(1, roundi(im.get_height() * f)), Image.INTERPOLATE_NEAREST)
	var q: Px = Px.new(24, 24)
	q.draw_image(im, 12 - im.get_width() / 2, 23 - im.get_height())
	return q


static func _make_generated(id: String) -> Px:
	if id == "s_v9":
		# Höchster Großmeister nach Wahl: goldener Ehrwürdiger in einem Kranz aus Pfadfarben
		var qv: Px = _person_fit(0, 9, Color("#ffd24a"))
		for k: int in range(48):
			var a: float = k / 48.0 * TAU
			var pc: Color = GuData.PATH_COL[[2, 3, 6, 5, 9, 24, 11, 17][(k / 6) % 8]]
			for rr: float in [10.5, 11.0]:
				var x: int = 12 + roundi(cos(a) * rr)
				var y: int = 12 + roundi(sin(a) * rr)
				if x >= 0 and y >= 0 and x < 24 and y < 24 and qv.img.get_pixel(x, y).a < 0.1:
					qv.img.set_pixel(x, y, pc)
		qv.p(0, 0, 2, 2, GuData.PATH_COL[2])
		qv.p(2, 0, 2, 2, GuData.PATH_COL[3])
		qv.p(0, 2, 2, 2, GuData.PATH_COL[6])
		qv.p(2, 2, 2, 2, GuData.PATH_COL[24])
		_badge(qv, 9, GuData.ESS_COL[9])
		return qv.outline()
	if id.begins_with("s_") and id.substr(2).is_valid_int():
		var r: int = int(id.substr(2))
		return _person_fit(r, 0, [Color("#3d6fd0"), Color("#b8562e"), Color("#7a8a2a"), Color("#2a9ab0"), Color("#d8a040"), Color("#5a8ae8"), Color("#2a8a9a"), Color("#8a5a2a"), Color("#c84a6a"), Color("#6a7a3a"), Color("#4e8a3a")][r]).outline()
	if id.begins_with("s_gm"):
		var rk: int = int(id.substr(4))
		var q: Px = _person_fit(0, rk, [Color("#3d6fd0"), Color("#2f9a7a"), Color("#c23a2e"), Color("#d18a2a"), Color("#8a46b8")][rk - 1])
		_badge(q, rk, GuData.ESS_COL[rk])
		return q.outline()
	if id == "s_imm" or id.begins_with("s_gi"):
		var rk2: int = 6 if id == "s_imm" else int(id.substr(4))
		var q2: Px = _person_fit(0, rk2, [Color("#a768e2"), Color("#c0284a"), Color("#e8e0d0")][rk2 - 6])
		_badge(q2, rk2, GuData.ESS_COL[rk2])
		return q2.outline()
	if id.begins_with("s_v_"):
		for vd: Dictionary in Lore.VEN:
			if "s_v_" + str(vd["id"]) == id:
				var q3: Px = _person_fit(0, 9, Color(str(vd["col"])))
				_ring_behind(q3, Color(str(vd["col"])).lightened(0.2))
				q3.p(0, 0, 4, 4, GuData.PATH_COL[int(vd["p"])])
				q3.p(0, 0, 4, 1, Color(GuData.PATH_COL[int(vd["p"])]).lightened(0.4))
				return q3.outline()
	if id.begins_with("s_f_"):
		for fd: Dictionary in Lore.FIG:
			if "s_f_" + str(fd["id"]) == id:
				var oc: Dictionary = Lore.org(str(fd["org"]))
				var col: Color = Color(str(oc["col"])) if not oc.is_empty() else (Color("#3a2a3a") if int(fd["al"]) == 1 else Color("#8e8676"))
				var q4: Px = _person_fit(int(fd.get("race", 0)), int(fd["r"]), col)
				q4.p(0, 0, 4, 4, GuData.PATH_COL[int(fd["p"])])
				if not (fd["igu"] as Array).is_empty() and str(fd["igu"][0]) == "spring_autumn_cicada":
					q4.p(17, 1, 6, 4, Color(0.9, 1.0, 0.95, 0.9))
					q4.p(19, 1, 2, 6, Color("#8a6a3a"))
				return q4.outline()
	if id.begins_with("s_gu") and id.substr(4).is_valid_int():
		return _gu_icon(GuData.PATH_COL[int(id.substr(4))])
	if id.begins_with("s_ig_"):
		if id == "s_ig_rand":
			var q5: Px = _igu_icon("")
			q5.p(10, 9, 4, 1, Color("#ffffff"))
			q5.p(13, 10, 1, 2, Color("#ffffff"))
			q5.p(11, 12, 2, 1, Color("#ffffff"))
			q5.p(11, 13, 1, 1, Color("#ffffff"))
			q5.p(11, 15, 1, 1, Color("#ffffff"))
			return q5
		return _igu_icon(id.substr(5))
	if id.begins_with("pl_"):
		return _place_icon(id.substr(3))
	if id.begins_with("o_"):
		return _org_icon(Lore.org(id.substr(2)))
	if id.begins_with("s_") and GuData.SPEC.has(id.substr(2)):
		return _animal_fit(id.substr(2)).outline()
	var q6: Px = Px.new(24, 24)
	match id:
		"ev_calam":
			q6.p(1, 10, 22, 12, Color("#8a6a42"))
			q6.p(1, 10, 22, 2, Color("#c9a46a"))
			for pt: Vector2i in [Vector2i(11, 11), Vector2i(10, 13), Vector2i(12, 15), Vector2i(11, 17), Vector2i(13, 19), Vector2i(5, 14), Vector2i(4, 16), Vector2i(18, 13), Vector2i(19, 15)]:
				q6.p(pt.x, pt.y, 2, 2, Color("#1a100a"))
			q6.p(9, 1, 6, 6, Color("#92de5c"))
			q6.p(10, 2, 4, 4, Color("#e8ffd0"))
			for k: int in range(4):
				q6.p(3 + k * 5, 6 + (k % 2), 2, 2, Color("#c9a46a"))
		"ev_dream":
			return _place_icon("dream").outline()
		"ev_inherit":
			var qi: Px = _place_icon("inherit")
			for k2: int in range(6):
				var a: float = k2 * TAU / 6.0
				qi.p(12 + roundi(cos(a) * 10.0), 12 + roundi(sin(a) * 10.0), 2, 2, Color("#ffe27a"))
			return qi.outline()
		"ev_ow":
			var qo: Px = _person_fit(0, 3, Color("#6a2a8a"), true)
			qo.p(1, 1, 3, 3, Color("#d04aff"))
			qo.p(20, 1, 3, 3, Color("#d04aff"))
			return qo.outline()
		"ev_war":
			q6.p(3, 2, 2, 20, Color("#6a4a2a"))
			q6.p(5, 3, 8, 7, Color("#f0f0e8"))
			q6.p(5, 3, 8, 2, Color("#ffffff"))
			q6.p(19, 2, 2, 20, Color("#3a2a20"))
			q6.p(11, 11, 8, 7, Color("#c02a2a"))
			q6.p(11, 11, 8, 2, Color("#e04a3a"))
			q6.p(8, 6, 2, 2, Color("#4a8ad8"))
			q6.p(14, 14, 2, 2, Color("#1a0a0a"))
		"ev_frag":
			for k3: int in range(6):
				q6.p(1 + k3, 1 + k3, 3, 3, Color("#cfe0ff") if k3 < 3 else Color("#8aa8e8"))
			q6.p(9, 8, 7, 9, Color("#cfe0ff"))
			q6.p(11, 6, 3, 3, Color("#ffffff"))
			q6.p(14, 10, 2, 6, Color("#8aa8e8"))
			q6.p(5, 19, 16, 3, Color("#5a4a40"))
		_:
			return null
	return q6.outline()


# ---------------- Gottkräfte-Parität (WorldBox) ----------------

## Explosions-Stern mit Rang-Abzeichen (Mordzug-Leiter).
static func _blast(outer: Color, inner: Color, core: Color, rays: int, rmax: float, badge: int = -1) -> Px:
	var q: Px = Px.new(24, 24)
	for k: int in range(rays):
		var a: float = k * TAU / rays + 0.2
		var len: float = rmax if k % 2 == 0 else rmax * 0.7
		for dd: int in range(3, int(len)):
			q.p(12 + roundi(cos(a) * dd) - 1, 12 + roundi(sin(a) * dd) - 1, 2, 2, outer if dd > len * 0.55 else inner)
	q.d(12, 12, int(rmax * 0.45), inner)
	q.d(12, 12, int(rmax * 0.25), core)
	if badge >= 0:
		_badge(q, badge, GuData.ESS_COL[badge])
	return q


## Saatbeutel mit Zeichen des Bioms.
static func _seed_bag(mark: Color, mark2: Color) -> Px:
	var q: Px = Px.new(24, 24)
	q.p(6, 9, 12, 12, "#b08a52")
	q.p(5, 11, 14, 9, "#b08a52")
	q.p(6, 9, 3, 12, "#c8a468")
	q.p(15, 10, 3, 10, "#8a6a3a")
	q.p(8, 6, 8, 3, "#9a7846")
	q.p(7, 8, 10, 1, "#6a4a2a")
	q.p(9, 13, 6, 5, mark)
	q.p(10, 14, 2, 2, mark2)
	q.p(13, 16, 1, 1, mark2)
	for pt: Vector2i in [Vector2i(4, 4), Vector2i(19, 6), Vector2i(17, 2)]:
		q.p(pt.x, pt.y, 2, 2, "#e8d8a0")
	return q


static func _make_parity(id: String) -> Px:
	var q: Px = Px.new(24, 24)
	match id:
		"layer":
			q.p(2, 3, 20, 18, "#2f6ab8")
			q.p(3, 4, 9, 8, "#e8e0a0")
			q.p(12, 4, 9, 8, "#c070e8")
			q.p(3, 12, 6, 8, "#e8a040")
			q.p(9, 12, 12, 8, "#5ac85a")
			for k: int in range(0, 20, 2):
				q.p(2 + k, 11, 1, 2, "#ffffff")
				q.p(11, 3 + k * 9 / 10, 2, 1, "#ffffff")
			q.p(14, 14, 3, 3, "#c23a2e")
			q.p(5, 6, 2, 2, "#2f6fd6")
		"plans":
			q.p(4, 3, 16, 18, "#efe2b8")
			q.p(3, 3, 18, 2, "#c8b080")
			q.p(3, 19, 18, 2, "#c8b080")
			for y: int in range(7, 18, 3):
				q.p(6, y, 5, 1, "#9a8a60")
			for k: int in range(8):
				q.p(11 + k, 8 + k, 2, 1, "#b8bcc8")
				q.p(18 - k, 8 + k, 2, 1, "#b8bcc8")
			q.p(10, 16, 3, 2, "#6a4a2a")
			q.p(18, 16, 3, 2, "#6a4a2a")
			q.p(14, 11, 2, 2, "#c02a2a")
		"brushshape":
			q.d(8, 9, 6, "#f4f0e0")
			q.d(8, 9, 4, "#d8eef8")
			q.p(11, 11, 10, 10, "#f4f0e0")
			q.p(12, 12, 8, 8, "#ffd23a")
			q.p(3, 21, 6, 1, "#f4f0e0")
		"t_dig":
			q.p(2, 15, 20, 7, "#8a6a42")
			q.p(2, 15, 20, 2, "#6aa046")
			q.p(7, 17, 10, 5, "#3a8ac8")
			q.p(8, 17, 8, 1, "#9ad8f8")
			for k: int in range(9):
				q.p(15 - k, 2 + k, 2, 2, "#8a5a30")
			q.p(4, 10, 6, 5, "#b8bcc8")
			q.p(5, 11, 4, 4, "#d8dce4")
			q.p(13, 1, 5, 2, "#6a4a2a")
		"t_sponge":
			q.p(5, 7, 14, 10, "#f0d050")
			q.p(5, 7, 14, 2, "#ffe880")
			q.p(5, 15, 14, 2, "#c8a830")
			for pt: Vector2i in [Vector2i(7, 10), Vector2i(12, 9), Vector2i(15, 12), Vector2i(9, 13)]:
				q.p(pt.x, pt.y, 2, 2, "#b89020")
			for pt2: Vector2i in [Vector2i(4, 19), Vector2i(10, 20), Vector2i(17, 19)]:
				q.p(pt2.x, pt2.y, 2, 3, "#5ab8f0")
			q.p(10, 2, 2, 3, "#5ab8f0")
			q.p(14, 3, 2, 3, "#5ab8f0")
		"t_axe":
			for k: int in range(14):
				q.p(6 + k, 5 + k, 2, 2, "#8a5a30")
			q.p(2, 3, 8, 7, "#b8bcc8")
			q.p(2, 3, 3, 7, "#e4e8ee")
			q.p(9, 5, 2, 3, "#6a6e78")
			q.p(16, 3, 6, 6, "#4e8a32")
			q.p(17, 2, 4, 1, "#6aaa44")
		"t_erase":
			for k: int in range(9):
				q.p(4 + k, 13 - k, 8, 6, "#f0a0b8" if k > 3 else "#e8e8f0")
			q.p(4, 18, 16, 2, "#c8c0b0")
			q.p(14, 16, 2, 2, "#ffffff")
			q.p(16, 20, 5, 1, "#9db09e")
		"seed_grass":
			var g1: Px = _seed_bag(Color("#5ab84a"), Color("#c8f0a0"))
			g1.p(11, 3, 2, 5, Color("#4e8a32"))
			g1.p(8, 3, 3, 2, Color("#6aaa44"))
			g1.p(13, 2, 3, 2, Color("#6aaa44"))
			return g1.outline()
		"seed_des":
			return _seed_bag(Color("#e8c070"), Color("#fff0b0")).outline()
		"seed_snow":
			var g3: Px = _seed_bag(Color("#e8f4ff"), Color("#81d4fa"))
			g3.p(11, 2, 1, 5, Color("#ffffff"))
			g3.p(9, 4, 5, 1, Color("#ffffff"))
			return g3.outline()
		"inspire":
			q.p(5, 3, 2, 19, "#6a4a2a")
			q.p(7, 4, 12, 9, "#ffd23a")
			q.p(7, 4, 12, 2, "#fff0a0")
			q.p(16, 11, 3, 2, "#e0a020")
			q.p(11, 7, 3, 3, "#c23a2e")
			q.p(3, 20, 6, 2, "#8a7a5a")
			for pt: Vector2i in [Vector2i(20, 3), Vector2i(21, 9), Vector2i(1, 2)]:
				q.p(pt.x, pt.y, 2, 2, "#fff4c0")
		"bless":
			var b: Px = _person_fit(0, 0, Color("#e8c040"))
			for k2: int in range(10):
				b.p(7 + k2, 1, 1, 1, Color("#ffe27a"))
			b.p(7, 0, 10, 1, Color("#fff4c0"))
			b.p(2, 6, 2, 2, Color("#fff4c0"))
			b.p(20, 9, 2, 2, Color("#fff4c0"))
			b.p(19, 3, 1, 3, Color("#ffe27a"))
			b.p(18, 4, 3, 1, Color("#ffe27a"))
			return b.outline()
		"curse":
			var c: Px = _person_fit(0, 0, Color("#5a2a6a"))
			c.p(5, 0, 14, 4, Color("#3a1a4a"))
			c.p(7, 3, 10, 2, Color("#5a2a6a"))
			c.p(8, 5, 1, 3, Color("#8a4aa8"))
			c.p(15, 5, 1, 4, Color("#8a4aa8"))
			c.p(11, 5, 1, 2, Color("#8a4aa8"))
			return c.outline()
		"shield":
			for y: int in range(3, 21):
				var hw: int = 8 if y < 13 else maxi(1, 8 - (y - 13))
				q.p(12 - hw, y, hw * 2, 1, "#4a8ad8")
				q.p(12 - hw + 1, y, 2, 1, "#8ac0f8")
			q.p(11, 5, 2, 13, "#e8f4ff")
			q.p(7, 9, 10, 2, "#e8f4ff")
			q.p(18, 1, 2, 3, "#fff27a")
			q.p(20, 3, 2, 2, "#fff27a")
		"hand":
			q.d(12, 12, 10, Color(1, 0.89, 0.48, 0.25))
			q.p(7, 11, 10, 9, "#f0c090")
			q.p(8, 19, 8, 2, "#d8a070")
			for fx: int in range(4):
				q.p(7 + fx * 2 + (1 if fx > 1 else 0), 4 + absi(fx - 1) * 1, 2, 8, "#f0c090")
			q.p(4, 11, 3, 2, "#f0c090")
			q.p(5, 13, 3, 3, "#f0c090")
			q.p(7, 11, 1, 9, "#d8a070")
			q.p(10, 16, 4, 1, "#d8a070")
		"possess":
			var ps: Px = _person_fit(0, 0, Color("#8e8676"))
			ps.p(13, 1, 8, 9, Color(0.75, 0.44, 1.0, 0.9))
			ps.p(14, 9, 2, 3, Color(0.75, 0.44, 1.0, 0.9))
			ps.p(17, 10, 2, 2, Color(0.75, 0.44, 1.0, 0.9))
			ps.p(15, 4, 1, 2, Color("#ffffff"))
			ps.p(18, 4, 1, 2, Color("#ffffff"))
			return ps.outline()
		"ctrlbeast":
			var gi: Px = _animal_fit("remote")
			gi.p(0, 0, 6, 5, Color("#c070ff"))
			gi.p(1, 1, 1, 2, Color("#ffffff"))
			gi.p(4, 1, 1, 2, Color("#ffffff"))
			return gi.outline()
		"fert":
			_cloud(q, "#9ad89a", "#5aa85a")
			for pt: Vector2i in [Vector2i(6, 16), Vector2i(10, 18), Vector2i(15, 16), Vector2i(18, 19)]:
				q.p(pt.x, pt.y, 1, 2, "#7ae07a")
			q.p(9, 21, 6, 2, "#6aa046")
			q.p(11, 18, 2, 3, "#4e8a32")
			q.p(9, 17, 2, 2, "#ff8ac0")
		"sunray":
			q.d(12, 5, 4, "#ffd23a")
			q.d(12, 5, 2, "#fff6c0")
			for k3: int in range(8):
				var a3: float = k3 * TAU / 8.0
				q.p(12 + roundi(cos(a3) * 6.0), 5 + roundi(sin(a3) * 6.0), 1, 1, "#ffb43a")
			q.p(10, 9, 4, 11, "#ff9a2a")
			q.p(11, 9, 2, 11, "#fff4c0")
			q.p(5, 20, 14, 3, "#5a4a40")
			q.p(8, 18, 8, 2, "#ff6a2a")
		"frost":
			for k4: int in range(3):
				var a4: float = k4 * PI / 3.0
				for dd2: int in range(-9, 10):
					q.p(12 + roundi(cos(a4) * dd2), 12 + roundi(sin(a4) * dd2), 1, 1, "#e8f8ff")
			for k5: int in range(6):
				var a5: float = k5 * PI / 3.0
				var ex: int = 12 + roundi(cos(a5) * 6.0)
				var ey: int = 12 + roundi(sin(a5) * 6.0)
				q.p(ex - 1, ey - 1, 3, 3, "#81d4fa")
			q.d(12, 12, 2, "#ffffff")
		"volcano":
			for y2: int in range(7, 22):
				var w2: int = roundi((y2 - 6) * 0.75) + 2
				q.p(12 - w2, y2, w2 * 2, 1, "#5a4a44" if y2 > 9 else "#3a3030")
				q.p(12 - w2, y2, 2, 1, "#7a6a60")
			q.p(10, 6, 4, 2, "#ff7a2e")
			q.p(11, 8, 2, 6, "#ff6a2a")
			q.p(10, 13, 2, 5, "#ff9a2a")
			q.p(13, 11, 2, 4, "#e4402a")
			q.p(8, 1, 4, 3, "#8a8480")
			q.p(12, 2, 5, 3, "#6a6460")
			q.p(16, 4, 2, 2, "#ffb43a")
			q.p(5, 3, 2, 2, "#ffb43a")
		"tornado":
			for y3: int in range(2, 22):
				var w3: int = maxi(1, roundi((22 - y3) * 0.45))
				var off: int = roundi(sin(y3 * 0.6) * 2.0)
				q.p(12 - w3 + off, y3, w3 * 2, 1, "#c8ccd0" if y3 % 3 else "#8a9098")
			q.p(4, 21, 16, 2, "#a08a6a")
			q.p(3, 9, 2, 2, "#5a8a32")
			q.p(19, 14, 2, 2, "#5a8a32")
		"acid":
			_cloud(q, "#6a7a4a", "#4a5a32")
			for pt3: Vector2i in [Vector2i(5, 16), Vector2i(9, 18), Vector2i(13, 16), Vector2i(17, 18), Vector2i(7, 21), Vector2i(15, 21)]:
				q.p(pt3.x, pt3.y, 2, 2, "#8cf040")
			q.p(9, 8, 2, 2, "#c8ff60")
			q.p(13, 8, 2, 2, "#c8ff60")
			q.p(10, 11, 4, 1, "#c8ff60")
		"undead":
			q.p(7, 3, 10, 9, "#8ab86a")
			q.p(8, 2, 8, 1, "#8ab86a")
			q.p(8, 5, 3, 3, "#1a2a10")
			q.p(13, 5, 3, 3, "#1a2a10")
			q.p(9, 6, 1, 1, "#e0ff60")
			q.p(14, 6, 1, 1, "#e0ff60")
			q.p(9, 10, 6, 1, "#3a4a2a")
			q.p(10, 9, 1, 1, "#f0f0d8")
			q.p(13, 9, 1, 1, "#f0f0d8")
			q.p(8, 12, 8, 8, "#4a3a3a")
			q.p(2, 13, 6, 2, "#8ab86a")
			q.p(16, 13, 6, 2, "#8ab86a")
			q.p(9, 20, 2, 3, "#3a2c26")
			q.p(13, 20, 2, 3, "#3a2c26")
			q.p(16, 2, 3, 3, "#86e04a")
		"lava":
			return _tile(GuData.LAVA, func(o: Px) -> void:
				o.p(6, 8, 3, 2, "#fff0a0")
				o.p(13, 12, 4, 2, "#fff0a0")
				o.p(9, 15, 2, 2, "#ffe27a")
				o.p(4, 4, 16, 1, "#7a2818"))
		"tnt":
			q.d(11, 14, 7, "#2a2a34")
			q.d(9, 12, 2, "#5a5a6a")
			q.p(13, 5, 2, 4, "#8a6a42")
			for pt4: Vector2i in [Vector2i(16, 1), Vector2i(15, 3), Vector2i(17, 3), Vector2i(18, 5)]:
				q.p(pt4.x, pt4.y, 2, 2, "#fff27a")
			q.p(9, 13, 5, 1, "#fff27a")
			q.p(11, 11, 1, 5, "#fff27a")
		"mine":
			q.p(1, 15, 22, 7, "#8a6a42")
			q.p(1, 15, 22, 2, "#6aa046")
			q.p(6, 12, 12, 5, "#5a5a62")
			q.p(7, 11, 10, 1, "#7a7a84")
			q.p(10, 9, 4, 3, "#3a3a42")
			q.p(11, 8, 2, 2, "#ff3a2a")
			q.p(4, 6, 1, 1, "#ff8a7a")
			q.p(19, 6, 1, 1, "#ff8a7a")
		"napalm":
			for k6: int in range(4):
				var bx: int = 2 + k6 * 5
				var by: int = 3 + k6 * 4
				q.p(bx, by, 4, 4, "#ff7a2e")
				q.p(bx + 1, by + 1, 2, 2, "#ffe27a")
				q.p(bx - 2, by - 2, 2, 2, "#ffb43a")
			q.p(2, 20, 20, 3, "#e4402a")
			q.p(4, 18, 4, 2, "#ff9a2a")
			q.p(14, 18, 5, 2, "#ff9a2a")
		"km6":
			return _blast(GuData.ESS_COL[6].darkened(0.2), GuData.ESS_COL[6], Color("#f4ffe0"), 8, 10.0, 6).outline()
		"km8":
			return _blast(Color("#ff9a3a"), GuData.ESS_COL[8], Color("#ffffff"), 12, 11.0, 8).outline()
		"km9":
			var k9: Px = _blast(Color("#ff6a2a"), GuData.ESS_COL[9], Color("#ffffff"), 16, 12.0, 9)
			k9.p(2, 21, 20, 2, Color("#5a4a40"))
			return k9.outline()
		"void":
			q.d(12, 12, 10, Color("#7c4dff"))
			q.d(12, 12, 8, Color("#2a1050"))
			q.d(12, 12, 5, Color("#0a0414"))
			for a6: int in range(20):
				var an6: float = a6 / 20.0 * TAU
				q.p(12 + roundi(cos(an6) * 9.0), 12 + roundi(sin(an6) * 4.0), 1, 1, Color("#e8e0ff"))
			q.p(14, 7, 2, 2, Color("#b39dff"))
		"goo":
			for k7: int in range(26):
				var gx: int = 3 + int(GuData.hash2(k7, 1, 9) * 17.0)
				var gy: int = 4 + int(GuData.hash2(k7, 2, 9) * 15.0)
				q.p(gx, gy, 2, 2, "#3a1a4a" if k7 % 3 else "#8a5aa8")
				if k7 % 4 == 0:
					q.p(gx + 1, gy - 1, 1, 1, "#c8a0e8")
			q.p(2, 20, 20, 3, "#5a4a44")
		"coin":
			q.d(12, 12, 10, "#c89020")
			q.d(12, 12, 9, "#ffd24a")
			q.d(12, 12, 7, "#f0b030")
			q.p(9, 9, 6, 6, "#1a1408")
			q.p(10, 10, 4, 4, "#3a2a10")
			q.p(6, 5, 3, 2, "#fff6c0")
			q.p(16, 16, 3, 2, "#a87010")
		_:
			return null
	return q.outline()


# ---------------- Sandkasten (Regionen, Welt-Aktionen) ----------------

## Aufwärts- (dir = -1) oder Abwärtspfeil (dir = 1), Spitze bei (cx, tip).
static func _arrow(q: Px, cx: int, tip: int, dir: int, shaft: int, col: Variant) -> void:
	for k: int in range(4):
		q.p(cx - k, tip - dir * k, k * 2 + 1, 1, col)
	var y0: int = tip - dir * 4
	if dir < 0:
		q.p(cx - 1, y0, 3, shaft, col)
	else:
		q.p(cx - 1, y0 - shaft + 1, 3, shaft, col)


## Gefaltete Karte in der Farbe der Region mit einem Zeichen.
static func _region_icon(r: int) -> Px:
	var q: Px = Px.new(24, 24)
	var col: Color = World.REG_COL[r]
	for k: int in range(3):
		var x0: int = 3 + k * 6
		var top: int = 4 if k % 2 == 0 else 6
		for y: int in range(top, top + 15):
			for x: int in range(x0, x0 + 6):
				var n: float = GuData.hash2(x, y, r * 13 + 3)
				var c: Color = col.lightened(0.12) if n < 0.3 else (col.darkened(0.1) if n > 0.8 else col)
				if k == 1:
					c = c.darkened(0.18)
				q.p(x, y, 1, 1, c)
		q.p(x0, top, 6, 1, col.lightened(0.35))
	var lt: String = "#fffaf0"
	var dk: String = "#2a2418"
	match r:
		0:
			# Jurte der Steppenstämme
			q.p(8, 12, 9, 5, "#8a5a30")
			q.p(9, 10, 7, 2, "#a8743c")
			q.p(11, 8, 3, 2, "#a8743c")
			q.p(11, 13, 3, 4, dk)
			q.p(8, 11, 9, 1, "#c84a3a")
		1:
			# Berge der Südgrenze
			for y: int in range(7, 17):
				var w: int = roundi((y - 6) * 0.75)
				q.p(11 - w, y, w * 2 + 1, 1, "#2e6a2e")
			q.p(10, 7, 3, 2, lt)
			q.p(9, 9, 5, 1, lt)
		2:
			# Sonne über der Düne
			q.d(14, 9, 3, "#fff2a0")
			q.d(14, 9, 2, "#ffe060")
			for x: int in range(4, 20):
				var hh: int = roundi(2.0 + sin((x - 4) * 0.45) * 1.6)
				q.p(x, 16 - hh, 1, hh + 2, "#c86a20")
		3:
			# Wellen des Ostmeers
			for row: int in range(2):
				for x: int in range(5, 19):
					var yy: int = 9 + row * 5 + roundi(sin(x * 0.9) * 1.2)
					q.p(x, yy, 1, 2, lt)
		4:
			# Pagode des Zentralkontinents
			q.p(7, 8, 11, 2, "#ffd24a")
			q.p(6, 9, 2, 1, "#ffd24a")
			q.p(17, 9, 2, 1, "#ffd24a")
			q.p(9, 10, 7, 3, "#c23a2e")
			q.p(6, 13, 13, 2, "#ffd24a")
			q.p(9, 15, 7, 3, "#c23a2e")
			q.p(11, 15, 3, 3, dk)
			q.p(12, 6, 1, 2, "#ffd24a")
	return q.outline()


static func _make_sandbox(id: String) -> Px:
	if id.begins_with("rg_") and id.substr(3).is_valid_int():
		return _region_icon(int(id.substr(3)))
	var q: Px = Px.new(24, 24)
	match id:
		"t_unwall":
			q.p(8, 5, 8, 17, "#b8a6ee")
			q.p(8, 5, 3, 17, "#e0d6ff")
			q.p(14, 5, 2, 17, "#8a76c8")
			q.p(8, 3, 3, 2, "#b8a6ee")
			q.p(13, 2, 3, 3, "#b8a6ee")
			q.p(11, 9, 2, 1, "#5a4a90")
			q.p(10, 10, 2, 2, "#5a4a90")
			q.p(11, 12, 2, 3, "#5a4a90")
			q.p(4, 20, 3, 2, "#9a88d0")
			q.p(17, 19, 3, 3, "#9a88d0")
			q.p(6, 21, 12, 1, "#7a68b0")
			for k: int in range(15):
				q.p(4 + k, 4 + k, 2, 2, "#e4503a")
				q.p(18 - k, 4 + k, 2, 2, "#e4503a")
		"w_wipe":
			q.d(12, 12, 10, "#2f7ad8")
			q.d(12, 12, 9, "#3a8ae0")
			q.p(4, 7, 5, 4, "#5ab84a")
			q.p(15, 15, 6, 4, "#5ab84a")
			q.p(16, 5, 3, 3, "#5ab84a")
			q.p(5, 16, 3, 2, "#5ab84a")
			# Totenschädel
			q.d(12, 10, 6, "#f4f0e0")
			q.p(8, 14, 9, 3, "#f4f0e0")
			q.p(9, 17, 7, 2, "#d8d0b8")
			q.p(8, 9, 3, 3, "#1a1010")
			q.p(14, 9, 3, 3, "#1a1010")
			q.p(12, 13, 1, 2, "#1a1010")
			q.p(10, 17, 1, 2, "#6a6050")
			q.p(12, 17, 1, 2, "#6a6050")
			q.p(14, 17, 1, 2, "#6a6050")
			q.p(9, 5, 3, 1, "#ffffff")
		"w_flat":
			for y: int in range(3, 13):
				var w: int = roundi((y - 2) * 0.8)
				for x: int in range(12 - w, 12 + w + 1):
					if x == 12 - w or x == 12 + w:
						q.p(x, y, 1, 1, "#c8ccd0" if y % 3 != 0 else "#8a8e94")
					elif y < 6:
						q.p(x, y, 1, 1, "#eef2f4")
					elif (x + y) % 3 == 0:
						q.p(x, y, 1, 1, Color(0.6, 0.62, 0.66, 0.6))
			_arrow(q, 12, 13, 1, 6, "#ffffff")
			q.p(2, 15, 20, 3, "#6aaa44")
			q.p(2, 15, 20, 1, "#8ad05a")
			q.p(2, 18, 20, 4, "#8a6a42")
			q.p(2, 21, 20, 1, "#6a4a2a")
		"w_flood":
			q.p(3, 9, 7, 7, "#6aaa44")
			q.p(4, 8, 5, 1, "#8ad05a")
			q.p(5, 4, 3, 5, "#2e6a2e")
			q.p(6, 3, 1, 1, "#2e6a2e")
			q.p(2, 13, 20, 9, "#2f7ad8")
			q.p(2, 18, 20, 4, "#2560b8")
			for x: int in range(2, 22):
				var yy: int = 12 + roundi(sin(x * 0.8) * 1.0)
				q.p(x, yy, 1, 2, "#9ad8f8")
				if (x % 5) == 1:
					q.p(x, yy - 1, 2, 1, "#ffffff")
			_arrow(q, 16, 2, -1, 6, "#9ad8f8")
		"w_raise":
			q.p(2, 16, 20, 6, "#2f7ad8")
			q.p(2, 16, 20, 1, "#9ad8f8")
			for y: int in range(7, 17):
				var w2: int = roundi((y - 6) * 0.9)
				q.p(9 - w2, y, w2 * 2 + 1, 1, "#6aaa44" if y < 14 else "#e8d890")
			q.p(8, 7, 3, 2, "#8ad05a")
			_arrow(q, 18, 2, -1, 8, Y)
		_:
			return null
	return q.outline()
