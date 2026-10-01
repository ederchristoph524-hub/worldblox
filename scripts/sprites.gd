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


## Gebäude-Texturen in der Farbe eines Clans (zwischengespeichert), optional je Volk.
## Schlüssel: fire, hall1, hall2 (= hall), tent, tent_b, hut, hut_b, house, house_b, farm, pen, forge, tower.
static func clan_textures(col: Color, race: int = 0) -> Dictionary:
	var key: String = col.to_html(false) + str(race)
	if _clan_cache.has(key):
		return _clan_cache[key]
	var C: Color = col
	var cr: Color = col.darkened(0.22)
	var cd: Color = col.darkened(0.5)
	var cl: Color = col.lightened(0.28)
	var res: Dictionary = {}
	# --- Lagerfeuer (Dorfmitte, Stufe 0) ---
	res["fire"] = _bt(Px.grid([
		"...........",
		".g.BBBBB.g.",
		"gGBb...bBGg",
		".gBb...bBg.",
		"..BBBBBBB..",
		".g.b...b.g.",
		"..YY...YY.."], {"g": "#8a8a84", "G": "#c4c4bc", "B": "#7a5432", "b": "#55361e", "Y": "#d8b050"}))
	# --- Zelte (Volk bestimmt die Plane) ---
	var tp: Array = [["#e6fff6", "#a4e8dc", "#6fc4bc", "#3f8e94"], ["#f0d8b0", "#c89a68", "#a07448", "#6e4c2e"],
		["#ecece4", "#bcb8ae", "#8e8a82", "#64605a"], ["#f0fbff", "#a8d4f0", "#74a8d8", "#4a74a8"]][clampi(race, 0, 3)]
	var tent: Array = [
		"...Pp..",
		"...B...",
		"..WLM..",
		".WLLMD.",
		"YLLLMMY",
		"BLkkkMB",
		"YMKKKDY",
		"BBKKKBB"]
	var tpal: Dictionary = {"P": C, "p": cd, "W": tp[0], "L": tp[1], "M": tp[2], "D": tp[3], "Y": "#e8b850", "B": "#8a5a2e", "k": "#6a3e20", "K": "#1a1210"}
	res["tent"] = _bt(Px.grid(tent, tpal))
	res["tent_b"] = _bt(Px.grid(_flip(tent), tpal))
	# --- Holzhütten ---
	var hut: Array = [
		"...hTt...",
		".hTTTttt.",
		"TThTTthtt",
		"ttttttttt",
		".WCWWWWW.",
		".wOwDDww.",
		".WWWDDWW.",
		".kkkkkkk."]
	var hpal: Dictionary = {"C": C, "T": "#c8884a", "t": "#94582c", "h": "#e4ae64", "W": "#9c6a3a", "w": "#7a4e2a", "D": "#2e1c12", "O": "#ffd27a", "k": "#6a5a48"}
	if race == 2:
		hpal["W"] = "#8e8a84"
		hpal["w"] = "#6a6660"
	res["hut"] = _bt(Px.grid(hut, hpal))
	res["hut_b"] = _bt(Px.grid(_flip(hut), hpal))
	# --- Häuser mit Clan-Dach ---
	var hpal2: Dictionary = {"R": C, "r": cr, "c": cd, "l": cl, "P": "#ecdcbc", "p": "#b8a684", "O": "#5a7a9a", "o": "#ffd27a", "D": "#5a3a22", "G": "#9a968e", "m": "#8a7e74"}
	res["house"] = _bt(Px.grid([
		"......mm.",
		"...lRRmm.",
		"..lRrRRr.",
		".lRRRRRrr",
		"lRrRRRrRr",
		"ccccccccc",
		".PPPPPPp.",
		".POPDPop.",
		".PPPDPPp.",
		".GGGGGGG."], hpal2))
	res["house_b"] = _bt(Px.grid([
		"....l....",
		"...lRR...",
		"..lRRRr..",
		".lRrRRrr.",
		"ccccccccc",
		".PoPPOPp.",
		".PPPPPPp.",
		"lRRRRRRrr",
		"ccccccccc",
		".POPDPOp.",
		".PPPDPPp.",
		".GGGGGGG."], hpal2))
	# --- Ahnenhallen ---
	res["hall1"] = _bt(Px.grid([
		".....Y.....",
		"....lRr....",
		"c..lRRRr..c",
		"lllRRRRRrrr",
		"lRRRrRRRrRr",
		".ccccccccc.",
		"XWoWXDXWoWX",
		"XWWWXDXWWWX",
		"GGGGGGGGGGG",
		".ggggggggg."], {"Y": "#f0c040", "R": C, "r": cr, "c": cd, "l": cl, "X": "#c63a2a", "W": "#8a5a34", "o": "#ffd27a", "D": "#20140c", "G": "#b4ae9e", "g": "#8a847a"}))
	res["hall2"] = _bt(Px.grid([
		".......Y.......",
		"......lRr......",
		".c...lRRRr...c.",
		".lllRRRRRRrrrl.",
		"..ccccccccccc..",
		"...XwowowowX...",
		".lllRRRRRRRrrl.",
		"clRRRRRRRRRRRrc",
		".ccccccccccccc.",
		"..XwwXwDDwXwwX.",
		"..XwoXwDDwXowX.",
		".GGGGGGGGGGGGG.",
		"GgggggggggggggG"], {"Y": "#f0c040", "R": C, "r": cr, "c": cd, "l": cl, "X": "#c63a2a", "w": "#6a4a30", "o": "#ffd27a", "D": "#20140c", "G": "#b4ae9e", "g": "#8a847a"}))
	res["hall"] = res["hall2"]
	# --- Gu-Veredelung (Schmiede) ---
	res["forge"] = _bt(Px.grid([
		"..lCC.mm..",
		".lCCCCmm..",
		"cCCCCCCc..",
		".WWDW.MMM.",
		".WWDWMXXXM",
		".WWDWMMMMM",
		".KKKK.OmO."], {"C": C, "c": cd, "l": cl, "W": "#d8c48a", "D": "#3a2a1e", "K": "#6a5a40", "m": "#6a625a", "M": "#4a4a52", "X": "#8ff0c8", "O": "#ff8a3a"}))
	# --- Wachturm ---
	res["tower"] = _bt(Px.grid([
		"...F...",
		"...FCC.",
		"...FC..",
		".lCCCl.",
		"cCCCCCc",
		".ccccc.",
		".bbbbb.",
		".p.o.p.",
		".pp.pp.",
		".p.p.p.",
		".pp.pp.",
		".p...p.",
		".pp.pp.",
		"KKKKKKK"], {"F": "#5a4030", "C": C, "c": cd, "l": cl, "b": "#9a6a3a", "p": "#7a5030", "o": "#ffd27a", "K": "#5a4a36"}))
	# --- Felder und Gehege (15 × 11 wie die Grundfläche, Zaun ragt 1 nach oben) ---
	res["farm"] = _bt(_farm_img(C, false))
	res["pen"] = _bt(_farm_img(C, true))
	_clan_cache[key] = res
	return res


