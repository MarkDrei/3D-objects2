# 3D-objects2

A gallery of nice 3D objects built entirely in code with Godot 4 (no imported assets), meant to
be reused in other projects. A simple viewer lists all objects; pick one and look at it
fullscreen, orbit, pan and zoom. Runs on the **Web**. Code and docs are English, the UI German.
Architecture: [doc/arc42.md](doc/arc42.md).

## Objects

| Category | Objects |
|---|---|
| Fahrzeuge | Limousine, Taxi, Polizei (Kombi), Sportwagen, Kleinwagen, Krankenwagen, Geländewagen, Pickup, Lieferwagen, Roadster, Oldtimer, Formelwagen, Muscle-Car, Familienvan, Monstertruck, Stadtfloh |
| Menschen | Notärztin, Polizist, Geschäftsfrau, Kind, Opa |
| Tiere | Teddybär, Hase, Einhorn – each in three styles: Plüsch, Vinyl, Low-Poly |

## Viewer controls

| | Mouse / keyboard | Touch |
|---|---|---|
| Orbit | drag with the left button, W/A/S/D | drag with one finger |
| Pan | drag with the right/middle button or Shift + left | drag with two fingers |
| Zoom | wheel, Q/E | pinch |
| Next / previous object | Page Down / Page Up (or N / P), click in the list | tap in the list |
| Fullscreen | F or "Vollbild"; Esc or "Zurück" to leave | buttons |
| Reset view / auto-rotate | R / Space, or the buttons | buttons |

URL options: `?obj=<id>` opens an object directly (ids in `src/catalog.gd`).

## Reusing an object

Copy `src/kit/` plus the object's script (e.g. `src/objects/animals/teddy_bear.gd` and
`cute_parts.gd`, or `src/objects/vehicles/` for cars) into another Godot 4 project, then:

```gdscript
var bear := TeddyBear.new()
bear.style = 1            # 0 Plüsch, 1 Vinyl, 2 Low-Poly
add_child(bear)           # builds its meshes in _ready()
var car := Sedan.new()
car.variant = "police"    # "sedan", "taxi", "police"
add_child(car)
```

Conventions: Y up, +Z is the object's front (Godot's `MODEL_FRONT`), metres, origin on the
ground under the object.

## Build, run, test

Everything installs without root into `~/.local/opt/3D-objects2` (`scripts/setup.sh`).
Start Godot only through `scripts/godot.sh`, which caps its memory (3 GB, `GODOT_MEM`).

```bash
scripts/setup.sh                 # install Godot, web templates, Playwright + Chromium
scripts/test.sh                  # headless tests: objects + viewer with real input (~1 min)
scripts/export.sh                # web export to build/web
scripts/shots.sh bear_0,sedan    # screenshots (hero/front/side/back + 2x2 sheet) in build/screenshots
scripts/release.sh "Message"     # test, commit, push main, wait for deploy, verify live
```

Play locally: `python3 -m http.server -d build/web 8000` → http://localhost:8000.
Debugging and testing lessons: [doc/testing-notes.md](doc/testing-notes.md).
Test catalogue: [doc/test-scenarios.md](doc/test-scenarios.md).

## Deployment

Pushing `main` deploys live via the VPS webhook once the project is registered on the platform
(`~/clones/config`); expected URL https://3d-objects2.ironstrike.de. The `Dockerfile` exports the
web build and serves it with nginx on port 3000. Other branches get preview deploys.

## Layout

```
src/kit          mesh generators (rings, loft, lathe, tube, decals), materials, builder
src/objects      vehicles (car_kit + cars), people, animals (cute_parts + animals)
src/viewer       viewer: stage (studio light), orbit camera, UI
src/catalog.gd   list of all objects shown in the viewer
tests            headless viewer tests, web screenshot script
```
