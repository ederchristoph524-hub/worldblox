class_name Powers
extends RefCounted
## Gottkräfte: alle Werkzeuge der Leiste und was sie auf der Karte bewirken.

const W: int = GuData.W
const H: int = GuData.H

## Reiter -1 ist das Hauptmenü. m: paint = Pinsel, tap = Tippen, pair = zwei Dörfer, spawn = Setzen, act = Sofort-Aktion.
const TABS: PackedStringArray = ["Welt formen", "Noosphäre und Leben", "Kreaturen und Bestien", "Natur und Katastrophen", "Zerstörung und Chaos", "Gu und Schicksal", "Gu-Meister und Unsterbliche"]
## Alle Werkzeuge, nach Reiter und Gruppe sortiert (Gruppenwechsel = Trennstrich in der Leiste).
static var TOOLS: Array = _build_tools()


static func _build_tools() -> Array:
	var L: Array = [
	{"id": "winfo", "tab": -1, "g": 0, "n": "Weltinfo", "m": "act"},
	{"id": "help", "tab": -1, "g": 0, "n": "Lexikon", "m": "act"},
	{"id": "chron", "tab": -1, "g": 0, "n": "Chronik", "m": "act"},
	{"id": "ages", "tab": -1, "g": 0, "n": "Zeitalter", "m": "act"},
	{"id": "laws", "tab": -1, "g": 1, "n": "Weltgesetze", "m": "act", "riv": true},
	{"id": "disp", "tab": -1, "g": 1, "n": "Anzeige", "m": "act", "riv": true},
	{"id": "rank", "tab": -1, "g": 1, "n": "Rangliste", "m": "act", "riv": true},
	{"id": "stats", "tab": -1, "g": 1, "n": "Clan-Statistik", "m": "act", "riv": true},
	{"id": "save", "tab": -1, "g": 2, "n": "Speichern", "m": "act", "riv": true},
	{"id": "load", "tab": -1, "g": 2, "n": "Laden", "m": "act", "riv": true},
	{"id": "new", "tab": -1, "g": 2, "n": "Neue Welt", "m": "act", "riv": true},
	{"id": "hideui", "tab": -1, "g": 2, "n": "Oberfläche ausblenden", "m": "act", "riv": true},
	{"id": "t_deep", "tab": 0, "g": 0, "n": "Tiefes Meer", "d": "Nur Fischschuppenmenschen und Unsterbliche kommen hindurch.", "m": "paint", "tt": GuData.DEEP},
	{"id": "t_shal", "tab": 0, "g": 0, "n": "Seichtes Wasser", "d": "Watbar, aber langsam.", "m": "paint", "tt": GuData.SHAL},
	{"id": "t_sand", "tab": 0, "g": 0, "n": "Strand", "m": "paint", "tt": GuData.SAND},
	{"id": "t_grass", "tab": 0, "g": 0, "n": "Grasland", "d": "Fruchtbares Land – hier gründen Clans Dörfer.", "m": "paint", "tt": GuData.GRASS},
	{"id": "t_step", "tab": 0, "g": 0, "n": "Steppe", "d": "Die Grasmeere der Nordebenen.", "m": "paint", "tt": GuData.STEP},
	{"id": "t_des", "tab": 0, "g": 0, "n": "Wüste", "d": "Der Sand der Westwüste.", "m": "paint", "tt": GuData.DES},
	{"id": "t_soil", "tab": 0, "g": 0, "n": "Erde", "m": "paint", "tt": GuData.SOIL},
	{"id": "t_snow", "tab": 0, "g": 0, "n": "Schnee", "m": "paint", "tt": GuData.SNOW},
	{"id": "t_hill", "tab": 0, "g": 1, "n": "Hügel", "d": "Steinig – hier liegen Urstein-Adern.", "m": "paint", "tt": GuData.HILL},
	{"id": "t_mount", "tab": 0, "g": 1, "n": "Gebirge", "m": "paint", "tt": GuData.MOUNT},
	{"id": "t_up", "tab": 0, "g": 1, "n": "Land heben", "m": "paint"},
	{"id": "t_down", "tab": 0, "g": 1, "n": "Land senken", "m": "paint"},
	{"id": "t_wall", "tab": 0, "g": 1, "n": "Regionswand", "d": "Trennt die fünf Regionen. Nur Gu-Unsterbliche durchqueren sie.", "m": "paint", "tt": GuData.WALL},
	{"id": "f_tree", "tab": 0, "g": 2, "n": "Wald", "m": "paint"},
	{"id": "f_bamb", "tab": 0, "g": 2, "n": "Bambushain", "m": "paint"},
	{"id": "f_ore", "tab": 0, "g": 2, "n": "Urstein-Ader", "d": "Bergleute bauen Ursteine ab – die Nahrung jeder Kultivierung.", "m": "paint"},
	{"id": "f_spring", "tab": 0, "g": 2, "n": "Geisterquelle", "d": "Ein Dorf in der Nähe erhält laufend Ursteine.", "m": "paint"},
	{"id": "f_clear", "tab": 0, "g": 2, "n": "Roden", "m": "paint"},
	{"id": "inspect", "tab": 1, "g": 0, "n": "Dorf inspizieren", "d": "Tippe auf ein Dorf, einen Gu-Meister oder ein Tier.", "m": "tap"},
	{"id": "stats2", "tab": 1, "g": 0, "n": "Clan-Statistik", "m": "act"},
	{"id": "ally", "tab": 1, "g": 0, "n": "Bündnis", "d": "Tippe zwei Dörfer an – ihre Clans verbünden sich.", "m": "pair"},
	{"id": "feud", "tab": 1, "g": 1, "n": "Fehde", "d": "Tippe zwei Dörfer verschiedener Clans an – sie ziehen in den Krieg.", "m": "pair"},
	{"id": "discord", "tab": 1, "g": 1, "n": "Zwietracht", "d": "Ein Dorf sagt sich los und gründet einen eigenen Clan.", "m": "tap"},
	{"id": "peace", "tab": 1, "g": 1, "n": "Frieden", "d": "Tippe ein Dorf an: Sein Clan beendet alle Fehden.", "m": "tap"},
	{"id": "demon", "tab": 1, "g": 1, "n": "Dämonischer Pfad", "d": "Gu-Meister im Pinsel verlassen ihren Clan und morden für Macht.", "m": "paint"},
	{"id": "s_0", "tab": 2, "g": 0, "n": "Menschen", "m": "spawn", "sp": "p0"},
	{"id": "s_1", "tab": 2, "g": 0, "n": "Haarmenschen", "d": "Geborene Gu-Veredler.", "m": "spawn", "sp": "p1"},
	{"id": "s_2", "tab": 2, "g": 0, "n": "Steinmenschen", "d": "Zäh und langlebig, aber langsam.", "m": "spawn", "sp": "p2"},
	{"id": "s_3", "tab": 2, "g": 0, "n": "Fischschuppenmenschen", "d": "Schwimmen durch tiefes Wasser.", "m": "spawn", "sp": "p3"},
	{"id": "s_deer", "tab": 2, "g": 1, "n": "Hirsch", "m": "spawn", "sp": "deer"},
	{"id": "s_boar", "tab": 2, "g": 1, "n": "Eber", "m": "spawn", "sp": "boar"},
	{"id": "s_wolf", "tab": 2, "g": 1, "n": "Wolf", "m": "spawn", "sp": "wolf"},
	{"id": "s_monkey", "tab": 2, "g": 1, "n": "Affe", "m": "spawn", "sp": "monkey"},
	{"id": "s_crane", "tab": 2, "g": 1, "n": "Kranich", "m": "spawn", "sp": "crane"},
	{"id": "w_rain", "tab": 3, "g": 0, "n": "Regen", "d": "Löscht Feuer, lässt Wälder wachsen.", "m": "act", "w": "rain"},
	{"id": "w_snow", "tab": 3, "g": 0, "n": "Schneefall", "m": "act", "w": "snow"},
	{"id": "w_drought", "tab": 3, "g": 0, "n": "Dürre", "d": "Gras verdorrt, Feuer breitet sich schneller aus.", "m": "act", "w": "drought"},
	{"id": "w_sand", "tab": 3, "g": 0, "n": "Sandsturm", "d": "Alle Wanderer kommen nur langsam voran.", "m": "act", "w": "sand"},
	{"id": "bloom", "tab": 3, "g": 1, "n": "Aufblühen", "d": "Asche, Erde und Wüste werden zu blühendem Land.", "m": "paint"},
	{"id": "bolt", "tab": 3, "g": 1, "n": "Blitz", "m": "tap"},
	{"id": "quake", "tab": 3, "g": 1, "n": "Erdkatastrophe", "d": "Die Erde bebt, Gebäude stürzen ein.", "m": "tap"},
	{"id": "trib", "tab": 3, "g": 1, "n": "Himmelsdrangsal", "d": "Ein Gewitter der Drangsal über einem Gebiet.", "m": "tap"},
	{"id": "plague", "tab": 3, "g": 1, "n": "Seuchen-Gu", "d": "Eine Seuche, die von Wesen zu Wesen springt.", "m": "paint"},
	{"id": "fire", "tab": 4, "g": 0, "n": "Feuer", "m": "paint"},
	{"id": "det", "tab": 4, "g": 0, "n": "Gu-Selbstdetonation", "d": "Ein Gu-Meister opfert seine Gu in einer Explosion.", "m": "tap"},
	{"id": "cres", "tab": 4, "g": 0, "n": "Mondsichel-Mordzug", "d": "Ein unsterblicher Mordzug aus Mondlicht reißt das Land auf.", "m": "tap"},
	{"id": "meteor", "tab": 4, "g": 0, "n": "Sternenfall", "m": "tap"},
	{"id": "wrath", "tab": 4, "g": 1, "n": "Unsterbliche Katastrophe", "d": "Vernichtet alles in einem weiten Umkreis.", "m": "tap"},
	{"id": "will", "tab": 4, "g": 1, "n": "Himmelswille", "d": "Schlägt den stärksten Gu-Meister der Welt.", "m": "act"},
	{"id": "smite", "tab": 4, "g": 1, "n": "Auslöschen", "d": "Tötet jedes Wesen im Pinsel.", "m": "paint"},
	{"id": "hope", "tab": 5, "g": 0, "n": "Hoffnungs-Gu", "d": "Erweckt die Öffnung von Sterblichen – sie werden Rang-1-Gu-Meister.", "m": "paint"},
	{"id": "enlight", "tab": 5, "g": 0, "n": "Erleuchtung", "d": "Gu-Meister im Pinsel steigen sofort eine Stufe auf.", "m": "paint"},
	{"id": "luck", "tab": 5, "g": 0, "n": "Großes Glück", "d": "Schnellere Kultivierung und ein sicherer Durchbruch.", "m": "paint"},
	{"id": "life", "tab": 5, "g": 0, "n": "Lebensspannen-Gu", "d": "Schenkt 100 Jahre Lebenszeit.", "m": "paint"},
	{"id": "stones", "tab": 5, "g": 1, "n": "Urstein-Regen", "d": "Tippe auf ein Dorf: 50 Ursteine fallen vom Himmel.", "m": "tap"},

	]
	# --- Reiter 2: Völker, Tiere, Bestienkönige, Ödbestien ---
	for r: int in range(4, GuData.RACE_NAME.size()):
		var hr: int = GuData.RACE_REG[r]
		L.append({"id": "s_%d" % r, "tab": 2, "g": 0, "n": GuData.RACE_PL[r], "d": GuData.RACE_TRAIT[r] + (" Heimat: " + GuData.REGN[hr] + "." if hr >= 0 else ""), "m": "spawn", "sp": "p%d" % r})
	for s: String in ["bk100", "kingwolf", "bk10000", "desolate", "ancient", "remote"]:
		var S: Dictionary = GuData.SPEC[s]
		L.append({"id": "s_" + s, "tab": 2, "g": 2, "n": S["n"], "d": str(S.get("d", "")), "m": "spawn", "sp": s})
	for s2: String in GuData.NAMED_BEASTS:
		var S2: Dictionary = GuData.SPEC[s2]
		var tn: String = GuData.TIER_NAME.get(int(S2.get("tier", 0)), "")
		L.append({"id": "s_" + s2, "tab": 2, "g": 3, "n": S2["n"], "d": (tn + ". " if int(S2.get("tier", 0)) > 0 else "") + str(S2.get("d", "")), "m": "spawn", "sp": s2})
	L.append({"id": "tide", "tab": 2, "g": 4, "n": "Wolfsflut", "d": "Tippe aufs Land: Eine Wolfsflut stürmt das nächste Dorf.", "m": "tap"})
	# --- Reiter 6: Gu-Meister, Unsterbliche, Ehrwürdige, Figuren ---
	for r2: int in range(1, 6):
		L.append({"id": "s_gm%d" % r2, "tab": 6, "g": 0, "n": "Rang-%d-Gu-Meister" % r2, "d": "Erweckter Gu-Meister mit dem Pfad seiner Region und passenden sterblichen Gu. Schließt sich einem nahen Dorf an.", "m": "spawn", "sp": "gm", "r": r2})
	L.append({"id": "s_imm", "tab": 6, "g": 1, "n": "Rang-6-Gu-Unsterblicher", "d": "Ein wandernder Gu-Unsterblicher ohne Clan. Fliegt über Regionswände und setzt Mordzüge ein.", "m": "spawn", "sp": "gi", "r": 6})
	L.append({"id": "s_gi7", "tab": 6, "g": 1, "n": "Rang-7-Gu-Unsterblicher", "d": "Ein mächtiger wandernder Unsterblicher, oft mit einem Unsterblichen Gu.", "m": "spawn", "sp": "gi", "r": 7})
	L.append({"id": "s_gi8", "tab": 6, "g": 1, "n": "Rang-8-Gu-Unsterblicher", "d": "Fast ein Ehrwürdiger – vom Himmelswillen beobachtet.", "m": "spawn", "sp": "gi", "r": 8})
	for vd: Dictionary in Lore.VEN:
		L.append({"id": "s_v_" + str(vd["id"]), "tab": 6, "g": 2, "n": vd["t"], "d": str(vd["d"]) + " %s-Pfad, %s. Nur einer zur selben Zeit." % [GuData.PATH_NAME[int(vd["p"])], "dämonisch" if int(vd["al"]) == 1 else "rechtschaffen"], "m": "spawn", "sp": "ven", "ven": vd["id"]})
	for fd: Dictionary in Lore.FIG:
		L.append({"id": "s_f_" + str(fd["id"]), "tab": 6, "g": 3, "n": (str(fd["sur"]) + " " + str(fd["given"])).strip_edges(), "d": str(fd["d"]) + " (" + GuData.rank_title(int(fd["r"])) + ")", "m": "spawn", "sp": "fig", "fig": fd["id"]})
	# --- Reiter 5: wilde Gu und Unsterbliche Gu ---
	L.append({"id": "s_wildgu", "tab": 5, "g": 2, "n": "Wilde Gu", "d": "Ein Schwarm wilder Gu vom Pfad der Region. Gu-Meister fangen und veredeln sie.", "m": "spawn", "sp": "gu", "path": -1})
	for pth: int in Lore.WILD_PATHS:
		L.append({"id": "s_gu%d" % pth, "tab": 5, "g": 2, "n": "Wilde %s-Gu" % GuData.PATH_NAME[pth], "d": "z. B. %s. Gu-Meister fangen sie und nehmen sie in ihre Sammlung auf." % ", ".join(Lore.mgu(pth).slice(0, 3)), "m": "spawn", "sp": "gu", "path": pth})
	for gid: String in Lore.IGU_BTN:
		var e: Dictionary = Lore.igu(gid)
		L.append({"id": "s_ig_" + gid, "tab": 5, "g": 3, "n": e["n"], "d": str(e["d"]) + " Rang %d. Nur Gu-Unsterbliche können es fangen." % int(e["r"]), "m": "spawn", "sp": "igu", "igu": gid})
	L.append({"id": "s_ig_rand", "tab": 5, "g": 3, "n": "Zufälliges Unsterbliches Gu", "d": "Eines von %d Unsterblichen Gu der Enzyklopädie." % Lore.IGU.size(), "m": "spawn", "sp": "igu", "igu": ""})
	# --- Reiter 0: Orte ---
	for pt: String in Lore.PLACE_ORDER:
		var D: Dictionary = Lore.PLACE[pt]
		L.append({"id": "pl_" + pt, "tab": 0, "g": 3, "n": D["n"], "d": D["d"], "m": "tap", "pl": pt})
	# --- Reiter 1: Organisationen ---
	for o: Dictionary in Lore.ORGS:
		var rg: int = int(o["reg"])
		L.append({"id": "o_" + str(o["id"]), "tab": 1, "g": 2 + int(o["g"]), "n": o["n"], "d": str(o["d"]) + (" Region: " + GuData.REGN[rg] + "." if rg >= 0 else ""), "m": "tap", "org": o["id"], "gl": o["gl"], "col": o["col"]})
	# --- Ereignisse ---
	L.append({"id": "ev_calam", "tab": 3, "g": 2, "n": "Irdische Kalamität", "d": "Prüfung der Unsterblichen: Gu-Unsterbliche in der Nähe müssen sie bestehen. Ohne Unsterbliche bebt nur die Erde.", "m": "tap"})
	L.append({"id": "ev_dream", "tab": 3, "g": 2, "n": "Traumreich erscheint", "d": "Irgendwo in der Welt öffnet sich ein Traumreich.", "m": "act"})
	L.append({"id": "ev_inherit", "tab": 3, "g": 2, "n": "Erbe öffnet sich", "d": "Das verborgene Erbe eines toten Unsterblichen wird zugänglich.", "m": "act"})
	L.append({"id": "ev_ow", "tab": 4, "g": 2, "n": "Fremdweltdämon", "d": "Eine fremde Seele: lernt mehrere Pfade ohne Konflikt, kultiviert rasend schnell – und wird von allen gejagt.", "m": "spawn", "sp": "ow"})
	L.append({"id": "ev_war", "tab": 4, "g": 2, "n": "Rechtschaffen gegen Dämonisch", "d": "Alle rechtschaffenen Clans erklären allen dämonischen den Krieg.", "m": "act"})
	L.append({"id": "ev_frag", "tab": 4, "g": 2, "n": "Himmelsfragment", "d": "Ein Trümmerstück eines zerstörten Himmels stürzt herab und bleibt als Schatz liegen.", "m": "tap"})
	_parity_tools(L)
	for k: int in range(L.size()):
		L[k]["o"] = k
	L.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["tab"]) != int(b["tab"]):
			return int(a["tab"]) < int(b["tab"])
		if int(a["g"]) != int(b["g"]):
			return int(a["g"]) < int(b["g"])
		return int(a["o"]) < int(b["o"]))
	return L


