class_name Boot
extends Node
## Startknoten: zeigt das Spiel in einem SubViewport. Auf Touch-Geräten im Hochformat wird das ganze Bild
## um 90° gedreht – das Spiel läuft immer im Querformat wie andere Handy-Spiele, auch mit Ausrichtungssperre.
## Der SubViewport rendert in voller Pixelauflösung (`size`) mit logischer Größe `size_2d_override`.

var cont: SubViewportContainer
var sv: SubViewport
var main: GuMain
var force_land: bool = true   ## Handy hochkant → Bild drehen (Einstellung „Force landscape“)
var forced: bool = false      ## gerade gedreht?
var _busy: bool = false


func _ready() -> void:
	var win: Window = get_window()
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	cont = SubViewportContainer.new()
	cont.stretch = false
	cont.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(cont)
	sv = SubViewport.new()
	sv.handle_input_locally = true
	sv.size_2d_override_stretch = true
	sv.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	sv.audio_listener_enable_2d = true
	cont.add_child(sv)
	var cf: ConfigFile = ConfigFile.new()
	if not ("--fresh" in OS.get_cmdline_user_args()) and cf.load("user://settings.cfg") == OK:
		force_land = bool(cf.get_value("ui", "force_landscape", true))
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as GuMain
	main.boot = self
	_apply_sizes()
	sv.add_child(main)
	win.size_changed.connect(_on_win)
	if "--rottest" in OS.get_cmdline_user_args():
		dev_rottest()


func _on_win() -> void:
	_apply_sizes()
	if main != null and main.is_inside_tree():
		main._on_resize()


## Größen von Container und SubViewport aus der Fenstergröße; dreht im Hochformat auf Touch-Geräten.
func relayout() -> void:
	_apply_sizes()


func _apply_sizes() -> void:
	if _busy:
		return
	_busy = true
	var phys: Vector2 = Vector2(get_window().size)
	phys = Vector2(maxf(phys.x, 64.0), maxf(phys.y, 64.0))
	forced = force_land and main != null and main.is_touch() and phys.y > phys.x * 1.1
	var eff: Vector2 = Vector2(phys.y, phys.x) if forced else phys
	var land: bool = eff.x > eff.y * 1.1
	var base: Vector2 = main.ui_base(land) if main != null else Vector2(400, 880)
	var sc: float = minf(eff.x / base.x, eff.y / base.y)
	var logical: Vector2i = Vector2i((eff / sc).round())
	if sv.size != Vector2i(eff):
		sv.size = Vector2i(eff)
	if sv.size_2d_override != logical:
		sv.size_2d_override = logical
	cont.size = eff
	cont.rotation = PI / 2.0 if forced else 0.0
	cont.position = Vector2(phys.x, 0.0) if forced else Vector2.ZERO
	_busy = false


## Entwickler: -- --rottest – prüft, ob Eingaben im gedrehten Bild an der richtigen Stelle ankommen (mit --touch).
func dev_rottest() -> void:
	while main.loading or main.presim_on:
		await get_tree().process_frame
	await get_tree().process_frame
	var phys: Vector2 = Vector2(get_window().size)
	var logical: Vector2 = Vector2(sv.size_2d_override)
	var sc: float = float(sv.size.x) / logical.x
	for lp: Vector2 in [Vector2(100, 50), Vector2(logical.x - 30, logical.y - 20), Vector2(logical.x * 0.5, logical.y * 0.4)]:
		var local: Vector2 = lp * sc
		var g: Vector2 = Vector2(phys.x - local.y, local.x) if forced else local
		var ev: InputEventMouseMotion = InputEventMouseMotion.new()
		ev.position = g
		ev.global_position = g
		Input.parse_input_event(ev)
		await get_tree().process_frame
		await get_tree().process_frame
		print("ROT forced=", forced, " want ", lp, " got ", main.hover)
	await RenderingServer.frame_post_draw
	get_window().get_texture().get_image().save_png("/tmp/claude-0/rot_%s.png" % ("p" if forced else "l"))
	print("ROTTEST DONE")
	get_tree().quit()
