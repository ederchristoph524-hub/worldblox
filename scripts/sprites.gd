class_name Sprites
extends RefCounted
## Alle Pixel-Sprites der Welt: Bäume, Felsen, Gebäude pro Clan-Farbe und das Zeichnen von Wesen.

const S_SHADOW: Color = Color(0.055, 0.157, 0.04, 0.42)

static var tree_img: Array[Image] = []
static var pine_img: Image
static var palm_img: Image
static var bamb_img: Image
static var rock_img: Image
static var ore_img: Image
static var spring_img: Image
static var shrub_img: Image
static var tuft_img: Image
static var flower_img: Image
static var _clan_cache: Dictionary = {}
static var _ready: bool = false


static func init() -> void:
	if _ready:
		return
	_ready = true
	var big: Array = [
		"...LLL...",
		".LLLBBBL.",
		"LLBBBBBBD",
		"LBBBBBBDD",
		"BBBBBBBDD",
		".BBBBBDDD",
		"..DDDDDD.",
		"....Tt...",
		"....Tt...",
		"....TtSS.",
		"....TtSSS",
		"...TTtSSS",
		".....SSS."]
	var small: Array = [
		"..LLL..",
		".LBBBB.",
		"LBBBBBD",
		"BBBBBDD",
		".DBBDD.",
		"..DDD..",
		"...Tt..",
		"...TtS.",
		"...TtSS",
		"..TTtSS",
		"....SS."]
	var pi: int = 0
	for p: Array in GuData.TREEPAL:
		var gi: int = 0
		for g: Array in [big, small]:
			var pal: Dictionary = {"L": Color(p[0]), "B": Color(p[1]), "D": Color(p[2]), "T": Color("#8e887c"), "t": Color("#5a5864"), "S": S_SHADOW}
			tree_img.append(Px.speckle(Px.grid(g, pal), pi * 7 + gi + 1, Color(p[1]), Color(p[0]), Color(p[2]), 0.06))
			gi += 1
		pi += 1
	pine_img = Px.grid([
		"....L....",
		"...LBD...",
		"...WBD...",
		"..LBBDD..",
		"..WWBDD..",
		".LBBBBDD.",
		".WWWBBDD.",
		"LBBBBBDDD",
		"WWBBBBDDD",
		"....Tt...",
		"....TtSS.",
		"...TTtSSS",
		".....SSS."], {"L": "#5a9a6a", "B": "#3a7050", "D": "#24503a", "W": "#eef4f6", "T": "#7a6a5a", "t": "#4a3e34", "S": S_SHADOW})
	palm_img = Px.grid([
		"..LL...LL..",
		".LBBL.LBBL.",
		"LB..BLB..BL",
		"L...DTD...L",
		".....T.....",
		"....tT.....",
		"....tT.....",
		".....tT....",
		".....tTS...",
		".....tTSS..",
		"....ttTTSS.",
		"......SSS.."], {"L": "#7ad04a", "B": "#4ea83a", "D": "#2e7a2a", "T": "#c09a5a", "t": "#8a6a3a", "S": S_SHADOW})
	bamb_img = Px.grid([
		"...L.....",
		"..LG..L..",
		".LG..LG..",
		"..G.LGG..",
		"..g..G.L.",
		"..G..g.G.",
		"..G..G.G.",
		".LG..G.g.",
		"..g..GSG.",
		"..G..gSGS",
		"..G..GSgS",
		".GG.GGSSS",
		"..SSSSS.."], {"L": "#a8d860", "G": "#7ab44a", "g": "#4e8030", "S": S_SHADOW})
	rock_img = Px.grid(["..gg..", ".gGGg.", "gGgggd", ".dddd."], {"G": "#b0aca4", "g": "#8a8680", "d": "#5e5a56"})
	ore_img = Px.grid(["......", ".ggXg.", "gGgggd", ".dddd."], {"G": "#9a968e", "g": "#6e6a66", "d": "#46423e", "X": "#d8f4ea"})
	spring_img = Px.grid([".bbbb.", "bcwccb", "bcccwb", ".bbbb."], {"b": "#3a8aa8", "c": "#6fd6e8", "w": "#f0ffff"})
	shrub_img = Px.grid([".gg.g", "gGgGg", ".ggd."], {"G": "#a8964a", "g": "#8a7a3a", "d": "#5e5228"})
	tuft_img = Px.grid(["g.g", "gg."], {"g": Color(0.12, 0.27, 0.08, 0.55)})
	flower_img = Px.grid(["p", "g"], {"p": "#e87ac8", "g": "#3a7a2a"})