const BRUSH: PackedInt32Array = [1, 2, 4, 7, 11]
const LADDER: PackedInt32Array = [GuData.DEEP, GuData.SHAL, GuData.SAND, GuData.GRASS, GuData.HILL, GuData.MOUNT]

var sim: Sim
var brush_idx: int = 2
var pair_sel: Village = null
var stroke_id: int = 0
## Pinselform: 0 Kreis, 1 Quadrat, 2 Linie (ein Feld breit)
var shape: int = 0
const SHAPE_NAME: PackedStringArray = ["Kreis", "Quadrat", "Linie"]
var _seg_from: Vector2 = Vector2(-1, -1)
## Göttliche Hand: gehaltene Wesen und ihr Abstand zum Finger
var held: Array[Unit] = []
var held_off: Array[Vector2] = []


func _init(s: Sim) -> void:
	sim = s


## Gottkräfte nach dem Vorbild von WorldBox (Gelände-Werkzeuge, Naturgewalten, Mordzug-Leiter, Zivilisation).
static func _parity_tools(L: Array) -> void:
	L.append_array([
		{"id": "layer", "tab": -1, "g": 1, "n": "Kartenebene", "d": "Wechselt die Gebietsanzeige: Clan-Gebiete, Dorf-Gebiete, Regionen.", "m": "act", "riv": true},
		{"id": "plans", "tab": -1, "g": 1, "n": "Pläne und Kriege", "d": "Kriegs- und Bündnispläne der Clans, laufende Fehden und unruhige Dörfer.", "m": "act", "riv": true},
		{"id": "brushshape", "tab": 0, "g": -1, "n": "Pinselform", "d": "Wechselt die Form des Pinsels: Kreis, Quadrat oder Linie (ein Feld breit).", "m": "act"},
		{"id": "t_dig", "tab": 0, "g": 1, "n": "Erdschaufel", "d": "Gräbt Kanäle und Gräben: Land wird zu seichtem Wasser.", "m": "paint"},
		{"id": "t_sponge", "tab": 0, "g": 1, "n": "Wassersaug-Gu", "d": "Saugt Wasser auf – Meer und Flüsse werden zu Strand.", "m": "paint"},
		{"id": "t_axe", "tab": 0, "g": 2, "n": "Klingen-Axt", "d": "Fällt Bäume; das Holz geht an das nächste Dorf.", "m": "paint"},
		{"id": "t_erase", "tab": 0, "g": 2, "n": "Weltradierer", "d": "Löscht Lava, Asche, Feuer, Eis, Minen, Gu-Schwärme und Straßen – das Land kehrt in seinen natürlichen Zustand zurück.", "m": "paint"},
		{"id": "seed_grass", "tab": 0, "g": 2, "n": "Grasland-Samen", "d": "Ein Same, der sich zu blühendem Grasland mit Bäumen ausbreitet.", "m": "tap", "seed": GuData.GRASS},
		{"id": "seed_des", "tab": 0, "g": 2, "n": "Wüsten-Samen", "d": "Ein Same, aus dem sich eine Wüste ausbreitet.", "m": "tap", "seed": GuData.DES},
		{"id": "seed_snow", "tab": 0, "g": 2, "n": "Frost-Samen", "d": "Ein Same, aus dem sich ewiger Schnee mit Kiefern ausbreitet.", "m": "tap", "seed": GuData.SNOW},
		{"id": "inspire", "tab": 1, "g": 0, "n": "Gründungsgeist", "d": "Clanlose im Pinsel gründen einen eigenen Clan; Dörfer im Pinsel sagen sich von ihrem Clan los.", "m": "paint"},
		{"id": "bless", "tab": 1, "g": 1, "n": "Segen", "d": "Gesegnete werden stärker, zäher, schneller und kultivieren rascher (goldener Schimmer). Heilt die Leichen-Seuche.", "m": "paint"},
		{"id": "curse", "tab": 1, "g": 1, "n": "Fluch", "d": "Verfluchte werden schwach und langsam und kultivieren nur halb so schnell (dunkler Schleier).", "m": "paint"},
		{"id": "shield", "tab": 1, "g": 1, "n": "Himmelsschutz", "d": "20 Jahre lang trifft die Gu-Meister im Pinsel weder Drangsal noch Himmelswille noch Irdische Kalamität.", "m": "paint"},
		{"id": "hand", "tab": 2, "g": 5, "n": "Göttliche Hand", "d": "Halten und ziehen: Wesen im Pinsel werden hochgehoben und folgen dem Finger; loslassen lässt sie fallen.", "m": "paint"},
		{"id": "possess", "tab": 2, "g": 5, "n": "Seelenbesitz", "d": "Seelen-Pfad: Tippe ein Wesen an, um es zu besetzen. Danach lenkt ein Tippen es dorthin (oder auf einen Gegner). Tippe es erneut an, um es freizugeben.", "m": "tap"},
		{"id": "ctrlbeast", "tab": 2, "g": 5, "n": "Gelenkte Ödbestie", "d": "Ruft eine Urzeitliche Ödbestie unter deine Kontrolle – jedes weitere Tippen lenkt sie durch Dörfer und Gebirge.", "m": "tap"},
		{"id": "fert", "tab": 3, "g": 1, "n": "Frühlingsgras-Gu-Regen", "d": "Dünger: Erde und Asche ergrünen, Bäume, Sträucher und Blumen sprießen, Dörfer ernten mehr.", "m": "paint"},
		{"id": "sunray", "tab": 3, "g": 1, "n": "Sonnenstrahl", "d": "Feuer-Pfad: Ein Strahl der Sonne verbrennt Wesen und Wälder, lässt Wasser verdampfen, Eis schmelzen und Fels zu Lava werden.", "m": "paint"},
		{"id": "frost", "tab": 3, "g": 1, "n": "Frostodem", "d": "Eis-Pfad: Friert Wasser zu begehbarem Eis, löscht Feuer, lässt Lava erstarren und Wesen erstarren.", "m": "paint"},
		{"id": "volcano", "tab": 3, "g": 1, "n": "Erdfeuer-Vulkan", "d": "Ein Vulkan bricht aus: Lava fließt bergab, setzt alles in Brand und erkaltet zu Fels; Lavabomben und Asche regnen herab.", "m": "tap"},
		{"id": "tornado", "tab": 3, "g": 1, "n": "Windpfad-Wirbel", "d": "Ein Wirbelsturm des Wind-Pfades zieht über das Land, entwurzelt Bäume, reißt Häuser ein und schleudert Wesen fort.", "m": "tap"},
		{"id": "acid", "tab": 3, "g": 1, "n": "Giftregen", "d": "Gift-Pfad: Eine giftige Wolke zieht umher; ihr Regen verätzt Wesen, lässt Gras und Wälder welken und zerfrisst Gebäude.", "m": "tap"},
		{"id": "undead", "tab": 3, "g": 1, "n": "Leichen-Seuche", "d": "Seelen-Pfad: Angesteckte erheben sich als wandelnde Leichen, deren Biss die Seuche weiterträgt. Unsterbliche sind immun, Segen heilt.", "m": "paint"},
		{"id": "lava", "tab": 4, "g": 0, "n": "Erdfeuer-Lava", "d": "Gießt glühende Lava aus, die bergab fließt und zu Fels erkaltet.", "m": "paint"},
		{"id": "tnt", "tab": 4, "g": 3, "n": "Donnerkugel-Gu", "d": "Ein kleiner Sprengkörper aus Donner-Gu.", "m": "tap"},
		{"id": "mine", "tab": 4, "g": 3, "n": "Erdminen-Gu", "d": "Versteckte Erdminen-Gu explodieren, sobald jemand darauf tritt.", "m": "paint"},
		{"id": "napalm", "tab": 4, "g": 3, "n": "Feuerregen-Mordzug", "d": "Eine Reihe von Feuereinschlägen setzt alles in Brand.", "m": "tap"},
		{"id": "km6", "tab": 4, "g": 3, "n": "Rang-6-Mordzug", "d": "Ein unsterblicher Mordzug: Krater, Feuer und Druckwelle.", "m": "tap"},
		{"id": "km8", "tab": 4, "g": 3, "n": "Rang-8-Mordzug", "d": "Ein Mordzug fast auf Ehrwürdigen-Stufe: riesiger Krater, Pilzwolke, Druckwelle, die alles fortschleudert.", "m": "tap"},
		{"id": "km9", "tab": 4, "g": 3, "n": "Ehrwürdigen-Mordzug", "d": "Der Mordzug eines Rang-9-Ehrwürdigen löscht ganze Landstriche aus.", "m": "tap"},
		{"id": "void", "tab": 4, "g": 3, "n": "Leere-Mordzug", "d": "Raum-Pfad: Alles im Umkreis wird vom Raum verschlungen – zurück bleibt nur Meer.", "m": "tap"},
		{"id": "goo", "tab": 4, "g": 3, "n": "Verzehrender Gu-Schwarm", "d": "Ein Schwarm gefräßiger Gu breitet sich aus und frisst Land, Wälder, Gebäude und Wesen, bis er sich erschöpft.", "m": "tap"},
		{"id": "coin", "tab": 4, "g": 3, "n": "Schicksals-Münze", "d": "Das Schicksals-Gu wirft eine Münze: Die Hälfte aller Lebewesen stirbt. Nur wer das Schicksal überlistet (Frühling-Herbst-Zikade), kehrt zurück.", "m": "act"},
	])


