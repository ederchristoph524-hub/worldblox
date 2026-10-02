class_name Lore
extends RefCounted
## Inhalte aus Reverend Insanity (Quelle: docs/ri_content.json): sterbliche und unsterbliche Gu, Mordzüge,
## Ehrwürdige, Figuren, Organisationen und Orte. Unsichere Einträge der Daten sind als Spielinhalt erlaubt.

# ---------------- Sterbliche Gu je Pfad ----------------
## Index = Pfad-Id (GuData.PATH_NAME). Leere Listen bekommen erfundene Namen aus mgu().
const MGU: Array = [
	["White Boar Gu", "Black Boar Gu", "Strength Devouring Gu", "Crocodile Strength Gu", "Great Bear Gu", "Full Strength Gu", "Borrowed Strength Gu", "Flying Bear Strength Gu"],
	["Moonlight Gu", "Moonglow Gu", "Little Light Gu", "Extreme Light Gu", "Rainbow Light Gu"],
	["Human Torch Gu", "Charred Thunder Potato Gu", "Prairie Fire Gu", "Fire Clothes Gu"],
	["Water Shield Gu", "Purifying Water Gu", "Water Image Gu"],
	["Wind Blade Gu", "Wounding Wind Gu"],
	["Thunder Wings Gu", "Lightning Eye Gu", "Charred Thunder Potato Gu"],
	["Wood Charm Gu", "Tusita Flower", "Heavenly Essence Treasure Lotus", "Three Step Fragrant Grass Gu", "Pine Island Gu", "Wood Chicken Gu"],
	["Earth Treasure Flower Gu", "Earth Treasure Flower King Gu", "Earth Chief Zombie Gu", "Earth Hole Gu", "Stone Aperture Gu", "Camouflage Rock Gu", "Mountain As Before Gu", "Thousand Li Earth Wolf Spider"],
	["Blood Skull Gu", "Blood Moon Gu", "Blood Guillotine Gu", "Blood Frenzy Gu", "Blood Curtain Heavenly Flower Gu", "Blood Handprint Gu", "Iron Blood Gu"],
	["Soul Explosion Gu", "Wolf Soul Gu", "Accumulated Worry Gu", "Divine Sense Gu", "Soul Search Gu"],
	["Spring Grass Gu", "Man As Before Gu", "Third Night Watch Gu"],
	["Flash of Insight Gu", "Evil Thought Gu", "Thread Trace Gu", "Hint Gu", "Star Thought Gu"],
	["Bone Spear Gu", "Spiral Bone Spear Gu", "Flying Bone Shield Gu", "Jade Bone Gu", "Battle Bone Wheel Gu", "Bone Wings Gu", "White Bone Wheel Gu", "Turtle Jade Wolf Skin Gu"],
	["Living Steel Gu", "Iron Skin Gu", "Copper Skin Gu"],
	["Ice Crystal Gu", "Ice Explosion Gu", "Blue Bird Ice Coffin Gu", "Frost Demon Gu"],
	["Snow Crystal Formation", "Snow Wash Gu", "Ice Crystal Gu"],
	["Yin Yang Twin Cloud Gu", "Heavenly Canopy Gu"],
	["Little Light Gu", "Extreme Light Gu", "Rainbow Light Gu", "Moonglow Gu"],
	[], [],
	["Star Gate Gu", "Starlight Firefly Gu", "Star Thought Gu", "Star Nebula Cloak Gu"],
	["Leap Gu", "Position Swap Gu", "Divine Travel Gu", "Air Sack Gu"],
	[], [],
	["Luck Gaze Gu"],
	["Rule and Order Gu"],
	[], [], [], [], [],
	["Slave Gu", "Bear Enslavement Gu", "Dog Enslavement Gu"],
	["Wood Charm Gu", "Human Skin Gu", "Yin Yang Switch Gu"],
	["Charcoal Gu", "Instant Success Gu", "Hundred Battles Gu", "Living Steel Gu", "Liquor Worm", "Four Flavors Liquor Worm"],
	[],
	["Poison Breath Gu", "Poison Spit Gu", "Poison Oath Gu", "Jade Heaven Gu", "Word Eating Gu", "Snow Wash Gu", "Poison Ant Plague", "Woman's Heart Gu"],
	["Moonlight Gu", "Sword Shadow Gu", "Single Blade Gu", "Moonglow Gu"],
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
		for suf: String in [" Worm Gu", " Shield Gu", " Arrow Gu", " Spark Gu"]:
			out.append(nm + suf)
	_mgu_cache[p] = out
	return out


static func start_gu(p: int) -> String:
	return mgu(p)[0]


# ---------------- Mordzüge ----------------
const KM: Dictionary = {0: "Bear Strength Killer Move", 1: "Crescent Moon Killer Move", 2: "Sea of Fire Killer Move", 3: "Flood Dragon Killer Move", 4: "Storm Blade Killer Move",
	5: "Thunder Dragon Killer Move", 6: "Vine Prison Killer Move", 7: "Landslide Killer Move", 8: "Blood Torrent Killer Move", 9: "Soul Scream Killer Move", 10: "Time Stream Killer Move",
	11: "Star Firefly Killer Move", 12: "Bone Spear Killer Move", 14: "Ice Coffin Killer Move", 15: "Blizzard Killer Move", 17: "Light Arrow Killer Move",
	18: "Dark Limit Killer Move", 20: "Starfall Killer Move", 21: "Space Rift Killer Move", 24: "Calamity Beckoning Killer Move", 30: "Triple Qi Killer Move",
	32: "Beast Form Killer Move", 33: "Heaven Forging Killer Move", 35: "Poison Mist Killer Move", 36: "Sword Rain Killer Move", 39: "Dream Wings Killer Move",
	46: "Fate Song Killer Move", 47: "Killing Intent Killer Move"}


static func km_name(p: int) -> String:
	if KM.has(p):
		return KM[p]
	return GuData.PATH_NAME[clampi(p, 0, GuData.PATH_NAME.size() - 1)] + " Killer Move"


# ---------------- Unsterbliche Gu ----------------
## fx: Wirkung beim Besitzer. revive = jung wiedergeboren, rez = wiederbelebt, fortune = übersteht eine Drangsal,
## str/str2 = Schaden, hp = Leben, move = Tempo, life = Lebenszeit, wis/cult/dream = Kultivierung, range = Reichweite,
## fire = Brand, bolt = Blitze, luck = Dauerglück, heal = Heilung, thief = stiehlt Gu, steal = stiehlt Lebenszeit,
## stones = Ursteine fürs Dorf, refine = mehr Gu, fetus = sofort Rang 6, gen = allgemeine Macht.
const IGU: Array = [
	{"id": "spring_autumn_cicada", "n": "Spring Autumn Cicada", "r": 9, "p": 10, "fx": "revive", "d": "If the bearer dies, he is reborn young – with all his memories."},
	{"id": "wisdom_gu", "n": "Wisdom Gu", "r": 9, "p": 11, "fx": "wis", "d": "Light of wisdom: much faster cultivation."},
	{"id": "love_gu", "n": "Love Gu", "r": 9, "p": 22, "fx": "gen", "d": "Chooses its own bearer; strengthens attack and defense."},
	{"id": "sovereign_immortal_fetus", "n": "Sovereign Immortal Fetus Gu", "r": 9, "p": 29, "fx": "fetus", "d": "Single use: a rank 5 Gu Master instantly becomes a Gu Immortal."},
	{"id": "derivation_gu", "n": "Derivation Gu", "r": 9, "p": 25, "fx": "gen", "d": "Creates new offspring from the dead."},
	{"id": "hatred_gu", "n": "Hatred Gu", "r": 9, "p": 22, "fx": "str", "d": "Amplifies revenge: more damage."},
	{"id": "heavenly_secret", "n": "Heavenly Secret Gu", "r": 9, "p": 11, "fx": "wis", "d": "Uncovers heavenly secrets: faster cultivation."},
	{"id": "heavenly_web", "n": "Heavenly Net Gu", "r": 9, "p": 28, "fx": "gen", "d": "Casts an all-catching net over an area."},
	{"id": "light_gu", "n": "Light Gu", "r": 9, "p": 17, "fx": "range", "d": "Wild sun Gu: light strikes over long distances."},
	{"id": "fire_gu", "n": "Fire Gu", "r": 9, "p": 2, "fx": "fire", "d": "Wild sun Gu: every hit starts a fire."},
	{"id": "strength_gu", "n": "Strength Gu", "r": 9, "p": 0, "fx": "str2", "d": "Primordial Gu of strength: double damage."},
	{"id": "lightning_gu", "n": "Lightning Gu", "r": 9, "p": 5, "fx": "bolt", "d": "Legendary lightning storm: attacks call down lightning."},
	{"id": "advance_refinement", "n": "Advance Refinement Gu", "r": 9, "p": 33, "fx": "refine", "d": "Gu refinement succeeds more often: more Gu and progress."},
	{"id": "change_form", "n": "Change Form Gu", "r": 9, "p": 32, "fx": "hp", "d": "Transforms into beasts: much more vitality."},
	{"id": "heavenly_essence_imperial_lotus", "n": "Heavenly Essence Treasure Imperial Lotus", "r": 9, "p": 6, "fx": "stones", "d": "Permanently produces primeval stones for the bearer's village."},
	{"id": "fixed_immortal_travel", "n": "Fixed Immortal Travel Gu", "r": 8, "p": 21, "fx": "move", "d": "Instant travel: the bearer is much faster."},
	{"id": "fixed_space", "n": "Fixed Space Gu", "r": 7, "p": 21, "fx": "gen", "d": "Seals an area against escape."},
	{"id": "man_as_before", "n": "Man As Before Gu", "r": 8, "p": 10, "fx": "heal", "d": "Resets the body: heals completely when things get close."},
	{"id": "landscape_as_before", "n": "Landscape As Before Gu", "r": 8, "p": 10, "fx": "gen", "d": "Resets the terrain of an area."},
	{"id": "years_flow_like_water", "n": "Years Flow Like Water Gu", "r": 8, "p": 10, "fx": "cult", "d": "Accelerates time: twice as fast cultivation."},
	{"id": "time_anchor", "n": "Time Anchor Gu", "r": 6, "p": 10, "fx": "life", "d": "Anchors time: 400 more years of life."},
	{"id": "instant_pause", "n": "Instant Pause", "r": 6, "p": 10, "fx": "move", "d": "Briefly freezes time: the bearer acts faster."},
	{"id": "dog_shit_luck", "n": "Dog Shit Luck Gu", "r": 9, "p": 24, "fx": "luck", "d": "Permanent great luck: faster cultivation, safer breakthroughs."},
	{"id": "fortune_rivalling_heaven", "n": "Fortune Rivalling Heaven Gu", "r": 8, "p": 24, "fx": "fortune", "d": "Once: surely survives a tribulation or Heavenly Will."},
	{"id": "calamity_beckoning", "n": "Calamity Beckoning Gu", "r": 7, "p": 24, "fx": "bolt", "d": "Steers calamity onto enemies: attacks call down lightning."},
	{"id": "blood_asset", "n": "Blood Asset Gu", "r": 8, "p": 8, "fx": "str", "d": "Core of blood killer moves: more damage."},
	{"id": "blood_relation", "n": "Blood Relation Gu", "r": 8, "p": 8, "fx": "gen", "d": "Tracks down all Blood Path cultivators."},
	{"id": "mutation", "n": "Mutation Gu", "r": 8, "p": 32, "fx": "gen", "d": "Mutates targets into weaker forms."},
	{"id": "resurrection_from_the_dead", "n": "Resurrection From the Dead", "r": 8, "p": 32, "fx": "rez", "d": "Once: the bearer rises again after death."},
	{"id": "dream_token", "n": "Dream Token Gu", "r": 8, "p": 39, "fx": "dream", "d": "Rules over dreams: protects in dream realms, faster cultivation."},
	{"id": "dream_wings", "n": "Dream Wings Gu", "r": 6, "p": 39, "fx": "dream", "d": "Flies safely through dream realms and gains much insight there."},
	{"id": "dreaming_immortal", "n": "Dreaming Immortal Gu", "r": 7, "p": 39, "fx": "dream", "d": "Lives through dream lives: faster cultivation."},
	{"id": "change_soul", "n": "Change Soul Gu", "r": 7, "p": 9, "fx": "gen", "d": "Swaps souls with a target."},
	{"id": "myriad_self", "n": "Myriad Self Gu", "r": 7, "p": 29, "fx": "hp", "d": "An army of phantom copies protects the bearer."},
	{"id": "perseverance", "n": "Perseverance Gu", "r": 7, "p": 29, "fx": "hp", "d": "The bearer fights on where others give up."},
	{"id": "humility", "n": "Humility Gu", "r": 8, "p": 29, "fx": "hp", "d": "Returns damage amplified."},
	{"id": "second_aperture", "n": "Second Aperture Gu", "r": 6, "p": 29, "fx": "cult", "d": "Two apertures at once: double cultivation."},
	{"id": "strong_gu", "n": "Strong Gu", "r": 7, "p": 25, "fx": "str", "d": "Permanently strengthens the bearer's power."},
	{"id": "kill_gu", "n": "Kill Gu", "r": 8, "p": 47, "fx": "str", "d": "Attacks are optimized for pure killing."},
	{"id": "great_thief", "n": "Great Thief Gu", "r": 8, "p": 41, "fx": "thief", "d": "Steals the Gu of defeated enemies."},
	{"id": "steal_life", "n": "Steal Life Gu", "r": 8, "p": 41, "fx": "steal", "d": "Steals lifespan from defeated enemies."},
	{"id": "earth_prison", "n": "Earth Prison Gu", "r": 7, "p": 7, "fx": "gen", "d": "Locks enemies in an earth prison."},
	{"id": "gruel_mud", "n": "Gruel Mud Gu", "r": 6, "p": 7, "fx": "gen", "d": "Corrosive mud eats away entire areas."},
	{"id": "heavens_envy", "n": "Heaven's Envy Gu", "r": 7, "p": 28, "fx": "gen", "d": "Steers tribulations onto talented enemies."},
	{"id": "heavenly_birth", "n": "Heavenly Birth Gu", "r": 8, "p": 28, "fx": "heal", "d": "Strong healing when things get close."},
	{"id": "attitude_gu", "n": "Attitude Gu", "r": 8, "p": 29, "fx": "gen", "d": "Hides the bearer's true intentions."},
	{"id": "star_thought", "n": "Star Thought Gu", "r": 8, "p": 11, "fx": "wis", "d": "A starlight swarm of thoughts: faster cultivation."},
	{"id": "dark_limit", "n": "Dark Limit Gu", "r": 6, "p": 18, "fx": "gen", "d": "Blocks enemy divination."},
	{"id": "crescent_moon", "n": "Crescent Moon Gu", "r": 7, "p": 1, "fx": "range", "d": "Crescent moon blades over long distances."},
	# Rang 9: Schicksals-Gu und Gu-Häuser; Rang 10: Legenden, die nie verfeinert wurden (norand = nie zufällig)
	{"id": "fate_gu", "n": "Fate Gu", "r": 9, "p": 28, "fx": "fate", "norand": true, "d": "Tool of Heavenly Will: as long as it exists, all fates are fixed – Heavenly Will strikes harder and rank 8 barely advances. If it is destroyed, an era of chaos begins."},
	{"id": "heaven_overseeing_tower", "n": "Heaven Overseeing Tower", "r": 9, "p": 28, "fx": "tower", "d": "Gu House of Heavenly Court: watches over the whole world – long range and strong protection."},
	{"id": "blood_refinement_pool", "n": "Four Elements Square Regret Blood Refinement Pool", "r": 9, "p": 8, "fx": "pool", "d": "Gu House of the Blood Path: refines blood into power – healing, vitality and Gu refinement."},
	{"id": "star_chessboard", "n": "Star Constellation Chessboard", "r": 9, "p": 11, "fx": "chess", "d": "Gu House of Star Constellation Venerable: every move a deduction – faster cultivation and smarter attacks."},
	{"id": "destiny_gu", "n": "Destiny Gu", "r": 10, "p": 28, "fx": "destiny", "norand": true, "d": "Rank 10 legend, never refined: rewrites the bearer's fate once – up to three major ranks at once and great luck."},
	{"id": "eternal_gu", "n": "Eternal Gu", "r": 10, "p": 10, "fx": "eternal", "norand": true, "d": "Rank 10 legend, never refined: the bearer no longer ages."},
]
## Unsterbliche Gu mit eigenem Knopf (die übrigen über "Zufälliges Unsterbliches Gu").
const IGU_BTN: PackedStringArray = ["spring_autumn_cicada", "wisdom_gu", "strength_gu", "fixed_immortal_travel", "man_as_before", "time_anchor", "dog_shit_luck",
	"fortune_rivalling_heaven", "years_flow_like_water", "fire_gu", "lightning_gu", "resurrection_from_the_dead", "great_thief", "sovereign_immortal_fetus", "crescent_moon", "dream_wings"]
const FX_TEXT: Dictionary = {"revive": "Rebirth", "rez": "Resurrection", "fortune": "Tribulation ward", "str": "Damage +60%", "str2": "Damage ×2", "hp": "Life +50%",
	"move": "Speed ×1.8", "life": "+400 years", "wis": "Cultivation ×2.2", "cult": "Cultivation ×2", "dream": "Dream ward", "range": "Range +40%",
	"fire": "Burning", "bolt": "Lightning", "luck": "Lasting luck", "heal": "Healing", "thief": "Gu theft", "steal": "Life theft", "stones": "Primeval stones", "refine": "Refinement", "fetus": "Immortality", "gen": "Power +15%",
	"fate": "Fate", "tower": "Range +50%, protection", "pool": "Blood refinement", "chess": "Cultivation ×1.6", "destiny": "New destiny", "eternal": "Ageless"}

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
	{"id": "primordial_origin", "fig": "primordial_origin", "n": "Primordial Origin", "t": "Primordial Origin Immortal Venerable", "p": 30, "al": 0, "col": "#9fd8e8", "igu": "heavenly_birth", "d": "First Venerable; founded Heavenly Court.", "goal": 4, "seat": "Himmlischer Hof", "lin": "heavenly_court", "ag": "humans", "agenda": "Founds Heavenly Court in the Central Continent and helps humans rule over the variant humans."},
	{"id": "star_constellation", "fig": "star_constellation", "n": "Star Constellation", "t": "Star Constellation Immortal Venerable", "p": 11, "al": 0, "col": "#7e57c2", "igu": "star_thought", "d": "The only female Venerable; Wisdom Path.", "goal": 4, "seat": "Himmlischer Hof", "lin": "heavenly_court", "ag": "fate_guard", "agenda": "Leads Heavenly Court, guards Fate Gu, strengthens wisdom and divination and fights demonic Venerables."},
	{"id": "limitless", "fig": "limitless", "n": "Limitless", "t": "Limitless Demon Venerable", "p": 25, "al": 1, "col": "#3f51b5", "igu": "derivation_gu", "d": "Schemed across a million years; Rule Path.", "goal": 2, "seat": "Unpassierbare Dünen", "lin": "", "ag": "order", "agenda": "Schemes in seclusion in the Western Desert; rule and order reign in his domain – feuds end."},
	{"id": "reckless_savage", "fig": "reckless_savage", "n": "Reckless Savage", "t": "Reckless Savage Demon Venerable", "p": 0, "al": 1, "col": "#8d6e63", "igu": "strength_gu", "d": "Strongest body of all Venerables; Strength Path.", "goal": -1, "seat": "", "lin": "", "ag": "hunt", "agenda": "Roams the world, hunts its strongest beings and Venerables and transforms in battle."},
	{"id": "red_lotus", "fig": "red_lotus", "n": "Red Lotus", "t": "Red Lotus Demon Venerable", "p": 10, "al": 1, "col": "#d32f2f", "igu": "spring_autumn_cicada", "d": "Created Spring Autumn Cicada; Time Path.", "goal": 1, "seat": "Qing-Mao-Berg", "lin": "gu_yue_clan", "ag": "inherit", "life": 70.0, "agenda": "Ancestor of the Gu Yue Clan on Qing Mao Mountain; leaves a true inheritance there. A short, tragic life."},
	{"id": "genesis_lotus", "fig": "genesis_lotus", "n": "Genesis Lotus", "t": "Genesis Lotus Immortal Venerable", "p": 6, "al": 0, "col": "#43a047", "igu": "heavenly_essence_imperial_lotus", "d": "Founder of Heavenly Lotus Sect; Wood Path.", "goal": 4, "seat": "", "lin": "heavenly_lotus_sect", "ag": "forest", "agenda": "Founds Heavenly Lotus Sect in the Central Continent; forests spread around him."},
	{"id": "thieving_heaven", "fig": "thieving_heaven", "n": "Thieving Heaven", "t": "Thieving Heaven Demon Venerable", "p": 41, "al": 1, "col": "#455a64", "igu": "great_thief", "d": "Stole Gu from his opponents' apertures in battle.", "goal": 3, "seat": "", "lin": "fang_clan", "ag": "steal", "agenda": "Founds the Fang Clan's lineage in the Eastern Sea and steals immortal Gu from other immortals."},
	{"id": "giant_sun", "fig": "giant_sun", "n": "Giant Sun", "t": "Giant Sun Immortal Venerable", "p": 24, "al": 0, "col": "#ffc107", "igu": "dog_shit_luck", "d": "Golden-eyed giant of the Luck Path; founded Longevity Heaven.", "goal": 0, "seat": "", "lin": "huang_jin_tribes", "court": "longevity_heaven", "ag": "descend", "agenda": "Moves to the Northern Plains, founds the Huang Jin Tribe and Longevity Heaven, fathers many lucky descendants and unites the tribes under him."},
	{"id": "spectral_soul", "fig": "spectral_soul", "n": "Spectral Soul", "t": "Spectral Soul Demon Venerable", "p": 9, "al": 1, "col": "#6a1b9a", "igu": "change_soul", "d": "Cruelest Venerable; founder of Shadow Sect.", "goal": 1, "seat": "", "lin": "shadow_sect", "ag": "farm", "agenda": "Founds Shadow Sect in the Southern Border; villages in his domain grow as human farms – until he devours their souls."},
	{"id": "paradise_earth", "fig": "paradise_earth", "n": "Paradise Earth", "t": "Paradise Earth Immortal Venerable", "p": 7, "al": 0, "col": "#a1887f", "igu": "earth_prison", "d": "The peaceful one from the Southern Border; Earth Path.", "goal": 1, "seat": "", "lin": "", "ag": "bless", "agenda": "Blesses the land of the Southern Border: fertility, bloom, healing and aid for the villages."},
	{"id": "fang_yuan_venerable", "fig": "fang_yuan", "n": "Fang Yuan", "t": "Great Love Immortal Venerable", "p": 33, "al": 1, "col": "#ff7043", "igu": "advance_refinement", "d": "The eleventh Venerable; destroyed Fate Gu.", "goal": 4, "seat": "", "lin": "heaven_earth_great_love_alliance", "ag": "refine", "agenda": "Founds the Heaven Earth Great Love Alliance, refines immortal Gu and destroys Fate Gu wherever it is."},
]

