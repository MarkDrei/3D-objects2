# Testing and debugging notes

Practical lessons, each of which cost time once. Read this before debugging, and add to it when
you learn something new (see `CLAUDE.md`). Many entries were carried over from an earlier Godot
project on this VPS; delete them if they turn out not to apply here.

## Quick reference

| Goal | Command | Duration |
|---|---|---|
| Install toolchain | `scripts/setup.sh` | ~1 min first time |
| Headless tests (objects + viewer input) | `scripts/test.sh [test_name]` | ~1 min |
| Web export | `scripts/export.sh` | ~10 s |
| Screenshots of objects | `scripts/shots.sh id,id [views]` → `build/screenshots/<id>.png` (2x2 sheet) | ~15 s per view, vehicles slower |
| Contact sheet of many screenshots | `node tests/web/sheet.cjs <playwright-dir> out.png 5 build/screenshots/*__hero.png` (set `PLAYWRIGHT_BROWSERS_PATH` and `LD_LIBRARY_PATH` as in `shots.sh`) | seconds |
| Native run of one object | `scripts/godot.sh --headless --path . --quit-after 3 -- --obj=sedan` | seconds |
| Parse a single script | `scripts/godot.sh --headless --path . --check-only -s src/x.gd` | seconds |
| Release | `scripts/release.sh "msg"` | – |