static var _tool_idx: Dictionary = {}


static func tool_by_id(id: String) -> Dictionary:
	if _tool_idx.is_empty():
		for t: Dictionary in TOOLS:
			_tool_idx[t["id"]] = t
	return _tool_idx.get(id, {})


func brush_r() -> int:
	return 0 if shape == 2 else BRUSH[brush_idx]


func cycle_shape() -> String:
	shape = (shape + 1) % SHAPE_NAME.size()
	return SHAPE_NAME[shape]


func _brush_tiles(tx: int, ty: int, fn: Callable) -> void:
	if shape == 2:
		# Linie: alle Felder zwischen dem letzten und dem aktuellen Pinselpunkt
		var a: Vector2 = _seg_from if _seg_from.x >= 0.0 else Vector2(tx, ty)
		var b: Vector2 = Vector2(tx, ty)
		var n: int = maxi(1, ceili(a.distance_to(b) * 2.0))
		var last: int = -1
		for k: int in range(n + 1):
			var p: Vector2 = a.lerp(b, float(k) / n)
			var x0: int = int(p.x)
			var y0: int = int(p.y)
			if sim.world.in_map(x0, y0) and y0 * W + x0 != last:
				last = y0 * W + x0
				fn.call(last, x0, y0)
		return
	var r: int = brush_r()
	for dy: int in range(-r, r + 1):
		for dx: int in range(-r, r + 1):
			if shape == 0 and dx * dx + dy * dy > r * r + r * 0.8:
				continue
			var x: int = tx + dx
			var y: int = ty + dy
			if sim.world.in_map(x, y):
				fn.call(y * W + x, x, y)


