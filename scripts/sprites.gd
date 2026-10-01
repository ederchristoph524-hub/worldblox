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


static func draw_person(sink: Callable, X: float, Y: float, sc: float, race: int, rank: int, cl: Color, f: int, adult: bool, moving: bool, anim: float, flash: bool, working: bool, rogue: bool, sick: bool, lucky: bool, ol: float = 0.0, tnow: float = 0.0, ow: bool = false) -> void:
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
	if rank > 0 and not no_aura:
		var ec: Color = GuData.ESS_COL[rank]
		var pul: float = 0.5 + 0.5 * sin(tnow * 3.0 + X * 0.7)
		var ga: float = (0.09 + 0.05 * pul) if imm else (0.06 + 0.05 * pul)
		var gr: float = 1.0 if imm else 0.7
		# ovaler Schein aus drei Lagen
		P.call(-3.0 * gr, -8.0 - gr, 6.0 * gr, 6.0 + gr, Color(ec, ga))
		P.call(-2.2 * gr, -9.0 - gr, 4.4 * gr, 9.0 + gr, Color(ec, ga))
		P.call(-1.6 * gr, -9.6 - gr, 3.2 * gr, 10.0 + gr, Color(ec, ga * 0.8))
	if ow and not no_aura:
		var pa: float = 0.12 + 0.08 * sin(tnow * 5.0 + X)
		P.call(-2.6, -9.0, 5.2, 9.0, Color(0.75, 0.2, 1.0, pa))
	P.call(-2.0, -0.5, 4.0, 1.0, Color(0, 0, 0, 0.28))
	var skin: Color = Color.WHITE if flash else GuData.RACE_SKIN[race]
	var hair: Color = GuData.RACE_HAIR[race]
	var shirt: Color = Color.WHITE if flash else cl
	var pants: Color = Color("#3a2c26") if not rogue else Color("#241820")
	# Federschwingen (hinter dem Körper)
	if race == 4:
		var wf: float = sin(anim * 9.0) * 0.5 if moving else 0.0
		P.call(-3.4, -5.6 + bob - wf, 2.0, 3.2, Color("#f4ead8"))
		P.call(-3.8, -4.6 + bob - wf, 0.9, 2.4, Color("#e8d4b0"))
		P.call(-3.8, -3.0 + bob - wf, 0.9, 0.8, hair)
	elif race == 6:
		P.call(-2.8, -2.6 + bob, 1.4, 0.7, skin.darkened(0.15))
		P.call(-3.4, -2.2 + bob, 0.8, 0.6, skin.darkened(0.25))
	elif race == 7:
		P.call(-2.6, -3.6 + bob, 1.2, 0.6, hair)
		P.call(-3.0, -4.2 + bob, 0.7, 0.8, hair)
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
	# Volksmerkmale am Körper
	match race:
		5:
			P.call(-1.7, -5.3 + bob, 3.4, 0.8, Color("#f8fbff"))
		9:
			P.call(-1.5, -2.5 + bob, 0.5, 0.9, skin.darkened(0.3))
			P.call(1.0, -3.2 + bob, 0.5, 1.0, skin.darkened(0.3))
		10:
			P.call(-0.3, -4.8 + bob, 0.4, 2.4, Color("#6a4a2a"))
	# Kopf
	var hy: float = -7.0 + bob
	if race == 2:
		P.call(-1.2, hy - 0.4, 2.6, 2.4, skin)
		P.call(-1.2, hy - 0.4, 2.6, 0.6, hair)
		P.call(0.0, hy + 0.3, 0.4, 0.9, Color("#7a766e"))
	elif race == 8:
		P.call(-1.0, hy, 2.0, 2.0, skin)
		P.call(-1.9, hy - 1.4, 3.8, 1.3, hair)
		P.call(-1.4, hy - 2.0, 2.8, 0.7, hair)
		P.call(-1.1, hy - 1.6, 0.6, 0.5, Color("#fff6ee"))
		P.call(0.5, hy - 1.2, 0.6, 0.5, Color("#fff6ee"))
	elif race == 10:
		P.call(-1.0, hy, 2.0, 2.0, skin)
		P.call(-1.5, hy - 1.0, 3.0, 1.2, hair)
		P.call(-0.6, hy - 1.7, 1.4, 0.8, hair.lightened(0.25))
		P.call(-1.5, hy, 0.6, 0.8, hair)
	else:
		P.call(-1.0, hy, 2.0, 2.0, skin)
		P.call(-1.0, hy - 0.4, 2.0, 0.8, hair)
		P.call(-1.0, hy, 0.6, 1.2, hair)
	match race:
		1:
			P.call(-1.0, hy + 1.0, 2.0, 0.6, hair)
		3:
			P.call(-1.6, hy + 0.2, 0.6, 1.0, Color("#3a9a8a"))
		4:
			P.call(-0.8, hy - 1.4, 0.8, 1.1, hair)
			P.call(0.1, hy - 1.0, 0.6, 0.7, Color("#f0c040"))
		5:
			P.call(0.4, hy + 1.1, 0.6, 0.4, Color("#a8d4f0"))
		6:
			P.call(-0.9, hy - 1.3, 0.5, 1.0, Color("#e8c860"))
			P.call(0.5, hy - 1.3, 0.5, 1.0, Color("#e8c860"))
			P.call(-1.0, hy + 1.2, 2.0, 0.4, skin.darkened(0.2))
		7:
			P.call(-1.1, hy - 1.1, 0.6, 0.8, hair)
			P.call(0.6, hy - 1.1, 0.6, 0.8, hair)
	var eye: Color = Color("#1a1210")
	if rogue:
		eye = Color("#ff3030")
	elif ow:
		eye = Color("#d04aff")
	elif race == 6 or race == 7:
		eye = Color("#e8b020")
	P.call(0.6, hy + 0.7, 0.4, 0.5, eye)
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




