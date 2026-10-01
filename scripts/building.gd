class_name Building
extends RefCounted
## Gebäude auf der Karte. x/y/w/h ist die Grundfläche in Kacheln.

var id: int = 0
var type: String = "house"
var x: int = 0
var y: int = 0
var w: int = 1
var h: int = 1
var v: int = 0
var hp: float = 50.0


func to_dict() -> Dictionary:
	return {"id": id, "type": type, "x": x, "y": y, "w": w, "h": h, "v": v, "hp": hp}


static func from_dict(d: Dictionary) -> Building:
	var b: Building = Building.new()
	b.id = int(d["id"])
	b.type = d["type"]
	b.x = int(d["x"])
	b.y = int(d["y"])
	b.w = int(d["w"])
	b.h = int(d["h"])
	b.v = int(d["v"])
	b.hp = d["hp"]
	return b