func _brush_units(x: float, y: float) -> Array[Unit]:
	return sim.near_units(x, y, brush_r() + 1.5)


func _ladder_idx(t: int) -> int:
	var k: int = LADDER.find(t)
	if k >= 0:
		return k
	if t == GuData.WALL:
		return -1
	return 3


func begin_stroke() -> void:
	stroke_id += 1
	_seg_from = Vector2(-1, -1)
	if not held.is_empty():
		drop_held(-1.0, -1.0)


## Ende eines Pinselstrichs (Finger/Maus losgelassen): Die Göttliche Hand lässt los.
func end_stroke(wx: float, wy: float) -> void:
	_seg_from = Vector2(-1, -1)
	if not held.is_empty():
		drop_held(wx, wy)


## Ein Pinselstrich-Schritt an Weltposition (wx, wy).
func apply_paint(t: Dictionary, wx: float, wy: float, stroke: Dictionary) -> void:
	var tx: int = int(wx)
	var ty: int = int(wy)
	if not sim.world.in_map(tx, ty):
		return
	if stroke.has("lp"):
		_seg_from = stroke["lp"]
	else:
		_seg_from = Vector2(-1, -1)
	stroke["lp"] = Vector2(tx, ty)
	if paint_parity(t, wx, wy, stroke):
		return
	var w: World = sim.world
	if t.has("tt"):
		var tt: int = t["tt"]
		_brush_tiles(tx, ty, func(i: int, _x: int, _y: int) -> void:
			var nt: int = tt
			if nt == GuData.GRASS and w.region[i] == 0:
				nt = GuData.STEP
			sim.set_tile(i, nt))
		return
	match str(t["id"]):
		"t_up", "t_down":
			var up: bool = t["id"] == "t_up"
			_brush_tiles(tx, ty, func(i: int, _x: int, _y: int) -> void:
				if stroke.has(i):
					return
				stroke[i] = true
				var k: int = _ladder_idx(w.tile[i])
				if k < 0:
					return
				var nt: int = LADDER[clampi(k + (1 if up else -1), 0, 5)]
				if nt == GuData.GRASS:
					nt = sim.land_for(i)
				sim.set_tile(i, nt))
		"f_tree", "f_bamb":
			var bamb: bool = t["id"] == "f_bamb"
			_brush_tiles(tx, ty, func(i: int, x: int, y: int) -> void:
				var tt2: int = w.tile[i]
				if not GuData.is_land(tt2) or tt2 == GuData.WALL or tt2 == GuData.MOUNT or w.bmap[i] >= 0 or w.feat[i] != 0 or randf() < 0.8:
					return
				w.feat[i] = GuData.F_BAMB if bamb else sim.plant_for(i)
				w.mark_area(x, y))
		"f_ore":
			_brush_tiles(tx, ty, func(i: int, x: int, y: int) -> void:
				var tt3: int = w.tile[i]
				if not GuData.is_land(tt3) or tt3 == GuData.WALL or w.bmap[i] >= 0 or randf() < 0.85:
					return
				w.feat[i] = GuData.F_ORE
				w.mark_area(x, y))
		"f_spring":
			_brush_tiles(tx, ty, func(i: int, x: int, y: int) -> void:
				var tt4: int = w.tile[i]
				if not GuData.is_land(tt4) or tt4 == GuData.WALL or tt4 == GuData.MOUNT or w.bmap[i] >= 0 or randf() < 0.93:
					return
				w.feat[i] = GuData.F_SPRING
				w.mark_area(x, y))
			for v: Village in sim.villages:
				if v.alive:
					v.spring = sim.near_feat(v.cx, v.cy, 12, GuData.F_SPRING)
		"f_clear":
			_brush_tiles(tx, ty, func(i: int, x: int, y: int) -> void:
				if w.feat[i] != 0:
					w.feat[i] = 0
					w.mark_area(x, y))
		"bloom":
			_brush_tiles(tx, ty, func(i: int, x: int, y: int) -> void:
				var tt5: int = w.tile[i]
				if tt5 == GuData.ASH or tt5 == GuData.SOIL or tt5 == GuData.DES or tt5 == GuData.SNOW:
					var lf: int = sim.land_for(i)
					sim.set_tile(i, GuData.GRASS if lf == GuData.DES else lf)
				if (w.tile[i] == GuData.GRASS or w.tile[i] == GuData.STEP) and w.feat[i] == 0 and w.bmap[i] < 0 and randf() < 0.06:
					w.feat[i] = GuData.F_FLOWER if randf() < 0.5 else sim.plant_for(i)
					w.mark_area(x, y)
				if randf() < 0.08:
					sim.parts.append({"x": x + 0.5, "y": y + 0.5, "vx": 0.0, "vy": -3.0, "l": 0.8, "ml": 0.8, "c": [Color("#ff9ad0"), Color("#fff09a"), Color("#9affb0")].pick_random(), "s": 0.6, "g": 0.0}))
		"fire":
			_brush_tiles(tx, ty, func(i: int, _x: int, _y: int) -> void:
				if randf() < 0.5:
					sim.ignite(i, 1.2))
		"hope":
			for u: Unit in _brush_units(wx, wy):
				if u.k == "p" and u.rank == 0 and sim.uage(u) >= 10.0:
					sim.awaken(u, true)
					sim.pillar(u.x, u.y, GuData.ESS_COL[1], 0.5)
					sim.float_txt(u, "Erweckt · " + ("Extrem" if u.apt == "X" else u.apt), GuData.ESS_COL[1])
		"enlight":
			for u: Unit in _brush_units(wx, wy):
				if u.k != "p" or u.stroke_mark == stroke_id:
					continue
				u.stroke_mark = stroke_id
				if u.rank == 0 and sim.uage(u) >= 10.0:
					sim.awaken(u, true)
				elif u.rank > 0:
					sim.stage_up(u)
				sim.spark(u.x, u.y - 2.0, Color("#fff3c0"), 6, 4.0)
		"luck":
			for u: Unit in _brush_units(wx, wy):
				if u.k == "p":
					u.luck = 1.0
					sim.spark(u.x, u.y - 2.0, Color("#ffe27a"), 3, 3.0)
		"life":
			for u: Unit in _brush_units(wx, wy):
				if u.k == "p" and u.stroke_mark != stroke_id:
					u.stroke_mark = stroke_id
					u.life += 100.0
					sim.float_txt(u, "+100 Jahre", Color("#9affb0"))
		"demon":
			for u: Unit in _brush_units(wx, wy):
				if u.k == "p" and u.rank > 0 and not u.rogue:
					u.align = 1
					sim.go_rogue(u)
					sim.spark(u.x, u.y - 2.0, Color("#ff3030"), 6, 4.0)
		"plague":
			for u: Unit in _brush_units(wx, wy):
				if u.beh != GuData.B_GU and u.beh != GuData.B_IGU:
					u.sick = 22.0 + randf() * 10.0
		"smite":
			for u: Unit in _brush_units(wx, wy):
				u.dreason = "göttliche Auslöschung"
				sim.hurt(u, 1e9, null)
				sim.spark(u.x, u.y - 1.0, Color.WHITE, 5, 6.0)


