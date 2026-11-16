# Where the ranges come from

Every Setting 1.0.0, for WoW Forever 1.60.1 (build 70938) and WoW retail 12.1.5 (build 70783).

The game can't be asked for a CVar's range. So every slider, menu and checkbox in Every Setting
has a source, and this page lists them: where each range comes from, how sure that makes it,
and what the client kept when it was tried.

The page is written for each release by `scripts/gen-ranges.lua` in [the addon's repository](https://github.com/bstotmeister/everysetting),
from the addon's own files and the results kept in `data/ranges/` there.

## The clients

- WoW Forever 1.60.1, build 70938 (interface 16001).
- 1,797 CVars, as `/every dump` saved them on a Mac (`data/cvars.lua`).
- 14 more on Windows, which a Mac's client doesn't have, as `/every dump` saved them there
  (`data/ranges/70938/windows-d3d12/cvars.lua`): `AllowSoftwareRendererDX12`, `AllowWinRT`, `ChromaEffectsEnable`, `ChromaEffectsFactionColor`, `luaErrorExceptions`, `rawMouseEnable`, `vrsValarAlwaysOn`, `vrsValarEnvLuma`, `vrsValarLPUseCornerSampling`, `vrsValarUseAsyncCompute`, `vrsValarUseMotionVectors`, `vrsValarUseWeberFechner`, `vrsValarWeberFechnerConstant`, `winePlatformTTS`.
- What its graphics quality settings set, level by level, is from build 70888 (`data/presets.lua`).
- The client locks 65 of them and marks 4 read-only, and the game's server enforces 1 (`TurnSpeed`).
  Every Setting leaves those alone outside danger mode. 82 can't be set in combat.

Every Setting runs in WoW retail too: 12.1.5, build 70783 (interface 120105), whose 1,683 CVars are in
`data/ranges/70783/retail/cvars.lua`. The ranges here are Forever's: [The tuned settings](#the-tuned-settings) says where
retail's differ, and which of them retail lacks, and [In WoW retail](#in-wow-retail) has the lines
retail has of its own for the other CVars.

## Sources

The engine holds only some CVars to a range. For the rest it keeps whatever it's given, so
a range here is either one the engine enforces or one the game itself uses.

| Source | Where the range comes from | How sure | Tuned settings | Other CVars |
| --- | --- | --- | --- | --- |
| `ui` | Blizzard's settings code (the `forever` branch of wow-ui-source, or `live` for a line of retail's) has that control for it. | The game's own options offer the same values. | 2 | 312 |
| `help` | The CVar's help text in the client gives the range or lists the values. | The game's own words for it. Not every one has been tried against the engine. | 24 | 325 |
| `api` | A function the client provides gives the range. | Asked of the client as it runs. | 0 | 0 |
| `probe` | It was set in the client, and the engine kept these values. Past its own range the engine turns a value down, and usually says the range in its log. | Measured, in the clients under [What the client kept](#what-the-client-kept). Another build, platform or graphics API may keep other values. | 34 | 30 |
| `preset` | The values the game's own graphics quality settings give it, from their lowest level to their highest, and the engine's default. | The engine keeps any number for these. The range is the one the game itself uses, not a limit: the slider, styles and presets stay inside it, and the box beside the slider takes a number past it. | 10 | 0 |
| `command` | The game's own console command for it (`/console ActionCam full`) only sets 0 and 1. | The engine keeps any number for these. It's a checkbox because that's how the game sets it. | 4 | 0 |
| `code` | Blizzard's interface code only reads or sets it as on or off. | A checkbox for how the game uses it. The engine may keep other values. | 0 | 19 |
| `name` | Its name: showX, enableX and the like. | The weakest: nothing but the name says it's on or off. | 0 | 61 |
| `as X` | It's a raid twin, given the control of the CVar it stands in for. | As sure as that CVar's. | 0 | 49 |

## The tuned settings

The 74 settings in `EverySetting/Knobs.lua`. Every Setting holds each to the range or options here, but for
a number typed in the box of one whose source is `preset`.

| Group | Setting | CVar | Range or options | Source |
| --- | --- | --- | --- | --- |
| Draw distance | View distance | `farclip` | 1000 to 10000, in steps of 100 | `preset` |
|  | Horizon start | `horizonStart` | 400 to 4000, in steps of 100 | `preset` |
|  | Horizon distance | `horizonClip` | 1600 to 10000, in steps of 100 | `preset` |
| Ground clutter | Ground clutter density | `groundEffectDensity` | 16 to 256, in steps of 8 | `probe` |
|  | Ground clutter distance | `groundEffectDist` | 40 to 500, in steps of 10 | `probe` |
| Level of detail | Object fade distance | `lodObjectFadeScale` | 50 to 5000, in steps of 10 | `probe` |
|  | Small object culling | `lodObjectCullSize` | 1 to 100, in steps of 1 | `probe` |
|  | Terrain detail distance | `terrainLodDist` | 200 to 650, in steps of 25 | `preset` |
|  | Building detail distance | `wmoLodDist` | 250 to 400, in steps of 10 | `preset` |
|  | Prop detail distance | `doodadLodScale` | 50 to 150, in steps of 5 | `preset` |
|  | Creature detail distance | `entityLodDist` | 5 to 10, in steps of 1 | `preset` |
| Textures | Ground texture blending | `terrainMipLevel` | 0 = Full detail; 1 = Reduced | `probe` |
|  | Character textures | `componentTextureLevel` | 0 = Full detail; 1 = Reduced; 2 = Lowest | `probe` |
| Effects | Loot sparkles | `outlineModeShowLootEffectWhenDisabled` | On or off (1 or 0) | `help` |
|  | Particle density | `particleDensity` | 0 to 100, in steps of 5 | `probe` |
|  | Spell effect density | `spellVisualDensityFilterSetting` | 1 = Minimum; 2 = Reduced; 3 = Performance; 4 = Full | `help` |
|  | Weather | `weatherDensity` | 0 = None; 1 = Light; 2 = Medium; 3 = Heavy | `probe` |
|  | Footprints | `showfootprintparticles` | On or off (1 or 0) | `help` |
|  | Full-screen glow | `ffxGlow` | On or off (1 or 0) | `help` |
|  | Death effect | `ffxDeath` | On or off (1 or 0) | `help` |
|  | Nether effect | `ffxNether` | On or off (1 or 0) | `help` |
| Lighting and water | Sun shafts | `sunShafts` | 0 = Off; 1 = Low; 2 = High | `probe` |
|  | Indirect lighting | `giQuality` | 1 to 4, in steps of 1 | `preset` |
|  | Volumetric fog | `volumeFog` | On or off (1 or 0) | `probe` |
|  | Volumetric fog quality | `volumeFogLevel` | 0 to 4, in steps of 1 | `probe` |
|  | Fog indoors | `volumeFogInterior` | On or off (1 or 0) | `probe` |
|  | Bloom | `bloomEnable` | On or off (1 or 0) | `help` |
|  | Shine | `specular` | 0 to 1, in steps of 0.05 | `help` |
|  | Water reflections | `reflectionMode` | 0 = None; 1 = Screen space, without the sky; 2 = Screen space; 3 = Planar | `probe` |
|  | Refraction | `refraction` | 0 to 2, in steps of 1 | `probe` |
|  | Water ripples | `rippleDetail` | 0 to 2, in steps of 1 | `probe` |
|  | Soft edges | `DepthBasedOpacity` | On or off (1 or 0) | `help` |
| Shadows | Shadow type | `shadowMode` | 0 = Blob shadows; 1 = 1 band, on units; 2 = 2 bands, on units and terrain; 3 = 3 bands, on units and terrain; 4 = 4 bands, on units and terrain | `probe` |
|  | Shadow resolution | `shadowTextureSize` | 512; 768; 1024; 1536; 2048; 4096 | `probe` |
|  | Shadow cascades | `shadowNumCascades` | 1 to 4, in steps of 1 | `preset` |
|  | Creature shadow distance | `entityShadowFadeScale` | 10 to 50, in steps of 5 | `preset` |
|  | Soft shadows | `shadowSoft` | On or off (1 or 0) | `probe` |
|  | Blend shadow bands | `shadowBlendCascades` | On or off (1 or 0) | `probe` |
| Sharpness and smoothing | Always sharpen | `ResampleAlwaysSharpen` | On or off (1 or 0) | `help` |
|  | CMAA2 quality | `CMAA2Quality` | 0 = Low; 1 = Medium; 2 = High; 3 = Ultra | `help` |
|  | CMAA2 extra sharpness | `CMAA2ExtraSharpness` | On or off (1 or 0) | `help` |
|  | Dynamic render scale (beta) | `DynamicRenderScale` | On or off (1 or 0) | `help` |
| HDR | HDR output | `HDROutput` | On or off (1 or 0) | `help` |
|  | Set the brightness | `useHDRBrightness` | On or off (1 or 0) | `help` |
|  | Set the peak brightness | `useHDRPeakBrightness` | On or off (1 or 0) | `help` |
| Frame rate and screenshots | Loading screen frame rate | `maxFPSLoading` | 10 to 100, in steps of 5 | `probe` |
|  | Screenshot quality | `screenshotQuality` | 1 to 10, in steps of 1 | `help` |
|  | Screenshot format | `screenshotFormat` | jpeg = JPEG; png = PNG; tga = TGA | `probe` |
| Camera | Max camera distance | `cameraDistanceMaxZoomFactor` | 1 to 4, in steps of 0.1 | `probe` |
|  | Zoom speed | `cameraZoomSpeed` | 1 to 50, in steps of 1 | `probe` |
|  | Zoom catch-up rate | `cameraDistanceRateMult` | 0.1 to 10, in steps of 0.1 | `probe` |
|  | Camera turn speed, sideways | `cameraYawMoveSpeed` | 1 to 360, in steps of 1 | `probe` |
|  | Camera turn speed, up and down | `cameraPitchMoveSpeed` | 1 to 360, in steps of 1 | `probe` |
|  | Camera follow speed, sideways | `cameraYawSmoothSpeed` | 1 to 360, in steps of 1 | `probe` |
|  | Camera follow speed, up and down | `cameraPitchSmoothSpeed` | 1 to 360, in steps of 1 | `probe` |
|  | Smooth camera height | `cameraZSmooth` | 1 = Only while moving; 2 = Also while standing still | `help` |
| Action camera | Over the shoulder | `test_cameraOverShoulder` | On or off (1 or 0) | `command` |
|  | Keep your character centered | `CameraKeepCharacterCentered` | On or off (1 or 0) | `ui` |
|  | Reduce camera movement | `CameraReduceUnexpectedMovement` | On or off (1 or 0) | `ui` |
|  | Dynamic pitch | `test_cameraDynamicPitch` | On or off (1 or 0) | `command` |
|  | Dynamic pitch: your character's height | `test_cameraDynamicPitchBaseFovPad` | 0 to 1, in steps of 0.05 | `probe` |
|  | Dynamic pitch: your character's height where you can fly | `test_cameraDynamicPitchBaseFovPadFlying` | 0 to 1, in steps of 0.05 | `probe` |
|  | Turn toward your enemy | `test_cameraTargetFocusEnemyEnable` | On or off (1 or 0) | `command` |
|  | Turn toward what you interact with | `test_cameraTargetFocusInteractEnable` | On or off (1 or 0) | `command` |
| Mouse | Mouse acceleration | `mouseAcceleration` | -1 = Use the desktop's setting; 0 = Off; 1 = On | `help` |
| Nameplates | Nameplate movement speed | `nameplateMotionSpeed` | 0 to 1, in steps of 0.005 | `help` |
| Threat | Threat warning | `threatWarning` | 0 = Off; 1 = In dungeons; 2 = In a party or raid; 3 = Always | `help` |
| Sound | Footsteps | `FootstepSounds` | On or off (1 or 0) | `help` |
|  | Armor sounds, yours | `Sound_EnableArmorFoleySoundForSelf` | On or off (1 or 0) | `probe` |
|  | Armor sounds, other players' | `Sound_EnableArmorFoleySoundForOthers` | On or off (1 or 0) | `probe` |
|  | Listen from your character | `Sound_ListenerAtCharacter` | On or off (1 or 0) | `help` |
|  | Sound processing effects | `Sound_EnableDSPEffects` | On or off (1 or 0) | `probe` |
| Combat text | Classic combat text | `classicStyleWorldText` | On or off (1 or 0) | `help` |
| Spells | Spell queue window | `SpellQueueWindow` | 0 to 400, in steps of 1 | `probe` |

In WoW retail the engine keeps another range for 2 of them, and Every Setting holds them to that one there,
styles and presets too:

| Setting | CVar | Range or options in retail | Source |
| --- | --- | --- | --- |
| Shadow resolution | `shadowTextureSize` | 512; 1024; 2048 | `probe` |
| Max camera distance | `cameraDistanceMaxZoomFactor` | 1 to 2.6, in steps of 0.1 | `probe` |

Retail has no CVar for 7 of them, and its window leaves them out: `outlineModeShowLootEffectWhenDisabled`, `giQuality`, `bloomEnable`, `HDROutput`, `useHDRBrightness`, `useHDRPeakBrightness`, `classicStyleWorldText`.

`Knobs.lua` also has 70 settings that aren't CVars, such as the modified clicks and the action bars.
Each has the control and the options the game's own settings have, and none is here.

And 8 that are console commands, each set with `/console <command> <value>` and listed under
Console commands in the window. [What the client kept](#what-the-client-kept) has what each printed and did.

| Setting | Command | Range or options | Source |
| --- | --- | --- | --- |
| Camera tilt limit | `pitchLimit` | 45 to 90, in steps of 1 | `probe` |
| Physics | `physEnable` | On or off (1 or 0) | `probe` |
| Text size | `fontsize` | 10 to 50, in steps of 1 | `help` |
| Color: input | `fontcolor` | A color | `help` |
| Color: echo | `fontcolor` | A color | `help` |
| Color: warning | `fontcolor` | A color | `help` |
| Color: admin | `fontcolor` | A color | `help` |
| Color: global | `fontcolor` | A color | `help` |

## Every other CVar

`EverySetting/CVars.lua`, which ships with the addon, has a line for each of the client's CVars,
on a Mac and on Windows.
796 of them suggest a control, and name the evidence for it at the end of the line. A suggested
control is only that: the box beside it still takes any value (except `TurnSpeed`'s). The other
941 CVars have just the box.

| Control | CVars |
| --- | --- |
| Checkbox | 550 |
| Slider | 114 |
| Menu | 104 |
| Menu of ticks | 26 |
| Color swatch | 2 |

The ones whose control rests on a probe:

| CVar | Range or options | Noted with it |
| --- | --- | --- |
| `BlizzCon2026Experience` | On or off (1 or 0) |  |
| `dynamicLod` | On or off (1 or 0) |  |
| `guildNewsFilter` | A menu of ticks | set in game a flag at a time through SetGuildNewsFilter, filters 1, 2 and 9 were flags 1, 2 and 9 of a number, each on while its filter is off; the labels and the seven filters are the game's |
| `heirloomCollectedFilters` | A menu of ticks | set in game a flag at a time through C_Heirloom.SetCollectedHeirloomFilter and SetUncollectedHeirloomFilter, flags 1 and 2, each on while its filter is off; the labels are the game's |
| `heirloomSourceFilters` | A menu of ticks | set in game a flag at a time through C_Heirloom.SetHeirloomSourceFilter, sources 1 and 3 were flags 1 and 3, each on while its filter is off; the labels are the game's |
| `InputDeviceInterfaceStyle` | On or off (1 or 0) |  |
| `lfgListAdvancedFilters` | A menu of ticks | set in game a field at a time through C_LFGList.SaveAdvancedFilter, flags 1, 2, 4, 6, 7, 10, 11 and 14 were its table's true or false fields in their order; the labels are the game's |
| `lfgSelectedRoles` | A menu of ticks | set in game a role at a time through SetLFGRoles, leader was 1, tank 2 and damage 8; the game didn't take healer for a warrior, and it's 4 by the pattern |
| `lodObjectCullDist` | 1 to 200, in steps of 1 |  |
| `lodObjectMinSize` | 0 to 1000, in steps of 1 |  |
| `mountJournalGeneralFilters` | A menu of ticks | set in game a flag at a time through C_MountJournal.SetCollectedFilterSetting, filters 1, 2 and 3 were the bits of a number, each on while its filter is; the labels are the game's |
| `mountJournalSourcesFilter` | A menu of ticks | set in game a flag at a time through C_MountJournal.SetSourceFilter, sources 3 and 9 were bits 3 and 9 of a number, each on while its filter is; the only two C_MountJournal.IsValidSourceFilter takes in 1.60.1, and the labels are the game's |
| `mountJournalTypeFilter` | A menu of ticks | set in game a flag at a time through C_MountJournal.SetTypeFilter, types 1 and 5 were bits 1 and 5 of a number, each on while its filter is; type 4 is the one C_MountJournal.IsValidTypeFilter turns down in 1.60.1, and the labels are the game's |
| `particleMTDensity` | 0 to 100, in steps of 1 |  |
| `pbrLiquidDetail` | 0 to 2, in steps of 1 |  |
| `petJournalFilters` | A menu of ticks | set in game a flag at a time through C_PetJournal.SetFilterChecked, flags 1 and 2, each on while its filter is off; the labels are the game's |
| `petJournalSort` | 0 = Name; 1 = Level; 2 = Rarity; 3 = Pet type | set in game through C_PetJournal.SetPetSortParameter, level was 1 and pet type 3: the game's four sorts counted from 0 |
| `petJournalSourceFilters` | A menu of ticks | set in game a flag at a time through C_PetJournal.SetPetSourceChecked, sources 1 and 12 were bits 1 and 12 of a number, each on while its filter is, and 0 with all twelve on; the labels are the game's |
| `petJournalTypeFilters` | A menu of ticks | set in game a flag at a time through C_PetJournal.SetPetTypeFilter, types 1 and 10 were bits 1 and 10 of a number, each on while its filter is, and 0 with all ten on; the labels are the game's |
| `pvpSelectedRoles` | A menu of ticks | set in game a role at a time through SetPVPRoles, tank was 2 and damage 8; the game didn't take healer for a warrior, and it's 4 by the pattern |
| `spellClutter` | 0 to 4, in steps of 1 |  |
| `SSAO` | 0 to 4, in steps of 1 |  |
| `toyBoxCollectedFilters` | A menu of ticks | set in game a flag at a time through C_ToyBox.SetCollectedShown, SetUncollectedShown and SetUnusableShown, flags 1, 2 and 3, each on while its filter is off; the labels are the game's |
| `toyBoxExpansionFilters` | A menu of ticks | set in game a flag at a time through C_ToyBox.SetExpansionTypeFilter, expansion 1 was flag 1, on while its filter is off; GetNumExpansions() is 1 in 1.60.1, and the label is the game's |
| `toyBoxSourceFilters` | A menu of ticks | set in game a flag at a time through C_ToyBox.SetSourceTypeFilter, sources 1 and 3 were flags 1 and 3, each on while its filter is off; the labels are the game's |
| `transmogrifySetsFilters` | A menu of ticks | set in game a flag at a time through C_TransmogSets.SetSetsFilter away from a transmogrifier, filters 1 and 4 were flags 1 and 4, each on while its filter is off; the labels are the game's |
| `TurnSpeed` | 1 to 540, in steps of 1 | 540 is the most the game keeps; help: capped by the server |
| `wardrobeSetsFilters` | A menu of ticks | set in game a flag at a time through C_TransmogSets.SetBaseSetsFilter, filters 1 and 4 were flags 1 and 4, each on while its filter is off; the labels are the game's |
| `wardrobeSourceFilters` | A menu of ticks | set in game a flag at a time through C_TransmogCollection.SetSourceTypeFilter, sources 1 to 6 were flags 2 to 5, 8 and 9, each on while its filter is off; the labels are the game's |
| `waterDetail` | 0 to 3, in steps of 1 |  |

### In WoW retail

Retail's own lines are at the end of `CVars.lua` (`RETAIL_CVARS`), and take the place of Forever's in retail:
15 for the CVars only retail has, and 17 for CVars both games have, where retail's options menu
gives a control Forever's doesn't, or another one. Its other CVars have Forever's line. `ui` on one of these is
retail's settings code (the `live` branch of wow-ui-source). One with just the box says why.

| CVar | Section | In retail | In Forever | Noted with it |
| --- | --- | --- | --- | --- |
| `activeCUFProfile` | Other | Just the box | Only in retail | an earlier version's, kept in the saved settings of the account it was found on: another account's client hadn't it at all, the client gives it no default or help, and retail's interface code doesn't read it |
| `advFlyKeyboardMaxPitchFactor` | Mouse and keyboard | 1 to 10, in steps of 0.5 | Just the box | ui |
| `advFlyKeyboardMaxTurnFactor` | Mouse and keyboard | 1 to 10, in steps of 0.5 | Just the box | ui |
| `advFlyKeyboardMinPitchFactor` | Mouse and keyboard | 1 to 10, in steps of 0.5 | Just the box | ui |
| `advFlyKeyboardMinTurnFactor` | Mouse and keyboard | 1 to 10, in steps of 0.5 | Just the box | ui |
| `advFlyPitchControl` | Mouse and keyboard | 3 = Default; 2 = Backward/up; 1 = Forward/up | Just the box | ui |
| `advFlyPitchControlCameraChase` | Camera | 10 to 30, in steps of 1 | Just the box | ui |
| `auctionDisplayOnCharacter` | Other | Just the box | Only in retail | an earlier version's, as activeCUFProfile |
| `cacaoBilateralSimilarityDistanceSigma` | Graphics | Just the box | Only in retail | help: any number above 0, with no top, so just the box |
| `encounterTimelineEnabled` | Interface | On or off (1 or 0) | Just the box | ui |
| `encounterTimelineHideForOtherRoles` | Interface | On or off (1 or 0) | Just the box | ui |
| `encounterTimelineHideLongCountdowns` | Interface | On or off (1 or 0) | Just the box | ui |
| `encounterTimelineHideQueuedCountdowns` | Interface | On or off (1 or 0) | Just the box | ui |
| `graphicsComputeEffects` | Graphics | 0 = Disabled; 1 = Low; 2 = Medium; 3 = High; 4 = Ultra | 0 = Low; 1 = Fair; 2 = Medium; 3 = High; 4 = Ultra | ui |
| `graphicsParticleDensity` | Graphics | 0 = Disabled; 1 = Low; 2 = Fair; 3 = Medium; 4 = High; 5 = Ultra | Just the box | ui |
| `KioskCharacterTemplateSet` | Debug and development | Just the box | Only in retail | kiosk mode's, as Forever's KioskCharacterTemplateSet1 and 2; read-only |
| `lastLaunchedExternalEventURL` | Other | Just the box | Only in retail | the last event page the game opened outside it, kept per account; locked |
| `LowLatencyMode` | Graphics | 0 = Disabled; 1 = Built-in; 2 = NVIDIA Reflex; 3 = NVIDIA Reflex + Boost; 4 = Intel XeLL | 0 = Auto detect; 1 = Disabled; 2 = Built-in; 3 = NVIDIA Reflex; 4 = NVIDIA Reflex + Boost; 5 = Intel XeLL | ui |
| `nameplateShowFriends` | Other | Just the box | Only in retail | an earlier version's, as activeCUFProfile: retail's menu shows friendly players' nameplates with nameplateShowFriendlyPlayers |
| `nameplateStyle` | Nameplates and names | 0 = Modern; 1 = Thin; 2 = Block; 3 = Clean health; 4 = Cast focus; 5 = Legacy red | 1 = Thin; 0 = Modern; 2 = Block; 4 = Cast focus | ui |
| `Outline` | Graphics | 0 = Disabled; 1 = Quest objectives only; 2 = Quest objectives and mouseover; 3 = Quest objectives, mouseover and target | Just the box | ui |
| `playerStatLeftDropdown` | Other | Just the box | Only in retail | an earlier version's, as activeCUFProfile |
| `playerStatRightDropdown` | Other | Just the box | Only in retail | an earlier version's, as activeCUFProfile |
| `raidGraphicsComputeEffects` | Raid graphics | 0 = Disabled; 1 = Low; 2 = Medium; 3 = High; 4 = Ultra | 0 = Low; 1 = Fair; 2 = Medium; 3 = High; 4 = Ultra | as graphicsComputeEffects |
| `raidGraphicsParticleDensity` | Raid graphics | 0 = Disabled; 1 = Low; 2 = Fair; 3 = Medium; 4 = High; 5 = Ultra | Just the box | as graphicsParticleDensity |
| `SSAOType` | Graphics | 0; 1 | Only in retail | probe: the engine kept 0 and 1, and turned down 2, 3 and 9 ("Unsupported SSAO type."); the game names neither |
| `unlockedExpansionLandingPages` | Other | Just the box | Only in retail | an earlier version's, as activeCUFProfile |
| `useShadowMapping` | Graphics | On or off (1 or 0) | Only in retail | name: the engine kept 2 too |
| `volumeFogDisableLightScattering` | Graphics | On or off (1 or 0) | Only in retail | help |
| `volumeFogDisableNoise` | Graphics | On or off (1 or 0) | Only in retail | help |
| `volumeFogDisableShadows` | Graphics | On or off (1 or 0) | Only in retail | help |
| `volumeFogUse16BitTexture` | Graphics | On or off (1 or 0). Shows after a graphics restart | Only in retail | help, restart: help |

Retail's list has 2 more that only it has, and that no line names: `LibOpenRaidTempCache`, `LibOpenRaidTempCacheDebug`. Like any CVar `CVars.lua`
doesn't have, each is listed under the last section, with a box.

## Settings that wait for a restart

A change to one of these doesn't show at once. Its tooltip in Every Setting says what it waits
for, the window offers Restart graphics or Update window when that's what it is, and situations
leave these settings out.

| CVar | A change | Evidence |
| --- | --- | --- |
| `GxAdapter` | Shows after a graphics restart | `ui` |
| `GxApi` | Shows after a graphics restart | `ui` |
| `GxCompatAsyncShaderCompilation` | Shows after a graphics restart | `ui` |
| `GxCompatCommandListMultiThreading` | Shows after a graphics restart | `ui` |
| `GxCompatOptionalGpuFeatures` | Shows after a graphics restart | `ui` |
| `GxCompatWorkSubmitOptimizations` | Shows after a graphics restart | `ui` |
| `GxFullscreenResolution` | Shows once the game's window is updated | `ui` |
| `GxMaxFrameLatency` | Shows after a graphics restart | `ui` |
| `GxMaximize` | Shows once the game's window is updated | `ui` |
| `GxMonitor` | Shows once the game's window is updated | `ui` |
| `GxWindowedResolution` | Shows once the game's window is updated | `ui` |
| `HDROutput` | Shows after a graphics restart, when it's set to 0 | `probe` |
| `NotchedDisplayMode` | Shows once the game's window is updated | `ui` |
| `outlineModeShowLootEffectWhenDisabled` | Shows after logging out and in again, when it's set to 0 | `probe` |
| `physicsLevel` | Takes effect the next time the game starts | `ui` |
| `vsync` | Shows once the game's window is updated | `ui` |

| Evidence | What it is |
| --- | --- |
| `ui` | Blizzard's settings code restarts the graphics or updates the window after a change to it, or says the game needs restarting. |
| `help` | The CVar's help text in the client says so. |
| `probe` | Seen in the client: a change showed only after it. [What the client kept](#what-the-client-kept) has the note. |
| `guide` | Another addon's page or a guide says so. Not seen in the client. |

## What the heavy settings cost

A tuned setting that costs frame rate as it's turned up says so in its tooltip and under its
name: light, medium or heavy. A measured cost is how far the frame rate fell from the low end of
the setting's range to the high end, from the same spot: heavy for a fifth or more, medium for a
twentieth or more, light for less. Another machine may fall further or less, so the window also
shows the frame rate before and after a change to any graphics setting, or a style.

| Setting | CVar | Cost | Evidence |
| --- | --- | --- | --- |
| View distance | `farclip` | heavy | `guide` |
| Ground clutter density | `groundEffectDensity` | heavy | `guide` |
| Ground clutter distance | `groundEffectDist` | heavy | `guide` |
| Volumetric fog | `volumeFog` | heavy | `guide` |
| Water reflections | `reflectionMode` | heavy | `guide` |
| Shadow resolution | `shadowTextureSize` | heavy | `guide` |

| Evidence | What it is |
| --- | --- |
| `probe` | Measured in the client: the frame rate at each end of the setting's range, under [Frame rates](#frame-rates). |
| `guide` | Graphics guides and other graphics addons rate it so. Frame rates measured for it, if any, are under [Frame rates](#frame-rates), and didn't show the cost. |

### Frame rates

Each is `GetFramerate()` averaged over several seconds, standing still, with the setting at one
end of its range and then the other, one setting at a time, and put back after.

#### WoW Forever 1.60.1 (build 70938), Mac, Metal

Standing still on a snowy road with the window closed, the game in front: snow and pines in view, no water and little ground cover. The rest as the player has it: graphics quality 9 (Ultra), render scale 0.5, vertical sync on, no frame rate cap (`useMaxFPS` 0), the cap in the background at 30 (`maxFPSBk`, not in play). Each value set, 4 seconds to settle, then `GetFramerate()` every quarter second for 5 seconds, and the old value put back. The frame rate stayed near 80 for all six: none moved it by more than 5%, and three went up. At this spot something else holds the frame rate, so these back no rating, and the six stay on guides' word (`guide`).

| CVar | Low end | Frame rate | High end | Frame rate | Fall | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `farclip` | 1000 | 81 fps | 10000 | 83 fps | -3% |  |
| `groundEffectDensity` | 16 | 78 fps | 256 | 80 fps | -3% | Little ground cover in the snow. |
| `groundEffectDist` | 40 | 84 fps | 500 | 80 fps | 5% | Little ground cover in the snow. |
| `shadowTextureSize` | 512 | 84 fps | 4096 | 81 fps | 4% |  |
| `reflectionMode` | 0 | 83 fps | 3 | 84 fps | -1% | No water in view. |
| `volumeFog` | 0 | 84 fps | 1 | 83 fps | 1% |  |

## What the client kept

From `/every probe` and `/every check`: each sets a CVar, reads back what the engine kept, and
puts the old value back. A value is under Not kept when the CVar read something else after
it was set: the engine turned it down, or changed it. The notes are what the engine said in
its log, or what was seen.

### WoW Forever 1.60.1 (build 70938), Mac, Metal

Each tuned setting's range ends or options and, for a slider, one step past each end, tried one setting at a time. Not tried: `nameplateMotionSpeed`, which the client marks as not to be set in combat; the six `test_camera` settings, which raise the game's warning when one is changed, but for one probe of over the shoulder with the warning hidden; `DynamicRenderScale`, which changes the size the game renders at; and any value below zero, but over the shoulder's -10. The six HDR settings were set one at a time on the Mac's own display, which shows HDR, and what the game's window showed was compared in screenshots: at once, after a reload (`HDRFactor`) and after a graphics restart. The loot sparkle (`outlineModeShowLootEffectWhenDisabled`) was turned on and off through its checkbox, which turns Outline Mode off and back on with it, in front of two quest objects, and watched in screenshots: at once, after a reload, after a graphics restart and after logging out and in again. The game wasn't started again for it. The hidden settings players ask for most were each set to two values far apart, one setting at a time, and where the engine turned one down, the range's ends and the values past them. The console commands that take a value were run one at a time too. Not tried: physCulling, physCullingDist and the six physVeg values with a value, which nothing reads back to put back; SetGraphicsQualityRAID with none; and what any of them does after the game is started again.

77 CVars, 66 of them tuned settings.

| CVar | Kept | Not kept | Notes |
| --- | --- | --- | --- |
| `farclip` | 900, 1000, 10000, 10100 |  |  |
| `horizonStart` | 300, 400, 4000, 4100 |  |  |
| `horizonClip` | 1500, 1600, 10000, 10100 |  |  |
| `groundEffectDensity` | 16, 256 | 8, 264 | Value must be between 16 and 256. |
| `groundEffectDist` | 40, 500 | 30, 510 | Value must be between 40 and 500. |
| `lodObjectFadeScale` | 50, 5000 | 40, 5010 | lodObjectFadescale must be in range 50 to 5000. |
| `lodObjectCullSize` | 1, 100 | 0, 101 | lodObjectCullSize must be in range 1 to 100. |
| `terrainLodDist` | 175, 200, 650, 675 |  |  |
| `wmoLodDist` | 240, 250, 400, 410 |  |  |
| `doodadLodScale` | 45, 50, 150, 155 |  |  |
| `entityLodDist` | 4, 5, 10, 11 |  |  |
| `terrainMipLevel` | 0, 1 |  |  |
| `componentTextureLevel` | 0, 1, 2 |  |  |
| `particleDensity` | 0, 100 | 105 | Value must be between 0 and 100. |
| `spellVisualDensityFilterSetting` | 1, 2, 3, 4 |  |  |
| `weatherDensity` | 0, 1, 2, 3 |  |  |
| `showfootprintparticles` | 0, 1 |  |  |
| `ffxGlow` | 0, 1 |  |  |
| `ffxDeath` | 0, 1 |  |  |
| `ffxNether` | 0, 1 |  |  |
| `sunShafts` | 0, 1, 2 |  |  |
| `volumeFog` | 0, 1 |  |  |
| `volumeFogLevel` | 0, 4 | 5 | Volume values from 0 (lowest) to 4 (highest) |
| `bloomEnable` | 0, 1 |  |  |
| `specular` | 0, 1 | 1.05 | Specular multiplier must be between 0.0 and 1.0 |
| `reflectionMode` | 0, 1, 2, 3 |  |  |
| `refraction` | 0, 2 | 3 | Failed to set refraction mode. |
| `rippleDetail` | 0, 2 | 3 | Unsupported ripple detail mode. |
| `DepthBasedOpacity` | 0, 1 |  |  |
| `shadowMode` | 0, 1, 2, 3, 4 |  |  |
| `shadowTextureSize` | 512, 768, 1024, 1536, 2048, 4096 |  |  |
| `shadowNumCascades` | 0, 1, 4, 5 |  |  |
| `entityShadowFadeScale` | 5, 10, 50, 55 |  |  |
| `shadowSoft` | 0, 1 |  |  |
| `shadowBlendCascades` | 0, 1 |  |  |
| `ResampleAlwaysSharpen` | 0, 1 |  |  |
| `CMAA2Quality` | 0, 1, 2, 3 |  |  |
| `CMAA2ExtraSharpness` | 0, 1 |  |  |
| `maxFPSLoading` | 10, 100 | 5, 105 | MaxFPSLoading must be between 10 and 100 |
| `screenshotQuality` | 1, 10 | 0, 11 | The engine said nothing. |
| `screenshotFormat` | jpeg, png, tga |  |  |
| `cameraDistanceMaxZoomFactor` | 1, 2, 4 | 0.9, 4.1 | Value out of range (1.000000 - 4.000000) Seen: zoomed all the way out, the camera stopped 30 yards from the character at 2, where the game's own slider stops, and 50 yards at 4. |
| `cameraZoomSpeed` | 1, 50 | 0, 51 | Value out of range (0.002778 - 50.000000) |
| `cameraDistanceRateMult` | 0.1, 10, 10.1 | 0 | Value out of range (0.002778 - 50.000000) |
| `cameraYawMoveSpeed` | 1, 360 | 0, 361 | Value out of range (0.100000 - 360.000000) |
| `cameraPitchMoveSpeed` | 1, 360 | 0, 361 | Value out of range (0.100000 - 360.000000) |
| `cameraYawSmoothSpeed` | 1, 360 | 0, 361 | Value out of range (0.100000 - 360.000000) |
| `cameraPitchSmoothSpeed` | 1, 360 | 0, 361 | Value out of range (0.100000 - 360.000000) |
| `cameraZSmooth` | 1, 2 |  |  |
| `CameraKeepCharacterCentered` | 0, 1 |  |  |
| `mouseAcceleration` | -1, 0, 1 |  |  |
| `threatWarning` | 0, 1, 2, 3 |  |  |
| `FootstepSounds` | 0, 1 |  |  |
| `Sound_EnableArmorFoleySoundForSelf` | 0, 1 |  |  |
| `Sound_EnableArmorFoleySoundForOthers` | 0, 1 |  |  |
| `Sound_ListenerAtCharacter` | 0, 1 |  |  |
| `Sound_EnableDSPEffects` | 0, 1 |  |  |
| `HDROutput` | 0, 1 |  | Seen: on shows at once. Turned off after a graphics restart with it on, the picture was garbled, in false colors, until the next graphics restart. Turned off with the graphics started with it off, it showed at once. |
| `HDRFactor` | 0, 2.000000, 4, 100 |  | Seen, with HDR on: each change showed at once. A reload and a graphics restart changed nothing more. Kept, so the engine holds it to no range. HDR was off. |
| `useHDRBrightness` | 0, 1 |  | Seen, with HDR on: each change showed at once. |
| `HDRBrightness` | 0, 203, 600, 10000 |  | Seen, with HDR on and useHDRBrightness at 1: each change showed at once. A graphics restart changed nothing more. Kept, so the engine holds it to no range. HDR was off. |
| `useHDRPeakBrightness` | 0, 1 |  | Seen, with HDR on: at night each change showed at once. By day no change was seen. |
| `HDRPeakBrightness` | 0, 400, 1000, 10000 |  | Seen, with HDR on and useHDRPeakBrightness at 1: no change, at once or after a graphics restart, by day or at night. Kept, so the engine holds it to no range. HDR was off. |
| `nameplateMaxDistance` | 0, 1000 |  | Kept, so the engine holds it to no range. |
| `SpellQueueWindow` | 0, 400 | 401, 10000 | The engine said nothing. |
| `WorldTextScale_v2` | 0, 100 |  | Kept, so the engine holds it to no range. |
| `groundEffectFade` | 0, 10000 |  | Kept, so the engine holds it to no range. |
| `giQuality` | 0, 10 |  | Kept, so the engine holds it to no range. |
| `volumeFogInterior` | 0, 1 | 2 | Use values from 0 (lowest) to 1 (highest) |
| `cameraIndirectVisibility` | 0, 10 |  | Kept, so the engine holds it to no range. |
| `cameraIndirectOffset` | 0, 100 |  | Kept, so the engine holds it to no range. |
| `violenceLevel` | 0, 10 |  | Kept, so the engine holds it to no range. |
| `autoLootRate` | 0, 10000 |  | Kept, so the engine holds it to no range. |
| `classicStyleWorldText` | 0, 1, 2 |  | Kept: the engine holds it to no range. Its help text says it's one way or the other. |
| `outlineModeShowLootEffectWhenDisabled` | 0, 1 |  | Seen in front of two quest objects in Westfall (Sacks of Oats), set through the Loot sparkles checkbox, with graphicsOutlineMode and raidGraphicsOutlineMode at 0 while it was on and 1 otherwise: neither sack had an outline at 1. On, both sparkled at once. Off, both still sparkled, after a /reload and after a graphics restart too. After logging out and in again, with no game restart, the sack still there didn't. |
| `graphicsOutlineMode` | 1, 2 |  | raidGraphicsOutlineMode stayed at 1 both times: the one doesn't set the other. |
| `test_cameraOverShoulder` | -10, 10 |  | Kept, so the engine holds it to no range: Test CVar test_cameraOverShoulder has been set to 10 (default 0.000000) |

Console commands that aren't CVars, each run with a value or none. A command has nothing to
read it back by, so what it did is what the console printed, and what was seen or read elsewhere.

| Command | Value | Printed | Seen |
| --- | --- | --- | --- |
| `pitchLimit` | none |  | Nothing to see. The game can't be asked for its value. |
| `pitchLimit` | `45` |  | The camera tilted down only about half way: cameraSavedPitch read 42.4, then 45 at the stop, after a /reload too. |
| `pitchLimit` | `88` |  | The camera looked almost straight down on the character, after a /reload too. |
| `pitchLimit` | `1000` |  | The camera looked straight down. -1000 printed nothing either. |
| `physEnable` | none | Disabling physics processing. |  |
| `physEnable` | `0` | Disabling physics processing. |  |
| `physEnable` | `1` | Enabling physics processing. | The same again for a second 1: it's set, not switched. |
| `physCulling` | none |  |  |
| `physCullingDist` | none |  |  |
| `physEnableVegOverrides` | none |  |  |
| `physEnableVegOverrides` | `1` |  | No CVar changed, and the six physVeg commands stayed commands. |
| `physEnableVegOverrides` | `0` |  |  |
| `physVegMinPushDist` | none |  |  |
| `physVegPosMaxPush` | none |  |  |
| `physVegPosPushAmt` | none |  |  |
| `physVegPosRelaxSpeed` | none |  |  |
| `physVegVelMaxPush` | none |  |  |
| `physVegVelSpeed` | none |  |  |
| `ActionCam` | none | Syntax: ActionCam [option] | And its 13 options: heavyHeadMove, noHeadMove, lowHeadMove, headMove, focusAll, focusEnemy, focusInteract, focusOff, full, basic, off, on, default. |
| `ActionCam` | `off` | ACTION Camera set to 'off' - 'Disable action cam features' | test_cameraDynamicPitch, test_cameraOverShoulder and test_cameraHeadMovementStrength set to 0, with a line for each. |
| `SetGraphicsQuality` | none | Graphics Quality set to 0 | The lowest quality: the 15 graphics quality settings to 0, and 36 CVars with them, a line for each. graphicsQuality stayed at 9. |
| `SetGraphicsQuality` | `9` | Graphics Quality set to 9 | Each of them back as it was at 9, but outline mode: 2, where it had been 1. |
| `SetGraphicsQualityRAID` | `5` | Raid Graphics Quality set to 5 | The 15 raid graphics quality settings and 21 RAID CVars, to level 5's values. RAIDgraphicsQuality stayed at 5. |
| `fontcolor` | none | Invalid number of parameters |  |
| `fontcolor` | `echo 200 100 50` |  | ConsoleGetColorFromType read 200, 100, 50 for the echo color, after a /reload too. |
| `fontcolor` | `echo 300 0 0` | One or more colors are not in the 0 to 255 range or missing. |  |
| `fontcolor` | `purple 1 2 3` | Unknown color class. Choose 'input','echo','warning','admin',or 'global' as the first parameter |  |
| `fontsize` | none |  | ConsoleGetFontHeight read 10. |
| `fontsize` | `20` |  |  |
| `fontsize` | `60` |  | ConsoleGetFontHeight read 50, after a /reload too: the console's own addon saves the size. |

### WoW Forever 1.60.1 (build 70938), Windows, Direct3D 11

`/every check` in one go, from Every Setting at `0576910`, on an NVIDIA GeForce RTX 5080 at 1920 by 1080, with the character in the world, in an inn in Stormwind. It checked 74 tuned settings and the engine kept both ends of every one. The game's warning about experimental camera features came up, as the six `test_camera` settings were set, and Accept closed it. Nothing else was seen: no other popup, no hitch, no disconnect. The four menus a Mac can't try, a `/every probe` line each: `LowLatencyMode` keeps 0 to 4 and not 5, Intel XeLL, which the game's own menu greys out on this card; `shadowRt` keeps only 0 ("Unsupported shadow RT mode."), and the game's own Graphics options have no Ray Traced Shadows on this client; `ffxAntiAliasingMode` keeps 0 to 4 and `ResampleQuality` 0 to 3, the options the game's own menus list, and Every Setting's menus list the same. The CVar list (`data/ranges/70938/windows-d3d11/cvars.lua` in the repository) has 1,801 CVars, to the Mac's 1,797. 14 are only on Windows: `rawMouseEnable`, `AllowWinRT`, `AllowSoftwareRendererDX12`, `ChromaEffectsEnable`, `ChromaEffectsFactionColor`, `luaErrorExceptions`, `winePlatformTTS` and seven `vrsValar` ones. 10 are only on the Mac: the six `Mac` and `AllowMac` ones, `GxDebugLevel`, `GxDebugBreakLevel`, `PlayerInfoTempCache` and `PlayerInfoTempCacheDebug`. Of the 1,787 in both, 20 have another default: the 14 quality settings the game picks for the hardware (`graphicsQuality` 6, not 5, and the rest), `RenderScale` 1, not 0.5, `CMAA2HalfFloat` 0, not 1, `mouseSpeed` 0.03, not 0.25, `Sound_EnableSoundWhenGameIsInBG` 0, not 1, `VoicePushToTalkKeybind`, and `PraiseTheSun`, which has none here. `VoicePushToTalkKeybind`, whose default is `` ` `` (`LMETA` on the Mac), is also stored per account. Against Direct3D 12: the same names and the same check, and `vrsParticles` and `vrsWorldGeo` have no default here, as on the Mac.

78 CVars, 74 of them tuned settings.

| CVar | Kept | Not kept | Notes |
| --- | --- | --- | --- |
| `farclip` | 900, 1000, 10000, 10100 |  |  |
| `horizonStart` | 300, 400, 4000, 4100 |  |  |
| `horizonClip` | 1500, 1600, 10000, 10100 |  |  |
| `groundEffectDensity` | 16, 256 | 8, 264 |  |
| `groundEffectDist` | 40, 500 | 30, 510 |  |
| `lodObjectFadeScale` | 50, 5000 | 40, 5010 |  |
| `lodObjectCullSize` | 1, 100 | 0, 101 |  |
| `terrainLodDist` | 175, 200, 650, 675 |  |  |
| `wmoLodDist` | 240, 250, 400, 410 |  |  |
| `doodadLodScale` | 45, 50, 150, 155 |  |  |
| `entityLodDist` | 4, 5, 10, 11 |  |  |
| `terrainMipLevel` | 0, 1 |  |  |
| `componentTextureLevel` | 0, 1, 2 |  |  |
| `outlineModeShowLootEffectWhenDisabled` | 0, 1 |  |  |
| `particleDensity` | 0, 100 | -5, 105 |  |
| `spellVisualDensityFilterSetting` | 1, 2, 3, 4 |  |  |
| `weatherDensity` | 0, 1, 2, 3 |  |  |
| `showfootprintparticles` | 0, 1 |  |  |
| `ffxGlow` | 0, 1 |  |  |
| `ffxDeath` | 0, 1 |  |  |
| `ffxNether` | 0, 1 |  |  |
| `sunShafts` | 0, 1, 2 |  |  |
| `giQuality` | 0, 1, 4, 5 |  |  |
| `volumeFog` | 0, 1 |  |  |
| `volumeFogLevel` | 0, 4 | -1, 5 |  |
| `volumeFogInterior` | 0, 1 |  |  |
| `bloomEnable` | 0, 1 |  |  |
| `specular` | 0, 1 | -0.05, 1.05 |  |
| `reflectionMode` | 0, 1, 2, 3 |  |  |
| `refraction` | 0, 2 | -1, 3 |  |
| `rippleDetail` | -1, 0, 2 | 3 |  |
| `DepthBasedOpacity` | 0, 1 |  |  |
| `shadowMode` | 0, 1, 2, 3, 4 |  |  |
| `shadowTextureSize` | 512, 768, 1024, 1536, 2048, 4096 |  |  |
| `shadowNumCascades` | 0, 1, 4, 5 |  |  |
| `entityShadowFadeScale` | 5, 10, 50, 55 |  |  |
| `shadowSoft` | 0, 1 |  |  |
| `shadowBlendCascades` | 0, 1 |  |  |
| `ResampleAlwaysSharpen` | 0, 1 |  |  |
| `CMAA2Quality` | 0, 1, 2, 3 |  |  |
| `CMAA2ExtraSharpness` | 0, 1 |  |  |
| `DynamicRenderScale` | 0, 1 |  |  |
| `HDROutput` | 0, 1 |  |  |
| `useHDRBrightness` | 0, 1 |  |  |
| `useHDRPeakBrightness` | 0, 1 |  |  |
| `maxFPSLoading` | 10, 100 | 5, 105 |  |
| `screenshotQuality` | 1, 10 | 0, 11 |  |
| `screenshotFormat` | jpeg, png, tga |  |  |
| `cameraDistanceMaxZoomFactor` | 1, 4 | 0.9, 4.1 |  |
| `cameraZoomSpeed` | 1, 50 | 0, 51 |  |
| `cameraDistanceRateMult` | 0.1, 10, 10.1 | 0 |  |
| `cameraYawMoveSpeed` | 1, 360 | 0, 361 |  |
| `cameraPitchMoveSpeed` | 1, 360 | 0, 361 |  |
| `cameraYawSmoothSpeed` | 1, 360 | 0, 361 |  |
| `cameraPitchSmoothSpeed` | 1, 360 | 0, 361 |  |
| `cameraZSmooth` | 1, 2 |  |  |
| `test_cameraOverShoulder` | 0, 1 |  |  |
| `CameraKeepCharacterCentered` | 0, 1 |  |  |
| `CameraReduceUnexpectedMovement` | 0, 1 |  |  |
| `test_cameraDynamicPitch` | 0, 1 |  |  |
| `test_cameraDynamicPitchBaseFovPad` | 0, 1 | -0.05, 1.05 |  |
| `test_cameraDynamicPitchBaseFovPadFlying` | 0, 1 | -0.05, 1.05 |  |
| `test_cameraTargetFocusEnemyEnable` | 0, 1 |  |  |
| `test_cameraTargetFocusInteractEnable` | 0, 1 |  |  |
| `mouseAcceleration` | -1, 0, 1 |  |  |
| `nameplateMotionSpeed` | -0.005, 0, 1, 1.005 |  |  |
| `threatWarning` | 0, 1, 2, 3 |  |  |
| `FootstepSounds` | 0, 1 |  |  |
| `Sound_EnableArmorFoleySoundForSelf` | 0, 1 |  |  |
| `Sound_EnableArmorFoleySoundForOthers` | 0, 1 |  |  |
| `Sound_ListenerAtCharacter` | 0, 1 |  |  |
| `Sound_EnableDSPEffects` | 0, 1 |  |  |
| `classicStyleWorldText` | 0, 1 |  |  |
| `SpellQueueWindow` | 0, 400 | -1, 401 |  |
| `LowLatencyMode` | 0, 1, 2, 3, 4 | 5 | The engine said nothing. The game's own menu greys Intel XeLL out on this card: "Requires an Intel graphics card." |
| `shadowRt` | 0 | 1, 2, 3 | Unsupported shadow RT mode. The game's own Graphics options have no Ray Traced Shadows on this client, and gx.log gives the card as rt:None. Unsupported shadow RT mode. The game's own Graphics options have no Ray Traced Shadows on this client, and gx.log gives the card as rt:None. |
| `ffxAntiAliasingMode` | 0, 1, 2, 3, 4 |  |  |
| `ResampleQuality` | 0, 1, 2, 3 |  |  |

### WoW Forever 1.60.1 (build 70938), Windows, Direct3D 12

`/every check` in one go, from Every Setting at `0576910`, on an NVIDIA GeForce RTX 5080 at 1920 by 1080, with the character in the world, in an inn in Stormwind. It checked 74 tuned settings and the engine kept both ends of every one. The game's warning about experimental camera features came up, as the six `test_camera` settings were set, and Accept closed it. Nothing else was seen: no other popup, no hitch, no disconnect. The four menus a Mac can't try, a `/every probe` line each: `LowLatencyMode` keeps 0 to 4 and not 5, Intel XeLL, which the game's own menu greys out on this card; `shadowRt` keeps only 0 ("Unsupported shadow RT mode."), and the game's own Graphics options have no Ray Traced Shadows on this client; `ffxAntiAliasingMode` keeps 0 to 4 and `ResampleQuality` 0 to 3, the options the game's own menus list, and Every Setting's menus list the same. The CVar list (`data/ranges/70938/windows-d3d12/cvars.lua` in the repository) has 1,801 CVars, to the Mac's 1,797. 14 are only on Windows: `rawMouseEnable`, `AllowWinRT`, `AllowSoftwareRendererDX12`, `ChromaEffectsEnable`, `ChromaEffectsFactionColor`, `luaErrorExceptions`, `winePlatformTTS` and seven `vrsValar` ones. 10 are only on the Mac: the six `Mac` and `AllowMac` ones, `GxDebugLevel`, `GxDebugBreakLevel`, `PlayerInfoTempCache` and `PlayerInfoTempCacheDebug`. Of the 1,787 in both, 21 have another default: the 14 quality settings the game picks for the hardware (`graphicsQuality` 6, not 5, and the rest), `RenderScale` 1, not 0.5, `CMAA2HalfFloat` 0, not 1, `mouseSpeed` 0.03, not 0.25, `Sound_EnableSoundWhenGameIsInBG` 0, not 1, `VoicePushToTalkKeybind`, and `vrsParticles` and `vrsWorldGeo` 1x1, where the Mac has none. `VoicePushToTalkKeybind`, whose default is `` ` `` (`LMETA` on the Mac), is also stored per account. The 14 CVars only Windows has were each set to 0 and 1, then to 2 and -1, and the two VRS numbers also to -1, 100 and a million, a CVar at a time, each put back: the engine kept every value. So the 12 that are on or off get a checkbox on their names and help texts, and the two numbers just the box. The game's own check of a menu's values (`IsGraphicsCVarValueSupported`, which its Graphics options grey out by) says this computer can't use `shadowRt` 1 to 3 ("Unsupported for graphics related reasons") or `LowLatencyMode` 5 ("Requires an Intel graphics card"), and nothing else Every Setting offers; Every Setting greys the same ones out, and `RAIDshadowRt` 1 and 2 by the check of `shadowRt`.

93 CVars, 74 of them tuned settings.

| CVar | Kept | Not kept | Notes |
| --- | --- | --- | --- |
| `farclip` | 900, 1000, 10000, 10100 |  |  |
| `horizonStart` | 300, 400, 4000, 4100 |  |  |
| `horizonClip` | 1500, 1600, 10000, 10100 |  |  |
| `groundEffectDensity` | 16, 256 | 8, 264 |  |
| `groundEffectDist` | 40, 500 | 30, 510 |  |
| `lodObjectFadeScale` | 50, 5000 | 40, 5010 |  |
| `lodObjectCullSize` | 1, 100 | 0, 101 |  |
| `terrainLodDist` | 175, 200, 650, 675 |  |  |
| `wmoLodDist` | 240, 250, 400, 410 |  |  |
| `doodadLodScale` | 45, 50, 150, 155 |  |  |
| `entityLodDist` | 4, 5, 10, 11 |  |  |
| `terrainMipLevel` | 0, 1 |  |  |
| `componentTextureLevel` | 0, 1, 2 |  |  |
| `outlineModeShowLootEffectWhenDisabled` | 0, 1 |  |  |
| `particleDensity` | 0, 100 | -5, 105 |  |
| `spellVisualDensityFilterSetting` | 1, 2, 3, 4 |  |  |
| `weatherDensity` | 0, 1, 2, 3 |  |  |
| `showfootprintparticles` | 0, 1 |  |  |
| `ffxGlow` | 0, 1 |  |  |
| `ffxDeath` | 0, 1 |  |  |
| `ffxNether` | 0, 1 |  |  |
| `sunShafts` | 0, 1, 2 |  |  |
| `giQuality` | 0, 1, 4, 5 |  |  |
| `volumeFog` | 0, 1 |  |  |
| `volumeFogLevel` | 0, 4 | -1, 5 |  |
| `volumeFogInterior` | 0, 1 |  |  |
| `bloomEnable` | 0, 1 |  |  |
| `specular` | 0, 1 | -0.05, 1.05 |  |
| `reflectionMode` | 0, 1, 2, 3 |  |  |
| `refraction` | 0, 2 | -1, 3 |  |
| `rippleDetail` | -1, 0, 2 | 3 |  |
| `DepthBasedOpacity` | 0, 1 |  |  |
| `shadowMode` | 0, 1, 2, 3, 4 |  |  |
| `shadowTextureSize` | 512, 768, 1024, 1536, 2048, 4096 |  |  |
| `shadowNumCascades` | 0, 1, 4, 5 |  |  |
| `entityShadowFadeScale` | 5, 10, 50, 55 |  |  |
| `shadowSoft` | 0, 1 |  |  |
| `shadowBlendCascades` | 0, 1 |  |  |
| `ResampleAlwaysSharpen` | 0, 1 |  |  |
| `CMAA2Quality` | 0, 1, 2, 3 |  |  |
| `CMAA2ExtraSharpness` | 0, 1 |  |  |
| `DynamicRenderScale` | 0, 1 |  |  |
| `HDROutput` | 0, 1 |  |  |
| `useHDRBrightness` | 0, 1 |  |  |
| `useHDRPeakBrightness` | 0, 1 |  |  |
| `maxFPSLoading` | 10, 100 | 5, 105 |  |
| `screenshotQuality` | 1, 10 | 0, 11 |  |
| `screenshotFormat` | jpeg, png, tga |  |  |
| `cameraDistanceMaxZoomFactor` | 1, 4 | 0.9, 4.1 |  |
| `cameraZoomSpeed` | 1, 50 | 0, 51 |  |
| `cameraDistanceRateMult` | 0.1, 10, 10.1 | 0 |  |
| `cameraYawMoveSpeed` | 1, 360 | 0, 361 |  |
| `cameraPitchMoveSpeed` | 1, 360 | 0, 361 |  |
| `cameraYawSmoothSpeed` | 1, 360 | 0, 361 |  |
| `cameraPitchSmoothSpeed` | 1, 360 | 0, 361 |  |
| `cameraZSmooth` | 1, 2 |  |  |
| `test_cameraOverShoulder` | 0, 1 |  |  |
| `CameraKeepCharacterCentered` | 0, 1 |  |  |
| `CameraReduceUnexpectedMovement` | 0, 1 |  |  |
| `test_cameraDynamicPitch` | 0, 1 |  |  |
| `test_cameraDynamicPitchBaseFovPad` | 0, 1 | -0.05, 1.05 |  |
| `test_cameraDynamicPitchBaseFovPadFlying` | 0, 1 | -0.05, 1.05 |  |
| `test_cameraTargetFocusEnemyEnable` | 0, 1 |  |  |
| `test_cameraTargetFocusInteractEnable` | 0, 1 |  |  |
| `mouseAcceleration` | -1, 0, 1 |  |  |
| `nameplateMotionSpeed` | -0.005, 0, 1, 1.005 |  |  |
| `threatWarning` | 0, 1, 2, 3 |  |  |
| `FootstepSounds` | 0, 1 |  |  |
| `Sound_EnableArmorFoleySoundForSelf` | 0, 1 |  |  |
| `Sound_EnableArmorFoleySoundForOthers` | 0, 1 |  |  |
| `Sound_ListenerAtCharacter` | 0, 1 |  |  |
| `Sound_EnableDSPEffects` | 0, 1 |  |  |
| `classicStyleWorldText` | 0, 1 |  |  |
| `SpellQueueWindow` | 0, 400 | -1, 401 |  |
| `LowLatencyMode` | 0, 1, 2, 3, 4 | 5 | The engine said nothing. The game's own menu greys Intel XeLL out on this card: "Requires an Intel graphics card." |
| `shadowRt` | 0 | 1, 2, 3 | Unsupported shadow RT mode. The game's own Graphics options have no Ray Traced Shadows on this client, and gx.log gives the card as rt:None. Unsupported shadow RT mode. The game's own Graphics options have no Ray Traced Shadows on this client, and gx.log gives the card as rt:None. |
| `ffxAntiAliasingMode` | 0, 1, 2, 3, 4 |  |  |
| `ResampleQuality` | 0, 1, 2, 3 |  |  |
| `AllowSoftwareRendererDX12` | -1, 0, 1, 2 |  |  |
| `AllowWinRT` | -1, 0, 1, 2 |  |  |
| `ChromaEffectsEnable` | -1, 0, 1, 2 |  |  |
| `ChromaEffectsFactionColor` | -1, 0, 1, 2 |  |  |
| `luaErrorExceptions` | -1, 0, 1, 2 |  |  |
| `rawMouseEnable` | -1, 0, 1, 2 |  |  |
| `vrsValarAlwaysOn` | -1, 0, 1, 2 |  |  |
| `vrsValarLPUseCornerSampling` | -1, 0, 1, 2 |  |  |
| `vrsValarUseAsyncCompute` | -1, 0, 1, 2 |  |  |
| `vrsValarUseMotionVectors` | -1, 0, 1, 2 |  |  |
| `vrsValarUseWeberFechner` | -1, 0, 1, 2 |  |  |
| `winePlatformTTS` | -1, 0, 1, 2 |  |  |
| `vrsValarEnvLuma` | -1, 0, 0.5, 1, 100, 1000000 |  |  |
| `vrsValarWeberFechnerConstant` | -1, 0, 0.5, 1, 100, 1000000 |  |  |
| `RAIDshadowRt` | 0 | 1, 2, 3 | The engine said nothing, and kept 0, as it does of shadowRt here. Every Setting greys 1 and 2 out by the game's check of shadowRt. |

### WoW retail 12.1.5 (build 70783), Windows, Direct3D 11

As on Direct3D 12, after `gxApi` was set to D3D11 and the client started again (gx.log: `Dx11 Device Create Successful`), on the same computer, character and inn, from Every Setting at `c2891c5`. `/every check` kept both ends of all 67 tuned settings, the same values as on Direct3D 12, and the camera warning came up again; nothing else was seen. The four menus a Mac can't try kept what they kept on Direct3D 12: `LowLatencyMode` 0 to 3, `shadowRt` only 0, `ffxAntiAliasingMode` 0 to 4 and `ResampleQuality` 0 to 3. gx.log gives the card as `sm:dx_5_0, rt:None, vrs:0`. The CVar list (`data/ranges/70783/retail-windows-d3d11/cvars.lua` in the repository) has the same 1,679 CVars as on Direct3D 12. 11 have another default: `vrsParticles` and `vrsWorldGeo` have none, as on the Mac, and eight `CACHE-` counters and `PraiseTheSun` had none in this dump either. The game's own check of a menu's values says this computer can't use `LowLatencyMode` 4 ("Requires an Intel graphics card"), `shadowRt` 1 to 3 ("Disabled due to compatibility settings") or `vrsValar` 1 and 2 ("Requires DirectX 12"), as the game's own Graphics options say, and Every Setting greys the same ones out, with the same words. Retail's own settings were read in game as well, every dropdown's values from its settings panel: 103 dropdowns. Each of the 31 for a CVar that Every Setting gives a menu in retail lists the same values as Every Setting's menu, the three with a line of retail's own (`LowLatencyMode`, `nameplateStyle` and `Outline`) among them. The others are proxies for settings that aren't one CVar, or list what this computer has: voices, sound devices, languages.

71 CVars, 67 of them tuned settings.

| CVar | Kept | Not kept | Notes |
| --- | --- | --- | --- |
| `farclip` | 900, 1000, 10000, 10100 |  |  |
| `horizonStart` | 300, 400, 4000, 4100 |  |  |
| `horizonClip` | 1500, 1600, 10000, 10100 |  |  |
| `groundEffectDensity` | 16, 256 | 8, 264 |  |
| `groundEffectDist` | 40, 500 | 30, 510 |  |
| `lodObjectFadeScale` | 50, 5000 | 40, 5010 |  |
| `lodObjectCullSize` | 1, 100 | 0, 101 |  |
| `terrainLodDist` | 175, 200, 650, 675 |  |  |
| `wmoLodDist` | 240, 250, 400, 410 |  |  |
| `doodadLodScale` | 45, 50, 150, 155 |  |  |
| `entityLodDist` | 4, 5, 10, 11 |  |  |
| `terrainMipLevel` | 0, 1 |  |  |
| `componentTextureLevel` | 0, 1, 2 |  |  |
| `particleDensity` | 0, 100 | -5, 105 |  |
| `spellVisualDensityFilterSetting` | 1, 2, 3, 4 |  |  |
| `weatherDensity` | 0, 1, 2, 3 |  |  |
| `showfootprintparticles` | 0, 1 |  |  |
| `ffxGlow` | 0, 1 |  |  |
| `ffxDeath` | 0, 1 |  |  |
| `ffxNether` | 0, 1 |  |  |
| `sunShafts` | 0, 1, 2 |  |  |
| `volumeFog` | 0, 1 |  |  |
| `volumeFogLevel` | 0, 4 | -1, 5 |  |
| `volumeFogInterior` | 0, 1 |  |  |
| `specular` | 0, 1 | -0.05, 1.05 |  |
| `reflectionMode` | 0, 1, 2, 3 |  |  |
| `refraction` | 0, 2 | -1, 3 |  |
| `rippleDetail` | -1, 0, 2 | 3 |  |
| `DepthBasedOpacity` | 0, 1 |  |  |
| `shadowMode` | 0, 1, 2, 3, 4 |  |  |
| `shadowTextureSize` | 512, 1024, 2048 |  |  |
| `shadowNumCascades` | 0, 1, 4, 5 |  |  |
| `entityShadowFadeScale` | 5, 10, 50, 55 |  |  |
| `shadowSoft` | 0, 1 |  |  |
| `shadowBlendCascades` | 0, 1 |  |  |
| `ResampleAlwaysSharpen` | 0, 1 |  |  |
| `CMAA2Quality` | 0, 1, 2, 3 |  |  |
| `CMAA2ExtraSharpness` | 0, 1 |  |  |
| `DynamicRenderScale` | 0, 1 |  |  |
| `maxFPSLoading` | 10, 100 | 5, 105 |  |
| `screenshotQuality` | 1, 10 | 0, 11 |  |
| `screenshotFormat` | jpeg, png, tga |  |  |
| `cameraDistanceMaxZoomFactor` | 1, 2.6 | 0.9, 2.7 |  |
| `cameraZoomSpeed` | 1, 50 | 0, 51 |  |
| `cameraDistanceRateMult` | 0.1, 10, 10.1 | 0 |  |
| `cameraYawMoveSpeed` | 1, 360 | 0, 361 |  |
| `cameraPitchMoveSpeed` | 1, 360 | 0, 361 |  |
| `cameraYawSmoothSpeed` | 1, 360 | 0, 361 |  |
| `cameraPitchSmoothSpeed` | 1, 360 | 0, 361 |  |
| `cameraZSmooth` | 1, 2 |  |  |
| `test_cameraOverShoulder` | 0, 1 |  |  |
| `CameraKeepCharacterCentered` | 0, 1 |  |  |
| `CameraReduceUnexpectedMovement` | 0, 1 |  |  |
| `test_cameraDynamicPitch` | 0, 1 |  |  |
| `test_cameraDynamicPitchBaseFovPad` | 0, 1 | -0.05, 1.05 |  |
| `test_cameraDynamicPitchBaseFovPadFlying` | 0, 1 | -0.05, 1.05 |  |
| `test_cameraTargetFocusEnemyEnable` | 0, 1 |  |  |
| `test_cameraTargetFocusInteractEnable` | 0, 1 |  |  |
| `mouseAcceleration` | -1, 0, 1 |  |  |
| `nameplateMotionSpeed` | -0.005, 0, 1, 1.005 |  |  |
| `threatWarning` | 0, 1, 2, 3 |  |  |
| `FootstepSounds` | 0, 1 |  |  |
| `Sound_EnableArmorFoleySoundForSelf` | 0, 1 |  |  |
| `Sound_EnableArmorFoleySoundForOthers` | 0, 1 |  |  |
| `Sound_ListenerAtCharacter` | 0, 1 |  |  |
| `Sound_EnableDSPEffects` | 0, 1 |  |  |
| `SpellQueueWindow` | 0, 400 | -1, 401 |  |
| `LowLatencyMode` | 0, 1, 2, 3 | 4 | The engine said nothing. The game's own menu says of Intel XeLL on this card: "Requires an Intel graphics card." |
| `shadowRt` | 0 | 1, 2, 3 | Unsupported shadow RT mode. The game's own Graphics options say Fair, Good and High are "Disabled due to compatibility settings", and gx.log gives the card as rt:None. Unsupported shadow RT mode. The game's own Graphics options say Fair, Good and High are "Disabled due to compatibility settings", and gx.log gives the card as rt:None. |
| `ffxAntiAliasingMode` | 0, 1, 2, 3, 4 |  |  |
| `ResampleQuality` | 0, 1, 2, 3 |  |  |

### WoW retail 12.1.5 (build 70783), Windows, Direct3D 12

`/every check` in one go, from Every Setting at `c2891c5`, on an NVIDIA GeForce RTX 5080 at 1920 by 1080, with Windows' display scaling at 125%, with the character in the world, in an inn in Valdrakken. It checked the 67 tuned settings retail has, in retail's ranges, and the engine kept both ends of every one. The game's warning about experimental camera features came up, as the six `test_camera` settings were set, and Accept closed it. Nothing else was seen: no other popup, no hitch, no disconnect. The four menus a Mac can't try, each set and read back a value at a time, as `/every probe` does: `LowLatencyMode` keeps 0 to 3 and not 4, Intel XeLL, which the game's own menu says needs an Intel graphics card. Retail's menu has no Auto detect, so each of its values is one lower than Forever's (0 is Disabled, 4 is Intel XeLL), and Every Setting gives retail that menu. `shadowRt` keeps only 0 ("Unsupported shadow RT mode."): unlike Forever's, retail's own Graphics options list Ray Traced Shadows, and say Fair, Good and High are "Disabled due to compatibility settings". gx.log gives the card as `sm:dx_5_0, rt:None`. `ffxAntiAliasingMode` keeps 0 to 4 and `ResampleQuality` 0 to 3, the options the game's own menus list, and Every Setting's menus list the same. The CVar list (`data/ranges/70783/retail-windows-d3d12/cvars.lua` in the repository) has 1,679 CVars on this character, to the Mac's 1,683 on another. 14 are only on Windows, the same 14 as in Forever. 18 are only in the Mac's list: the six `Mac` and `AllowMac` ones, `GxDebugLevel` and `GxDebugBreakLevel`, Details' `LibOpenRaidTempCache` and `LibOpenRaidTempCacheDebug`, `PlayerInfoTempCache` and `PlayerInfoTempCacheDebug`, `activeCUFProfile`, `auctionDisplayOnCharacter`, `nameplateShowFriends`, `playerStatLeftDropdown`, `playerStatRightDropdown` and `unlockedExpansionLandingPages`. Of the 1,665 in both, 20 have another default: the 12 quality settings the game picks for the hardware (`graphicsQuality` 6, not 5, and the rest), `RenderScale` 1, not 0.5, `ffxAntiAliasingMode` 0, not 4, `CMAA2HalfFloat` 0, not 1, `mouseSpeed` 0.03, not 0.25, `Sound_EnableSoundWhenGameIsInBG` 0, not 1, `VoicePushToTalkKeybind`, and `vrsParticles` and `vrsWorldGeo` 1x1, where the Mac has none. `VoicePushToTalkKeybind`, whose default is `` ` `` (`LMETA` on the Mac), is also stored per account. The game's own check of a menu's values (`IsGraphicsCVarValueSupported`, which its Graphics options grey out by) says this computer can't use `LowLatencyMode` 4 ("Requires an Intel graphics card"), `shadowRt` 1 to 3 ("Disabled due to compatibility settings") or `vrsValar` 1 and 2 ("Requires a shader model 6 capable graphics card"), and nothing else Every Setting offers; Every Setting greys the same ones out, with the game's words, and `RAIDshadowRt` 1 and 2 by the check of `shadowRt`.

71 CVars, 67 of them tuned settings.

| CVar | Kept | Not kept | Notes |
| --- | --- | --- | --- |
| `farclip` | 900, 1000, 10000, 10100 |  |  |
| `horizonStart` | 300, 400, 4000, 4100 |  |  |
| `horizonClip` | 1500, 1600, 10000, 10100 |  |  |
| `groundEffectDensity` | 16, 256 | 8, 264 |  |
| `groundEffectDist` | 40, 500 | 30, 510 |  |
| `lodObjectFadeScale` | 50, 5000 | 40, 5010 |  |
| `lodObjectCullSize` | 1, 100 | 0, 101 |  |
| `terrainLodDist` | 175, 200, 650, 675 |  |  |
| `wmoLodDist` | 240, 250, 400, 410 |  |  |
| `doodadLodScale` | 45, 50, 150, 155 |  |  |
| `entityLodDist` | 4, 5, 10, 11 |  |  |
| `terrainMipLevel` | 0, 1 |  |  |
| `componentTextureLevel` | 0, 1, 2 |  |  |
| `particleDensity` | 0, 100 | -5, 105 |  |
| `spellVisualDensityFilterSetting` | 1, 2, 3, 4 |  |  |
| `weatherDensity` | 0, 1, 2, 3 |  |  |
| `showfootprintparticles` | 0, 1 |  |  |
| `ffxGlow` | 0, 1 |  |  |
| `ffxDeath` | 0, 1 |  |  |
| `ffxNether` | 0, 1 |  |  |
| `sunShafts` | 0, 1, 2 |  |  |
| `volumeFog` | 0, 1 |  |  |
| `volumeFogLevel` | 0, 4 | -1, 5 |  |
| `volumeFogInterior` | 0, 1 |  |  |
| `specular` | 0, 1 | -0.05, 1.05 |  |
| `reflectionMode` | 0, 1, 2, 3 |  |  |
| `refraction` | 0, 2 | -1, 3 |  |
| `rippleDetail` | -1, 0, 2 | 3 |  |
| `DepthBasedOpacity` | 0, 1 |  |  |
| `shadowMode` | 0, 1, 2, 3, 4 |  |  |
| `shadowTextureSize` | 512, 1024, 2048 |  |  |
| `shadowNumCascades` | 0, 1, 4, 5 |  |  |
| `entityShadowFadeScale` | 5, 10, 50, 55 |  |  |
| `shadowSoft` | 0, 1 |  |  |
| `shadowBlendCascades` | 0, 1 |  |  |
| `ResampleAlwaysSharpen` | 0, 1 |  |  |
| `CMAA2Quality` | 0, 1, 2, 3 |  |  |
| `CMAA2ExtraSharpness` | 0, 1 |  |  |
| `DynamicRenderScale` | 0, 1 |  |  |
| `maxFPSLoading` | 10, 100 | 5, 105 |  |
| `screenshotQuality` | 1, 10 | 0, 11 |  |
| `screenshotFormat` | jpeg, png, tga |  |  |
| `cameraDistanceMaxZoomFactor` | 1, 2.6 | 0.9, 2.7 |  |
| `cameraZoomSpeed` | 1, 50 | 0, 51 |  |
| `cameraDistanceRateMult` | 0.1, 10, 10.1 | 0 |  |
| `cameraYawMoveSpeed` | 1, 360 | 0, 361 |  |
| `cameraPitchMoveSpeed` | 1, 360 | 0, 361 |  |
| `cameraYawSmoothSpeed` | 1, 360 | 0, 361 |  |
| `cameraPitchSmoothSpeed` | 1, 360 | 0, 361 |  |
| `cameraZSmooth` | 1, 2 |  |  |
| `test_cameraOverShoulder` | 0, 1 |  |  |
| `CameraKeepCharacterCentered` | 0, 1 |  |  |
| `CameraReduceUnexpectedMovement` | 0, 1 |  |  |
| `test_cameraDynamicPitch` | 0, 1 |  |  |
| `test_cameraDynamicPitchBaseFovPad` | 0, 1 | -0.05, 1.05 |  |
| `test_cameraDynamicPitchBaseFovPadFlying` | 0, 1 | -0.05, 1.05 |  |
| `test_cameraTargetFocusEnemyEnable` | 0, 1 |  |  |
| `test_cameraTargetFocusInteractEnable` | 0, 1 |  |  |
| `mouseAcceleration` | -1, 0, 1 |  |  |
| `nameplateMotionSpeed` | -0.005, 0, 1, 1.005 |  |  |
| `threatWarning` | 0, 1, 2, 3 |  |  |
| `FootstepSounds` | 0, 1 |  |  |
| `Sound_EnableArmorFoleySoundForSelf` | 0, 1 |  |  |
| `Sound_EnableArmorFoleySoundForOthers` | 0, 1 |  |  |
| `Sound_ListenerAtCharacter` | 0, 1 |  |  |
| `Sound_EnableDSPEffects` | 0, 1 |  |  |
| `SpellQueueWindow` | 0, 400 | -1, 401 |  |
| `LowLatencyMode` | 0, 1, 2, 3 | 4 | The engine said nothing. The game's own menu says of Intel XeLL on this card: "Requires an Intel graphics card." |
| `shadowRt` | 0 | 1, 2, 3 | Unsupported shadow RT mode. The game's own Graphics options say Fair, Good and High are "Disabled due to compatibility settings", and gx.log gives the card as rt:None. Unsupported shadow RT mode. The game's own Graphics options say Fair, Good and High are "Disabled due to compatibility settings", and gx.log gives the card as rt:None. |
| `ffxAntiAliasingMode` | 0, 1, 2, 3, 4 |  |  |
| `ResampleQuality` | 0, 1, 2, 3 |  |  |

### WoW retail 12.1.5 (build 70783), Mac, Metal

Each tuned setting's range ends or options, tried one setting at a time with `EverySetting.Probe`, the function behind `/every probe`, through a copy of Every Setting whose `.toc` gave retail's interface number, 120105. Not one step past the ends. The engine's words are from the console's own saved lines: retail left `Logs/General.log` empty. Of the 59 tuned settings tried, the engine kept both ends of all but two: `shadowTextureSize` (not 768, 1536 or 4096) and `cameraDistanceMaxZoomFactor` (not 4: retail stops it at 2.6). Seven tuned settings have no CVar in retail: the loot sparkle (`outlineModeShowLootEffectWhenDisabled`), `HDROutput`, `useHDRBrightness`, `useHDRPeakBrightness`, `giQuality`, `bloomEnable` and `classicStyleWorldText`. Not tried, as in Forever: `nameplateMotionSpeed`, which retail also marks as not to be set in combat; the six `test_camera` settings, which raise the game's warning when one is changed; and `DynamicRenderScale`, which changes the size the game renders at. Retail's CVar list (`data/ranges/70783/retail/cvars.lua` in the repository) has 1,683 CVars on this character, to Forever's 1,797. 17 are only in retail, two of them made by an addon (Details' `LibOpenRaidTempCache` and `LibOpenRaidTempCacheDebug`), and 131 only in Forever. Of the 1,666 in both, 39 have another default (`cameraDistanceMaxZoomFactor` 1.9, not 1; `nameplateMaxDistance` 60, not 45; `volumeFog` 0, not 1), 15 that Forever lists with no default have one in retail, and 4 have other flags: two kiosk CVars are read-only in retail, and `nameplateShowClassColor` and `nameplateShowFriendlyClassColor` are secure in retail and stored per account in Forever. The 1,712 values a snapshot read (every CVar, and the settings that aren't CVars it can) were the same after as before. On 15 November, on another character, Every Setting with retail's range set `cameraDistanceMaxZoomFactor` to 2, and its Photo style set it to 2.6 (the style's 4, held to retail's range): the engine kept both, and every value was the same after as before. Later on 15 November, on that same other character and its account, each control `CVars.lua` gives retail of its own (`RETAIL_CVARS`) was tried the same way, one CVar at a time, from `SSAOType` on, but for `nameplateStyle`, which retail marks as not to be set in combat, and the graphics quality levels (`graphicsComputeEffects`, `graphicsParticleDensity`), which set other CVars. Six of the 17 CVars only retail has weren't in the client on that account at all (`activeCUFProfile`, `auctionDisplayOnCharacter`, `nameplateShowFriends`, `playerStatLeftDropdown`, `playerStatRightDropdown`, `unlockedExpansionLandingPages`): an earlier version's, kept in the first account's saved settings. The 1,713 values a snapshot read were the same after as before.

74 CVars, 59 of them tuned settings.

| CVar | Kept | Not kept | Notes |
| --- | --- | --- | --- |
| `farclip` | 1000, 10000 |  |  |
| `horizonStart` | 400, 4000 |  |  |
| `horizonClip` | 1600, 10000 |  |  |
| `groundEffectDensity` | 16, 256 |  |  |
| `groundEffectDist` | 40, 500 |  |  |
| `lodObjectFadeScale` | 50, 5000 |  |  |
| `lodObjectCullSize` | 1, 100 |  |  |
| `terrainLodDist` | 200, 650 |  |  |
| `wmoLodDist` | 250, 400 |  |  |
| `doodadLodScale` | 50, 150 |  |  |
| `entityLodDist` | 5, 10 |  |  |
| `terrainMipLevel` | 0, 1 |  |  |
| `componentTextureLevel` | 0, 1, 2 |  |  |
| `particleDensity` | 0, 100 |  |  |
| `spellVisualDensityFilterSetting` | 1, 2, 3, 4 |  |  |
| `weatherDensity` | 0, 1, 2, 3 |  |  |
| `showfootprintparticles` | 0, 1 |  |  |
| `ffxGlow` | 0, 1 |  |  |
| `ffxDeath` | 0, 1 |  |  |
| `ffxNether` | 0, 1 |  |  |
| `sunShafts` | 0, 1, 2 |  |  |
| `volumeFog` | 0, 1 |  |  |
| `volumeFogLevel` | 0, 4 |  |  |
| `volumeFogInterior` | 0, 1 |  |  |
| `specular` | 0, 1 |  |  |
| `reflectionMode` | 0, 1, 2, 3 |  |  |
| `refraction` | 0, 2 |  |  |
| `rippleDetail` | 0, 2 |  |  |
| `DepthBasedOpacity` | 0, 1 |  |  |
| `shadowMode` | 0, 1, 2, 3, 4 |  |  |
| `shadowTextureSize` | 512, 1024, 2048 | 768, 1536, 4096 | Unsupported shadow texture size. Unsupported shadow texture size. Unsupported shadow texture size. |
| `shadowNumCascades` | 1, 4 |  |  |
| `entityShadowFadeScale` | 10, 50 |  |  |
| `shadowSoft` | 0, 1 |  |  |
| `shadowBlendCascades` | 0, 1 |  |  |
| `ResampleAlwaysSharpen` | 0, 1 |  |  |
| `CMAA2Quality` | 0, 1, 2, 3 |  |  |
| `CMAA2ExtraSharpness` | 0, 1 |  |  |
| `maxFPSLoading` | 10, 100 |  |  |
| `screenshotQuality` | 1, 10 |  |  |
| `screenshotFormat` | jpeg, png, tga |  |  |
| `cameraDistanceMaxZoomFactor` | 1, 2, 2.6 | 4 | Value out of range (1.000000 - 2.600000) Set through Every Setting, 2.6 by the Photo style. |
| `cameraZoomSpeed` | 1, 50 |  |  |
| `cameraDistanceRateMult` | 0.1, 10 |  |  |
| `cameraYawMoveSpeed` | 1, 360 |  |  |
| `cameraPitchMoveSpeed` | 1, 360 |  |  |
| `cameraYawSmoothSpeed` | 1, 360 |  |  |
| `cameraPitchSmoothSpeed` | 1, 360 |  |  |
| `cameraZSmooth` | 1, 2 |  |  |
| `CameraKeepCharacterCentered` | 0, 1 |  |  |
| `CameraReduceUnexpectedMovement` | 0, 1 |  |  |
| `mouseAcceleration` | -1, 0, 1 |  |  |
| `threatWarning` | 0, 1, 2, 3 |  |  |
| `FootstepSounds` | 0, 1 |  |  |
| `Sound_EnableArmorFoleySoundForSelf` | 0, 1 |  |  |
| `Sound_EnableArmorFoleySoundForOthers` | 0, 1 |  |  |
| `Sound_ListenerAtCharacter` | 0, 1 |  |  |
| `Sound_EnableDSPEffects` | 0, 1 |  |  |
| `SpellQueueWindow` | 0, 400 |  |  |
| `SSAOType` | 1 | 2, 3, 9 | Unsupported SSAO type. Unsupported SSAO type, for each. |
| `useShadowMapping` | 0, 2 |  |  |
| `volumeFogDisableLightScattering` | 0, 1 |  |  |
| `volumeFogDisableNoise` | 0, 1 |  |  |
| `volumeFogDisableShadows` | 0, 1 |  |  |
| `volumeFogUse16BitTexture` | 0, 1 |  |  |
| `advFlyKeyboardMinPitchFactor` | 1, 10 |  |  |
| `advFlyKeyboardMaxPitchFactor` | 1, 10 |  |  |
| `advFlyKeyboardMinTurnFactor` | 1, 10 |  |  |
| `advFlyKeyboardMaxTurnFactor` | 1, 10 |  |  |
| `advFlyPitchControlCameraChase` | 10, 30 |  |  |
| `advFlyPitchControl` | 1, 2 |  |  |
| `LowLatencyMode` | 1 | 4 | Not Intel XeLL, on a Mac: retail's own menu offers only what the computer supports. |
| `Outline` | 0, 3 |  |  |
| `encounterTimelineEnabled` | 0, 1 |  |  |

## Counts

Of the client's 1,811 CVars, on a Mac or on Windows:

|  | CVars | Share |
| --- | --- | --- |
| Have a control in the game's own options (`ui`) | 314 | 17.3% |
| Have none, and are set by one of the options' graphics quality settings (`data/presets.lua`) | 39 | 2.2% |
| Are the raid twin of one of either (`as X`) | 46 | 2.5% |
| Those three together: what the game's options reach | 399 | 22.0% |
| Are tuned in Every Setting | 74 | 4.1% |
| Have a control in Every Setting, tuned or suggested | 870 | 48.0% |
