# What the client kept

The raw results behind [RANGES.md](../../RANGES.md), by the client's build and by platform.
Not shipped with the addon.

| File | What it is |
| --- | --- |
| `<build>/<platform>/probes.lua` | What the engine kept, a probe a line. |
| `<build>/<platform>/cvars.lua` | That client's CVar list, in the shape of `data/cvars.lua`. Only for a client other than the one `data/cvars.lua` is from. `70783/retail/cvars.lua` is retail's list for the tests (`tests/retail_test.lua`), and the newest `<build>/retail/cvars.lua` for `RANGES.md`. `70938/windows-d3d12/cvars.lua` gives the CVars only Windows has, which `EverySetting/CVars.lua` has lines for too: the tests and `RANGES.md` read it with `data/cvars.lua`. |
| `<build>/<platform>/costs.lua` | The frame rate at each end of a tuned setting's range, a setting a line: what its `cost` goes on. |

`<build>` is the client's build number, as `/every dump` saves it (`70938`). `<platform>` is
in lower case, with the graphics API after a hyphen where the platform has more than one:
`mac`, `windows-d3d12`, `windows-d3d11`. A client of another game than WoW Forever has the
game's name in its place on a Mac, `retail`, and before the platform elsewhere:
`retail-windows-d3d12`. Its `probes.lua` goes by that game's ranges, and by the `cvars.lua`
beside it.

## A line of probes.lua

```lua
{ "groundEffectDensity", "8", "264", "48", "48", note = "Value must be between 16 and 256." },
```

The CVar, the two values set, and what the CVar read after each: what
`/every probe groundEffectDensity 8 264` prints. The engine usually turns a value down by
keeping the one it had, so here it kept neither.

`note` is optional: what the engine said (a `[Console]` line in `Logs/General.log`), or
what was seen in the game. A value that the CVar's slider, menu or checkbox offers and the
engine didn't keep needs one, or the tests fail: either the range is wrong, or there's a
reason to give.

The file's `version`, `build` and `platform` name the client, the platform in words for the
page (`"Mac, Metal"`). `game` names the game, for a client that isn't WoW Forever's
(`"WoW retail"`). Its own `note`, if it has one, is printed under the client's heading:
what wasn't tried, and why.

## A line of costs.lua

```lua
{ "groundEffectDensity", "16", "256", 88.2, 64.1 },
```

The CVar, the low and high ends of its knob's range, and `GetFramerate()` averaged over
several seconds at each: set the low end, wait for the scene to settle, average, then the
same at the high end, and put the old value back. Standing still in one spot, one setting at
a time, with nothing else changed. `note` is optional: what was in view, or what was seen.

The file's `version`, `build`, `platform` and `note` are as in `probes.lua`. Its `note` says
where it was measured, and the frame rate limits (`maxFPS`, `maxFPSBk`, `vsync`) at the time.
A knob with `costSrc = "probe"` needs a line here, at the ends of its range, and its `cost`
must be the one the frame rates give, or the page isn't written: a fall of a fifth or more
is heavy, of a twentieth or more medium, and less is light.

## A line of commands, in probes.lua

```lua
{ "fontsize", "60", "", note = "ConsoleGetFontHeight read 50." },
```

A console command that isn't a CVar, in `probes.lua`'s `commands`: the command, the value it was
run with (`""` for none), and what the console printed (`""` for nothing). A command has no
value to read back, so `note` says what was seen, or read some other way. The console's own
addon keeps every line it prints in `WTF/SavedVariables/Blizzard_Console.lua`, which a
`/reload` writes. A command with a row in the window (`@console:` in `Knobs.lua`) needs a line
here, or the tests fail.

## Adding results

Each of these ends the same way: `lua scripts/gen-ranges.lua > RANGES.md`, then the tests,
which fail while the page isn't what the script writes.

- **A probe.** `/every probe <cvar> <low> <high>` in the game, one CVar at a time, then a
  line for what it printed, in that build and platform's `probes.lua`. A knob with
  `src = "probe"` and a line of `CVars.lua` marked `probe` should each have theirs here.
- **A frame rate.** In the game, the same spot each time, standing still: a line in that
  build and platform's `costs.lua` for each setting measured.
- **Something seen, not read back**, such as a setting that only shows after a graphics
  restart: the probe's line, with a `note`.
- **A whole check from another client**: another platform, graphics API or build. In that
  client, type `/every dump`, `/every check` and `/reload`, then copy
  `WTF/Account/<account>/SavedVariables/EverySetting.lua` before the next reload or logout,
  which writes it again without them. From the repo root, at the commit that client's addon
  was built from:

  ```sh
  mkdir -p data/ranges/<build>/<platform>
  lua scripts/gen-cvars.lua <the copy> data/cvars.lua > data/ranges/<build>/<platform>/cvars.lua
  lua scripts/gen-probes.lua <the copy> "<the platform, in words>" > data/ranges/<build>/<platform>/probes.lua
  ```

  `gen-cvars.lua` prints the CVars that client has and `data/cvars.lua` doesn't, and the
  other way round. `diff data/cvars.lua data/ranges/<build>/<platform>/cvars.lua` shows the
  defaults and flags that differ. Write up what differs in the new `probes.lua`'s `note`,
  which the page prints under that client's heading. The copy holds that client's value
  for every CVar, so it isn't kept here: only what the two scripts write from it.
- **A new build of the game.** A new `data/cvars.lua` (`scripts/gen-cvars.lua`), and a
  folder for the build as its results come in. The folders of older builds stay: they're
  what earlier releases were measured on.
- **A count**, such as how many CVars the game's own options show. The Counts table that
  ends the page is written by `scripts/gen-ranges.lua` from `CVars.lua`, `Knobs.lua` and
  `data/`. Add a row there, so it's counted again for every release.
