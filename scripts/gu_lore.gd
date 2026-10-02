class_name Lore
extends RefCounted
## Inhalte aus Reverend Insanity (Quelle: docs/ri_content.json): sterbliche und unsterbliche Gu, Mordzüge,
## Ehrwürdige, Figuren, Organisationen und Orte. Unsichere Einträge der Daten sind als Spielinhalt erlaubt.

# ---------------- Sterbliche Gu je Pfad ----------------
## Index = Pfad-Id (GuData.PATH_NAME). Leere Listen bekommen erfundene Namen aus mgu().
const MGU: Array = [
	["Weißer-Eber-Gu", "Schwarzer-Eber-Gu", "Kraftfresser-Gu", "Krokodilkraft-Gu", "Großbär-Gu", "Volle-Kraft-Gu", "Kraftleih-Gu", "Flugbärkraft-Gu"],
	["Mondlicht-Gu", "Mondglanz-Gu", "Kleines-Licht-Gu", "Extremlicht-Gu", "Regenbogenlicht-Gu"],
	["Menschenfackel-Gu", "Verkohlte-Donnerkartoffel-Gu", "Steppenbrand-Gu", "Feuergewand-Gu"],
	["Wasserschild-Gu", "Reinigungswasser-Gu", "Wasserbild-Gu"],
	["Windklingen-Gu", "Verletzungswind-Gu"],
	["Donnerflügel-Gu", "Blitzauge-Gu", "Verkohlte-Donnerkartoffel-Gu"],
	["Holzzauber-Gu", "Tusita-Blume", "Himmelsessenz-Schatzlotus", "Drei-Schritt-Duftgras-Gu", "Kieferninsel-Gu", "Holzhuhn-Gu"],
	["Erdschatzblumen-Gu", "Erdschatzblumen-König-Gu", "Erdhäuptling-Zombie-Gu", "Erdloch-Gu", "Steinblenden-Gu", "Tarnfels-Gu", "Berg-wie-zuvor-Gu", "Tausend-Li-Erdwolfspinne"],
	["Blutschädel-Gu", "Blutmond-Gu", "Blutguillotine-Gu", "Blutrausch-Gu", "Blutvorhang-Himmelsblume-Gu", "Bluthandabdruck-Gu", "Eisenblut-Gu"],
	["Seelenexplosions-Gu", "Wolfsseelen-Gu", "Sorgenhäufungs-Gu", "Göttlicher-Sinn-Gu", "Seelensuche-Gu"],
	["Frühlingsgras-Gu", "Mensch-wie-zuvor-Gu", "Dritte-Nachtwache-Gu"],
	["Geistesblitz-Gu", "Böser-Gedanke-Gu", "Fadenspur-Gu", "Hinweis-Gu", "Sternengedanken-Gu"],
	["Knochenspeer-Gu", "Spiralknochenspeer-Gu", "Fliegender-Knochenschild-Gu", "Jadeknochen-Gu", "Kampfknochenrad-Gu", "Knochenflügel-Gu", "Weißknochenrad-Gu", "Schildkrötenjade-Wolfshaut-Gu"],
	["Lebendstahl-Gu", "Eisenhaut-Gu", "Kupferhaut-Gu"],
	["Eiskristall-Gu", "Eisexplosions-Gu", "Blauvogel-Eissarg-Gu", "Frostdämon-Gu"],
	["Schneekristall-Formation", "Schneewasch-Gu", "Eiskristall-Gu"],
	["Yin-Yang-Doppelwolken-Gu", "Himmelsbaldachin-Gu"],
	["Kleines-Licht-Gu", "Extremlicht-Gu", "Regenbogenlicht-Gu", "Mondglanz-Gu"],
	[], [],
	["Sternentor-Gu", "Sternlicht-Glühwürmchen-Gu", "Sternengedanken-Gu", "Sternennebel-Tarn-Gu"],
	["Sprung-Gu", "Platztausch-Gu", "Göttliche-Reise-Gu", "Luftsack-Gu"],
	[], [],
	["Glücksschau-Gu"],
	["Regel-und-Ordnung-Gu"],
	[], [], [], [], [],
	["Sklaven-Gu", "Bärenversklavungs-Gu", "Hundeversklavungs-Gu"],
	["Holzzauber-Gu", "Menschenhaut-Gu", "Yin-Yang-Wechsel-Gu"],
	["Holzkohle-Gu", "Sofortiger-Erfolg-Gu", "Hundert-Schlachten-Gu", "Lebendstahl-Gu", "Weinwurm", "Vier-Aromen-Weinwurm"],
	[],
	["Gifthauch-Gu", "Giftspucke-Gu", "Giftschwur-Gu", "Jadehimmel-Gu", "Worte-essen-Gu", "Schneewasch-Gu", "Giftameisen-Plage", "Frauenherz-Gu"],
	["Mondlicht-Gu", "Schwertschatten-Gu", "Einzelklingen-Gu", "Mondglanz-Gu"],
	[], [], [], [], [], [], [], [], [], [], [],
]
## Pfade, für die es einen eigenen Knopf "Wilde Gu" gibt (Tab Gu und Schicksal).
const WILD_PATHS: PackedInt32Array = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 20, 21, 31, 32, 33, 35, 36]

static var _mgu_cache: Dictionary = {}


## Sterbliche Gu eines Pfades (nie leer).
static func mgu(p: int) -> PackedStringArray:
	if _mgu_cache.has(p):
		return _mgu_cache[p]
	var out: PackedStringArray = PackedStringArray()
	if p >= 0 and p < MGU.size():
		for g: String in MGU[p]:
			out.append(g)
	if out.is_empty():
		var nm: String = GuData.PATH_NAME[clampi(p, 0, GuData.PATH_NAME.size() - 1)]
		for suf: String in ["wurm-Gu", "schild-Gu", "pfeil-Gu", "funken-Gu"]:
			out.append(nm + suf)
	_mgu_cache[p] = out
	return out


static func start_gu(p: int) -> String:
	return mgu(p)[0]