static var _pal_cache: Dictionary = {}
## Für Icons: halbdurchsichtige Auren und Scheine weglassen.
static var no_aura: bool = false


## Palette einer Tierart: [Haupt, Licht, Akzent] aus GuData.SPEC (zwischengespeichert).
static func _pal(sp: String) -> Array:
	if _pal_cache.has(sp):
		return _pal_cache[sp]
	var cs: Array = GuData.SPEC[sp].get("cols", ["#80848a", "#a4aab0", "#4e5256"])
	var out: Array = [Color(str(cs[0])), Color(str(cs[1])), Color(str(cs[2]))]
	_pal_cache[sp] = out
	return out


static func draw_animal(sink: Callable, X: float, Y: float, sc: float, sp: String, f: int, moving: bool, anim: float, flash: bool, tide: bool, uid: int, ol: float = 0.0, pth: int = -1) -> void:
	var S: Dictionary = GuData.SPEC[sp]
	var s: float = sc * float(S.get("ss", 1.0))
	var parts: Array = []
	var P: Callable = func(x: float, y: float, w: float, h: float, c: Color) -> void:
		var rx: float = X + (x if f > 0 else -x - w) * s
		parts.append([Rect2(rx, Y + y * s, w * s, h * s), c])
	var st: int = (int(anim * 8.0) & 1) if moving else 0
	var bob: float = -0.3 if st == 1 else 0.0
	var la: float = 0.4 if st == 1 else 0.0
	var lb: float = 0.4 - la
	var arch: String = S.get("arch", "wolf")
	var pal: Array = _pal(sp)
	var b: Color = Color.WHITE if flash else pal[0]
	var l: Color = pal[1]
	var d: Color = pal[2]
	var sh: Color = Color(0, 0, 0, 0.28)
	var crown: bool = S.get("crown", false)
	var cx: float = 0.0
	var cy: float = 0.0
	match arch:
		"wolf":
			var kw: bool = sp == "kingwolf"
			if no_aura:
				pass
			elif kw:
				P.call(-4.0, -7.0, 8.0, 7.0, Color(1, 0.95, 0.48, 0.18 + 0.1 * sin(anim * 9.0)))
			elif S.has("stars"):
				P.call(-4.0, -6.5, 8.0, 6.5, Color(l, 0.12 + 0.06 * sin(anim * 5.0)))
			if tide and not flash:
				b = b.darkened(0.12)
			var dk: Color = b.darkened(0.35) if (sp == "lightning_wolf" or S.has("stars")) else pal[2]
			P.call(-3.0, -0.4, 6.0, 0.8, sh)
			P.call(-2.5, -1.2 - la, 1.0, 1.2, dk)
			P.call(0.8, -1.2 - lb, 1.0, 1.2, dk)
			P.call(-3.0, -3.0 + bob, 5.0, 2.0, b)
			P.call(-3.0, -3.0 + bob, 5.0, 0.7, l)
			P.call(2.0, -4.0 + bob, 2.0, 2.0, b)
			P.call(3.0, -4.8 + bob, 0.8, 0.9, dk)
			P.call(2.0, -4.8 + bob, 0.8, 0.9, dk)
			P.call(4.0, -3.0 + bob, 0.8, 0.7, Color("#2a2a2a"))
			P.call(-4.0, -3.6 + bob, 1.0, 1.0, b)
			if S.get("shell", false):
				P.call(-2.6, -3.6 + bob, 1.4, 0.8, d)
				P.call(-0.8, -3.7 + bob, 1.4, 0.9, d)
				P.call(1.0, -3.6 + bob, 1.0, 0.8, d)
			if S.has("stars"):
				P.call(-2.2, -2.6 + bob, 0.4, 0.4, d)
				P.call(-0.4, -2.2 + bob, 0.4, 0.4, d)
				P.call(1.0, -2.7 + bob, 0.4, 0.4, d)
			if sp == "lightning_wolf":
				P.call(-1.8, -3.4 + bob, 0.5, 0.5, d)
				P.call(-0.6, -3.1 + bob, 0.5, 0.5, d)
				P.call(0.6, -3.4 + bob, 0.5, 0.5, d)
			P.call(2.8, -3.6 + bob, 0.6, 0.6, Color("#ffdf4a") if (tide or crown or sp == "lightning_wolf") else Color("#1a1a1a"))
			cx = 1.8
			cy = -6.2
		"boar":
			P.call(-3.0, -0.4, 6.0, 0.8, sh)
			P.call(-2.5, -1.2 - la, 1.0, 1.2, d.darkened(0.3))
			P.call(0.8, -1.2 - lb, 1.0, 1.2, d.darkened(0.3))
			P.call(-3.0, -3.5 + bob, 5.0, 2.5, b)
			P.call(-3.0, -3.5 + bob, 5.0, 0.6, l)
			P.call(2.0, -3.0 + bob, 2.0, 2.0, b.darkened(0.12))
			P.call(3.6, -2.4 + bob, 0.6, 0.6, d)
			P.call(3.6, -1.8 + bob, 0.8, 0.8, Color("#f0e6d0"))
			P.call(2.6, -2.6 + bob, 0.5, 0.5, Color("#1a1a1a"))
			cx = 2.0
			cy = -4.6
		"monkey":
			P.call(-1.5, -0.4, 3.0, 0.8, sh)
			P.call(-1.2, -1.0, 0.8, 1.0, b.darkened(0.3))
			P.call(0.4, -1.0, 0.8, 1.0, b.darkened(0.3))
			P.call(-1.5, -3.5 + bob, 3.0, 2.5, b)
			P.call(-1.0, -5.2 + bob, 2.0, 1.8, l)
			P.call(-0.2, -4.7 + bob, 1.0, 0.8, d)
			P.call(-2.6, -4.2 + bob, 1.0, 2.0, b.darkened(0.15))
			cx = -1.0
			cy = -6.4
		"deer":
			P.call(-2.5, -0.4, 5.0, 0.8, Color(0, 0, 0, 0.25))
			P.call(-1.6, -1.4 - la * 0.75, 0.6, 1.4, Color("#7a5432"))
			P.call(1.0, -1.4 - lb * 0.75, 0.6, 1.4, Color("#7a5432"))
			P.call(-2.0, -3.0 + bob, 4.0, 1.8, Color.WHITE if flash else Color("#b47c48"))
			P.call(1.4, -5.0 + bob, 1.0, 2.4, Color("#b47c48"))
			P.call(1.6, -6.0 + bob, 1.8, 1.2, Color("#c48c58"))
			P.call(1.6, -7.6 + bob, 0.5, 1.6, Color("#e0d0a8"))
			P.call(2.9, -7.6 + bob, 0.5, 1.6, Color("#e0d0a8"))
			P.call(-2.3, -3.0 + bob, 0.6, 0.6, Color("#f0e0c8"))
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
		"tiger":
			P.call(-3.5, -0.4, 7.0, 0.8, sh)
			var lg: Color = b.darkened(0.25)
			P.call(-2.8, -1.4 - la, 0.9, 1.4, lg)
			P.call(-1.6, -1.4 - lb, 0.9, 1.4, lg)
			P.call(1.2, -1.4 - lb, 0.9, 1.4, lg)
			P.call(2.3, -1.4 - la, 0.9, 1.4, lg)
			P.call(-4.4, -4.4 + bob, 1.0, 0.6, b)
			P.call(-4.8, -5.2 + bob, 0.7, 1.0, b)
			P.call(-3.2, -3.4 + bob, 6.0, 2.2, b)
			P.call(-2.6, -1.6 + bob, 4.8, 0.5, l)
			if S.get("spots", false):
				for k: int in range(4):
					P.call(-2.6 + k * 1.3, -3.0 + bob + (k % 2) * 0.6, 0.6, 0.6, l)
			else:
				for k: int in range(3):
					P.call(-2.3 + k * 1.4, -3.4 + bob, 0.5, 1.6, d)
			P.call(2.2, -4.4 + bob, 2.4, 2.2, b)
			P.call(2.3, -5.0 + bob, 0.6, 0.7, b)
			P.call(3.8, -5.0 + bob, 0.6, 0.7, b)
			P.call(3.9, -3.2 + bob, 1.0, 0.8, l)
			P.call(3.6, -3.9 + bob, 0.5, 0.5, Color("#ffe04a"))
			cx = 2.4
			cy = -6.2
		"bear":
			P.call(-3.6, -0.4, 7.2, 0.8, sh)
			var bl: Color = b.darkened(0.3)
			P.call(-2.8, -1.6 - la, 1.2, 1.6, bl)
			P.call(-1.2, -1.6 - lb, 1.2, 1.6, bl)
			P.call(1.0, -1.6 - lb, 1.2, 1.6, bl)
			P.call(2.4, -1.6 - la, 1.2, 1.6, bl)
			if S.get("wings", false):
				var fl: float = sin(anim * 7.0) * 0.8
				P.call(-2.4, -5.8 + bob - fl * 0.4, 4.8, 1.2, d)
				P.call(-3.2, -6.8 + bob - fl * 0.7, 4.4, 1.2, d)
				P.call(-4.0, -7.8 + bob - fl, 3.6, 1.2, d)
				P.call(-4.6, -8.6 + bob - fl, 2.0, 0.8, d)
				P.call(-2.0, -5.0 + bob - fl * 0.4, 1.0, 0.6, l)
				P.call(-2.8, -6.0 + bob - fl * 0.7, 1.0, 0.6, l)
				P.call(-3.6, -7.0 + bob - fl, 1.0, 0.6, l)
			P.call(-3.4, -4.6 + bob, 6.4, 3.2, b)
			P.call(-3.0, -4.6 + bob, 5.0, 0.7, b.lightened(0.15))
			P.call(-2.4, -1.8 + bob, 4.0, 0.5, l)
			P.call(2.4, -5.2 + bob, 2.6, 2.4, b)
			P.call(2.4, -5.8 + bob, 0.7, 0.7, b)
			P.call(4.2, -5.8 + bob, 0.7, 0.7, b)
			P.call(4.4, -4.0 + bob, 1.0, 1.0, l)
			P.call(5.0, -4.0 + bob, 0.4, 0.4, Color("#1a1a1a"))
			P.call(3.8, -4.6 + bob, 0.4, 0.4, Color("#1a1a1a"))
			cx = 2.8
			cy = -7.0
		"horned":
			if not no_aura:
				P.call(-4.5, -7.0, 9.0, 7.5, Color(l, 0.13 + 0.06 * sin(anim * 4.0)))
			P.call(-3.6, -0.4, 7.2, 0.8, Color(0, 0, 0, 0.32))
			var hl: Color = b.darkened(0.3)
			P.call(-3.0, -1.6 - la, 1.3, 1.6, hl)
			P.call(-1.0, -1.6 - lb, 1.3, 1.6, hl)
			P.call(0.8, -1.6 - lb, 1.3, 1.6, hl)
			P.call(2.2, -1.6 - la, 1.3, 1.6, hl)
			P.call(-3.4, -4.0 + bob, 6.0, 3.0, b)
			for k: int in range(3):
				P.call(-2.6 + k * 1.5, -4.8 + bob, 0.7, 0.8, l)
			P.call(2.4, -4.0 + bob, 2.2, 2.2, b.darkened(0.1))
			P.call(3.6, -5.8 + bob, 0.6, 1.8, d)
			P.call(4.2, -6.2 + bob, 0.6, 0.8, d)
			P.call(2.6, -5.4 + bob, 0.5, 1.4, d)
			P.call(3.8, -3.6 + bob, 0.6, 0.5, Color("#ffcf3a"))
			P.call(-4.2, -3.6 + bob, 0.9, 0.8, b)
		"behemoth":
			if not no_aura:
				P.call(-5.0, -7.5, 10.0, 8.0, Color(1.0, 0.35, 0.1, 0.16 + 0.08 * sin(anim * 3.0)))
			P.call(-4.0, -0.4, 8.0, 0.9, Color(0, 0, 0, 0.38))
			var ml: Color = b.lightened(0.1)
			P.call(-3.4, -1.8 - la, 1.5, 1.8, b)
			P.call(-1.2, -1.8 - lb, 1.5, 1.8, b)
			P.call(1.0, -1.8 - lb, 1.5, 1.8, b)
			P.call(2.6, -1.8 - la, 1.5, 1.8, b)
			P.call(-3.8, -5.0 + bob, 7.0, 3.6, b)
			P.call(-3.8, -5.0 + bob, 7.0, 0.7, ml)
			P.call(-2.6, -3.6 + bob, 2.0, 0.4, l)
			P.call(-1.0, -2.8 + bob, 2.4, 0.4, l)
			P.call(0.6, -4.2 + bob, 1.8, 0.4, l)
			for k: int in range(4):
				P.call(-3.2 + k * 1.6, -6.0 + bob, 0.8, 1.0, d)
			P.call(2.8, -5.2 + bob, 2.6, 2.8, b)
			P.call(4.6, -7.0 + bob, 0.7, 2.2, d)
			P.call(3.4, -6.6 + bob, 0.6, 1.6, d)
			P.call(3.6, -4.4 + bob, 0.5, 0.5, l)
			P.call(4.4, -4.0 + bob, 0.5, 0.5, l)
			P.call(4.0, -3.2 + bob, 0.5, 0.5, l)
		"croc":
			P.call(-4.5, -0.4, 9.0, 0.8, sh)
			var cl2: Color = b.darkened(0.2)
			P.call(-3.0, -1.0 - la * 0.5, 1.0, 1.0, cl2)
			P.call(-1.2, -1.0 - lb * 0.5, 1.0, 1.0, cl2)
			P.call(1.0, -1.0 - lb * 0.5, 1.0, 1.0, cl2)
			P.call(2.4, -1.0 - la * 0.5, 1.0, 1.0, cl2)
			P.call(-6.0, -1.8 + bob, 2.2, 0.9, b)
			P.call(-7.2, -1.4 + bob, 1.4, 0.6, b)
			P.call(-4.0, -2.4 + bob, 7.0, 1.6, b)
			for k: int in range(4):
				P.call(-3.6 + k * 1.6, -2.8 + bob, 0.8, 0.5, l)
			P.call(3.0, -2.6 + bob, 3.0, 1.0, b)
			P.call(3.0, -1.6 + bob, 2.8, 0.6, d)
			P.call(3.6, -1.9 + bob, 0.3, 0.3, Color.WHITE)
			P.call(4.6, -1.9 + bob, 0.3, 0.3, Color.WHITE)
			P.call(3.4, -3.0 + bob, 0.6, 0.5, Color("#ffd23a"))
			cx = 3.0
			cy = -4.0
		"spider":
			P.call(-3.0, -0.4, 6.0, 0.7, sh)
			var lg2: Color = d
			for k: int in range(4):
				var lx: float = -2.2 + k * 1.3
				var lw: float = 0.25 if (k + st) % 2 == 0 else 0.0
				P.call(lx - 0.3, -2.2 - lw, 1.0, 0.4, lg2)
				P.call(lx - 0.5, -1.8 - lw, 0.4, 1.8, lg2)
			P.call(-2.8, -3.2 + bob, 2.8, 2.2, b)
			P.call(-2.4, -2.8 + bob, 2.0, 0.4, l)
			P.call(-2.4, -2.0 + bob, 2.0, 0.4, l)
			P.call(0.0, -2.8 + bob, 1.8, 1.6, b.darkened(0.15))
			P.call(1.3, -2.6 + bob, 0.4, 0.4, Color("#ff4a2a"))
			P.call(1.3, -1.9 + bob, 0.4, 0.4, Color("#ff4a2a"))
		"whale":
			P.call(-5.6, -0.7, 11.0, 0.7, Color(1, 1, 1, 0.3))
			P.call(-6.6, -4.6 + bob, 1.6, 1.0, b)
			P.call(-6.6, -1.8 + bob, 1.6, 1.0, b)
			P.call(-5.8, -3.6 + bob, 1.2, 1.8, b)
			P.call(-5.0, -3.8 + bob, 8.0, 3.2, b)
			P.call(3.0, -3.4 + bob, 2.0, 2.6, b)
			P.call(-4.4, -1.2 + bob, 7.0, 0.6, d)
			P.call(-4.0, -3.8 + bob, 6.0, 0.6, l)
			P.call(3.4, -2.6 + bob, 0.5, 0.5, Color("#f8f8f8"))
			if int(anim * 1.5 + uid) % 4 == 0:
				P.call(1.6, -6.4, 0.4, 2.2, Color(0.9, 0.97, 1.0, 0.7))
				P.call(1.0, -6.8, 1.6, 0.4, Color(0.9, 0.97, 1.0, 0.6))
		"eagle":
			P.call(-2.4, -0.4, 4.8, 0.7, sh)
			P.call(-0.5, -1.4, 0.4, 1.4, d)
			P.call(0.4, -1.4, 0.4, 1.4, d)
			P.call(-2.8, -3.2 + bob, 1.6, 0.8, b.darkened(0.2))
			P.call(-1.4, -4.4 + bob, 3.0, 3.0, b)
			if moving:
				var fl2: float = sin(anim * 10.0) * 1.2
				P.call(-3.6, -7.0 + bob - fl2, 4.4, 1.2, b.darkened(0.12))
				P.call(-3.8, -6.0 + bob - fl2 * 0.6, 1.4, 1.2, b.darkened(0.25))
			else:
				P.call(-1.6, -4.0 + bob, 2.4, 1.8, b.darkened(0.15))
			P.call(0.8, -5.8 + bob, 1.8, 1.6, l)
			P.call(2.6, -5.2 + bob, 0.8, 0.6, d)
			P.call(1.8, -5.4 + bob, 0.4, 0.4, Color("#1a1a1a"))
			cx = 0.8
			cy = -7.0
		"lion":
			if not no_aura:
				P.call(-4.0, -7.0, 8.5, 7.2, Color(l, 0.16 + 0.08 * sin(anim * 5.0)))
			P.call(-3.5, -0.4, 7.0, 0.8, sh)
			var ll: Color = b.darkened(0.25)
			P.call(-2.6, -1.4 - la, 0.9, 1.4, ll)
			P.call(-1.4, -1.4 - lb, 0.9, 1.4, ll)
			P.call(1.0, -1.4 - lb, 0.9, 1.4, ll)
			P.call(2.0, -1.4 - la, 0.9, 1.4, ll)
			P.call(-4.0, -3.6 + bob, 1.0, 0.5, b)
			P.call(-4.6, -4.0 + bob, 0.8, 0.8, d)
			P.call(-3.0, -3.4 + bob, 5.6, 2.2, b)
			P.call(1.6, -5.6 + bob, 3.2, 3.6, d)
			P.call(1.4, -4.8 + bob, 0.6, 2.4, d.darkened(0.2))
			P.call(2.6, -4.6 + bob, 2.0, 1.8, b)
			P.call(4.2, -3.6 + bob, 0.8, 0.7, b.lightened(0.2))
			P.call(3.6, -4.2 + bob, 0.4, 0.4, Color("#1a1a1a"))
		"dragon":
			var segs: int = 7
			for k: int in range(segs):
				var sx: float = -5.6 + k * 1.5
				var sy: float = -3.6 + sin(anim * 3.0 + k * 0.9) * 1.0
				P.call(sx, sy - 1.0, 1.8, 1.6, b)
				P.call(sx, sy + 0.4, 1.8, 0.4, l)
				if k % 2 == 0:
					P.call(sx + 0.4, sy - 1.6, 0.6, 0.6, l)
				if k == 2 or k == 5:
					P.call(sx + 0.4, sy + 0.6, 0.5, 1.0, d)
			P.call(-6.6, -3.6 + sin(anim * 3.0 - 0.9) - 0.8, 1.2, 1.2, l)
			var hy2: float = -4.2 + sin(anim * 3.0 + segs * 0.9) * 1.0
			var hx2: float = -5.6 + segs * 1.5
			P.call(hx2, hy2 - 1.4, 2.4, 2.0, b)
			P.call(hx2 + 2.2, hy2 - 0.8, 1.2, 1.0, b)
			P.call(hx2 + 0.2, hy2 - 2.8, 0.5, 1.4, l)
			P.call(hx2 + 1.0, hy2 - 2.6, 0.5, 1.2, l)
			P.call(hx2 + 2.6, hy2 + 0.2, 1.6, 0.3, l)
			P.call(hx2 + 1.4, hy2 - 0.9, 0.5, 0.5, Color("#ff3a2a"))
		"turtle":
			if S.get("smoke", false):
				for k: int in range(3):
					var ph: float = anim * 0.8 + k * 1.3 + uid
					P.call(-2.0 + k * 1.6 + sin(ph) * 0.6, -5.4 - fmod(ph, 2.0) * 0.8, 1.6, 1.0, Color(0.85, 0.87, 0.9, 0.3))
			P.call(-3.4, -0.4, 6.8, 0.8, sh)
			var tl: Color = d.lightened(0.2)
			P.call(-2.6, -1.0 - la * 0.5, 1.0, 1.0, tl)
			P.call(1.6, -1.0 - lb * 0.5, 1.0, 1.0, tl)
			P.call(-4.0, -1.8, 1.0, 0.5, tl)
			P.call(-3.0, -2.2, 6.0, 1.4, b)
			P.call(-2.4, -3.2, 4.8, 1.0, b)
			P.call(-1.6, -3.8, 3.2, 0.6, b)
			P.call(-1.8, -2.8, 0.8, 0.8, l)
			P.call(-0.4, -3.4, 0.8, 0.8, l)
			P.call(1.0, -2.8, 0.8, 0.8, l)
			P.call(-3.2, -1.2, 6.4, 0.5, d)
			P.call(3.0, -2.4 + bob, 1.6, 1.2, tl)
			P.call(4.0, -2.2 + bob, 0.4, 0.4, Color("#1a1a1a"))
		"bat":
			var fl3: float = sin(anim * 10.0) * 0.6
			P.call(-1.6, -0.4, 3.2, 0.6, Color(0, 0, 0, 0.2))
			P.call(-4.2, -5.0 + fl3 * 2.0, 3.4, 1.0, b)
			P.call(-4.6, -4.2 + fl3 * 2.0, 1.0, 1.6, b)
			P.call(0.8, -5.0 + fl3 * 2.0, 3.4, 1.0, b)
			P.call(3.6, -4.2 + fl3 * 2.0, 1.0, 1.6, b)
			P.call(-3.6, -4.2 + fl3 * 2.0, 2.4, 0.4, d)
			P.call(1.2, -4.2 + fl3 * 2.0, 2.4, 0.4, d)
			P.call(-0.8, -4.4 + fl3, 1.6, 2.2, d)
			P.call(-0.6, -5.6 + fl3, 1.2, 1.2, d)
			P.call(-0.6, -6.2 + fl3, 0.4, 0.6, d)
			P.call(0.2, -6.2 + fl3, 0.4, 0.6, d)
			P.call(0.2, -5.2 + fl3, 0.3, 0.3, l)
			P.call(-4.8, -3.0 + fl3 * 2.0, 0.6, 0.6, l)
			P.call(4.4, -3.0 + fl3 * 2.0, 0.6, 0.6, l)
		"ancient":
			if not no_aura:
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
		"gu":
			var gc: Color = GuData.PATH_COL[pth] if pth >= 0 else Color(0.6, 0.83, 1.0)
			var bb: float = 0.55 + 0.45 * sin(anim * 6.0 + uid)
			P.call(-1.6, -5.2, 3.2, 3.2, Color(gc, 0.38 * bb))
			P.call(-0.8, -3.9, 1.6, 0.9, gc)
			P.call(-0.4, -3.7, 0.8, 0.5, Color("#ffffff") if bb > 0.5 else gc.lightened(0.5))
			P.call(-1.0, -4.5 - bb * 0.3, 0.7, 0.5, Color(1, 1, 1, 0.7))
			P.call(0.3, -4.5 - (1.0 - bb) * 0.3, 0.7, 0.5, Color(1, 1, 1, 0.7))
			_emit(sink, parts, 0.0)
			return
		"igu":
			var ic: Color = GuData.PATH_COL[pth] if pth >= 0 else Color("#ffd24a")
			var pb: float = 0.55 + 0.45 * sin(anim * 4.0 + uid)
			var fl4: float = sin(anim * 16.0) * 0.3
			P.call(-3.4, -8.0, 6.8, 6.8, Color(1.0, 0.9, 0.5, 0.14 * pb))
			P.call(-2.4, -7.0, 4.8, 4.8, Color(ic, 0.3 * pb))
			P.call(-0.3, -9.0, 0.6, 1.6, Color(1.0, 0.95, 0.7, 0.5 * pb))
			P.call(-0.3, -2.2, 0.6, 1.4, Color(1.0, 0.95, 0.7, 0.5 * pb))
			P.call(-4.0, -4.9, 1.6, 0.6, Color(1.0, 0.95, 0.7, 0.5 * pb))
			P.call(2.4, -4.9, 1.6, 0.6, Color(1.0, 0.95, 0.7, 0.5 * pb))
			var wing: Color = Color(1.0, 1.0, 0.92, 0.85)
			P.call(-1.6, -6.4 + fl4, 1.4, 1.0, wing)
			P.call(0.2, -6.6 - fl4, 1.4, 1.0, wing)
			P.call(-1.2, -5.2, 2.2, 1.4, ic)
			P.call(-1.2, -5.2, 2.2, 0.4, ic.lightened(0.4))
			P.call(0.8, -5.0, 0.9, 1.0, ic.darkened(0.35))
			P.call(1.2, -4.8, 0.3, 0.3, Color("#ffe24a"))
	if crown and cx != 0.0:
		var gold: Color = Color("#ffd23a") if sp != "bk10000" else d
		P.call(cx, cy, 2.4, 0.8, gold)
		P.call(cx, cy - 0.6, 0.6, 0.6, gold)
		P.call(cx + 0.9, cy - 0.8, 0.6, 0.8, gold)
		P.call(cx + 1.8, cy - 0.6, 0.6, 0.6, gold)
	_emit(sink, parts, ol * s)


