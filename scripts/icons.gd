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


static func _person_icon(race: int, rank: int, col: Color, w: int, h: int, X: float, Yp: float, sc: float) -> Px:
	var q: Px = Px.new(w, h)
	Sprites.draw_person(func(r: Rect2, c: Color) -> void: q.p(roundi(r.position.x), roundi(r.position.y), maxi(1, roundi(r.size.x)), maxi(1, roundi(r.size.y)), c), X, Yp, sc, race, rank, col, 1, true, false, 0.0, false, false, false, false, false)
	return q.outline()


static func _animal_icon(sp: String, w: int, h: int, X: float, Yp: float, sc: float, tide: bool = false) -> Px:
	var q: Px = Px.new(w, h)
	Sprites.draw_animal(func(r: Rect2, c: Color) -> void: q.p(roundi(r.position.x), roundi(r.position.y), maxi(1, roundi(r.size.x)), maxi(1, roundi(r.size.y)), c), X, Yp, sc, sp, 1, false, 1.0, false, tide, 3)
	return q.outline()


static func _make(id: String) -> Px:
	var q: Px = Px.new(24, 24)
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
		"s_0":
			return _person_icon(0, 0, Color("#3d6fd0"), 12, 12, 6.0, 11.5, 1.2)
		"s_1":
			return _person_icon(1, 0, Color("#b8562e"), 12, 12, 6.0, 11.5, 1.2)
		"s_2":
			return _person_icon(2, 0, Color("#7a8a2a"), 12, 12, 6.0, 11.5, 1.2)
		"s_3":
			return _person_icon(3, 0, Color("#2a9ab0"), 12, 12, 6.0, 11.5, 1.2)
		"s_imm":
			return _person_icon(0, 6, Color("#a768e2"), 18, 18, 9.0, 17.0, 1.0)
		"s_deer", "s_boar", "s_wolf", "s_monkey", "s_crane":
			return _animal_icon(id.substr(2), 12, 12, 6.0, 10.5, 1.15)
		"s_kingwolf":
			return _animal_icon("kingwolf", 18, 18, 9.0, 16.0, 1.0)
		"s_ancient":
			return _animal_icon("ancient", 22, 22, 11.0, 19.0, 0.8)
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
			for pt: Vector2i in [Vector2i(4, 6), Vector2i(11, 4), Vector2i(15, 11), Vector2i(7, 13), Vector2i(12, 16)]:
				g.p(pt.x - 1, pt.y - 1, 4, 4, Color(0.6, 0.82, 1.0, 0.45))
				g.p(pt.x, pt.y, 2, 2, "#f0faff")
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
		_:
			pass
	return q.outline()


static func _scaled(src: Image, f: int) -> Image:
	var im: Image = src.duplicate()
	im.resize(src.get_width() * f, src.get_height() * f, Image.INTERPOLATE_NEAREST)
	return im