# ---------------- Mordzüge ----------------
const KM: Dictionary = {0: "Bärenkraft-Mordzug", 1: "Mondsichel-Mordzug", 2: "Feuermeer-Mordzug", 3: "Flutdrachen-Mordzug", 4: "Sturmklingen-Mordzug",
	5: "Donnerdrachen-Mordzug", 6: "Rankenkerker-Mordzug", 7: "Bergsturz-Mordzug", 8: "Blutstrom-Mordzug", 9: "Seelenschrei-Mordzug", 10: "Zeitstrom-Mordzug",
	11: "Sternenglühwürmchen-Mordzug", 12: "Knochenspeer-Mordzug", 14: "Eissarg-Mordzug", 15: "Schneesturm-Mordzug", 17: "Lichtpfeil-Mordzug",
	18: "Dunkelgrenze-Mordzug", 20: "Sternenfall-Mordzug", 21: "Raumriss-Mordzug", 24: "Unheilsruf-Mordzug", 30: "Dreifach-Qi-Mordzug",
	32: "Bestiengestalt-Mordzug", 33: "Himmelsschmiede-Mordzug", 35: "Giftnebel-Mordzug", 36: "Schwertregen-Mordzug", 39: "Traumflügel-Mordzug",
	46: "Schicksalslied-Mordzug", 47: "Tötungsabsicht-Mordzug"}


static func km_name(p: int) -> String:
	if KM.has(p):
		return KM[p]
	return GuData.PATH_NAME[clampi(p, 0, GuData.PATH_NAME.size() - 1)] + "-Mordzug"