static func _flip(rows: Array) -> Array:
	var out: Array = []
	for r: String in rows:
		out.append(r.reverse())
	return out


## Baut eine Gebäude-Textur: Schlagschatten nach rechts unten wie in WorldBox.
static func _bt(im: Image) -> ImageTexture:
	var q: Px = Px.new(im.get_width() + 2, im.get_height() + 1)
	q.draw_image(im, 1, 1)
	q.outline(Color(0.13, 0.09, 0.06, 0.55))
	return ImageTexture.create_from_image(Px.drop_shadow(q.img, S_SHADOW))


static func _farm_img(C: Color, pen: bool) -> Image:
	var f: Px = Px.new(15, 12)
	var F: Color = Color("#c4d2be")
	var Fs: Color = Color("#8ea08a")
	var Y: Color = Color("#e4b44e")
	var B: Color = Color("#a8743c")
	var Bd: Color = Color("#6e4c28")
	var sh: Color = Color(0.05, 0.14, 0.04, 0.35)
	if not pen:
		# Ackerfurchen mit Ähren
		for y: int in range(2, 10):
			for x: int in range(1, 14):
				var soil: bool = y % 2 == 1
				if soil:
					f.p(x, y, 1, 1, "#7a5a34" if (x + y) % 3 else "#6a4c2c")
				else:
					var ripe: bool = GuData.hash2(x, y, 5) < 0.35
					f.p(x, y, 1, 1, Color("#d8c04a") if ripe else (Color("#8cc444") if (x * 7 + y) % 4 else Color("#a8d858")))
		f.p(1, 2, 13, 1, sh)
	else:
		# Gehege: Heuhaufen, Trog, Stall
		f.p(2, 3, 3, 2, "#e0c060")
		f.p(2, 3, 3, 1, "#f0d878")
		f.p(2, 5, 3, 1, "#a88a34")
		f.p(10, 3, 3, 2, "#8a5a30")
		f.p(10, 3, 3, 1, C)
		f.p(11, 4, 1, 1, "#2a1a10")
		f.p(9, 8, 3, 1, "#6a4a2a")
		f.p(10, 8, 1, 1, "#7ab0d8")
		f.p(1, 2, 13, 1, sh)
	# Zaun
	f.p(0, 1, 15, 1, F)
	f.p(0, 10, 5, 1, F)
	f.p(10, 10, 5, 1, F)
	f.p(0, 1, 1, 10, F)
	f.p(14, 1, 1, 10, F)
	f.p(1, 2, 1, 8, Fs)
	f.p(0, 11, 5, 1, sh)
	f.p(10, 11, 5, 1, sh)
	var posts: Array[Vector2i] = [Vector2i(0, 0), Vector2i(5, 0), Vector2i(9, 0), Vector2i(14, 0), Vector2i(0, 4), Vector2i(14, 4), Vector2i(0, 9), Vector2i(4, 9), Vector2i(10, 9), Vector2i(14, 9)]
	for p: Vector2i in posts:
		f.p(p.x, p.y, 1, 1, Y)
		f.p(p.x, p.y + 1, 1, 1, B)
		f.p(p.x, p.y + 2, 1, 1, Bd)
	f.p(7, 0, 1, 1, C)
	return f.img


