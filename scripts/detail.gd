class_name Detail
extends Node2D
## Nahansicht der Welt: Gelände mit 4 × 4 Texeln je Kachel (Shader) und Objekte (Bäume, Felsen …)
## in hoher Auflösung, die je 32er-Block nur bei Bedarf gebacken werden.
##
## Gelände: Ein Datenbild (256 × 256, je Kachel R = Geländeart, G = Höhe, B = Wasserabstand,
## A = Region × 16 + Straße) wird im Shader zu Pixel-Art: verwackelte (organische) Grenzen,
## Wassertiefe in Stufen mit Gischt am Ufer, Licht von links oben über die Höhe, Schnee auf Gipfeln,
## Dünenrippel, glühende Lava, schimmernde Regionswände. Kosten auf der CPU nur beim Ändern von Kacheln.
## Objekte: Sprites.hd_feat (4 Texel je Kachel) werden je Block in ein Bild gemischt (wie World._render_rect).
## Ein Block gilt als veraltet, wenn World.dver (Version je Block, steigt in flush_dirty/render_all) sich ändert.

const DS: int = 4
const CHK: int = World.CHK
const CXN: int = World.CXN
const CPX: int = CHK * DS
## Höchstens so viele Objekt-Blöcke behalten (64 = ganze Karte, je ~85 kB mit Mipmaps)
const MAX_FEAT: int = 48
## Zeitbudget je Bild für das Backen in Millisekunden
const BUDGET_MS: float = 3.0
## Ab dieser Zoomstufe blendet die Nahansicht ein (voll ab Z_FULL)
const Z_ON: float = 2.7
const Z_FULL: float = 2.95

var world: World
var dat_img: Image
var dat_tex: ImageTexture
var dat_ver: PackedInt32Array
var dat_dirty: bool = false
var feat: FeatLayer
var ftex: Array[ImageTexture] = []
var fver: PackedInt32Array
var fuse: PackedInt32Array  ## letztes Bild, in dem der Block sichtbar war (für das Verdrängen)
var frame: int = 0
var amt: float = 0.0
var view: Rect2 = Rect2()
var mat: ShaderMaterial
## Messwerte (Entwickler): Zeit fürs Backen im letzten Bild und Höchstwert
var last_ms: float = 0.0
var max_ms: float = 0.0
var built: int = 0
## Entwickler: Nahansicht abschalten (Vergleichsmessung)
var dev_off: bool = false


func _ready() -> void:
	Sprites.hd_begin()
	mat = ShaderMaterial.new()
	var sh: Shader = Shader.new()
	sh.code = SHADER
	mat.shader = sh
	material = mat
	feat = FeatLayer.new()
	feat.d = self
	feat.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	add_child(feat)
	dat_img = Image.create_empty(World.W, World.H, false, Image.FORMAT_RGBA8)
	dat_tex = ImageTexture.create_from_image(dat_img)
	mat.set_shader_parameter("dat", dat_tex)
	mat.set_shader_parameter("nz", _noise_tex(64, 11))
	mat.set_shader_parameter("wn", _noise_tex(256, 23))
	mat.set_shader_parameter("ds", float(DS))
	dat_ver = PackedInt32Array()
	dat_ver.resize(CXN * CXN)
	dat_ver.fill(-1)
	fver = PackedInt32Array()
	fver.resize(CXN * CXN)
	fver.fill(-1)
	fuse = PackedInt32Array()
	fuse.resize(CXN * CXN)
	ftex.resize(CXN * CXN)


## Zufallswerte in allen vier Kanälen (n × n, kachelbar durch Wiederholung im Shader).
static func _noise_tex(n: int, sd: int) -> ImageTexture:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = sd
	var ints: PackedInt32Array = PackedInt32Array()
	ints.resize(n * n)
	for i: int in range(n * n):
		ints[i] = rng.randi()
	return ImageTexture.create_from_image(Image.create_from_data(n, n, false, Image.FORMAT_RGBA8, ints.to_byte_array()))