# ---------------- Unsterbliche Gu ----------------
## fx: Wirkung beim Besitzer. revive = jung wiedergeboren, rez = wiederbelebt, fortune = übersteht eine Drangsal,
## str/str2 = Schaden, hp = Leben, move = Tempo, life = Lebenszeit, wis/cult/dream = Kultivierung, range = Reichweite,
## fire = Brand, bolt = Blitze, luck = Dauerglück, heal = Heilung, thief = stiehlt Gu, steal = stiehlt Lebenszeit,
## stones = Ursteine fürs Dorf, refine = mehr Gu, fetus = sofort Rang 6, gen = allgemeine Macht.
const IGU: Array = [
	{"id": "spring_autumn_cicada", "n": "Frühling-Herbst-Zikade", "r": 9, "p": 10, "fx": "revive", "d": "Stirbt der Träger, wird er jung wiedergeboren – mit allen Erinnerungen."},
	{"id": "wisdom_gu", "n": "Weisheits-Gu", "r": 9, "p": 11, "fx": "wis", "d": "Licht der Weisheit: viel schnellere Kultivierung."},
	{"id": "love_gu", "n": "Liebes-Gu", "r": 9, "p": 22, "fx": "gen", "d": "Wählt seinen Träger selbst; stärkt Angriff und Schutz."},
	{"id": "sovereign_immortal_fetus", "n": "Souveräner-Unsterblichen-Fötus-Gu", "r": 9, "p": 29, "fx": "fetus", "d": "Einweg: Ein Rang-5-Gu-Meister wird sofort Gu-Unsterblicher."},
	{"id": "derivation_gu", "n": "Ableitungs-Gu", "r": 9, "p": 25, "fx": "gen", "d": "Erschafft aus Toten neue Nachkommen."},
	{"id": "hatred_gu", "n": "Hass-Gu", "r": 9, "p": 22, "fx": "str", "d": "Verstärkt Rache: mehr Schaden."},
	{"id": "heavenly_secret", "n": "Himmelsgeheimnis-Gu", "r": 9, "p": 11, "fx": "wis", "d": "Deckt Himmelsgeheimnisse auf: schnellere Kultivierung."},
	{"id": "heavenly_web", "n": "Himmelsnetz-Gu", "r": 9, "p": 28, "fx": "gen", "d": "Wirft ein alles fangendes Netz über ein Gebiet."},
	{"id": "light_gu", "n": "Licht-Gu", "r": 9, "p": 17, "fx": "range", "d": "Wildes Sonnen-Gu: Lichtschläge über weite Distanz."},
	{"id": "fire_gu", "n": "Feuer-Gu", "r": 9, "p": 2, "fx": "fire", "d": "Wildes Sonnen-Gu: jeder Treffer entfacht einen Brand."},
	{"id": "strength_gu", "n": "Stärke-Gu", "r": 9, "p": 0, "fx": "str2", "d": "Ur-Gu der Kraft: doppelter Schaden."},
	{"id": "lightning_gu", "n": "Blitz-Gu", "r": 9, "p": 5, "fx": "bolt", "d": "Legendärer Blitzsturm: Angriffe rufen Blitze herab."},
	{"id": "advance_refinement", "n": "Fortschrittsverfeinerungs-Gu", "r": 9, "p": 33, "fx": "refine", "d": "Gu-Veredelung gelingt öfter: mehr Gu und Fortschritt."},
	{"id": "change_form", "n": "Gestaltwandel-Gu", "r": 9, "p": 32, "fx": "hp", "d": "Verwandlung in Bestien: viel mehr Lebenskraft."},
	{"id": "heavenly_essence_imperial_lotus", "n": "Himmelsessenz-Kaiserlotus", "r": 9, "p": 6, "fx": "stones", "d": "Erzeugt dauerhaft Ursteine für das Dorf des Trägers."},
	{"id": "fixed_immortal_travel", "n": "Fixierte-Unsterbliche-Reise-Gu", "r": 8, "p": 21, "fx": "move", "d": "Sofortige Reise: der Träger ist viel schneller."},
	{"id": "fixed_space", "n": "Raumfixierungs-Gu", "r": 7, "p": 21, "fx": "gen", "d": "Versiegelt ein Gebiet gegen Flucht."},
	{"id": "man_as_before", "n": "Mensch-wie-zuvor-Gu", "r": 8, "p": 10, "fx": "heal", "d": "Setzt den Körper zurück: heilt vollständig, wenn es knapp wird."},
	{"id": "landscape_as_before", "n": "Landschaft-wie-zuvor-Gu", "r": 8, "p": 10, "fx": "gen", "d": "Setzt das Gelände eines Gebiets zurück."},
	{"id": "years_flow_like_water", "n": "Jahre-fließen-wie-Wasser-Gu", "r": 8, "p": 10, "fx": "cult", "d": "Beschleunigt die Zeit: doppelt so schnelle Kultivierung."},
	{"id": "time_anchor", "n": "Zeitanker-Gu", "r": 6, "p": 10, "fx": "life", "d": "Verankert die Zeit: 400 Jahre mehr Leben."},
	{"id": "instant_pause", "n": "Augenblicksstopp", "r": 6, "p": 10, "fx": "move", "d": "Friert die Zeit kurz ein: der Träger handelt schneller."},
	{"id": "dog_shit_luck", "n": "Hundedreck-Glücks-Gu", "r": 9, "p": 24, "fx": "luck", "d": "Dauerhaftes Großes Glück: schnellere Kultivierung, sicherere Durchbrüche."},
	{"id": "fortune_rivalling_heaven", "n": "Himmelstrotzendes-Glück-Gu", "r": 8, "p": 24, "fx": "fortune", "d": "Einmalig: übersteht sicher eine Drangsal oder den Himmelswillen."},
	{"id": "calamity_beckoning", "n": "Unheilsruf-Gu", "r": 7, "p": 24, "fx": "bolt", "d": "Lenkt Unheil auf Feinde: Angriffe rufen Blitze herab."},
	{"id": "blood_asset", "n": "Blutvermögen-Gu", "r": 8, "p": 8, "fx": "str", "d": "Kern der Blut-Mordzüge: mehr Schaden."},
	{"id": "blood_relation", "n": "Blutsverwandtschafts-Gu", "r": 8, "p": 8, "fx": "gen", "d": "Spürt alle Blutpfad-Kultivierenden auf."},
	{"id": "mutation", "n": "Mutations-Gu", "r": 8, "p": 32, "fx": "gen", "d": "Mutiert Ziele in schwächere Formen."},
	{"id": "resurrection_from_the_dead", "n": "Auferstehung von den Toten", "r": 8, "p": 32, "fx": "rez", "d": "Einmalig: Der Träger steht nach dem Tod wieder auf."},
	{"id": "dream_token", "n": "Traummarken-Gu", "r": 8, "p": 39, "fx": "dream", "d": "Herrscht über Träume: schützt in Traumreichen, schnellere Kultivierung."},
	{"id": "dream_wings", "n": "Traumflügel-Gu", "r": 6, "p": 39, "fx": "dream", "d": "Fliegt sicher durch Traumreiche und gewinnt dort viel Erkenntnis."},
	{"id": "dreaming_immortal", "n": "Träumender-Unsterblicher-Gu", "r": 7, "p": 39, "fx": "dream", "d": "Durchlebt Traumleben: schnellere Kultivierung."},
	{"id": "change_soul", "n": "Seelentausch-Gu", "r": 7, "p": 9, "fx": "gen", "d": "Tauscht die Seele mit einem Ziel."},
	{"id": "myriad_self", "n": "Zehntausend-Selbst-Gu", "r": 7, "p": 29, "fx": "hp", "d": "Eine Armee von Phantom-Kopien schützt den Träger."},
	{"id": "perseverance", "n": "Beharrlichkeits-Gu", "r": 7, "p": 29, "fx": "hp", "d": "Der Träger kämpft weiter, wo andere aufgeben."},
	{"id": "humility", "n": "Demuts-Gu", "r": 8, "p": 29, "fx": "hp", "d": "Gibt Schaden gestärkt zurück."},
	{"id": "second_aperture", "n": "Zweitblenden-Gu", "r": 6, "p": 29, "fx": "cult", "d": "Zwei Blenden zugleich: doppelte Kultivierung."},
	{"id": "strong_gu", "n": "Stark-Gu", "r": 7, "p": 25, "fx": "str", "d": "Stärkt die Kraft des Trägers dauerhaft."},
	{"id": "kill_gu", "n": "Töten-Gu", "r": 8, "p": 47, "fx": "str", "d": "Angriffe sind auf reines Töten optimiert."},
	{"id": "great_thief", "n": "Großer-Dieb-Gu", "r": 8, "p": 41, "fx": "thief", "d": "Stiehlt besiegten Feinden ihre Gu."},
	{"id": "steal_life", "n": "Lebensraub-Gu", "r": 8, "p": 41, "fx": "steal", "d": "Stiehlt besiegten Feinden Lebenszeit."},
	{"id": "earth_prison", "n": "Erdkerker-Gu", "r": 7, "p": 7, "fx": "gen", "d": "Sperrt Gegner in ein Erdgefängnis."},
	{"id": "gruel_mud", "n": "Breischlamm-Gu", "r": 6, "p": 7, "fx": "gen", "d": "Korrosiver Schlamm zerfrisst ganze Gebiete."},
	{"id": "heavens_envy", "n": "Himmelsneid-Gu", "r": 7, "p": 28, "fx": "gen", "d": "Lenkt Drangsale auf talentierte Feinde."},
	{"id": "heavenly_birth", "n": "Himmelsgeburt-Gu", "r": 8, "p": 28, "fx": "heal", "d": "Starke Heilung, wenn es knapp wird."},
	{"id": "attitude_gu", "n": "Haltungs-Gu", "r": 8, "p": 29, "fx": "gen", "d": "Verbirgt die wahren Absichten des Trägers."},
	{"id": "star_thought", "n": "Sternengedanken-Gu", "r": 8, "p": 11, "fx": "wis", "d": "Sternenlicht-Schwarm aus Gedanken: schnellere Kultivierung."},
	{"id": "dark_limit", "n": "Dunkelgrenze-Gu", "r": 6, "p": 18, "fx": "gen", "d": "Blockiert gegnerische Wahrsagung."},
	{"id": "crescent_moon", "n": "Sichelmond-Gu", "r": 7, "p": 1, "fx": "range", "d": "Mondsichel-Klingen über große Distanz."},
	# Rang 9: Schicksals-Gu und Gu-Häuser; Rang 10: Legenden, die nie verfeinert wurden (norand = nie zufällig)
	{"id": "fate_gu", "n": "Schicksals-Gu", "r": 9, "p": 28, "fx": "fate", "norand": true, "d": "Werkzeug des Himmelswillens: Solange es existiert, liegen alle Schicksale fest – der Himmelswille schlägt härter zu, Rang 8 steigt kaum noch auf. Wird es zerstört, beginnt eine Ära des Chaos."},
	{"id": "heaven_overseeing_tower", "n": "Himmelsaufsichtsturm", "r": 9, "p": 28, "fx": "tower", "d": "Gu-Haus des Himmelshofs: überwacht die ganze Welt – große Reichweite und starker Schutz."},
	{"id": "blood_refinement_pool", "n": "Vier-Elemente-Reue-Blutveredelungsbecken", "r": 9, "p": 8, "fx": "pool", "d": "Gu-Haus des Blutpfades: veredelt Blut zu Kraft – Heilung, Lebenskraft und Gu-Veredelung."},
	{"id": "star_chessboard", "n": "Sternbild-Schachbrett", "r": 9, "p": 11, "fx": "chess", "d": "Gu-Haus der Sternbild-Ehrwürdigen: Jeder Zug eine Ableitung – schnellere Kultivierung und klügere Angriffe."},
	{"id": "destiny_gu", "n": "Bestimmungs-Gu", "r": 10, "p": 28, "fx": "destiny", "norand": true, "d": "Legende von Rang 10, nie verfeinert: Schreibt einmalig das Schicksal des Trägers neu – bis zu drei große Ränge auf einmal und Großes Glück."},
	{"id": "eternal_gu", "n": "Ewigkeits-Gu", "r": 10, "p": 10, "fx": "eternal", "norand": true, "d": "Legende von Rang 10, nie verfeinert: Der Träger altert nicht mehr."},
]
## Unsterbliche Gu mit eigenem Knopf (die übrigen über "Zufälliges Unsterbliches Gu").
const IGU_BTN: PackedStringArray = ["spring_autumn_cicada", "wisdom_gu", "strength_gu", "fixed_immortal_travel", "man_as_before", "time_anchor", "dog_shit_luck",
	"fortune_rivalling_heaven", "years_flow_like_water", "fire_gu", "lightning_gu", "resurrection_from_the_dead", "great_thief", "sovereign_immortal_fetus", "crescent_moon", "dream_wings"]