Views for `shots.sh`: `hero,front,side,back,top,face` or custom `c:yaw:pitch:zoom:tx:ty:tz`
(target offset from the object's centre), e.g. a wheel close-up `c:90:2:0.3:0.9:-0.35:1.4`.

`shots.sh` with five vehicles × four views takes over 10 minutes (software rendering); run it in
the background or split it. With exactly two views the 2x2 sheet step can fail although all
single PNGs were written; build a sheet with `sheet.cjs` instead.

Look at screenshots (`build/screenshots/*.png`) with the Read tool. That is the only way to check
visuals, layout and placement.

## Memory (the VPS has ~8 GB, shared with everything else)

- Start Godot only through `scripts/godot.sh`: it runs Godot in a systemd scope with `MemoryMax`
  (default 3G, `GODOT_MEM`) and no swap, so only Godot gets killed (exit code 137).
- The limit only kills on real heap growth. Under memory pressure from file-backed pages Godot
  gets slow instead; a run that times out (124) with a tiny limit is that case.
- Memory exploding within seconds usually means an endless loop that allocates. Example:
  `while child_count > 5: get_child(0).queue_free()` never ends, because `queue_free` removes the
  node only at the end of the frame (`remove_child` first).

## Finding errors

- A project-wide check often shows only the end of a chain ("Could not resolve class X, because
  of a parser error"). Parse that script on its own with `--check-only -s` to get the real line.
  "Identifier not found" for autoloads is expected there.
- "Expected statement, found elif": new code was inserted in the middle of an `if/elif` chain.
- Debug timing/input behaviour with temporary `print("DBG …")`, run natively with
  `--quit-after N`, grep for `DBG`, remove the prints afterwards (`grep -c DBG` → 0).
- Godot buffers stdout into pipes: when a run is killed, the last lines are lost. Capture with a
  pseudo terminal: `script -qfc "scripts/godot.sh …" out.log`.
- "Cannot infer the type of x": the source is untyped (e.g. a plain `Node`). Write the type
  explicitly: `var cam: Camera3D = node.camera`.
- GDScript lambdas capture local variables by value: assigning inside a lambda does not change the
  outer variable. Return the value, or use an Array/Dictionary as a container.

## Test runs

- Piping a test script (`| tail`) hides its exit code. Redirect to a log file and check `$?`.
- Tests must use the project's constants, not copies of lists; copies break when content is added.
- `--fixed-fps 30` runs much faster than real time and makes runs reproducible (with a fixed
  random seed). With `Engine.time_scale` above ~4 at 30 fps physics falls behind; use 60 fps.

## Headless scenario tests

- A script error inside a test aborts the test function, but the runner may still print "ok".
  Grep the output for "SCRIPT ERROR" and fail on it.
- Headless windows are 64×64 px. Set `root.size` (e.g. 1280×720), otherwise touch taps and
  button positions are wrong.
- Real input works natively: `Input.parse_input_event` with `InputEventAction`, `InputEventKey`
  (set `keycode` for code that reads keys directly), `InputEventMouseButton`,
  `InputEventScreenTouch/Drag`. Some touch bugs still only show on a real device.
- Tests that pass alone but fail in a file depend on leftover state from earlier tests. Make the
  reset clear it instead of reordering tests.
- `RenderingServer.frame_post_draw` never fires headless; code that awaits it hangs.
- Parallel runs must not share `user://` save files; give each run its own.

## Browser (web) tests

- Use browser runs for screenshots only; test behaviour with native scenario tests. Simulated
  input (Playwright clicks/keys, even `Input.parse_input_event`) does not reliably reach the game
  in headless Chromium.
- Load time in headless Chromium varies by seconds; timing-dependent screenshots are flaky.
  Prefer static states (fixed camera, frozen time).
- Godot imports every PNG inside the project folder, including screenshots in `build/`. Keep a
  `build/.gdignore`.
- The default UI font lacks symbols such as ▼ ▲ (render as boxes). Draw shapes instead.

## Engine pitfalls

- `input_devices/pointing/emulate_mouse_from_touch` must stay `true`: Godot's controls (Tree,
  Button) only react to mouse events, so with it off, taps on the object list did nothing on
  touch devices. Code that handles touch itself (the orbit camera) skips the emulated copies
  (`event.device == InputEvent.DEVICE_ID_EMULATION`), otherwise a one-finger drag turns twice.
  Covered by `test_tap_on_list_item_shows_object` and `test_one_finger_drag_orbits_once`.
- Tree has extra styles for a selected item under the mouse (`hovered_selected`,
  `hovered_selected_focus`); without them the selected entry turned white on white.

- `get_theme_stylebox()` on a control not yet in the tree returns Godot's default style, not
  your theme. Build styles from your theme directly.
- Input events reach every node's `_unhandled_input` until one calls
  `get_viewport().set_input_as_handled()`; otherwise one key press can open and close a menu.
- A mouse press on UI can be followed by a release over the 3D view: only treat a release as a
  click when the press was on the view too.
- `InputEventScreenTouch` reaches `_unhandled_input` even when the finger is on a button (buttons
  only consume the emulated mouse events). Check whether the point is over UI before treating it
  as a tap on the 3D view.
- Controls placed with `position = …` don't follow window resizes; re-centre them on `resized`.

## Procedural meshes

- A class that is new or changed needs `scripts/godot.sh --headless --path . --import` before a
  `-s` script or a run sees its `class_name`; otherwise "Nonexistent function 'new' in base
  'GDScript'" or a parse error in a dependent script.
- `for side in [1.0, -1.0]` makes `side` a Variant, so `var x := side * 0.6` fails to parse
  ("Cannot infer the type"). Write `for side: float in [1.0, -1.0]`. Same for values read from a
  Dictionary (`var r: float = spec.wheel_r`).
- `Callable.bind()` appends the bound arguments at the end, not the start.
- Mirroring a part that is not symmetric needs scale (-1, 1, 1) (`Builder.mirror_mesh`); mirroring
  only position and rotation (`Builder.mirror`) is enough for ellipsoids.
- An `AABB` of a rotated part is the box around the rotated box, so bounding boxes of rotated
  ellipsoids are larger than they look.
- Decals: points whose ray misses the solid are dropped, so an outline must stay inside the
  part's silhouette seen from the projection direction. Faces the ray only grazes are skipped
  (`min_facing`); otherwise the patch smears around rounded ends.
- Decals call the inside test thousands of times. Sample profiles into tables
  (`CarKit._tab`), start rays just outside the part, and keep `spacing` coarse on big areas.
  Building a car dropped from 3–6 s to ~0.5 s that way. Measure with a `-s` script.
- `CarKit.end_z` only finds the body: at a height above the body's top line at that end (cabin,
  tailgate, bed walls) it walks 2 m inward and returns a z in the middle of the car, so the lamp
  shows up inside a side window. Pass the back face's z to `CarKit.tail_lights` there.
- `MeshGen.tube` needs one radius per path point: after `smooth_path`, `resample` the radii.
- Open-wheel or narrow bodies between the wheels: give the body spec `axles = []` (no arches)
  and the wheels their own small spec for `CarKit.wheels`.
- GDScript lambdas capture locals by value: a timing lambda that updates `t` never updates the
  outer `t` (profiling output looked cumulative).

## Look and lighting

- Shadow acne on glossy materials looks like wood grain. Godot's default shadow bias is fine;
  a small custom bias brought it back.
- Bright reflections wash out car paint. The sky shader shows a darker studio only in the
  radiance pass (`AT_CUBEMAP_PASS`), and the ambient light is a fixed colour so it does not get
  darker with it.
- AgX desaturated bright reds (salmon instead of red). ACES keeps them saturated but needs a
  lower exposure (~0.8).
- Metallic parts in shadow turn black (they take almost no ambient light): wheel spokes under
  the wheel arch looked missing. Use non-metallic materials with high specular for small parts.
- White objects on the light backdrop disappear (white coffee cup): give props a colour.

## Deploy and platform

- The deploy platform (webhook, dashboard) lives in `~/clones/config` and is owned by the
  orchestrator. Restarting the webhook is the user's call, not this session's.