## Pfad-Gruppen für die Auswahl „Höchster Großmeister / Rang 9 nach Wahl“ (alle 48 Pfade).
const PATH_GROUPS: Array = [
	["Elements", [2, 3, 4, 5, 6, 7, 13, 14, 15, 16, 17, 18, 1]],
	["Body and Life", [0, 8, 12, 32, 29, 35, 42, 43]],
	["Mind and Soul", [9, 11, 39, 40, 26, 22, 23, 45, 46, 44]],
	["Heaven and Law", [10, 21, 20, 28, 24, 25, 27, 30, 34, 19]],
	["Combat and Art", [36, 37, 38, 47, 41, 31, 33]],
]

# ---------------- Figuren ----------------
const FIG: Array = [
	{"id": "fang_yuan", "sur": "Gu Yue", "given": "Fang Yuan", "r": 1, "age": 15.0, "p": 33, "al": 1, "apt": "C", "org": "gu_yue_clan", "igu": ["spring_autumn_cicada"], "d": "Lives his second life thanks to Spring Autumn Cicada. If he dies, he is reborn young once."},
	{"id": "fang_zheng", "sur": "Gu Yue", "given": "Fang Zheng", "r": 1, "age": 15.0, "p": 8, "al": 0, "apt": "A", "org": "gu_yue_clan", "igu": [], "d": "Fang Yuan's younger brother with A-grade aptitude; Blood Path."},
	{"id": "bai_ning_bing", "sur": "Bai", "given": "Ning Bing", "r": 3, "age": 17.0, "p": 14, "al": 1, "apt": "X", "org": "bai_clan", "igu": [], "d": "Genius of the Bai Clan with the Northern Dark Ice Soul Physique."},
	{"id": "shang_xin_ci", "sur": "Shang", "given": "Xin Ci", "r": 3, "age": 20.0, "p": 45, "al": 0, "apt": "B", "org": "shang_clan", "igu": [], "d": "Leader of the Shang Clan; Information Path."},
	{"id": "hei_lou_lan", "sur": "Hei", "given": "Lou Lan", "r": 6, "age": 40.0, "p": 0, "al": 0, "apt": "A", "org": "hei_tribe", "igu": ["strong_gu"], "d": "Daughter of the Hei Tribe's chief; Strength Path immortal."},
	{"id": "tai_bai_yun_sheng", "sur": "Tai Bai", "given": "Yun Sheng", "r": 6, "age": 90.0, "p": 10, "al": 0, "apt": "B", "org": "", "igu": ["man_as_before"], "d": "Early mentor in Gu refinement; owns Man As Before Gu."},
	{"id": "feng_jin_huang", "sur": "Feng", "given": "Jin Huang", "r": 6, "age": 30.0, "p": 39, "al": 0, "apt": "X", "org": "spirit_affinity_house", "igu": ["dream_wings"], "d": "Fang Yuan's most talented rival; bearer of Dream Wings."},
	{"id": "zhao_lian_yun", "sur": "Zhao", "given": "Lian Yun", "r": 6, "age": 35.0, "p": 11, "al": 0, "apt": "B", "org": "", "igu": ["love_gu"], "d": "Bearer of Love Gu; Wisdom Path."},
	{"id": "sixth_hair", "sur": "", "given": "Sixth Hair", "race": 1, "r": 6, "age": 300.0, "p": 33, "al": 1, "apt": "B", "org": "shadow_sect", "igu": [], "d": "Refinement Path immortal of Shadow Sect (Hairy Man)."},
	{"id": "ying_wu_xie", "sur": "Ying", "given": "Wu Xie", "r": 7, "age": 200.0, "p": 9, "al": 1, "apt": "A", "org": "shadow_sect", "igu": ["fixed_immortal_travel"], "d": "Leader of Shadow Sect; Soul Path."},
	{"id": "wu_shuai", "sur": "Wu", "given": "Shuai", "r": 7, "age": 160.0, "p": 39, "al": 1, "apt": "A", "org": "", "igu": ["dream_token"], "d": "Leads the variant humans in the late war; Dream Token Gu."},
	{"id": "wu_yong", "sur": "Wu", "given": "Yong", "r": 8, "age": 400.0, "p": 4, "al": 0, "apt": "A", "org": "wu_clan", "igu": [], "d": "Supreme elder of the Wu Clan and leader of the Southern Alliance."},
	{"id": "feng_jiu_ge", "sur": "Feng", "given": "Jiu Ge", "r": 8, "age": 500.0, "p": 46, "al": 0, "apt": "A", "org": "spirit_affinity_house", "igu": [], "d": "Father of Feng Jin Huang; killer move Fate Song."},
	{"id": "duke_long", "sur": "", "given": "Duke Long", "r": 8, "age": 900.0, "p": 30, "al": 0, "apt": "A", "org": "heavenly_court", "igu": ["blood_relation"], "d": "Commander of Heavenly Court with quasi rank 9 power."},
]

