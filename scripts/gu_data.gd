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
const LAVA: int = 12   # Erdfeuer-Lava (fließt, kühlt zu Fels ab); hinten angehängt wegen alter Spielstände

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
const F_ROAD: int = 11   # Straße zwischen Dörfern eines Clans

const REGN: PackedStringArray = ["Nordebenen", "Südgrenze", "Westwüste", "Ostmeer", "Zentralkontinent"]
const REGN_IN: PackedStringArray = ["die Nordebenen", "die Südgrenze", "die Westwüste", "das Ostmeer", "den Zentralkontinent"]
const REGN_DAT: PackedStringArray = ["den Nordebenen", "der Südgrenze", "der Westwüste", "dem Ostmeer", "dem Zentralkontinent"]
const TNAME: PackedStringArray = ["Tiefes Meer", "Seichtes Wasser", "Strand", "Grasland", "Steppe", "Erde", "Hügel", "Gebirge", "Schnee", "Regionswand", "Asche", "Wüste", "Lava"]
const FNAME: PackedStringArray = ["", "Baum", "Bambus", "Palme", "Kiefer", "Fels", "Urstein-Ader", "Geisterquelle", "Strauch", "Grasbüschel", "Blume", "Straße"]
const DEFH: PackedFloat32Array = [0.2, 0.34, 0.38, 0.5, 0.5, 0.5, 0.67, 0.84, 0.5, 0.5, 0.5, 0.5, 0.6]

const ESS_NAME: PackedStringArray = ["", "Grüne Kupfer-Uressenz", "Rote Stahl-Uressenz", "Weiße Silber-Uressenz", "Gelbe Gold-Uressenz", "Purpurne Kristall-Uressenz", "Grüne-Traube-Unsterblichenessenz", "Rote-Dattel-Unsterblichenessenz", "Weiße-Litschi-Unsterblichenessenz", "Unsterblichenessenz (Rang 9)"]
const ESS_COL: Array[Color] = [Color.WHITE, Color("#43b38f"), Color("#d24a35"), Color("#e6eaf0"), Color("#f0c040"), Color("#a768e2"), Color("#92de5c"), Color("#c0284a"), Color("#fff1d8"), Color("#ffd24a")]
const STAGE: PackedStringArray = ["Anfangsstufe", "Mittlere Stufe", "Obere Stufe", "Gipfelstufe"]
const HP: PackedFloat32Array = [10, 22, 38, 64, 105, 170, 700, 1700, 4200, 16000]
const ATK: PackedFloat32Array = [2, 4, 7, 12, 20, 34, 160, 420, 1050, 4200]
const RNG: PackedFloat32Array = [2.2, 6, 6.8, 7.6, 8.4, 9.6, 14, 16, 18, 22]
const AOE: PackedFloat32Array = [0, 0, 0, 0, 1.6, 2.4, 4, 5.2, 6.4, 9]
const LIFEB: PackedFloat32Array = [0, 4, 8, 15, 25, 40, 300, 600, 1000, 3000]

# Pfade: Ids 0..11 bleiben für alte Spielstände gleich, danach die übrigen Pfade aus der Enzyklopädie.
const PATH_NAME: PackedStringArray = ["Kraft", "Mond", "Feuer", "Wasser", "Wind", "Donner", "Holz", "Erde", "Blut", "Seele", "Zeit", "Weisheit",
	"Knochen", "Metall", "Eis", "Schnee", "Wolken", "Licht", "Dunkel", "Schatten", "Sternen", "Raum", "Gefühls", "Bezauberungs",
	"Glücks", "Regel", "Phantom", "Beschränkungs", "Himmels", "Menschen", "Qi", "Versklavungs", "Verwandlungs", "Verfeinerungs",
	"Formations", "Gift", "Schwert", "Klingen", "Waffen", "Traum", "Illusions", "Diebstahl", "Speise", "Pillen", "Mal", "Informations", "Klang", "Tötungs"]
