# Every Setting

![Every Setting: set once, kept forever, even the hidden ones](docs/brand/banner.png)

Every console variable World of Warcraft has, in one searchable window, for WoW Forever
and retail: about 1,800 in Forever and 1,700 in retail, along with the game's other console
commands and 70 settings that aren't CVars. The useful ones get a slider, menu or checkbox,
with a range taken from the game itself. Your values are set again at every login, so the
game's graphics presets can't overwrite them.

One download covers Forever and retail. Retail doesn't have a few of these settings (loot
sparkles, HDR) and caps a few others lower. [RANGES.md](RANGES.md) lists them.

![The Every Setting window: sections on the left, and each setting with a slider, its value and Reset](docs/screenshots/window.jpg)

## Why use it

- **Every console variable is there.** All of them, in 17 sections, searchable by name,
  by the game's description or by value. Forever's own options menu has a control for 314.
- **Your values stay put.** What you change is set again at every login, or at once with
  Apply now. With Put back on, it's set again a second after something else changes it.
- **Sliders that know the real range.** Each range comes from the game: its settings code,
  help text, quality levels, or testing in the client. In Forever the camera zooms out to
  50 yards, where the game's slider stops at 30.
- **It only touches what you change.** A setting you never moved is never written. Reset,
  Undo and Redo take back any change.
- **A whole look in one pick.** Styles (Cinematic, Immersive, Competitive, Photo, Ultra+,
  True Max, Action) set graphics, camera and sound together. Situations switch settings in
  combat, while mounted, in a city or in an instance.
- **Profiles you can share.** Save a set of values under a name and pass it on as a line
  of text or as `/console` lines.
- **Paste the commands from any guide.** Import takes `/console` lines and `SetCVar` macros
  as one change you can undo. Nothing pasted is ever run.

| | |
| --- | --- |
| ![A section's other CVars under its tuned settings, by the game's own name where it has one](docs/screenshots/cvars.jpg) | ![Changed: just the settings Every Setting keeps, each with a bar and Reset](docs/screenshots/kept.jpg) |
| ![Styles: a look for graphics, camera and sound, picked part by part](docs/screenshots/styles.jpg) | ![Situations: a preset for combat, mounted, a city or an instance](docs/screenshots/situations.jpg) |
| ![A locked group, which styles and presets leave alone, and Lock all](docs/screenshots/locks.jpg) | ![The camera section, with the max camera distance at 4](docs/screenshots/camera.jpg) |
| ![A search for shadow: the tuned settings, then every other CVar that matches](docs/screenshots/search.jpg) | ![Export: a profile as a line of text to share](docs/screenshots/export.jpg) |

In the world, from the same spot:

| | |
| --- | --- |
| ![Ground clutter at the game's top level: density 48, distance 320](docs/screenshots/clutter-48.jpg) | ![Ground clutter at density 256 and distance 500](docs/screenshots/clutter-256.jpg) |
| ![Max camera distance at 2, zoomed all the way out](docs/screenshots/camera-2.jpg) | ![Max camera distance at 4, zoomed all the way out](docs/screenshots/camera-4.jpg) |
| ![View distance at its lowest, 1000: the far forest is lost in haze](docs/screenshots/view-1000.jpg) | ![View distance at its highest, 10000](docs/screenshots/view-10000.jpg) |

## Install

Download `EverySetting-<version>.zip` from the
[releases page](https://github.com/bstotmeister/everysetting/releases), unzip it into
`World of Warcraft/_forever_/Interface/AddOns` (or `_retail_`), and type `/every` in game.

## Usage

- `/every`: open the window (also in the game's Options under AddOns, on a key you can
  bind, and in the minimap's addon list)
- `/every apply`: set every value you keep again now
- `/every putback [on|off]`: put a kept setting back when something else changes it
- `/every reset`, `/every undo`, `/every redo`
- `/every profile [name]`: list your profiles, or switch to one
- `/every situations`: list the situations and their presets
- `/every danger [on|off]`: change the settings the game locks, where it allows it

The [guide](docs/guide.md) covers everything else: search and filters, kept settings,
the frame rate readout, presets, situations, styles, locks, danger mode, what Every
Setting leaves alone, and where the ranges come from.

## Development

The addon is in `EverySetting/`. `scripts/link.sh` links it into your client
(`_forever_` by default, or pass `_retail_`). Lint and test before a pull request:

```sh
luacheck EverySetting tests scripts
lua tests/run.lua
```

## Contributing

Report bugs and request settings with the [issue forms](https://github.com/bstotmeister/everysetting/issues/new/choose).
For branches, pull requests, labels, milestones, translations and releasing, see [CONTRIBUTING](.github/CONTRIBUTING.md).