## Jedes Bild aus main.gd: sichtbarer Ausschnitt in Kacheln und Zoom.
func tick(w: World, vrect: Rect2, z: float) -> void:
	if w != world:
		world = w
		dat_ver.fill(-1)
		fver.fill(-1)
		for c: int in range(ftex.size()):
			ftex[c] = null
	frame += 1
	amt = 0.0 if dev_off else clampf((z - Z_ON) / (Z_FULL - Z_ON), 0.0, 1.0)
	var t0: int = Time.get_ticks_usec()
	# Bilder der Nahansicht im Hintergrund erzeugen; bis die Objekte fertig sind, bleibt das 1:1-Bild
	Sprites.hd_step(int(BUDGET_MS * 1000.0))
	if not Sprites.hd_feat_ready():
		amt = 0.0
	visible = amt > 0.0
	view = vrect
	# Datenbild: geänderte Blöcke neu kodieren (immer, damit es beim Hineinzoomen bereit ist)
	for c: int in range(CXN * CXN):
		if dat_ver[c] != world.dver[c]:
			_encode(c)
			dat_ver[c] = world.dver[c]
			dat_dirty = true
			if (Time.get_ticks_usec() - t0) > BUDGET_MS * 1000.0:
				break
	if dat_dirty and (visible or frame % 30 == 0):
		dat_tex.update(dat_img)
		dat_dirty = false
	if visible:
		mat.set_shader_parameter("amt", amt)
		feat.modulate.a = amt
		_bake_visible(t0)
		feat.queue_redraw()
		queue_redraw()
	last_ms = (Time.get_ticks_usec() - t0) / 1000.0
	max_ms = maxf(max_ms, last_ms)


func _draw() -> void:
	# Ein Rechteck über die ganze Karte; der Shader rechnet nur sichtbare Pixel.
	draw_rect(Rect2(0, 0, World.W, World.H), Color.WHITE)


## Sichtbare Blöcke (plus Rand) backen, die nächsten zur Bildmitte zuerst, im Zeitbudget.
func _bake_visible(t0: int) -> void:
	var cx0: int = clampi(int(floorf(view.position.x / CHK)) - 1, 0, CXN - 1)
	var cy0: int = clampi(int(floorf(view.position.y / CHK)) - 1, 0, CXN - 1)
	var cx1: int = clampi(int(floorf(view.end.x / CHK)) + 1, 0, CXN - 1)
	var cy1: int = clampi(int(floorf(view.end.y / CHK)) + 1, 0, CXN - 1)
	var cen: Vector2 = view.get_center() / CHK
	var todo: Array[Vector3] = []
	for cy: int in range(cy0, cy1 + 1):
		for cx: int in range(cx0, cx1 + 1):
			var c: int = cy * CXN + cx
			fuse[c] = frame
			if fver[c] != world.dver[c]:
				todo.append(Vector3(Vector2(cx + 0.5, cy + 0.5).distance_squared_to(cen), c, 0))
	if todo.is_empty():
		return
	todo.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.x < b.x)
	for e: Vector3 in todo:
		var c: int = int(e.y)
		_bake(c)
		fver[c] = world.dver[c]
		built += 1
		if (Time.get_ticks_usec() - t0) > BUDGET_MS * 1000.0:
			break
	_evict()


## Zu viele Blöcke im Speicher: die am längsten nicht gesehenen freigeben.
func _evict() -> void:
	var n: int = 0
	for c: int in range(ftex.size()):
		if ftex[c] != null:
			n += 1
	while n > MAX_FEAT:
		var old: int = -1
		for c: int in range(ftex.size()):
			if ftex[c] != null and (old < 0 or fuse[c] < fuse[old]):
				old = c
		ftex[old] = null
		fver[old] = -1
		n -= 1


