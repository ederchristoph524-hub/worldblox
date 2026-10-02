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
static var road_img: Image
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
	road_img = Px.grid(["r"], {"r": "#b08e60"})


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
		GuData.F_ROAD:
			return road_img
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
	var ph: float = anim * 7.0
	var st: int = (int(ph) & 1) if moving else 0
	var bob: float = -0.4 if st == 1 else 0.0
	# Schwung von Armen und Beinen beim Gehen
	var sw: float = sin(ph * PI) * 0.55 if moving else 0.0
	var P: Callable = func(x: float, y: float, w: float, h: float, c: Color) -> void:
		var rx: float = X + (x if f > 0 else -x - w) * s
		parts.append([Rect2(rx, Y + y * s, w * s, h * s), c])
	var ec: Color = GuData.ESS_COL[rank] if rank > 0 else Color.WHITE
	# Aura der Uressenz
	if rank > 0 and not no_aura:
		var pul: float = 0.5 + 0.5 * sin(tnow * 3.0 + X * 0.7)
		var ga: float = (0.09 + 0.05 * pul) if imm else (0.06 + 0.05 * pul)
		var gr: float = 1.0 if imm else 0.7
		P.call(-3.0 * gr, -8.6 - gr, 6.0 * gr, 6.6 + gr, Color(ec, ga))
		P.call(-2.2 * gr, -9.6 - gr, 4.4 * gr, 9.6 + gr, Color(ec, ga))
		P.call(-1.6 * gr, -10.2 - gr, 3.2 * gr, 10.6 + gr, Color(ec, ga * 0.8))
		if rank >= 9:
			# Heiligenschein hinter dem Kopf
			P.call(-2.3, -10.2 + bob, 4.6, 4.6, Color(1.0, 0.86, 0.35, 0.22 + 0.08 * pul))
	if ow and not no_aura:
		var pa: float = 0.12 + 0.08 * sin(tnow * 5.0 + X)
		P.call(-2.6, -9.6, 5.2, 9.6, Color(0.75, 0.2, 1.0, pa))
	P.call(-2.0, -0.45, 4.2, 0.9, Color(0, 0, 0, 0.28))
	var skin: Color = Color.WHITE if flash else GuData.RACE_SKIN[race]
	var skd: Color = skin.darkened(0.2)
	var hair: Color = GuData.RACE_HAIR[race]
	var shirt: Color = Color.WHITE if flash else cl
	var pants: Color = Color("#3a2c26") if not rogue else Color("#241820")
	var shoe: Color = Color("#22180f")
	# Federschwingen, Schwanz, Fell (hinter dem Körper)
	if race == 4:
		var wf: float = sin(anim * 9.0) * 0.5 if moving else 0.0
		P.call(-3.5, -6.2 + bob - wf, 2.1, 3.4, Color("#f4ead8"))
		P.call(-3.9, -5.2 + bob - wf, 0.9, 2.6, Color("#e8d4b0"))
		P.call(-3.9, -3.4 + bob - wf, 0.9, 0.8, hair)
	elif race == 6:
		P.call(-2.8, -2.8 + bob, 1.4, 0.7, skin.darkened(0.15))
		P.call(-3.4, -2.4 + bob, 0.8, 0.6, skin.darkened(0.25))
	elif race == 7:
		P.call(-2.6, -3.8 + bob, 1.2, 0.6, hair)
		P.call(-3.0, -4.4 + bob, 0.7, 0.8, hair)
	# hinterer Arm
	P.call(-0.6 - sw * 0.6, -5.0 + bob, 0.8, 2.3, shirt.darkened(0.35))
	if imm:
		# Gewand bis zum Boden mit Saum in der Essenzfarbe
		P.call(-1.2, -0.45, 1.0, 0.45, shoe)
		P.call(0.4, -0.45, 1.0, 0.45, shoe)
		P.call(-1.7, -5.6 + bob, 3.4, 5.2 - bob, shirt)
		P.call(-2.0, -1.6, 4.0, 1.2, shirt.darkened(0.08))
		P.call(-1.7, -5.6 + bob, 0.8, 5.2 - bob, shirt.lightened(0.2))
		P.call(1.0, -5.6 + bob, 0.7, 5.2 - bob, shirt.darkened(0.25))
		P.call(-2.0, -0.75, 4.0, 0.4, ec)
		P.call(-1.7, -3.4 + bob, 3.4, 0.5, ec)
		P.call(-0.4, -5.6 + bob, 0.8, 2.2, ec.lightened(0.3))
	else:
		# Beine mit Schuhen
		P.call(-1.1 - sw * 0.5, -2.3, 1.0, 1.9, pants.darkened(0.25))
		P.call(0.1 + sw * 0.5, -2.3, 1.0, 1.9, pants)
		P.call(-1.2 - sw * 0.5, -0.5, 1.2, 0.5, shoe)
		P.call(0.1 + sw * 0.5, -0.5, 1.3, 0.5, shoe)
		# Oberkörper, links hell, rechts dunkel
		P.call(-1.5, -5.5 + bob, 3.0, 3.4, shirt)
		P.call(-1.5, -5.5 + bob, 0.7, 3.4, shirt.lightened(0.18))
		P.call(0.9, -5.5 + bob, 0.6, 3.4, shirt.darkened(0.22))
		P.call(-1.5, -2.6 + bob, 3.0, 0.5, ec if rank > 0 else Color("#5a3e26"))
		if rank > 0:
			P.call(0.6, -2.6 + bob, 0.5, 0.5, ec.lightened(0.5))
	# Volksmerkmale am Körper
	match race:
		5:
			P.call(-1.7, -5.8 + bob, 3.4, 0.8, Color("#f8fbff"))
		9:
			P.call(-1.5, -2.7 + bob, 0.5, 0.9, skin.darkened(0.3))
			P.call(1.0, -3.4 + bob, 0.5, 1.0, skin.darkened(0.3))
		10:
			P.call(-0.3, -5.2 + bob, 0.4, 2.6, Color("#6a4a2a"))
	# Kopf (3 × 3): Gesicht, Haar oben und hinten, Auge vorne
	var hy: float = -8.5 + bob
	P.call(-0.5, -5.8 + bob, 1.0, 0.4, skd)
	if race == 2:
		P.call(-1.4, hy - 0.3, 2.9, 3.0, skin)
		P.call(-1.4, hy - 0.3, 2.9, 0.7, hair)
		P.call(1.2, hy + 1.6, 0.3, 0.8, skd)
		P.call(-0.2, hy + 0.9, 0.5, 1.0, Color("#7a766e"))
	elif race == 8:
		P.call(-1.2, hy + 0.4, 2.6, 2.4, skin)
		P.call(-2.2, hy - 1.0, 4.4, 1.6, hair)
		P.call(-1.6, hy - 1.7, 3.2, 0.8, hair)
		P.call(-1.3, hy - 1.3, 0.7, 0.6, Color("#fff6ee"))
		P.call(0.6, hy - 0.9, 0.7, 0.6, Color("#fff6ee"))
	elif race == 10:
		P.call(-1.3, hy, 2.8, 2.9, skin)
		P.call(-1.8, hy - 1.0, 3.6, 1.4, hair)
		P.call(-0.8, hy - 1.8, 1.6, 0.9, hair.lightened(0.25))
		P.call(-1.8, hy, 0.8, 1.2, hair)
	else:
		P.call(-1.3, hy, 2.8, 2.9, skin)
		P.call(1.0, hy + 1.8, 0.5, 1.1, skd)
		P.call(-1.5, hy - 0.4, 3.1, 1.1, hair)
		P.call(-1.5, hy, 1.0, 2.1, hair)
		if race == 0 and adult:
			# Haarknoten der Gu-Meister
			P.call(-1.2, hy - 1.0, 1.0, 0.7, hair)
	match race:
		1:
			P.call(-1.3, hy + 2.0, 2.8, 0.8, hair)
		3:
			P.call(-1.8, hy + 0.5, 0.6, 1.2, Color("#3a9a8a"))
			P.call(0.2, hy + 2.2, 0.5, 0.4, Color("#3a9a8a"))
		4:
			P.call(-0.9, hy - 1.4, 0.8, 1.1, hair)
			P.call(0.1, hy - 1.0, 0.6, 0.7, Color("#f0c040"))
		5:
			P.call(0.4, hy + 2.2, 0.6, 0.4, Color("#a8d4f0"))
		6:
			P.call(-1.0, hy - 1.4, 0.5, 1.1, Color("#e8c860"))
			P.call(0.6, hy - 1.4, 0.5, 1.1, Color("#e8c860"))
			P.call(-1.3, hy + 2.4, 2.8, 0.5, skin.darkened(0.2))
		7:
			P.call(-1.3, hy - 1.1, 0.7, 0.9, hair)
			P.call(0.7, hy - 1.1, 0.7, 0.9, hair)
	var eye: Color = Color("#1a1210")
	if rogue:
		eye = Color("#ff3030")
	elif ow:
		eye = Color("#d04aff")
	elif race == 6 or race == 7:
		eye = Color("#e8b020")
	P.call(0.55, hy + 1.1, 0.5, 0.7, eye)
	P.call(0.55, hy + 1.1, 0.5, 0.2, Color(1, 1, 1, 0.35))
	# vorderer Arm mit Hand, ggf. Werkzeug
	if working:
		var up: bool = sin(anim * 14.0) > 0.0
		if up:
			P.call(1.0, -5.4 + bob, 0.8, 1.4, shirt.darkened(0.1))
			P.call(1.3, -8.4 + bob, 0.6, 3.2, Color("#8a5a30"))
			P.call(0.8, -8.8 + bob, 1.6, 0.7, Color("#b8b8c0"))
			P.call(1.0, -6.0 + bob, 0.8, 0.7, skin)
		else:
			P.call(1.0, -4.8 + bob, 0.8, 1.4, shirt.darkened(0.1))
			P.call(1.6, -4.4 + bob, 2.4, 0.6, Color("#8a5a30"))
			P.call(3.6, -5.2 + bob, 0.7, 1.6, Color("#b8b8c0"))
			P.call(1.2, -3.6 + bob, 0.8, 0.7, skin)
	else:
		P.call(0.2 + sw * 0.6, -5.2 + bob, 0.8, 2.3, shirt.darkened(0.08))
		P.call(0.2 + sw * 0.6, -2.9 + bob, 0.8, 0.6, skin)
	if rank >= 9:
		P.call(-1.3, hy - 1.4, 2.8, 0.6, Color("#ffd24a"))
		P.call(-1.3, hy - 2.1, 0.6, 0.7, Color("#ffd24a"))
		P.call(-0.3, hy - 2.4, 0.6, 1.0, Color("#fff0a0"))
		P.call(0.9, hy - 2.1, 0.6, 0.7, Color("#ffd24a"))
	if sick:
		P.call(1.4, hy - 1.4, 0.8, 0.8, Color("#86e04a"))
	_emit(sink, parts, ol * s)
	# kleines Gu, das um Gu-Meister kreist (Rang 1–5)
	if rank > 0 and rank < 6 and not no_aura and adult:
		var ga2: float = tnow * 2.2 + X * 1.3
		var gx: float = X + cos(ga2) * 2.4 * s
		var gy: float = Y + (-6.0 + sin(ga2) * 0.9) * s
		sink.call(Rect2(gx - 0.3 * s, gy - 0.3 * s, 0.6 * s, 0.6 * s), Color(ec, 0.9))
	if lucky and int(anim * 4.0) % 3 == 0:
		var rx2: float = X + (-2.8 if f > 0 else 2.0) * s
		sink.call(Rect2(rx2, Y - 9.0 * s, 0.8 * s, 0.8 * s), Color("#ffe27a"))


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
static var _place_lo: Dictionary = {}


