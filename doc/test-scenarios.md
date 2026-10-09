# Test scenarios

Catalogue of everything a user can do, and whether an automated test covers it. Tests live in
`tests/viewer_tests.gd` and run natively and headless (`scripts/test.sh`, ~1 min). UI tests use
real input events (mouse, keys, touch) via `Input.parse_input_event`. Visuals are checked with
screenshots (`scripts/shots.sh`), not with tests.

**Keep this file up to date:** when you add a feature, add its row here; when you add a test, set
its status. A feature is only "done" with a ✅ row.

## Legend

| Status | Meaning |
|---|---|
| ✅ | Scenario test with real input |
| 🔶 | Tested through a shortcut (start state set directly or internal call; reason in the row) |
| ⬜ | Not tested yet; the row says how to test it |

## Features

| Feature | Status | Test | Notes |
|---|---|---|---|
| Every catalog object builds, stands on the ground, plausible size and triangle count | 🔶 | `test_every_object_builds_and_stands_on_the_ground` | calls `show_object` directly |
| Objects work outside the viewer (`TeddyBear.new()`, `Sedan.new()`) | 🔶 | `test_objects_can_be_used_without_the_viewer` | the reuse API |
| Click on a list entry shows that object | ✅ | `test_click_on_list_item_shows_object` | |
| Tap on a list entry (touch) shows that object | ✅ | `test_tap_on_list_item_shows_object` | needs touch-to-mouse emulation |
| One-finger drag orbits (exactly once, not doubled by emulated mouse events) | ✅ | `test_one_finger_drag_orbits_once` | |
| Page Down / Page Up step through objects | ✅ | `test_page_keys_step_through_objects` | |
| Left drag orbits | ✅ | `test_left_drag_orbits` | |
| Mouse wheel zooms in and out | ✅ | `test_wheel_zooms` | |
| Right drag pans | ✅ | `test_right_drag_pans` | |
| Pinch with two fingers zooms | ✅ | `test_pinch_zooms_on_touch` | |
| Fullscreen via F/Esc and via the buttons | ✅ | `test_fullscreen_with_key_and_buttons` | real window mode is skipped headless |
| A drag that starts on the list does not orbit | ✅ | `test_drag_on_the_list_does_not_orbit` | |
| W/A/S/D orbit, Q/E zoom | ⬜ | | press keys, compare `goal_yaw` / `goal_distance` |
| Space toggles auto-rotate, R resets the view | ⬜ | | press keys, check `cam.auto_rotate`, view angles |
| Two-finger pan | ⬜ | | two touches, drag both the same way, compare target |
| `?obj=<id>` opens an object | ⬜ | | start with `--obj=bunny_1`, check `current_id` |