## Kacheldaten eines Blocks ins Datenbild schreiben.
func _encode(c: int) -> void:
	var x0: int = (c % CXN) * CHK
	var y0: int = (c / CXN) * CHK
	var buf: PackedByteArray = PackedByteArray()
	buf.resize(CHK * CHK * 4)
	var tile: PackedByteArray = world.tile
	var hgt: PackedFloat32Array = world.hgt
	var wd: PackedByteArray = world.wdist
	var reg: PackedByteArray = world.region
	var ft: PackedByteArray = world.feat
	var ts: PackedByteArray = world.temp_snow
	var k: int = 0
	for y: int in range(y0, y0 + CHK):
		var i: int = y * World.W + x0
		for x: int in range(CHK):
			var t: int = tile[i]
			if t == GuData.SNOW and ts[i] > 0:
				t = 13
			buf[k] = t
			buf[k + 1] = clampi(int(hgt[i] * 255.0), 0, 255)
			buf[k + 2] = 0 if t != GuData.DEEP and t != GuData.SHAL else mini(wd[i], 63) * 4
			buf[k + 3] = reg[i] * 16 + (1 if ft[i] == GuData.F_ROAD else 0)
			k += 4
			i += 1
	var im: Image = Image.create_from_data(CHK, CHK, false, Image.FORMAT_RGBA8, buf)
	dat_img.blit_rect(im, Rect2i(0, 0, CHK, CHK), Vector2i(x0, y0))


## Objekte eines Blocks in ein Bild mit 4 Texeln je Kachel mischen (mit Überhang aus Nachbarblöcken).
func _bake(c: int) -> void:
	var x0: int = (c % CXN) * CHK
	var y0: int = (c / CXN) * CHK
	var img: Image = null
	var ft: PackedByteArray = world.feat
	var reg: PackedByteArray = world.region
	var clip: Rect2i = Rect2i(0, 0, CPX, CPX)
	for y: int in range(maxi(0, y0 - 1), mini(World.H, y0 + CHK + 16)):
		for x: int in range(maxi(0, x0 - 8), mini(World.W, x0 + CHK + 8)):
			var i: int = y * World.W + x
			var f: int = ft[i]
			if f == 0 or f == GuData.F_ROAD:
				continue
			var e: Array = Sprites.hd_feat(f, x, y, reg[i])
			var im: Image = e[0]
			var foot: Vector2i = e[1]
			var jx: int = int(GuData.hash2(x, y, 41) * 3.0) - 1
			var dst: Rect2i = Rect2i((x - x0) * DS + DS / 2 - foot.x + jx, (y + 1 - y0) * DS - foot.y, im.get_width(), im.get_height())
			var inter: Rect2i = dst.intersection(clip)
			if inter.size.x <= 0 or inter.size.y <= 0:
				continue
			if img == null:
				img = Image.create_empty(CPX, CPX, false, Image.FORMAT_RGBA8)
			img.blend_rect(im, Rect2i(inter.position - dst.position, inter.size), inter.position)
	if img == null:
		ftex[c] = null
		return
	img.generate_mipmaps()
	if ftex[c] != null and ftex[c].get_size() == Vector2(CPX, CPX):
		ftex[c].update(img)
	else:
		ftex[c] = ImageTexture.create_from_image(img)


class FeatLayer:
	extends Node2D
	var d: Detail

	func _draw() -> void:
		var v: Rect2 = d.view
		var cx0: int = clampi(int(floorf(v.position.x / CHK)) - 1, 0, CXN - 1)
		var cy0: int = clampi(int(floorf(v.position.y / CHK)) - 1, 0, CXN - 1)
		var cx1: int = clampi(int(floorf(v.end.x / CHK)) + 1, 0, CXN - 1)
		var cy1: int = clampi(int(floorf(v.end.y / CHK)) + 1, 0, CXN - 1)
		for cy: int in range(cy0, cy1 + 1):
			for cx: int in range(cx0, cx1 + 1):
				var t: ImageTexture = d.ftex[cy * CXN + cx]
				if t != null:
					draw_texture_rect(t, Rect2(cx * CHK, cy * CHK, CHK, CHK), false)