## Welche Textur ein Gebäude je nach Dorfgröße zeigt (Zelte → Hütten → Häuser).
static func village_tier(v: Village) -> int:
	if v.lvl == 0:
		return 0
	if v.pop >= 26 or v.houses >= 8:
		return 2
	return 1


static func building_key(b: Building, v: Village) -> String:
	var h: float = GuData.hash2(b.id, b.x, 913)
	var alt: bool = GuData.hash2(b.y, b.id, 377) < 0.5
	match b.type:
		"hall":
			if v.lvl == 0:
				return "fire"
			return "hall2" if village_tier(v) == 2 else "hall1"
		"house":
			var t: int = village_tier(v)
			if t > 0 and h < 0.3:
				t -= 1
			var base: String = ["tent", "hut", "house"][t]
			return base + ("_b" if alt else "")
		"farm":
			return "pen" if h < 0.45 else "farm"
	return b.type


## Bodenmitte (Tür) eines Gebäudes in Kacheln – Ziel der Dorfwege.
static func door(b: Building) -> Vector2:
	return Vector2(b.x + floorf(b.w * 0.5), b.y + b.h)


## Kleine Tiere, die im Gehege umherlaufen (in Kachel-Koordinaten).
static func draw_pen_animals(sink: Callable, bx: float, by: float, t: float, sd: int) -> void:
	for k: int in range(3):
		var ph: float = t * (0.18 + 0.05 * k) + sd * 1.7 + k * 2.1
		var ax: float = bx + 4.0 + k * 2.6 + sin(ph) * 2.4
		var ay: float = by + 6.0 + (k % 2) * 1.6 + cos(ph * 0.7) * 1.2
		var f: int = 1 if cos(ph) > 0.0 else -1
		var kind: int = (sd + k) % 3
		var step: float = 0.15 if int(t * 5.0 + k) % 2 == 0 else 0.0
		var P: Callable = func(x: float, y: float, w: float, hh: float, c: Color) -> void:
			var rx: float = ax + (x if f > 0 else -x - w)
			sink.call(Rect2(rx, ay + y, w, hh), c)
		P.call(-1.0, 0.1, 2.2, 0.4, Color(0, 0, 0, 0.25))
		match kind:
			0:  # Schaf
				P.call(-1.0, -1.3, 1.8, 1.1, Color("#f2f0e8"))
				P.call(-1.0, -1.3, 1.8, 0.35, Color.WHITE)
				P.call(0.7, -1.5, 0.7, 0.8, Color("#3a3230"))
				P.call(-0.8, -0.2 - step, 0.35, 0.4, Color("#3a3230"))
				P.call(0.3, -0.2 - (0.15 - step), 0.35, 0.4, Color("#3a3230"))
			1:  # Schwein
				P.call(-1.0, -1.1, 1.9, 1.0, Color("#eaa0a0"))
				P.call(-1.0, -1.1, 1.9, 0.3, Color("#f6c0bc"))
				P.call(0.85, -0.9, 0.45, 0.5, Color("#d07a7a"))
				P.call(-0.8, -0.15 - step, 0.35, 0.3, Color("#b86a6a"))
				P.call(0.4, -0.15 - (0.15 - step), 0.35, 0.3, Color("#b86a6a"))
			_:  # Huhn
				P.call(-0.5, -0.9, 1.0, 0.8, Color("#f8f4ec"))
				P.call(0.3, -1.3, 0.5, 0.5, Color("#f8f4ec"))
				P.call(0.45, -1.55, 0.3, 0.3, Color("#e03a2a"))
				P.call(0.8, -1.15, 0.3, 0.2, Color("#f0b030"))
				P.call(-0.1, -0.1, 0.25, 0.25, Color("#f0b030"))


