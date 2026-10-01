class_name GuData
extends RefCounted
## Feste Spieldaten: Gelände, Ränge, Pfade, Völker, Tiere, Namen und Zeitalter.

const W: int = 256
const H: int = 256
const N: int = W * H

# Geländearten
const DEEP: int = 0
const SHAL: int = 1
const SAND: int = 2
const GRASS: int = 3
const STEP: int = 4
const SOIL: int = 5
const HILL: int = 6
const MOUNT: int = 7
const SNOW: int = 8
const WALL: int = 9
const ASH: int = 10
const DES: int = 11

# Objekte auf einer Kachel
const F_NONE: int = 0
const F_TREE: int = 1
const F_BAMB: int = 2
const F_PALM: int = 3
const F_PINE: int = 4
const F_ROCK: int = 5
const F_ORE: int = 6
const F_SPRING: int = 7
const F_SHRUB: int = 8
const F_TUFT: int = 9
const F_FLOWER: int = 10

const REGN: PackedStringArray = ["Nordebenen", "Südgrenze", "Westwüste", "Ostmeer", "Zentralkontinent"]
const TNAME: PackedStringArray = ["Tiefes Meer", "Seichtes Wasser", "Strand", "Grasland", "Steppe", "Erde", "Hügel", "Gebirge", "Schnee", "Regionswand", "Asche", "Wüste"]
const FNAME: PackedStringArray = ["", "Baum", "Bambus", "Palme", "Kiefer", "Fels", "Urstein-Ader", "Geisterquelle", "Strauch", "Grasbüschel", "Blume"]
const DEFH: PackedFloat32Array = [0.2, 0.34, 0.38, 0.5, 0.5, 0.5, 0.67, 0.84, 0.5, 0.5, 0.5, 0.5]

const ESS_NAME: PackedStringArray = ["", "Grüne Kupfer-Uressenz", "Rote Stahl-Uressenz", "Weiße Silber-Uressenz", "Gelbe Gold-Uressenz", "Purpurne Kristall-Uressenz", "Grüne-Traube-Unsterblichenessenz", "Rote-Dattel-Unsterblichenessenz", "Weiße-Litschi-Unsterblichenessenz", "Unsterblichenessenz (Rang 9)"]
const ESS_COL: Array[Color] = [Color.WHITE, Color("#43b38f"), Color("#d24a35"), Color("#e6eaf0"), Color("#f0c040"), Color("#a768e2"), Color("#92de5c"), Color("#c0284a"), Color("#fff1d8"), Color("#ffd24a")]
const STAGE: PackedStringArray = ["Anfangsstufe", "Mittlere Stufe", "Obere Stufe", "Gipfelstufe"]
const HP: PackedFloat32Array = [10, 22, 38, 64, 105, 170, 700, 1700, 4200, 16000]
const ATK: PackedFloat32Array = [2, 4, 7, 12, 20, 34, 160, 420, 1050, 4200]
const RNG: PackedFloat32Array = [2.2, 6, 6.8, 7.6, 8.4, 9.6, 14, 16, 18, 22]
const AOE: PackedFloat32Array = [0, 0, 0, 0, 1.6, 2.4, 4, 5.2, 6.4, 9]
const LIFEB: PackedFloat32Array = [0, 4, 8, 15, 25, 40, 300, 600, 1000, 3000]

