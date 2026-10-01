# CLAUDE.md – Gu-Weltenbox

God-Simulator im Stil von **WorldBox**, gesetzt in die Welt von *Reverend Insanity*. Der Spieler ist Gott über eine Pixel-Welt mit den Fünf Regionen, Clans und Sekten, Gu-Meistern von Rang 1 bis 9, Drangsalen, Wolfsfluten und dem Himmelswillen. Optik und Bedienung folgen WorldBox (Leiste unten mit sechs Reitern, rotes Zurück, Pause, Sanduhr, Stern- und Geschenk-Knopf oben rechts).

## Tech-Stack

- Godot **4.7.2** (Standard, nicht .NET). Programm lokal: `C:\Projekte\Godot\Godot_v4.7.2-stable_win64_console.exe`.
- GDScript mit statischen Typen; Warnung für untypisierte Deklarationen ist aktiv.
- Renderer: Compatibility (läuft auch im Browser und am Handy).
- Hochformat, Basisauflösung 400 × 880, Stretch `canvas_items` / `expand`. Texturfilter: Nearest (Pixel-Art).
- Alle Grafiken werden zur Laufzeit aus Code gezeichnet (`Px`, `Sprites`, `Icons`). Es gibt keine Bilddateien. Keine WorldBox-Grafiken übernehmen.

## Aufbau

| Datei | Inhalt |
|---|---|
| `scripts/gu_data.gd` | Konstanten: Gelände, Ränge, Uressenzen, Pfade, Völker, Tiere, Namen, Zeitalter, Farben |
| `scripts/world.gd` | Karte (256 × 256, eine Kachel = ein Pixel), Generierung, Bilder für nah/fern/Clan-Gebiete, Neuzeichnen in 32er-Blöcken |
| `scripts/sim.gd` | Simulation: Wesen, Dörfer, Clans, Kultivierung, Kampf, Feuer, Wetter, Zeitalter, Speichern |
| `scripts/powers.gd` | Liste aller Werkzeuge (Reiter, Gruppen) und was jede Gottkraft tut |
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
Mit `-- --fresh --selftest` wird kein Spielstand geladen oder überschrieben. Löst jedes Werkzeug einmal aus, speichert und lädt und endet mit `SELFTEST DONE`. Screenshots für Vergleiche: `-- --shots=<ordner>` (ohne `--headless`).

## Regeln

- Neue Werkzeuge: Eintrag in `Powers.TOOLS`, Icon in `Icons._make`, Wirkung in `Powers`.
- Spielstand liegt in `user://gu_weltenbox.json`. Bei Formatänderungen `v` in `Sim.serialize` erhöhen.