const SHADER: String = """
shader_type canvas_item;

uniform sampler2D dat : filter_nearest, repeat_disable;
// Rauschtexturen statt Hash-Rechnung (billiger auf Handy-GPUs): nz weich (bilinear), wn je Texel
uniform sampler2D nz : filter_linear, repeat_enable;
uniform sampler2D wn : filter_nearest, repeat_enable;
uniform float ds = 4.0;
uniform float amt = 1.0;

varying vec2 wp;

const vec3 GR[15] = {
	vec3(150.0, 156.0, 72.0), vec3(140.0, 148.0, 66.0), vec3(160.0, 164.0, 80.0),
	vec3(70.0, 126.0, 44.0), vec3(64.0, 118.0, 41.0), vec3(78.0, 134.0, 47.0),
	vec3(80.0, 136.0, 48.0), vec3(74.0, 128.0, 44.0), vec3(88.0, 144.0, 51.0),
	vec3(87.0, 142.0, 50.0), vec3(80.0, 134.0, 47.0), vec3(94.0, 150.0, 55.0),
	vec3(76.0, 132.0, 46.0), vec3(70.0, 124.0, 43.0), vec3(84.0, 140.0, 49.0)
};
const float BAY[16] = { 0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0 };

float ch(vec4 v, int s) {
	int c = s & 3;
	return c == 0 ? v.r : (c == 1 ? v.g : (c == 2 ? v.b : v.a));
}

// weißes Rauschen je Texel (Periode 256)
float h2(ivec2 p, int s) {
	ivec2 q = (p + ivec2(s * 37, s * 61)) & ivec2(255);
	return ch(texelFetch(wn, q, 0), s);
}

// weiches Wertrauschen, Gitterweite 1 (Periode 64)
float vn(vec2 p, int s) {
	vec2 o = vec2(float(s) * 17.31, float(s) * 9.73);
	return ch(texture(nz, (p + o) / 64.0), s);
}

vec4 D(ivec2 t) {
	return texelFetch(dat, clamp(t, ivec2(0), ivec2(255)), 0);
}

vec3 c8(vec3 c) {
	return c / 255.0;
}

// fünf Stufen dunkel..hell, v in 0..4 (bereits gerastert)
vec3 pick5(vec3 a, vec3 b, vec3 c, vec3 d, vec3 e, float v) {
	if (v < 0.5) return a;
	if (v < 1.5) return b;
	if (v < 2.5) return c;
	if (v < 3.5) return d;
	return e;
}

// Stufe runden, nur nahe der Stufengrenze gerastert (saubere Pixel-Flächen statt Rauschen)
float lv(float v, float dith, float hi) {
	return clamp(floor(v + 0.5 + dith), 0.0, hi);
}

// Licht aus dem unverwackelten Höhenfeld (ruhigere Flächen für Fels und Schnee)
float relief(vec2 p) {
	vec2 q = p - 0.5;
	ivec2 b = ivec2(floor(q));
	vec2 f = q - floor(q);
	float a = D(b).g;
	float bx = D(b + ivec2(1, 0)).g;
	float cy = D(b + ivec2(0, 1)).g;
	float d = D(b + ivec2(1, 1)).g;
	float gx = mix(bx - a, d - cy, f.y);
	float gy = mix(cy - a, d - bx, f.x);
	return clamp((gx + gy) * 3.2, -1.0, 1.0);
}

int tt(vec2 p) {
	return int(D(ivec2(floor(p))).r * 255.0 + 0.5);
}

void vertex() {
	wp = VERTEX;
}

void fragment() {
	vec2 tx = floor(wp * ds);
	ivec2 ti = ivec2(tx);
	vec2 pc = (tx + 0.5) / ds;
	float fw = fwidth(wp.x) * ds;
	// Kleinteiliges (Halme, Körner, Funkeln) im Fernblick ausblenden, sonst flimmert es
	float spk = clamp(1.7 - fw * 1.1, 0.0, 1.0);
	// Raster nur nahe den Stufengrenzen; im Nahblick (große Texel) fast keins, sonst wirkt es wie Rauschen
	float dith = ((BAY[(ti.y & 3) * 4 + (ti.x & 3)] + 0.5) / 16.0 - 0.5) * mix(0.12, 0.4, clamp(fw * 1.4, 0.0, 1.0));

	// verwackelte Abtastung: organische Grenzen zwischen den Kacheln
	vec2 jt = vec2(vn(pc * 0.85, 1), vn(pc * 0.85 + 17.3, 2)) - 0.5;
	vec2 pj = pc + jt * 0.8;
	vec2 q = pj - 0.5;
	ivec2 b = ivec2(floor(q));
	vec2 f = q - floor(q);
	vec4 d00 = D(b);
	vec4 d10 = D(b + ivec2(1, 0));
	vec4 d01 = D(b + ivec2(0, 1));
	vec4 d11 = D(b + ivec2(1, 1));
	float hg = mix(mix(d00.g, d10.g, f.x), mix(d01.g, d11.g, f.x), f.y);
	float gx = mix(d10.g - d00.g, d11.g - d01.g, f.y);
	float gy = mix(d01.g - d00.g, d11.g - d10.g, f.x);
	float wd = mix(mix(d00.b, d10.b, f.x), mix(d01.b, d11.b, f.x), f.y) * 63.75;
	vec4 dn = f.x < 0.5 ? (f.y < 0.5 ? d00 : d01) : (f.y < 0.5 ? d10 : d11);
	int t = int(dn.r * 255.0 + 0.5);
	int aa = int(dn.a * 255.0 + 0.5);
	int reg = clamp(aa >> 4, 0, 4);
	bool road = (aa & 1) == 1;
	// Licht von links oben: Hang, der nach links oben schaut, ist hell
	float L = clamp((gx + gy) * 3.2, -1.0, 1.0);
	float T = TIME;
	vec3 col;

	if (wd > 0.5) {
		// ---------- Wasser ----------
		float dep = wd + (vn(pc * 0.3, 5) - 0.5) * 3.0 + dith * 1.5;
		if (dep < 1.4) col = c8(vec3(98.0, 204.0, 236.0));
		else if (dep < 3.2) col = c8(vec3(76.0, 184.0, 234.0));
		else if (dep < 7.0) col = c8(vec3(62.0, 156.0, 226.0));
		else if (dep < 12.0) col = c8(vec3(52.0, 128.0, 214.0));
		else if (dep < 19.0) col = c8(vec3(46.0, 112.0, 202.0));
		else col = c8(vec3(40.0, 99.0, 190.0));
		// dunkle Strömungsflecken im tiefen Wasser
		if (wd > 9.0 && vn(pc * 0.22 + vec2(T * 0.03, 0.0), 6) > 0.68) col *= 0.93;
		// Wellenstriche, die langsam treiben und aufblinken
		vec2 wq = vec2(tx.x + floor(T * 2.0), tx.y);
		ivec2 cell = ivec2(floor(wq / vec2(9.0, 5.0)));
		float hc = h2(cell, 7);
		ivec2 inc = ivec2(wq) - cell * ivec2(9, 5);
		int sx = int(hc * 5.0);
		int sy = int(fract(hc * 7.0) * 4.0);
		float blink = sin(T * 1.7 + hc * 40.0);
		if (wd > 1.6 && hc < 0.5 && inc.y == sy && inc.x >= sx && inc.x < sx + 3 && blink > 0.2) {
			col = mix(col, c8(vec3(150.0, 216.0, 250.0)), 0.75 * spk);
		}
		// Brandung: Linien laufen auf den Strand zu
		float ph = fract(wd * 0.8 - T * 0.22 + vn(pc * 0.45, 8) * 0.7);
		if (wd < 3.0 && ph < 0.09) {
			float fa = (1.0 - (wd - 0.5) / 2.5) * 0.85;
			col = mix(col, c8(vec3(214.0, 242.0, 252.0)), fa);
		}
		// Gischtsaum direkt am Ufer
		float rim = 0.5 + 0.2 + vn(pc * 1.3 + vec2(T * 0.15, 0.0), 9) * 0.22;
		if (wd < rim) col = c8(vec3(236.0, 250.0, 255.0));
		else if (wd < rim + 0.13) col = mix(col, c8(vec3(190.0, 236.0, 250.0)), 0.7);
		// Sonnenglitzern
		if (wd > 4.0 && h2(ti + ivec2(int(floor(T * 3.0)) * 7, 0), 10) > 1.0 - 0.0035 * spk) col = vec3(1.0);
	} else {
		if (t <= 1) t = 2;
		float n1 = vn(pc * 0.2, 3);
		float hb = h2(ti, 11);
		float ha = h2(ti - ivec2(0, 1), 11);
		if (road && t != 9 && t != 12) {
			// ---------- Straße: festgetretene Erde mit Kieseln ----------
			float v = 2.0 + (n1 - 0.5) * 0.8 + L * 0.8;
			if (hb < 0.12 * spk) v -= 1.0;
			else if (hb > 1.0 - 0.06 * spk) v += 1.0;
			col = c8(pick5(vec3(128.0, 98.0, 62.0), vec3(152.0, 120.0, 80.0), vec3(176.0, 142.0, 98.0), vec3(196.0, 166.0, 118.0), vec3(214.0, 190.0, 142.0), lv(v, dith, 4.0)));
		} else if (t == 3 || t == 4) {
			// ---------- Grasland / Steppe ----------
			int r3 = (t == 4 ? 0 : reg) * 3;
			vec3 cb = GR[r3];
			vec3 cd = GR[r3 + 1];
			vec3 cl = GR[r3 + 2];
			float v = 2.0 + (n1 - 0.5) * 2.4 + L * 1.6 + (vn(pc * 0.9, 4) - 0.5) * 0.9;
			float bl = (t == 4 ? 0.05 : 0.075) * spk;
			if (hb < bl) v += 1.3;
			else if (ha < bl) v -= 1.3;
			// Grasnarbe: zum Strand/Wasser hin ein dunkler Rand (wirkt erhaben)
			int tb = tt(pj + vec2(0.0, 0.3));
			if (tb <= 2 || tb == 11) v -= 1.6;
			col = c8(pick5(cd * 0.8, cd, cb, cl, cl * 1.1 + vec3(6.0, 8.0, 2.0), lv(v, dith, 4.0)));
			// Blumen auf Wiesen
			if (t == 3 && h2(ti, 12) < 0.004 * spk && vn(pc * 0.25, 13) > 0.55) {
				float fc = h2(ti, 14);
				col = fc < 0.35 ? vec3(0.97, 0.95, 0.88) : (fc < 0.65 ? vec3(0.98, 0.86, 0.3) : (fc < 0.85 ? vec3(0.92, 0.5, 0.78) : vec3(0.6, 0.72, 0.98)));
			}
			// trockene Halme in der Steppe
			if (t == 4 && h2(ti, 15) < 0.02 * spk) col = c8(vec3(196.0, 186.0, 104.0));
		} else if (t == 2) {
			// ---------- Strand ----------
			float v = 2.0 + (vn(pc * 0.5, 16) - 0.5) * 1.2 + L * 1.0;
			if (hb < 0.1 * spk) v -= 1.0;
			else if (hb > 1.0 - 0.05 * spk) v += 1.0;
			if (wd > 0.22) v -= 1.6;  // nasser Sand am Wasser
			col = c8(pick5(vec3(190.0, 180.0, 120.0), vec3(210.0, 202.0, 140.0), vec3(226.0, 220.0, 158.0), vec3(236.0, 232.0, 176.0), vec3(246.0, 244.0, 204.0), lv(v, dith, 4.0)));
			if (h2(ti, 17) < 0.0025 * spk) col = c8(vec3(240.0, 200.0, 190.0));  // Muschel
		} else if (t == 11) {
			// ---------- Wüste mit Dünenrippeln ----------
			float rv = sin(pc.x * 1.6 + pc.y * 4.1 + vn(pc * 0.33, 18) * 7.0);
			float v = 2.0 + L * 1.4 + (n1 - 0.5) * 0.8;
			if (rv > 0.8) v += 1.0;
			else if (rv < -0.86) v -= 1.0;
			if (hb < 0.05 * spk) v -= 0.8;
			col = c8(pick5(vec3(186.0, 154.0, 86.0), vec3(206.0, 178.0, 102.0), vec3(224.0, 198.0, 118.0), vec3(236.0, 214.0, 140.0), vec3(246.0, 230.0, 166.0), lv(v, dith, 4.0)));
		} else if (t == 5) {
			// ---------- Erde ----------
			float v = 2.0 + (n1 - 0.5) * 1.2 + L * 1.2;
			if (hb < 0.14 * spk) v -= 1.0;
			else if (hb > 1.0 - 0.08 * spk) v += 1.0;
			col = c8(pick5(vec3(92.0, 68.0, 42.0), vec3(114.0, 86.0, 52.0), vec3(132.0, 100.0, 62.0), vec3(150.0, 116.0, 74.0), vec3(170.0, 136.0, 90.0), lv(v, dith, 4.0)));
		} else if (t == 6) {
			// ---------- Hügel: Fels mit Grasflecken ----------
			L = relief(pc);
			float rk = vn(pc * 0.6, 19);
			float v = 2.0 + L * 2.2 + (rk - 0.5) * 1.6;
			float cr = abs(vn(pc * 1.1, 20) - 0.5);
			if (cr < 0.03) v -= 1.0;
			if (hb < 0.04 * spk) v -= 1.0;
			int tb = tt(pj + vec2(0.0, 0.4));
			if (tb != 6 && tb != 7) v -= 1.2;
			else if (tt(pj - vec2(0.0, 0.4)) < 6) v += 0.8;
			bool gp = vn(pc * 0.55, 21) > 0.56 && L > -0.35;
			if (gp) {
				vec3 g = GR[reg * 3] * 0.82;
				col = c8(pick5(g * 0.7, g * 0.85, g, g * 1.12, g * 1.25, lv(v, dith, 4.0)));
			} else {
				col = c8(pick5(vec3(58.0, 62.0, 58.0), vec3(78.0, 84.0, 76.0), vec3(100.0, 106.0, 94.0), vec3(126.0, 130.0, 114.0), vec3(152.0, 154.0, 136.0), lv(v, dith, 4.0)));
			}
		} else if (t == 7) {
			// ---------- Gebirge: Fels in Facetten, Schneekappen ----------
			L = relief(pc);
			// Facetten: grobes Rauschen gestuft, dazu feine Risse
			float rk = vn(pc * 0.75, 22);
			float v = 2.0 + L * 2.6 + (rk - 0.5) * 2.0 + (hg - 0.85) * 4.0;
			float cr = abs(vn(pc * 1.25, 23) - 0.5);
			if (cr < 0.035) v -= 1.2;
			else if (cr < 0.07 && L > 0.0) v += 0.6;
			// Felswand nach unten, heller Grat oben
			int tb = tt(pj + vec2(0.0, 0.45));
			if (tb != 7) v -= 1.6;
			else if (tt(pj - vec2(0.0, 0.45)) != 7) v += 1.0;
			float snow = hg + (vn(pc * 0.8, 24) - 0.5) * 0.05;
			if (snow > 0.935 && tb == 7) {
				float sv = v - 0.2 + (vn(pc * 0.9, 34) - 0.5) * 1.4;
				col = c8(pick5(vec3(132.0, 150.0, 188.0), vec3(170.0, 188.0, 218.0), vec3(204.0, 216.0, 236.0), vec3(232.0, 240.0, 248.0), vec3(252.0, 253.0, 255.0), lv(sv, dith, 4.0)));
			} else {
				col = c8(pick5(vec3(46.0, 46.0, 54.0), vec3(70.0, 70.0, 78.0), vec3(98.0, 98.0, 102.0), vec3(130.0, 128.0, 126.0), vec3(166.0, 164.0, 158.0), lv(v, dith, 4.0)));
			}
		} else if (t == 8) {
			// ---------- Schnee ----------
			float v = 2.6 + L * 1.6 + (n1 - 0.5) * 1.0;
			col = c8(pick5(vec3(160.0, 178.0, 208.0), vec3(196.0, 210.0, 230.0), vec3(222.0, 232.0, 242.0), vec3(236.0, 242.0, 248.0), vec3(250.0, 252.0, 255.0), lv(v, dith, 4.0)));
			if (h2(ti + ivec2(int(T * 2.0) * 3, 0), 25) > 1.0 - 0.004 * spk) col = vec3(1.0);
		} else if (t == 13) {
			// ---------- Eis (gefrorenes Wasser) ----------
			float v = 2.0 + (vn(pc * 0.5, 26) - 0.5) * 1.6;
			float cr = abs(vn(pc * 0.7, 27) - 0.5);
			col = c8(pick5(vec3(130.0, 186.0, 220.0), vec3(156.0, 206.0, 234.0), vec3(184.0, 224.0, 244.0), vec3(210.0, 238.0, 250.0), vec3(240.0, 250.0, 255.0), lv(v, dith, 4.0)));
			if (cr < 0.025) col = c8(vec3(236.0, 248.0, 255.0));
		} else if (t == 9) {
			// ---------- Regionswand: schimmernde Himmelsschranke ----------
			float band = sin((pc.x + pc.y * 1.6) * 1.3 - T * 1.8 + vn(pc * 0.4 + vec2(0.0, T * 0.2), 28) * 5.0);
			float v = 2.0 + band * 1.3 + (vn(pc * 1.5 + vec2(T * 0.4, 0.0), 29) - 0.5) * 1.0;
			col = c8(pick5(vec3(120.0, 100.0, 196.0), vec3(150.0, 132.0, 222.0), vec3(178.0, 162.0, 236.0), vec3(210.0, 198.0, 248.0), vec3(240.0, 236.0, 255.0), lv(v, dith, 4.0)));
			float tw = h2(ti, 30);
			if (tw > 0.985 && sin(T * 4.0 + tw * 300.0) > 0.6) col = vec3(1.0);
		} else if (t == 10) {
			// ---------- Asche mit Glut ----------
			float v = 2.0 + (n1 - 0.5) * 1.4 + L * 1.0;
			if (hb < 0.12 * spk) v -= 1.0;
			col = c8(pick5(vec3(40.0, 36.0, 36.0), vec3(52.0, 47.0, 46.0), vec3(64.0, 58.0, 56.0), vec3(80.0, 74.0, 70.0), vec3(100.0, 94.0, 88.0), lv(v, dith, 4.0)));
			float eh = h2(ti, 31);
			if (eh < 0.012 && sin(T * 3.0 + eh * 900.0) > 0.0) col = c8(vec3(255.0, 120.0, 40.0));
		} else if (t == 12) {
			// ---------- Lava: fließende Glut ----------
			float n = vn(pc * 0.55 + vec2(T * 0.12, T * 0.05), 32) * 0.65 + vn(pc * 1.6 - vec2(T * 0.22, 0.0), 33) * 0.35;
			float v = (n - 0.3) * 8.0;
			col = c8(pick5(vec3(110.0, 30.0, 20.0), vec3(196.0, 56.0, 24.0), vec3(250.0, 128.0, 28.0), vec3(255.0, 186.0, 56.0), vec3(255.0, 238.0, 150.0), lv(v, dith, 4.0)));
		} else {
			col = c8(vec3(132.0, 100.0, 62.0));
		}
	}
	COLOR = vec4(col, amt);
}
"""