## Ort für die Karte: hochaufgelöst, sobald erzeugt; bis dahin das grobe Bild (Kacheln = Pixel, dann size_div 1).
## Gibt [Textur, Teiler] zurück.
static func place_tex_any(type: String) -> Array:
	if _place_cache.has(type):
		return [_place_cache[type], float(PK)]
	if not _place_lo.has(type):
		_place_lo[type] = ImageTexture.create_from_image(place_image(type))
		var pk: String = "place:" + type
		if not _hd_pending.has(pk):
			_hd_pending[pk] = true
			_hd_jobs.append(func() -> void: place_tex(type))
	return [_place_lo[type], 1.0]


static func place_size(type: String) -> float:
	return float(PLACE_SIZE.get(type, 20))


## Textur eines Ortes für die Karte: place_image_hd (4 Texel je Kachel wie die Nahansicht) mit Mipmaps.
## Größe in Kacheln = Texturgröße / 4.
static func place_tex(type: String) -> ImageTexture:
	if _place_cache.has(type):
		return _place_cache[type]
	var im: Image = place_image_hd(type)
	im.generate_mipmaps()
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


# ---------------- Nahansicht (4 Texel je Kachel) ----------------
# Objekte für Detail: Bilder mit Fußpunkt (Bodenmitte), Licht von links oben, dunkle Kontur,
# weicher Schatten nach rechts unten. Erzeugt einmal beim Start (hd_init).

const HD_SHADOW: Color = Color(0.04, 0.12, 0.03, 0.34)
static var _hd: Dictionary = {}


## Aufträge zum Erzeugen der Nahansicht-Bilder; Detail.tick arbeitet sie im Zeitbudget ab (hd_step),
## damit der Start nicht stockt (im Browser läuft alles in einem Faden).
static var _hd_jobs: Array[Callable] = []
static var _hd_pending: Dictionary = {}
static var _hd_feat_left: int = -1
## Entwickler: längster einzelner Auftrag in Mikrosekunden
static var hd_job_max_us: int = 0


## Alle Objekt-Bilder sofort erzeugen (Entwickler-Bogen, Rückfall).
static func hd_init() -> void:
	hd_begin()
	while _hd_feat_left > 0:
		hd_step(1000000)


## Aufträge für alle Objekt-Bilder und Orte einreihen (einmal).
static func hd_begin() -> void:
	if _hd_feat_left >= 0:
		return
	var jobs: Array[Callable] = []
	var trees: Array = []
	for pi: int in range(GuData.TREEPAL.size()):
		for big: int in range(2):
			var vs: Array = []
			trees.append(vs)
			for v: int in range(2):
				var p: Array = GuData.TREEPAL[pi]
				var sd: int = pi * 31 + big * 7 + v * 3 + 1
				jobs.append(func() -> void:
					var e: Array = _hd_tree(p, big == 0, sd)
					var fl: Image = (e[0] as Image).duplicate()
					fl.flip_x()
					vs.append(e)
					vs.append([fl, Vector2i(fl.get_width() - 1 - (e[1] as Vector2i).x, (e[1] as Vector2i).y)]))
	_hd["tree"] = trees
	_hd["pine"] = []
	_hd["palm"] = []
	_hd["bamb"] = []
	_hd["rock"] = []
	_hd["ore"] = []
	_hd["spring"] = []
	_hd["shrub"] = []
	_hd["tuft"] = []
	_hd["flower"] = []
	jobs.append(func() -> void: _hd["pine"].append_array([_hd_pine(false, 3), _hd_pine(false, 4)]))
	jobs.append(func() -> void: _hd["pine"].append_array([_hd_pine(true, 5), _hd_pine(true, 6)]))
	jobs.append(func() -> void: _hd["palm"].append_array([_hd_palm(1, false), _hd_palm(2, true)]))
	jobs.append(func() -> void: _hd["bamb"].append_array([_hd_bamboo(1), _hd_bamboo(2)]))
	jobs.append(func() -> void:
		_hd["rock"].append_array([_hd_rock(1, false), _hd_rock(2, false)])
		_hd["ore"].append_array([_hd_rock(3, true), _hd_rock(4, true)])
		_hd["spring"].append(_hd_spring())
		_hd["shrub"].append_array([_hd_shrub(1), _hd_shrub(2)])
		_hd["tuft"].append_array([_hd_tuft(1), _hd_tuft(2), _hd_tuft(3)])
		_hd["flower"].append_array([_hd_flower(0), _hd_flower(1), _hd_flower(2), _hd_flower(3)]))
	_hd_feat_left = jobs.size()
	for j: Callable in jobs:
		_hd_jobs.append(func() -> void:
			j.call()
			_hd_feat_left -= 1)
	# Orte danach (bis dahin zeigt die Karte das grobe Bild)
	for pt: String in PLACE_SIZE.keys():
		_hd_jobs.append(func() -> void: place_tex(pt))


## Sind alle Objekt-Bilder der Nahansicht fertig?
static func hd_feat_ready() -> bool:
	return _hd_feat_left == 0


## Aufträge abarbeiten, bis budget_us Mikrosekunden verbraucht sind; true, wenn nichts mehr ansteht.
static func hd_step(budget_us: int) -> bool:
	var t0: int = Time.get_ticks_usec()
	while not _hd_jobs.is_empty():
		var j: Callable = _hd_jobs.pop_front()
		var t1: int = Time.get_ticks_usec()
		j.call()
		var now: int = Time.get_ticks_usec()
		hd_job_max_us = maxi(hd_job_max_us, now - t1)
		if now - t0 > budget_us:
			break
	return _hd_jobs.is_empty()


## Bild und Fußpunkt eines Objekts für die Nahansicht.
static func hd_feat(f: int, x: int, y: int, reg: int) -> Array:
	var h: float = GuData.hash2(x, y, 79)
	match f:
		GuData.F_TREE:
			var tv: int = tree_variant(x, y, reg)
			var vs: Array = _hd["tree"][tv]
			return vs[int(h * vs.size()) % vs.size()]
		GuData.F_PINE:
			return _hd["pine"][(2 if reg == 0 else 0) + (1 if h < 0.5 else 0)]
		GuData.F_PALM:
			return _hd["palm"][1 if h < 0.5 else 0]
		GuData.F_BAMB:
			return _hd["bamb"][1 if h < 0.5 else 0]
		GuData.F_ROCK:
			return _hd["rock"][1 if h < 0.5 else 0]
		GuData.F_ORE:
			return _hd["ore"][1 if h < 0.5 else 0]
		GuData.F_SPRING:
			return _hd["spring"][0]
		GuData.F_SHRUB:
			return _hd["shrub"][1 if h < 0.5 else 0]
		GuData.F_TUFT:
			return _hd["tuft"][int(h * 3.0) % 3]
		GuData.F_FLOWER:
			return _hd["flower"][int(h * 4.0) % 4]
	return _hd["tuft"][0]


static func _hdh(x: int, y: int, s: int) -> float:
	return GuData.hash2(x, y, s)


static var _nimg: Image = null


## Weiches Rauschen mit Strukturweite sc Pixel (für Blattbüschel, Fels): ein Nachschlagen in einem
## einmal nativ erzeugten Rauschbild (FastNoiseLite) statt vieler Hash-Rechnungen.
static func _hdvn(x: float, y: float, sc: float, s: int) -> float:
	if _nimg == null:
		var n: FastNoiseLite = FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_VALUE_CUBIC
		n.frequency = 0.25
		n.fractal_type = FastNoiseLite.FRACTAL_NONE
		n.seed = 4711
		_nimg = n.get_image(256, 256, false, false, true)
	var f: float = 4.0 / sc
	var ix: int = int(floorf(x * f + s * 37.0)) & 255
	var iy: int = int(floorf(y * f + s * 59.0)) & 255
	return _nimg.get_pixel(ix, iy).r