## Setzt ein Wesen. Gibt einen Hinweistext zurück, wenn es nicht geht.
func spawn_at(t: Dictionary, wx: float, wy: float) -> String:
	var tx: int = int(wx)
	var ty: int = int(wy)
	if not sim.world.in_map(tx, ty):
		return ""
	var tt: int = sim.world.tile[ty * W + tx]
	var s: String = t["sp"]
	var land: bool = GuData.is_land(tt) and tt != GuData.WALL
	if s.begins_with("p"):
		var race: int = int(s.substr(1))
		if tt == GuData.WALL or (tt == GuData.DEEP and not GuData.RACE_SWIM[race] and not GuData.RACE_FLY[race]):
			return "Hier kann niemand leben."
		var u: Unit = sim.mk_person(wx, wy, race, 16.0 + randf() * 14.0)
		u.awk = true
		if randf() < 0.4:
			sim.awaken(u)
		sim.puff(wx, wy - 1.0, Color("#fff6d8"), 5)
		return ""
	match s:
		"gm":
			if not land:
				return "Gu-Meister brauchen festen Boden."
			sim.spawn_gm(wx, wy, int(t["r"]))
			return ""
		"gi":
			if tt == GuData.WALL:
				return ""
			sim.spawn_immortal(wx, wy, int(t["r"]))
			return ""
		"ven":
			for vd: Dictionary in Lore.VEN:
				if vd["id"] == t["ven"]:
					return sim.spawn_venerable(vd, wx, wy)
			return ""
		"fig":
			if not land:
				return "Hier kann niemand leben."
			for fd: Dictionary in Lore.FIG:
				if fd["id"] == t["fig"]:
					return sim.spawn_figure(fd, wx, wy)
			return ""
		"gu":
			if not land:
				return "Wilde Gu leben an Land."
			var pth: int = int(t["path"])
			if pth < 0:
				pth = int(GuData.REGPATH[sim.region_at(wx, wy)].pick_random())
			for k: int in range(3):
				sim.spawn_wild_gu(wx + (randf() - 0.5) * 3.0, wy + (randf() - 0.5) * 3.0, pth)
			sim.spark(wx, wy - 2.0, GuData.PATH_COL[pth], 6, 3.0)
			return ""
		"igu":
			var g: Unit = sim.spawn_wild_igu(wx, wy, str(t["igu"]))
			sim.pillar(wx, wy, GuData.PATH_COL[g.path], 0.7)
			sim.log_event("Ein wildes Unsterbliches Gu erscheint: " + g.pname() + ".", "violet", true)
			return ""
		"ow":
			if not land:
				return "Hier kann niemand leben."
			sim.ow_demon(wx, wy)
			return ""
	var S: Dictionary = GuData.SPEC[s]
	if S.get("aqua", false):
		if not GuData.is_water(tt):
			return S["n"] + " lebt nur im Wasser."
	elif not S["fly"] and ((tt == GuData.DEEP and not S.get("swim", false)) or tt == GuData.WALL):
		return "Hier kann diese Kreatur nicht leben."
	sim.spawn_beast(wx, wy, s)
	var tier: int = int(S.get("tier", 0))
	if tier >= 6:
		sim.shake = 0.4 + 0.15 * (tier - 6)
		sim.log_event("%s erwacht in %s." % [str(S["n"]), GuData.REGN_DAT[sim.region_at(wx, wy)]], "war", true)
	sim.puff(wx, wy - 1.0, Color("#e8dcc0"), 4)
	return ""


## Tipp-Werkzeuge. Gibt einen Hinweistext zurück (leer = nichts anzeigen).
func tap_tool(t: Dictionary, wx: float, wy: float) -> String:
	var tx: int = clampi(int(wx), 0, W - 1)
	var ty: int = clampi(int(wy), 0, H - 1)
	if t.has("pl"):
		var pt: String = t["pl"]
		var msg: String = sim.place_ok(pt, wx, wy)
		if msg != "":
			return msg
		sim.add_place(pt, wx, wy)
		return ""
	if t.has("org"):
		return sim.found_org(Lore.org(t["org"]), wx, wy)
	if t.has("seed"):
		if not sim._solid(ty * W + tx):
			return "Samen brauchen festen Boden."
		sim.plant_seed(wx, wy, int(t["seed"]))
		sim.spark(wx, wy - 1.0, Color("#e8d8a0"), 8, 3.0)
		return ""
	var pm: String = tap_parity(t, wx, wy)
	if pm != "-":
		return pm
	match str(t["id"]):
		"ev_calam":
			calamity(wx, wy)
		"ev_frag":
			var msg2: String = sim.place_ok("fragment", wx, wy)
			if msg2 != "":
				return msg2
			sim.fx.append({"k": "met", "x": wx, "y": wy, "l": 0.8, "ml": 0.8, "big": true})
			sim.later(0.8, func() -> void:
				sim.boom(wx, wy, 5.0, 200.0, {"ash": true, "burn": 0.2, "c": Color("#cfe0ff")})
				if sim.place_ok("fragment", wx, wy) == "":
					sim.add_place("fragment", wx, wy))
		"feud", "ally":
			var v: Village = sim.village_at(tx, ty)
			if v == null:
				return "Tippe auf ein Dorf."
			if pair_sel == null:
				pair_sel = v
				return sim.clans[v.clan].name + " gewählt – jetzt den zweiten Clan antippen."
			var a: Clan = sim.clans[pair_sel.clan]
			var b: Clan = sim.clans[v.clan]
			pair_sel = null
			if a == b:
				return "Wähle zwei verschiedene Clans."
			if t["id"] == "feud":
				sim.declare_war(a, b)
			else:
				sim.make_ally(a, b)
		"peace":
			var v2: Village = sim.village_at(tx, ty)
			if v2 == null:
				return "Tippe auf ein Dorf."
			var c: Clan = sim.clans[v2.clan]
			if c.war.is_empty():
				return c.name + " führt keine Fehde."
			for e: int in c.war.keys():
				sim.make_peace(c, sim.clans[e])
		"discord":
			var v3: Village = sim.village_at(tx, ty)
			if v3 == null:
				return "Tippe auf ein Dorf."
			return discord(v3)
		"stones":
			var v4: Village = sim.village_at(tx, ty)
			if v4 == null:
				return "Tippe auf ein Dorf."
			v4.stones += 50.0
			for k: int in range(24):
				sim.later(k * 0.04, func() -> void: sim.spark(v4.cx + (randf() - 0.5) * 14.0, v4.cy + (randf() - 0.5) * 10.0, Color("#f4fff8"), 2, 3.0))
			sim.log_event("Ein Urstein-Regen fällt über " + v4.name + ".", "gold", true)
		"tide":
			var rg: int = sim.region_at(wx, wy)
			var v5: Village = sim.nearest_village(wx, wy, 120.0, func(vv: Village) -> bool: return vv.reg == rg)
			if v5 == null:
				return "Kein Dorf in dieser Region."
			sim.beast_tide(v5, Vector2(wx, wy))
		"bolt":
			sim.bolt(wx, wy, 45.0, true)
		"quake":
			quake(wx, wy)
		"trib":
			for k: int in range(10):
				sim.later(k * 0.15, func() -> void: sim.bolt(wx + (randf() - 0.5) * 18.0, wy + (randf() - 0.5) * 18.0, 120.0, true))
			sim.later(1.7, func() -> void:
				sim.bolt(wx, wy, 400.0, true)
				sim.ring(wx, wy, 9.0, Color("#b98cff"), 1.0))
		"det":
			sim.boom(wx, wy, 5.0, 140.0, {"burn": 0.3, "c": Color("#9affb0")})
		"cres":
			crescent(wx, wy)
		"meteor":
			sim.fx.append({"k": "met", "x": wx, "y": wy, "l": 0.7, "ml": 0.7, "big": false})
			sim.later(0.7, func() -> void: sim.boom(wx, wy, 9.0, 400.0, {"ash": true, "burn": 0.4, "c": Color("#ff9a3a")}))
		"wrath":
			sim.fx.append({"k": "met", "x": wx, "y": wy, "l": 0.9, "ml": 0.9, "big": true})
			sim.later(0.9, func() -> void:
				sim.boom(wx, wy, 26.0, 99999.0, {"ash": true, "lake": true, "burn": 0.3, "c": Color("#ffe4a0")})
				sim.log_event("Eine unsterbliche Katastrophe verwüstet " + GuData.REGN[sim.region_at(wx, wy)] + ".", "red", true))
	return ""


## Irdische Kalamität: Unsterbliche im Umkreis werden geprüft, sonst bebt die Erde.
func calamity(x: float, y: float) -> void:
	var imms: Array[Unit] = []
	for u: Unit in sim.near_units(x, y, 30.0):
		if u.k == "p" and u.rank >= 6:
			imms.append(u)
	if imms.is_empty():
		quake(x, y)
		for k: int in range(4):
			sim.later(k * 0.3, func() -> void: sim.boom(x + (randf() - 0.5) * 20.0, y + (randf() - 0.5) * 20.0, 3.5, 60.0, {"ash": true, "burn": 0.15, "c": Color("#c9a46a")}))
		sim.log_event("Eine Irdische Kalamität erschüttert " + GuData.REGN_IN[sim.region_at(x, y)] + ".", "war", true)
		return
	for u: Unit in imms:
		sim.earthly_calamity(u)
	sim.log_event("Die Irdische Kalamität kommt über %d Gu-Unsterbliche." % imms.size(), "violet", true)


## Sofort-Ereignisse. Gibt {"msg": Hinweis, "pos": Ort zum Hinzoomen} zurück.
func event_act(id: String) -> Dictionary:
	match id:
		"ev_war":
			return {"msg": sim.rd_war(), "pos": Vector2(-1, -1)}
		"ev_dream", "ev_inherit":
			var pt: String = "dream" if id == "ev_dream" else "inherit"
			var vs: Array[Village] = []
			for v: Village in sim.villages:
				if v.alive:
					vs.append(v)
			for k: int in range(80):
				var p: Vector2
				if not vs.is_empty() and k < 60:
					var v2: Village = vs.pick_random()
					var a: float = randf() * TAU
					var d: float = 14.0 + randf() * 18.0
					p = Vector2(v2.cx + cos(a) * d, v2.cy + sin(a) * d)
				else:
					p = Vector2(randf() * W, randf() * H)
				if sim.place_ok(pt, p.x, p.y) == "":
					sim.add_place(pt, p.x, p.y)
					return {"msg": "", "pos": p}
			return {"msg": "Kein Ort gefunden.", "pos": Vector2(-1, -1)}
	return {"msg": "", "pos": Vector2(-1, -1)}