# ---------------- Wesen ----------------
# Gezeichnet wird über einen Callable(rect: Rect2, col: Color), damit dieselbe Figur
# auf der Karte (draw_rect) und in Icons (Px) erscheint. Mit ol > 0 bekommt jede Figur
# eine dunkle Kontur der Breite ol (in Figur-Einheiten), wie die WorldBox-Sprites.

const OUTLINE: Color = Color(0.07, 0.06, 0.06, 0.92)
## Konturfarbe; die Karte blendet sie im Fernblick aus (siehe EntityLayer).
static var outline_col: Color = OUTLINE


static func _emit(sink: Callable, parts: Array, ol: float) -> void:
	if ol > 0.0:
		for e: Array in parts:
			var c: Color = e[1]
			if c.a >= 0.9:
				sink.call((e[0] as Rect2).grow(ol), outline_col)
	for e: Array in parts:
		sink.call(e[0], e[1])


static func draw_person(sink: Callable, X: float, Y: float, sc: float, race: int, rank: int, cl: Color, f: int, adult: bool, moving: bool, anim: float, flash: bool, working: bool, rogue: bool, sick: bool, lucky: bool, ol: float = 0.0, tnow: float = 0.0) -> void:
	var imm: bool = rank >= 6
	var s: float = sc * (2.1 if rank >= 9 else (1.45 if imm else 1.0))
	if not adult:
		s *= 0.72
	var parts: Array = []
	var st: int = (int(anim * 7.0) & 1) if moving else 0
	var bob: float = -0.5 if st == 1 else 0.0
	var P: Callable = func(x: float, y: float, w: float, h: float, c: Color) -> void:
		var rx: float = X + (x if f > 0 else -x - w) * s
		parts.append([Rect2(rx, Y + y * s, w * s, h * s), c])
	# Aura der Uressenz
	if rank > 0:
		var ec: Color = GuData.ESS_COL[rank]
		var pul: float = 0.5 + 0.5 * sin(tnow * 3.0 + X * 0.7)
		var ga: float = (0.09 + 0.05 * pul) if imm else (0.06 + 0.05 * pul)
		var gr: float = 1.0 if imm else 0.7
		# ovaler Schein aus drei Lagen
		P.call(-3.0 * gr, -8.0 - gr, 6.0 * gr, 6.0 + gr, Color(ec, ga))
		P.call(-2.2 * gr, -9.0 - gr, 4.4 * gr, 9.0 + gr, Color(ec, ga))
		P.call(-1.6 * gr, -9.6 - gr, 3.2 * gr, 10.0 + gr, Color(ec, ga * 0.8))
	P.call(-2.0, -0.5, 4.0, 1.0, Color(0, 0, 0, 0.28))
	var skin: Color = Color.WHITE if flash else GuData.RACE_SKIN[race]
	var hair: Color = GuData.RACE_HAIR[race]
	var shirt: Color = Color.WHITE if flash else cl
	var pants: Color = Color("#3a2c26") if not rogue else Color("#241820")
	# Beine
	if moving:
		P.call(-1.0, -2.0 - (0.6 if st == 1 else 0.0), 1.0, 2.0 - (0.0 if st == 1 else 0.0), pants)
		P.call(0.0, -2.0 - (0.0 if st == 1 else 0.6), 1.0, 2.0, pants)
	else:
		P.call(-1.0, -2.0, 1.0, 2.0, pants)
		P.call(0.0, -2.0, 1.0, 2.0, pants)
	# Körper
	if imm:
		P.call(-1.5, -5.0 + bob, 3.0, 4.2, shirt)
		P.call(-1.5, -5.0 + bob, 1.0, 4.2, shirt.darkened(0.25))
		P.call(-1.5, -3.2 + bob, 3.0, 0.6, GuData.ESS_COL[rank])
	else:
		P.call(-1.5, -5.0 + bob, 3.0, 3.0, shirt)
		P.call(-1.5, -5.0 + bob, 1.0, 3.0, shirt.darkened(0.25))
		P.call(-1.0, -5.0 + bob, 2.0, 0.5, shirt.darkened(0.4))
		if rank > 0:
			P.call(-1.5, -2.7 + bob, 3.0, 0.6, GuData.ESS_COL[rank])
		else:
			P.call(-1.5, -2.6 + bob, 3.0, 0.5, Color("#5a3e26"))
	# Kopf
	var hy: float = -7.0 + bob
	if race == 2:
		P.call(-1.2, hy - 0.4, 2.6, 2.4, skin)
		P.call(-1.2, hy - 0.4, 2.6, 0.6, hair)
	else:
		P.call(-1.0, hy, 2.0, 2.0, skin)
		P.call(-1.0, hy - 0.4, 2.0, 0.8, hair)
		P.call(-1.0, hy, 0.6, 1.2, hair)
	if race == 1:
		P.call(-1.0, hy + 1.0, 2.0, 0.6, hair)
	if race == 3:
		P.call(-1.6, hy + 0.2, 0.6, 1.0, Color("#3a9a8a"))
	P.call(0.6, hy + 0.7, 0.4, 0.5, Color("#1a1210") if not rogue else Color("#ff3030"))
	# Arm und Werkzeug
	if working:
		var up: bool = sin(anim * 14.0) > 0.0
		if up:
			P.call(1.2, -5.2 + bob, 0.8, 1.2, skin)
			P.call(1.5, -8.0 + bob, 0.6, 3.2, Color("#8a5a30"))
			P.call(1.0, -8.4 + bob, 1.6, 0.7, Color("#b8b8c0"))
		else:
			P.call(1.2, -4.4 + bob, 0.8, 1.2, skin)
			P.call(1.8, -4.2 + bob, 2.4, 0.6, Color("#8a5a30"))
			P.call(3.8, -5.0 + bob, 0.7, 1.6, Color("#b8b8c0"))
	else:
		P.call(1.2, -4.6 + bob, 0.6, 1.6, skin)
	if rank >= 9:
		P.call(-1.0, hy - 1.4, 2.0, 0.6, Color("#ffd24a"))
		P.call(-1.0, hy - 2.0, 0.5, 0.6, Color("#ffd24a"))
		P.call(0.5, hy - 2.0, 0.5, 0.6, Color("#ffd24a"))
	if sick:
		P.call(1.4, hy - 1.4, 0.8, 0.8, Color("#86e04a"))
	_emit(sink, parts, ol * s)
	if lucky and int(anim * 4.0) % 3 == 0:
		var rx2: float = X + (-2.8 if f > 0 else 2.0) * s
		sink.call(Rect2(rx2, Y - 8.0 * s, 0.8 * s, 0.8 * s), Color("#ffe27a"))


