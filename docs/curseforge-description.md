<!--
Title:   Every Setting - Hidden Settings, CVars & Console Commands
Summary: Every console variable (CVar) in WoW Forever and retail in one searchable window: view distance, ground clutter, camera distance, loot sparkles and HDR (Forever), with real ranges, undo, FPS before and after, and your values set again at every login.
Gallery: the images in docs/screenshots/, a pair taken in the world first: clutter-48 and
         clutter-256, then camera-2 and camera-4, view-1000 and view-10000, then window.jpg,
         cvars, kept, styles, presets, situations, locks, camera, search and export.
Paste everything below this comment into the description. The README has the full guide.
-->

# Every Setting

**Set once, kept forever. Even the hidden ones.**

Every console variable (CVar) the game has, about 1,800 in WoW Forever and 1,700 in retail, in one searchable window, with the game's other console commands and 70 settings that aren't CVars. About 870 in Forever and 800 in retail get a slider, menu, checkbox or color swatch, with a range taken from that game itself. Whatever you change is set again every time you log in. For **WoW Forever** and **retail**.

## Key features

- **Every setting, searchable.** Find any CVar by name, by the game's own description, or by value (`=2048`). 314 in Forever and 258 in retail go by that game's own name for them, in your game's language.
- **Your values stay put.** The game's graphics presets overwrite hand-set values. Every Setting sets yours again at every login, or at once with **Apply now**, the game's own options among them: keep **Advanced combat logging** on for your logs, and it's on every time you log in. Tick **Put back** and it does that by itself, a second after something changes them.
- **Real ranges.** In Forever the camera zooms out to 50 yards, where the game's own slider stops at 30; in retail, as far as its engine allows (2.6). Ground clutter goes to five times the top quality level. Where the engine takes any number, type it in the box.
- **The hidden settings players ask for.** Loot sparkles and HDR (in Forever), nameplate distance, the spell queue window, the action camera, and the fifteen modified clicks the options menu never shows.
- **Undo, Redo and Reset.** Reset puts a setting back to how it was before you changed it. A setting you never move is never written.
- **Styles.** Cinematic, Immersive, Competitive, Photo, Ultra+, True Max and Action, in one pick or mixed part by part.
- **Profiles, presets and situations.** Save sets of values and share them as a line of text, and switch settings while you're in combat, mounted, in a city or in an instance, each with a preset of its own to start from.
- **Paste the commands from any guide.** Import takes `/console` lines and `SetCVar` macros as one change you can undo, and says what the game kept. Nothing pasted is ever run.
- **It tells you what happened.** A setting's tooltip says what last changed it (another addon by name, the game or the console) and where the game saves it, and the window shows your frame rate before and after a graphics change.
- **No libraries, no setup.** Type `/every`.

## Commands

- `/every` or `/everysetting`: open the window
- `/every apply`: set every value you keep again now
- `/every putback [on|off]`: put a kept setting back a second after something else changes it
- `/every reset`: put back every setting you changed
- `/every undo` and `/every redo`
- `/every profile [name]`: list your profiles, or switch to one
- `/every danger [on|off]`: change by hand the settings the game locks, where the game allows it

It's also in the game's Options under AddOns, on a key you can bind, and in the minimap's addon list, where a right-click picks a style or a profile.

## Questions

**How is this different from Advanced Interface Options?** Its CVar browser gives each CVar a text box. Every Setting gives about 870 a real control, keeps what you change, puts back what you had before, and has Undo, profiles, styles and situations.

**Is this allowed?** It only uses the functions the game's own options call and changes no files. The game turns down any value it doesn't allow, and Every Setting says so.

**Will it lower my frame rate?** Every Setting itself does next to nothing while you play. The settings graphics guides warn about say so on their row, and the window shows your frame rate before and after each change.

**I use another addon that changes settings.** Every Setting only writes the settings you change in it. If two addons keep the same one, the tooltip names the other addon, and Every Setting says so in chat.

## Feedback

Report bugs and ask for more settings on [GitHub](https://github.com/bstotmeister/everysetting/issues/new/choose).
