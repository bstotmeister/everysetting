# Every Setting guide

The full guide to the window and its commands. The [README](../README.md) has the overview.

## Usage

- `/every` or `/everysetting` — open the window. `/kui` works too, unless another addon uses it
- `/every apply` — set every value you keep again now, as at login
- `/every putback [on|off]` — put a setting you keep back a second after something else changes it
- `/every reset` — put back every setting you changed
- `/every undo`, `/every redo` — take back your last change, or make it again
- `/every profile [name]` — list your profiles, or switch to one
- `/every situations` — list the situations, and the preset each one uses
- `/every warning [on|off]` — show or hide the game's warning about its experimental camera settings
- `/every danger [on|off]` — danger mode: change the settings the game locks or its server enforces, by hand

Besides the commands, there are three more ways in:

- **The game's Options.** Every Setting is listed on the AddOns tab, with a button that opens the window.
- **A key.** In Options > Keybindings, under AddOns, bind a key that opens and closes the window, and another that undoes your last change.
- **The minimap's addon list.** Click Every Setting to open the window. Right-click it for a menu: pick a style or a profile, apply now, or reset everything.

The window is one list, by section (Graphics, Camera, Sound...). A section starts with its
tuned settings: the ones worth tuning, each with a name, a description and a range that
comes from the game. Under them, a button unfolds the section's other console variables (the
client has about 1,800 in Forever 1.60.1), each by its own name. The 314 Forever's options menu has go
by the game's name for them instead, in the game's language, with the CVar's name under it
and the game's tooltip: `cameraTerrainTilt` is Follow Terrain. In retail it's the 258 retail's own
options menu has, by retail's names. 79 more go by a plain name, in the words players
would search for, with the CVar's name under it too: Nameplate distance, Grass fade, Auto
loot speed, and in Graphics and Camera each one whose help or name says what it does, such
as Hardware instancing and Action combat camera. 14 of them are the CVars only Windows has,
which the game's options don't show: Raw mouse input, Windows Game Bar support, Chroma
lighting effects and the VRS settings. A raid twin, the copy of a graphics CVar the game uses in raids, goes by the name of
the CVar it stands in for: `RAIDfarclip` is View distance (raid). The rest go by the CVar's
own name, and the tooltip says it has no plain name yet. Where the game's range or options are known, a CVar gets a slider, menu or checkbox, and the box beside it takes any
value. A setting that packs several on/off flags into one value, such as what a nameplate's cast bar shows,
gets a menu with a tick for each flag, and a color gets a swatch that opens the game's
color picker. A graphics menu greys out what the game says this computer can't use, and says
why in the option's tooltip, as the game's own options do: Ray Traced Shadows on a card
without ray tracing, Intel XeLL on another maker's card.