static func draw_animal(sink: Callable, X: float, Y: float, sc: float, sp: String, f: int, moving: bool, anim: float, flash: bool, tide: bool, uid: int, ol: float = 0.0) -> void:
	var s: float = sc
	if sp == "kingwolf":
		s *= 1.8
	elif sp == "ancient":
		s *= 3.0
	var parts: Array = []
	var P: Callable = func(x: float, y: float, w: float, h: float, c: Color) -> void:
		var rx: float = X + (x if f > 0 else -x - w) * s
		parts.append([Rect2(rx, Y + y * s, w * s, h * s), c])
	var st: int = (int(anim * 8.0) & 1) if moving else 0
	var bob: float = -0.3 if st == 1 else 0.0
	match sp:
		"wolf", "kingwolf":
			var kw: bool = sp == "kingwolf"
			if kw:
				P.call(-4.0, -7.0, 8.0, 7.0, Color(1, 0.95, 0.48, 0.18 + 0.1 * sin(anim * 9.0)))
			var b: Color = Color.WHITE if flash else (Color("#c4d2e6") if kw else (Color("#6e7278") if tide else Color("#80848a")))
			var l: Color = Color("#e2ecf8") if kw else Color("#a4aab0")
			var d: Color = Color("#8a9ab0") if kw else Color("#4e5256")
			P.call(-3.0, -0.4, 6.0, 0.8, Color(0, 0, 0, 0.28))
			P.call(-2.5, -1.2 - (0.4 if st == 1 else 0.0), 1.0, 1.2, d)
			P.call(0.8, -1.2 - (0.0 if st == 1 else 0.4), 1.0, 1.2, d)
			P.call(-3.0, -3.0 + bob, 5.0, 2.0, b)
			P.call(-3.0, -3.0 + bob, 5.0, 0.7, l)
			P.call(2.0, -4.0 + bob, 2.0, 2.0, b)
			P.call(3.0, -4.8 + bob, 0.8, 0.9, d)
			P.call(2.0, -4.8 + bob, 0.8, 0.9, d)
			P.call(4.0, -3.0 + bob, 0.8, 0.7, Color("#2a2a2a"))
			P.call(-4.0, -3.6 + bob, 1.0, 1.0, b)
			P.call(2.8, -3.6 + bob, 0.6, 0.6, Color("#ffdf4a") if (tide or kw) else Color("#1a1a1a"))
			if kw:
				P.call(1.8, -6.2, 2.4, 0.8, Color("#ffe46a"))
				P.call(1.8, -6.8, 0.6, 0.6, Color("#ffe46a"))
				P.call(3.6, -6.8, 0.6, 0.6, Color("#ffe46a"))
				P.call(2.7, -7.0, 0.6, 0.8, Color("#ffe46a"))
		"boar":
			P.call(-3.0, -0.4, 6.0, 0.8, Color(0, 0, 0, 0.28))
			P.call(-2.5, -1.2 - (0.4 if st == 1 else 0.0), 1.0, 1.2, Color("#2a1a10"))
			P.call(0.8, -1.2 - (0.0 if st == 1 else 0.4), 1.0, 1.2, Color("#2a1a10"))
			P.call(-3.0, -3.5 + bob, 5.0, 2.5, Color.WHITE if flash else Color("#4a3324"))
			P.call(-3.0, -3.5 + bob, 5.0, 0.6, Color("#6a4a32"))
			P.call(2.0, -3.0 + bob, 2.0, 2.0, Color("#3a2618"))
			P.call(3.6, -1.8 + bob, 0.8, 0.8, Color("#f0e6d0"))
		"deer":
			P.call(-2.5, -0.4, 5.0, 0.8, Color(0, 0, 0, 0.25))
			P.call(-1.6, -1.4 - (0.3 if st == 1 else 0.0), 0.6, 1.4, Color("#7a5432"))
			P.call(1.0, -1.4 - (0.0 if st == 1 else 0.3), 0.6, 1.4, Color("#7a5432"))
			P.call(-2.0, -3.0 + bob, 4.0, 1.8, Color.WHITE if flash else Color("#b47c48"))
			P.call(1.4, -5.0 + bob, 1.0, 2.4, Color("#b47c48"))
			P.call(1.6, -6.0 + bob, 1.8, 1.2, Color("#c48c58"))
			P.call(1.6, -7.6 + bob, 0.5, 1.6, Color("#e0d0a8"))
			P.call(2.9, -7.6 + bob, 0.5, 1.6, Color("#e0d0a8"))
			P.call(-2.3, -3.0 + bob, 0.6, 0.6, Color("#f0e0c8"))
		"monkey":
			P.call(-1.5, -0.4, 3.0, 0.8, Color(0, 0, 0, 0.25))
			P.call(-1.2, -1.0, 0.8, 1.0, Color("#5a3a1e"))
			P.call(0.4, -1.0, 0.8, 1.0, Color("#5a3a1e"))
			P.call(-1.5, -3.5 + bob, 3.0, 2.5, Color.WHITE if flash else Color("#7a5530"))
			P.call(-1.0, -5.2 + bob, 2.0, 1.8, Color("#8a6540"))
			P.call(-0.2, -4.7 + bob, 1.0, 0.8, Color("#e0b890"))
			P.call(-2.6, -4.2 + bob, 1.0, 2.0, Color("#6a4524"))
		"crane":
			P.call(-2.0, -0.4, 4.0, 0.8, Color(0, 0, 0, 0.2))
			P.call(-1.0, -1.6, 0.4, 1.6, Color("#3a3a3a"))
			P.call(0.0, -1.6, 0.4, 1.6, Color("#3a3a3a"))
			P.call(-2.0, -3.2 + bob, 3.0, 1.6, Color("#dddddd") if flash else Color("#f2f2ee"))
			P.call(-2.7, -3.0 + bob, 1.0, 1.0, Color("#2a2a2a"))
			P.call(0.6, -6.0 + bob, 0.6, 3.0, Color("#f2f2ee"))
			P.call(0.6, -6.6 + bob, 1.4, 0.8, Color("#f2f2ee"))
			P.call(0.9, -6.9 + bob, 0.6, 0.5, Color("#d8302a"))
			P.call(2.0, -6.4 + bob, 1.0, 0.4, Color("#c8b060"))
		"ancient":
			P.call(-5.0, -7.0, 10.0, 7.5, Color(1, 0.3, 0.16, 0.2))
			P.call(-3.5, -0.4, 7.0, 0.8, Color(0, 0, 0, 0.35))
			P.call(-3.0, -1.2, 1.2, 1.2, Color("#3a1012"))
			P.call(1.0, -1.2, 1.2, 1.2, Color("#3a1012"))
			P.call(-3.5, -3.6 + bob, 6.0, 3.0, Color.WHITE if flash else Color("#5a1e22"))
			P.call(-3.5, -3.6 + bob, 6.0, 0.7, Color("#7a2a2e"))
			P.call(2.0, -4.4 + bob, 2.4, 2.6, Color("#4a161a"))
			P.call(3.4, -3.8 + bob, 0.6, 0.6, Color("#ffcf3a"))
			P.call(2.2, -5.6 + bob, 0.6, 1.4, Color("#e6d6ae"))
			P.call(3.6, -5.8 + bob, 0.6, 1.4, Color("#e6d6ae"))
			P.call(-4.4, -3.4 + bob, 1.0, 0.8, Color("#5a1e22"))
			for k: int in range(3):
				P.call(-2.6 + k * 1.6, -4.3 + bob, 0.7, 0.8, Color("#8a3a3a"))
		"wildgu":
			var bb: float = 0.55 + 0.45 * sin(anim * 6.0 + uid)
			P.call(-1.5, -5.0, 3.0, 3.0, Color(0.6, 0.83, 1.0, 0.35 * bb))
			P.call(-0.5, -3.5, 1.0, 1.0, Color("#f0faff") if bb > 0.5 else Color("#bfe0ff"))
			_emit(sink, parts, 0.0)
			return
	_emit(sink, parts, ol * s)