func discord(v: Village) -> String:
	var c: Clan = sim.clans[v.clan]
	var count: int = 0
	for w2: Village in sim.villages:
		if w2.alive and w2.clan == c.id:
			count += 1
	if count < 2:
		var gm: Array[Unit] = []
		for u: Unit in sim.units:
			if u.k == "p" and u.vil == v.id and u.rank > 0:
				gm.append(u)
		if gm.is_empty():
			return "Hier gibt es keine Gu-Meister, die sich abwenden könnten."
		for k: int in range(ceili(gm.size() / 2.0)):
			sim.go_rogue(gm[k])
		return ""
	var nc: Clan = sim.new_clan(v.reg, sim.rand_sur(v.reg))
	v.clan = nc.id
	for u: Unit in sim.units:
		if u.k == "p" and u.vil == v.id:
			u.clan = nc.id
	sim.log_event(v.name + " sagt sich von " + c.name + " los und gründet " + nc.name + ".", "war", true)
	sim.declare_war(nc, c, true)
	sim.terr_dirty = true
	return ""


func quake(x: float, y: float) -> void:
	sim.quake(x, y)


func crescent(x: float, y: float) -> void:
	var a0: float = randf() * TAU
	sim.fx.append({"k": "cres", "x": x, "y": y, "r": 12.0, "a": a0, "l": 0.9, "ml": 0.9})
	var w: World = sim.world
	for k: int in range(41):
		var a: float = a0 - 1.1 + k * (2.2 / 40.0)
		var rr: float = 10.0
		while rr <= 13.5:
			var tx: int = int(x + cos(a) * rr)
			var ty: int = int(y + sin(a) * rr)
			rr += 0.5
			if not w.in_map(tx, ty):
				continue
			var i: int = ty * W + tx
			var t: int = w.tile[i]
			if GuData.is_land(t) and t != GuData.WALL:
				if w.feat[i] != 0 and w.feat[i] != GuData.F_SPRING:
					w.feat[i] = 0
				sim.set_tile(i, GuData.HILL if t == GuData.MOUNT else GuData.SOIL)
			var bi: int = w.bmap[i]
			if bi >= 0 and sim.buildings[bi] != null:
				sim.remove_building(sim.buildings[bi])
	for u: Unit in sim.near_units(x, y, 14.0):
		if Vector2(u.x - x, u.y - y).length() > 8.0:
			sim.hurt(u, 900.0, null)
	sim.spark(x, y, Color("#d8eeff"), 50, 16.0)
	sim.shake = 0.7


## Zufallsereignis der Schicksalsgabe.
func fate() -> Vector2:
	var gms: Array[Unit] = []
	var old: Array[Unit] = []
	for u: Unit in sim.units:
		if u.k == "p" and u.hp > 0.0:
			if u.rank >= 1 and u.rank <= 4:
				gms.append(u)
			if u.rank >= 3:
				old.append(u)
	var vs: Array[Village] = []
	for v: Village in sim.villages:
		if v.alive:
			vs.append(v)
	var opts: Array[String] = ["bestie"]
	if not gms.is_empty():
		opts.append("erbe")
	if not old.is_empty():
		opts.append("zikade")
	if not vs.is_empty():
		opts.append_array(["steine", "stern"])
	match opts.pick_random():
		"erbe":
			var u: Unit = gms.pick_random()
			sim.ascend(u, u.rank + 1)
			sim.log_event(u.pname() + " entdeckt das Erbe eines alten Unsterblichen und erreicht " + GuData.rank_title(u.rank) + ".", "gold", true)
			return Vector2(u.x, u.y)
		"zikade":
			var u2: Unit = old.pick_random()
			u2.birth = sim.sim_time - 16.0 * 12.0
			u2.hp = u2.mhp
			sim.log_event(u2.pname() + " benutzt eine Frühling-Herbst-Zikade und wird wiedergeboren – jung, mit allen Erinnerungen.", "violet", true)
			sim.pillar(u2.x, u2.y, Color("#ffb6e0"))
			return Vector2(u2.x, u2.y)
		"steine":
			var v: Village = vs.pick_random()
			v.stones += 80.0
			sim.log_event("Ein Urstein-Regen fällt über " + v.name + ".", "gold", true)
			for j: int in range(24):
				sim.spark(v.cx + (randf() - 0.5) * 14.0, v.cy + (randf() - 0.5) * 10.0, Color("#eef8f2"), 2, 3.0)
			return Vector2(v.cx, v.cy)
		"stern":
			var v2: Village = vs.pick_random()
			var n: int = 0
			for u3: Unit in sim.units:
				if u3.k == "p" and u3.vil == v2.id and u3.hp > 0.0:
					u3.luck = 1.0
					if u3.rank == 0 and sim.uage(u3) >= 10.0 and randf() < 0.5:
						sim.awaken(u3, true)
						n += 1
			sim.log_event("Ein Glücksstern steht über %s: %d Öffnungen erwachen." % [v2.name, n], "gold", true)
			return Vector2(v2.cx, v2.cy)
	var p: Vector2 = sim.random_tile(func(i: int) -> bool: return (sim.world.tile[i] == GuData.GRASS or sim.world.tile[i] == GuData.STEP) and sim.world.bmap[i] < 0)
	if p.x >= 0.0:
		sim.mk_animal(p.x, p.y, "kingwolf")
		sim.log_event("Ein Bestienkönig erwacht in den " + GuData.REGN[sim.region_at(p.x, p.y)] + ".", "war", true)
	return p


# =====================================================================
# Gottkräfte-Parität (WorldBox)
# =====================================================================

