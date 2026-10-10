# 3D-objects2 – Architecture (arc42)

A gallery of nice 3D objects (vehicles, people, cute animals) built entirely in code with
Godot 4, plus a small web viewer to pick an object and look at it. The objects are meant to be
copied into other projects. Keep this file current together with `README.md`.

---

## 1. Introduction and goals

### 1.1 Requirements overview
- Objects that look good on their own: vehicles, people, animals (animals in three styles each,
  to explore directions).
- Every object is a self-contained Node3D class that builds itself; reusable in other projects.
- Viewer: list of all objects, fullscreen view, orbit / pan / zoom with mouse, keyboard and touch.

### 1.2 Quality goals
| Priority | Goal | Meaning |
|---|---|---|
| 1 | Runs in the browser | Loads and plays smoothly in a desktop and phone browser |
| 2 | Testable | Behaviour covered by headless scenario tests, visuals by screenshots |
| 3 | Reproducible setup | One command (`scripts/setup.sh`) sets up the toolchain on a fresh machine |

---

## 2. Constraints

- **Godot 4, GDScript**, *Compatibility* renderer (WebGL 2 / GLES 3) for web and Android.
- **Rootless VPS** with ~8 GB RAM shared with other projects: toolchain in
  `~/.local/opt/3D-objects2` (`scripts/setup.sh`), Godot started only via `scripts/godot.sh`
  (memory cap).
- **Single-threaded web export** (`variant/thread_support=false`): no `SharedArrayBuffer`, no
  COOP/COEP headers needed.

---

## 3. Context and scope
Static web app (Godot web export) served by nginx. No backend, no external assets: geometry,
materials and textures are generated at runtime (shaders for plush fur, studio sky, floor).

---

## 4. Solution strategy
- **Procedural geometry kit** (`src/kit`): every shape is a stack of rings turned into a mesh
  (`MeshGen.from_rings`), on top of which sit superellipsoids, lathes, tubes along curves, lofts
  and extrusions. `MeshGen.decal` projects a 2D outline onto any solid (given as an inside test)
  — used for car windows, lights, stripes and stickers with crisp edges.
- **Object families** share helpers: `CarKit` (lofted body with wheel arches, cabin, wheels,
  decals) and `CuteParts` (eyes, blush, limbs, the three animal styles).
- **Studio stage**: grey backdrop, key + fill light, fading floor, contact shadow; reflections see
  a darker studio with softboxes so car paint keeps contrast.

---

## 5. Building block view
| Block | Files | Responsibility |
|---|---|---|
| Kit | `src/kit/mesh_gen.gd`, `mats.gd`, `builder.gd`, `plush.gdshader` | mesh generators, cached materials, part composition (groups, mirroring) |
| Vehicles | `src/objects/vehicles/` | `CarKit` + `Sedan` (sedan/taxi/police), `SportsCar`, `CompactCar`, `Ambulance`, `Suv`, `Pickup`, `DeliveryVan`, `Roadster`, `VintageCar`, `FormulaCar`, `MuscleCar`, `Minivan`, `MonsterTruck`, `MicroCar` |
| People | `src/objects/people/person.gd` | one stylised figure, roles change clothes, hair and props |
| Animals | `src/objects/animals/` | `CuteParts` + `TeddyBear`, `Bunny`, `Unicorn` (style 0/1/2) |
| Catalog | `src/catalog.gd` | ids, names, categories, classes and properties of all objects |
| Viewer | `src/viewer/` | `viewer.gd` (selection, shots mode, options), `stage.gd`, `orbit_camera.gd`, `viewer_ui.gd` |

---

## 6. Runtime view
Selecting an object: the UI emits `selected(id)` → the viewer shows "Baue Objekt …", waits two
frames, instantiates the class from the catalog (it builds its meshes in `_ready`), fits the
stage and frames the camera on the bounding box. Vehicles take ~0.5 s to build natively
(decal projection), animals and people a few milliseconds.

---

## 7. Deployment view

- Web: static files (`index.html` + wasm + pck), single-threaded build.
- Production: push to `main` → VPS webhook builds the `Dockerfile` (Godot headless export in the
  build stage, web server on port 3000). Other branches → preview deploys.

---

## 8. Cross-cutting concepts

### 8.1 Conventions for objects
Y up, +Z front (`MODEL_FRONT`), metres, origin on the ground under the object. An object class
extends Node3D, exposes its options as `@export` vars and builds in `_ready()` if it has no
children yet, so it can be configured after `new()` and before `add_child()`.

### 8.2 Testing
| Level | Tool | What |
|---|---|---|
| Scenario | `scripts/test.sh` (`tests/viewer_tests.gd`) | objects build and stand on the ground; viewer reacts to real mouse, key and touch input; catalogue in [test-scenarios.md](test-scenarios.md) |
| Visual | `scripts/shots.sh` (`tests/web/shots.cjs`) | web export in headless Chromium, the viewer's shots mode renders each object from several views; checked with the Read tool |

Native test runs use `--fixed-fps` (deterministic, faster than real time) and `scripts/godot.sh`.

---

## 9. Architecture decisions

| # | Decision | Rationale | Consequence |
|---|---|---|---|
| 1 | Compatibility renderer, single-threaded web build | Runs everywhere, no special hosting headers | No SDFGI/volumetrics |
| 2 | Objects built in code, no imported assets | Reusable by copying scripts, easy variants, tiny download | Model code is long; shapes are tuned via screenshots |
| 3 | Decals projected onto implicit solids | Crisp windows and liveries on curved bodies without UV mapping | Build cost (~0.5 s per car); outlines must stay inside the part's silhouette |
| 4 | Text with Label3D | Lettering (POLIZEI, plates) without textures | Labels are flat; keep them on flat-ish areas |

---

## 10. Quality requirements
- Every object stands on y = 0 and has a plausible size (checked by tests).
- Selecting an object takes well under a second natively.

---

## 11. Risks and technical debt
- Memory on the shared VPS (see `CLAUDE.md`).
- Vehicle build time grows with every decal; keep outlines simple or cache meshes if it grows.

---

## 12. Glossary
| Term | Meaning |
|---|---|
| Decal | A patch projected onto a solid's surface from a 2D outline |
| Loft | A body made of cross-sections along Z (car bodies) |
| Lathe | A surface of revolution around Y (wheels, pots, hats) |
| Style | Plüsch / Vinyl / Low-Poly look of the animals |
