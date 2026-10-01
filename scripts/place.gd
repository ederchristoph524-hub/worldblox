class_name Place
extends RefCounted
## Besonderer Ort auf der Karte (Gesegnetes Land, Grottenhimmel, Himmelshof, Traumreich, Erbe …), siehe Lore.PLACE.

var id: int = 0
var type: String = "blessed"
var name: String = ""
var x: float = 0.0
var y: float = 0.0
var owner: int = -1        # Unit-Id des Besitzers (Gesegnetes Land, Grottenhimmel)
var born: float = 0.0      # Simulationszeit der Entstehung
var until: float = -1.0    # Simulationszeit des Verschwindens (-1 = dauerhaft)
var t: float = 0.0         # Monatszähler für wiederkehrende Ereignisse
var used: bool = false
var alive: bool = true


func radius() -> float:
	return float(Lore.PLACE[type].get("r", 16.0))


func lure() -> float:
	return float(Lore.PLACE[type].get("lure", 0.0))


func to_dict() -> Dictionary:
	return {"id": id, "type": type, "name": name, "x": x, "y": y, "owner": owner, "born": born, "until": until, "t": t, "used": used}


static func from_dict(d: Dictionary) -> Place:
	var p: Place = Place.new()
	p.id = int(d.get("id", 0))
	p.type = str(d.get("type", "blessed"))
	if not Lore.PLACE.has(p.type):
		p.type = "blessed"
	p.name = str(d.get("name", ""))
	p.x = float(d.get("x", 0.0))
	p.y = float(d.get("y", 0.0))
	p.owner = int(d.get("owner", -1))
	p.born = float(d.get("born", 0.0))
	p.until = float(d.get("until", -1.0))
	p.t = float(d.get("t", 0.0))
	p.used = bool(d.get("used", false))
	return p