## Weicher Bodenschatten unter allem Bisherigen (nur auf leere Pixel).
static func _hd_ground_shadow(im: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	for y: int in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x: int in range(int(cx - rx) - 1, int(cx + rx) + 2):
			if x < 0 or y < 0 or x >= im.get_width() or y >= im.get_height():
				continue
			var dx: float = (x + 0.5 - cx) / rx
			var dy: float = (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0 and im.get_pixel(x, y).a < 0.1:
				im.set_pixel(x, y, HD_SHADOW)


## Dunkle Kontur um alle deckenden Pixel (Schatten zählt nicht). Arbeitet auf den Rohdaten (schnell).
static func _hd_outline(im: Image, col: Color) -> void:
	var w: int = im.get_width()
	var h: int = im.get_height()
	var d: PackedByteArray = im.get_data()
	var src: PackedByteArray = d.duplicate()
	var r: int = int(col.r * 255.0)
	var g: int = int(col.g * 255.0)
	var bb: int = int(col.b * 255.0)
	var a: int = int(col.a * 255.0)
	var row: int = w * 4
	for y: int in range(h):
		var o: int = y * row
		for x: int in range(w):
			var i: int = o + x * 4 + 3
			if src[i] > 153:
				continue
			if (x > 0 and src[i - 4] > 153) or (x < w - 1 and src[i + 4] > 153) or (y > 0 and src[i - row] > 153) or (y < h - 1 and src[i + row] > 153):
				d[i - 3] = r
				d[i - 2] = g
				d[i - 1] = bb
				d[i] = a
	im.set_data(w, h, false, Image.FORMAT_RGBA8, d)


## Kugeliger Klumpen mit Licht von links oben in vier Stufen (+ Blattsprenkel).
static func _hd_blob(im: Image, cx: float, cy: float, r: float, cols: Array, sd: int, leafy: bool, ao_y: float = 99999.0) -> void:
	for y: int in range(int(cy - r) - 1, int(cy + r) + 2):
		for x: int in range(int(cx - r) - 1, int(cx + r) + 2):
			if x < 0 or y < 0 or x >= im.get_width() or y >= im.get_height():
				continue
			var nx: float = (x + 0.5 - cx) / r
			var ny: float = (y + 0.5 - cy) / r
			var d2: float = nx * nx + ny * ny
			if d2 > 1.0:
				continue
			var s: float = -(nx * 0.55 + ny * 0.83) * 0.85 + (_hdh(x, y, sd) - 0.5) * 0.18
			if leafy:
				# kleine Blattbüschel: eigenes Licht je Büschel (Gitter 3 px)
				var bx: float = _hdvn(x + 0.5 - 0.7, y + 0.5 - 0.7, 3.0, sd + 7) - _hdvn(x + 0.5 + 0.7, y + 0.5 + 0.7, 3.0, sd + 7)
				s += bx * 1.3
			var k: int = 3 if s > 0.55 else (2 if s > 0.1 else (1 if s > -0.38 else 0))
			if d2 > 0.78 and s < -0.05:
				k = 0
			if leafy:
				var lh: float = _hdh(x, y, sd + 1)
				if lh < 0.05:
					k = mini(3, k + 1)
				elif lh > 0.95:
					k = maxi(0, k - 1)
			if y + 0.5 > ao_y:
				k = maxi(0, k - 1)
			im.set_pixel(x, y, cols[k])


static func _hd_tree(p: Array, big: bool, sd: int) -> Array:
	var w: int = 34 if big else 26
	var h: int = 41 if big else 32
	var im: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = sd
	var foot: Vector2i = Vector2i(w / 2, h - 3)
	var li: Color = Color(p[0])
	var mi: Color = Color(p[1])
	var dk: Color = Color(p[2])
	var cols: Array = [dk.darkened(0.12), mi, li, li.lightened(0.13)]
	var bark: Array = [Color("#4a3424"), Color("#6e4e34"), Color("#94704c")]
	# Stamm mit Wurzelansatz
	var tw: int = 4 if big else 3
	var cr: float = w * 0.4
	var ccx: float = w * 0.5
	var ccy: float = cr + 2.0
	var tx0: int = foot.x - tw / 2
	for y: int in range(int(ccy), foot.y + 1):
		for x: int in range(tx0, tx0 + tw):
			var c: Color = bark[1]
			if x == tx0:
				c = bark[2]
			elif x == tx0 + tw - 1:
				c = bark[0]
			if _hdh(x, y, sd + 5) < 0.12:
				c = bark[0]
			im.set_pixel(x, y, c)
	im.set_pixel(tx0 - 1, foot.y, bark[1])
	im.set_pixel(tx0 + tw, foot.y, bark[0])
	if big:
		im.set_pixel(tx0 - 1, foot.y - 1, bark[2])
		# Ast
		im.set_pixel(tx0 + tw, int(ccy + cr * 0.75), bark[1])
		im.set_pixel(tx0 + tw + 1, int(ccy + cr * 0.65), bark[1])
	# Krone aus Klumpen, von hinten (oben) nach vorne (unten)
	# Grundkörper zuerst, dann die Büschel darüber (sonst verdeckt er sie)
	_hd_blob(im, ccx, ccy + cr * 0.05, cr * 0.85, cols, sd * 13 + 99, true, ccy + cr * 0.75)
	var lobes: Array[Vector3] = []
	var n: int = 5 if big else 4
	for k: int in range(n):
		var a: float = -PI * 0.5 + (k - (n - 1) * 0.5) * (2.6 / n) + rng.randf_range(-0.18, 0.18)
		var dd: float = cr * rng.randf_range(0.42, 0.6)
		lobes.append(Vector3(ccx + cos(a) * dd * 1.1, ccy + sin(a) * dd * 0.9, cr * rng.randf_range(0.5, 0.66)))
	lobes.append(Vector3(ccx - cr * rng.randf_range(0.35, 0.5), ccy + cr * 0.42, cr * rng.randf_range(0.5, 0.6)))
	lobes.append(Vector3(ccx + cr * rng.randf_range(0.35, 0.5), ccy + cr * 0.38, cr * rng.randf_range(0.48, 0.58)))
	lobes.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.y < b.y)
	for k: int in range(lobes.size()):
		var lb: Vector3 = lobes[k]
		_hd_blob(im, lb.x, lb.y, lb.z, cols, sd * 13 + k, true, ccy + cr * 0.75)
	# Früchte/Blüten bei manchen Bäumen
	if rng.randf() < 0.35 and li.g > li.r + 0.05:
		var fc: Color = Color("#e84a3a") if rng.randf() < 0.6 else Color("#f8f0f0")
		for k: int in range(4 if big else 3):
			var fx: int = int(ccx + rng.randf_range(-cr * 0.7, cr * 0.7))
			var fy: int = int(ccy + rng.randf_range(-cr * 0.4, cr * 0.6))
			if im.get_pixel(fx, fy).a > 0.5:
				im.set_pixel(fx, fy, fc)
	_hd_outline(im, dk.darkened(0.55))
	_hd_ground_shadow(im, foot.x + 3.0, foot.y + 0.8, w * 0.36, 2.2)
	return [im, foot + Vector2i(0, 1)]


static func _hd_pine(snowy: bool, sd: int) -> Array:
	var w: int = 24
	var h: int = 48
	var im: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var foot: Vector2i = Vector2i(12, h - 3)
	var cols: Array = [Color("#183a2a"), Color("#24503a"), Color("#3a7050"), Color("#5a9a6a"), Color("#7ab88a")]
	var snow: Array = [Color("#c8d8e8"), Color("#eef4f6"), Color("#ffffff")]
	for y: int in range(37, foot.y + 1):
		im.set_pixel(11, y, Color("#7a6a5a"))
		im.set_pixel(12, y, Color("#5a4a3a"))
		im.set_pixel(13, y, Color("#4a3e34"))
	var tiers: int = 5
	for k: int in range(tiers):
		var top: int = 2 + k * 7
		var bot: int = top + 11 + k
		var wmax: float = 3.5 + k * 1.75
		for y: int in range(top, bot + 1):
			var hw: float = (y - top + 1.0) / float(bot - top + 1) * wmax + 0.6 + (_hdh(y, k, sd) - 0.5) * 1.1
			for x: int in range(int(12.0 - hw), int(12.0 + hw) + 1):
				if x < 0 or x >= w:
					continue
				var rel: float = (x + 0.5 - 12.0) / maxf(1.0, hw)
				var ci: int = 3 if rel < -0.4 else (2 if rel < 0.2 else 1)
				if y >= bot - 1:
					ci = maxi(0, ci - 1)
				if k > 0 and y < top + 2:
					ci = maxi(0, ci - 1)
				var hh: float = _hdh(x, y, sd + 9)
				if hh < 0.08:
					ci = mini(4, ci + 1)
				elif hh > 0.93:
					ci = maxi(0, ci - 1)
				var c: Color = cols[ci]
				if snowy and (y < top + 3 or (y >= bot - 1 and rel < 0.3)) and hh < 0.75:
					c = snow[2] if rel < -0.3 else (snow[1] if rel < 0.3 else snow[0])
				im.set_pixel(x, y, c)
	_hd_outline(im, Color("#0e2418"))
	_hd_ground_shadow(im, 15.0, foot.y + 0.8, 8.0, 2.0)
	return [im, foot + Vector2i(0, 1)]


static func _hd_palm(sd: int, lean_r: bool) -> Array:
	var w: int = 38
	var h: int = 46
	var im: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var foot: Vector2i = Vector2i(19, h - 3)
	var dir: float = 1.0 if lean_r else -1.0
	var top: Vector2 = Vector2(19, 14)
	# geschwungener Stamm mit Ringen
	for y: int in range(int(top.y), foot.y + 1):
		var t: float = float(foot.y - y) / float(foot.y - int(top.y))
		var x: int = int(roundf(foot.x + dir * sin(t * 1.5) * 4.0))
		for dx: int in range(-1, 2):
			var c: Color = Color("#c09a5a") if dx < 0 else (Color("#a07a44") if dx == 0 else Color("#7a5a32"))
			if y % 3 == 0:
				c = c.darkened(0.22)
			im.set_pixel(x + dx, y, c)
		top.x = x
	var cx: float = top.x
	var cy: float = top.y
	var fl: Color = Color("#8ad85a")
	var fm: Color = Color("#4ea83a")
	var fd: Color = Color("#2e7a2a")
	var angs: Array[float] = [-2.75, -2.2, -1.25, -0.6, 0.05, 2.95, 0.55, 2.45]
	for a: float in angs:
		var ln: float = 15.0 if absf(sin(a)) < 0.6 else 11.0
		for s: int in range(1, int(ln)):
			var px: float = cx + cos(a) * s
			var py: float = cy + sin(a) * s * 0.6 + s * s * 0.045
			var ix: int = int(px)
			var iy: int = int(py)
			if ix < 1 or ix >= w - 1 or iy < 1 or iy >= h - 1:
				continue
			im.set_pixel(ix, iy, fm if sin(a) < 0.2 else fd)
			if s < ln - 2:
				im.set_pixel(ix, iy - 1, fl if cos(a) < 0.3 else fm)
				if s % 2 == 0:
					im.set_pixel(ix, iy + 1, fd)
	for k: int in range(3):
		var ox: int = int(cx) - 2 + k * 2
		im.set_pixel(ox, int(cy) + 2, Color("#6a4a22"))
		im.set_pixel(ox + 1, int(cy) + 2, Color("#4a3018"))
		im.set_pixel(ox, int(cy) + 3, Color("#4a3018"))
	im.set_pixel(int(cx), int(cy), fl)
	_hd_outline(im, Color("#183a14"))
	_hd_ground_shadow(im, foot.x + 4.0, foot.y + 0.8, 10.0, 2.0)
	return [im, foot + Vector2i(0, 1)]


static func _hd_bamboo(sd: int) -> Array:
	var w: int = 28
	var h: int = 52
	var im: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = sd * 101
	var foot: Vector2i = Vector2i(14, h - 3)
	var gl: Color = Color("#a8dc68")
	var gm: Color = Color("#78b448")
	var gd: Color = Color("#4e8030")
	for k: int in range(6):
		var x: int = 3 + k * 4 + rng.randi_range(-1, 1)
		var top: int = foot.y - rng.randi_range(30, 46)
		var off: int = rng.randi_range(0, 5)
		for y: int in range(top, foot.y + 1 - (k % 2)):
			var node: bool = (y + off) % 6 == 0
			im.set_pixel(x, y, gd if node else gl)
			im.set_pixel(x + 1, y, gd if node else gm)
			if node and y < foot.y - 8 and rng.randf() < 0.55:
				var dx: int = -1 if rng.randf() < 0.5 else 1
				for s: int in range(1, 5):
					var lx: int = x + (0 if dx < 0 else 1) + dx * s
					var ly: int = y - s / 2
					if lx >= 0 and lx < w and ly >= 0:
						im.set_pixel(lx, ly, gl if s < 3 else gm)
						if ly + 1 < h and s > 1:
							im.set_pixel(lx, ly + 1, gd)
		im.set_pixel(x, top - 1, gl)
		im.set_pixel(x - 1, top - 2, gl)
	_hd_outline(im, Color("#1e3a12"))
	_hd_ground_shadow(im, foot.x + 3.0, foot.y + 0.8, 12.0, 2.0)
	return [im, foot + Vector2i(0, 1)]


static func _hd_rock(sd: int, ore: bool) -> Array:
	var w: int = 16
	var h: int = 13
	var im: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var foot: Vector2i = Vector2i(8, h - 3)
	var cols: Array = [Color("#5e5a56"), Color("#8a8680"), Color("#aeaaa2"), Color("#d0ccc2")]
	if ore:
		cols = [Color("#46423e"), Color("#6e6a66"), Color("#8e8a84"), Color("#aaa69e")]
	var rx: float = 6.6 if sd % 2 == 1 else 5.6
	for y: int in range(1, foot.y + 1):
		for x: int in range(w):
			var nx: float = (x + 0.5 - 8.0) / rx
			var ny: float = (y + 0.5 - (foot.y - 3.2)) / 4.4
			if ny > 0.0:
				ny *= 1.6
			var d2: float = nx * nx + ny * ny
			if d2 > 1.0:
				continue
			var s: float = -(nx * 0.6 + ny * 0.8) + (_hdh(x, y, sd) - 0.5) * 0.35
			var k: int = 3 if s > 0.55 else (2 if s > 0.1 else (1 if s > -0.4 else 0))
			im.set_pixel(x, y, cols[k])
	# Riss
	im.set_pixel(9, foot.y - 4, cols[0])
	im.set_pixel(10, foot.y - 3, cols[0])
	if ore:
		var cry: Array = [Color("#e8fff6"), Color("#8ff0c8"), Color("#3aa888")]
		for c: Vector2i in [Vector2i(5, foot.y - 6), Vector2i(9, foot.y - 7), Vector2i(11, foot.y - 4)]:
			im.set_pixel(c.x, c.y - 1, cry[0])
			im.set_pixel(c.x, c.y, cry[1])
			im.set_pixel(c.x + 1, c.y, cry[2])
			im.set_pixel(c.x, c.y + 1, cry[1])
	_hd_outline(im, Color("#2e2a26"))
	_hd_ground_shadow(im, 10.0, foot.y + 0.6, 7.0, 1.6)
	return [im, foot + Vector2i(0, 1)]


static func _hd_spring() -> Array:
	var w: int = 20
	var h: int = 12
	var im: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var foot: Vector2i = Vector2i(10, h - 2)
	for y: int in range(h):
		for x: int in range(w):
			var nx: float = (x + 0.5 - 10.0) / 9.0
			var ny: float = (y + 0.5 - 6.0) / 5.0
			var d2: float = nx * nx + ny * ny
			if d2 > 1.0:
				continue
			var c: Color
			if d2 > 0.55:
				var s: float = -(nx * 0.5 + ny * 0.85)
				c = Color("#b4b0a6") if s > 0.2 else (Color("#8e8a82") if s > -0.4 else Color("#64605a"))
				if _hdh(x, y, 3) < 0.15:
					c = c.darkened(0.15)
			else:
				var s2: float = nx * 0.5 + ny * 0.85
				c = Color("#3a9ab8") if s2 < -0.25 else (Color("#6fd6e8") if s2 < 0.35 else Color("#9ae8f4"))
			im.set_pixel(x, y, c)
	im.set_pixel(7, 5, Color.WHITE)
	im.set_pixel(8, 5, Color("#e0fbff"))
	im.set_pixel(12, 7, Color("#e0fbff"))
	_hd_outline(im, Color("#2a3a3e"))
	return [im, foot + Vector2i(0, 1)]


static func _hd_shrub(sd: int) -> Array:
	var w: int = 15
	var h: int = 11
	var im: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var foot: Vector2i = Vector2i(7, h - 2)
	var cols: Array = [Color("#5e5228"), Color("#8a7a3a"), Color("#a8964a"), Color("#c8b468")]
	_hd_blob(im, 4.5, 5.5, 3.6, cols, sd * 7, true)
	_hd_blob(im, 10.0, 5.8, 3.4, cols, sd * 7 + 1, true)
	_hd_blob(im, 7.2, 4.0, 3.8, cols, sd * 7 + 2, true)
	_hd_outline(im, Color("#3a3018"))
	_hd_ground_shadow(im, 9.0, foot.y + 0.6, 6.0, 1.4)
	return [im, foot + Vector2i(0, 1)]


static func _hd_tuft(sd: int) -> Array:
	var w: int = 9
	var h: int = 7
	var im: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var dk: Color = Color(0.12, 0.27, 0.08, 0.9)
	var md: Color = Color(0.22, 0.42, 0.14, 0.95)
	var lt: Color = Color(0.45, 0.66, 0.26, 1.0)
	var xs: Array[int] = [1, 3, 4, 6, 7]
	for k: int in range(xs.size()):
		var hh: int = 2 + int(_hdh(k, sd, 4) * 3.0)
		var x: int = xs[k]
		for y: int in range(h - 1 - hh, h - 1):
			im.set_pixel(x, y, lt if y == h - 1 - hh else (md if k % 2 == 0 else dk))
	return [im, Vector2i(4, h)]


static func _hd_flower(v: int) -> Array:
	var w: int = 8
	var h: int = 8
	var im: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var head: Color = [Color("#f07ac8"), Color("#ffd84a"), Color("#f8f4f0"), Color("#8aa8ff")][v]
	var stem: Color = Color("#2e6a22")
	for s: Vector3i in [Vector3i(2, 3, 0), Vector3i(5, 2, 1), Vector3i(4, 5, 0)]:
		for y: int in range(s.y + 1, h - 1):
			im.set_pixel(s.x, y, stem)
		im.set_pixel(s.x, s.y, head)
		im.set_pixel(s.x - 1, s.y, head.darkened(0.15))
		im.set_pixel(s.x + 1, s.y, head.darkened(0.15))
		im.set_pixel(s.x, s.y - 1, head.lightened(0.3))
		im.set_pixel(s.x, s.y + 1, head.darkened(0.3))
		im.set_pixel(s.x, s.y, Color("#ffe27a") if v != 1 else Color("#c87a20"))
	im.set_pixel(3, h - 2, stem)
	return [im, Vector2i(4, h - 1)]


## Entwickler: alle Nahansicht-Objekte (und Gebäude) vergrößert auf einen Bogen schreiben.
static func hd_sheet(path: String, extra: Array[Image] = []) -> void:
	hd_init()
	var ims: Array[Image] = []
	for key: String in ["tree", "pine", "palm", "bamb", "rock", "ore", "spring", "shrub", "tuft", "flower"]:
		var arr: Array = _hd[key]
		for e: Variant in arr:
			if e is Array and (e as Array).size() == 2 and (e as Array)[0] is Image:
				ims.append((e as Array)[0])
			elif e is Array:
				for e2: Array in (e as Array):
					ims.append(e2[0])
	ims.append_array(extra)
	var sc: int = 3
	var W2: int = 1400
	var x: int = 4
	var y: int = 4
	var rowh: int = 0
	var out: Image = Image.create_empty(W2, 2200, false, Image.FORMAT_RGBA8)
	out.fill(Color8(76, 132, 46))
	for im: Image in ims:
		var big: Image = im.duplicate()
		big.resize(im.get_width() * sc, im.get_height() * sc, Image.INTERPOLATE_NEAREST)
		if x + big.get_width() > W2:
			x = 4
			y += rowh + 6
			rowh = 0
		if y + big.get_height() > out.get_height():
			break
		out.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(x, y))
		x += big.get_width() + 6
		rowh = maxi(rowh, big.get_height())
	out.crop(W2, mini(out.get_height(), y + rowh + 6))
	out.save_png(path)


