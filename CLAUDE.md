# CLAUDE.md – Gu-Weltenbox

God-Simulator im Stil von **WorldBox**, gesetzt in die Welt von *Reverend Insanity*. Der Spieler ist Gott über eine Pixel-Welt mit den Fünf Regionen, Clans und Sekten, Gu-Meistern von Rang 1 bis 9, Drangsalen, Wolfsfluten und dem Himmelswillen. Optik und Bedienung folgen WorldBox (Leiste unten mit sieben Reitern, rotes Zurück, Pause, Sanduhr, Stern- und Geschenk-Knopf oben rechts).

## Tech-Stack

- Godot **4.7.2** (Standard, nicht .NET). Programm lokal: `C:\Projekte\Godot\Godot_v4.7.2-stable_win64_console.exe`.
- GDScript mit statischen Typen; Warnung für untypisierte Deklarationen ist aktiv.
- Renderer: Compatibility (läuft auch im Browser und am Handy).
- Hochformat, Basisauflösung 400 × 880, Stretch `canvas_items` / `expand`. Texturfilter: Nearest (Pixel-Art).
- Alle Grafiken werden zur Laufzeit aus Code gezeichnet (`Px`, `Sprites`, `Icons`). Es gibt keine Bilddateien. Keine WorldBox-Grafiken übernehmen.

## Aufbau

| Datei | Inhalt |
|---|---|
| `scripts/gu_data.gd` | Konstanten: Gelände, Ränge, Uressenzen, 48 Pfade (`PATH_*`), 11 Völker (`RACE_*`), Tiere und Bestien (`SPEC`, Verhalten `B_*`, Stufen `TIER_NAME`), Namen, Zeitalter, Farben |
| `scripts/gu_lore.gd` | `Lore`: Inhalte aus `docs/ri_content.json` – sterbliche Gu je Pfad (`MGU`/`mgu()`), Mordzug-Namen, 49 Unsterbliche Gu mit Wirkung (`IGU`, `fx`), 11 Ehrwürdige (`VEN`), Figuren (`FIG`), Organisationen (`ORGS`), Orte (`PLACE`) |
| `scripts/place.gd` | Datenklasse besonderer Orte (Gesegnetes Land, Grottenhimmel, Himmelshof, Traumreich, Erbe …) |
| `scripts/world.gd` | Karte (256 × 256, eine Kachel = ein Pixel), Generierung, Bilder für nah/fern/Clan-Gebiete, Neuzeichnen in 32er-Blöcken |
| `scripts/map_gu.gd` | Kanonische Gu-Weltkarte (Kartenmodus „gu“), benannte Orte in `World.LANDMARKS` |
| `scripts/sim.gd` | Simulation: Wesen, Dörfer, Clans, Kultivierung, Kampf, Feuer, Wetter, Zeitalter, Speichern; Abschnitt „Gu-Welt“: Wiedergeburt, Mordzüge, Gu-Meister/Unsterbliche/Ehrwürdige/Figuren setzen, Organisationen gründen, Orte (`place_month`), Ereignisse; am Ende „Gottkräfte-Parität“: Lava/Erdfeuer-Vulkan, Wirbel, Giftregen, Minen, Gu-Schwarm, Biom-Samen, Mordzug-Leiter, Leere-Mordzug, Schicksals-Münze, Leichen-Seuche, Seelenbesitz, Pläne, Loyalität/Aufstände, Straßen, zufällige Katastrophen |
| `scripts/powers.gd` | Liste aller Werkzeuge (Reiter, Gruppen) und was jede Gottkraft tut; Parität in `_parity_tools`, `paint_parity`, `tap_parity`; Texte für Dorf-Inspektor (`village_lines`, `unit_lines`) und Fenster „Pläne und Kriege“ (`plans_text`) |
| `scripts/hud.gd` | Oberfläche: Leiste, Reiter, Knöpfe, Hinweise, Meldungen, Inspektor, Fenster, Ladebildschirm |
| `scripts/main.gd` | Kamera, Eingabe (Maus, Touch, Pinch), Zeichenebenen, Fenster-Inhalte, Speichern/Laden |
| `scripts/sprites.gd`, `icons.gd`, `px.gd` | Pixel-Sprites und Icons |
| `scripts/unit.gd`, `village.gd`, `clan.gd`, `building.gd` | Datenklassen |

