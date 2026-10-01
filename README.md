# Gu-Weltenbox (Godot)

WorldBox-artiger God-Simulator in der Welt von Reverend Insanity.

## Starten

1. Godot 4.7.2 öffnen: `C:\Projekte\Godot\Godot_v4.7.2-stable_win64.exe`
2. **Importieren** → Ordner `C:\Projekte\gu-weltenbox` → `project.godot` wählen → **Importieren und bearbeiten**
3. Oben rechts **▶ (F5)** drücken.

Beim ersten Start entstehen die Fünf Regionen und 16 Jahre Vorgeschichte laufen ab (ein paar Sekunden).

## Bedienung

- Karte ziehen: Maus oder ein Finger. Zoomen: Mausrad oder zwei Finger.
- Reiter unten wählen, dann ein Werkzeug. Mit Pinsel-Werkzeugen auf die Karte malen.
- Ohne Werkzeug: auf ein Wesen oder Dorf tippen, um es zu inspizieren.
- Leertaste = Pause, T = Zeit, Esc = zurück, F5 im Spiel = speichern (speichert auch automatisch jede Minute).

## Web-Build

Bei jedem Push auf `main` exportiert GitHub Actions (`.github/workflows/web.yml`) das Spiel mit Godot 4.7.2 für den Browser und veröffentlicht es auf GitHub Pages. Danach läuft es unter `https://<github-name>.github.io/<repo-name>/`, auch am Handy.

Einmalig im Repository einstellen: **Settings → Pages → Source „GitHub Actions“**. GitHub Pages ist nur bei öffentlichen Repositories kostenlos.

Die Größe des Downloads steht nach jedem Lauf in der Zusammenfassung des Actions-Laufs (derzeit ca. 10,5 MB komprimiert, fast alles davon ist die Engine).

Lokal exportieren (Export-Templates 4.7.2 müssen installiert sein: im Editor „Editor → Export-Vorlagen verwalten“):
```
Godot_v4.7.2-stable_win64_console.exe --headless --path C:\Projekte\gu-weltenbox --export-release "Web" build/web/index.html
```
Zum Testen den Ordner `build/web` über einen lokalen Webserver öffnen (z. B. `python -m http.server` im Ordner), nicht per Doppelklick auf `index.html`.