## Entwickler: Zusatzbilder für hd_sheet (Gebäude der Nahansicht).
static func hd_sheet_extra() -> Array[Image]:
	var out: Array[Image] = []
	# Wesen in der Größe wie bei z ≈ 24 (eine Einheit ≈ 6,5 Bildpunkte, hier durch 3 geteilt)
	for r: int in range(GuData.RACE_NAME.size()):
		var q: Px = Px.new(120, 40)
		var sk: Callable = func(rr: Rect2, c: Color) -> void: q.p(roundi(rr.position.x), roundi(rr.position.y), maxi(1, roundi(rr.position.x + rr.size.x) - roundi(rr.position.x)), maxi(1, roundi(rr.position.y + rr.size.y) - roundi(rr.position.y)), c)
		var k2: int = 0
		for rk: int in [0, 3, 6, 9]:
			draw_person(sk, 10.0 + k2 * 26.0, 36.0, 2.2 if rk < 9 else 1.3, r, rk, GuData.CLANCOL[(r + k2) % 16], 1, true, k2 == 1, 0.15, false, k2 == 2, false, false, false, 0.45, 0.0, false)
			k2 += 1
		out.append(q.img)
	for sp: String in GuData.SPEC.keys():
		var q2: Px = Px.new(60, 40)
		var sk2: Callable = func(rr: Rect2, c: Color) -> void: q2.p(roundi(rr.position.x), roundi(rr.position.y), maxi(1, roundi(rr.position.x + rr.size.x) - roundi(rr.position.x)), maxi(1, roundi(rr.position.y + rr.size.y) - roundi(rr.position.y)), c)
		var ss: float = float(GuData.SPEC[sp].get("ss", 1.0))
		draw_animal(sk2, 30.0, 36.0, 2.2 / maxf(1.0, ss * 0.6), sp, 1, false, 1.0, false, false, 3, 0.45, 1)
		out.append(q2.img)
	for pt: String in ["blessed", "grotto", "court", "imperial", "langya", "hu", "dream", "palace", "mushroom"]:
		out.append(place_image_hd(pt))
	for k: int in range(4):
		var d: Dictionary = clan_textures_hd(GuData.CLANCOL[k * 3], k)
		for key: String in ["fire", "tent", "hut", "house", "house_b", "hall1", "hall2", "forge", "tower", "farm", "pen"]:
			if k > 0 and key in ["farm", "pen", "hall2", "tower", "fire"]:
				continue
			out.append((d[key] as ImageTexture).get_image())
	return out


# ---------------- Gebäude der Nahansicht (4 Texel je Kachel) ----------------
# Jede Textur trägt Meta "foot" (Bodenmitte in Texeln); EntityLayer setzt diesen Punkt auf die
# Mitte der Grundfläche-Unterkante. Licht von links oben, dunkle Kontur, Schlagschatten nach rechts unten.

static var _clan_cache_hd: Dictionary = {}
const HD_OL: Color = Color(0.13, 0.08, 0.06, 1.0)


## Gebäude-Texturen der Nahansicht in der Farbe eines Clans, sofort und vollständig (Entwickler-Bogen).
static func clan_textures_hd(col: Color, race: int = 0) -> Dictionary:
	for key: String in ["fire", "tent", "hut", "house", "house_b", "hall1", "hall2", "forge", "tower", "farm", "pen"]:
		_hd_make_building(col, race, key)
	return _clan_cache_hd[col.to_html(false) + str(race)]


## Eine Gebäude-Textur der Nahansicht (Schlüssel wie clan_textures) oder null, solange sie noch
## erzeugt wird – dann ist der Auftrag eingereiht und der Aufrufer zeichnet das grobe Bild.
static func hd_building(col: Color, race: int, key: String) -> ImageTexture:
	var ck: String = col.to_html(false) + str(race)
	var d: Dictionary = _clan_cache_hd.get(ck, {})
	if d.has(key):
		return d[key]
	var pk: String = ck + key
	if not _hd_pending.has(pk):
		_hd_pending[pk] = true
		_hd_jobs.append(func() -> void: _hd_make_building(col, race, key))
	return null