Zeiteinheit der Simulation: 1.0 = ein Monat, ein Simulationsschritt `Sim.DT` = 0,05. Weltkoordinaten sind Kacheln.

## Input Map

`toggle_pause` (Leertaste), `zoom_in` (+), `zoom_out` (−), `ui_back` (Esc), `speed_cycle` (T), `quick_save` (F5). Kamera: ziehen mit Maus oder einem Finger, Mausrad oder zwei Finger zum Zoomen (im Code).

## Prüfen

```
Godot_v4.7.2-stable_win64_console.exe --headless --path C:\Projekte\gu-weltenbox -- --selftest
```
Mit `-- --fresh --selftest` wird kein Spielstand geladen oder überschrieben. Löst jedes Werkzeug einmal aus, speichert und lädt und endet mit `SELFTEST DONE`. Screenshots für Vergleiche: `-- --shots=<ordner>` (ohne `--headless`). Leere/freie Welten: `-- --fresh --blanktest` (jede Kartenart und Lebensstufe ~5 Jahre, alle Fenster, Speichern/Laden im Speicher, alle Gottkräfte auf leerer Welt; endet mit `BLANKTEST DONE`), Bilder mit `-- --fresh --blankshots=<ordner>`.

## Regeln

- Neue Werkzeuge: Eintrag in `Powers._build_tools()` (Reiter `tab`, Gruppe `g`, deutscher Name `n`, Beschreibung `d`), Icon in `Icons._make` bzw. `Icons._make_generated` (24 × 24, dunkle Kontur), Wirkung in `Powers`. `Powers.TOOLS` wird beim Start erzeugt und nach Reiter und Gruppe sortiert; ein Gruppenwechsel gibt in der Leiste einen Trennstrich. Viele Knöpfe entstehen aus den Tabellen (`Lore.VEN`, `Lore.FIG`, `Lore.ORGS`, `Lore.PLACE_ORDER`, `Lore.IGU_BTN`, `Lore.WILD_PATHS`, `GuData.NAMED_BEASTS`) – neuer Eintrag dort = neuer Knopf.
- Reiter: 0 Welt formen (+ Regionen, Welt-Aktionen, Orte), 1 Noosphäre (+ Organisationen mit Siegel-Overlay `gl`), 2 Kreaturen (Völker, Tiere, Bestienkönige/Ödbestien, benannte Bestien, Wolfsflut), 3 Natur (+ Irdische Kalamität, Traumreich, Erbe), 4 Zerstörung (+ Fremdweltdämon, Rechtschaffen gegen Dämonisch, Himmelsfragment, Alles Leben auslöschen), 5 Gu und Schicksal (+ wilde Gu je Pfad, Unsterbliche Gu), 6 Gu-Meister und Unsterbliche (Rang 1–8, Ehrwürdige, Figuren).
- Pfad-Ids 0..11 und Völker-Ids 0..3 nie umnummerieren (alte Spielstände). Neue Pfade/Völker nur hinten anhängen und alle parallelen Arrays (`PATH_COL`, `RACE_*`, `Lore.MGU`) mitpflegen.
- Tierverhalten über `Unit.beh` (`GuData.B_*`), nicht über Artnamen abfragen. Abgeleitete Felder (`beh`, `aqua`, `ig_*`, `igf`) werden nach dem Laden in `Sim.deserialize` neu berechnet (`init_animal`, `apply_igu`).
- Unsterbliche Gu wirken über `Sim.apply_igu` (Faktoren `ig_atk/ig_hp/ig_sp/ig_cult/ig_rng`, Merker `igf` = `Sim.F_*`). Neue Wirkung: `fx` in `Lore.IGU`, Fall in `apply_igu`, Text in `Lore.FX_TEXT`.
- Einzigartig: Ehrwürdige und Figuren über `Unit.fig` (Fang Yuan als Figur und als Ehrwürdiger teilen sich `fang_yuan`), Orte über `uniq` in `Lore.PLACE`, Organisationen über `Clan.org`.
- Die Vorgeschichte läuft im Hintergrund (`GuMain.presim_on`): die Karte ist nach ~1–2 s sichtbar, `Sim.presim_chunk` bekommt pro Bild ein anpassbares Zeitbudget, oben links steht „Vorgeschichte … n %“. Greift der Spieler mit einer Gottkraft ein, endet sie sofort (`_end_presim`).
- Kamera: Übersicht passt immer ganz und mittig über die Leiste (`min_z`, `_clamp_cam`), weiches Zoomen über `zoom_smooth`, Schwung nach dem Wischen (`fling`), Doppeltippen/-klick zoomt hinein. Desktop-Querformat nutzt Basis 400 × 760 (`_on_resize`).
- In der Vorgeschichte (`Sim.presim`) entzündet nichts Feuer, sonst verascht der Zentralkontinent durch Drangsal-Blitze der Unsterblichen.
- Neue Welt: `Sim.new_world(live, mode, opts)` mit `mode` „gu“ (Standard, kanonische Mächte über `Sim.seed_canon`), „random“ oder einer leeren Welt aus `World.BLANK_MODES` („ocean“ nur tiefes Meer, „flat“ eine Ebene mit schmalem Meeressaum, „island“ eine runde Insel, „continents“ flache Landmassen mit ~40 % Land). Leere Welten (`World.is_blank`, `_base_blank`, `_blank_plants`): eine einzige Region 4, daher keine Regionswände, keine benannten Orte, nur vereinzelte Bäume/Grasbüschel, Höhen `hgt` = `GuData.DEFH` der Kachel. `opts`: `life` „full“/„animals“/„none“ (Standard: `live` → „full“, sonst „animals“, auf leeren Karten „none“; „none“ schaltet das Weltgesetz Tier-Spawn aus, sonst an – es steuert auch wilde Gu), `canon` false = Gu-Karte ohne kanonische Mächte, `presim` false = ohne Vorgeschichte (Jahr 1 sofort). `GuMain.presim_on` folgt `Sim.presim`. Fenster „Neue Welt“ ist zweistufig (`_open_new_world` → `_open_new_world_life` bzw. `_open_new_world_blank`); erster Start bleibt Gu-Weltkarte mit Clans und Vorgeschichte. `map_mode` wird gespeichert, kein neues Spielstandformat.
- Spielstand liegt in `user://gu_weltenbox.json`. Bei Formatänderungen `v` in `Sim.serialize` erhöhen. Aktuell **v4** (neu: `age_off`); v3 (`lava` [Kachel, Hitze], `mines`, `layer`; Unit-Felder `bless/prot/undead/boat`; Village `loy/capt/road`; Clan `cap/exh/plans`), v2 (`map_mode`, `places`, `next_pid`, Unit `gname/igu/fig/ow/hx/hy/notrib`, Clan `org/align/sur`) und v1 werden weiter geladen. `Clan.war`-Werte sind der Kriegsbeginn (Simulationszeit), nach dem Laden `true`.
- Entwickler-Bögen: `-- --fresh --sheets=<ordner>` schreibt `icons.png` (alle Werkzeug-Icons, nach Reitern) und `sprites.png` (Völker, alle Tierarten, Orte) – läuft auch headless.