const PATH_COL: Array[Color] = [Color("#d0803e"), Color("#c8e8ff"), Color("#ff7a2e"), Color("#4fb0ff"), Color("#a8f0c8"), Color("#f4e46a"), Color("#6fd24a"), Color("#caa46a"), Color("#e8303a"), Color("#b98cff"), Color("#ffb6e0"), Color("#7ef0ff"),
	Color("#e6dcc3"), Color("#b0bec5"), Color("#81d4fa"), Color("#f5faff"), Color("#cfd8dc"), Color("#fff59d"), Color("#6a4ad0"), Color("#7a7a8a"), Color("#7c8be0"), Color("#7c4dff"), Color("#ec407a"), Color("#f48fb1"),
	Color("#ffd54f"), Color("#5c6fe0"), Color("#b39ddb"), Color("#8a6a5a"), Color("#e3f2fd"), Color("#ffccbc"), Color("#80deea"), Color("#a07a60"), Color("#9ccc65"), Color("#ff7043"),
	Color("#26a69a"), Color("#7cb342"), Color("#90a4ae"), Color("#78909c"), Color("#7d97a6"), Color("#ce93d8"), Color("#ba68c8"), Color("#5a6a74"), Color("#ffb74d"), Color("#aed581"), Color("#f06292"), Color("#4db6ac"), Color("#ffab91"), Color("#d03030")]
## Pfad-Id aus den englischen Ids der Inhaltsdaten.
const PATH_ID: Dictionary = {"strength": 0, "moon": 1, "fire": 2, "water": 3, "wind": 4, "lightning": 5, "wood": 6, "earth": 7, "blood": 8, "soul": 9, "time": 10, "wisdom": 11,
	"bone": 12, "metal": 13, "ice": 14, "snow": 15, "cloud": 16, "light": 17, "dark": 18, "shadow": 19, "star": 20, "space": 21, "emotion": 22, "enchantment": 23,
	"luck": 24, "rule": 25, "phantom": 26, "restriction": 27, "heaven": 28, "human": 29, "qi": 30, "enslavement": 31, "transformation": 32, "refinement": 33,
	"formation": 34, "poison": 35, "sword": 36, "blade": 37, "weapon": 38, "dream": 39, "illusion": 40, "theft": 41, "food": 42, "pill": 43, "painting": 44, "information": 45, "sound": 46, "killing": 47}
const REGPATH: Array = [[0, 4, 1, 5, 0, 14, 15, 31, 20, 24, 18], [1, 0, 6, 7, 1, 8, 35, 12, 33, 9, 46], [2, 7, 4, 0, 13, 21, 42, 19], [3, 5, 1, 6, 3, 16, 32, 39, 37],
	[11, 10, 9, 8, 1, 2, 3, 6, 17, 36, 34, 25, 30, 28, 20, 21, 43, 44, 45, 22, 26]]
const GU_LOW: PackedStringArray = ["Weinwurm", "Jadehaut-Gu", "Kupferhaut-Gu", "Tarnschuppen-Gu", "Weißer-Eber-Gu", "Bärenkraft-Gu", "Mondsichel-Gu", "Steinhaut-Gu", "Leuchtkäfer-Gu", "Erdlausch-Gu"]
const GU_MID: PackedStringArray = ["Wasserdrachen-Gu", "Flammenzungen-Gu", "Lebensspannen-Gu", "Eisenknochen-Gu", "Weißjade-Gu", "Donnerschild-Gu", "Blutmond-Gu", "Schattenschritt-Gu", "Tausend-Klingen-Gu"]