# ---------------- Orte ----------------

const PLACE_SIZE: Dictionary = {"blessed": 24, "grotto": 34, "court": 40, "langya": 28, "hu": 24, "imperial": 30, "dream": 22, "inherit": 12, "fragment": 12, "palace": 22, "mushroom": 20, "yitian": 24, "crazed": 20}
## Schwebende Orte (mit Schatten am Boden und leichtem Auf und Ab).
const PLACE_FLOAT: Array[String] = ["blessed", "grotto", "court", "langya", "hu", "imperial"]
static var _place_cache: Dictionary = {}


static func place_size(type: String) -> float:
	return float(PLACE_SIZE.get(type, 20))


static func place_tex(type: String) -> ImageTexture:
	if _place_cache.has(type):
		return _place_cache[type]
	var im: Image = place_image(type)
	var t: ImageTexture = ImageTexture.create_from_image(im)
	_place_cache[type] = t
	return t


## Schwebende Insel: Grasdecke oben, zerklüfteter Fels darunter.
static func _island(q: Px, cx: float, top: float, rx: float, ry: float, depth: float, grass: Array, rock: Array, sd: int) -> void:
	var h0: int = int(top)
	for y: int in range(int(top - ry), int(top + depth) + 1):
		for x: int in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx: float = (x + 0.5 - cx) / rx
			if y <= top:
				var dy: float = (y + 0.5 - top) / ry
				if dx * dx + dy * dy <= 1.0:
					var edge: bool = dx * dx + dy * dy > 0.72 and y < top - ry * 0.3
					q.p(x, y, 1, 1, grass[0] if edge else (grass[1] if GuData.hash2(x, y, sd) < 0.8 else grass[2]))
			else:
				var k: float = (y - top) / depth
				var hw: float = rx * pow(maxf(0.0, 1.0 - k), 0.9) * (0.85 + 0.25 * GuData.hash2(y, sd, 3))
				if absf(x + 0.5 - cx) <= hw:
					var ci: int = 0 if k < 0.15 else (1 if k < 0.6 else 2)
					if GuData.hash2(x, y, sd + 1) < 0.12:
						ci = mini(2, ci + 1)
					q.p(x, y, 1, 1, rock[ci])
	# Rand der Grasdecke
	for x: int in range(int(cx - rx), int(cx + rx) + 1):
		var dx2: float = (x + 0.5 - cx) / rx
		if absf(dx2) < 0.98:
			q.p(x, h0, 1, 1, grass[2])
	# hängende Wurzeln
	for k2: int in range(4):
		var wx: int = int(cx - rx * 0.6 + k2 * rx * 0.4)
		q.p(wx, h0 + 1, 1, 2 + (k2 % 2) * 2, Color("#5a3a20"))