static func tree_variant(x: int, y: int, reg: int) -> int:
	var h: float = GuData.hash2(x, y, 77)
	var v: int = 0 if GuData.hash2(x, y, 78) < 0.6 else 1
	var p: int = 0
	match reg:
		4:
			p = 0 if h < 0.4 else (3 if h < 0.65 else (4 if h < 0.85 else 1))
		1:
			p = 1 if h < 0.38 else (0 if h < 0.6 else (4 if h < 0.8 else 2))
		0:
			p = 3 if h < 0.7 else 1
		3:
			p = 4 if h < 0.6 else 0
		_:
			p = 1 if h < 0.6 else 4
	return p * 2 + v


static func feat_image(f: int, x: int, y: int, reg: int) -> Image:
	match f:
		GuData.F_TREE:
			return tree_img[tree_variant(x, y, reg)]
		GuData.F_BAMB:
			return bamb_img
		GuData.F_PALM:
			return palm_img
		GuData.F_PINE:
			return pine_img
		GuData.F_ROCK:
			return rock_img
		GuData.F_ORE:
			return ore_img
		GuData.F_SPRING:
			return spring_img
		GuData.F_SHRUB:
			return shrub_img
		GuData.F_TUFT:
			return tuft_img
		GuData.F_FLOWER:
			return flower_img
	return null


## Gebäude-Texturen in der Farbe eines Clans (zwischengespeichert).
static func clan_textures(col: Color) -> Dictionary:
	var key: String = col.to_html(false)
	if _clan_cache.has(key):
		return _clan_cache[key]
	var C: Color = col
	var cd: Color = col.darkened(0.38)
	var cl: Color = col.lightened(0.3)
	var res: Dictionary = {}
	res["fire"] = ImageTexture.create_from_image(Px.grid([
		".g.L.L.g.",
		"g.LLLLL.g",
		".gLlLlLg.",
		"..g.g.g.."], {"g": "#9a968e", "L": "#7a5030", "l": "#5a3a20"}))
	res["hall"] = ImageTexture.create_from_image(Px.grid([
		".......Y.......",
		"......CCC......",
		".c...CCCCC...c.",
		".lCCCCCCCCCCCl.",
		"..ccccccccccc..",
		"...PwwwwwwwP...",
		".lCCCCCCCCCCCl.",
		"cCCCCCCCCCCCCCc",
		".ccccccccccccc.",
		"..PwwPwDDwPwwPS",
		"..PwwPwDDwPwwPS",
		".GGGGGGGGGGGGGS",
		"GgggggggggggggG"], {"C": C, "c": cd, "l": cl, "Y": "#f0c040", "P": "#c63a2a", "w": "#6a4a30", "D": "#20140c", "G": "#b4ae9e", "g": "#8a847a", "S": S_SHADOW}))
	res["house"] = ImageTexture.create_from_image(Px.grid([
		"....R....",
		"...RRr...",
		"..RRRrr..",
		".RRRRrrr.",
		"cCCCCCCCc",
		".WWWDWWwS",
		".WWWDWWwS",
		".WwWDWwwS",
		".KKKKKKKS",
		"..SSSSSS."], {"R": "#d2aa58", "r": "#9e7836", "C": C, "c": cd, "W": "#e6d49a", "w": "#b49e64", "D": "#3a2a1e", "K": "#6a5a40", "S": S_SHADOW}))
	res["forge"] = ImageTexture.create_from_image(Px.grid([
		"..CCC.....",
		".CCCCC....",
		"CcccccC...",
		".WWDW.mmm.",
		".WWDWmXXXm",
		".WWDWmmmmm",
		".KKKK.OmO.",
		"..SSSSSSSS"], {"C": C, "c": cd, "W": "#d8c48a", "D": "#3a2a1e", "K": "#6a5a40", "m": "#4a4a52", "X": "#8ff0c8", "O": "#ff8a3a", "S": S_SHADOW}))
	res["tower"] = ImageTexture.create_from_image(Px.grid([
		".lCCCl.",
		"cCCCCCc",
		".ccccc.",
		".bbbbb.",
		".p...p.",
		".pp.pp.",
		".p.p.p.",
		".pp.pp.",
		".p...p.",
		".pp.pp.",
		".p.p.pS",
		".p...pS",
		"KKKKKKS"], {"C": C, "c": cd, "l": cl, "b": "#9a6a3a", "p": "#7a5030", "K": "#5a4a36", "S": S_SHADOW}))
	var f: Px = Px.new(15, 12)
	f.p(1, 1, 13, 10, "#8a6a3e")
	for y: int in range(2, 10, 2):
		f.p(2, y + 1, 11, 1, "#6e5230")
		for x: int in range(2, 13):
			f.p(x, y, 1, 1, "#8fc04a" if (x + y) % 3 != 0 else "#d8c84a")
	f.p(0, 0, 15, 1, "#d8d8c8")
	f.p(0, 10, 15, 1, "#d8d8c8")
	f.p(0, 0, 1, 11, "#d8d8c8")
	f.p(14, 0, 1, 11, "#d8d8c8")
	for x: int in [0, 4, 10, 14]:
		f.p(x, 0, 1, 2, "#a87040")
		f.p(x, 9, 1, 2, "#a87040")
	f.p(1, 11, 14, 1, S_SHADOW)
	f.p(6, 10, 3, 1, C)
	res["farm"] = f.tex()
	_clan_cache[key] = res
	return res