const FX_TEXT: Dictionary = {"revive": "Wiedergeburt", "rez": "Auferstehung", "fortune": "Drangsal-Schutz", "str": "Schaden +60 %", "str2": "Schaden ×2", "hp": "Leben +50 %",
	"move": "Tempo ×1,8", "life": "+400 Jahre", "wis": "Kultivierung ×2,2", "cult": "Kultivierung ×2", "dream": "Traum-Schutz", "range": "Reichweite +40 %",
	"fire": "Brand", "bolt": "Blitze", "luck": "Dauerglück", "heal": "Heilung", "thief": "Gu-Raub", "steal": "Lebensraub", "stones": "Ursteine", "refine": "Veredelung", "fetus": "Unsterblichkeit", "gen": "Macht +15 %",
	"fate": "Schicksal", "tower": "Reichweite +50 %, Schutz", "pool": "Blutveredelung", "chess": "Kultivierung ×1,6", "destiny": "Neues Schicksal", "eternal": "Alterslos"}

static var _igu_idx: Dictionary = {}


static func igu(id: String) -> Dictionary:
	if _igu_idx.is_empty():
		for e: Dictionary in IGU:
			_igu_idx[e["id"]] = e
	return _igu_idx.get(id, {})


## Zufälliges Unsterbliches Gu (ohne Schicksals-Gu und Rang-10-Legenden).
static func igu_random() -> String:
	for k: int in range(20):
		var e: Dictionary = IGU.pick_random()
		if not e.get("norand", false):
			return e["id"]
	return "strong_gu"


## Alle Unsterblichen Gu ab Rang 9 (Knopfgruppe „Rang-9-Gu“), in Tabellenreihenfolge.
static func igu_top() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for e: Dictionary in IGU:
		if int(e["r"]) >= 9:
			out.append(e["id"])
	return out


static func igu_name(id: String) -> String:
	var e: Dictionary = igu(id)
	return str(e["n"]) if not e.is_empty() else id


