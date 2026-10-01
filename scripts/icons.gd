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


## Unsterbliches Gu: goldener Kranz, Strahlen, Insekt in Pfadfarbe und ein Zeichen seiner Wirkung.
static func _igu_icon(id: String) -> Px:
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
		return q.outline()
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
	return q.outline()


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