const PATH_NAME: PackedStringArray = ["Kraft", "Mond", "Feuer", "Wasser", "Wind", "Donner", "Holz", "Erde", "Blut", "Seele", "Zeit", "Weisheit"]
const PATH_COL: Array[Color] = [Color("#d0803e"), Color("#c8e8ff"), Color("#ff7a2e"), Color("#4fb0ff"), Color("#a8f0c8"), Color("#f4e46a"), Color("#6fd24a"), Color("#caa46a"), Color("#e8303a"), Color("#b98cff"), Color("#ffb6e0"), Color("#7ef0ff")]
const REGPATH: Array = [[0, 4, 1, 5, 0], [1, 0, 6, 7, 1], [2, 7, 4, 0], [3, 5, 1, 6, 3], [11, 10, 9, 8, 1, 2, 3, 6]]
const STARTGU: PackedStringArray = ["Schwarzer-Eber-Gu", "Mondlicht-Gu", "Feuergewand-Gu", "Wasserschild-Gu", "Windklingen-Gu", "Donnerflügel-Gu", "Grünranken-Gu", "Erdkommunikations-Gu", "Blutschädel-Gu", "Seelenwurm-Gu", "Frühlingsgras-Gu", "Gedankenfunken-Gu"]
const GU_LOW: PackedStringArray = ["Weinwurm", "Jadehaut-Gu", "Kupferhaut-Gu", "Tarnschuppen-Gu", "Weißer-Eber-Gu", "Bärenkraft-Gu", "Mondsichel-Gu", "Steinhaut-Gu", "Leuchtkäfer-Gu", "Erdlausch-Gu"]
const GU_MID: PackedStringArray = ["Wasserdrachen-Gu", "Flammenzungen-Gu", "Lebensspannen-Gu", "Eisenknochen-Gu", "Weißjade-Gu", "Donnerschild-Gu", "Blutmond-Gu", "Schattenschritt-Gu", "Tausend-Klingen-Gu"]
const GU_IMM: PackedStringArray = ["Frühling-Herbst-Zikade", "Fixierte Unsterblichen-Reise", "Unsterbliches Mondlicht", "Himmelsdonner-Gu", "Blutmeer-Gu", "Sternenpfeil-Gu", "Zeitfluss-Gu", "Großes-Glück-Gu", "Weisheits-Gu", "Gesegnetes-Land-Gu"]

# Völker: Name, Haut, Haar, Lebenserwartung, HP-Faktor, Tempo, Erweckungs-Chance, schwimmt
const RACE_NAME: PackedStringArray = ["Mensch", "Haarmensch", "Steinmensch", "Fischschuppenmensch"]
const RACE_SKIN: Array[Color] = [Color("#f0c090"), Color("#9a6c44"), Color("#a8a296"), Color("#6dc0b0")]
const RACE_HAIR: Array[Color] = [Color("#3a2414"), Color("#5c3c22"), Color("#6c675f"), Color("#2d6a62")]
const RACE_LIFE: PackedFloat32Array = [68, 84, 150, 80]
const RACE_HP: PackedFloat32Array = [1.0, 1.15, 1.7, 1.0]
const RACE_SP: PackedFloat32Array = [3.4, 3.4, 2.6, 3.4]
const RACE_AWK: PackedFloat32Array = [0.3, 0.4, 0.22, 0.3]

# Tiere
const SPEC: Dictionary = {
	"deer": {"n": "Hirsch", "hp": 9.0, "atk": 0.0, "sp": 3.3, "cap": 110, "range": 2.2, "fly": false},
	"boar": {"n": "Eber", "hp": 26.0, "atk": 4.0, "sp": 2.4, "cap": 60, "range": 2.2, "fly": false},
	"wolf": {"n": "Wolf", "hp": 16.0, "atk": 4.0, "sp": 3.8, "cap": 70, "range": 2.2, "fly": false},
	"monkey": {"n": "Affe", "hp": 8.0, "atk": 1.0, "sp": 3.0, "cap": 40, "range": 2.2, "fly": false},
	"crane": {"n": "Kranich", "hp": 6.0, "atk": 1.0, "sp": 4.0, "cap": 80, "range": 2.2, "fly": true},
	"kingwolf": {"n": "Donnerkronen-Wolf", "hp": 340.0, "atk": 32.0, "sp": 3.6, "cap": 8, "range": 7.0, "fly": false},
	"ancient": {"n": "Uralte Wildbestie", "hp": 6500.0, "atk": 700.0, "sp": 2.0, "cap": 4, "range": 4.5, "fly": false},
	"wildgu": {"n": "Wilder Mondlicht-Gu", "hp": 2.0, "atk": 0.0, "sp": 1.8, "cap": 200, "range": 2.2, "fly": true},
}