static func _hd_make_building(col: Color, race: int, key: String) -> void:
	var ck: String = col.to_html(false) + str(race)
	if not _clan_cache_hd.has(ck):
		_clan_cache_hd[ck] = {}
	var res: Dictionary = _clan_cache_hd[ck]
	if res.has(key):
		return
	match key:
		"fire":
			res["fire"] = _hd_bt(_hdb_fire(), Vector2i(12, 13))
		"tent", "tent_b":
			var tent: Image = _hdb_tent(col, race)
			res["tent"] = _hd_bt(tent, Vector2i(12, 21))
			var tent_b: Image = tent.duplicate()
			tent_b.flip_x()
			res["tent_b"] = _hd_bt(tent_b, Vector2i(12, 21))
		"hut", "hut_b":
			var hut: Image = _hdb_hut(col, race)
			res["hut"] = _hd_bt(hut, Vector2i(15, 26))
			var hut_b: Image = hut.duplicate()
			hut_b.flip_x()
			res["hut_b"] = _hd_bt(hut_b, Vector2i(15, 26))
		"house":
			res["house"] = _hd_bt(_hdb_house(col, race, false), Vector2i(17, 33))
		"house_b":
			res["house_b"] = _hd_bt(_hdb_house(col, race, true), Vector2i(17, 43))
		"hall1":
			res["hall1"] = _hd_bt(_hdb_hall(col, false), Vector2i(23, 38))
		"hall2", "hall":
			res["hall2"] = _hd_bt(_hdb_hall(col, true), Vector2i(30, 54))
			res["hall"] = res["hall2"]
		"forge":
			res["forge"] = _hd_bt(_hdb_forge(col), Vector2i(18, 29))
		"tower":
			res["tower"] = _hd_bt(_hdb_tower(col), Vector2i(12, 53))
		"farm":
			res["farm"] = _hd_bt(_hdb_farm(col, false), Vector2i(31, 46), false)
		"pen":
			res["pen"] = _hd_bt(_hdb_farm(col, true), Vector2i(31, 46), false)
	_hd_pending.erase(ck + key)


## Kontur, Schlagschatten (2 Texel nach rechts unten) und Mipmaps; Fußpunkt als Meta.
static func _hd_bt(im: Image, foot: Vector2i, outline: bool = true) -> ImageTexture:
	var w: int = im.get_width()
	var h: int = im.get_height()
	var src: Image = Image.create_empty(w + 2, h + 2, false, Image.FORMAT_RGBA8)
	src.blit_rect(im, Rect2i(0, 0, w, h), Vector2i(1, 1))
	if outline:
		_hd_outline(src, HD_OL)
	# Schlagschatten: Silhouette 2 Texel versetzt in Schattenfarbe (über die Rohdaten)
	var sd: PackedByteArray = src.get_data()
	var od: PackedByteArray = PackedByteArray()
	od.resize((w + 5) * (h + 5) * 4)
	var sr: int = int(HD_SHADOW.r * 255.0)
	var sg: int = int(HD_SHADOW.g * 255.0)
	var sb: int = int(HD_SHADOW.b * 255.0)
	var sa: int = int(HD_SHADOW.a * 255.0)
	for y: int in range(h + 2):
		for x: int in range(w + 2):
			if sd[(y * (w + 2) + x) * 4 + 3] > 127:
				var o: int = ((y + 2) * (w + 5) + x + 2) * 4
				od[o] = sr
				od[o + 1] = sg
				od[o + 2] = sb
				od[o + 3] = sa
	var out: Image = Image.create_from_data(w + 5, h + 5, false, Image.FORMAT_RGBA8, od)
	out.blend_rect(src, Rect2i(0, 0, w + 2, h + 2), Vector2i.ZERO)
	out.generate_mipmaps()
	var t: ImageTexture = ImageTexture.create_from_image(out)
	t.set_meta("foot", Vector2(foot.x + 1, foot.y + 1))
	return t


## Dach von vorn: Trapez mit Ziegelreihen, Grat oben, Traufe unten; up = hochgezogene Ecken (Pagode).
static func _hdb_roof(q: Px, cx: float, top: int, ht: float, hb: float, h: int, C: Color, up: bool, ridge: Color = Color.TRANSPARENT) -> void:
	var cl: Color = C.lightened(0.22)
	var cd: Color = C.darkened(0.42)
	var cr: Color = C.darkened(0.18)
	for r: int in range(h):
		var y: int = top + r
		var t: float = float(r) / maxf(1.0, h - 1.0)
		var half: float = lerpf(ht, hb, t)
		var x0: int = int(roundf(cx - half))
		var x1: int = int(roundf(cx + half))
		for x: int in range(x0, x1):
			var c: Color = C
			var rel: float = (x + 0.5 - cx) / maxf(1.0, half)
			if rel < -0.55:
				c = cl
			elif rel > 0.55:
				c = cr
			if (x - x0) % 3 == 2:
				c = c.darkened(0.12)
			if r % 3 == 2:
				c = c.darkened(0.2)
			if r == h - 1:
				c = cd
			q.p(x, y, 1, 1, c)
		if up and r == h - 1:
			q.p(x0 - 2, y - 1, 2, 1, C)
			q.p(x0 - 3, y - 2, 1, 1, cl)
			q.p(x1, y - 1, 2, 1, cr)
			q.p(x1 + 2, y - 2, 1, 1, cr)
			q.p(x0 - 1, y, 1, 1, cd)
			q.p(x1, y, 1, 1, cd)
	var rx0: int = int(roundf(cx - ht))
	var rx1: int = int(roundf(cx + ht))
	q.p(rx0, top - 1, rx1 - rx0, 1, ridge if ridge.a > 0.0 else cl)
	if up:
		q.p(rx0 - 1, top - 2, 1, 1, ridge if ridge.a > 0.0 else cl)
		q.p(rx1, top - 2, 1, 1, ridge if ridge.a > 0.0 else cl)


## Wand: kind "plaster" (Fachwerk), "log" (Blockbohlen), "stone" (Mauer), "wood" (Halle mit roten Säulen).
static func _hdb_wall(q: Px, x0: int, y0: int, w: int, h: int, kind: String) -> void:
	for y: int in range(y0, y0 + h):
		for x: int in range(x0, x0 + w):
			var c: Color
			match kind:
				"log":
					c = Color("#a8743c") if (y - y0) % 3 != 2 else Color("#7a4e2a")
					if (y - y0) % 3 == 0:
						c = Color("#bc8a50")
				"stone":
					var row: int = (y - y0) / 3
					var bx: int = (x - x0 + (row % 2) * 2) % 5
					c = Color("#b0aa9c")
					if (y - y0) % 3 == 2 or bx == 4:
						c = Color("#7e786c")
					elif GuData.hash2(x, y, 31) < 0.15:
						c = Color("#c4beb0")
				"wood":
					c = Color("#8a5434") if (x - x0) % 2 == 0 else Color("#7a4a2c")
				_:
					c = Color("#ecdcbc")
					if GuData.hash2(x, y, 33) < 0.08:
						c = Color("#e0ceaa")
			if x == x0 + w - 1:
				c = c.darkened(0.18)
			if y == y0:
				c = c.darkened(0.35)
			elif y == y0 + 1:
				c = c.darkened(0.15)
			q.p(x, y, 1, 1, c)
	if kind == "plaster":
		var beam: Color = Color("#6a4428")
		q.p(x0, y0 + 1, w, 1, beam)
		q.p(x0, y0, 1, h, beam)
		q.p(x0 + w - 1, y0, 1, h, beam.darkened(0.2))
	if kind == "log":
		for y: int in range(y0 + 1, y0 + h, 3):
			q.p(x0 - 1, y, 1, 2, Color("#d8b07a"))
			q.p(x0 + w, y, 1, 2, Color("#8a5a30"))


static func _hdb_window(q: Px, x: int, y: int, w: int = 4, h: int = 4) -> void:
	q.p(x - 1, y - 1, w + 2, h + 2, Color("#4a2e1a"))
	q.p(x, y, w, h, Color("#ffd27a"))
	q.p(x, y, w, 1, Color("#fff0b4"))
	q.p(x + w / 2, y, 1, h, Color("#8a5a2a"))
	q.p(x, y + h / 2, w, 1, Color("#c08a3a"))
	q.p(x - 1, y + h, w + 2, 1, Color("#b8a080"))


static func _hdb_door(q: Px, x: int, y: int, w: int, h: int, col: Color = Color("#3a2414")) -> void:
	q.p(x - 1, y - 1, w + 2, h + 1, Color("#6a4428"))
	q.p(x, y, w, h, col)
	q.p(x, y, w, 1, col.darkened(0.4))
	q.p(x + w - 2, y + h / 2, 1, 1, Color("#e8c060"))


static func _hdb_found(q: Px, x0: int, y: int, w: int) -> void:
	for x: int in range(x0, x0 + w):
		q.p(x, y, 1, 1, Color("#a49e90") if (x - x0) % 4 != 3 else Color("#6e6a60"))
		q.p(x, y + 1, 1, 1, Color("#7a766c"))


static func _hdb_fire() -> Image:
	var q: Px = Px.new(24, 16)
	# Sitzbänke aus Stämmen
	q.p(1, 11, 5, 2, Color("#8a5a30"))
	q.p(1, 11, 5, 1, Color("#b07a44"))
	q.p(18, 10, 5, 2, Color("#8a5a30"))
	q.p(18, 10, 5, 1, Color("#b07a44"))
	# Steinring
	for k: int in range(14):
		var a: float = k * TAU / 14.0
		var x: int = int(roundf(12.0 + cos(a) * 6.0))
		var y: int = int(roundf(10.0 + sin(a) * 3.2))
		var c: Color = Color("#c4c4bc") if sin(a) < 0.0 else Color("#8a8a84")
		q.p(x - 1, y - 1, 2, 2, c)
		q.p(x, y, 1, 1, c.darkened(0.25))
	# Asche und Holzscheite
	q.p(8, 9, 8, 3, Color("#3a302a"))
	q.p(8, 8, 8, 2, Color("#7a5432"))
	q.p(9, 8, 6, 1, Color("#a8743c"))
	q.p(10, 10, 5, 2, Color("#55361e"))
	q.p(11, 7, 2, 4, Color("#6a4428"))
	return q.img


static func _hdb_tent(C: Color, race: int) -> Image:
	var tp: Array = [["#e6fff6", "#a4e8dc", "#6fc4bc", "#3f8e94"], ["#f0d8b0", "#c89a68", "#a07448", "#6e4c2e"],
		["#ecece4", "#bcb8ae", "#8e8a82", "#64605a"], ["#f0fbff", "#a8d4f0", "#74a8d8", "#4a74a8"]][clampi(race, 0, 3)]
	var q: Px = Px.new(24, 23)
	var ax: float = 12.0
	for y: int in range(5, 21):
		var half: float = (y - 4.0) / 16.0 * 11.0
		for x: int in range(int(ax - half), int(ax + half) + 1):
			var rel: float = (x + 0.5 - ax) / maxf(1.0, half)
			var c: Color = Color(tp[1]) if rel < 0.0 else Color(tp[2])
			if rel < -0.6:
				c = Color(tp[0])
			elif rel > 0.6:
				c = Color(tp[3])
			if (x + 64) % 5 == 0:
				c = c.darkened(0.12)
			if y == 20:
				c = Color(tp[3]).darkened(0.2)
			q.p(x, y, 1, 1, c)
	# Eingang
	for y: int in range(12, 21):
		var hw: float = (y - 11.0) / 9.0 * 3.4
		q.p(int(ax - hw), y, int(hw * 2.0) + 1, 1, Color("#1a1210"))
	q.p(int(ax) - 4, 18, 2, 3, Color(tp[0]))
	q.p(int(ax) + 3, 18, 2, 3, Color(tp[2]))
	# Stange mit Wimpel in Clanfarbe
	q.p(12, 0, 1, 6, Color("#6a4428"))
	q.p(13, 0, 4, 1, C.lightened(0.15))
	q.p(13, 1, 3, 1, C)
	q.p(13, 2, 2, 1, C.darkened(0.3))
	# Pflöcke
	q.p(0, 20, 1, 2, Color("#8a5a2e"))
	q.p(23, 20, 1, 2, Color("#8a5a2e"))
	q.p(1, 19, 2, 1, Color("#e8b850"))
	q.p(21, 19, 2, 1, Color("#e8b850"))
	return q.img