# ---------------- Ehrwürdige (Rang 9) ----------------
## fig ist der Schlüssel für "nur einer zur selben Zeit" (Fang Yuan teilt ihn mit seiner Figur).
## Agenda (Venerables): goal = Zielregion (-1 = wandert umher), seat = Orientierungspunkt (World.LANDMARKS) für den Sitz,
## lin = Organisation der Blutlinie (leer = eigene Linie), court = zweite Organisation, ag = Agenda-Schlüssel, life = Restlebenszeit in Jahren.
const VEN: Array = [
	{"id": "primordial_origin", "fig": "primordial_origin", "n": "Urursprung", "t": "Urursprung-Unsterblicher-Ehrwürdiger", "p": 30, "al": 0, "col": "#9fd8e8", "igu": "heavenly_birth", "d": "Erster Ehrwürdiger; gründete den Himmelshof.", "goal": 4, "seat": "Himmlischer Hof", "lin": "heavenly_court", "ag": "humans", "agenda": "Gründet den Himmelshof im Zentralkontinent und verhilft den Menschen zur Herrschaft über die Variant-Menschen."},
	{"id": "star_constellation", "fig": "star_constellation", "n": "Sternbild", "t": "Sternbild-Unsterbliche-Ehrwürdige", "p": 11, "al": 0, "col": "#7e57c2", "igu": "star_thought", "d": "Einzige weibliche Ehrwürdige; Weisheitspfad.", "goal": 4, "seat": "Himmlischer Hof", "lin": "heavenly_court", "ag": "fate_guard", "agenda": "Führt den Himmelshof, hütet das Schicksals-Gu, stärkt Weisheit und Wahrsagung und bekämpft dämonische Ehrwürdige."},
	{"id": "limitless", "fig": "limitless", "n": "Grenzenlos", "t": "Grenzenloser Dämonen-Ehrwürdiger", "p": 25, "al": 1, "col": "#3f51b5", "igu": "derivation_gu", "d": "Plante über eine Million Jahre; Regelpfad.", "goal": 2, "seat": "Unpassierbare Dünen", "lin": "", "ag": "order", "agenda": "Plant zurückgezogen in der Westwüste; in seinem Reich herrschen Regel und Ordnung – Fehden enden."},
	{"id": "reckless_savage", "fig": "reckless_savage", "n": "Rücksichtsloser Wilder", "t": "Rücksichtsloser-Wilder-Dämonen-Ehrwürdiger", "p": 0, "al": 1, "col": "#8d6e63", "igu": "strength_gu", "d": "Stärkster Körper aller Ehrwürdigen; Kraftpfad.", "goal": -1, "seat": "", "lin": "", "ag": "hunt", "agenda": "Zieht umher, jagt die stärksten Wesen und Ehrwürdigen der Welt und verwandelt sich im Kampf."},
	{"id": "red_lotus", "fig": "red_lotus", "n": "Roter Lotus", "t": "Roter-Lotus-Dämonen-Ehrwürdiger", "p": 10, "al": 1, "col": "#d32f2f", "igu": "spring_autumn_cicada", "d": "Schuf die Frühling-Herbst-Zikade; Zeitpfad.", "goal": 1, "seat": "Qing-Mao-Berg", "lin": "gu_yue_clan", "ag": "inherit", "life": 70.0, "agenda": "Ahnherr des Gu-Yue-Clans auf dem Qing-Mao-Berg; hinterlässt dort ein wahres Erbe. Kurzes, tragisches Leben."},
	{"id": "genesis_lotus", "fig": "genesis_lotus", "n": "Ursprungslotus", "t": "Ursprungslotus-Unsterblicher-Ehrwürdiger", "p": 6, "al": 0, "col": "#43a047", "igu": "heavenly_essence_imperial_lotus", "d": "Gründer der Himmelslotus-Sekte; Holzpfad.", "goal": 4, "seat": "", "lin": "heavenly_lotus_sect", "ag": "forest", "agenda": "Gründet die Himmelslotus-Sekte im Zentralkontinent; um ihn herum breiten sich Wälder aus."},
	{"id": "thieving_heaven", "fig": "thieving_heaven", "n": "Himmelsdieb", "t": "Himmelsdieb-Dämonen-Ehrwürdiger", "p": 41, "al": 1, "col": "#455a64", "igu": "great_thief", "d": "Stahl Gegnern im Kampf die Gu aus der Blende.", "goal": 3, "seat": "", "lin": "fang_clan", "ag": "steal", "agenda": "Begründet die Linie des Fang-Clans im Ostmeer und stiehlt anderen Unsterblichen ihre Unsterblichen Gu."},
	{"id": "giant_sun", "fig": "giant_sun", "n": "Riesensonne", "t": "Riesensonnen-Unsterblicher-Ehrwürdiger", "p": 24, "al": 0, "col": "#ffc107", "igu": "dog_shit_luck", "d": "Goldäugiger Riese des Glückspfads; gründete den Langlebigkeitshimmel.", "goal": 0, "seat": "", "lin": "huang_jin_tribes", "court": "longevity_heaven", "ag": "descend", "agenda": "Zieht in die Nordebenen, gründet den Huang-Jin-Stamm und den Langlebigkeitshimmel, zeugt viele glückliche Nachkommen und eint die Stämme unter sich."},
	{"id": "spectral_soul", "fig": "spectral_soul", "n": "Geisterseele", "t": "Geisterseelen-Dämonen-Ehrwürdiger", "p": 9, "al": 1, "col": "#6a1b9a", "igu": "change_soul", "d": "Grausamster Ehrwürdiger; Gründer der Schattensekte.", "goal": 1, "seat": "", "lin": "shadow_sect", "ag": "farm", "agenda": "Gründet die Schattensekte in der Südgrenze; Dörfer in seinem Reich wachsen als Menschenfarmen – bis er ihre Seelen verschlingt."},
	{"id": "paradise_earth", "fig": "paradise_earth", "n": "Paradieserde", "t": "Paradieserde-Unsterblicher-Ehrwürdiger", "p": 7, "al": 0, "col": "#a1887f", "igu": "earth_prison", "d": "Der Friedvolle aus der Südgrenze; Erdpfad.", "goal": 1, "seat": "", "lin": "", "ag": "bless", "agenda": "Segnet das Land der Südgrenze: Fruchtbarkeit, Blüte, Heilung und Hilfe für die Dörfer."},
	{"id": "fang_yuan_venerable", "fig": "fang_yuan", "n": "Fang Yuan", "t": "Himmelsschmiede-Dämonen-Ehrwürdiger", "p": 33, "al": 1, "col": "#ff7043", "igu": "advance_refinement", "d": "Der elfte Ehrwürdige; zerstörte das Schicksals-Gu.", "goal": 4, "seat": "", "lin": "heaven_earth_great_love_alliance", "ag": "refine", "agenda": "Gründet die Allianz der Großen Liebe, veredelt Unsterbliche Gu und zerstört das Schicksals-Gu, wo immer es ist."},
]

## Pfad-Gruppen für die Auswahl „Höchster Großmeister / Rang 9 nach Wahl“ (alle 48 Pfade).
const PATH_GROUPS: Array = [
	["Elemente", [2, 3, 4, 5, 6, 7, 13, 14, 15, 16, 17, 18, 1]],
	["Körper und Leben", [0, 8, 12, 32, 29, 35, 42, 43]],
	["Geist und Seele", [9, 11, 39, 40, 26, 22, 23, 45, 46, 44]],
	["Himmel und Gesetz", [10, 21, 20, 28, 24, 25, 27, 30, 34, 19]],
	["Kampf und Kunst", [36, 37, 38, 47, 41, 31, 33]],
]