# Völker: Ids 0..3 wie bisher, danach die Variant-Menschen der Enzyklopädie.
const RACE_NAME: PackedStringArray = ["Mensch", "Haarmensch", "Steinmensch", "Fischschuppenmensch", "Federmensch", "Schneemensch", "Drachenmensch", "Tiermensch", "Pilzmensch", "Schlammmensch", "Holzmensch"]
const RACE_PL: PackedStringArray = ["Menschen", "Haarmenschen", "Steinmenschen", "Fischschuppenmenschen", "Federmenschen", "Schneemenschen", "Drachenmenschen", "Tiermenschen", "Pilzmenschen", "Schlammmenschen", "Holzmenschen"]
const RACE_SKIN: Array[Color] = [Color("#f0c090"), Color("#9a6c44"), Color("#a8a296"), Color("#6dc0b0"), Color("#eac08c"), Color("#e4eef6"), Color("#5ea884"), Color("#b4844e"), Color("#ecdcc0"), Color("#8a7052"), Color("#9a7448")]
const RACE_HAIR: Array[Color] = [Color("#3a2414"), Color("#5c3c22"), Color("#6c675f"), Color("#2d6a62"), Color("#d8502a"), Color("#fbfdff"), Color("#2a5a44"), Color("#5a3818"), Color("#d83a2a"), Color("#5a4630"), Color("#4ea83a")]
const RACE_LIFE: PackedFloat32Array = [68, 84, 150, 80, 72, 90, 160, 60, 45, 70, 220]
const RACE_HP: PackedFloat32Array = [1.0, 1.15, 1.7, 1.0, 0.85, 1.1, 1.35, 1.4, 0.8, 1.05, 1.3]
const RACE_ATK: PackedFloat32Array = [1.0, 1.12, 1.0, 1.0, 1.0, 1.0, 1.15, 1.3, 0.9, 1.0, 1.0]
const RACE_SP: PackedFloat32Array = [3.4, 3.4, 2.6, 3.4, 4.2, 3.4, 3.2, 4.0, 3.0, 3.0, 2.6]
const RACE_AWK: PackedFloat32Array = [0.3, 0.4, 0.22, 0.3, 0.3, 0.28, 0.35, 0.25, 0.2, 0.25, 0.25]
const RACE_GROW: PackedFloat32Array = [1.0, 1.0, 0.8, 1.0, 1.0, 0.9, 0.8, 1.0, 1.7, 1.1, 0.7]
const RACE_SWIM: Array[bool] = [false, false, false, true, false, false, true, false, false, false, false]
const RACE_FLY: Array[bool] = [false, false, false, false, true, false, false, false, false, false, false]
## Heimatregion (-1 = überall)
const RACE_REG: PackedInt32Array = [-1, 1, 1, 3, 2, 0, 3, -1, 1, 1, 1]
## Bevorzugte Pfade beim Erwecken (zur Hälfte statt des Regionspfads)
const RACE_PATHS: Array = [[], [33, 6], [7, 12], [3, 16], [4, 21], [14, 15], [3, 32], [0, 32], [35, 6], [7, 35], [6, 34]]
const RACE_TRAIT: PackedStringArray = [
	"Ausgewogen und anpassungsfähig – als einzige Rasse fähig, Ehrwürdiger zu werden.",
	"Begabte Gu-Veredler: Wilde Gu bringen ihnen mehr Fortschritt.",
	"Zäh und langlebig, aber langsam; im Gebirge kaum gebremst.",
	"Schwimmen frei durch tiefes Wasser.",
	"Fliegen mit Federschwingen über Land und Wasser; schnell in der Wüste.",
	"Kältefest: Schnee und Eiszeit bremsen sie nicht.",
	"Schwimmen, zäh und schlagkräftig; Wasser- und Verwandlungspfad.",
	"Ausgestorbene Urrasse: stark und schnell, aber kurzlebig.",
	"Wachsen in feuchten Tälern schnell nach, leben aber kurz.",
	"Verbergen sich im Schlamm: Sumpf und Erde bremsen sie nicht.",
	"Baumartig und sehr langlebig; heilen im Wald."]
## Familiennamen und Siegel der Variant-Menschen (für Clans und Kinder)
const RACE_SUR: Array = [[], [["Mao", "毛"], ["Fa", "发"], ["Rong", "绒"]], [["Yan", "岩"], ["Shi", "石"], ["Kuang", "矿"]], [["Yu", "鱼"], ["Lin", "鳞"], ["Hai", "海"]],
	[["Yu", "羽"], ["Ling", "翎"], ["He", "翮"]], [["Xue", "雪"], ["Bing", "冰"], ["Shuang", "霜"]], [["Long", "龙"], ["Ao", "敖"], ["Jiao", "蛟"]],
	[["Shou", "兽"], ["Hu", "虎"], ["Lang", "狼"]], [["Gu", "菇"], ["Jun", "菌"], ["Mo", "蘑"]], [["Ni", "泥"], ["Zhao", "沼"], ["Tu", "土"]], [["Mu", "木"], ["Shu", "树"], ["Song", "松"]]]