## Pinsel-Werkzeuge der Parität. true = behandelt.
func paint_parity(t: Dictionary, wx: float, wy: float, stroke: Dictionary) -> bool:
	var w: World = sim.world
	var tx: int = int(wx)
	var ty: int = int(wy)
	match str(t["id"]):
		"t_dig":
			_brush_tiles(tx, ty, func(i: int, _x: int, _y: int) -> void:
				var tt: int = w.tile[i]
				if GuData.is_land(tt) and tt != GuData.WALL:
					sim.lava.erase(i)
					sim.set_tile(i, GuData.SHAL))
		"t_sponge":
			_brush_tiles(tx, ty, func(i: int, _x: int, _y: int) -> void:
				var tt: int = w.tile[i]
				if GuData.is_water(tt) or (tt == GuData.SNOW and w.temp_snow[i] in [1, 2]):
					sim.set_tile(i, GuData.SAND)
				sim.fire.erase(i))
			if randf() < 0.3:
				sim.spark(wx, wy, Color("#9fd6ff"), 4, 4.0)
		"t_axe":
			_brush_tiles(tx, ty, func(i: int, x: int, y: int) -> void:
				if GuData.is_tree(w.feat[i]):
					w.feat[i] = 0
					w.mark_area(x, y)
					sim.puff(x + 0.5, y - 3.0, Color("#7a9a3a"), 2)
					stroke["cut"] = int(stroke.get("cut", 0)) + 1)
			var nc: int = int(stroke.get("cut", 0))
			if nc > 0:
				var v: Village = sim.nearest_village(wx, wy, 40.0)
				if v != null:
					v.wood += nc * 2.0
				stroke["cut"] = 0
		"t_erase":
			_brush_tiles(tx, ty, func(i: int, x: int, y: int) -> void:
				var tt: int = w.tile[i]
				sim.fire.erase(i)
				var mi: int = sim.mines.find(i)
				if mi >= 0:
					sim.mines.remove_at(mi)
				if tt == GuData.LAVA or tt == GuData.ASH or tt == GuData.SOIL:
					sim.lava.erase(i)
					sim.set_tile(i, sim.land_for(i))
				elif tt == GuData.SNOW and w.temp_snow[i] > 0:
					sim.thaw(i)
				if w.feat[i] == GuData.F_ROAD or w.feat[i] == GuData.F_ROCK:
					w.feat[i] = 0
					w.mark_area(x, y))
			var gi: int = sim.goo.size() - 1
			while gi >= 0:
				var gx: int = int(sim.goo[gi]["i"]) % W
				var gy: int = int(sim.goo[gi]["i"]) / W
				if absi(gx - tx) <= brush_r() + 1 and absi(gy - ty) <= brush_r() + 1:
					sim.goo.remove_at(gi)
				gi -= 1
		"inspire":
			for u: Unit in _brush_units(wx, wy):
				if u.k != "p" or u.vil >= 0 or u.rogue or u.undead or sim.uage(u) < 14.0 or u.stroke_mark == stroke_id:
					continue
				u.stroke_mark = stroke_id
				if sim.found_village(u, -1):
					sim.pillar(u.x, u.y, Color("#ffe27a"), 0.6)
				else:
					var st: Vector2 = sim.find_site(u.x, u.y, 3.0, 24.0, sim.region_at(u.x, u.y))
					if st.x >= 0.0:
						u.col_to = st
						u.col_clan = -1
						sim.float_txt(u, "Gründungsgeist", Color("#ffe27a"))
			var v2: Village = sim.village_at(tx, ty)
			if v2 != null and not stroke.has("v%d" % v2.id):
				stroke["v%d" % v2.id] = true
				var c: Clan = sim.clans[v2.clan]
				var cnt: int = 0
				for o: Village in sim.villages:
					if o.alive and o.clan == c.id:
						cnt += 1
				if cnt >= 2:
					if c.cap == v2.id:
						c.cap = -1
					sim.rebel(v2)
					sim.pillar(v2.cx, v2.cy, Color("#ffe27a"), 0.8)
		"bless", "curse", "shield":
			var id: String = t["id"]
			for u: Unit in _brush_units(wx, wy):
				if u.k != "p" or u.stroke_mark == stroke_id:
					continue
				u.stroke_mark = stroke_id
				u.fxm = true
				match id:
					"bless":
						if u.undead:
							u.dreason = "durch Segen erlöst"
							sim.hurt(u, 1e9, null)
							sim.pillar(u.x, u.y, Color("#ffe27a"), 0.4)
							continue
						u.bless = 1
						u.zin = -1.0
						u.sick = 0.0
						sim.set_stats(u, false)
						u.hp = u.mhp
						sim.float_txt(u, "Gesegnet", Color("#ffe27a"))
						sim.spark(u.x, u.y - 3.0, Color("#ffe27a"), 6, 4.0)
					"curse":
						u.bless = -1
						sim.set_stats(u, false)
						sim.float_txt(u, "Verflucht", Color("#b070d0"))
						sim.puff(u.x, u.y - 3.0, Color("#3a1a4a"), 5)
					_:
						u.prot = sim.sim_time + 240.0
						sim.float_txt(u, "Himmelsschutz", Color("#bfe8ff"))
						sim.ring(u.x, u.y - 2.0, 3.0, Color("#bfe8ff"), 0.6)
		"hand":
			# Beim Ziehen sammelt die Hand weitere Wesen ein (höchstens 80)
			var got: int = 0
			for u: Unit in _brush_units(wx, wy):
				if held.size() >= 80 or u.held or u.air > 0.0:
					continue
				u.held = true
				u.fxm = true
				u.tgt = null
				u.st = "idle"
				held.append(u)
				held_off.append(Vector2(u.x - wx, u.y - wy).limit_length(float(brush_r()) + 1.0) * 0.6)
				got += 1
			if got > 0:
				sim.spark(wx, wy - 3.0, Color("#fff3c0"), 6, 4.0)
			for k: int in range(held.size()):
				var hu: Unit = held[k]
				if hu.hp <= 0.0:
					continue
				hu.x = clampf(wx + held_off[k].x, 0.5, W - 0.5)
				hu.y = clampf(wy - 3.0 + held_off[k].y, 0.5, H - 0.5)
				hu.tx = hu.x
				hu.ty = hu.y
				hu.moving = true
			if not held.is_empty() and randf() < 0.5:
				sim.parts.append({"x": wx + (randf() - 0.5) * 4.0, "y": wy - 2.0, "vx": 0.0, "vy": -2.0, "l": 0.4, "ml": 0.4, "c": Color("#fff3c0"), "s": 0.6, "g": 0.0})
		"fert":
			_brush_tiles(tx, ty, func(i: int, x: int, y: int) -> void:
				if randf() > 0.5:
					return
				var tt: int = w.tile[i]
				if tt == GuData.SOIL or tt == GuData.ASH:
					var lf: int = sim.land_for(i)
					sim.set_tile(i, GuData.GRASS if lf == GuData.DES else lf)
				elif tt == GuData.DES and randf() < 0.15:
					sim.set_tile(i, GuData.GRASS)
				tt = w.tile[i]
				if (tt == GuData.GRASS or tt == GuData.STEP) and w.feat[i] == 0 and w.bmap[i] < 0:
					var q: float = randf()
					if q < 0.05:
						w.feat[i] = sim.plant_for(i)
					elif q < 0.09:
						w.feat[i] = GuData.F_SHRUB
					elif q < 0.15:
						w.feat[i] = GuData.F_TUFT
					elif q < 0.18:
						w.feat[i] = GuData.F_FLOWER
					if q < 0.18:
						w.mark_area(x, y))
			for k2: int in range(3):
				sim.parts.append({"x": wx + (randf() - 0.5) * (brush_r() * 2.0 + 1.0), "y": wy - 8.0, "vx": 0.0, "vy": 14.0, "l": 0.5, "ml": 0.5, "c": Color("#7ae07a"), "s": 0.6, "g": 0.0})
			var v3: Village = sim.nearest_village(wx, wy, brush_r() + 10.0)
			if v3 != null and not stroke.has("f%d" % v3.id):
				stroke["f%d" % v3.id] = true
				v3.food += 6.0
		"sunray":
			if randf() < 0.5:
				sim.pillar(wx, wy, Color("#ffb43a"), 0.3)
			sim.spark(wx, wy, Color("#ffe27a"), 3, 5.0)
			_brush_tiles(tx, ty, func(i: int, _x: int, _y: int) -> void: _sun_tile(i))
			for u: Unit in _brush_units(wx, wy):
				u.dreason = "Sonnenstrahl"
				sim.hurt(u, 25.0 + u.mhp * 0.03, null)
				if u.hp > 0.0:
					u.dreason = ""
		"frost":
			_brush_tiles(tx, ty, func(i: int, x: int, y: int) -> void:
				if randf() > 0.6:
					return
				var tt: int = w.tile[i]
				sim.fire.erase(i)
				if tt == GuData.LAVA:
					sim.cool_lava(i)
				elif (GuData.is_water(tt) or tt == GuData.GRASS or tt == GuData.STEP or tt == GuData.SOIL or tt == GuData.DES or tt == GuData.ASH) and w.bmap[i] < 0:
					w.temp_snow[i] = tt + 1
					w.tile[i] = GuData.SNOW
					w.mark_dirty(x, y))
			for u: Unit in _brush_units(wx, wy):
				if u.beh == GuData.B_IGU:
					continue
				u.frz = sim.sim_time + (0.4 if u.rank >= 6 else 1.2 + randf())
				u.fxm = true
				sim.hurt(u, 2.0, null)
			for k3: int in range(4):
				sim.parts.append({"x": wx + (randf() - 0.5) * (brush_r() * 2.0 + 1.0), "y": wy + (randf() - 0.5) * (brush_r() * 2.0 + 1.0), "vx": (randf() - 0.5) * 3.0, "vy": -1.0, "l": 0.6, "ml": 0.6, "c": Color("#e8f8ff") if k3 % 2 else Color("#81d4fa"), "s": 0.8, "g": 0.0})
		"undead":
			for u: Unit in _brush_units(wx, wy):
				if u.k == "p" and not u.undead and u.rank < 6 and u.zin < 0.0:
					u.zin = sim.sim_time + 0.5 + randf() * 1.5
					u.fxm = true
					sim.spark(u.x, u.y - 2.0, Color("#86e04a"), 3, 3.0)
		"lava":
			_brush_tiles(tx, ty, func(i: int, _x: int, _y: int) -> void:
				if randf() < 0.5 and w.tile[i] != GuData.WALL:
					sim.set_lava(i, 1.1))
		"mine":
			_brush_tiles(tx, ty, func(i: int, _x: int, _y: int) -> void:
				if randf() < 0.05:
					sim.add_mine(i))
			if brush_r() <= 1 and not stroke.has("m%d" % (ty * W + tx)):
				stroke["m%d" % (ty * W + tx)] = true
				sim.add_mine(ty * W + tx)
		_:
			return false
	return true


## Sonnenstrahl auf einer Kachel: Wasser verdampft, Eis schmilzt, Fels wird zu Lava, Land brennt.
func _sun_tile(i: int) -> void:
	if randf() > 0.4:
		return
	var tt: int = sim.world.tile[i]
	if tt == GuData.SHAL:
		if randf() < 0.3:
			sim.set_tile(i, GuData.SAND)
	elif tt == GuData.DEEP:
		if randf() < 0.15:
			sim.set_tile(i, GuData.SHAL)
	elif tt == GuData.SNOW:
		sim.thaw(i)
	elif tt == GuData.MOUNT or tt == GuData.HILL:
		if randf() < 0.05:
			sim.set_lava(i, 0.8)
	elif tt == GuData.LAVA:
		sim.lava[i] = float(sim.lava.get(i, 0.0)) + 0.2
	elif randf() < 0.45:
		sim.ignite(i, 1.0)


## Tipp-Werkzeuge der Parität. "-" = nicht behandelt, sonst Hinweistext ("" = keiner).
func tap_parity(t: Dictionary, wx: float, wy: float) -> String:
	var i: int = clampi(int(wy), 0, H - 1) * W + clampi(int(wx), 0, W - 1)
	match str(t["id"]):
		"volcano":
			if sim.world.tile[i] == GuData.WALL:
				return "Hier kann kein Vulkan entstehen."
			sim.volcano(wx, wy)
		"tornado":
			sim.tornado(wx, wy)
		"acid":
			sim.acid_rain(wx, wy)
		"tnt":
			sim.ladder_move(wx, wy, 0)
		"napalm":
			sim.napalm(wx, wy)
		"km6":
			sim.ladder_move(wx, wy, 1)
		"km8":
			sim.ladder_move(wx, wy, 2)
		"km9":
			sim.ladder_move(wx, wy, 3)
		"void":
			sim.void_move(wx, wy)
		"goo":
			if not sim._solid(i):
				return "Der Gu-Schwarm braucht festen Boden."
			sim.goo_swarm(wx, wy)
		"possess", "ctrlbeast":
			return possess_tap(wx, wy, t["id"] == "ctrlbeast")
		_:
			return "-"
	return ""


