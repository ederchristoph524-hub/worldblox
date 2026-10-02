class_name Village
extends RefCounted
## Ein Dorf eines Clans mit Vorräten und Gebäuden.

var id: int = 0
var clan: int = 0
var name: String = ""
var x: int = 0
var y: int = 0
var cx: float = 0.0
var cy: float = 0.0
var race: int = 0
var food: float = 10.0
var wood: float = 8.0
var stones: float = 3.0
var houses: int = 0
var farms: int = 0
var forge: bool = false
var towers: int = 0
var b: PackedInt32Array = PackedInt32Array()
var pop: int = 1
var adults: int = 1
var gm: int = 0
var cap: int = 4
var alive: bool = true
var born: int = 1
var spring: bool = false
var reg: int = 0
var lvl: int = 0
var lead: Unit = null
var bfail: float = -1.0  ## Bauplatz nicht gefunden: bis zu dieser Simulationszeit nicht erneut suchen (nicht gespeichert)
var loy: float = 80.0      # Loyalität zum Clan (0..100); niedrig = Aufstand
var capt: float = -999.0   # Zeitpunkt der letzten Eroberung
var road: bool = false     # Straße zur Hauptstadt gebaut


func to_dict() -> Dictionary:
	return {"id": id, "clan": clan, "name": name, "x": x, "y": y, "cx": cx, "cy": cy, "race": race, "food": food, "wood": wood, "stones": stones,
		"b": Array(b), "alive": alive, "born": born, "spring": spring, "reg": reg, "lvl": lvl, "loy": loy, "capt": capt, "road": road}


static func from_dict(d: Dictionary) -> Village:
	var v: Village = Village.new()
	for key: String in d.keys():
		if key == "b":
			v.b = PackedInt32Array(d[key])
		elif key in ["id", "clan", "x", "y", "race", "born", "reg", "lvl"]:
			v.set(key, int(d[key]))
		else:
			v.set(key, d[key])
	return v