# Familiennamen je Region mit Siegel-Schriftzeichen
const SURN: Array = [
	[["Ma", "马"], ["Ge", "葛"], ["Yang", "杨"], ["Huang Jin", "黄"], ["Liu", "柳"], ["Nu Er", "奴"], ["Bao", "包"], ["Che", "车"], ["Wang", "王"]],
	[["Gu Yue", "古"], ["Bai", "白"], ["Xiong", "熊"], ["Tie", "铁"], ["Shang", "商"], ["Wu", "武"], ["Chi", "赤"], ["Mo", "莫"], ["Jia", "贾"]],
	[["Lu", "陆"], ["Qing", "青"], ["Ke", "柯"], ["Shi", "石"], ["Lin", "林"], ["Hu", "胡"], ["Zhou", "周"]],
	[["Shen", "沈"], ["Ye", "叶"], ["Chen", "陈"], ["Song", "宋"], ["Lan", "兰"], ["Feng", "风"]],
	[["Himmelskranich", "鹤"], ["Geistaffinitäts", "灵"], ["Xuan-Yuan", "轩"], ["Sternenpalast", "星"], ["Mondfluss", "河"], ["Wolkenschwert", "剑"], ["Jadequell", "玉"], ["Reinlotus", "莲"]],
]
const GIVEN: PackedStringArray = ["Fang", "Yuan", "Zheng", "Wei", "Bao", "Ling", "Shu", "Qing", "Hua", "Mo", "Chen", "Jiang", "Tai", "Li", "Yun", "Feng", "Shan", "Zi", "Lan", "Hai", "Ming", "Xue", "Kong", "Jing", "Rou", "Tian", "Hong", "Ying", "Long", "Hu", "Ning", "Bing", "Yao", "Shi", "Xia", "Gang", "Lei", "Ye", "Su", "Mei"]
const VPRE: PackedStringArray = ["Grünbambus", "Mondlicht", "Weißjade", "Eisenfels", "Rotlotus", "Donner", "Silbernebel", "Kranich", "Kiefern", "Wolfs", "Drachen", "Schwarzeber", "Jadequell", "Herbstblatt", "Sternfall", "Wolken", "Bärenpfad", "Schneelotus", "Feuerkrähen", "Tausendfluss", "Lanzen", "Nebel", "Tigerkopf", "Goldsand", "Perlmuschel"]
const VSUF: PackedStringArray = ["-Berg", "-Tal", "-Dorf", "-Gipfel", "-Hain", "-Quelle", "-Furt", "-Hang", "-Oase", "-Bucht"]
const CLANCOL: Array[Color] = [Color("#2f6fd6"), Color("#c23a2e"), Color("#2f9a7a"), Color("#d18a2a"), Color("#8a46b8"), Color("#1f8aa0"), Color("#b8562e"), Color("#c9487a"), Color("#7a8a2a"), Color("#5a6ab8"), Color("#8a2a5a"), Color("#c9a83a"), Color("#2e7a3a"), Color("#d86a5a"), Color("#2ab8b0"), Color("#6a3ab8")]

# Gebäude: Grundfläche in Kacheln und Haltbarkeit
const BSIZE: Dictionary = {"hall": Vector2i(7, 4), "house": Vector2i(7, 3), "farm": Vector2i(15, 11), "forge": Vector2i(7, 3), "tower": Vector2i(5, 2)}
const BHP: Dictionary = {"hall": 260.0, "house": 80.0, "farm": 50.0, "forge": 110.0, "tower": 150.0}

const MAXU: int = 1600