After the sections, **Console commands** has the client's console commands that aren't
variables (74 in Forever 1.60.1). The few that take a value with a known range have a row like a
setting's: the camera tilt limit (`pitchLimit`, up to 90 to look straight down), physics
(`physEnable`), and the console window's text size and five colors. A value you set there
is kept, and Every Setting runs the command with it again at each login. A value given to one
anywhere else, by `/console` in chat, in the game's console window or by another addon, shows
in its row at once, with what gave it in the tooltip. The game can't be asked for the tilt
limit's or physics' value, so their rows show the last value given this session, and Reset
can't put back what they were before: a game restart does.
The rest are listed by name, such as `GxRestart`, `TakeScreenshot` and `cvarlist`, each
with what it does, in the game's own words where it has some. **Run** runs one as
`/console` would and shows in chat what it printed, which otherwise goes only to the
game's console window. It runs only the 39 that were tried in Forever and retail and found safe
with nothing after them, such as `ver`, `GxCurrentGPU`, `cvarlist`, `reloadUI` and
`ToggleWindowMode`. Others the
game refuses from an addon (`quit`, `logout`) or can do harm with nothing after them
(`cvar_default` resets every CVar to its default), so for the rest Run is greyed out. The
**/** button on each shows `/console <command>`, to copy and type in chat.

Search looks through all of them, unfolded or not, by name, description or CVar, and by
value: `=2048` finds the settings at 2048 (and `=1` finds `1.000000` too). In a game client
in another language, a setting's English name in Every Setting finds it too, as a guide
gives it. **Changed** shows
only what you've changed in Every Setting, **Tuned** only the tuned settings, and the type
menu only the checkboxes, sliders, menus, flag menus, colors, text boxes or commands.

**Not default** shows every setting that isn't at the game's default, whatever set it: Every
Setting, the game's own options, a `/console` command or another addon. Each section's
button in the sidebar counts them, and a grey bar down a row's left edge marks one Every
Setting doesn't keep (the amber bar is one it keeps). Three kinds are left out:

- Other and Debug and development, which are mostly what the game remembers and switches
  for its developers. Their buttons still count them: pick one to list it.
- The settings the game's graphics quality settings set, such as view distance and shadow
  resolution, with their raid twins. No quality level keeps their default (view distance is
  1000 by default and 10000 at the top level), so the quality setting itself is the one
  that shows.
- The values the game writes for itself: the language the launcher set, what Battle.net
  passes it, what its hardware detection found (such as the graphics API it picked, and
  records stamped with the game's version), and what the login screens have shown once.
  Nobody chose these. Kept, they'd be set again at every login, and go with an exported
  profile to someone else's computer. They're still listed in their sections, and one you
  set there is kept like any other.

While it's ticked, **Keep these** takes the status line's place: it keeps what the list
shows at the values it has now, in the profile in use or in a new copy of it. Nothing
changes in the game, and one Undo takes it back. From then on Every Setting sets those
values again at each login, and Export shares them: the quickest way to a first profile.
Settings the game locks or its server enforces are left out, as they are from presets.

Click a section's title (Graphics) or a group's (Draw distance), or the plus or minus
beside it, to fold it down to that title. **Collapse all** folds every section, and once
they're all folded it reads **Expand all**, which opens every section and group again.
Picking a section in the sidebar unfolds it. Under the section at the top of the list,
the sidebar lists its groups (Camera, Action camera); picking one unfolds it and goes
to it. When they don't all fit, the sidebar scrolls with the mouse wheel. The window
remembers what's folded, and a search still shows everything it finds, folded or not.

Drag the grip in the window's bottom-right corner to make it bigger or smaller, from 75% to
150%. Double-click it to go back to 100%. Every character uses the same size.

A setting you change is kept at your value: Every Setting sets it again at every login, because
the game's graphics presets overwrite hand-set values. Settings you never changed are
never written.

When something else changes settings you keep during a session (a Graphics Quality level
in the game's options, or another addon), the status line at the top of the window says so
and counts them: "The game changed 6 kept settings." **Apply now**, beside it, sets
them again, with the same rules as a login: what the game set is what Reset then puts back,
and settings the game locks in combat wait until it ends. `/every apply` and the minimap
entry's menu do the same. It isn't a change of yours, so Undo doesn't take it back. A
setting a situation holds isn't counted: its own value comes back when the situation ends.

So mid-session, "kept" means set again at the next login or with Apply now, and the game
or another addon can change a kept setting until then. To have Every Setting put one back by
itself, tick **Put back** in the game's Options, under AddOns > Every Setting, or type
`/every putback on`. It's off unless you turn it on, for every character. Then, a second
after the last change (so a Graphics Quality level that writes twenty settings is answered
once), Every Setting does what Apply now does, with three exceptions:

- A setting you change on its own in the game's options, while they're open, is taken as
  your choice: Every Setting keeps the new value from then on, and says so in chat. A
  quality level, which changes several settings at once, is put back.
- A setting whose change waits for a restart is left for Apply now.
- When another addon keeps changing a setting back, Every Setting stops after three rounds,
  leaves that one alone until the next login, and says in chat which addon it was. Turn
  that setting off in the other addon to keep yours.

Some settings don't show a change at once, and their tooltips say what it waits for: a
graphics restart (the graphics API and card, triple buffering and the four compatibility
settings), an update of the game's window (the monitor, the display mode, the window size,
vertical sync and the notch mode) or the next start of the game (physics interactions).
They're the ones Blizzard's own options restart the graphics for, update the window for,
or say need a restart. Two more, in Forever, wait only when they're turned off, as seen in the
game: HDR output, for a graphics restart, and the loot sparkle, for the next login (a reload or a
graphics restart isn't enough). Once one has changed, **Restart graphics** or **Update
window** appears at the bottom of the window and does it. [RANGES.md](../RANGES.md) lists them
with the evidence for each.

**Loot sparkles**, under Graphics in Forever (retail has no such CVar), is one checkbox for
the two commands the guides give.
The sparkle on loot and quest objects (`outlineModeShowLootEffectWhenDisabled`) stands in
for the outlines, so it only shows with the game's Outline Mode off (`graphicsOutlineMode`,
and `raidGraphicsOutlineMode` for raids). Ticking it sets all three and keeps them, as one
change that one Undo takes back. The sparkle shows at once. Unticking it, or Reset, puts
the outlines back as they were, but the sparkle stays until you log out and in again. A
Graphics Quality change in the game's options turns Outline Mode back on, which hides the
sparkle. It's the setting the game's presets undo most visibly, and the status line then
counts it among the settings the game changed: **Apply now** turns the outlines off again
at once, **Put back** does it a second later by itself if it's on, and the next login does
too.

**HDR**, under Graphics in Forever (retail has none of its CVars), has a group of its own: HDR output, and the two switches that
make the game use your brightness and peak brightness in place of the ones the display
reports. The two values, HDR brightness and HDR peak brightness, in nits, are boxes with
Graphics' other CVars: the engine keeps any number for them, so there's no range for a
slider. Turned off after the graphics last started with it on, HDR output garbles the
colors until the graphics restart, and its row says so.

Hover a setting for what it does, its value, the game's default, its range and its CVar
(or, for one that isn't a CVar, the game's functions for it).
The tooltip also says where the game saves it: for your account, for each character, or on
this computer only. And it says what last changed it since Every Setting loaded: another
addon by its folder name, Every Setting, the game, the console, or a `/run` line or macro.
When another addon changes a setting you keep, Every Setting says so in chat, once a
session for each setting, and `/every apply` sets yours again. That's the usual answer to "I set it and it changed back".

Change a graphics setting, or apply a style, and the status line at the top of the window
shows the frame rate before and after: `Ground clutter density 48 to 256: 88 to 64 fps`.
It's the game's own frame rate, averaged over the two seconds before the change and over
three seconds after it, once the scene has had a second to settle. Stand still while it
measures: a reading taken while you move or turn, while the camera moves or in combat
would mean nothing, so the line says it was skipped. It also says when the frame rate sits
at the game's frame rate limit (or the limit while the game is in the background), and
when vertical sync is on, which holds it to the screen's rate. A style applied whole is
remembered: hovering it in the Styles menu gives the frame rate it gave you last time.

The settings every graphics guide warns about (view distance, ground clutter density and
distance, shadow resolution, water reflections and volumetric fog) say how much they cost
under their name and in their tooltip: light, medium or heavy, and where that comes from.
For now it's the guides' word: measured on a Mac in the Forever client, at one spot, none
of the six moved the frame rate by more than 5%. [RANGES.md](../RANGES.md) has the numbers,
and what a measured rating takes.

A slider, and a number typed in the box beside it, stay inside the setting's range. Ten
sliders are the exception: view distance, horizon start and distance, the terrain,
building, prop and creature detail distances, indirect lighting (Forever's), shadow cascades and
creature shadow distance. The engine keeps any number for those, so their range is the one Forever's own
quality levels use, and the box takes a number past it, such as the `horizonStart 6000` a
guide gives. It's set as typed, the box shows what the game kept, and the row says the
value is past the game's top level, or below its lowest. Only a number typed in the box
goes past: the slider, styles, presets and imported text stay inside the range. A
situation given such a value (**Use what you've changed since login**) uses it as typed.

- **Reset** puts a setting back to what it was before you changed it. Right-click Reset
  for the game's own default instead. **Reset all** offers both, for everything you've
  changed, or the values another profile keeps.
- **Undo** and **Redo** step through the changes you've made since you logged in.
- **/**, at the right end of a row, shows the command that sets the setting to the value
  in its box, typed or as it is, to copy and type in chat or put in a macro:
  `/run SetCVar("farclip", 5000)`, the game's own function where it has one
  (`/run SetAutoDeclineGuildInvites(true)` for a setting that isn't a CVar), or
  `/console pitchLimit 89` for a console command's row. Showing it sets nothing. A value
  set by typing it isn't kept: a value Every Setting keeps for that setting is set again
  at the next login, or a second later with Put back on. A CVar the game locks in combat
  can't be set that way in combat either.
- **Profiles** are named sets of kept values ("Raid night", "Screenshots"). Switching sets
  the new profile's values and puts back what only the old one kept. Profiles are shared
  by all your characters, and each character remembers which one it's on.
- **Export** shows a profile as a line of text to share, and **Import** makes a profile
  from one. **As /console** in Export shows the same settings as `/console` lines to paste
  into chat or a guide, with a `/run SetCVar` line for a value `/console` can't carry.
  Danger settings are left out of both, and the settings that aren't CVars out of the
  `/console` lines, which can't set them, but for a console command's row, which gets its
  own line (`/console pitchLimit 89`).
- **Import** also takes the commands from any guide: paste them in, one per line, in any
  of the forms guides use, mixed:

  ```text
  /console groundEffectDensity 256
  /run SetCVar("cameraDistanceMaxZoomFactor", 4)
  /script C_CVar.SetCVar("weatherDensity", "3")
  SET horizonStart "4000"
  groundEffectDist 500
  ```

  They're set in the profile in use as one change, which one Undo takes back, and need no
  name. A report then says how many were set, which the game turned down or changed
  (`horizonStart 6000` is held to the slider's 4000, as all imported text is), which names
  this client doesn't have, and which lines aren't settings at all (`/console ActionCam
  full`, `gxRestart`). Nothing pasted is ever run: a line is read for a setting's name and
  a value, and a `/run` or `/script` line only when it's one `SetCVar` call with both
  written out. A line for a console command with a row of its own (`/console pitchLimit
  89`) sets that row, as a CVar's line does: Every Setting runs its own command with the
  value it took, held to the row's range. Danger settings and locked ones are left alone,
  as presets leave them, and nothing is imported in combat.
- **Presets**, on each section's header, are named sets of values for that part of the
  list. Picking one sets just the settings it lists and leaves the rest of your profile
  alone. Graphics and its groups have Low, Medium, High and Ultra built in, which are
  levels of the game's own quality settings. The styles are there too, for just that part:
  Cinematic under Camera sets only its camera. You can save the settings you've changed
  under a header as a preset of your own, export them as text or `/console` lines, and
  import someone else's or a guide's: importing a whole profile's text under Camera takes
  only its camera settings.
- **Situations** give you different settings while something is true: in combat, mounted,
  in a city or inn, or in an instance. To set one up, change the settings the way you want
  them there, then click **Situations...**, pick the situation, and pick **Use what you've
  changed since login**. Your profile goes back how it was, and the situation uses your
  changes whenever it's on. A situation can also use any saved preset, or its own, built in,
  which none uses until you pick it in its menu: **In combat**, enemy nameplates, no rain or
  snow, and room to zoom the camera out on the whole fight; **Mounted**, the game's top view
  and horizon distance, and room to zoom out; **In a city or inn**, the game's middle levels
  of spell effects and particles, where crowds cost frames; **In an instance**, Advanced
  combat logging (the detail log sites ask for, while `/combatlog` is on) and no weather.
  Its values are held to your game's ranges, so the camera zooms out to 2.6 in retail. Use
  what you've changed since login while it's picked, and your changes go on top of its
  values, in a preset of your own. Its values are only borrowed: each setting goes back when it ends. When two are on, the one higher in the
  list wins a setting. Settings the game locks in combat, ones that need a restart, and
  the ones that aren't CVars are left out.
- **Styles**, at the top of the window beside the profile, are built-in presets that span sections and set a
  whole look and feel in one pick: Cinematic (Ultra+'s graphics, and a camera that turns,
  follows and zooms slowly and tilts down as you zoom out), Immersive (high graphics with
  Ultra+'s effects, a camera that tilts down as you zoom out, and sound from where your
  character stands), Competitive (medium graphics with clutter, weather, haze and glare
  off, and the whole fight on screen), Photo (Ultra+ with sharper shadows and thicker
  ground clutter that reaches further, and PNG screenshots), Ultra+ (the game's Ultra, with
  the effects its quality settings leave alone switched on), True Max (Photo's shadows and
  clutter, with objects drawn from much further away and the smallest ones not culled,
  which is heavy) and Action (just the action camera, over the shoulder, to pick for that
  part with another style).
  At the game's defaults, Ultra+ adds two things to the game's Ultra: in Forever bloom and
  blended shadow cascades, in retail (which has no bloom) fog and blended shadow cascades.
  Its other effects (the full-screen glow, specular shine and footprints, and fog in
  Forever) are on already unless you've turned them off. True Max doesn't
  go past the game's Ultra in view distance, horizon or the terrain, building and prop
  detail distances: Ultra is already the top of their sliders, and the engine takes a
  number past it only typed in the box beside the slider.
  Only Cinematic, Immersive and Action change the camera. Competitive, Photo, Ultra+ and
  True Max leave it as you have it, but for how far out Competitive and Photo let it zoom:
  picked after Action, they leave it over your shoulder.
  Cinematic and Immersive give the same camera: behind you rather than over your shoulder,
  tilting down as you zoom out (dynamic pitch), free to move your character off center,
  and turning toward neither the enemy you target nor what you talk to. Picking one after
  Action takes the camera off your shoulder.
  The game keeps one of two motion sickness controls on, and its Motion Sickness checkbox
  swaps them: keeping your character centered, or reducing camera movement. Cinematic and
  Immersive swap them the same way, since dynamic pitch moves your character off center
  and still shows with camera movement reduced. Over the shoulder doesn't show while
  either is on, so Action turns both off.
  Those three styles use the game's experimental camera settings, so the game
  asks you to accept them; its Disable button turns them off and Every Setting stops keeping
  them. To keep them without the warning at each login, tick Hide camera warning at the
  bottom of the window. Hover a style in the menu for
  what it's for and how many settings it sets. The Styles panel has a row for each part of
  a style (draw distance, shadows, camera and so on): picking a style puts every row on it,
  and any row can take another style's values, a built-in or saved preset for that part, or
  **Keep mine** instead, so you can take Cinematic, keep your own camera and put shadows on
  High. Each row starts on the style or preset that's set there now.
  **Apply** sets them all as one change, which one Undo takes back. A style's values are
  kept like any other change, and nothing links your profile to the style afterwards. To switch a look on and off, **Save as** a new profile first and pick
  the style there. They live in `EverySetting/Styles.lua`, and set only tuned settings, so every
  value is inside a known range. In retail a value past its range is held to it: Photo's and
  Competitive's camera to 2.6, and a shadow size retail lacks to the one below it.
- **Locks**: tick the box beside a setting, or beside a group's or section's title, and
  styles and presets leave it alone. You can still change it by hand. A lock doesn't stop
  the game or another addon changing it: the next login, or Apply now, sets a value you
  keep again. Apply True Max, lock
  Ground clutter, then apply Cinematic: the ground clutter stays where True Max put it. A section's
  box locks all of its tuned settings, not its other CVars. **Lock all**, beside Collapse
  all, locks every tuned setting, and reads **Unlock all** once they're all locked. Each
  part in the Styles panel has the same box as its group in the list, and the box beside
  Style at the top locks every part. Locks are your account's, not a profile's.
- **Danger mode**: about 70 settings are greyed out and left alone: `TurnSpeed`, the
  keyboard turn rate, which the game's server enforces, and the ones the client marks
  locked or read-only. Tick **Danger mode** at the bottom of the window, or type
  `/every danger`, and a red **Danger** section at the end of the list gathers them, in
  four groups: **Server-enforced**, **Locked, set indirectly** (through a function of the
  game's own), **Locked, can't be changed** and **Read-only**. The first two change by hand
  only: styles, presets, situations, Import and Export still leave them
  alone. `TurnSpeed` gets a slider from 1 to 540 degrees a second (180 is the game's
  default). Seven voice chat settings the game locks take a change, each through the
  game's own voice function: output and input volume, microphone sensitivity,
  push-to-talk or open mic, the microphone and the speakers (each a menu of the devices
  the game offers now), and the push-to-talk key (its box takes the keys' names:
  `LCTRL LSHIFT`). Seven more take one through the game's own function for each: the
  roles you sign up as in the group finder and in battlegrounds (each a menu of ticks),
  the group finder's advanced filter (a menu of ticks) and its minimum rating, the pet
  journal's sort, and the wardrobe's show collected and show uncollected. By the game's
  code, its wardrobe sets those two back to showing collected only each time its filter
  menu opens, and Every Setting sets them again at the next login. Saving the advanced filter also writes
  `lfgListAdvancedFilterRemovedActivities`, the dungeons it leaves out. Fifteen more are
  filters, each a menu of ticks that the game's own function sets one filter at a time: the
  mount journal's (collected, sources, types), the pet journal's (collected, sources,
  families), the toy box's (collected, sources, expansions), the heirlooms' (collected,
  sources), the wardrobe's sources and sets, the transmogrifier's sets, and which guild news
  shows. A tick is a filter that's on, as in the game's own menus. While **Only show
  collected** (`onlyShowCollectedItemsInJournal`) is on, the game puts the mount and pet
  journals' filters back to its defaults when the collections window first opens (and the
  toy box's, by its code), and Every Setting sets them again at the next login. Seven more
  are lists, each a box of IDs or names with a space between, that the game's own
  functions change an entry at a time: the quests you watch (by quest ID: the ones watched
  by hand, which in Forever is every quest as it's accepted), the recipes tracked and the
  recrafts tracked (by recipe ID, and a recipe the character doesn't know can be tracked
  too), the tutorials the game has shown (by ID), the group finder's search languages
  (`esMX ptBR`), the advanced filter's dungeons left out (by activity group) and the
  dungeon finder's dungeons (by dungeon ID). Every Setting reads each as the game has it
  now: the game writes the quests', the recipes' and the tutorials' CVars only at a reload
  or logout. Nothing takes one tutorial off, so taking one off takes them all off and flags
  the rest again. A kept list is put back as it was kept at each login, so it undoes what
  was tracked or shown in the game since, on every character that uses the profile. A
  list's command is longer than chat takes past about four quests or recipes, or eight
  dungeons. The game offers no way to change the others it locks or makes read-only, from
  an addon or typed in chat (each was tried in 1.60.1), so those stay greyed out in danger
  mode too, with ` (locked)` or ` (read-only)` after their name. Their rows have no lock
  box, and only in danger mode do they have the **/** button other rows have, which shows
  the command for the value (`/run SetCVar("TurnSpeed", 540)`, or the game's own function
  where it has one), to copy, though for the greyed-out ones it changes nothing.
  Turning it off leaves them as they are, and Every Setting stops keeping them. It's your
  account's, not a profile's.

  The game gives an addon no way in to these:
  - No function an addon can call: `GamepadConstrainedGroundTargetEnabled`,
    `GamepadConstrainedGroundTargetMaxRange`, `UseKeyHeldSpellErrorPollTime`,
    `minimapShapeshiftTracking`, `collapsedCurrencyCategoryDefaults`,
    `characterSocialRestrictionSettingsApplied`, `unlockedMajorFactions`,
    `accountNeedsTurnStrafeDialog`, `characterNeedsTurnStrafeDialog`, and two stamps the
    client keeps for itself, `lfgListAdvancedFiltersVersion` and `petJournalFilterVersion`.
  - A function that only goes one way: `latestTransmogSetSource` and
    `perksActivitiesPendingCompletion` (each only clears it), `trackedQuests` (the quests
    the game watches by itself: an addon can take a watch off, and one it adds is watched
    by hand), `seenAgeVerificationRestrictionState` and `seenRegionalChatDisabled` (they only
    acknowledge), `actionedAdventureJournalEntries` and `lastAttemptedExternalEventURLHash`
    (the game notes them when it opens a window or a web page for you).
  - Nothing in Forever for the game's function to change: `trackedAchievements` (the game
    says none of its achievements can be tracked), `trackedWorldQuests` and
    `hardTrackedWorldQuests` (its function took no other quest, and Forever has no world
    quests), `trackedPerksActivities` (it has no Trading Post activities),
    `trackedInitiativeTasks` (no neighbourhood), `lfdCollapsedHeaders` (its dungeon
    finder's list has no headers) and `eventReminders` (no scheduled events).
  - Read-only: `imageSharingPublishCooldown`, `nameplateShowCastBars`, `portal` and
    `serverAlert`.
  - Only at a transmogrifier: `transmogrifyShowCollected`, `transmogrifyShowUncollected`
    and `transmogrifySourceFilters`. Anywhere else the game's function for them sets the
    wardrobe's instead, and at a transmogrifier the game sets the first itself each time a
    slot is picked.
  - A function that can't be told which one: `currencyCategoriesCollapsed`, the currency
    headers folded. It holds currency categories by ID, and its function,
    `C_CurrencyInfo.ExpandCurrencyList`, folds a header by its place in the list as shown.
    The list has a header only for a category the character has a currency in, and a header
    doesn't say which category it is: only its name does, and two can share a name.

## What it covers

Every Setting covers the game's console variables: every one the client has, read from the
client itself. The ones the game locks are listed too, and 36 of them take a change,
through the game's own function for each (see Danger mode, above). The client's other
console commands are listed after them: a few that take a value with a row of their own,
and the rest to copy, 39 of which Every Setting can also run.

It also has settings of the game's that aren't CVars, each read and set through the game's
own functions for it, and kept, set again at login, undone and reset like a CVar:

- **Modified clicks**, under Mouse and keyboard: the key held, or the key and the mouse
  button, for each of the 20 things a modified click does. Five are in the game's options
  (self cast, focus cast, mouseover cast, auto loot and pick up action). The other fifteen
  aren't anywhere in them: link in chat, try on, split a stack, compare items, open all
  bags, take all from a letter, track a quest, a recipe or a currency, the equipment and
  totem flyouts, the sticky camera and more. The game keeps them with your key bindings,
  for your account, or for this character if its Keybindings options say so.
- **Turn and strafe keys**, under Mouse and keyboard: the game's Enhanced or Classic
  movement keys, as its two buttons under Preset set them. Once you've changed the
  movement keys by hand, Every Setting leaves them alone.
- **Action bars 2 to 8**, under Action bars and spells: each on or off. A bar shows or
  hides at the next reload (`/reload`): the game's own options lay the bars out at once,
  from code an addon can't run without tainting the action bars.
- **Item quality colours**, under Accessibility: the colour of poor to legendary items.
  Chat and tooltips change at once; bags and the rest of the game's colours at the next
  reload, for the same reason.
- **Audio alerts per spec**, under Accessibility: the combat audio alerts the game keeps
  for each specialization. Saying your main and second resource (how often, what's said,
  the voice by its number, and how loud) and saying when you're targeted, for the
  specialization you're in.
- **Social**, under Chat and social: disable chat (the game's own option asks first; this
  doesn't), block guild invites, and who sees your location. The game's server keeps them.
- **Minimap tracking**, under Interface: each of the 24 kinds the minimap's tracking menu
  has, on or off, low-level quests among them.
- **Console commands that take a value**, under Console commands: the camera tilt limit,
  physics, and the console window's text size and colors. Each was tried in the game, and
  [RANGES.md](../RANGES.md) has what each took and printed. The game isn't known to save the
  first two, which Every Setting runs again at each login with the value you keep.

The game's options have a few more that aren't CVars, and Every Setting leaves them alone:
Forever's Classic or Enhanced experience and standard or high definition character models (each
changes a great deal at once), the preferred language and data centre (a change starts a
cooldown of days), and the window size, whose CVars are in the list. Whether dangerous
scripts may run is the game's to ask you.

A setting that isn't a CVar says so in its tooltip, where a CVar's shows its name. A change
made in combat waits until combat ends. Styles and situations leave them alone. A saved
preset carries them, and so does an exported profile: its text then starts
`EverySetting:2:`, which an older Every Setting won't import. A profile of CVars alone is
still `EverySetting:1:`. Export's `/console` lines leave the modified clicks out, since
`/console` can't set them, and give a console command's setting as its own `/console` line.

It leaves alone what the game keeps elsewhere and has a window of its own for. Those are
found, changed and kept there, so Every Setting doesn't list, keep or export them:

| What | Where the game has it |
| --- | --- |
| Key bindings (the modified clicks and the turn and strafe keys aside) | The game's Keybindings options, per account or per character |
| Edit Mode layouts | Edit Mode, which imports and exports a layout as text |
| Chat windows, their message types and colours | Each chat tab's own settings |
| Chat text to speech | The chat's Text to Speech settings |
| Macros | The Macros window |
| Click-cast bindings | The game's Click Casting window |
| Which addons are on | The AddOn list |
| The Cooldown Manager's layout | The Cooldown Manager's own settings |
| Bag settings and frame positions | Each bag's menu, and Edit Mode |
| What the game's own addons save (combat log filters, the battlefield map, the stopwatch) | Each one's own window |

## Where the ranges come from

The game has no API for a CVar's range, so every knob in `EverySetting/Knobs.lua` records its
source (`src`): Blizzard's settings code, the CVar's help text, a function the client
provides, setting it in the Forever client and reading back what the engine kept, or the
values the game's own quality settings and console commands set. A knob isn't added
without one. Where retail's engine keeps another range, the knob has that one too, with a
source of its own (`retail`), and retail uses it. Where the range is the game's own quality levels (`preset`), the engine keeps
any number, and the box beside the slider takes one past the range.

`EverySetting/CVars.lua` does the same for the list of every CVar: the section each is listed
under, and a control only where there's evidence for it (noted on each line). A line can
also mark its CVar as one whose change waits for a graphics restart, a window update, a
reload, the next login or a game restart, on evidence of its own. To change one, edit its
line. A CVar that isn't in the file is still listed, with just a box. The file has a line for
every CVar of the client on a Mac and on Windows; a line for one that only the other has does
nothing. Retail's own lines are at its end: the 15 CVars only retail has (two more, made by an
addon, are left as any addon's CVar is), and 17 that both games have, where retail's options
menu gives a control Forever's doesn't, or another one, such as its own Low Latency Mode menu.

[RANGES.md](../RANGES.md) lists every tuned setting with its range and its source, says how
sure each kind of source is, and shows what the client kept when the ranges were tried,
by game build and platform. It also has what the heavy settings cost (a knob's `cost`, on
evidence of its own, `costSrc`), and the frame rates measured at each end of their range. It's written for each release and ships with the addon.

To find a range yourself:

- `/every probe <cvar> <low> <high>` — sets both values, prints what the engine kept for
  each, and puts the old value back
- `/every check` — probes every knob at and one step past the ends of its range
- `/every dump` — saves the client's whole CVar list, and its other console commands, in
  the saved variables (`/reload` writes them to
  `WTF/Account/<account>/SavedVariables/EverySetting.lua`)

Probe one CVar at a time, and leave alone the ones the server enforces (`TurnSpeed` says
"capped by the server" in its help). `/every probe` leaves a danger setting alone unless
danger mode is on.

## Development

Addon source lives in `EverySetting/`. Link it into your WoW client so changes load on `/reload`:

```sh
scripts/link.sh                # _forever_ (default)
scripts/link.sh _retail_       # or any other flavor folder
```

Set `WOW_DIR` if WoW isn't installed at `/Applications/World of Warcraft` (macOS) or
`C:\Program Files (x86)\World of Warcraft` (Windows, given as WSL sees it, such as
`/mnt/d/Games/World of Warcraft`). On Windows, run it from WSL: the game can't follow a link
into WSL, so the script copies the folder instead. Run it again after each change, then
`/reload`. A copy it made has a `.copied-from` file in it, and is copied over the next time;
any other folder of that name is moved aside first, as on macOS.

The logo, the in-game icon and the README's banner are built from `docs/brand/` by
`scripts/brand.sh`, which needs Google Chrome and Python 3 with Pillow.

`data/cvars.lua` is the Forever client's whole CVar list (name, default, category, help,
flags), as `/every dump` saved it on a Mac. The tests check every knob against it, the lines
of `CVars.lua` against it and the CVars only Windows has
(`data/ranges/70938/windows-d3d12/cvars.lua`), and the knobs and retail's own lines against
retail's (`data/ranges/70783/retail/cvars.lua`) with retail's ranges. None is shipped.

`data/ranges/` holds what the client kept when the ranges were tried, by game build and
platform. `scripts/gen-ranges.lua` writes `RANGES.md` from it and from the addon's own
files, and the tests fail while the page isn't what it writes. `data/ranges/README.md` says
how results are added.

Lint and test before opening a pull request:

```sh
luacheck EverySetting tests scripts
lua tests/run.lua
```