# ---------------- Wesen ----------------
# Gezeichnet wird über einen Callable(rect: Rect2, col: Color), damit dieselbe Figur
# auf der Karte (draw_rect) und in Icons (Px) erscheint.

static func draw_person(sink: Callable, X: float, Y: float, sc: float, race: int, rank: int, cl: Color, f: int, adult: bool, moving: bool, anim: float, flash: bool, working: bool, rogue: bool, sick: bool, lucky: bool) -> void:
	var s: float = sc * (2.1 if rank >= 9 else (1.45 if rank >= 6 else 1.0))
	if not adult:
		s *= 0.72
	var P: Callable = func(x: float, y: float, w: float, h: float, c: Color) -> void:
		var rx: float = X + (x if f > 0 else -x - w) * s
		sink.call(Rect2(rx, Y + y * s, w * s, h * s), c)
	P.call(-2.0, 0.0, 4.0, 1.0, Color(0, 0, 0, 0.3))
	var st: int = (int(anim * 7.0) & 1) if moving else 0
	P.call(-1.5, -2.0 - (0.5 if st == 1 else 0.0), 1.0, 2.0, Color("#2a1d16"))
	P.call(0.5, -2.0 - (0.0 if st == 1 else 0.5), 1.0, 2.0, Color("#2a1d16"))
	if rank >= 6:
		P.call(-2.0, -4.0, 4.0, 2.4, cl)
	P.call(-1.5, -5.0, 3.0, 3.0, Color.WHITE if flash else cl)
	P.call(-1.5, -5.0, 3.0, 0.8, Color(1, 1, 1, 0.25))
	if rank > 0 and rank < 6:
		P.call(-1.5, -3.6, 3.0, 0.7, GuData.ESS_COL[rank])
	var skin: Color = GuData.RACE_SKIN[race]
	var hair: Color = GuData.RACE_HAIR[race]
	if race == 2:
		P.call(-1.5, -7.6, 3.0, 2.8, skin)
		P.call(-1.5, -7.6, 3.0, 0.6, hair)
	else:
		P.call(-1.0, -7.0, 2.0, 2.0, skin)
		P.call(-1.0, -7.5, 2.0, 0.8, hair)
	if race == 1:
		P.call(-1.5, -7.2, 0.6, 2.4, hair)
		P.call(0.9, -7.2, 0.6, 2.4, hair)
	if race == 3:
		P.call(0.4, -6.4, 0.6, 0.6, Color("#d8fff4"))
	if rank > 0:
		P.call(-0.5, -9.0, 1.0, 1.0, GuData.ESS_COL[rank])
	if rogue:
		P.call(0.2, -6.6, 0.6, 0.6, Color("#ff3030"))
	if sick:
		P.call(1.2, -8.2, 1.0, 1.0, Color("#86e04a"))
	if working:
		var up: bool = sin(anim * 14.0) > 0.0
		P.call(1.5, -6.0 if up else -5.0, 0.8, 2.2, Color("#a89a84"))
	if lucky and int(anim * 4.0) % 3 == 0:
		P.call(-2.6, -8.0, 0.8, 0.8, Color("#ffe27a"))