const RACE_CLAN: PackedStringArray = ["", "", "", "", "Federstamm", "Schneestamm", "Drachenclan", "Tierstamm", "Pilzsippe", "Schlammsippe", "Holzsippe"]
const RACE_VPRE: Array = [[], [], ["Granit", "Felsherz", "Basalt"], ["Muschel", "Korallen", "Gezeiten"], ["Federwind", "Sandflügel", "Falken"], ["Frostzahn", "Eisheim", "Weißwind"],
	["Drachenperl", "Schuppen", "Tiefsee"], ["Krallen", "Mähnen", "Reißzahn"], ["Pilzhut", "Sporen", "Moderlicht"], ["Schlick", "Moor", "Brackwasser"], ["Rindenherz", "Wurzel", "Moosbart"]]

# Tiere und Bestien. beh: Verhalten (B_*), tier: Rang-Äquivalent (0 = Wildtier, 3..8 Bestienkönige und Ödbestien),
# arch: Körperbau für Sprites.draw_animal, cols: Hauptfarbe, Licht, Akzent, ss: Größe, fol/foln: Gefolge, pc: Geschossfarbe.
const B_PREY: int = 0
const B_BOAR: int = 1
const B_PRED: int = 2
const B_KING: int = 3
const B_GU: int = 4
const B_IGU: int = 5
const B_SHY: int = 6
const SPEC: Dictionary = {
	"deer": {"n": "Hirsch", "hp": 9.0, "atk": 0.0, "sp": 3.3, "cap": 110, "range": 2.2, "fly": false, "beh": B_PREY, "arch": "deer"},
	"boar": {"n": "Eber", "hp": 26.0, "atk": 4.0, "sp": 2.4, "cap": 60, "range": 2.2, "fly": false, "beh": B_BOAR, "arch": "boar", "cols": ["#4a3324", "#6a4a32", "#f0e6d0"]},
	"wolf": {"n": "Wolf", "hp": 16.0, "atk": 4.0, "sp": 3.8, "cap": 70, "range": 2.2, "fly": false, "beh": B_PRED, "arch": "wolf", "cols": ["#80848a", "#a4aab0", "#4e5256"]},
	"monkey": {"n": "Affe", "hp": 8.0, "atk": 1.0, "sp": 3.0, "cap": 40, "range": 2.2, "fly": false, "beh": B_SHY, "arch": "monkey", "cols": ["#7a5530", "#8a6540", "#e0b890"]},
	"crane": {"n": "Kranich", "hp": 6.0, "atk": 1.0, "sp": 4.0, "cap": 80, "range": 2.2, "fly": true, "beh": B_SHY, "arch": "crane"},
	"kingwolf": {"n": "Donnerkronen-Wolf", "hp": 340.0, "atk": 32.0, "sp": 3.6, "cap": 8, "range": 7.0, "fly": false, "beh": B_KING, "tier": 4, "arch": "wolf", "cols": ["#c4d2e6", "#e2ecf8", "#8a9ab0"], "ss": 1.8, "crown": true, "fol": "wolf", "foln": 5, "pc": "#fff27a", "d": "Tausend-Bestien-König, der mit Blitzen angreift und Wolfsfluten anführt."},
	"ancient": {"n": "Uralte Ödbestie", "hp": 6500.0, "atk": 700.0, "sp": 2.0, "cap": 4, "range": 4.5, "fly": false, "beh": B_KING, "tier": 7, "arch": "ancient", "ss": 3.0, "aoe": 3.5, "d": "Stark wie ein Rang-7-Unsterblicher. Revierbestie, zertrampelt Dörfer."},
	"wildgu": {"n": "Wilder Gu", "hp": 2.0, "atk": 0.0, "sp": 1.8, "cap": 200, "range": 2.2, "fly": true, "beh": B_GU, "arch": "gu"},
	"wildimm": {"n": "Wildes Unsterbliches Gu", "hp": 40.0, "atk": 0.0, "sp": 2.6, "cap": 30, "range": 2.2, "fly": true, "beh": B_IGU, "arch": "igu"},
	"bk100": {"n": "Hundert-Bestien-König", "hp": 192.0, "atk": 15.0, "sp": 3.8, "cap": 10, "range": 2.2, "fly": false, "beh": B_KING, "tier": 3, "arch": "tiger", "cols": ["#e0882a", "#f8e8c8", "#2a1a10"], "ss": 1.5, "crown": true, "fol": "wolf", "foln": 4, "d": "Bestienkönig (Rang 3) mit einem Rudel von etwa hundert Tieren."},
	"bk10000": {"n": "Zehntausend-Bestien-König", "hp": 510.0, "atk": 42.0, "sp": 3.0, "cap": 6, "range": 2.4, "fly": false, "beh": B_KING, "tier": 5, "arch": "bear", "cols": ["#5a3a24", "#8a6040", "#ffd24a"], "ss": 2.0, "crown": true, "aoe": 1.5, "fol": "wolf", "foln": 8, "d": "Bestienkönig (Rang 5) – eine Bedrohung für ganze Clans."},
	"desolate": {"n": "Ödbestie", "hp": 2100.0, "atk": 200.0, "sp": 2.6, "cap": 6, "range": 2.8, "fly": false, "beh": B_KING, "tier": 6, "arch": "horned", "cols": ["#5a3a6a", "#9a6aaa", "#ffcf3a"], "ss": 2.4, "aoe": 3.0, "d": "Rang-6-Äquivalent. Revierbestie, trägt oft ein wildes Unsterbliches Gu."},
	"remote": {"n": "Urzeitliche Ödbestie", "hp": 12600.0, "atk": 1310.0, "sp": 1.8, "cap": 3, "range": 5.0, "fly": false, "beh": B_KING, "tier": 8, "arch": "behemoth", "cols": ["#2a2a30", "#ff5a1a", "#e8d8b0"], "ss": 3.4, "aoe": 5.0, "pc": "#ff7a2a", "d": "Rang-8-Äquivalent, kann ganze Regionen verwüsten."},
	"white_boar": {"n": "Weißer Eber", "hp": 40.0, "atk": 6.0, "sp": 2.6, "cap": 30, "range": 2.2, "fly": false, "beh": B_BOAR, "arch": "boar", "cols": ["#edede6", "#b9a89a", "#6b4f3f"], "ss": 1.1, "reg": 1, "gu": "Weißer-Eber-Gu", "d": "Wildeber der Berge; seine Jagd liefert das Weißer-Eber-Gu."},
	"black_boar": {"n": "Schwarzer Eber", "hp": 44.0, "atk": 7.0, "sp": 2.6, "cap": 30, "range": 2.2, "fly": false, "beh": B_BOAR, "arch": "boar", "cols": ["#2b2b2b", "#5a4636", "#c9b79c"], "ss": 1.1, "reg": 1, "gu": "Schwarzer-Eber-Gu", "d": "Dunkle Ebervariante; Quelle des Schwarzer-Eber-Gu."},
	"lightning_wolf": {"n": "Blitzwolf", "hp": 22.0, "atk": 6.0, "sp": 4.2, "cap": 40, "range": 5.0, "fly": false, "beh": B_PRED, "arch": "wolf", "cols": ["#5c6b8a", "#c9d6f2", "#ffe45c"], "pc": "#ffe45c", "reg": 1, "d": "Rudeltier mit Blitzkraft; Rudel bedrohen Clandörfer."},
	"stone_monkey_king": {"n": "Steinaffenkönig", "hp": 200.0, "atk": 15.0, "sp": 3.2, "cap": 4, "range": 2.2, "fly": false, "beh": B_KING, "tier": 3, "arch": "monkey", "cols": ["#8a8a82", "#5e5a52", "#d1c7a0"], "ss": 1.7, "crown": true, "fol": "monkey", "foln": 6, "reg": 1, "gu": "Tarnfels-Gu", "d": "Affenkönig der Felsen; von ihm stammt das Tarnfels-Gu."},
	"crocodile_king": {"n": "Krokodilkönig", "hp": 360.0, "atk": 28.0, "sp": 2.6, "cap": 4, "range": 2.4, "fly": false, "swim": true, "beh": B_KING, "tier": 4, "arch": "croc", "cols": ["#4e6b3a", "#2f4024", "#d8cfa0"], "ss": 1.9, "reg": 1, "gu": "Krokodilkraft-Gu", "d": "Riesenkrokodil der Flüsse; liefert Krokodilkraft- und Panzer-Gu."},
	"turtle_jade_wolf": {"n": "Schildkrötenjadewolf", "hp": 600.0, "atk": 40.0, "sp": 3.2, "cap": 4, "range": 2.4, "fly": false, "beh": B_KING, "tier": 5, "arch": "wolf", "cols": ["#4f8f7a", "#e0e6d8", "#2f5a4c"], "ss": 2.2, "crown": true, "shell": true, "aoe": 1.5, "fol": "wolf", "foln": 8, "reg": 0, "gu": "Schildkrötenjade-Wolfshaut-Gu", "d": "Wolfsherrscher mit Panzerhaut (Zehntausend-Bestien-König)."},
	"earth_chief": {"n": "Erdhäuptling", "hp": 330.0, "atk": 26.0, "sp": 2.4, "cap": 4, "range": 2.4, "fly": false, "beh": B_KING, "tier": 4, "arch": "horned", "cols": ["#7a5c3a", "#b89b6e", "#4a3826"], "ss": 1.8, "reg": 1, "gu": "Erdhäuptling-Zombie-Gu", "d": "Erdbestie; ihre Jagd liefert das Erdhäuptling-Zombie-Gu."},
	"thousand_li_earthwolf_spider": {"n": "Tausend-Li-Erdwolfspinne", "hp": 30.0, "atk": 8.0, "sp": 4.6, "cap": 20, "range": 2.2, "fly": false, "beh": B_PRED, "arch": "spider", "cols": ["#5b4630", "#c49a5a", "#2e2418"], "ss": 1.4, "reg": 1, "d": "Grabende Spinne, die blitzschnell Tunnel durch die Erde zieht."},
	"flying_bear": {"n": "Flugbär", "hp": 2100.0, "atk": 200.0, "sp": 3.4, "cap": 3, "range": 2.6, "fly": true, "beh": B_KING, "tier": 6, "arch": "bear", "cols": ["#6b4a2e", "#c9a27a", "#f1e2c8"], "ss": 2.4, "wings": true, "aoe": 3.0, "reg": 0, "d": "Geflügelter Ödbär; Vorbild für das Flugbärkraft-Gu."},
	"star_desolate_hound": {"n": "Sternen-Ödhund", "hp": 1900.0, "atk": 220.0, "sp": 4.4, "cap": 3, "range": 2.6, "fly": false, "beh": B_KING, "tier": 6, "arch": "wolf", "cols": ["#1e2a5a", "#8fa8ff", "#ffffff"], "ss": 2.2, "stars": true, "aoe": 3.0, "reg": 4, "d": "Sternenhafter Jagdhund des Zentralkontinents."},
	"wailing_whale": {"n": "Heulwal", "hp": 3200.0, "atk": 160.0, "sp": 2.2, "cap": 3, "range": 3.0, "fly": false, "swim": true, "aqua": true, "beh": B_KING, "tier": 6, "arch": "whale", "cols": ["#2c4a6b", "#7fa3c4", "#e8f1f7"], "ss": 3.0, "aoe": 3.0, "reg": 3, "d": "Gigantischer Meereswal; lebt nur im Wasser."},
	"iron_crown_eagle": {"n": "Eisenkronenadler", "hp": 1600.0, "atk": 230.0, "sp": 5.0, "cap": 3, "range": 2.6, "fly": true, "beh": B_KING, "tier": 6, "arch": "eagle", "cols": ["#5a5a5a", "#b0b0b0", "#e0a030"], "ss": 2.2, "crown": true, "aoe": 3.0, "reg": 0, "d": "Raubadler mit Eisenkrone aus den Nordebenen."},
	"peach_wolf": {"n": "Pfirsichwolf", "hp": 510.0, "atk": 42.0, "sp": 3.6, "cap": 4, "range": 2.4, "fly": false, "beh": B_KING, "tier": 5, "arch": "wolf", "cols": ["#e8a0a0", "#fff0e8", "#b85c6a"], "ss": 2.1, "crown": true, "aoe": 1.5, "fol": "wolf", "foln": 8, "reg": 0, "d": "Rosafarbener Wolfskönig (Zehntausend-Bestien-König)."},
	"qi_grand_lion": {"n": "Qi-Großlöwe", "hp": 2300.0, "atk": 210.0, "sp": 3.4, "cap": 3, "range": 6.0, "fly": false, "beh": B_KING, "tier": 6, "arch": "lion", "cols": ["#d9b14a", "#8fd3e0", "#6a4a1e"], "ss": 2.4, "aoe": 3.0, "pc": "#8fd3e0", "reg": 4, "d": "Löwe aus verdichtetem Qi; brüllt Qi-Stöße."},
	"dragon": {"n": "Drache", "hp": 13000.0, "atk": 1300.0, "sp": 3.0, "cap": 2, "range": 10.0, "fly": true, "swim": true, "beh": B_KING, "tier": 8, "arch": "dragon", "cols": ["#2e8b57", "#d4af37", "#0f3d2e"], "ss": 3.2, "aoe": 5.0, "pc": "#ffb030", "reg": 3, "d": "Mythische Drachenbestie (Urzeitliche Ödbestie); speit Feuer."},
	"divination_tortoise": {"n": "Orakelschildkröte", "hp": 7000.0, "atk": 380.0, "sp": 1.4, "cap": 2, "range": 3.0, "fly": false, "swim": true, "beh": B_KING, "tier": 7, "arch": "turtle", "cols": ["#4a6b3a", "#c2b280", "#2f3a2a"], "ss": 2.8, "aoe": 3.5, "reg": 3, "d": "Mystische Wahrsage-Schildkröte (Uralte Ödbestie)."},
	"grand_smoke_sea_turtle": {"n": "Großrauch-Meeresschildkröte", "hp": 3000.0, "atk": 150.0, "sp": 1.6, "cap": 3, "range": 3.0, "fly": false, "swim": true, "beh": B_KING, "tier": 6, "arch": "turtle", "cols": ["#6b7b7f", "#a9b8bc", "#3a4548"], "ss": 2.8, "smoke": true, "aoe": 3.0, "reg": 3, "d": "Riesige, rauchumhüllte Meeresschildkröte."},
	"moon_demon_bat": {"n": "Monddämonfledermaus", "hp": 1500.0, "atk": 210.0, "sp": 4.4, "cap": 3, "range": 6.0, "fly": true, "beh": B_KING, "tier": 6, "arch": "bat", "cols": ["#2a2238", "#a9b8e8", "#6b4a8a"], "ss": 2.0, "aoe": 3.0, "pc": "#c8d4ff", "reg": 1, "d": "Nächtliche Fledermausbestie mit Mondklauen."},
	"devouring_blue_leopard": {"n": "Verschlingender Blauleopard", "hp": 4800.0, "atk": 560.0, "sp": 4.8, "cap": 2, "range": 2.6, "fly": false, "beh": B_KING, "tier": 7, "arch": "tiger", "cols": ["#2f5fa8", "#8fb8f0", "#14294a"], "ss": 2.4, "spots": true, "aoe": 3.5, "reg": 2, "d": "Blauer Raubleopard aus der Ren-Zu-Legende (Uralte Ödbestie)."},
	"thunder_rush_yellow_bird": {"n": "Donnersturm-Gelbvogel", "hp": 3800.0, "atk": 520.0, "sp": 6.0, "cap": 2, "range": 8.0, "fly": true, "beh": B_KING, "tier": 7, "arch": "eagle", "cols": ["#f2c230", "#fff2a8", "#5a6ba8"], "ss": 2.2, "aoe": 3.5, "pc": "#fff27a", "reg": 0, "d": "Blitzschneller gelber Vogel (Uralte Ödbestie)."},
}
const TIER_NAME: Dictionary = {0: "Wildtier", 3: "Hundert-Bestien-König", 4: "Tausend-Bestien-König", 5: "Zehntausend-Bestien-König", 6: "Ödbestie", 7: "Uralte Ödbestie", 8: "Urzeitliche Ödbestie"}
## Benannte Bestien der Enzyklopädie (Reihenfolge der Spawn-Knöpfe)
const NAMED_BEASTS: PackedStringArray = ["white_boar", "black_boar", "lightning_wolf", "thousand_li_earthwolf_spider", "stone_monkey_king", "crocodile_king", "earth_chief",
	"turtle_jade_wolf", "peach_wolf", "flying_bear", "star_desolate_hound", "wailing_whale", "iron_crown_eagle", "qi_grand_lion", "grand_smoke_sea_turtle", "moon_demon_bat",
	"divination_tortoise", "devouring_blue_leopard", "thunder_rush_yellow_bird", "dragon"]

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
	LAVA: [Color8(255, 132, 28), Color8(255, 186, 56), Color8(236, 84, 20)],
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