static func _hdb_hut(C: Color, race: int) -> Image:
	var q: Px = Px.new(31, 28)
	# Strohdach
	for r: int in range(13):
		var y: int = 2 + r
		var half: float = lerpf(5.0, 15.0, r / 12.0)
		var x0: int = int(15.5 - half)
		var x1: int = int(15.5 + half)
		for x: int in range(x0, x1):
			var hh: float = GuData.hash2(x, y / 2, 21)
			var rel: float = (x + 0.5 - 15.5) / half
			var c: Color = Color("#d8a058") if hh < 0.45 else (Color("#c8884a") if hh < 0.85 else Color("#e8bc74"))
			if rel < -0.6:
				c = c.lightened(0.12)
			elif rel > 0.55:
				c = c.darkened(0.2)
			if r == 12 or (r == 11 and hh > 0.7):
				c = Color("#94582c")
			q.p(x, y, 1, 1, c)
		if r == 12:
			for x2: int in range(x0, x1, 3):
				q.p(x2, y + 1, 1, 1, Color("#94582c"))
	q.p(11, 1, 10, 1, Color("#e8bc74"))
	q.p(14, 0, 3, 1, C)
	# Wand
	_hdb_wall(q, 4, 15, 23, 9, "stone" if race == 2 else "log")
	_hdb_door(q, 14, 18, 4, 6)
	_hdb_window(q, 7, 18, 3, 3)
	_hdb_window(q, 21, 18, 3, 3)
	_hdb_found(q, 3, 24, 25)
	return q.img


static func _hdb_house(C: Color, race: int, two: bool) -> Image:
	var hh: int = 44 if two else 34
	var q: Px = Px.new(35, hh)
	var off: int = 10 if two else 0
	# Schornstein
	q.p(25, 1, 3, 7, Color("#8a7e74"))
	q.p(25, 1, 1, 7, Color("#a89a8e"))
	q.p(24, 0, 5, 2, Color("#6a6058"))
	_hdb_roof(q, 17.5, 3, 9.0, 16.5, 13, C, true)
	if two:
		_hdb_wall(q, 6, 16, 23, 8, "plaster" if race != 2 else "stone")
		_hdb_window(q, 9, 18, 3, 3)
		_hdb_window(q, 16, 18, 3, 3)
		_hdb_window(q, 23, 18, 3, 3)
		_hdb_roof(q, 17.5, 24, 13.0, 16.5, 4, C, true)
	var wy: int = 16 + off
	_hdb_wall(q, 4, wy, 27, 15, "plaster" if race != 2 else "stone")
	_hdb_window(q, 8, wy + 4, 4, 4)
	_hdb_window(q, 23, wy + 4, 4, 4)
	_hdb_door(q, 15, wy + 6, 5, 9)
	# Laterne
	q.p(13, wy + 5, 1, 1, Color("#3a2414"))
	q.p(12, wy + 6, 3, 3, Color("#e04030"))
	q.p(12, wy + 6, 1, 1, Color("#ff8a6a"))
	_hdb_found(q, 3, wy + 15, 29)
	return q.img


static func _hdb_hall(C: Color, big: bool) -> Image:
	var Y: Color = Color("#f0c040")
	var red: Color = Color("#c63a2a")
	if not big:
		var q: Px = Px.new(47, 39)
		q.p(21, 0, 5, 1, Y)
		q.p(22, 1, 3, 2, Y.darkened(0.15))
		_hdb_roof(q, 23.5, 4, 11.0, 22.5, 13, C, true, Y)
		_hdb_wall(q, 5, 17, 37, 15, "wood")
		for x: int in [5, 12, 19, 27, 34, 40]:
			q.p(x, 17, 2, 15, red)
			q.p(x, 17, 1, 15, red.lightened(0.2))
		_hdb_window(q, 8, 21, 3, 4)
		_hdb_window(q, 14, 21, 4, 4)
		_hdb_window(q, 30, 21, 4, 4)
		_hdb_window(q, 36, 21, 3, 4)
		_hdb_door(q, 21, 22, 6, 10, Color("#5a2416"))
		q.p(23, 24, 1, 1, Y)
		q.p(24, 24, 1, 1, Y)
		q.p(23, 28, 1, 1, Y)
		q.p(24, 28, 1, 1, Y)
		# Laternen
		for x2: int in [17, 29]:
			q.p(x2, 19, 2, 3, Color("#e84a2a"))
			q.p(x2, 19, 1, 1, Color("#ffb08a"))
		# Steinpodest mit Stufen
		q.p(2, 32, 43, 3, Color("#b4ae9e"))
		q.p(2, 32, 43, 1, Color("#cac4b4"))
		q.p(2, 34, 43, 1, Color("#8a847a"))
		q.p(19, 35, 10, 2, Color("#a49e90"))
		q.p(19, 35, 10, 1, Color("#bcb6a8"))
		return q.img
	var q2: Px = Px.new(61, 55)
	q2.p(28, 0, 5, 1, Y)
	q2.p(29, 1, 3, 2, Y.darkened(0.15))
	_hdb_roof(q2, 30.5, 4, 10.0, 19.5, 10, C, true, Y)
	_hdb_wall(q2, 14, 14, 33, 8, "wood")
	for x: int in [14, 20, 26, 33, 39, 45]:
		q2.p(x, 14, 2, 8, red)
	_hdb_window(q2, 17, 16, 2, 3)
	_hdb_window(q2, 29, 16, 3, 3)
	_hdb_window(q2, 42, 16, 2, 3)
	_hdb_roof(q2, 30.5, 22, 20.0, 29.0, 8, C, true, Y)
	_hdb_wall(q2, 5, 30, 51, 16, "wood")
	for x: int in [5, 12, 19, 26, 34, 41, 48, 54]:
		q2.p(x, 30, 2, 16, red)
		q2.p(x, 30, 1, 16, red.lightened(0.2))
	for x: int in [8, 15, 22, 37, 44, 51]:
		_hdb_window(q2, x, 34, 3, 5)
	_hdb_door(q2, 27, 35, 8, 11, Color("#5a2416"))
	for yy: int in [37, 42]:
		q2.p(29, yy, 1, 1, Y)
		q2.p(32, yy, 1, 1, Y)
	# Banner in Clanfarbe
	for x3: int in [1, 57]:
		q2.p(x3 + 1, 26, 1, 22, Color("#5a3a20"))
		q2.p(x3, 28, 3, 10, C)
		q2.p(x3, 28, 1, 10, C.lightened(0.2))
		q2.p(x3 + 1, 32, 1, 2, Y)
	q2.p(2, 46, 57, 4, Color("#b4ae9e"))
	q2.p(2, 46, 57, 1, Color("#cac4b4"))
	q2.p(2, 49, 57, 1, Color("#8a847a"))
	q2.p(25, 50, 12, 2, Color("#a49e90"))
	q2.p(25, 50, 12, 1, Color("#bcb6a8"))
	q2.p(27, 52, 8, 2, Color("#9a9486"))
	return q2.img


static func _hdb_forge(C: Color) -> Image:
	var q: Px = Px.new(37, 30)
	_hdb_roof(q, 11.5, 3, 6.0, 11.5, 9, C, false)
	_hdb_wall(q, 1, 12, 21, 13, "stone")
	# offene Werkstatt mit Glut
	q.p(6, 16, 10, 9, Color("#2a1a12"))
	q.p(7, 21, 8, 4, Color("#4a2a1a"))
	q.p(8, 22, 3, 2, Color("#ff8a3a"))
	q.p(9, 22, 1, 1, Color("#ffe27a"))
	# Ofen mit Jade-Glut (Gu-Veredelung)
	for y: int in range(8, 26):
		for x: int in range(23, 35):
			var rel: float = (x + 0.5 - 29.0) / 6.0
			var c: Color = Color("#6a6a74") if rel < -0.3 else (Color("#54545e") if rel < 0.4 else Color("#3e3e48"))
			if (y + (x / 3) % 2) % 3 == 0:
				c = c.darkened(0.15)
			q.p(x, y, 1, 1, c)
	q.p(22, 7, 14, 2, Color("#7a7a84"))
	q.p(26, 17, 6, 5, Color("#2a1410"))
	q.p(27, 18, 4, 4, Color("#ff8a3a"))
	q.p(28, 19, 2, 2, Color("#ffe27a"))
	q.p(26, 2, 6, 6, Color("#4a4a52"))
	q.p(27, 1, 4, 1, Color("#8ff0c8"))
	q.p(28, 0, 2, 1, Color("#e8fff6"))
	# Amboss
	q.p(16, 24, 6, 2, Color("#5a5a62"))
	q.p(17, 23, 5, 1, Color("#8a8a94"))
	q.p(18, 26, 2, 1, Color("#3a3a42"))
	_hdb_found(q, 0, 26, 36)
	return q.img


static func _hdb_tower(C: Color) -> Image:
	var q: Px = Px.new(24, 54)
	var wd: Color = Color("#7a5030")
	var wl: Color = Color("#a8743c")
	# Beine und Streben
	for x: int in [3, 19]:
		q.p(x, 20, 2, 32, wd)
		q.p(x, 20, 1, 32, wl)
	for k: int in range(3):
		var y0: int = 22 + k * 10
		for s: int in range(10):
			q.p(5 + int(s * 1.4), y0 + s, 1, 1, wd)
			q.p(18 - int(s * 1.4), y0 + s, 1, 1, wd.darkened(0.15))
		q.p(4, y0, 16, 1, wl)
	# Plattform mit Geländer
	q.p(1, 17, 22, 3, Color("#9a6a3a"))
	q.p(1, 17, 22, 1, Color("#c08a50"))
	q.p(1, 19, 22, 1, Color("#5a3a20"))
	q.p(2, 11, 20, 6, Color("#8a5a30"))
	q.p(9, 12, 6, 3, Color("#1a1210"))
	q.p(11, 13, 1, 1, Color("#ffd27a"))
	# Dach
	_hdb_roof(q, 12.0, 5, 2.0, 11.5, 7, C, true)
	q.p(12, 0, 1, 5, Color("#5a4030"))
	q.p(13, 0, 5, 1, C.lightened(0.15))
	q.p(13, 1, 4, 1, C)
	q.p(13, 2, 3, 1, C.darkened(0.3))
	q.p(1, 52, 22, 2, Color("#6a5a46"))
	return q.img