static func draw_animal(sink: Callable, X: float, Y: float, sc: float, sp: String, f: int, moving: bool, anim: float, flash: bool, tide: bool, uid: int) -> void:
	var s: float = sc
	if sp == "kingwolf":
		s *= 1.8
	elif sp == "ancient":
		s *= 3.0
	var P: Callable = func(x: float, y: float, w: float, h: float, c: Color) -> void:
		var rx: float = X + (x if f > 0 else -x - w) * s
		sink.call(Rect2(rx, Y + y * s, w * s, h * s), c)
	var st: int = (int(anim * 8.0) & 1) if moving else 0
	match sp:
		"wolf", "kingwolf":
			var kw: bool = sp == "kingwolf"
			if kw:
				P.call(-4.0, -7.0, 8.0, 7.0, Color(1, 0.95, 0.48, 0.18 + 0.1 * sin(anim * 9.0)))
			var b: Color = Color.WHITE if flash else (Color("#c4d2e6") if kw else (Color("#6e7278") if tide else Color("#80848a")))
			var l: Color = Color("#e2ecf8") if kw else Color("#9aa0a6")
			var d: Color = Color("#8a9ab0") if kw else Color("#5a5e62")
			P.call(-3.0, 0.0, 6.0, 1.0, Color(0, 0, 0, 0.28))
			P.call(-3.0, -3.0, 5.0, 2.0, b)
			P.call(-3.0, -3.0, 5.0, 0.7, l)
			P.call(2.0, -4.0, 2.0, 2.0, b)
			P.call(3.0, -5.0, 1.0, 1.0, d)
			P.call(4.0, -3.3, 0.8, 0.7, Color("#2a2a2a"))
			P.call(-4.0, -3.6, 1.0, 1.0, b)
			P.call(-2.5, -1.0 - (0.4 if st == 1 else 0.0), 1.0, 1.0, d)
			P.call(0.5, -1.0 - (0.0 if st == 1 else 0.4), 1.0, 1.0, d)
			P.call(2.6, -3.8, 0.6, 0.6, Color("#ffdf4a") if (tide or kw) else Color("#1a1a1a"))
			if kw:
				P.call(1.8, -6.2, 2.4, 0.8, Color("#ffe46a"))
				P.call(1.8, -6.8, 0.6, 0.6, Color("#ffe46a"))
				P.call(3.6, -6.8, 0.6, 0.6, Color("#ffe46a"))
				P.call(2.7, -7.0, 0.6, 0.8, Color("#ffe46a"))
		"boar":
			P.call(-3.0, 0.0, 6.0, 1.0, Color(0, 0, 0, 0.28))
			P.call(-3.0, -3.5, 5.0, 2.5, Color.WHITE if flash else Color("#4a3324"))
			P.call(-3.0, -3.5, 5.0, 0.6, Color("#6a4a32"))
			P.call(2.0, -3.0, 2.0, 2.0, Color("#3a2618"))
			P.call(3.6, -1.8, 0.8, 0.8, Color("#f0e6d0"))
			P.call(-2.5, -1.0, 1.0, 1.0, Color("#2a1a10"))
			P.call(0.8, -1.0, 1.0, 1.0, Color("#2a1a10"))
		"deer":
			P.call(-2.5, 0.0, 5.0, 1.0, Color(0, 0, 0, 0.25))
			P.call(-2.0, -3.0, 4.0, 1.8, Color.WHITE if flash else Color("#b47c48"))
			P.call(1.4, -5.0, 1.0, 2.4, Color("#b47c48"))
			P.call(1.6, -6.0, 1.8, 1.2, Color("#c48c58"))
			P.call(1.6, -7.6, 0.5, 1.6, Color("#e0d0a8"))
			P.call(2.9, -7.6, 0.5, 1.6, Color("#e0d0a8"))
			P.call(1.6, -7.8, 1.8, 0.5, Color("#e0d0a8"))
			P.call(-1.6, -1.2 - (0.3 if st == 1 else 0.0), 0.6, 1.2, Color("#7a5432"))
			P.call(1.0, -1.2 - (0.0 if st == 1 else 0.3), 0.6, 1.2, Color("#7a5432"))
			P.call(-2.3, -3.0, 0.6, 0.6, Color("#f0e0c8"))
		"monkey":
			P.call(-1.5, 0.0, 3.0, 1.0, Color(0, 0, 0, 0.25))
			P.call(-1.5, -3.5, 3.0, 2.5, Color.WHITE if flash else Color("#7a5530"))
			P.call(-1.0, -5.2, 2.0, 1.8, Color("#8a6540"))
			P.call(-0.4, -4.7, 1.0, 0.8, Color("#e0b890"))
			P.call(-2.6, -4.2, 1.0, 2.0, Color("#6a4524"))
			P.call(-1.2, -1.0, 0.8, 1.0, Color("#5a3a1e"))
			P.call(0.4, -1.0, 0.8, 1.0, Color("#5a3a1e"))
		"crane":
			P.call(-2.0, 0.0, 4.0, 1.0, Color(0, 0, 0, 0.2))
			P.call(-2.0, -3.2, 3.0, 1.6, Color("#dddddd") if flash else Color("#f2f2ee"))
			P.call(-2.7, -3.0, 1.0, 1.0, Color("#2a2a2a"))
			P.call(0.6, -6.0, 0.6, 3.0, Color("#f2f2ee"))
			P.call(0.6, -6.6, 1.4, 0.8, Color("#f2f2ee"))
			P.call(0.9, -6.9, 0.6, 0.5, Color("#d8302a"))
			P.call(2.0, -6.4, 1.0, 0.4, Color("#c8b060"))
			P.call(-1.0, -1.6, 0.4, 1.6, Color("#3a3a3a"))
			P.call(0.0, -1.6, 0.4, 1.6, Color("#3a3a3a"))
		"ancient":
			P.call(-5.0, -7.0, 10.0, 7.5, Color(1, 0.3, 0.16, 0.2))
			P.call(-3.5, 0.0, 7.0, 1.0, Color(0, 0, 0, 0.35))
			P.call(-3.5, -3.6, 6.0, 3.0, Color.WHITE if flash else Color("#5a1e22"))
			P.call(-3.5, -3.6, 6.0, 0.7, Color("#7a2a2e"))
			P.call(2.0, -4.4, 2.4, 2.6, Color("#4a161a"))
			P.call(3.4, -3.8, 0.6, 0.6, Color("#ffcf3a"))
			P.call(2.2, -5.6, 0.6, 1.4, Color("#e6d6ae"))
			P.call(3.6, -5.8, 0.6, 1.4, Color("#e6d6ae"))
			P.call(-3.0, -1.0, 1.2, 1.2, Color("#3a1012"))
			P.call(1.0, -1.0, 1.2, 1.2, Color("#3a1012"))
			P.call(-4.4, -3.4, 1.0, 0.8, Color("#5a1e22"))
			for k: int in range(3):
				P.call(-2.6 + k * 1.6, -4.3, 0.7, 0.8, Color("#8a3a3a"))
		"wildgu":
			var bb: float = 0.55 + 0.45 * sin(anim * 6.0 + uid)
			P.call(-1.5, -5.0, 3.0, 3.0, Color(0.6, 0.83, 1.0, 0.35 * bb))
			P.call(-0.5, -3.5, 1.0, 1.0, Color("#f0faff") if bb > 0.5 else Color("#bfe0ff"))
