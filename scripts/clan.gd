class_name Clan
extends RefCounted
## Clan, Stamm oder Sekte mit Fehden und Bündnissen.

var id: int = 0
var name: String = ""
var glyph: String = ""
var kind: String = "Clan"
var col: Color = Color.WHITE
var war: Dictionary = {}    # Clan-ID -> true
var ally: Dictionary = {}
var born: int = 1
var alive: bool = true
var region: int = 0
var wt: int = -1
var kills: int = 0
var war_start: float = 0.0
var calm: float = -1.0


func to_dict() -> Dictionary:
	return {"id": id, "name": name, "glyph": glyph, "kind": kind, "col": col.to_html(false), "war": war.keys(), "ally": ally.keys(),
		"born": born, "alive": alive, "region": region, "kills": kills, "war_start": war_start, "calm": calm}


static func from_dict(d: Dictionary) -> Clan:
	var c: Clan = Clan.new()
	c.id = int(d["id"])
	c.name = d["name"]
	c.glyph = d["glyph"]
	c.kind = d["kind"]
	c.col = Color(str(d["col"]))
	for e: Variant in d["war"]:
		c.war[int(e)] = true
	for e: Variant in d["ally"]:
		c.ally[int(e)] = true
	c.born = int(d["born"])
	c.alive = d["alive"]
	c.region = int(d["region"])
	c.kills = int(d["kills"])
	c.war_start = d["war_start"]
	c.calm = d["calm"]
	return c