# ---------------- Figuren ----------------
const FIG: Array = [
	{"id": "fang_yuan", "sur": "Gu Yue", "given": "Fang Yuan", "r": 1, "age": 15.0, "p": 33, "al": 1, "apt": "C", "org": "gu_yue_clan", "igu": ["spring_autumn_cicada"], "d": "Lebt dank der Frühling-Herbst-Zikade sein zweites Leben. Stirbt er, wird er einmal jung wiedergeboren."},
	{"id": "fang_zheng", "sur": "Gu Yue", "given": "Fang Zheng", "r": 1, "age": 15.0, "p": 8, "al": 0, "apt": "A", "org": "gu_yue_clan", "igu": [], "d": "Fang Yuans jüngerer Bruder mit A-Begabung; Blutpfad."},
	{"id": "bai_ning_bing", "sur": "Bai", "given": "Ning Bing", "r": 3, "age": 17.0, "p": 14, "al": 1, "apt": "X", "org": "bai_clan", "igu": [], "d": "Genie des Bai-Clans mit der Nördlichen-Dunkeleis-Seelenkonstitution."},
	{"id": "shang_xin_ci", "sur": "Shang", "given": "Xin Ci", "r": 3, "age": 20.0, "p": 45, "al": 0, "apt": "B", "org": "shang_clan", "igu": [], "d": "Anführerin des Shang-Clans; Informationspfad."},
	{"id": "hei_lou_lan", "sur": "Hei", "given": "Lou Lan", "r": 6, "age": 40.0, "p": 0, "al": 0, "apt": "A", "org": "hei_tribe", "igu": ["strong_gu"], "d": "Tochter des Hei-Stammesführers; Kraftpfad-Unsterbliche."},
	{"id": "tai_bai_yun_sheng", "sur": "Tai Bai", "given": "Yun Sheng", "r": 6, "age": 90.0, "p": 10, "al": 0, "apt": "B", "org": "", "igu": ["man_as_before"], "d": "Früher Mentor bei der Gu-Veredelung; besitzt das Mensch-wie-zuvor-Gu."},
	{"id": "feng_jin_huang", "sur": "Feng", "given": "Jin Huang", "r": 6, "age": 30.0, "p": 39, "al": 0, "apt": "X", "org": "spirit_affinity_house", "igu": ["dream_wings"], "d": "Begabteste Rivalin Fang Yuans; Trägerin der Traumflügel."},
	{"id": "zhao_lian_yun", "sur": "Zhao", "given": "Lian Yun", "r": 6, "age": 35.0, "p": 11, "al": 0, "apt": "B", "org": "", "igu": ["love_gu"], "d": "Trägerin des Liebes-Gu; Weisheitspfad."},
	{"id": "sixth_hair", "sur": "", "given": "Sechstes Haar", "race": 1, "r": 6, "age": 300.0, "p": 33, "al": 1, "apt": "B", "org": "shadow_sect", "igu": [], "d": "Veredelungs-Unsterblicher der Schattensekte (Haarmensch)."},
	{"id": "ying_wu_xie", "sur": "Ying", "given": "Wu Xie", "r": 7, "age": 200.0, "p": 9, "al": 1, "apt": "A", "org": "shadow_sect", "igu": ["fixed_immortal_travel"], "d": "Anführer der Schattensekte; Seelenpfad."},
	{"id": "wu_shuai", "sur": "Wu", "given": "Shuai", "r": 7, "age": 160.0, "p": 39, "al": 1, "apt": "A", "org": "", "igu": ["dream_token"], "d": "Führt die Variant-Menschen im späten Krieg; Traummarken-Gu."},
	{"id": "wu_yong", "sur": "Wu", "given": "Yong", "r": 8, "age": 400.0, "p": 4, "al": 0, "apt": "A", "org": "wu_clan", "igu": [], "d": "Oberster Ältester des Wu-Clans und Führer der Südlichen Allianz."},
	{"id": "feng_jiu_ge", "sur": "Feng", "given": "Jiu Ge", "r": 8, "age": 500.0, "p": 46, "al": 0, "apt": "A", "org": "spirit_affinity_house", "igu": [], "d": "Vater von Feng Jin Huang; Mordzug Schicksalslied."},
	{"id": "duke_long", "sur": "", "given": "Herzog Long", "r": 8, "age": 900.0, "p": 30, "al": 0, "apt": "A", "org": "heavenly_court", "igu": ["blood_relation"], "d": "Heerführer des Himmelshofs mit Quasi-Rang-9-Kraft."},
]

