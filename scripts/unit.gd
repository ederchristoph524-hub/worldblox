class_name Unit
extends RefCounted
## Ein Wesen auf der Karte: Mensch (k == "p") oder Tier (k == "a").

var id: int = 0
var k: String = "p"
var sp: String = ""          # Tierart
var race: int = 0
var x: float = 0.0
var y: float = 0.0
var tx: float = 0.0
var ty: float = 0.0
var face: int = 1
var birth: float = 0.0
var life: float = 60.0
var vil: int = -1
var clan: int = -1
var rank: int = 0
var stage: int = 0
var prog: float = 0.0
var apt: String = ""
var path: int = -1
var align: int = 0
var gus: PackedStringArray = PackedStringArray()
var sur: String = ""
var given: String = ""
var kills: int = 0
var job: String = ""
var st: String = "idle"
var wt: float = 0.0
var wtype: String = ""
var wi: int = -1
var think: float = 0.0
var tgt: Unit = null
var aggro: Unit = null
var cd: float = 0.0
var hp: float = 1.0
var mhp: float = 1.0
var atk: float = 1.0
var rng: float = 2.2
var aoe: float = 0.0
var anim: float = 0.0
var awk: bool = false
var luck: float = 0.0
var sick: float = 0.0
var rogue: bool = false
var flash: float = 0.0
var next_trib: float = 0.0
var title: String = ""
var stuck: float = 0.0
var moving: bool = false
var militia: bool = false
var col_clan: int = -1
var col_to: Vector2 = Vector2(-1, -1)
var swim: bool = false
var fly: bool = false
var speed: float = 3.4
var phys_x: bool = false
var hungry: float = 0.0
var tide: bool = false
var tide_v: int = -1
var dreason: String = ""
var caught: bool = false
var stroke_mark: int = -1
# Gu-Welt-Inhalte
var gname: String = ""        # Wilde Gu: Name der Gu-Art bzw. Id des Unsterblichen Gu
var igu: PackedStringArray = PackedStringArray()   # besessene Unsterbliche Gu (Lore.IGU-Ids)
var fig: String = ""          # Schlüssel einzigartiger Figuren und Ehrwürdiger
var ow: bool = false          # Fremdweltdämon
var hx: float = -1.0          # Revier (Ödbestien) bzw. Bindung (Himmelsfragment)
var hy: float = -1.0
var notrib: bool = false      # Himmelsfragment einverleibt: keine Drangsale mehr
# Gottkräfte (v3)
var bless: int = 0            # 1 = gesegnet, -1 = verflucht
var prot: float = -1.0        # Himmelsschutz bis (Simulationszeit): keine Drangsal, kein Himmelswille
var undead: bool = false      # wandelnde Leiche (Leichen-Gu-Seuche)
var boat: bool = false        # Siedler im Boot: darf tiefes Wasser befahren
var ch: int = 0               # Cheat-Merker (Cheats.CH_*: unsterblich, unverwundbar, ewiges Glück)
# abgeleitet, nicht gespeichert
var beh: int = -1             # Tierverhalten GuData.B_*
var aqua: bool = false
var ldr: Unit = null          # Rudelführer
var km_cd: float = 0.0
var heal_cd: float = 0.0
var pb: float = 1.0           # Kultivierungs-Faktor durch einen Ort
var pb_t: float = -1.0
var lure_t: float = -1.0
var lx: float = 0.0
var ly: float = 0.0
var duel_t: float = -1.0
var ig_atk: float = 1.0
var ig_hp: float = 1.0
var ig_sp: float = 1.0
var ig_cult: float = 1.0
var ig_rng: float = 1.0
var igf: int = 0
var held: bool = false        # von der Göttlichen Hand gehalten
var poss: bool = false        # vom Spieler besessen (Seelenbesitz)
var air: float = 0.0          # fliegt durch die Luft (Wirbel, Druckwelle)
var kvx: float = 0.0
var kvy: float = 0.0
var frz: float = -1.0         # eingefroren bis (Frostodem)
var zin: float = -1.0         # mit der Leichen-Seuche angesteckt: erhebt sich ab dieser Zeit als Leiche
var fxm: bool = false         # einer der seltenen Zustände oben ist (vielleicht) aktiv – nur dann prüft Sim._special


func pname() -> String:
	if k == "p":
		return given if sur == "" else sur + " " + given
	if gname != "":
		if sp == "wildimm":
			return Lore.igu_name(gname)
		return "Wilder " + gname
	return str(GuData.SPEC[sp]["n"])


func has_col_target() -> bool:
	return col_to.x >= 0.0


func to_dict() -> Dictionary:
	return {"id": id, "k": k, "sp": sp, "race": race, "x": x, "y": y, "birth": birth, "life": life, "vil": vil, "clan": clan,
		"rank": rank, "stage": stage, "prog": prog, "apt": apt, "path": path, "align": align, "gus": Array(gus), "sur": sur, "given": given,
		"kills": kills, "job": job, "hp": hp, "mhp": mhp, "atk": atk, "rng": rng, "aoe": aoe, "awk": awk, "luck": luck, "rogue": rogue,
		"next_trib": next_trib, "title": title, "militia": militia, "col_clan": col_clan, "swim": swim, "fly": fly, "speed": speed,
		"phys_x": phys_x, "hungry": hungry, "tide": tide, "tide_v": tide_v,
		"gname": gname, "igu": Array(igu), "fig": fig, "ow": ow, "hx": hx, "hy": hy, "notrib": notrib,
		"bless": bless, "prot": prot, "undead": undead, "boat": boat, "ch": ch}


static func from_dict(d: Dictionary) -> Unit:
	var u: Unit = Unit.new()
	for key: String in d.keys():
		if key == "gus" or key == "igu":
			u.set(key, PackedStringArray(d[key]))
		elif key in ["id", "race", "vil", "clan", "rank", "stage", "path", "align", "kills", "col_clan", "tide_v", "bless", "ch"]:
			u.set(key, int(d[key]))
		else:
			u.set(key, d[key])
	u.tx = u.x
	u.ty = u.y
	u.fxm = u.bless != 0 or u.boat or u.prot > 0.0
	u.anim = randf() * 10.0
	u.think = randf()
	return u