static func _hdb_farm(C: Color, pen: bool) -> Image:
	var q: Px = Px.new(63, 48)
	var fx0: int = 1
	var fy0: int = 4
	var fx1: int = 61
	var fy1: int = 45
	if not pen:
		# Äcker: zwei Felder mit unterschiedlicher Frucht, Furchen quer
		for y: int in range(fy0 + 2, fy1 - 1):
			for x: int in range(fx0 + 2, fx1 - 1):
				var left: bool = x < 31
				var row: int = (y - fy0) % 4
				var c: Color
				if row == 3:
					c = Color("#6a4c2c") if (x + y) % 3 else Color("#7a5a34")
				else:
					var hh: float = GuData.hash2(x, y, 5)
					if left:
						c = Color("#e0c450") if hh < 0.55 else (Color("#c8a43a") if hh < 0.85 else Color("#f0dc80"))
						if row == 2:
							c = c.darkened(0.15)
					else:
						c = Color("#7ab83e") if hh < 0.6 else (Color("#5e9a2e") if hh < 0.9 else Color("#9ad05a"))
						if row == 0 and x % 3 == 0:
							c = Color("#a8dc68")
						if row == 2:
							c = c.darkened(0.18)
				q.p(x, y, 1, 1, c)
		q.p(31, fy0 + 2, 1, fy1 - fy0 - 3, Color("#8a6a40"))
	else:
		# Gehege: zertretene Wiese, Heuhaufen, Trog, Stall
		for y: int in range(fy0 + 1, fy1):
			for x: int in range(fx0 + 1, fx1):
				var hh2: float = GuData.hash2(x, y, 9)
				var c2: Color = Color("#8a9a4a") if hh2 < 0.5 else (Color("#7a8a40") if hh2 < 0.85 else Color("#a08a58"))
				q.p(x, y, 1, 1, c2)
		_hdb_roof(q, 49.0, 6, 6.0, 9.0, 6, C, false)
		q.p(41, 12, 16, 8, Color("#8a5a30"))
		q.p(41, 12, 16, 1, Color("#5a3a20"))
		q.p(47, 14, 4, 6, Color("#2a1a10"))
		for k: int in range(3):
			q.d(9 + k * 4, 12 - (k % 2), 3, Color("#e0c060"))
		q.p(7, 9, 12, 2, Color("#f0d878"))
		q.p(7, 15, 12, 1, Color("#a88a34"))
		q.p(26, 33, 10, 3, Color("#6a4a2a"))
		q.p(27, 33, 8, 1, Color("#7ab0d8"))
	# Zaun: Pfosten und zwei Latten
	var rail: Color = Color("#c09a64")
	var raild: Color = Color("#7a5a34")
	q.p(fx0, fy0, fx1 - fx0 + 1, 1, rail)
	q.p(fx0, fy0 + 1, fx1 - fx0 + 1, 1, raild)
	q.p(fx0, fy1, 26, 1, rail)
	q.p(fx1 - 25, fy1, 26, 1, rail)
	q.p(fx0, fy1 + 1, 26, 1, raild)
	q.p(fx1 - 25, fy1 + 1, 26, 1, raild)
	q.p(fx0, fy0, 1, fy1 - fy0 + 2, rail)
	q.p(fx1, fy0, 1, fy1 - fy0 + 2, raild)
	for x: int in range(fx0, fx1 + 1, 6):
		for y: int in [fy0, fy1]:
			if y == fy1 and x > 26 and x < fx1 - 25:
				continue
			q.p(x, y - 2, 2, 4, Color("#e4b44e"))
			q.p(x + 1, y - 1, 1, 3, Color("#a8743c"))
	for y: int in range(fy0, fy1 + 1, 6):
		q.p(fx0 - 1, y - 1, 2, 3, Color("#e4b44e"))
		q.p(fx1, y - 1, 2, 3, Color("#a8743c"))
	# Fahne in Clanfarbe
	q.p(31, 0, 1, 5, Color("#5a4030"))
	q.p(32, 0, 4, 2, C)
	q.p(32, 0, 4, 1, C.lightened(0.2))
	return q.img


## Scale2x (EPX): verdoppelt ein Pixelbild und rundet dabei Diagonalen ab.
static func scale2x(src: Image) -> Image:
	var w: int = src.get_width()
	var h: int = src.get_height()
	var sd: PackedByteArray = src.get_data()
	if src.get_format() != Image.FORMAT_RGBA8:
		var c: Image = src.duplicate()
		c.convert(Image.FORMAT_RGBA8)
		sd = c.get_data()
	var px: PackedInt32Array = sd.to_int32_array()
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(w * h * 4)
	var w2: int = w * 2
	for y: int in range(h):
		for x: int in range(w):
			var P: int = px[y * w + x]
			var A: int = px[(y - 1) * w + x] if y > 0 else P
			var B: int = px[y * w + x + 1] if x < w - 1 else P
			var C: int = px[y * w + x - 1] if x > 0 else P
			var D: int = px[(y + 1) * w + x] if y < h - 1 else P
			var e0: int = P
			var e1: int = P
			var e2: int = P
			var e3: int = P
			if C == A and C != D and A != B:
				e0 = A
			if A == B and A != C and B != D:
				e1 = B
			if D == C and D != B and C != A:
				e2 = C
			if B == D and B != A and D != C:
				e3 = D
			var o: int = (y * 2) * w2 + x * 2
			out[o] = e0
			out[o + 1] = e1
			out[o + w2] = e2
			out[o + w2 + 1] = e3
	return Image.create_from_data(w2, h * 2, false, Image.FORMAT_RGBA8, out.to_byte_array())


## Feine Körnung in großen einfarbigen Flächen (vergrößerte Orte wirken sonst flach).
static func _grain(im: Image, sd: int) -> void:
	for y: int in range(1, im.get_height() - 1):
		for x: int in range(1, im.get_width() - 1):
			var c: Color = im.get_pixel(x, y)
			if c.a < 0.95:
				continue
			# nur im Inneren einfarbiger Flächen
			if im.get_pixel(x - 1, y) != c or im.get_pixel(x, y - 1) != c:
				continue
			var h: float = GuData.hash2(x, y, sd)
			if h < 0.1:
				im.set_pixel(x, y, c.darkened(0.07))
			elif h > 0.93:
				im.set_pixel(x, y, c.lightened(0.06))


# ---------------- Orte in der Nahansicht (4 Texel je Kachel) ----------------
# Gleicher Aufbau wie place_image, aber in feinen Pixeln gezeichnet: Inseln mit Gesteinsschichten
# und Licht, Bäume der Nahansicht, Pagoden mit Ziegeldächern.

const PK: int = 4
static var _pink_tree: Array = []


