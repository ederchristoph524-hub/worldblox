class_name TerrOverlay
extends Node2D
## Über den Clan-Gebieten (Weltkoordinaten, liegt in world_root direkt über terr_spr): leuchtende
## Herrschaftsgebiete der Ehrwürdigen und pulsierende Kriegsgrenzen (World.war_tex).
## Dazu statisch die großen Gebietsnamen, die der ScreenLayer in Bildschirmkoordinaten zeichnet.

var m: GuMain
var fill_spr: Sprite2D  ## Nahansicht: Gebietsflächen ohne Kachel-Ränder
var edge_spr: Sprite2D  ## Nahansicht: feine Doppel-Grenzlinien (World.EDGE_S-fache Auflösung)
var war_spr: Sprite2D
static var _aura: GradientTexture2D = null


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	fill_spr = Sprite2D.new()
	fill_spr.centered = false
	fill_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(fill_spr)
	edge_spr = Sprite2D.new()
	edge_spr.centered = false
	edge_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	edge_spr.scale = Vector2.ONE / World.EDGE_S
	add_child(edge_spr)
	war_spr = Sprite2D.new()
	war_spr.centered = false
	war_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(war_spr)


## Läuft jedes Bild (aus GuMain._process): Nahansicht einblenden (close 0 = Übersicht, 1 = nah),
## Kriegsgrenzen pulsieren lassen, Auren neu zeichnen.
func tick(terr_on: bool, close: float) -> void:
	var wl: World = m.sim.world
	var on: bool = terr_on and wl.layer != 2
	fill_spr.texture = wl.fill_tex
	edge_spr.texture = wl.edge_tex
	war_spr.texture = wl.war_tex
	fill_spr.visible = on and close > 0.0
	edge_spr.visible = fill_spr.visible
	fill_spr.modulate.a = 0.48 * close
	edge_spr.modulate.a = 0.95 * close
	war_spr.visible = on
	var t: float = Time.get_ticks_msec() / 1000.0
	war_spr.modulate.a = lerpf(1.0, 0.45, close) * (0.6 + 0.4 * sin(t * 4.2))
	queue_redraw()


static func aura_tex() -> GradientTexture2D:
	if _aura == null:
		var g: Gradient = Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0.5))
		g.set_color(1, Color(1, 1, 1, 0.0))
		g.add_point(0.45, Color(1, 1, 1, 0.24))
		g.add_point(0.82, Color(1, 1, 1, 0.34))
		g.add_point(0.96, Color(1, 1, 1, 0.75))
		_aura = GradientTexture2D.new()
		_aura.gradient = g
		_aura.fill = GradientTexture2D.FILL_RADIAL
		_aura.fill_from = Vector2(0.5, 0.5)
		_aura.fill_to = Vector2(1.0, 0.5)
		_aura.width = 128
		_aura.height = 128
	return _aura


## Stärke der Auren: Ebene „Einflusssphären“ voll, sonst zart.
func _aura_strength() -> float:
	return 1.0 if (m.show_terr and m.sim.world.layer == 3 and not m.reg_view) else 0.5


func _draw() -> void:
	if Influence.doms.is_empty():
		return
	var a: float = _aura_strength()
	var t: float = Time.get_ticks_msec() / 1000.0
	var w: float = 2.2 / m.z
	for d: Dictionary in Influence.doms:
		var c: Vector2 = Vector2(float(d["x"]), float(d["y"]))
		var r: float = float(d["r"])
		var col: Color = d["col"]
		draw_texture_rect(aura_tex(), Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(col.lightened(0.1), a))
		# gestrichelter, langsam kreisender Rand
		var seg: int = 28
		for k: int in range(seg):
			var s0: float = k * TAU / seg + t * 0.06
			draw_arc(c, r, s0, s0 + TAU / seg * 0.55, 6, Color(col.lightened(0.45), 0.85 * a), w)
		draw_arc(c, r * 0.985, 0.0, TAU, 96, Color(col.darkened(0.5), 0.35 * a), w * 0.7)


# ---------------- Gebietsnamen (ScreenLayer) ----------------

## Ausweichstellen eines Gebietsnamens (in Breiten/Höhen des Namens), nächste zuerst.
const LABEL_OFFS: Array[Vector2] = [Vector2.ZERO, Vector2(0, -0.9), Vector2(0, 0.9), Vector2(-0.45, 0), Vector2(0.45, 0),
	Vector2(-0.4, -0.9), Vector2(0.4, -0.9), Vector2(-0.4, 0.9), Vector2(0.4, 0.9), Vector2(0, -1.8), Vector2(0, 1.8),
	Vector2(-0.6, -1.8), Vector2(0.6, -1.8), Vector2(-0.6, 1.8), Vector2(0.6, 1.8), Vector2(0, -2.7), Vector2(0, 2.7)]