## Web-Build

- **Preset „Web“** in `export_presets.cfg` (gehört ins Repository, ohne Passwörter): Single-Threaded (`variant/thread_support=false`, keine SharedArrayBuffer, keine Cross-Origin-Isolation-Header nötig, läuft deshalb auf GitHub Pages), keine GDExtensions, Standard-HTML-Shell, `canvas_resize_policy=2` (Canvas füllt das Browserfenster; Hochformat passt über `stretch/aspect="expand"`). Ausgabe nach `build/web/index.html`; `build/` steht in `.gitignore` und ist vom Export ausgeschlossen.
- **Workflow** `.github/workflows/web.yml`: bei jedem Push auf `main` (und manuell) Godot `GODOT_VERSION` (4.7.2) plus die Web-Templates `web_nothreads_*` laden (gecacht), importieren, exportieren, Downloadgröße (unkomprimiert, gzip, `index.pck`) in die Build-Zusammenfassung schreiben (Warnung über 50 MB), dann auf GitHub Pages veröffentlichen. Bei jedem Godot-Update `GODOT_VERSION` dort mitändern. Gleicher Aufbau wie bei Wildmark.
- **Größe:** Engine ca. 10 MB komprimiert (`index.wasm` 39,5 MB roh), Spieldaten (`index.pck`) nur einige hundert kB.
- **Export-Filter** ist `all_resources`: Godot packt nur Ressourcen (Szenen, Skripte, importierte Dateien inkl. `.json`). Andere Dateien, die zur Laufzeit per `FileAccess` gelesen werden (z. B. `.txt`, `.csv`), müssen in `include_filter` stehen, sonst fehlen sie nur im Web-Build.
- **Web-Fallen:** Spielstand `user://` liegt im Browser in IndexedDB (pro Domain). Im Release-Build stürzt ein Aufruf auf ein freigegebenes Objekt ab: gespeicherte Verweise vor der Nutzung mit `is_instance_valid()` prüfen. Nicht auf echte Parallelität durch `Thread` oder `WorkerThreadPool` bauen (Single-Threaded-Export).
- **Lokal prüfen:** `godot --headless --path . --export-release "Web" build/web/index.html` (Templates 4.7.2 unter `~/.local/share/godot/export_templates/4.7.2.stable/` bzw. `%APPDATA%\Godot\export_templates\4.7.2.stable\`).

## Gottkräfte-Parität (WorldBox)

- **Gelände:** `GuData.LAVA = 12` (hinten angehängt; `TNAME`, `DEFH`, `PAL` mitgepflegt), Objekt `GuData.F_ROAD = 11` (Straße, +30 % Tempo). Lava liegt in `Sim.lava` (Kachel → Hitze), fließt in `lava_tick` nur bergab bzw. eben (Höhe `world.hgt`, beim Umwandeln bleibt die Höhe erhalten), entzündet Nachbarn, erstarrt im Wasser sofort und bei Hitze 0 zu Fels (`HILL`, manchmal `F_ROCK`). Neue Lava immer über `set_lava`, Abkühlen über `cool_lava`. Zugefrorenes Wasser (Frostodem) ist `SNOW` mit `temp_snow` 1/2 – darauf wird nicht gebaut.
- **Laufende Naturgewalten** (nicht gespeichert außer Lava und Minen): `volcs`, `storms`, `acids`, `goo`/`goo_left` (Gu-Schwarm frisst höchstens ~1400 Kacheln je Schwarm, ≤ 260 aktive Zellen), `mines`, `seeds`. `nature_tick` (alle 0,15 Monate) und `forces_step` laufen nur, wenn etwas aktiv ist. Darstellung nur über Partikel und vorhandene `fx`-Arten – `main.gd` zeichnet nichts Neues.
- **Seltene Wesenszustände** (`held`, `air`, `frz`, `zin`, `poss`, `bless`, `prot`, `boat`): wer eines davon setzt, setzt auch `Unit.fxm = true`; nur dann prüft `step_unit` sie in `Sim._special` (Leistung). Geschleudert wird über `Sim.fling`.
- **Göttliche Hand:** `Powers.held` folgt dem Pinsel, `Powers.end_stroke` (Haken in `main.gd` beim Loslassen) bzw. `begin_stroke` lässt fallen. **Seelenbesitz/Gelenkte Ödbestie:** `Sim.possessed`, besessene Wesen denken nicht (`poss_think`), Tippen lenkt sie.
- **Zivilisation:** Jeder Clan hat eine Hauptstadt (`Clan.cap`), ein Clan-Oberhaupt (`Clan.lead`, stärkstes Mitglied, in `update_leaders`), Kriegsmüdigkeit (`exh`) und Pläne (`plans`: Krieg/Bündnis werden 2–9 Monate vorher geplant, `run_plans`). `loyalty_month` berechnet `Village.loy` (Entfernung zur Hauptstadt, Kriegsmüdigkeit, Clan-Größe, Stärke des Oberhaupts, rivalisierende Dorfälteste, Eroberung, Volk, Region, Gesinnung); unter 25 droht ein Aufstand (`rebel`). Straßen verbinden Dörfer mit ihrer Hauptstadt (`build_road`). Siedler fahren mit Booten (`Unit.boat`) über tiefes Wasser zu Inseln derselben Region, nie durch Regionswände.
- **Weltgesetze:** zusätzlich `Sim.LAWS_EXTRA` (Hunger, Alter, Aufstände, Diplomatie, Ausbreitung, Tier-Spawn, Grasausbreitung, Baumwachstum, Katastrophen); `main._open_laws` zeigt `LAWS + Sim.LAWS_EXTRA`. Neue Gesetze dort und mit Standardwert in `Sim.laws` eintragen.
- **Kartenebene:** `World.layer` 0 Clan-Gebiete, 1 Dorf-Gebiete (Hauptstadt golden umrandet), 2 Regionen; Knopf „Kartenebene“ im Hauptmenü.
- **Sandkasten** (alles frei änderbar, keine festen Abläufe): Regionen-Pinsel `rg_0`…`rg_4` (`"reg"` im Werkzeug, `Powers.paint_sandbox` → `Sim.set_region` + `sync_village_regions`; Dörfer/Clan-Hauptstädte übernehmen die Region ihres Mittelpunkts), `t_unwall` reißt Regionswände ein. Solange einer davon gewählt ist, schaltet `main._region_view` die Kartenebene auf „Regionen“ (in jeder Zoomstufe sichtbar) und danach zurück; der Pinsel zeichnet nur das betroffene Rechteck neu (`World.region_layer_rect`). Welt-Aktionen über `Powers.world_act`: `w_flat` (Welt einebnen), `w_flood` (Welt fluten: Küstenstreifen versinken, alle Höhen −`Sim.SEA_STEP`), `w_raise` (Kontinente heben), `w_wipe` (Alles Leben auslöschen: leert `units/villages/clans/buildings`, Land/Orte bleiben). `w_flat` und `w_wipe` fragen vorher nach. Danach zeichnet `Sim._sb_finish` alles neu (`refresh_water`, `render_all`), Nicht-Schwimmer im tiefen Wasser ertrinken.
- **Gesetze „Zeitalter“ (`ages`) und „Kultivierung“ (`cult`):** Bei `ages` aus zählt `Sim.age_off` jedes Jahr mit, das Zeitalter bleibt stehen (`age_year()`); im Fenster „Zeitalter“ startet ein Tippen (`[url=age:k]`) sofort Zeitalter k (`Sim.set_age`). `cult` aus: `cultivate` ruht, nur Gottkräfte lassen Gu-Meister wachsen. Im Gesetze-Fenster schalten `law:__off` / `law:__on` alle Gesetze auf einmal.
- Entwickler-Test Sandkasten: `-- --fresh --sandboxtest` (Auslöschen, neu besiedeln, Regionen malen, Speichern/Laden im Speicher, Fluten/Heben/Einebnen).
- Screenshots der Parität: `_dev_shots_parity` (P_vulkan, Q_wirbel, R_mordzug, S_krater, T_ebene0–2, U_dorf, V_plaene, W_gesetze).