static func place_image_hd(type: String) -> Image:
	hd_init()
	var k: int = PK
	var W2: int = int(place_size(type))
	var H2: int = int(W2 * 0.95)
	var q: Px = Px.new(W2 * k, H2 * k)
	# Rechteck in Kachel-Einheiten
	var P: Callable = func(x: float, y: float, w: float, h: float, c: Variant) -> void:
		var x0: int = roundi(x * k)
		var y0: int = roundi(y * k)
		q.p(x0, y0, maxi(1, roundi((x + w) * k) - x0), maxi(1, roundi((y + h) * k) - y0), c)
	var grass: Array = [Color("#9ade6a"), Color("#6ab84a"), Color("#4a8a34"), Color("#2e5e24")]
	var rock: Array = [Color("#a8987e"), Color("#8a7a62"), Color("#6a5a48"), Color("#4a3e32")]
	var cx: float = W2 / 2.0
	match type:
		"blessed", "hu":
			if type == "hu":
				grass = [Color("#ffd090"), Color("#f0a860"), Color("#d8803a"), Color("#a05a26")]
			_island_hd(q, k, cx, H2 * 0.42, W2 * 0.44, H2 * 0.14, H2 * 0.5, grass, rock, 11 if type == "blessed" else 12)
			var gy: float = H2 * 0.42
			_tree_hd(q, k, cx - W2 * 0.26, gy - 0.5, type == "hu", 1)
			_tree_hd(q, k, cx + W2 * 0.27, gy, type == "hu", 2)
			_pagoda_hd(q, k, cx, gy, Color("#c23a2e") if type == "blessed" else Color("#e8e0d0"), 2)
			P.call(cx + 4.0, gy - 1.0, 2.0, 0.75, Color("#7ae8ff"))
			P.call(cx + 4.25, gy - 1.0, 0.75, 0.25, Color("#ffffff"))
		"grotto":
			_island_hd(q, k, cx - 2.0, H2 * 0.4, W2 * 0.36, H2 * 0.12, H2 * 0.48, grass, rock, 21)
			_island_hd(q, k, W2 * 0.86, H2 * 0.22, W2 * 0.1, H2 * 0.05, H2 * 0.2, grass, rock, 22)
			_island_hd(q, k, W2 * 0.12, H2 * 0.62, W2 * 0.09, H2 * 0.05, H2 * 0.18, grass, rock, 23)
			var gy2: float = H2 * 0.4
			_tree_hd(q, k, cx - 9.0, gy2 - 0.5, false, 3)
			_tree_hd(q, k, cx + 7.0, gy2, false, 4)
			_pagoda_hd(q, k, cx - 1.0, gy2, Color("#8a46b8"), 3)
			# Wasserfall
			for yy: int in range(int((gy2 + 0.5) * k), int((gy2 + 12.0) * k)):
				for xx: int in range(int((cx + 8.75) * k), int((cx + 10.0) * k)):
					var ph: int = (yy + xx * 3) % 6
					q.p(xx, yy, 1, 1, Color("#e8f8ff") if ph < 2 else (Color("#a8e8ff") if ph < 4 else Color("#78c8f0")))
			P.call(W2 * 0.86 - 1.0, H2 * 0.22 - 3.0, 2.0, 3.0, Color("#ffe27a"))
			P.call(W2 * 0.86 - 0.5, H2 * 0.22 - 3.5, 1.0, 0.5, Color("#fff6c0"))
		"court", "imperial":
			var roof: Color = Color("#f0c040") if type == "court" else Color("#e0a020")
			_island_hd(q, k, cx, H2 * 0.55, W2 * 0.46, H2 * 0.1, H2 * 0.4, [Color("#ffffff"), Color("#f0f4fc"), Color("#d4deec"), Color("#a8b8cc")], [Color("#e4ecf6"), Color("#c4d0de"), Color("#9eacc0"), Color("#76849a")], 31)
			var gy3: float = H2 * 0.55
			# Palastmauer mit Zinnen und Toren
			P.call(cx - W2 * 0.4, gy3 - 3.0, W2 * 0.8, 3.0, Color("#c8382a"))
			P.call(cx - W2 * 0.4, gy3 - 3.0, W2 * 0.8, 0.25, Color("#e05a40"))
			P.call(cx - W2 * 0.4, gy3 - 0.5, W2 * 0.8, 0.5, Color("#8a2418"))
			P.call(cx - W2 * 0.4, gy3 - 4.0, W2 * 0.8, 1.0, roof)
			P.call(cx - W2 * 0.4, gy3 - 3.25, W2 * 0.8, 0.25, roof.darkened(0.35))
			var nb: int = int(W2 * 0.8 / 2.0)
			for b: int in range(nb):
				P.call(cx - W2 * 0.4 + b * 2.0 + 0.5, gy3 - 4.5, 1.0, 0.5, roof.lightened(0.15))
			_pagoda_hd(q, k, cx - W2 * 0.24, gy3 - 2.0, roof, 2, Color("#c8382a"))
			_pagoda_hd(q, k, cx + W2 * 0.24, gy3 - 2.0, roof, 2, Color("#c8382a"))
			if type == "court":
				# Himmelsüberwachungsturm
				var tx2: float = cx
				for yy2: int in range(int((gy3 - 26.0) * k), int((gy3 - 2.0) * k)):
					for xx2: int in range(int((tx2 - 2.0) * k), int((tx2 + 3.0) * k)):
						var rel: float = (xx2 + 0.5) / k - (tx2 + 0.5)
						var c2: Color = Color("#ffffff") if rel < -1.2 else (Color("#f0ece0") if rel < 0.8 else Color("#c8c0b0"))
						if (yy2 / k) % 2 == 0 and (xx2 % k) == 0:
							c2 = c2.darkened(0.06)
						q.p(xx2, yy2, 1, 1, c2)
				for kk: int in range(5):
					var ry: float = gy3 - 6.0 - kk * 5.0
					_hdb_roof(q, (tx2 + 0.5) * k, int(ry * k), 2.0 * k, 3.6 * k, k + 1, roof, true)
				P.call(tx2 - 1.0, gy3 - 30.0, 3.0, 4.0, roof)
				P.call(tx2 - 1.0, gy3 - 30.0, 1.0, 4.0, roof.lightened(0.2))
				P.call(tx2, gy3 - 32.0, 1.0, 2.0, Color("#fff8c0"))
				P.call(tx2 - 1.0, gy3 - 22.0, 3.0, 2.0, Color("#7ae8ff"))
				P.call(tx2 - 0.75, gy3 - 21.75, 1.0, 0.75, Color("#ffffff"))
			else:
				_pagoda_hd(q, k, cx, gy3 - 2.0, roof, 3, Color("#c8382a"))
		"langya":
			_island_hd(q, k, cx, H2 * 0.45, W2 * 0.44, H2 * 0.13, H2 * 0.48, grass, rock, 41)
			var gy4: float = H2 * 0.45
			for kk2: int in range(3):
				var sx: float = cx - 9.0 + kk2 * 7.0
				var rc: Color = [Color("#d23a2a"), Color("#3a7ad8"), Color("#e8b020")][kk2]
				P.call(sx - 1.0, gy4 - 3.0, 3.0, 3.0, Color("#e8d0a0"))
				P.call(sx + 1.5, gy4 - 3.0, 0.5, 3.0, Color("#c8ac7c"))
				P.call(sx, gy4 - 2.0, 1.0, 2.0, Color("#5a3a1a"))
				_hdb_roof(q, (sx + 0.5) * k, int((gy4 - 4.75) * k), 1.6 * k, 2.8 * k, k + 1, rc, true)
			P.call(cx - 1.0, gy4 - 9.0, 3.0, 3.0, Color("#ffd23a"))
			P.call(cx - 1.0, gy4 - 9.0, 1.0, 1.0, Color("#fff4b0"))
			P.call(cx, gy4 - 8.0, 1.0, 1.0, Color("#8a5a10"))
			_tree_hd(q, k, cx + 10.0, gy4, false, 5)
		"dream":
			for y: int in range(H2 * k):
				for x: int in range(W2 * k):
					var fx: float = (x + 0.5) / k
					var fy: float = (y + 0.5) / k
					var dd: float = Vector2((fx - cx) / (W2 * 0.5), (fy - H2 * 0.55) / (H2 * 0.42)).length()
					if dd > 1.0:
						continue
					var ang: float = atan2(fy - H2 * 0.55, fx - cx)
					var band: float = sin(dd * 9.0 - ang * 2.0)
					if band > 0.2 or dd < 0.25:
						var c: Color = Color("#f0c8ff").lerp(Color("#8a5ad8"), dd)
						if band > 0.8:
							c = c.lightened(0.2)
						c.a = 0.95 - dd * 0.45
						q.p(x, y, 1, 1, c)
			# leuchtender Kern
			q.d(roundi(cx * k), roundi(H2 * 0.55 * k), 5, Color("#f4e0ff"))
			q.d(roundi(cx * k), roundi(H2 * 0.55 * k), 3, Color("#ffffff"))
		_:
			# übrige Orte: grobes Bild vergrößern (Scale2x zweimal) – sie sind klein
			return scale2x(scale2x(place_image(type)))
	_hd_outline(q.img, Color(0.08, 0.07, 0.06, 0.9))
	return q.img


## Schwebende Insel in feinen Pixeln: gewölbte Grasdecke (Licht links oben), Grasnarbe,
## Fels in Schichten nach unten spitz zulaufend, hängende Wurzeln.
static func _island_hd(q: Px, k: int, cx: float, top: float, rx: float, ry: float, depth: float, grass: Array, rock: Array, sd: int) -> void:
	var im: Image = q.img
	var iw: int = im.get_width()
	var ky: int = int((top - ry) * k)
	var kb: int = int((top + depth) * k) + 1
	for y: int in range(maxi(0, ky), mini(im.get_height(), kb)):
		var fy: float = (y + 0.5) / k
		if fy <= top:
			for x: int in range(maxi(0, int((cx - rx) * k) - 2), mini(iw, int((cx + rx) * k) + 3)):
				var fx: float = (x + 0.5) / k
				var dx: float = (fx - cx) / rx
				var dy: float = (fy - top) / ry
				var d2: float = dx * dx + dy * dy
				if d2 > 1.0:
					continue
				var s: float = -dx * 0.6 - dy * 0.5 + (_hdvn(x, y, 3.0, sd) - 0.5) * 0.7
				var ci: int = 0 if s > 0.75 else (1 if s > -0.1 else 2)
				if d2 > 0.86 and dy < -0.3:
					ci = 0 if dx < 0.0 else 2
				var hh: float = _hdh(x, y, sd)
				if hh < 0.06:
					ci = maxi(0, ci - 1)
				elif hh > 0.95:
					ci = mini(3, ci + 1)
				im.set_pixel(x, y, grass[ci])
		else:
			var kk: float = (fy - top) / depth
			var jag: float = 0.85 + 0.25 * _hdvn(0.0, y, 2.5 * k / 4.0, sd + 3)
			var hw: float = rx * pow(maxf(0.0, 1.0 - kk), 0.9) * jag
			for x: int in range(maxi(0, int((cx - hw) * k) - 1), mini(iw, int((cx + hw) * k) + 2)):
				var fx2: float = (x + 0.5) / k
				if absf(fx2 - cx) > hw:
					continue
				var rel: float = (fx2 - cx) / maxf(0.5, hw)
				var ci2: int = 1 if rel < -0.35 else (2 if rel < 0.45 else 3)
				if rel < -0.75:
					ci2 = 0
				# Schichten
				var band: float = fmod(fy + _hdvn(x, 0.0, 6.0, sd + 4) * 0.8, 1.6)
				if band < 0.22:
					ci2 = mini(3, ci2 + 1)
				if kk > 0.7:
					ci2 = mini(3, ci2 + 1)
				if _hdh(x, y, sd + 1) < 0.07:
					ci2 = mini(3, ci2 + 1)
				var c: Color = rock[ci2]
				# Grasnarbe direkt unter der Decke
				if fy - top < 0.75:
					c = grass[3] if fy - top > 0.4 or _hdh(x, 0, sd + 2) < 0.4 else grass[2]
				im.set_pixel(x, y, c)
	# hängende Wurzeln
	for r: int in range(5):
		var wx: float = cx - rx * 0.6 + r * rx * 0.3
		var ln: int = int((1.5 + _hdh(r, sd, 9) * 2.5) * k)
		var y0: int = int((top + 0.7) * k)
		for t: int in range(ln):
			var xx: int = int(wx * k + sin(t * 0.5 + r) * 1.2)
			q.p(xx, y0 + t, 1, 1, Color("#5a3a20") if t < ln - 2 else Color("#7a8a3a"))


## Baum der Nahansicht auf einer Insel (Fußpunkt in Kacheln).
static func _tree_hd(q: Px, k: int, x: float, y: float, pink: bool, v: int) -> void:
	var e: Array
	if pink:
		if _pink_tree.is_empty():
			_pink_tree = _hd_tree(["#ffc8dc", "#f08aac", "#b84a6a"], false, 77)
		e = _pink_tree
	else:
		var trees: Array = _hd["tree"]
		var pal: int = [0, 3, 0, 3, 0, 3][v % 6]
		var vs: Array = trees[pal * 2 + 1]
		e = vs[v % vs.size()]
	var im: Image = e[0]
	var foot: Vector2i = e[1]
	q.img.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(roundi(x * k) - foot.x, roundi(y * k) - foot.y + 2))


## Pagode mit floors Stockwerken in feinen Pixeln (Fußpunkt x, y in Kacheln).
static func _pagoda_hd(q: Px, k: int, x: float, y: float, roof: Color, floors: int, wall: Color = Color("#e8d8b0")) -> void:
	for f: int in range(floors):
		var w: float = 9.0 - f * 2.0
		var by: float = y - f * 4.0
		var wx0: int = roundi((x - w / 2.0 + 1.0) * k)
		var wy0: int = roundi((by - 2.0) * k)
		var ww: int = roundi((w - 2.0) * k)
		var wh: int = 2 * k
		for yy: int in range(wy0, wy0 + wh):
			for xx: int in range(wx0, wx0 + ww):
				var c: Color = wall
				if xx == wx0 or xx == wx0 + ww - 1 or (xx - wx0) % (2 * k) == 0:
					c = Color("#c63a2a") if wall.r > 0.85 and wall.g > 0.8 else wall.darkened(0.25)
				if yy == wy0:
					c = c.darkened(0.35)
				q.p(xx, yy, 1, 1, c)
		# Fenster mit warmem Licht, unten eine Tür
		for wi: int in range(int(w - 3.0)):
			var fx: int = wx0 + k + wi * k
			if fx + 2 >= wx0 + ww - 1:
				break
			if f == 0 and wi == int((w - 3.0) / 2.0):
				q.p(fx, wy0 + 3, k - 1, wh - 3, Color("#3a2414"))
			else:
				q.p(fx, wy0 + 3, 2, 3, Color("#ffd27a"))
				q.p(fx, wy0 + 3, 2, 1, Color("#fff0b4"))
		_hdb_roof(q, x * k + k * 0.5, roundi((by - 4.0) * k) + 1, (w / 2.0 - 1.4) * k, (w / 2.0 + 0.4) * k, k + 1, roof, true)
	q.p(roundi(x * k) + 1, roundi((y - floors * 4.0 - 2.0) * k), 2, 2 * k, Color("#ffd23a"))
	q.p(roundi(x * k) + 1, roundi((y - floors * 4.0 - 2.0) * k), 1, 2 * k, Color("#fff4b0"))