## Göttliche Hand lässt los: Wesen fallen herab (bei wx < 0 an Ort und Stelle).
func drop_held(wx: float, wy: float) -> void:
	for k: int in range(held.size()):
		var u: Unit = held[k]
		u.held = false
		if u.hp <= 0.0:
			continue
		if wx >= 0.0:
			u.x = clampf(wx + held_off[k].x, 0.5, W - 0.5)
			u.y = clampf(wy + held_off[k].y, 0.5, H - 0.5)
		else:
			u.y = minf(H - 0.5, u.y + 3.0)
		u.tx = u.x
		u.ty = u.y
		u.tgt = null
		u.st = "idle"
		sim.hurt(u, 1.0 + u.mhp * 0.08, null)
		sim.puff(u.x, u.y, Color("#c8b89a"), 2)
	held.clear()
	held_off.clear()


## Seelenbesitz und gelenkte Ödbestie.
func possess_tap(wx: float, wy: float, giant: bool) -> String:
	var P: Unit = sim.possessed
	if P != null and P.hp <= 0.0:
		sim.set_possessed(null)
		P = null
	if giant and (P == null or P.sp != "remote"):
		var tt: int = sim.world.tile[clampi(int(wy), 0, H - 1) * W + clampi(int(wx), 0, W - 1)]
		if not GuData.is_land(tt) or tt == GuData.WALL:
			return "Die Ödbestie braucht festen Boden."
		var g: Unit = sim.spawn_beast(wx, wy, "remote")
		g.hx = -1.0
		sim.set_possessed(g)
		sim.shake = 0.8
		sim.log_event("Eine Urzeitliche Ödbestie erwacht – unter dem Willen des Himmels.", "war", true)
		return "Tippe auf die Karte, um die Ödbestie zu lenken."
	var near: Unit = null
	var bd: float = 3.0
	for u: Unit in sim.near_units(wx, wy + 1.5, 4.0):
		var d: float = Vector2(u.x - wx, u.y - 1.5 - wy).length()
		if d < bd and u.beh != GuData.B_IGU and not u.held:
			bd = d
			near = u
	if P != null and near == P:
		sim.set_possessed(null)
		sim.float_txt(P, "Freigegeben", Color("#c070ff"))
		return "Die Seele ist wieder frei."
	if P == null:
		if near == null:
			return "Tippe auf ein Wesen, um seine Seele zu besetzen."
		sim.set_possessed(near)
		sim.float_txt(near, "Besessen", Color("#c070ff"))
		return near.pname() + " ist besessen. Tippe auf die Karte, um es zu lenken, oder auf einen Gegner, um anzugreifen."
	if near != null:
		P.tgt = near
		sim.ring(near.x, near.y, 2.5, Color("#ff5a4a"), 0.5)
	else:
		P.tgt = null
		P.st = "idle"
		sim.go_to(P, wx, wy)
		sim.ring(wx, wy, 2.0, Color("#c070ff"), 0.5)
	return ""


## Sofort-Aktion Schicksals-Münze.
func coin() -> String:
	var n: int = sim.fate_coin()
	return "%d Wesen sind dem Schicksal erlegen." % n


static func _bar(frac: float, col: Color, width: int = 12) -> String:
	var n: int = clampi(roundi(frac * width), 0, width)
	return "[color=#%s]%s[/color][color=#2a352c]%s[/color]" % [col.to_html(false), "█".repeat(n), "█".repeat(width - n)]


## Zusatzzeilen für den Dorf-Inspektor: Hauptstadt, Clan-Oberhaupt, Loyalität, Kriegsmüdigkeit, Pläne.
func village_lines(v: Village) -> String:
	var c: Clan = sim.clans[v.clan]
	var mt: String = "[color=#9db09e]"
	var s: String = ""
	var capv: Village = sim.villages[c.cap] if c.cap >= 0 and c.cap < sim.villages.size() else null
	s += mt + "Hauptstadt[/color]  " + ("[color=#ffd24a]dieses Dorf[/color]" if c.cap == v.id else (capv.name if capv != null else "–")) + "\n"
	var L: Unit = c.lead
	if L != null and L.hp > 0.0:
		s += mt + "Clan-Oberhaupt[/color]  [color=#%s]■[/color] %s, %s\n" % [GuData.ESS_COL[L.rank].to_html(false), L.pname(), GuData.rank_title(L.rank)]
	if c.cap != v.id:
		var lc: Color = Color("#5fbf8a") if v.loy >= 50.0 else (Color("#e8c70a") if v.loy >= 25.0 else Color("#ff6a5a"))
		s += mt + "Loyalität[/color]  " + _bar(v.loy / 100.0, lc) + " %d" % int(v.loy) + ("  [color=#ff8a7a]Aufstand droht![/color]" if v.loy < 25.0 else "") + "\n"
	if c.exh >= 5.0:
		s += mt + "Kriegsmüdigkeit[/color]  " + _bar(c.exh / 100.0, Color("#c9a46a")) + " %d\n" % int(c.exh)
	for p: Dictionary in c.plans:
		var o: Clan = sim.clans[int(p["o"])]
		s += mt + "Plan[/color]  " + ("[color=#ffa894]Krieg gegen " if str(p["k"]) == "war" else "[color=#9fe0b0]Bündnis mit ") + o.name + "[/color] in %d Monaten\n" % maxi(0, ceili(float(p["t"]) - sim.sim_time))
	return s


## Zusatzzeilen für den Wesen-Inspektor (Segen, Fluch, Himmelsschutz, Seuche, Besessenheit, Boot).
func unit_lines(u: Unit) -> String:
	var s: String = ""
	if u.undead:
		s += "\n[color=#86e04a]Wandelnde Leiche – zerfällt in wenigen Jahren[/color]"
	elif u.zin > 0.0:
		s += "\n[color=#86e04a]Von der Leichen-Seuche angesteckt[/color]"
	if u.bless > 0:
		s += "\n[color=#ffe27a]Gesegnet[/color]"
	elif u.bless < 0:
		s += "\n[color=#b070d0]Verflucht[/color]"
	if u.prot > sim.sim_time:
		s += "\n[color=#bfe8ff]Himmelsschutz (noch %d Jahre)[/color]" % ceili((u.prot - sim.sim_time) / 12.0)
	if u.poss:
		s += "\n[color=#c070ff]Besessen – Tippen mit „Seelenbesitz“ lenkt es[/color]"
	if u.boat:
		s += "\n[color=#9fd6ff]Siedler im Boot[/color]"
	return s


## Inhalt des Fensters „Pläne und Kriege“.
func plans_text() -> String:
	var s: String = ""
	var sw: Callable = func(c: Clan) -> String: return "[color=#%s]■[/color] " % c.col.to_html(false)
	s += "[color=#e8c70a][b]LAUFENDE FEHDEN[/b][/color]\n"
	var nw: int = 0
	for a: Clan in sim.clans:
		if not a.alive:
			continue
		for e: int in a.war.keys():
			if e <= a.id:
				continue
			var b: Clan = sim.clans[e]
			var st: Variant = a.war[e]
			var since: String = (" · seit Jahr %d" % (int(float(st) / 12.0) + 1)) if st is float else ""
			s += sw.call(a) + "[b]" + a.name + "[/b]  [color=#ff7a5a]⚔[/color]  " + sw.call(b) + "[b]" + b.name + "[/b]\n    [color=#9db09e]Kriegsmüdigkeit %d / %d%s[/color]\n" % [int(a.exh), int(b.exh), since]
			nw += 1
	if nw == 0:
		s += "[color=#9db09e]Die Welt ist (noch) friedlich.[/color]\n"
	s += "\n[color=#e8c70a][b]PLÄNE DER CLANS[/b][/color]\n"
	var np: int = 0
	for c: Clan in sim.clans:
		if not c.alive:
			continue
		for p: Dictionary in c.plans:
			var o: Clan = sim.clans[int(p["o"])]
			var war: bool = str(p["k"]) == "war"
			s += sw.call(c) + c.name + (" [color=#ffa894]plant Krieg gegen[/color] " if war else " [color=#9fe0b0]bereitet ein Bündnis vor mit[/color] ") + sw.call(o) + o.name + "\n    [color=#9db09e]in %d Monaten[/color]\n" % maxi(0, ceili(float(p["t"]) - sim.sim_time))
			np += 1
	if np == 0:
		s += "[color=#9db09e]Keine Pläne.[/color]\n"
	s += "\n[color=#e8c70a][b]BÜNDNISSE[/b][/color]\n"
	var na: int = 0
	for a2: Clan in sim.clans:
		if not a2.alive:
			continue
		for e2: int in a2.ally.keys():
			if e2 <= a2.id or not sim.clans[e2].alive:
				continue
			s += sw.call(a2) + a2.name + "  [color=#62d8a4]⚭[/color]  " + sw.call(sim.clans[e2]) + sim.clans[e2].name + "\n"
			na += 1
	if na == 0:
		s += "[color=#9db09e]Keine Bündnisse.[/color]\n"
	s += "\n[color=#e8c70a][b]UNRUHIGE DÖRFER[/b][/color]\n"
	var nu: int = 0
	for v: Village in sim.villages:
		if v.alive and v.loy < 45.0 and sim.clans[v.clan].cap != v.id:
			s += "[url=v%d]%s[/url] [color=#9db09e](%s)[/color]  Loyalität %d%s\n" % [v.id, v.name, sim.clans[v.clan].name, int(v.loy), "  [color=#ff8a7a]Aufstand droht![/color]" if v.loy < 25.0 else ""]
			nu += 1
	if nu == 0:
		s += "[color=#9db09e]Alle Dörfer stehen treu zu ihren Clans.[/color]\n"
	return s