## Große Clan- bzw. Machtnamen quer über die Gebiete (wie Königreichsnamen in WorldBox) und die Namen der
## Herrschaftsgebiete der Ehrwürdigen. avoid: schon belegte Bildschirm-Rechtecke (Dorf-Schilder).
static func draw_labels(ci: CanvasItem, m: GuMain, o: Vector2, z: float, vs: Vector2, avoid: Array[Rect2]) -> void:
	var sim: Sim = m.sim
	var wl: World = sim.world
	var font: Font = m.hud.font_black
	var font2: Font = m.hud.font_bold
	var cjk: Font = m.hud.font_cjk
	var tz: float = m.terr_zoom()
	var on: bool = m.show_terr and not m.reg_view and wl.layer != 2
	# Ehrwürdige: Krone, Name und Titel am Rand ihres Herrschaftsgebiets (oben, sonst unten oder innen)
	var da: float = 1.0 if (on and wl.layer == 3) else 0.85
	for d: Dictionary in Influence.doms:
		var col: Color = d["col"]
		var r: float = float(d["r"])
		var nm: String = str(d["name"])
		var ti: String = str(d.get("title", ""))
		if ti == nm:
			ti = ""
		var fs: int = 12 if z < tz else 13
		var tw: float = maxf(font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 18.0, font2.get_string_size(ti, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x)
		var bh: float = fs + (13.0 if ti != "" else 3.0)
		var cx: float = float(d["x"]) * z + o.x
		var cy: float = float(d["y"]) * z + o.y
		var rect: Rect2 = Rect2()
		var first: bool = true
		for ay: float in [cy - r * z - bh * 0.5, cy + r * z - bh * 0.5, cy - r * z * 0.5 - bh, cy + r * z * 0.5]:
			var rr: Rect2 = Rect2(clampf(cx - tw / 2.0, 4.0, maxf(4.0, vs.x - tw - 4.0)), clampf(ay, 4.0, maxf(4.0, vs.y - bh - 4.0)), tw, bh)
			if first:
				rect = rr
				first = false
			var clash: bool = false
			for q: Rect2 in avoid:
				if q.intersects(rr):
					clash = true
					break
			if not clash:
				rect = rr
				break
		if rect.end.x < 0 or rect.position.x > vs.x or rect.end.y < 0 or rect.position.y > vs.y:
			continue
		avoid.append(rect)
		var nw: float = font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var lx: float = roundf(rect.position.x + (tw - nw - 18.0) / 2.0)
		_crown(ci, Vector2(lx + 7.0, rect.position.y + fs * 0.5 - 3.0), 1.0, Color(Color("#ffd24a"), da))
		var tp: Vector2 = Vector2(lx + 18.0, roundf(rect.position.y + fs))
		ci.draw_string_outline(font, tp, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(col.darkened(0.8), 0.9 * da))
		ci.draw_string(font, tp, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(col.lightened(0.55), da))
		if ti != "":
			var tiw: float = font2.get_string_size(ti, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
			var sp: Vector2 = Vector2(roundf(rect.position.x + (tw - tiw) / 2.0), roundf(rect.end.y - 1.0))
			ci.draw_string_outline(font2, sp, ti, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, 4, Color(0.03, 0.04, 0.03, 0.85 * da))
			ci.draw_string(font2, sp, ti, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(Color("#ffe8a0"), da))
	if not on:
		return
	var fa: float = clampf((tz * 1.3 - z) / (tz * 0.4), 0.0, 1.0)
	if fa <= 0.0:
		return
	# Ebene 3: je Macht ein Name (am eigenen Gebiet der Vormacht, Größe nach dem ganzen Bund), sonst je Clan
	var items: Array = []
	if wl.layer == 3:
		var tot: Dictionary = {}
		for kv: Variant in wl.terr_center.keys():
			var ck: int = int(kv)
			if ck < Influence.head.size() and Influence.head[ck] >= 0:
				var hh: int = Influence.head[ck]
				tot[hh] = float(tot.get(hh, 0.0)) + (wl.terr_center[ck] as Vector3).z
		for hv: Variant in tot.keys():
			if wl.terr_center.has(hv):
				var hc3: Vector3 = wl.terr_center[hv]
				items.append(Vector4(hc3.x, hc3.y, float(tot[hv]), float(int(hv))))
	else:
		for kv2: Variant in wl.terr_center.keys():
			var cc3: Vector3 = wl.terr_center[kv2]
			items.append(Vector4(cc3.x, cc3.y, cc3.z, float(int(kv2))))
	items.sort_custom(func(a: Vector4, b: Vector4) -> bool: return a.z > b.z)
	for it: Vector4 in items:
		var key: int = int(it.w)
		if key < 0 or key >= sim.clans.size():
			continue
		var c3: Vector3 = Vector3(it.x, it.y, it.z)
		if c3.z < 60.0:
			continue
		var c: Clan = sim.clans[key]
		# Clans mit nur einem Dorf: das Hauptstadt-Schild genügt (Mächte-Ebene: Bünde und Mächte ab 2 Dörfern)
		var nvk: int = Influence.nvil[key] if key < Influence.nvil.size() else 0
		if wl.layer != 3 and nvk < 2 and m.show_names:
			continue
		var title: String = c.name
		var sub: String = ""
		var sub_col: Color = Color(0.9, 0.93, 0.88)
		if wl.layer == 3:
			title = Influence.bloc_name(c)
			var b: Dictionary = Influence.bloc.get(key, {})
			var nmem: int = int(b.get("n", 1))
			var bv: int = int(b.get("v", 0))
			sub = ("%d clans · " % nmem if nmem > 1 else "") + ("%d villages" % bv if bv != 1 else "1 village")
			var dm: Dictionary = Influence.dominion_of(c)
			if not dm.is_empty():
				sub += " · " + str(dm["name"])
		else:
			var L: Unit = c.lead
			sub = ("R%d · " % L.rank if L != null and L.hp > 0.0 and L.rank > 0 else "") + ("%d villages" % nvk if nvk != 1 else "1 village")
			var ov: Clan = Influence.overlord(sim, c)
			if ov != null:
				sub = "follows " + ov.name
				sub_col = ov.col.lightened(0.5)
			if not c.war.is_empty():
				sub += " · war"
		var fs: int = clampi(int(6.0 + sqrt(c3.z) * z * 0.11), 11, 19)
		var fs2: int = maxi(9, fs - 4)
		var gs: float = fs + 3.0  # Siegel-Kästchen
		var tw: float = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var sw: float = font2.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
		var bw: float = maxf(gs + 4.0 + tw, sw)
		var bh: float = fs + fs2 + 6.0
		var ctr: Vector2 = Vector2(c3.x + 0.5, c3.y + 0.5) * z + o
		var rect: Rect2 = Rect2()
		var ok: bool = false
		for off: Vector2 in LABEL_OFFS:
			var r2: Rect2 = Rect2(roundf(ctr.x - bw / 2.0 + off.x * bw), roundf(ctr.y - bh / 2.0 + off.y * bh), bw, bh)
			# im Bild halten
			r2.position.x = clampf(r2.position.x, 4.0, maxf(4.0, vs.x - bw - 4.0))
			var clash: bool = false
			for q: Rect2 in avoid:
				if q.intersects(r2.grow(2.0)):
					clash = true
					break
			if not clash:
				rect = r2
				ok = true
				break
		if not ok:
			continue
		if rect.end.x < 0 or rect.position.x > vs.x or rect.end.y < 0 or rect.position.y > vs.y:
			continue
		avoid.append(rect)
		var col: Color = c.col
		var ink: Color = col.darkened(0.82)
		ink.a = 0.92 * fa
		# Siegel: Kästchen in Clanfarbe mit Zeichen
		var gx: float = rect.position.x + (bw - gs - 4.0 - tw) / 2.0
		var gy: float = rect.position.y + 1.0
		ci.draw_rect(Rect2(gx - 1.0, gy - 1.0, gs + 2.0, gs + 2.0), Color(ink, 0.9 * fa))
		ci.draw_rect(Rect2(gx, gy, gs, gs), Color(col.darkened(0.1), fa))
		ci.draw_rect(Rect2(gx + 1.5, gy + 1.5, gs - 3.0, gs - 3.0), Color(col.lightened(0.45), 0.8 * fa), false, 1.0)
		var gfs: int = maxi(9, fs - 3)
		var gw: float = cjk.get_string_size(c.glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, gfs).x
		ci.draw_string(cjk, Vector2(roundf(gx + gs / 2.0 - gw / 2.0), roundf(gy + gs / 2.0 + gfs * 0.38)), c.glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, gfs, Color(col.lightened(0.8), fa))
		var tp2: Vector2 = Vector2(roundf(gx + gs + 4.0), roundf(gy + gs / 2.0 + fs * 0.36))
		ci.draw_string_outline(font, tp2, title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, ink)
		ci.draw_string(font, tp2, title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(col.lightened(0.62), fa))
		var sp: Vector2 = Vector2(roundf(rect.position.x + bw / 2.0 - sw / 2.0), roundf(rect.end.y - 2.0))
		ci.draw_string_outline(font2, sp, sub, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, 4, Color(0.03, 0.04, 0.03, 0.85 * fa))
		ci.draw_string(font2, sp, sub, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, Color(sub_col, fa))


## Kleine Pixel-Krone (Mitte oben bei p).
static func _crown(ci: CanvasItem, p: Vector2, s: float, col: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array([Vector2(-7, 7), Vector2(-7, 0), Vector2(-3.5, 3.5), Vector2(0, -1), Vector2(3.5, 3.5), Vector2(7, 0), Vector2(7, 7)])
	for k: int in range(pts.size()):
		pts[k] = p + pts[k] * s
	var ol: Color = Color(0.12, 0.07, 0.02, col.a)
	var olp: PackedVector2Array = pts.duplicate()
	olp.append(pts[0])
	ci.draw_colored_polygon(pts, col)
	ci.draw_polyline(olp, ol, 1.5)
	ci.draw_rect(Rect2(p.x - 7.0 * s, p.y + 5.0 * s, 14.0 * s, 2.0 * s), col.darkened(0.3))
	ci.draw_rect(Rect2(p.x - 1.0, p.y + 2.5 * s, 2.0, 2.0), Color(0.9, 0.2, 0.2, col.a))
