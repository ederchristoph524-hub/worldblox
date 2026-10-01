class_name Px
extends RefCounted
## Kleiner Pixel-Maler: zeichnet Rechtecke und Kreise in ein Image und erzeugt Texturen.

var img: Image


func _init(w: int, h: int) -> void:
	img = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))


func p(x: int, y: int, w: int, h: int, c: Variant) -> void:
	var col: Color = c if c is Color else Color(str(c))
	var x0: int = maxi(0, x)
	var y0: int = maxi(0, y)
	var x1: int = mini(img.get_width(), x + w)
	var y1: int = mini(img.get_height(), y + h)
	for yy: int in range(y0, y1):
		for xx: int in range(x0, x1):
			if col.a >= 0.999:
				img.set_pixel(xx, yy, col)
			else:
				img.set_pixel(xx, yy, img.get_pixel(xx, yy).blend(col))


func d(cx: int, cy: int, r: int, c: Variant) -> void:
	for yy: int in range(-r, r + 1):
		for xx: int in range(-r, r + 1):
			if xx * xx + yy * yy <= r * r + r * 0.6:
				p(cx + xx, cy + yy, 1, 1, c)


func draw_image(src: Image, x: int, y: int) -> void:
	img.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(x, y))


## Dunkle Kontur um alle sichtbaren Pixel (wie die WorldBox-Icons).
func outline(col: Color = Color("#121814")) -> Px:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var src: Image = img.duplicate()
	for y: int in range(h):
		for x: int in range(w):
			if src.get_pixel(x, y).a > 0.4:
				continue
			var n: bool = false
			if x > 0 and src.get_pixel(x - 1, y).a > 0.4:
				n = true
			elif x < w - 1 and src.get_pixel(x + 1, y).a > 0.4:
				n = true
			elif y > 0 and src.get_pixel(x, y - 1).a > 0.4:
				n = true
			elif y < h - 1 and src.get_pixel(x, y + 1).a > 0.4:
				n = true
			if n:
				img.set_pixel(x, y, col)
	return self


func tex() -> ImageTexture:
	return ImageTexture.create_from_image(img)


## Baut ein Image aus Textzeilen; jedes Zeichen ist ein Schlüssel in der Palette, "." ist leer.
static func grid(rows: Array, pal: Dictionary) -> Image:
	var h: int = rows.size()
	var w: int = 0
	for r: String in rows:
		w = maxi(w, r.length())
	var im: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	for y: int in range(h):
		var row: String = rows[y]
		for x: int in range(row.length()):
			var ch: String = row[x]
			if ch == "." or not pal.has(ch):
				continue
			var c: Variant = pal[ch]
			im.set_pixel(x, y, c if c is Color else Color(str(c)))
	return im


## Tupft zufällig hellere und dunklere Pixel in eine Grundfarbe (Laub-Struktur).
static func speckle(im: Image, sd: int, from: Color, light: Color, dark: Color, prob: float) -> Image:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = sd
	for y: int in range(im.get_height()):
		for x: int in range(im.get_width()):
			var c: Color = im.get_pixel(x, y)
			if c.a > 0.99 and c.is_equal_approx(from):
				var q: float = rng.randf()
				if q < prob:
					im.set_pixel(x, y, light)
				elif q < prob * 2.0:
					im.set_pixel(x, y, dark)
	return im


## Neues Bild, 1 Pixel breiter und höher, mit Schlagschatten nach rechts unten.
static func drop_shadow(im: Image, col: Color) -> Image:
	var w: int = im.get_width()
	var h: int = im.get_height()
	var out: Image = Image.create_empty(w + 1, h + 1, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for y: int in range(h):
		for x: int in range(w):
			if im.get_pixel(x, y).a > 0.5:
				out.set_pixel(x + 1, y + 1, col)
	out.blend_rect(im, Rect2i(0, 0, w, h), Vector2i.ZERO)
	return out