# ---------------- Organisationen ----------------
## k: Sekte, Clan, Stamm, Hof, Allianz · reg: Region (-1 = überall) · al: 1 = dämonisch · lead: Rang des Gründers · g: Knopfgruppe
const ORGS: Array = [
	{"id": "heavenly_court", "n": "Himmelshof", "gl": "天", "k": "Hof", "reg": 4, "al": 0, "col": "#e8d47a", "lead": 8, "g": 0, "d": "Mächtigste Organisation der Gu-Unsterblichen, gegründet von Urursprung. Nur im Zentralkontinent."},
	{"id": "immortal_crane_sect", "n": "Unsterblicher-Kranich-Sekte", "gl": "鹤", "k": "Sekte", "reg": 4, "al": 0, "col": "#d8e0e8", "lead": 6, "g": 0, "d": "Etablierte Macht des Zentralkontinents."},
	{"id": "spirit_affinity_house", "n": "Geistaffinitäts-Haus", "gl": "灵", "k": "Sekte", "reg": 4, "al": 0, "col": "#5a8ae8", "lead": 6, "g": 0, "d": "Sekte von Feng Jiu Ge und Feng Jin Huang."},
	{"id": "heavenly_lotus_sect", "n": "Himmelslotus-Sekte", "gl": "莲", "k": "Sekte", "reg": 4, "al": 0, "col": "#e87aa8", "lead": 6, "g": 0, "d": "Gegründet von Ursprungslotus."},
	{"id": "ancient_soul_sect", "n": "Alte-Seelen-Sekte", "gl": "魂", "k": "Sekte", "reg": 4, "al": 0, "col": "#7a4ab8", "lead": 6, "g": 0, "d": "Eine der Zehn Großen Alten Sekten."},
	{"id": "black_heaven_temple", "n": "Schwarzhimmel-Tempel", "gl": "黑", "k": "Sekte", "reg": 4, "al": 0, "col": "#4a4a5a", "lead": 6, "g": 0, "d": "Eine der Zehn Großen Alten Sekten."},
	{"id": "combat_immortal_sect", "n": "Kampfunsterblichen-Sekte", "gl": "战", "k": "Sekte", "reg": 4, "al": 0, "col": "#c83a2a", "lead": 6, "g": 0, "d": "Eine der Zehn Großen Alten Sekten."},
	{"id": "heavens_envy_manor", "n": "Himmelsneid-Anwesen", "gl": "妒", "k": "Sekte", "reg": 4, "al": 0, "col": "#8a2a6a", "lead": 6, "g": 0, "d": "Eine der Zehn Großen Alten Sekten."},
	{"id": "myriad_dragon_dock", "n": "Zehntausend-Drachen-Dock", "gl": "龙", "k": "Sekte", "reg": 4, "al": 0, "col": "#2a8a6a", "lead": 6, "g": 0, "d": "Eine der Zehn Großen Alten Sekten."},
	{"id": "spirit_butterfly_valley", "n": "Geisterschmetterlings-Tal", "gl": "蝶", "k": "Sekte", "reg": 4, "al": 0, "col": "#c8a0e8", "lead": 6, "g": 0, "d": "Eine der Zehn Großen Alten Sekten."},
	{"id": "wind_cloud_manor", "n": "Windwolken-Anwesen", "gl": "云", "k": "Sekte", "reg": 4, "al": 0, "col": "#7ac8c8", "lead": 6, "g": 0, "d": "Eine der Zehn Großen Alten Sekten."},
	{"id": "lang_ya_sect", "n": "Lang-Ya-Sekte", "gl": "琅", "k": "Sekte", "reg": -1, "al": 0, "col": "#c8a03a", "race": 1, "lead": 6, "g": 0, "d": "Sekte der Haarmenschen; verfeinerte das Zehntausend-Selbst-Gu."},
	{"id": "longevity_heaven", "n": "Langlebigkeitshimmel", "gl": "寿", "k": "Hof", "reg": -1, "al": 0, "col": "#e8b830", "lead": 7, "g": 0, "d": "Fraktion von Riesensonne."},
	{"id": "shadow_sect", "n": "Schattensekte", "gl": "影", "k": "Sekte", "reg": -1, "al": 1, "col": "#4a3a5a", "lead": 6, "g": 0, "d": "Geheimorden aus den Seelensplittern von Geisterseele. Dämonisch."},
	{"id": "rockman_imperial_court", "n": "Steinmenschen-Kaiserhof", "gl": "岩", "k": "Hof", "reg": -1, "al": 0, "col": "#8a8478", "race": 2, "lead": 6, "g": 0, "d": "Antikes Reich der Steinmenschen, aus dem das Schicksals-Gu gestohlen wurde."},
	{"id": "dragon_palace", "n": "Drachenpalast", "gl": "宫", "k": "Hof", "reg": 3, "al": 0, "col": "#2a8a9a", "race": 6, "lead": 6, "g": 0, "d": "Sitz der Drachenmenschen im Ostmeer."},
	{"id": "wu_clan", "n": "Wu-Clan", "gl": "武", "k": "Clan", "reg": 1, "al": 0, "col": "#2f6fd6", "sur": "Wu", "lead": 6, "g": 1, "d": "Oberherr-Clan der Südgrenze."},
	{"id": "shang_clan", "n": "Shang-Clan", "gl": "商", "k": "Clan", "reg": 1, "al": 0, "col": "#d18a2a", "sur": "Shang", "lead": 5, "g": 1, "d": "Reichster Handelsclan der Südgrenze."},
	{"id": "gu_yue_clan", "n": "Gu-Yue-Clan", "gl": "古", "k": "Clan", "reg": 1, "al": 0, "col": "#2f9a7a", "sur": "Gu Yue", "lead": 4, "spring": true, "g": 1, "d": "Fang Yuans Heimatclan auf dem Qing-Mao-Berg, mit Geisterquelle."},
	{"id": "bai_clan", "n": "Bai-Clan", "gl": "白", "k": "Clan", "reg": 1, "al": 0, "col": "#b8c8d8", "sur": "Bai", "lead": 4, "g": 1, "d": "Bai Ning Bings Clan auf dem Bai-Gu-Berg."},
	{"id": "tie_clan", "n": "Tie-Clan", "gl": "铁", "k": "Clan", "reg": 1, "al": 0, "col": "#6a6a72", "sur": "Tie", "lead": 4, "g": 1, "d": "Rivalisierender Clan der Südgrenze."},
	{"id": "chi_clan", "n": "Chi-Clan", "gl": "赤", "k": "Clan", "reg": 1, "al": 0, "col": "#c23a2e", "sur": "Chi", "lead": 4, "g": 1, "d": "Einer der rivalisierenden Super-Clans."},
	{"id": "qing_clan", "n": "Qing-Clan", "gl": "青", "k": "Clan", "reg": -1, "al": 0, "col": "#2ab8b0", "sur": "Qing", "lead": 4, "g": 1, "d": "Besaß einst das Hass-Gu."},
	{"id": "fang_clan", "n": "Fang-Clan", "gl": "方", "k": "Clan", "reg": -1, "al": 0, "col": "#8a46b8", "sur": "Fang", "lead": 4, "g": 1, "d": "Hütet ein echtes Vermächtnis des Himmelsdiebs."},
	{"id": "western_desert_families", "n": "Oasenclans der Westwüste", "gl": "沙", "k": "Clan", "reg": 2, "al": 0, "col": "#d8a040", "race": 4, "lead": 4, "g": 1, "d": "Oasenclans der Federmenschen (Spielidee, keine Namen in den Quellen)."},
	{"id": "eastern_sea_clans", "n": "Inselclans des Ostmeers", "gl": "岛", "k": "Clan", "reg": 3, "al": 0, "col": "#1f8aa0", "race": 3, "lead": 4, "g": 1, "d": "Inselclans des Ostmeers (Spielidee)."},
	{"id": "hei_tribe", "n": "Hei-Stamm", "gl": "黑", "k": "Stamm", "reg": 0, "al": 0, "col": "#3a3a44", "sur": "Hei", "lead": 5, "g": 2, "d": "Stamm von Hei Cheng und Hei Lou Lan."},
	{"id": "huang_jin_tribes", "n": "Huang-Jin-Stämme", "gl": "黄", "k": "Stamm", "reg": 0, "al": 0, "col": "#e0b020", "sur": "Huang Jin", "lead": 5, "g": 2, "d": "Koalition goldener Stämme der Nordebenen."},
	{"id": "dong_fang_tribe", "n": "Dong-Fang-Stamm", "gl": "东", "k": "Stamm", "reg": 0, "al": 0, "col": "#5a6ab8", "sur": "Dong Fang", "lead": 5, "g": 2, "d": "Stamm von Dong Fang Chang Fan."},
	{"id": "bai_zu_tribe", "n": "Bai-Zu-Stamm", "gl": "祖", "k": "Stamm", "reg": 0, "al": 0, "col": "#c8b890", "sur": "Bai Zu", "lead": 4, "g": 2, "d": "Stamm der Nordebenen."},
	{"id": "chu_tribe", "n": "Chu-Stamm", "gl": "楚", "k": "Stamm", "reg": 0, "al": 0, "col": "#b8562e", "sur": "Chu", "lead": 4, "g": 2, "d": "Stamm der Nordebenen."},
	{"id": "chanyu_tribe", "n": "Chanyu-Stamm", "gl": "单", "k": "Stamm", "reg": 0, "al": 0, "col": "#7a8a2a", "sur": "Chanyu", "lead": 4, "g": 2, "d": "Stamm der Nordebenen."},
	{"id": "murong_tribe", "n": "Murong-Stamm", "gl": "慕", "k": "Stamm", "reg": 0, "al": 0, "col": "#c9487a", "sur": "Murong", "lead": 4, "g": 2, "d": "Stamm der Nordebenen."},
	{"id": "zombie_alliance", "n": "Zombie-Allianz", "gl": "尸", "k": "Allianz", "reg": 0, "al": 1, "col": "#5a6a4a", "lead": 6, "g": 3, "d": "Regionsübergreifende dämonische Allianz der Zombifizierung."},
	{"id": "southern_alliance", "n": "Südliche Allianz", "gl": "南", "k": "Allianz", "reg": 1, "al": 0, "col": "#2e7a3a", "lead": 6, "g": 3, "d": "Von Wu Yong geführte Allianz gegen den Himmelshof."},
	{"id": "righteous_qi_alliance", "n": "Rechtschaffene-Qi-Allianz", "gl": "义", "k": "Allianz", "reg": 3, "al": 0, "col": "#3a9ad8", "lead": 6, "g": 3, "d": "Bündnis rechtschaffener Kräfte im Ostmeer."},
	{"id": "four_races_alliance", "n": "Vier-Rassen-Allianz", "gl": "四", "k": "Allianz", "reg": -1, "al": 0, "col": "#9a7a4a", "race": -2, "lead": 5, "g": 3, "d": "Bündnis der Variant-Menschen."},
	{"id": "heaven_earth_great_love_alliance", "n": "Allianz der Großen Liebe", "gl": "爱", "k": "Allianz", "reg": -1, "al": 1, "col": "#ff7043", "lead": 7, "g": 3, "d": "Fang Yuans Allianz von Himmel und Erde."},
]