# ---------------- Organisationen ----------------
## k: Sekte, Clan, Stamm, Hof, Allianz · reg: Region (-1 = überall) · al: 1 = dämonisch · lead: Rang des Gründers · g: Knopfgruppe
const ORGS: Array = [
	{"id": "heavenly_court", "n": "Heavenly Court", "gl": "天", "k": "Hof", "reg": 4, "al": 0, "col": "#e8d47a", "lead": 8, "g": 0, "d": "Most powerful organization of Gu Immortals, founded by Primordial Origin. Central Continent only."},
	{"id": "immortal_crane_sect", "n": "Immortal Crane Sect", "gl": "鹤", "k": "Sekte", "reg": 4, "al": 0, "col": "#d8e0e8", "lead": 6, "g": 0, "d": "Established power of the Central Continent."},
	{"id": "spirit_affinity_house", "n": "Spirit Affinity House", "gl": "灵", "k": "Sekte", "reg": 4, "al": 0, "col": "#5a8ae8", "lead": 6, "g": 0, "d": "Sect of Feng Jiu Ge and Feng Jin Huang."},
	{"id": "heavenly_lotus_sect", "n": "Heavenly Lotus Sect", "gl": "莲", "k": "Sekte", "reg": 4, "al": 0, "col": "#e87aa8", "lead": 6, "g": 0, "d": "Founded by Genesis Lotus."},
	{"id": "ancient_soul_sect", "n": "Ancient Soul Sect", "gl": "魂", "k": "Sekte", "reg": 4, "al": 0, "col": "#7a4ab8", "lead": 6, "g": 0, "d": "One of the Ten Great Ancient Sects."},
	{"id": "black_heaven_temple", "n": "Black Heaven Temple", "gl": "黑", "k": "Sekte", "reg": 4, "al": 0, "col": "#4a4a5a", "lead": 6, "g": 0, "d": "One of the Ten Great Ancient Sects."},
	{"id": "combat_immortal_sect", "n": "Combat Immortal Sect", "gl": "战", "k": "Sekte", "reg": 4, "al": 0, "col": "#c83a2a", "lead": 6, "g": 0, "d": "One of the Ten Great Ancient Sects."},
	{"id": "heavens_envy_manor", "n": "Heaven's Envy Manor", "gl": "妒", "k": "Sekte", "reg": 4, "al": 0, "col": "#8a2a6a", "lead": 6, "g": 0, "d": "One of the Ten Great Ancient Sects."},
	{"id": "myriad_dragon_dock", "n": "Myriad Dragon Dock", "gl": "龙", "k": "Sekte", "reg": 4, "al": 0, "col": "#2a8a6a", "lead": 6, "g": 0, "d": "One of the Ten Great Ancient Sects."},
	{"id": "spirit_butterfly_valley", "n": "Spirit Butterfly Valley", "gl": "蝶", "k": "Sekte", "reg": 4, "al": 0, "col": "#c8a0e8", "lead": 6, "g": 0, "d": "One of the Ten Great Ancient Sects."},
	{"id": "wind_cloud_manor", "n": "Wind Cloud Manor", "gl": "云", "k": "Sekte", "reg": 4, "al": 0, "col": "#7ac8c8", "lead": 6, "g": 0, "d": "One of the Ten Great Ancient Sects."},
	{"id": "lang_ya_sect", "n": "Lang Ya Sect", "gl": "琅", "k": "Sekte", "reg": -1, "al": 0, "col": "#c8a03a", "race": 1, "lead": 6, "g": 0, "d": "Sect of the Hairy Men; refined Myriad Self Gu."},
	{"id": "longevity_heaven", "n": "Longevity Heaven", "gl": "寿", "k": "Hof", "reg": -1, "al": 0, "col": "#e8b830", "lead": 7, "g": 0, "d": "Faction of Giant Sun."},
	{"id": "shadow_sect", "n": "Shadow Sect", "gl": "影", "k": "Sekte", "reg": -1, "al": 1, "col": "#4a3a5a", "lead": 6, "g": 0, "d": "Secret order made from Spectral Soul's soul fragments. Demonic."},
	{"id": "rockman_imperial_court", "n": "Stone Man Imperial Court", "gl": "岩", "k": "Hof", "reg": -1, "al": 0, "col": "#8a8478", "race": 2, "lead": 6, "g": 0, "d": "Ancient realm of the Stone Men, from which Fate Gu was stolen."},
	{"id": "dragon_palace", "n": "Dragon Palace", "gl": "宫", "k": "Hof", "reg": 3, "al": 0, "col": "#2a8a9a", "race": 6, "lead": 6, "g": 0, "d": "Seat of the Dragon Men in the Eastern Sea."},
	{"id": "wu_clan", "n": "Wu Clan", "gl": "武", "k": "Clan", "reg": 1, "al": 0, "col": "#2f6fd6", "sur": "Wu", "lead": 6, "g": 1, "d": "Overlord clan of the Southern Border."},
	{"id": "shang_clan", "n": "Shang Clan", "gl": "商", "k": "Clan", "reg": 1, "al": 0, "col": "#d18a2a", "sur": "Shang", "lead": 5, "g": 1, "d": "Richest merchant clan of the Southern Border."},
	{"id": "gu_yue_clan", "n": "Gu Yue Clan", "gl": "古", "k": "Clan", "reg": 1, "al": 0, "col": "#2f9a7a", "sur": "Gu Yue", "lead": 4, "spring": true, "g": 1, "d": "Fang Yuan's home clan on Qing Mao Mountain, with a spirit spring."},
	{"id": "bai_clan", "n": "Bai Clan", "gl": "白", "k": "Clan", "reg": 1, "al": 0, "col": "#b8c8d8", "sur": "Bai", "lead": 4, "g": 1, "d": "Bai Ning Bing's clan on Bai Gu Mountain."},
	{"id": "tie_clan", "n": "Tie Clan", "gl": "铁", "k": "Clan", "reg": 1, "al": 0, "col": "#6a6a72", "sur": "Tie", "lead": 4, "g": 1, "d": "Rival clan of the Southern Border."},
	{"id": "chi_clan", "n": "Chi Clan", "gl": "赤", "k": "Clan", "reg": 1, "al": 0, "col": "#c23a2e", "sur": "Chi", "lead": 4, "g": 1, "d": "One of the rival super clans."},
	{"id": "qing_clan", "n": "Qing Clan", "gl": "青", "k": "Clan", "reg": -1, "al": 0, "col": "#2ab8b0", "sur": "Qing", "lead": 4, "g": 1, "d": "Once owned Hatred Gu."},
	{"id": "fang_clan", "n": "Fang Clan", "gl": "方", "k": "Clan", "reg": -1, "al": 0, "col": "#8a46b8", "sur": "Fang", "lead": 4, "g": 1, "d": "Guards a true legacy of Thieving Heaven."},
	{"id": "western_desert_families", "n": "Western Desert Oasis Clans", "gl": "沙", "k": "Clan", "reg": 2, "al": 0, "col": "#d8a040", "race": 4, "lead": 4, "g": 1, "d": "Oasis clans of the Feather Men (game idea, no names in the sources)."},
	{"id": "eastern_sea_clans", "n": "Eastern Sea Island Clans", "gl": "岛", "k": "Clan", "reg": 3, "al": 0, "col": "#1f8aa0", "race": 3, "lead": 4, "g": 1, "d": "Island clans of the Eastern Sea (game idea)."},
	{"id": "hei_tribe", "n": "Hei Tribe", "gl": "黑", "k": "Stamm", "reg": 0, "al": 0, "col": "#3a3a44", "sur": "Hei", "lead": 5, "g": 2, "d": "Tribe of Hei Cheng and Hei Lou Lan."},
	{"id": "huang_jin_tribes", "n": "Huang Jin Tribes", "gl": "黄", "k": "Stamm", "reg": 0, "al": 0, "col": "#e0b020", "sur": "Huang Jin", "lead": 5, "g": 2, "d": "Coalition of golden tribes of the Northern Plains."},
	{"id": "dong_fang_tribe", "n": "Dong Fang Tribe", "gl": "东", "k": "Stamm", "reg": 0, "al": 0, "col": "#5a6ab8", "sur": "Dong Fang", "lead": 5, "g": 2, "d": "Tribe of Dong Fang Chang Fan."},
	{"id": "bai_zu_tribe", "n": "Bai Zu Tribe", "gl": "祖", "k": "Stamm", "reg": 0, "al": 0, "col": "#c8b890", "sur": "Bai Zu", "lead": 4, "g": 2, "d": "Tribe of the Northern Plains."},
	{"id": "chu_tribe", "n": "Chu Tribe", "gl": "楚", "k": "Stamm", "reg": 0, "al": 0, "col": "#b8562e", "sur": "Chu", "lead": 4, "g": 2, "d": "Tribe of the Northern Plains."},
	{"id": "chanyu_tribe", "n": "Chanyu Tribe", "gl": "单", "k": "Stamm", "reg": 0, "al": 0, "col": "#7a8a2a", "sur": "Chanyu", "lead": 4, "g": 2, "d": "Tribe of the Northern Plains."},
	{"id": "murong_tribe", "n": "Murong Tribe", "gl": "慕", "k": "Stamm", "reg": 0, "al": 0, "col": "#c9487a", "sur": "Murong", "lead": 4, "g": 2, "d": "Tribe of the Northern Plains."},
	{"id": "zombie_alliance", "n": "Zombie Alliance", "gl": "尸", "k": "Allianz", "reg": 0, "al": 1, "col": "#5a6a4a", "lead": 6, "g": 3, "d": "Cross-regional demonic alliance of zombification."},
	{"id": "southern_alliance", "n": "Southern Alliance", "gl": "南", "k": "Allianz", "reg": 1, "al": 0, "col": "#2e7a3a", "lead": 6, "g": 3, "d": "Alliance led by Wu Yong against Heavenly Court."},
	{"id": "righteous_qi_alliance", "n": "Righteous Qi Alliance", "gl": "义", "k": "Allianz", "reg": 3, "al": 0, "col": "#3a9ad8", "lead": 6, "g": 3, "d": "Union of righteous forces in the Eastern Sea."},
	{"id": "four_races_alliance", "n": "Four Races Alliance", "gl": "四", "k": "Allianz", "reg": -1, "al": 0, "col": "#9a7a4a", "race": -2, "lead": 5, "g": 3, "d": "Union of the variant humans."},
	{"id": "heaven_earth_great_love_alliance", "n": "Heaven Earth Great Love Alliance", "gl": "爱", "k": "Allianz", "reg": -1, "al": 1, "col": "#ff7043", "lead": 7, "g": 3, "d": "Fang Yuan's alliance of heaven and earth."},
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
	"blessed": {"n": "Blessed Land", "r": 18.0, "d": "Aperture of a Gu Immortal: nearby immortals cultivate twice as fast, and wild immortal Gu appear over time."},
	"grotto": {"n": "Grotto-Heaven", "r": 26.0, "d": "Aperture of rank 8 and above: triple cultivation, heavenly crystals (primeval stones) for nearby villages, its own weather."},
	"court": {"n": "Heavenly Court", "r": 36.0, "uniq": true, "d": "Grotto-Heaven of Heavenly Court with Heaven Overseeing Tower: strengthens righteous immortals and punishes demonic ones."},
	"langya": {"n": "Lang Ya Blessed Land", "r": 30.0, "uniq": true, "d": "Trading place of the land spirit: nearby Gu Masters trade Gu, villages receive primeval stones."},
	"hu": {"n": "Hu Immortal Blessed Land", "r": 20.0, "uniq": true, "lure": 70.0, "d": "Ownerless Blessed Land: a rank 5 Gu Master who reaches it takes it over and becomes immortal."},
	"imperial": {"n": "Imperial Court Blessed Land", "r": 14.0, "uniq": true, "lure": 90.0, "d": "Contested treasure land: lures Gu Masters of all clans and sparks feuds."},
	"dream": {"n": "Dream Realm", "r": 7.0, "lure": 50.0, "life": 60.0, "d": "Temporary dream zone: lures Gu Masters who gain insight inside – or suffer soul damage."},
	"inherit": {"n": "Inheritance", "r": 3.0, "lure": 55.0, "d": "Legacy of a dead immortal: whoever reaches it first gains rank and Gu – or walks into a trap."},
	"fragment": {"n": "Heaven Fragment", "r": 3.0, "lure": 90.0, "d": "Debris of a destroyed heaven: an immortal who absorbs it no longer fears tribulations, but stays bound to it forever."},
	"palace": {"n": "Dragon Palace", "r": 20.0, "uniq": true, "d": "Underwater fortress of the Dragon Men. Must stand in the sea and brings forth new Dragon Men."},
	"mushroom": {"n": "Mushroom Man Paradise", "r": 16.0, "uniq": true, "d": "Damp valley full of giant mushrooms: Mushroom Men keep emerging here."},
	"yitian": {"n": "Yi Tian Mountain", "r": 12.0, "uniq": true, "lure": 110.0, "d": "Sovereign Immortal Fetus Gu appears once on this mountain – Gu Masters fight over it."},
	"crazed": {"n": "Crazed Demon Cave", "r": 14.0, "uniq": true, "lure": 160.0, "d": "Scene of the final battles: lures immortals of rank 7 and above who duel here to the death."},
}
const PLACE_ORDER: PackedStringArray = ["blessed", "grotto", "court", "langya", "hu", "imperial", "dream", "inherit", "palace", "mushroom", "yitian", "crazed"]
const INHERIT_NAMES: PackedStringArray = ["Three Kings Inheritance", "Red Lotus Inheritance", "Blood Sea Ancestor Inheritance", "Wine Monk Inheritance", "Flower Wine Monk Inheritance", "Wisdom Immortal Inheritance", "True Yang Building"]