static func _tree(q: Px, x: int, y: int, c: Color) -> void:
	q.p(x, y - 2, 1, 3, Color("#6a4628"))
	q.p(x - 2, y - 5, 5, 3, c)
	q.p(x - 1, y - 6, 3, 1, c.lightened(0.2))
	q.p(x - 2, y - 3, 5, 1, c.darkened(0.25))


static func _pagoda(q: Px, x: int, y: int, roof: Color, wall: Color, floors: int) -> void:
	for f: int in range(floors):
		var w: int = 9 - f * 2
		var by: int = y - f * 4
		q.p(x - w / 2 + 1, by - 2, w - 2, 2, wall)
		q.p(x - w / 2 + 2, by - 2, 1, 2, Color("#2a1a10"))
		q.p(x - w / 2, by - 3, w, 1, roof)
		q.p(x - w / 2 + 1, by - 4, w - 2, 1, roof.lightened(0.2))
	q.p(x, y - floors * 4 - 2, 1, 2, Color("#ffd23a"))


static func place_image(type: String) -> Image:
	var W2: int = int(place_size(type))
	var H2: int = int(W2 * 0.95)
	var q: Px = Px.new(W2, H2)
	var grass: Array = [Color("#8ad05a"), Color("#5aa83a"), Color("#3e7a2a")]
	var rock: Array = [Color("#8a7a62"), Color("#6a5a48"), Color("#4a3e32")]
	var cx: float = W2 / 2.0
	match type:
		"blessed", "hu":
			if type == "hu":
				grass = [Color("#f0b060"), Color("#d8803a"), Color("#a85a28")]
			_island(q, cx, H2 * 0.42, W2 * 0.44, H2 * 0.14, H2 * 0.5, grass, rock, 11 if type == "blessed" else 12)
			var gy: int = int(H2 * 0.42)
			_tree(q, int(cx - W2 * 0.26), gy - 1, Color("#4ea83a") if type == "blessed" else Color("#e86a8a"))
			_tree(q, int(cx + W2 * 0.27), gy, Color("#6ac04a") if type == "blessed" else Color("#f0a0b0"))
			_pagoda(q, int(cx), gy, Color("#c23a2e") if type == "blessed" else Color("#e8e0d0"), Color("#e8d8b0"), 2)
			q.p(int(cx) + 4, gy - 1, 2, 1, Color("#7ae8ff"))
		"grotto":
			_island(q, cx - 2, H2 * 0.4, W2 * 0.36, H2 * 0.12, H2 * 0.48, grass, rock, 21)
			_island(q, W2 * 0.86, H2 * 0.22, W2 * 0.1, H2 * 0.05, H2 * 0.2, grass, rock, 22)
			_island(q, W2 * 0.12, H2 * 0.62, W2 * 0.09, H2 * 0.05, H2 * 0.18, grass, rock, 23)
			var gy2: int = int(H2 * 0.4)
			_tree(q, int(cx - 9), gy2 - 1, Color("#4ea83a"))
			_tree(q, int(cx + 7), gy2, Color("#3e9a5a"))
			_pagoda(q, int(cx - 1), gy2, Color("#8a46b8"), Color("#f0e6d0"), 3)
			for y: int in range(gy2 + 1, gy2 + 12):
				q.p(int(cx + 9), y, 1, 1, Color("#a8e8ff") if y % 2 == 0 else Color("#e8f8ff"))
			q.p(int(W2 * 0.86) - 1, int(H2 * 0.22) - 3, 2, 3, Color("#ffe27a"))
		"court", "imperial":
			var roof: Color = Color("#f0c040") if type == "court" else Color("#e0a020")
			_island(q, cx, H2 * 0.55, W2 * 0.46, H2 * 0.1, H2 * 0.4, [Color("#f4f8ff"), Color("#dfe8f4"), Color("#b8c8dc")], [Color("#d8e4f0"), Color("#b8c4d4"), Color("#8a98ac")], 31)
			var gy3: int = int(H2 * 0.55)
			# Palastmauer und Hallen
			q.p(int(cx - W2 * 0.4), gy3 - 3, int(W2 * 0.8), 3, Color("#c8382a"))
			q.p(int(cx - W2 * 0.4), gy3 - 4, int(W2 * 0.8), 1, roof)
			_pagoda(q, int(cx - W2 * 0.24), gy3 - 2, roof, Color("#c8382a"), 2)
			_pagoda(q, int(cx + W2 * 0.24), gy3 - 2, roof, Color("#c8382a"), 2)
			if type == "court":
				# Himmelsüberwachungsturm
				var tx2: int = int(cx)
				q.p(tx2 - 2, gy3 - 26, 5, 24, Color("#f0ece0"))
				q.p(tx2 - 2, gy3 - 26, 1, 24, Color("#ffffff"))
				q.p(tx2 + 2, gy3 - 26, 1, 24, Color("#c8c0b0"))
				for k: int in range(5):
					q.p(tx2 - 3, gy3 - 6 - k * 5, 7, 1, roof)
				q.p(tx2 - 1, gy3 - 30, 3, 4, roof)
				q.p(tx2, gy3 - 32, 1, 2, Color("#fff8c0"))
				q.p(tx2 - 1, gy3 - 22, 3, 2, Color("#7ae8ff"))
			else:
				_pagoda(q, int(cx), gy3 - 2, roof, Color("#c8382a"), 3)
				q.p(int(cx - 2), gy3 - 2, 1, 2, Color("#3a2a10"))
		"langya":
			_island(q, cx, H2 * 0.45, W2 * 0.44, H2 * 0.13, H2 * 0.48, grass, rock, 41)
			var gy4: int = int(H2 * 0.45)
			for k: int in range(3):
				var sx: int = int(cx - 9 + k * 7)
				q.p(sx - 2, gy4 - 4, 5, 1, [Color("#d23a2a"), Color("#3a7ad8"), Color("#e8b020")][k])
				q.p(sx - 1, gy4 - 3, 3, 3, Color("#e8d0a0"))
				q.p(sx, gy4 - 2, 1, 2, Color("#5a3a1a"))
			q.p(int(cx) - 1, gy4 - 9, 3, 3, Color("#ffd23a"))
			q.p(int(cx), gy4 - 8, 1, 1, Color("#8a5a10"))
			_tree(q, int(cx + 10), gy4, Color("#5aa83a"))
		"dream":
			for y: int in range(H2):
				for x: int in range(W2):
					var dd: float = Vector2((x + 0.5 - cx) / (W2 * 0.5), (y + 0.5 - H2 * 0.55) / (H2 * 0.42)).length()
					if dd > 1.0:
						continue
					var ang: float = atan2(y - H2 * 0.55, x - cx)
					var band: float = sin(dd * 9.0 - ang * 2.0)
					if band > 0.2 or dd < 0.25:
						var c: Color = Color("#f0c8ff").lerp(Color("#8a5ad8"), dd)
						c.a = 0.95 - dd * 0.45
						q.p(x, y, 1, 1, c)
			q.p(int(cx) - 1, int(H2 * 0.55) - 1, 3, 3, Color("#ffffff"))
		"inherit":
			q.p(2, H2 - 3, W2 - 4, 3, Color("#7a7468"))
			q.p(3, 3, W2 - 6, H2 - 6, Color("#a8a294"))
			q.p(3, 3, 1, H2 - 6, Color("#c8c2b4"))
			q.p(2, 2, W2 - 4, 2, Color("#8a8476"))
			q.p(int(cx) - 1, 5, 2, 1, Color("#ffd23a"))
			q.p(int(cx) - 2, 7, 4, 1, Color("#ffd23a"))
			q.p(int(cx) - 1, 9, 2, 1, Color("#ffd23a"))
		"fragment":
			q.p(1, H2 - 3, W2 - 2, 3, Color("#5a4a40"))
			q.p(2, H2 - 4, W2 - 4, 1, Color("#3a2e28"))
			for y: int in range(1, H2 - 3):
				var w2: int = int((y + 2) * 0.45)
				q.p(int(cx) - w2 / 2 - (1 if y % 3 == 0 else 0), y, w2, 1, Color("#cfe0ff") if y % 4 else Color("#ffffff"))
				q.p(int(cx) + w2 / 2 - 1, y, 1, 1, Color("#8aa8e8"))
		"palace":
			q.p(0, H2 - 4, W2, 4, Color(0.35, 0.65, 0.9, 0.45))
			_pagoda(q, int(cx), H2 - 4, Color("#2a9a8a"), Color("#e8dcc0"), 3)
			q.p(2, H2 - 5, 3, 3, Color("#e86a6a"))
			q.p(W2 - 5, H2 - 6, 2, 4, Color("#f08a5a"))
			q.p(int(cx) - 7, H2 - 6, 2, 2, Color("#f0f0e0"))
		"mushroom":
			q.p(1, H2 - 3, W2 - 2, 3, Color("#4a7a3a"))
			for m: Array in [[5, 8, 6, Color("#d83a2a")], [13, 5, 8, Color("#e85a3a")], [W2 - 4, 11, 4, Color("#c8a040")]]:
				var mx: int = m[0]
				var mh: int = m[1]
				var mw: int = m[2]
				q.p(mx - 1, H2 - 3 - mh, 2, mh, Color("#f0e6d0"))
				q.p(mx - mw / 2, H2 - 3 - mh - 2, mw, 2, m[3])
				q.p(mx - mw / 2 + 1, H2 - 3 - mh - 3, mw - 2, 1, (m[3] as Color).lightened(0.15))
				q.p(mx - 1, H2 - 3 - mh - 2, 1, 1, Color("#ffffff"))
		"yitian":
			for y: int in range(4, H2):
				var w3: float = (y - 3) * 0.95
				q.p(int(cx - w3 / 2), y, int(w3), 1, Color("#7a7c80") if y < H2 * 0.4 else Color("#5a6a4a"))
				q.p(int(cx), y, int(w3 / 2), 1, Color("#5a5c60") if y < H2 * 0.4 else Color("#46563a"))
			q.p(int(cx) - 2, 4, 4, 3, Color("#eef2f4"))
			q.p(int(cx) - 1, 1, 2, 3, Color("#ffe27a"))
		"crazed":
			for y: int in range(3, H2):
				var w4: float = minf(W2, (y - 1) * 1.4)
				q.p(int(cx - w4 / 2), y, int(w4), 1, Color("#4a4048") if y % 3 else Color("#3a3238"))
			q.p(int(cx) - 4, H2 - 9, 8, 9, Color("#120a0e"))
			q.p(int(cx) - 3, H2 - 10, 6, 1, Color("#120a0e"))
			q.p(int(cx) - 2, H2 - 5, 1, 1, Color("#ff3a2a"))
			q.p(int(cx) + 1, H2 - 5, 1, 1, Color("#ff3a2a"))
			q.p(int(cx) - 1, H2 - 3, 3, 1, Color("#e8e0d0"))
	return q.outline(Color(0.08, 0.07, 0.06, 0.85)).img