static var _org_idx: Dictionary = {}


static func org(id: String) -> Dictionary:
	if _org_idx.is_empty():
		for e: Dictionary in ORGS:
			_org_idx[e["id"]] = e
	return _org_idx.get(id, {})


# ---------------- Orte ----------------
## r: Wirkungsradius · lure: Lockradius · life: Monate bis zum Verschwinden (0 = dauerhaft) · uniq: nur einmal
const PLACE: Dictionary = {
	"blessed": {"n": "Gesegnetes Land", "r": 18.0, "d": "Blende eines Gu-Unsterblichen: Unsterbliche in der Nähe kultivieren doppelt so schnell, mit der Zeit entstehen wilde Unsterbliche Gu."},
	"grotto": {"n": "Grottenhimmel", "r": 26.0, "d": "Blende ab Rang 8: dreifache Kultivierung, Himmelskristalle (Ursteine) für nahe Dörfer, eigenes Wetter."},
	"court": {"n": "Himmelshof", "r": 36.0, "uniq": true, "d": "Grottenhimmel des Himmelshofs mit dem Himmelsüberwachungsturm: stärkt rechtschaffene Unsterbliche und straft Dämonische."},
	"langya": {"n": "Lang-Ya-Gesegnetes-Land", "r": 30.0, "uniq": true, "d": "Handelsort des Landgeistes: Gu-Meister in der Nähe tauschen Gu, Dörfer erhalten Ursteine."},
	"hu": {"n": "Hu-Unsterblichen-Gesegnetes-Land", "r": 20.0, "uniq": true, "lure": 70.0, "d": "Herrenloses Gesegnetes Land: Ein Rang-5-Gu-Meister, der es erreicht, übernimmt es und wird unsterblich."},
	"imperial": {"n": "Kaiserhof-Gesegnetes-Land", "r": 14.0, "uniq": true, "lure": 90.0, "d": "Umkämpftes Schatzland: lockt Gu-Meister aller Clans an und entfacht Fehden."},
	"dream": {"n": "Traumreich", "r": 7.0, "lure": 50.0, "life": 60.0, "d": "Vorübergehende Traumzone: lockt Gu-Meister an, die darin Erkenntnis gewinnen – oder Seelenschaden erleiden."},
	"inherit": {"n": "Erbe", "r": 3.0, "lure": 55.0, "d": "Hinterlassenschaft eines toten Unsterblichen: Wer es zuerst erreicht, erhält Rang und Gu – oder tappt in eine Falle."},
	"fragment": {"n": "Himmelsfragment", "r": 3.0, "lure": 90.0, "d": "Trümmer eines zerstörten Himmels: Ein Unsterblicher, der es einverleibt, muss keine Drangsale mehr fürchten, bleibt aber für immer daran gebunden."},
	"palace": {"n": "Drachenpalast", "r": 20.0, "uniq": true, "d": "Unterwasserfestung der Drachenmenschen. Muss im Meer stehen und bringt neue Drachenmenschen hervor."},
	"mushroom": {"n": "Pilzmenschen-Paradies", "r": 16.0, "uniq": true, "d": "Feuchtes Tal voller Riesenpilze: Hier entstehen immer wieder Pilzmenschen."},
	"yitian": {"n": "Yi-Tian-Berg", "r": 12.0, "uniq": true, "lure": 110.0, "d": "Auf diesem Berg erscheint einmalig das Souveräner-Unsterblichen-Fötus-Gu – Gu-Meister kämpfen darum."},
	"crazed": {"n": "Höhle des Wahnsinnigen Dämons", "r": 14.0, "uniq": true, "lure": 160.0, "d": "Schauplatz der letzten Kämpfe: lockt Unsterbliche ab Rang 7 an, die sich hier bis zum Tod duellieren."},
}
const PLACE_ORDER: PackedStringArray = ["blessed", "grotto", "court", "langya", "hu", "imperial", "dream", "inherit", "palace", "mushroom", "yitian", "crazed"]
const INHERIT_NAMES: PackedStringArray = ["Erbe der Drei Könige", "Erbe des Roten Lotus", "Erbe des Blutmeer-Ahnen", "Erbe des Weinmönchs", "Erbe des Blumenweinmönchs", "Erbe eines Weisheits-Unsterblichen", "Wahres-Yang-Gebäude"]