# Zehn Zeitalter wie in WorldBox – jedes ändert Fruchtbarkeit, Kriegslust und Kultivierung.
# n, Wachstum, Kriegslust, Kultivierung, Tönung
const AGES: Array = [
	{"n": "Zeitalter der Hoffnung", "grow": 1.25, "war": 0.6, "cult": 1.0, "tint": Color(1, 1, 1, 0)},
	{"n": "Zeitalter der Sonne", "grow": 1.4, "war": 0.8, "cult": 1.0, "tint": Color(1.0, 0.85, 0.4, 0.07)},
	{"n": "Zeitalter der Dunkelheit", "grow": 0.8, "war": 1.5, "cult": 0.9, "tint": Color(0.05, 0.05, 0.2, 0.28)},
	{"n": "Zeitalter der Tränen", "grow": 1.1, "war": 1.0, "cult": 1.0, "tint": Color(0.2, 0.3, 0.6, 0.12)},
	{"n": "Zeitalter des Mondes", "grow": 1.0, "war": 0.9, "cult": 1.6, "tint": Color(0.5, 0.6, 1.0, 0.14)},
	{"n": "Zeitalter des Chaos", "grow": 0.9, "war": 2.4, "cult": 1.1, "tint": Color(0.7, 0.1, 0.1, 0.12)},
	{"n": "Zeitalter der Wunder", "grow": 1.2, "war": 0.7, "cult": 2.0, "tint": Color(0.9, 0.5, 1.0, 0.1)},
	{"n": "Zeitalter des Eises", "grow": 0.6, "war": 0.9, "cult": 1.0, "tint": Color(0.75, 0.9, 1.0, 0.18)},
	{"n": "Zeitalter der Asche", "grow": 0.7, "war": 1.4, "cult": 1.0, "tint": Color(0.35, 0.2, 0.1, 0.18)},
	{"n": "Zeitalter der Verzweiflung", "grow": 0.5, "war": 1.8, "cult": 0.8, "tint": Color(0.1, 0.0, 0.05, 0.3)},
]
const AGE_YEARS: int = 40

const TREEPAL: Array = [
	["#7cb048", "#4e8a32", "#2f5a24"], ["#cbb752", "#a6983c", "#625c30"],
	["#d2a04c", "#a8762e", "#664828"], ["#5e9a48", "#3c7a36", "#24502a"], ["#b8c45a", "#93a83e", "#5a6c30"]]

const GRASSP: Array = [
	[Color8(150, 156, 72), Color8(140, 148, 66), Color8(160, 164, 80)],
	[Color8(70, 126, 44), Color8(64, 118, 41), Color8(76, 132, 46)],
	[Color8(80, 136, 48), Color8(74, 128, 44), Color8(86, 142, 50)],
	[Color8(87, 142, 50), Color8(80, 134, 47), Color8(92, 148, 54)],
	[Color8(76, 132, 46), Color8(70, 124, 43), Color8(82, 138, 48)]]
const PAL: Dictionary = {
	SAND: [Color8(226, 220, 156), Color8(218, 212, 148), Color8(232, 226, 166)],
	STEP: [Color8(150, 156, 72), Color8(140, 148, 66), Color8(160, 164, 80)],
	SNOW: [Color8(228, 236, 240), Color8(216, 226, 234), Color8(238, 244, 246)],
	DES: [Color8(224, 198, 118), Color8(214, 188, 110), Color8(232, 208, 128)],
	SOIL: [Color8(132, 100, 62), Color8(122, 92, 56), Color8(142, 108, 68)],
	ASH: [Color8(64, 58, 56), Color8(56, 50, 48), Color8(74, 68, 64)],
	HILL: [Color8(62, 70, 64), Color8(58, 66, 60), Color8(66, 74, 68)],
	MOUNT: [Color8(46, 48, 50), Color8(42, 44, 46), Color8(52, 54, 56)],
}

const KCOL: Dictionary = {"info": Color("#e8c70a"), "war": Color("#ff7a5a"), "gold": Color("#ffd23a"), "jade": Color("#62d8a4"), "red": Color("#ff6a6a"), "violet": Color("#c8a0ff")}


static func rank_title(r: int) -> String:
	if r == 0:
		return "Sterblicher"
	if r <= 5:
		return "Rang %d Gu-Meister" % r
	if r <= 8:
		return "Rang %d Gu-Unsterblicher" % r
	return "Rang 9 Ehrwürdiger"


static func is_tree(f: int) -> bool:
	return f >= 1 and f <= 4


static func is_water(t: int) -> bool:
	return t == DEEP or t == SHAL


static func is_land(t: int) -> bool:
	return t != DEEP and t != SHAL


static func buildable(t: int) -> bool:
	return t == SAND or t == GRASS or t == STEP or t == SOIL or t == SNOW or t == ASH or t == DES


## Schneller ganzzahliger Hash für Zufallsmuster, Ergebnis 0..1.
static func hash2(x: int, y: int, s: int) -> float:
	var h: int = (x * 374761393) ^ (y * 668265263) ^ (s * 1442695041)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(h & 0xFFFFFF) / 16777216.0
