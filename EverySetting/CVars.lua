-- Every CVar in the WoW Forever client (1.60.1.70938), on a Mac and on Windows,
-- for the list of all CVars: the section each is listed under and, where the
-- game's range or options are known, the control to suggest. Core.lua (RawKnob)
-- reads these. A CVar that isn't here still gets listed, under the last section,
-- with a box. A line for a CVar only one of them has does nothing on the other.
-- Retail's own lines, for the CVars only retail has and those it gives another
-- control, are at the end (RETAIL_CVARS).
--
--   "1"               listed under section 1, with just a box
--   "1|t"             a checkbox: 0 or 1
--   "1|s|0|1|0.05"    a slider: min, max, step. Its box still takes any value.
--   "1|c|0=OFF|1=ON"  a menu: value=LABEL for each option, where LABEL is the
--                     label's key in the locale table (Locales/enUS.lua). A label
--                     of capitals, digits and signs (SDL, 03:27) is shown as it is.
--   "1|S|1|540|1"     a slider whose box is held to the range too
--   "1|f|1=A|2=B"     a menu of flags to tick, for a CVar that packs a set of
--                     on/off flags into one value: index=LABEL for each flag,
--                     by the index the game sets it by, from 1. "-2=A": a box
--                     that's ticked while flag 2 is off (a filter the game keeps
--                     as a flag for each one that's turned off)
--   "1|h"             a color, as eight hex digits (alpha, red, green, blue): a
--                     swatch that opens the game's color picker
--   "...|gx"          (after the control) a change shows after a graphics restart.
--                     "window": once the game's window is updated. "reload": after
--                     the interface is reloaded. "login": once the player logs out
--                     and in again. "client": the next time the game starts.
--                     "...|client:0" marks only a change to 0.
--   "...|x"           (last) the game's server enforces it: a danger setting, which
--                     Every Setting changes only by hand, and only in danger mode
--
-- A control is only suggested on evidence, noted after each entry:
--   ui     Blizzard's settings code has that control for it
--   code   a toggle: Blizzard's interface code only reads or sets it as on or off
--   help   the CVar's help text gives the range or lists the values
--   probe  the engine, set in game, kept only those values
--   name   a toggle read from a name such as showX or enableX
--   as X   a raid twin, given the control of the CVar it stands in for
-- A restart marker goes on evidence too, noted after the control's as "restart: ui":
--   ui     Blizzard's settings code restarts the graphics or updates the window
--          after a change to it, or says the game needs restarting
--   help   the CVar's help text says so
--   probe  seen in game: a change showed only after it
--   guide  another addon's page or a guide says so. Not seen in game.
-- CVars with a knob in Knobs.lua have only their section here.

local _, ns = ...
local EverySetting = ns.EverySetting
local L = ns.L

EverySetting.SECTIONS = {
	L.GRAPHICS,
	L.RAID_GRAPHICS,
	L.CAMERA,
	L.NAMEPLATES_AND_NAMES,
	L.SOUND_AND_VOICE,
	L.CHAT_AND_SOCIAL,
	L.COMBAT_TEXT,
	L.UNIT_AND_RAID_FRAMES,
	L.ACTION_BARS_AND_SPELLS,
	L.TARGETING_AND_INTERACTION,
	L.MOUSE_AND_KEYBOARD,
	L.GAMEPAD,
	L.ACCESSIBILITY,
	L.INTERFACE,
	L.NETWORK_AND_SYSTEM,
	L.DEBUG_AND_DEVELOPMENT,
	L.OTHER,
}

EverySetting.CVARS = {
	accessibilityScreenNarrationEnabled = "13|t", -- ui
	accessibilityScreenNarrationSpeechRate = "13|s|-10|10|1", -- ui
	accessibilityScreenNarrationSpeechVolume = "13|s|0|100|1", -- ui
	accessibilityScreenNarrationVoice = "13",
	accountNeedsTurnStrafeDialog = "17",
	acknowledgedArrowCallouts = "17",
	ActionButtonUseKeyDown = "9|t", -- help
	ActionButtonUseKeyHeldSpell = "9|t", -- ui
	ActionCombatCameraEnable = "3|t", -- help
	actionedAdventureJournalEntries = "17",
	addFriendInfoShown = "17",
	addonChallengeModeRestrictionsForced = "16|t", -- help
	addonChatRestrictionsForced = "16|t", -- help
	addonCombatRestrictionsForced = "16|t", -- help
	addonEncounterRestrictionsForced = "16|t", -- help
	addonLoadDebugging = "16|t", -- help
	addonMapRestrictionsForced = "16|t", -- help
	addonPerformanceMsgError = "16",
	addonPerformanceMsgOverall = "16",
	addonPerformanceMsgWarning = "16",
	addonPvPMatchRestrictionsForced = "16|t", -- help
	advancedCombatLogging = "15|t", -- ui
	AdvFlyingDynamicFOVEnabled = "3|t", -- help
	advFlyKeyboardMaxPitchFactor = "11",
	advFlyKeyboardMaxTurnFactor = "11",
	advFlyKeyboardMinPitchFactor = "11",
	advFlyKeyboardMinTurnFactor = "11",
	advFlyPitchControl = "11",
	advFlyPitchControlCameraChase = "3",
	advFlyPitchControlGroundDebounce = "11|t", -- help
	agentUID = "15",
	AIBrain = "16",
	AIController = "16",
	AIControllerEventLog = "16",
	AIEventLog = "16",
	allowCompareWithToggle = "14|t", -- code
	allowDevPublicKey = "15|t", -- help
	AllowMacHideAppBinding = "11|t", -- help
	AllowMacHideOthersBinding = "11|t", -- help
	AllowMacQuitBinding = "11|t", -- help
	AllowSoftwareRenderer = "1|t", -- help
	AllowSoftwareRendererDX12 = "1|t", -- name
	AllowSpectateMode = "14|t", -- help
	AllowWinRT = "15|t", -- name
	alwaysCompareItems = "14|t", -- help
	alwaysShowRuneIcons = "14|t", -- help
	animFrameSkipLOD = "1",
	arachnophobiaMode = "13|t", -- ui
	AreaTriggerEventLog = "16",
	AreaTriggers = "16",
	assaoAdaptiveQualityLimit = "1|s|0|1|0.05", -- help
	assaoBlurPassCount = "1|s|0|6|1", -- help
	assaoDetailShadowStrength = "1|s|0|5|0.1", -- help
	assaoFadeOutFrom = "1",
	assaoFadeOutTo = "1",
	assaoHorizonAngleThresh = "1",
	assaoNormals = "1|t", -- help
	assaoRadius = "1",
	assaoShadowClamp = "1|s|0|1|0.05", -- help
	assaoShadowMult = "1|s|0|5|0.1", -- help
	assaoShadowPower = "1|s|0.5|5|0.1", -- help
	assaoSharpness = "1|s|0|1|0.05", -- help
	assaoTemporalSSAngleOffset = "1",
	assaoTemporalSSRadiusOffset = "1|s|0|2|0.05", -- help
	assistAttack = "10|t", -- help
	assistedCombatHighlight = "9|t", -- ui
	assistedCombatHighlightRPE = "17",
	assistedCombatIconUpdateRate = "9",
	assistedCombatReduceHighlights = "9|t", -- ui
	AsyncAssistActions = "16",
	asyncHandlerTimeout = "15",
	asyncThreadSleep = "15",
	auctionHouseDurationDropdown = "17",
	audioLocale = "15",
	AuraDebugger = "16",
	AuraEventLog = "16",
	autoAcceptQuickJoinRequests = "6|t", -- ui
	autoClearAFK = "14|t", -- ui
	autoCompleteResortNamesOnRecency = "6|t", -- name
	autoCompleteUseContext = "6|t", -- name
	autoCompleteWhenEditingFromCenter = "6|t", -- name
	autoDismount = "9|t", -- name
	autoDismountFlying = "9|t", -- help
	autoFilledMultiCastSlots = "17",
	autoInteract = "10|t", -- ui
	autojoinBGVoice = "5|t", -- name
	autojoinPartyVoice = "5|t", -- name
	autoLootDefault = "10|t", -- ui
	autoLootRate = "10",
	AutoPushSpellToActionBar = "9|t", -- help
	autoQuestPopUps = "17",
	autoQuestProgress = "14|t", -- help
	autoQuestWatch = "14|t", -- help
	autoRangedCombat = "9|t", -- ui
	autoSelfCast = "9|t", -- help
	autoStand = "14|t", -- name
	autoUnshift = "9|t", -- name
	bankAutoDepositReagents = "14|t", -- help
	bankConfirmTabCleanUp = "14|t", -- help
	BeckonTriggerEventlog = "16",
	BehaviorTree = "16",
	BlizzCon2026ColdSwapFeatureEnabled = "17|t", -- name
	BlizzCon2026Experience = "17|t", -- probe
	blockChannelInvites = "6|t", -- ui
	blockTrades = "6|t", -- ui
	bloomEnable = "1",
	bloomUserMult = "1|s|0|1|0.2", -- ui
	bodyQuota = "1",
	breakUpLargeNumbers = "14|t", -- help
	Brightness = "1|s|0|100|1", -- ui
	buffDurations = "8|t", -- help
	CAADebuffSelfAlert = "13",
	CAAEnabled = "13|t", -- ui
	CAAInterruptCast = "13",
	CAAInterruptCastSuccess = "13",
	CAAPartyHealthFrequency = "13|s|-10|10|1", -- ui
	CAAPartyHealthPercent = "13|c|0=OFF|1=UNDER_100|2=UNDER_90|3=UNDER_80|4=UNDER_70|5=UNDER_60|6=UNDER_50|7=UNDER_40|8=UNDER_30|9=UNDER_20|10=UNDER_10", -- ui
	CAAPartyHealthVoice = "13",
	CAAPartyHealthVolume = "13|s|0|100|1", -- help
	CAAPlayerCastFormat = "13|c|0=FULL|1=SHORT|2=NO_SPELL_NAME|3=SHORT_NO_SPELL_NAME|4=SPELL_NAME_ONLY", -- ui
	CAAPlayerCastMinTime = "13|s|0|5|0.5", -- ui
	CAAPlayerCastMode = "13|c|0=OFF|1=CAST_START|2=CAST_END", -- ui
	CAAPlayerCastThrottle = "13|s|0|5|0.5", -- ui
	CAAPlayerCastVoice = "13",
	CAAPlayerCastVolume = "13|s|0|100|1", -- help
	CAAPlayerHealthFormat = "13|c|0=FULL|1=NO_PERCENT|2=NO_PERCENT_VALUE_10|3=NO_HEALTH|4=NUMBER_ONLY|5=NUMBER_ONLY_VALUE_10", -- ui
	CAAPlayerHealthPercent = "13|c|0=OFF|1=EVERY_10|2=EVERY_20|3=EVERY_30|4=EVERY_40|5=EVERY_50", -- ui
	CAAPlayerHealthThrottle = "13|s|0|5|0.5", -- ui
	CAAPlayerHealthVoice = "13",
	CAAPlayerHealthVolume = "13|s|0|100|1", -- help
	CAAPulsePlayerHealthPercent = "13|c|0=OFF|1=UNDER_90|2=UNDER_80|3=UNDER_70|4=UNDER_60|5=UNDER_50|6=UNDER_40|7=UNDER_30|8=UNDER_20|9=UNDER_10", -- ui
	CAAPulsePlayerHealthVolume = "13|s|0|100|1", -- help
	CAAResource1Formats = "13",
	CAAResource1Percents = "13",
	CAAResource1Throttle = "13",
	CAAResource1Voice = "13",
	CAAResource1Volume = "13",
	CAAResource2Formats = "13",
	CAAResource2Percents = "13",
	CAAResource2Throttle = "13",
	CAAResource2Voice = "13",
	CAAResource2Volume = "13",
	CAASayCombatEnd = "13",
	CAASayCombatStart = "13",
	CAASayIfTargeted = "13",
	CAASayTargetName = "13|t", -- ui
	CAASayYourDebuffs = "13|t", -- ui
	CAASayYourDebuffsFormat = "13|c|0=FULL|1=NO_SPELL_NAME", -- ui
	CAASayYourDebuffsMinDuration = "13|s|0|5|0.5", -- ui
	CAASayYourDebuffsVoice = "13",
	CAASayYourDebuffsVolume = "13|s|0|100|1", -- help
	CAASpeed = "13|s|-10|10|1", -- help
	CAATargetCastFormat = "13|c|0=TARGET_FULL|1=TARGET_SHORT|2=FULL|3=SHORT|4=NO_SPELL_NAME|5=SHORT_NO_SPELL_NAME|6=SPELL_NAME_ONLY", -- ui
	CAATargetCastMinTime = "13|s|0|5|0.5", -- ui
	CAATargetCastMode = "13|c|0=OFF|1=CAST_START|2=CAST_END", -- ui
	CAATargetCastThrottle = "13|s|0|5|0.5", -- ui
	CAATargetCastVoice = "13",
	CAATargetCastVolume = "13|s|0|100|1", -- help
	CAATargetDeathBehavior = "13",
	CAATargetHealthFormat = "13|c|0=FULL|1=NO_PERCENT|2=NO_PERCENT_VALUE_10|3=NO_HEALTH|4=NUMBER_ONLY|5=NUMBER_ONLY_VALUE_10|6=TARGET_FULL|7=TARGET_NO_PERCENT|8=TARGET_NO_PERCENT_VALUE_10", -- ui
	CAATargetHealthPercent = "13|c|0=OFF|1=EVERY_10|2=EVERY_20|3=EVERY_30|4=EVERY_40|5=EVERY_50", -- ui
	CAATargetHealthThrottle = "13|s|0|5|0.5", -- ui
	CAATargetHealthVoice = "13",
	CAATargetHealthVolume = "13|s|0|100|1", -- help
	CAAVoice = "13",
	CAAVolume = "13|s|0|100|1", -- help
	["CACHE-WGOB-GameObjectsHotfixCount"] = "17",
	["CACHE-WGOB-GameObjectsRecordCount"] = "17",
	["CACHE-WQST-QuestObjectiveHotfixCount"] = "17",
	["CACHE-WQST-QuestObjectiveRecordCount"] = "17",
	["CACHE-WQST-QuestObjectiveXEffectHotfixCount"] = "17",
	["CACHE-WQST-QuestObjectiveXEffectRecordCount"] = "17",
	["CACHE-WQST-QuestV2HotfixCount"] = "17",
	["CACHE-WQST-QuestV2RecordCount"] = "17",
	calendarShowBattlegrounds = "14|t", -- help
	calendarShowDarkmoon = "14|t", -- help
	calendarShowHolidays = "14|t", -- help
	calendarShowLockouts = "14|t", -- help
	calendarShowResets = "14|t", -- help
	calendarShowWeeklyHolidays = "14|t", -- help
	cameraBobbing = "3|t", -- ui
	cameraBobbingSmoothSpeed = "3",
	cameraCustomViewSmoothing = "3",
	cameraDistanceMaxZoomFactor = "3",
	cameraDistanceRateMult = "3",
	cameraDive = "3",
	CameraFollowGamepadAdjustDelay = "3",
	CameraFollowGamepadAdjustEaseIn = "3",
	CameraFollowOnStick = "3|t", -- help
	CameraFollowPitchDeadZone = "3",
	CameraFollowPitchOffset = "3",
	CameraFollowPitchSpeed = "3",
	CameraFollowPitchStrength = "3",
	CameraFollowSnapCharacterAngle = "3",
	CameraFollowTargetCombat = "3",
	CameraFollowYawSpeed = "3",
	cameraFov = "3",
	cameraFoVSmoothSpeed = "3",
	cameraGroundSmoothSpeed = "3",
	cameraHeightIgnoreStandState = "3",
	cameraIndirectOffset = "3",
	cameraIndirectVisibility = "3",
	CameraKeepCharacterCentered = "3",
	cameraPitchMoveSpeed = "3",
	cameraPitchSmoothMax = "3",
	cameraPitchSmoothMin = "3",
	cameraPitchSmoothSpeed = "3",
	cameraPivot = "3|t", -- ui
	cameraPivotDXMax = "3",
	cameraPivotDYMin = "3",
	CameraReduceUnexpectedMovement = "3",
	cameraSavedDistance = "17",
	cameraSavedPetBattleDistance = "17",
	cameraSavedPitch = "17",
	cameraSavedVehicleDistance = "17",
	cameraSmooth = "3",
	cameraSmoothAlwaysFearDelay = "3",
	cameraSmoothAlwaysFearFactor = "3",
	cameraSmoothAlwaysIdleDelay = "3",
	cameraSmoothAlwaysIdleFactor = "3",
	cameraSmoothAlwaysMoveDelay = "3",
	cameraSmoothAlwaysMoveFactor = "3",
	cameraSmoothAlwaysStopDelay = "3",
	cameraSmoothAlwaysStopFactor = "3",
	cameraSmoothAlwaysStrafeDelay = "3",
	cameraSmoothAlwaysStrafeFactor = "3",
	cameraSmoothAlwaysTrackDelay = "3",
	cameraSmoothAlwaysTrackFactor = "3",
	cameraSmoothAlwaysTurnDelay = "3",
	cameraSmoothAlwaysTurnFactor = "3",
	cameraSmoothNeverFearDelay = "3",
	cameraSmoothNeverFearFactor = "3",
	cameraSmoothNeverIdleDelay = "3",
	cameraSmoothNeverIdleFactor = "3",
	cameraSmoothNeverMoveDelay = "3",
	cameraSmoothNeverMoveFactor = "3",
	cameraSmoothNeverStopDelay = "3",
	cameraSmoothNeverStopFactor = "3",
	cameraSmoothNeverStrafeDelay = "3",
	cameraSmoothNeverStrafeFactor = "3",
	cameraSmoothNeverTrackDelay = "3",
	cameraSmoothNeverTrackFactor = "3",
	cameraSmoothNeverTurnDelay = "3",
	cameraSmoothNeverTurnFactor = "3",
	cameraSmoothPitch = "3",
	cameraSmoothSmarterFearDelay = "3",
	cameraSmoothSmarterFearFactor = "3",
	cameraSmoothSmarterIdleDelay = "3",
	cameraSmoothSmarterIdleFactor = "3",
	cameraSmoothSmarterMoveDelay = "3",
	cameraSmoothSmarterMoveFactor = "3",
	cameraSmoothSmarterStopDelay = "3",
	cameraSmoothSmarterStopFactor = "3",
	cameraSmoothSmarterStrafeDelay = "3",
	cameraSmoothSmarterStrafeFactor = "3",
	cameraSmoothSmarterTrackDelay = "3",
	cameraSmoothSmarterTrackFactor = "3",
	cameraSmoothSmarterTurnDelay = "3",
	cameraSmoothSmarterTurnFactor = "3",
	cameraSmoothSmartFearDelay = "3",
	cameraSmoothSmartFearFactor = "3",
	cameraSmoothSmartIdleDelay = "3",
	cameraSmoothSmartIdleFactor = "3",
	cameraSmoothSmartMoveDelay = "3",
	cameraSmoothSmartMoveFactor = "3",
	cameraSmoothSmartStopDelay = "3",
	cameraSmoothSmartStopFactor = "3",
	cameraSmoothSmartStrafeDelay = "3",
	cameraSmoothSmartStrafeFactor = "3",
	cameraSmoothSmartTrackDelay = "3",
	cameraSmoothSmartTrackFactor = "3",
	cameraSmoothSmartTurnDelay = "3",
	cameraSmoothSmartTurnFactor = "3",
	cameraSmoothSplineFearDelay = "3",
	cameraSmoothSplineFearFactor = "3",
	cameraSmoothSplineIdleDelay = "3",
	cameraSmoothSplineIdleFactor = "3",
	cameraSmoothSplineMoveDelay = "3",
	cameraSmoothSplineMoveFactor = "3",
	cameraSmoothSplineStopDelay = "3",
	cameraSmoothSplineStopFactor = "3",
	cameraSmoothSplineStrafeDelay = "3",
	cameraSmoothSplineStrafeFactor = "3",
	cameraSmoothSplineTrackDelay = "3",
	cameraSmoothSplineTrackFactor = "3",
	cameraSmoothSplineTurnDelay = "3",
	cameraSmoothSplineTurnFactor = "3",
	cameraSmoothStyle = "3|c|1=SMART|4=SMARTER|2=ALWAYS|0=NEVER", -- ui
	cameraSmoothTimeMax = "3",
	cameraSmoothTimeMin = "3",
	cameraSmoothTrackingStyle = "3|c|1=SMART|4=SMARTER|2=ALWAYS|0=NEVER", -- ui
	cameraSmoothViewDataAlwaysDistanceDelay = "3",
	cameraSmoothViewDataAlwaysDistanceFactor = "3",
	cameraSmoothViewDataAlwaysPitchDelay = "3",
	cameraSmoothViewDataAlwaysPitchFactor = "3",
	cameraSmoothViewDataAlwaysYawDelay = "3",
	cameraSmoothViewDataAlwaysYawFactor = "3",
	cameraSmoothViewDataNeverDistanceDelay = "3",
	cameraSmoothViewDataNeverDistanceFactor = "3",
	cameraSmoothViewDataNeverPitchDelay = "3",
	cameraSmoothViewDataNeverPitchFactor = "3",
	cameraSmoothViewDataNeverYawDelay = "3",
	cameraSmoothViewDataNeverYawFactor = "3",
	cameraSmoothViewDataSmartDistanceDelay = "3",
	cameraSmoothViewDataSmartDistanceFactor = "3",
	cameraSmoothViewDataSmarterDistanceDelay = "3",
	cameraSmoothViewDataSmarterDistanceFactor = "3",
	cameraSmoothViewDataSmarterPitchDelay = "3",
	cameraSmoothViewDataSmarterPitchFactor = "3",
	cameraSmoothViewDataSmarterYawDelay = "3",
	cameraSmoothViewDataSmarterYawFactor = "3",
	cameraSmoothViewDataSmartPitchDelay = "3",
	cameraSmoothViewDataSmartPitchFactor = "3",
	cameraSmoothViewDataSmartYawDelay = "3",
	cameraSmoothViewDataSmartYawFactor = "3",
	cameraSmoothViewDataSplineDistanceDelay = "3",
	cameraSmoothViewDataSplineDistanceFactor = "3",
	cameraSmoothViewDataSplinePitchDelay = "3",
	cameraSmoothViewDataSplinePitchFactor = "3",
	cameraSmoothViewDataSplineYawDelay = "3",
	cameraSmoothViewDataSplineYawFactor = "3",
	cameraSmoothYaw = "3",
	cameraSubmergePitch = "3",
	cameraSurfacePitch = "3",
	cameraTargetSmoothSpeed = "3",
	cameraTerrainTilt = "3|t", -- ui
	cameraTerrainTiltAlwaysFallAbsorb = "3",
	cameraTerrainTiltAlwaysFallDelay = "3",
	cameraTerrainTiltAlwaysFallFactor = "3",
	cameraTerrainTiltAlwaysFearAbsorb = "3",
	cameraTerrainTiltAlwaysFearDelay = "3",
	cameraTerrainTiltAlwaysFearFactor = "3",
	cameraTerrainTiltAlwaysIdleAbsorb = "3",
	cameraTerrainTiltAlwaysIdleDelay = "3",
	cameraTerrainTiltAlwaysIdleFactor = "3",
	cameraTerrainTiltAlwaysJumpAbsorb = "3",
	cameraTerrainTiltAlwaysJumpDelay = "3",
	cameraTerrainTiltAlwaysJumpFactor = "3",
	cameraTerrainTiltAlwaysMoveAbsorb = "3",
	cameraTerrainTiltAlwaysMoveDelay = "3",
	cameraTerrainTiltAlwaysMoveFactor = "3",
	cameraTerrainTiltAlwaysStrafeAbsorb = "3",
	cameraTerrainTiltAlwaysStrafeDelay = "3",
	cameraTerrainTiltAlwaysStrafeFactor = "3",
	cameraTerrainTiltAlwaysSwimAbsorb = "3",
	cameraTerrainTiltAlwaysSwimDelay = "3",
	cameraTerrainTiltAlwaysSwimFactor = "3",
	cameraTerrainTiltAlwaysTaxiAbsorb = "3",
	cameraTerrainTiltAlwaysTaxiDelay = "3",
	cameraTerrainTiltAlwaysTaxiFactor = "3",
	cameraTerrainTiltAlwaysTrackAbsorb = "3",
	cameraTerrainTiltAlwaysTrackDelay = "3",
	cameraTerrainTiltAlwaysTrackFactor = "3",
	cameraTerrainTiltAlwaysTurnAbsorb = "3",
	cameraTerrainTiltAlwaysTurnDelay = "3",
	cameraTerrainTiltAlwaysTurnFactor = "3",
	cameraTerrainTiltNeverFallAbsorb = "3",
	cameraTerrainTiltNeverFallDelay = "3",
	cameraTerrainTiltNeverFallFactor = "3",
	cameraTerrainTiltNeverFearAbsorb = "3",
	cameraTerrainTiltNeverFearDelay = "3",
	cameraTerrainTiltNeverFearFactor = "3",
	cameraTerrainTiltNeverIdleAbsorb = "3",
	cameraTerrainTiltNeverIdleDelay = "3",
	cameraTerrainTiltNeverIdleFactor = "3",
	cameraTerrainTiltNeverJumpAbsorb = "3",
	cameraTerrainTiltNeverJumpDelay = "3",
	cameraTerrainTiltNeverJumpFactor = "3",
	cameraTerrainTiltNeverMoveAbsorb = "3",
	cameraTerrainTiltNeverMoveDelay = "3",
	cameraTerrainTiltNeverMoveFactor = "3",
	cameraTerrainTiltNeverStrafeAbsorb = "3",
	cameraTerrainTiltNeverStrafeDelay = "3",
	cameraTerrainTiltNeverStrafeFactor = "3",
	cameraTerrainTiltNeverSwimAbsorb = "3",
	cameraTerrainTiltNeverSwimDelay = "3",
	cameraTerrainTiltNeverSwimFactor = "3",
	cameraTerrainTiltNeverTaxiAbsorb = "3",
	cameraTerrainTiltNeverTaxiDelay = "3",
	cameraTerrainTiltNeverTaxiFactor = "3",
	cameraTerrainTiltNeverTrackAbsorb = "3",
	cameraTerrainTiltNeverTrackDelay = "3",
	cameraTerrainTiltNeverTrackFactor = "3",
	cameraTerrainTiltNeverTurnAbsorb = "3",
	cameraTerrainTiltNeverTurnDelay = "3",
	cameraTerrainTiltNeverTurnFactor = "3",
	cameraTerrainTiltSmarterFallAbsorb = "3",
	cameraTerrainTiltSmarterFallDelay = "3",
	cameraTerrainTiltSmarterFallFactor = "3",
	cameraTerrainTiltSmarterFearAbsorb = "3",
	cameraTerrainTiltSmarterFearDelay = "3",
	cameraTerrainTiltSmarterFearFactor = "3",
	cameraTerrainTiltSmarterIdleAbsorb = "3",
	cameraTerrainTiltSmarterIdleDelay = "3",
	cameraTerrainTiltSmarterIdleFactor = "3",
	cameraTerrainTiltSmarterJumpAbsorb = "3",
	cameraTerrainTiltSmarterJumpDelay = "3",
	cameraTerrainTiltSmarterJumpFactor = "3",
	cameraTerrainTiltSmarterMoveAbsorb = "3",
	cameraTerrainTiltSmarterMoveDelay = "3",
	cameraTerrainTiltSmarterMoveFactor = "3",
	cameraTerrainTiltSmarterStrafeAbsorb = "3",
	cameraTerrainTiltSmarterStrafeDelay = "3",
	cameraTerrainTiltSmarterStrafeFactor = "3",
	cameraTerrainTiltSmarterSwimAbsorb = "3",
	cameraTerrainTiltSmarterSwimDelay = "3",
	cameraTerrainTiltSmarterSwimFactor = "3",
	cameraTerrainTiltSmarterTaxiAbsorb = "3",
	cameraTerrainTiltSmarterTaxiDelay = "3",
	cameraTerrainTiltSmarterTaxiFactor = "3",
	cameraTerrainTiltSmarterTrackAbsorb = "3",
	cameraTerrainTiltSmarterTrackDelay = "3",
	cameraTerrainTiltSmarterTrackFactor = "3",
	cameraTerrainTiltSmarterTurnAbsorb = "3",
	cameraTerrainTiltSmarterTurnDelay = "3",
	cameraTerrainTiltSmarterTurnFactor = "3",
	cameraTerrainTiltSmartFallAbsorb = "3",
	cameraTerrainTiltSmartFallDelay = "3",
	cameraTerrainTiltSmartFallFactor = "3",
	cameraTerrainTiltSmartFearAbsorb = "3",
	cameraTerrainTiltSmartFearDelay = "3",
	cameraTerrainTiltSmartFearFactor = "3",
	cameraTerrainTiltSmartIdleAbsorb = "3",
	cameraTerrainTiltSmartIdleDelay = "3",
	cameraTerrainTiltSmartIdleFactor = "3",
	cameraTerrainTiltSmartJumpAbsorb = "3",
	cameraTerrainTiltSmartJumpDelay = "3",
	cameraTerrainTiltSmartJumpFactor = "3",
	cameraTerrainTiltSmartMoveAbsorb = "3",
	cameraTerrainTiltSmartMoveDelay = "3",
	cameraTerrainTiltSmartMoveFactor = "3",
	cameraTerrainTiltSmartStrafeAbsorb = "3",
	cameraTerrainTiltSmartStrafeDelay = "3",
	cameraTerrainTiltSmartStrafeFactor = "3",
	cameraTerrainTiltSmartSwimAbsorb = "3",
	cameraTerrainTiltSmartSwimDelay = "3",
	cameraTerrainTiltSmartSwimFactor = "3",
	cameraTerrainTiltSmartTaxiAbsorb = "3",
	cameraTerrainTiltSmartTaxiDelay = "3",
	cameraTerrainTiltSmartTaxiFactor = "3",
	cameraTerrainTiltSmartTrackAbsorb = "3",
	cameraTerrainTiltSmartTrackDelay = "3",
	cameraTerrainTiltSmartTrackFactor = "3",
	cameraTerrainTiltSmartTurnAbsorb = "3",
	cameraTerrainTiltSmartTurnDelay = "3",
	cameraTerrainTiltSmartTurnFactor = "3",
	cameraTerrainTiltSplineFallAbsorb = "3",
	cameraTerrainTiltSplineFallDelay = "3",
	cameraTerrainTiltSplineFallFactor = "3",
	cameraTerrainTiltSplineFearAbsorb = "3",
	cameraTerrainTiltSplineFearDelay = "3",
	cameraTerrainTiltSplineFearFactor = "3",
	cameraTerrainTiltSplineIdleAbsorb = "3",
	cameraTerrainTiltSplineIdleDelay = "3",
	cameraTerrainTiltSplineIdleFactor = "3",
	cameraTerrainTiltSplineJumpAbsorb = "3",
	cameraTerrainTiltSplineJumpDelay = "3",
	cameraTerrainTiltSplineJumpFactor = "3",
	cameraTerrainTiltSplineMoveAbsorb = "3",
	cameraTerrainTiltSplineMoveDelay = "3",
	cameraTerrainTiltSplineMoveFactor = "3",
	cameraTerrainTiltSplineStrafeAbsorb = "3",
	cameraTerrainTiltSplineStrafeDelay = "3",
	cameraTerrainTiltSplineStrafeFactor = "3",
	cameraTerrainTiltSplineSwimAbsorb = "3",
	cameraTerrainTiltSplineSwimDelay = "3",
	cameraTerrainTiltSplineSwimFactor = "3",
	cameraTerrainTiltSplineTaxiAbsorb = "3",
	cameraTerrainTiltSplineTaxiDelay = "3",
	cameraTerrainTiltSplineTaxiFactor = "3",
	cameraTerrainTiltSplineTrackAbsorb = "3",
	cameraTerrainTiltSplineTrackDelay = "3",
	cameraTerrainTiltSplineTrackFactor = "3",
	cameraTerrainTiltSplineTurnAbsorb = "3",
	cameraTerrainTiltSplineTurnDelay = "3",
	cameraTerrainTiltSplineTurnFactor = "3",
	cameraTerrainTiltTimeMax = "3",
	cameraTerrainTiltTimeMin = "3",
	cameraView = "3",
	cameraViewBlendStyle = "3",
	cameraWaterCollision = "3|t", -- ui
	cameraYawMoveSpeed = "3",
	cameraYawSmoothMax = "3",
	cameraYawSmoothMin = "3",
	cameraYawSmoothSpeed = "3",
	cameraZoomSpeed = "3",
	cameraZSmooth = "3",
	canUseQuestItemWithLeftClick = "14|t", -- help
	casContainerSizeLimit = "15",
	categorizeTrainerUI = "14|t", -- help
	characterFrameCollapsed = "14|t", -- help
	characterNeedsTurnStrafeDialog = "17",
	characterSocialRestrictionSettingsApplied = "17",
	ChatAmbienceVolume = "5|s|0|1|0.05", -- help
	chatBubbles = "6|t", -- ui
	chatBubblesParty = "6|t", -- ui
	chatBubblesRaid = "6|t", -- ui
	chatClassColorOverride = "6|c|0=ALWAYS_COLOR_BY_CLASS|1=NEVER_COLOR_BY_CLASS|2=RESPECT_PER_CHANNEL_SETTINGS", -- help
	chatMouseScroll = "6|t", -- help
	ChatMusicVolume = "5|s|0|1|0.05", -- help
	ChatSoundVolume = "5|s|0|1|0.05", -- help
	chatStyle = "6|c|im=IM_STYLE|classic=CLASSIC_STYLE", -- ui
	checkAddonVersion = "14",
	ChromaEffectsEnable = "11|t", -- help
	ChromaEffectsFactionColor = "11|t", -- help
	classicStyleWorldText = "7",
	ClientCastDebug = "16",
	ClientCastLimitDebug = "16",
	ClientMessageEventLog = "16",
	ClientSettings_AFTERMATH_BY_API_MASK = "1",
	ClientSettings_AFTERMATH_BY_GPU_CATEGORY = "1",
	ClientSettings_ASYNC_COMPUTE_BY_API_MASK = "1",
	ClientSettings_ASYNC_COMPUTE_BY_GPU_CATEGORY = "1",
	ClientSettings_ClusteredShading = "1",
	ClientSettings_CMAA2 = "1",
	ClientSettings_CMD_LIST_MT_BY_API_MASK = "1",
	ClientSettings_CMD_LIST_MT_BY_GPU_CATEGORY = "1",
	ClientSettings_COPY_QUEUE_BY_API_MASK = "1",
	ClientSettings_COPY_QUEUE_BY_GPU_CATEGORY = "1",
	ClientSettings_CTexAsyncCreate = "1",
	ClientSettings_FSR = "1",
	ClientSettings_HIGH_MEM_FEATURES_BY_API_MASK = "1",
	ClientSettings_HIGH_MEM_FEATURES_BY_GPU_CATEGORY = "1",
	ClientSettings_LOW_LATENCY_CBS_BY_API_MASK = "1",
	ClientSettings_LOW_LATENCY_CBS_BY_GPU_CATEGORY = "1",
	ClientSettings_LowLatency = "1",
	ClientSettings_LowVramActions = "1",
	ClientSettings_MemoryAllocationTraces = "16",
	ClientSettings_MSAA = "1",
	ClientSettings_NeedsGxRestart = "1",
	ClientSettings_OPT_FEATURES_BY_API_MASK = "1",
	ClientSettings_OPT_FEATURES_BY_GPU_CATEGORY = "1",
	ClientSettings_RAY_TRACING_BY_API_MASK = "1",
	ClientSettings_RAY_TRACING_BY_GPU_CATEGORY = "1",
	ClientSettings_RGB10A2_API = "1",
	ClientSettings_RGB10A2_CAT = "1",
	ClientSettings_RTShadows = "1",
	ClientSettings_SHADER_MT_BY_API_MASK = "1",
	ClientSettings_SHADER_MT_BY_GPU_CATEGORY = "1",
	ClientSettings_SM6_BY_API_MASK = "1",
	ClientSettings_SM6_BY_GPU_CATEGORY = "1",
	ClientSettings_SpellClutter = "1",
	ClientSettings_VolumeFog = "1",
	ClientSettings_WORK_OPTIMS_BY_API_MASK = "1",
	ClientSettings_WORK_OPTIMS_BY_GPU_CATEGORY = "1",
	ClipCursor = "11|t", -- ui
	cloakFixEnabled = "14|t", -- name
	closedExtraAbiltyTutorials = "17",
	closedInfoFrames = "17",
	closedInfoFramesAccountWide = "17",
	closedRemixArtifactTutorialFrames = "17",
	clubFinderCacheExpiry = "17",
	clubFinderCachePendingExpiry = "17",
	clubFinderPlayerLanguageSettings = "6",
	clubFinderPlayerSettings = "6",
	clusteredShading = "1|t", -- help
	CMAA2ExtraSharpness = "1",
	CMAA2HalfFloat = "1|c|0=N32_BIT_FLOAT|1=N16_BIT_FLOAT", -- help
	CMAA2Quality = "1",
	collapsedCurrencyCategoryDefaults = "17",
	collapsedReputationHeaderDefaults = "17",
	collapseExpandBuffs = "8|t", -- help
	Collision = "16",
	colorblindMode = "13|t", -- ui
	colorblindSimulator = "13|c|0=NONE|1=PROTANOPIA|2=DEUTERANOPIA|3=TRITANOPIA", -- ui
	colorblindWeaknessFactor = "13|s|0|1|0.05", -- ui
	colorChatNamesByClass = "6|t", -- help
	combatLogRetentionTime = "14",
	combatLogUniqueFilename = "16",
	combatWarningsEnabled = "14|t", -- ui
	combinedBags = "14|t", -- ui
	comboPointLocation = "8|c|1=TARGET|2=SELF", -- help
	commentatorLossOfControlIconUnitFrame = "8|t", -- help
	commentatorLossOfControlTextNameplate = "4|t", -- help
	commentatorLossOfControlTextUnitFrame = "8|t", -- help
	communitiesShowOffline = "6|t", -- name
	componentCompress = "1",
	componentEmissive = "1",
	componentSpecular = "1",
	componentTexCacheSize = "1",
	componentTexLoadLimit = "1",
	componentTextureLevel = "1",
	componentThread = "1",
	ConsoleKey = "16",
	consoleShowDebugMessages = "16|t", -- help
	consoleShowSpamMessages = "16|t", -- help
	contentTrackingFilter = "14|t", -- help
	ContentTuning = "16",
	Contrast = "1|s|0|100|1", -- ui
	cooldownViewerEnabled = "9|t", -- ui
	cooldownViewerShowUnlearned = "9|t", -- help
	coordsByTenths = "14|t", -- ui
	countdownForCooldowns = "9|t", -- ui
	covenantMissionTutorial = "17",
	craftingOrdersOnlyPreferredArmorCollectable = "14|t", -- help
	currencyCategoriesCollapsed = "17",
	currentGameMode = "17",
	CursorCenteredYPos = "11|s|0|1|0.05", -- help
	CursorFreelookCentering = "11",
	CursorFreelookStartDelta = "11",
	cursorSizePreferred = "13|c|-1=DEFAULT|0=N32X32|1=N48X48|2=N64X64|3=N96X96|4=N128X128", -- ui
	CursorStickyCentering = "11",
	CustomDesignEventLog = "16",
	CustomWindowEventLog = "16",
	daltonize = "13",
	DamageCalculator = "16",
	damageMeterEnabled = "14|t", -- ui
	damageMeterResetOnNewInstance = "14|t", -- ui
	dangerousShipyardMissionWarningAlreadyShown = "17",
	DebugTorsoTwist = "16",
	deemphasizeOffspecPrimaryStats = "14",
	defaultReputationSortType = "14",
	DeprecatedWarningThrottle = "16",
	DepthBasedOpacity = "1",
	deselectOnClick = "10|t", -- ui
	developerLog = "16|t", -- help
	developerLogFilterDebug = "16|t", -- help
	developerLogFilterError = "16|t", -- help
	developerLogFilterFatal = "16|t", -- help
	developerLogFilterNormal = "16|t", -- help
	developerLogFilterSpam = "16|t", -- help
	developerLogFilterWarning = "16|t", -- help
	developerLogWriteToFile = "16|t", -- help
	digSites = "14|t", -- help
	DisableAdvancedFlyingFullScreenEffects = "1|t", -- name
	DisableAdvancedFlyingVelocityVFX = "1|t", -- name
	disableAELooting = "10|t", -- name
	disableAutoRealmSelect = "15|t", -- name
	disableHorizonStart = "1|t", -- name
	disableServerNagle = "15|t", -- ui
	disableSuggestedLevelActivityFilter = "14|t", -- help
	disableUILoadErrorDialog = "16|t", -- name
	disableUserAddonsByDefault = "14|t", -- help
	discordClientEnabled = "6|t", -- help
	discordDisplayName = "6|c|0=DEFAULT|1=LAST_ONLINE|2=GLOBAL_NAME", -- ui
	displayFreeBagSlots = "14|t", -- ui
	displaySpellActivationOverlays = "9|t", -- help
	displayTemporaryEnchantIcon = "14|t", -- help
	displayWorldPVPObjectives = "14|t", -- help
	dnMTUpdate = "1",
	doNotFlashLowHealthWarning = "14|t", -- ui
	doNotShowTWFraudWarning = "14|t", -- help
	dontShowEquipmentSetsOnItems = "14|t", -- help
	doodadLodScale = "1",
	dragonRidingRacesFilter = "14|t", -- help
	dragonRidingRacesFilterWQ = "14|t", -- help
	DriveDynamicFOVEnabled = "3|t", -- help
	DriverVersionCheck = "15|t", -- help
	DriveSwapReverseTurnDirection = "11|t", -- help
	dynamicLod = "1|t", -- probe
	DynamicRenderScale = "1",
	DynamicRenderScaleMin = "1",
	EJDungeonDifficulty = "17",
	EJLootClass = "17",
	EJLootSpec = "17",
	EJRaidDifficulty = "17",
	EJSelectedTier = "17",
	EmitterCombatRange = "1",
	emphasizeMySpellEffects = "1|t", -- help
	EmpowerMinHoldStagePercent = "9|s|0|1|0.05", -- help
	empowerTapControls = "9|c|0=PRESS_AND_HOLD|1=TAP", -- ui
	EmpowerTapControlsReleaseThreshold = "9",
	enableAssetTracking = "15|t", -- name
	enableBGDL = "15|t", -- name
	EnableBlinkApplicationIcon = "14|t", -- help
	enableCollectionToasts = "14|t", -- ui
	enableConnectToPhotoSharing = "6|t", -- ui
	enableFloatingCombatText = "7|t", -- ui
	enableLearnedRecipeToasts = "14|t", -- ui
	enableLootToasts = "14|t", -- ui
	enableMouseoverCast = "9|t", -- ui
	enableMouseSpeed = "11|t", -- ui
	enableMovePad = "13|t", -- ui
	enableMultiActionBars = "9",
	enablePetBattleFloatingCombatText_v2 = "7|t", -- help
	enablePings = "14|t", -- ui
	enablePVPNotifyAFK = "14|t", -- help
	enableQuestCacheLogging = "16|t", -- help
	enableRuneSpentAnim = "14",
	enableSourceLocationLookup = "16|t", -- name
	enableWowMouse = "11|t", -- help
	encounterTimelineEnabled = "14",
	encounterTimelineHideForOtherRoles = "14",
	encounterTimelineHideLongCountdowns = "14",
	encounterTimelineHideQueuedCountdowns = "14",
	encounterTimelineHighlightDuration = "14",
	encounterTimelineIconographyEnabled = "14",
	encounterTimelineIconographyHiddenMask = "14",
	encounterTimelineShowSequenceCount = "14|t", -- help
	encounterWarningsDefaultMessageDuration = "14",
	encounterWarningsEnabled = "14|t", -- ui
	encounterWarningsHideIfNotTargetingPlayer = "14|t", -- ui
	encounterWarningsLevel = "14|c|0=MINOR|1=MEDIUM|2=CRITICAL", -- ui
	endeavorInitiativesLastPointsMap = "17",
	engineSurvey = "17",
	engineSurveyPatch = "17",
	entityLodDist = "1",
	entityLodOffset = "1",
	entityShadowFadeScale = "1",
	equipmentManager = "14|t", -- help
	ErrorFilter = "16",
	ErrorLevelMax = "16",
	ErrorLevelMin = "16",
	Errors = "16",
	eventReminders = "17",
	eventSchedulerLastUpdate = "17",
	excludedCensorSources = "6|c|0=CENSOR_EVERYONE|1=EVERYONE_EXCEPT_FRIENDS|3=EVERYONE_EXCEPT_FRIENDS_AND_GUILDMATES|255=CENSOR_NO_ONE", -- ui
	ExclusiveWindowMode = "13",
	expandBagBar = "14|t", -- code
	expandUpgradePanel = "14|t", -- help
	expandWarbandCharacterList = "17",
	externalDefensivesEnabled = "8|t", -- ui
	farclip = "1",
	ffxAntiAliasingMode = "1|c|0=NONE|1=FXAA_LOW|2=FXAA_HIGH|3=CMAA|4=CMAA2", -- ui
	ffxDeath = "1",
	ffxGlow = "1",
	ffxLingeringVenari = "1",
	ffxNether = "1",
	ffxVenari = "1",
	findYourselfAnywhere = "13|t", -- code
	findYourselfAnywhereOnlyInCombat = "13",
	findYourselfInBG = "13",
	findYourselfInBGOnlyInCombat = "13",
	findYourselfInRaid = "13",
	findYourselfInRaidOnlyInCombat = "13",
	findYourselfMode = "13|c|0=CIRCLE|1=CIRCLE_AND_OUTLINE|2=OUTLINE", -- help
	findYourselfModeCircle = "13|t", -- code
	findYourselfModeIcon = "13|t", -- code
	findYourselfModeOutline = "13|t", -- code
	flaggedTutorials = "17",
	flashErrorMessageRepeats = "14|t", -- code
	flightAngleLookAhead = "3|t", -- help
	floatingCombatTextAuraFade_v2 = "7",
	floatingCombatTextAuras_v2 = "7|t", -- ui
	floatingCombatTextCombatDamage_v2 = "7|t", -- ui
	floatingCombatTextCombatDamageAllAutos_v2 = "7|t", -- help
	floatingCombatTextCombatDamageDirectionalOffset_v2 = "7",
	floatingCombatTextCombatDamageDirectionalScale_v2 = "7",
	floatingCombatTextCombatHealing_v2 = "7|t", -- ui
	floatingCombatTextCombatHealingAbsorbSelf_v2 = "7|t", -- ui
	floatingCombatTextCombatHealingAbsorbTarget_v2 = "7|t", -- ui
	floatingCombatTextCombatLogPeriodicSpells_v2 = "7|t", -- ui
	floatingCombatTextCombatState_v2 = "7|t", -- ui
	floatingCombatTextComboPoints_v2 = "7|t", -- ui
	floatingCombatTextDamageReduction_v2 = "7|t", -- ui
	floatingCombatTextDodgeParryMiss_v2 = "7|t", -- ui
	floatingCombatTextEnergyGains_v2 = "7|t", -- ui
	floatingCombatTextFloatMode_v2 = "7|c|1=SCROLL_UP|2=SCROLL_DOWN|3=SCROLL_ARC", -- ui
	floatingCombatTextFriendlyHealers_v2 = "7|t", -- ui
	floatingCombatTextHonorGains_v2 = "7|t", -- ui
	floatingCombatTextLowManaHealth_v2 = "7|t", -- ui
	floatingCombatTextPeriodicEnergyGains_v2 = "7|t", -- ui
	floatingCombatTextPetMeleeDamage_v2 = "7|t", -- help
	floatingCombatTextPetSpellDamage_v2 = "7|t", -- help
	floatingCombatTextReactives_v2 = "7|t", -- ui
	floatingCombatTextRepChanges_v2 = "7|t", -- ui
	floatingCombatTextSpellMechanics_v2 = "7|t", -- help
	floatingCombatTextSpellMechanicsOther_v2 = "7|t", -- help
	FootstepSounds = "5",
	forceClusteredShading = "1",
	forceEnglishNames = "15",
	ForceGenerateSlug = "16",
	forceLODCheck = "1|t", -- help
	ForceResolutionDefaultToMaxSize = "1",
	FrameBufferCacheForceNoHeaps = "1|t", -- help
	frameScriptFunctionInheritanceWarningMode = "16|t", -- help
	friendInvitesCollapsed = "6|t", -- help
	fstack_enabled = "16|t", -- help
	fstack_preferParentKeys = "16|t", -- help
	fstack_showanchors = "16|t", -- help
	fstack_showhidden = "16|t", -- help
	fstack_showhighlight = "16|t", -- help
	fstack_showRaisedFrameLevels = "16|t", -- help
	fstack_showregions = "16|t", -- help
	GameDataVisualizer = "16",
	GamePadAnalogMovement = "12|t", -- help
	GamePadBackend = "12|c|0=DEFAULT|1=SDL|2=PADDLE", -- help
	GamePadBackPedalThreshold = "12|s|0|1|0.05", -- ui
	GamepadCameraFollowOnStick = "12|t", -- ui
	GamepadCameraFollowPitchOffset = "12|s|0|45|1", -- ui
	GamePadCameraLookMaxPitch = "12",
	GamePadCameraLookMaxYaw = "12",
	GamePadCameraPitchSpeed = "12|s|0.5|5|0.1", -- ui
	GamepadCameraSavedDistance = "17",
	GamepadCameraSavedPetBattleDistance = "17",
	GamepadCameraSavedPitch = "17",
	GamepadCameraSavedVehicleDistance = "17",
	GamePadCameraYawSpeed = "12|s|0.5|5|0.1", -- ui
	GamepadCompassCustomFilterBoss = "12",
	GamepadCompassCustomFilterCritter = "12",
	GamepadCompassCustomFilterEnemy = "12",
	GamepadCompassCustomFilterFriendly = "12",
	GamepadCompassCustomFilterParty = "12",
	GamepadConstrainedGroundTargetDistanceYds = "12",
	GamepadConstrainedGroundTargetEnabled = "12|t", -- help
	GamepadConstrainedGroundTargetMaxRange = "12",
	GamePadCursorAutoDisableJump = "12",
	GamePadCursorAutoDisableSticks = "12|c|0=NONE|1=MOVEMENT|2=MOVEMENT_AND_CURSOR", -- help
	GamePadCursorAutoEnable = "12",
	GamePadCursorCenteredEmulation = "12",
	GamePadCursorCentering = "12",
	GamePadCursorForTargeting = "12",
	GamePadCursorLeftClick = "12",
	GamePadCursorOnLogin = "12|t", -- help
	GamePadCursorPushCamera = "12",
	GamePadCursorRightClick = "12",
	GamePadCursorSpeedAccel = "12",
	GamePadCursorSpeedMax = "12",
	GamePadCursorSpeedStart = "12",
	GamePadEmulateAlt = "12",
	GamePadEmulateCtrl = "12",
	GamePadEmulateShift = "12",
	GamePadEmulateTapWindowMs = "12",
	GamePadEnable = "12|t", -- help
	GamepadEnableReticleSwingTimer = "12|t", -- help
	GamePadFaceMovementFreeFlying = "12|t", -- ui
	GamePadFaceMovementMaxAngle = "12|s|0|180|1", -- ui
	GamePadFaceMovementMaxAngleCombat = "12|s|0|180|1", -- ui
	GamePadFaceMovementMount = "12|t", -- ui
	GamePadFaceMovementSwimming = "12|t", -- ui
	GamePadFactionColor = "12|t", -- help
	GamepadFocusStateColor = "12|c|1=GOLD|2=BLACK|3=BLUE", -- ui
	GamepadFocusStateOpacity = "12|s|0|1|0.1", -- ui
	GamepadHudModifierUsesToggle = "12|t", -- ui
	gamepadInvertPitch = "12|t", -- ui
	gamepadInvertYaw = "12|t", -- ui
	GamepadMapEdgePanDistance = "12",
	GamepadMapScrollSpeed = "12",
	GamepadMapScrollSpeedFullScreen = "12",
	GamepadMapZoomSpeed = "12",
	GamePadOverlapMouseMs = "12",
	GamepadPossessBarOverride = "12|c|1=POSSESS_BAR_SPECIAL_PAGE|2=PAGE_1_LEFT|3=PAGE_1_RIGHT|4=PAGE_1_BOTTOM|5=PAGE_2_TOP|6=PAGE_2_LEFT|7=PAGE_2_RIGHT|8=PAGE_2_BOTTOM|9=PAGE_3_TOP|10=PAGE_3_LEFT|11=PAGE_3_RIGHT|12=PAGE_3_BOTTOM", -- ui
	GamepadPreferScreenTargeting = "12|t", -- help
	GamepadRaidTargetingHoverMode = "12|t", -- ui
	GamepadRaidTargetingStyle = "12",
	GamePadRunThreshold = "12|s|0|1|0.1", -- ui
	GamepadShowAutoAuraTooltip = "12|t", -- help
	GamepadShowPersistentInputLegend = "12|t", -- ui
	GamePadSingleActiveID = "12",
	GamepadStanceBarOverride = "12|c|1=NONE|2=PAGE_1_LEFT|3=PAGE_1_RIGHT|4=PAGE_1_BOTTOM|5=PAGE_2_TOP|6=PAGE_2_LEFT|7=PAGE_2_RIGHT|8=PAGE_2_BOTTOM|9=PAGE_3_TOP|10=PAGE_3_LEFT|11=PAGE_3_RIGHT|12=PAGE_3_BOTTOM", -- ui
	GamePadStickAxisButtons = "12|t", -- help
	GamepadSwapFriendlyTargetActions = "12|t", -- ui
	GamepadSwapHostileTargetActions = "12|t", -- ui
	GamepadSwapTargetModifiers = "12|t", -- ui
	GamepadTabFriendlyTargetAction = "12|t", -- code
	GamepadTabHostileTargetAction = "12|t", -- code
	GamePadTankTurnSpeed = "12",
	GamepadTargetingAnalogDeadzone = "12|s|0|1|0.05", -- help
	GamepadTargetingAnalogPullbackThreshold = "12|s|0|1|0.05", -- help
	GamepadTargetingModifierVisualDelay = "12",
	GamePadTouchCursorAccel = "12",
	GamePadTouchCursorEnable = "12|c|0=DISABLED|1=ENABLED|2=ENABLED_IN_MOUSE_AND_KEYBOARD_UI_ONLY", -- help
	GamePadTouchCursorMoveThreshold = "12",
	GamePadTouchCursorSpeed = "12",
	GamePadTouchTapButtons = "12|t", -- help
	GamePadTouchTapMaxMs = "12",
	GamePadTouchTapOnlyClick = "12",
	GamePadTouchTapRightClick = "12",
	GamePadTurnWithCamera = "12|c|0=MOVING|1=MOVING_AND_IN_COMBAT|3=MOVING_IN_COMBAT_OR_CASTING|2=ALWAYS", -- ui
	GamepadUsePartyTargeting = "12|t", -- ui
	GamePadVibrationStrength = "12",
	GameplayContext = "17",
	gameTip = "17",
	Gamma = "1|s|0.3|2.8|0.1", -- ui
	garrisonCompleteTalent = "17",
	garrisonCompleteTalentType = "17",
	giQuality = "1",
	graphicsComputeEffects = "1|c|0=LOW|1=FAIR|2=MEDIUM|3=HIGH|4=ULTRA", -- ui
	graphicsDepthEffects = "1|c|0=DISABLED|1=LOW|2=MEDIUM|3=HIGH", -- ui
	graphicsEnvironmentDetail = "1|s|0|9|1", -- ui
	graphicsGroundClutter = "1|s|0|9|1", -- ui
	graphicsLightMode = "1|c|0=FAIR|1=MEDIUM|2=HIGH|3=ULTRA", -- ui
	graphicsLiquidDetail = "1|c|0=LOW|1=FAIR|2=MEDIUM|3=HIGH", -- ui
	graphicsOutlineMode = "1|c|0=DISABLED|1=MEDIUM|2=HIGH", -- ui
	graphicsParticleDensity = "1",
	graphicsPBRLiquidDetail = "1|c|0=LOW|1=HIGH|2=ULTRA", -- ui
	graphicsProjectedTextures = "1|t", -- ui
	graphicsQuality = "1|s|0|9|1", -- ui
	graphicsShadowQuality = "1|c|0=LOW|1=FAIR|2=MEDIUM|3=HIGH|4=ULTRA|5=ULTRA_HIGH", -- ui
	graphicsSpellDensity = "1|c|0=MINIMUM|1=REDUCED|2=FULL", -- ui
	graphicsSSAO = "1|c|0=DISABLED|1=LOW|2=MEDIUM|3=HIGH|4=ULTRA", -- ui
	graphicsTextureResolution = "1|c|0=LOW|1=FAIR|2=HIGH", -- ui
	graphicsViewDistance = "1|s|0|9|1", -- ui
	groundEffectDensity = "1",
	groundEffectDist = "1",
	groundEffectFade = "1",
	guildMemberNotify = "6|t", -- ui
	guildNewsFilter = "17|f|-1=GUILD_ACHIEVEMENTS|-2=MEMBERS_ACHIEVEMENTS|-3=RAID_ENCOUNTERS|-4=EPIC_ITEMS_LOOTED|-5=EPIC_ITEMS_CRAFTED|-6=EPIC_ITEMS_PURCHASED|-9=LEGENDARY_ITEMS_LOOTED", -- probe: set in game a flag at a time through SetGuildNewsFilter, filters 1, 2 and 9 were flags 1, 2 and 9 of a number, each on while its filter is off; the labels and the seven filters are the game's
	guildRewardsCategory = "6",
	guildRewardsUsable = "6|t", -- help
	guildShowOffline = "6|t", -- help
	GxAdapter = "1|gx", -- restart: ui
	GxAFRDevicesCount = "1",
	GxAllowCachelessShaderMode = "1|t", -- help
	GxApi = "1|gx", -- restart: ui
	GxCompatAllowSM6 = "1|t", -- help
	GxCompatAsyncComputeQueue = "1|t", -- help
	GxCompatAsyncShaderCompilation = "1|t|gx", -- ui, restart: ui
	GxCompatCommandListMultiThreading = "1|t|gx", -- ui, restart: ui
	GxCompatCopyQueue = "1|t", -- help
	GxCompatLowLatencyCallbacks = "1|t", -- help
	GxCompatOptionalGpuFeatures = "1|t|gx", -- ui, restart: ui
	GxCompatWorkSubmitOptimizations = "1|t|gx", -- ui, restart: ui
	GxDebugBreakLevel = "16|c|0=NONE|1=ERROR|2=WARNING|3=INFO", -- help
	GxDebugLevel = "16",
	GxFullscreenResolution = "1|window", -- restart: ui
	GxMaxFrameLatency = "1|c|2=TRIPLE_BUFFERING_OFF|3=TRIPLE_BUFFERING_ON|gx", -- ui, restart: ui
	GxMaximize = "1|c|1=WINDOWED_FULLSCREEN|0=WINDOWED|window", -- ui, restart: ui
	GxMonitor = "1|window", -- restart: ui
	gxMTAlphaM2 = "1",
	gxMTAlphaPass = "1",
	gxMTBeginDraw = "1",
	gxMTDecals = "1|t", -- help
	gxMTDisable = "1|t", -- help
	gxMTLightShafts = "1",
	gxMTMisc = "1",
	gxMTOpaqueM2 = "1",
	gxMTOpaqueM2NoReflect = "1",
	gxMTOpaqueWMO = "1",
	gxMTOutlines = "1",
	gxMTPrepass = "1",
	gxMTRefraction = "1",
	gxMTShadow = "1",
	gxMTTerrain = "1",
	gxMTTriggerOnBeginDrawComplete = "1|t", -- help
	gxMTVolFog = "1",
	GxNewResolution = "1",
	GxPrismEnabled = "1|c|0=DISABLED|1=DEFAULT_BACKENDS|2=EXPERIMENTAL_BACKENDS", -- help
	GxSlowShaderWarnThreshold = "15",
	GxWindowedResolution = "1|window", -- restart: ui
	hardcoreDeathAlertType = "14",
	hardcoreDeathChatType = "6",
	hardTrackedQuests = "17",
	hardTrackedWorldQuests = "17",
	HardwareCursor = "11|t", -- help
	hasSelectedExperiencePreset = "17",
	HDRBrightness = "1",
	HDRFactor = "1",
	HDROutput = "1",
	HDRPeakBrightness = "1",
	HealHandler = "16",
	heirloomCollectedFilters = "17|f|-1=COLLECTED|-2=NOT_COLLECTED", -- probe: set in game a flag at a time through C_Heirloom.SetCollectedHeirloomFilter and SetUncollectedHeirloomFilter, flags 1 and 2, each on while its filter is off; the labels are the game's
	heirloomSourceFilters = "17|f|-1=DROP|-2=QUEST|-3=VENDOR|-4=PROFESSION|-5=PET_BATTLE|-6=ACHIEVEMENT|-7=WORLD_EVENT|-8=PROMOTION|-9=TRADING_CARD_GAME|-10=IN_GAME_SHOP|-11=DISCOVERY|-12=TRADING_POST", -- probe: set in game a flag at a time through C_Heirloom.SetHeirloomSourceFilter, sources 1 and 3 were flags 1 and 3, each on while its filter is off; the labels are the game's
	hideFastLoginLoadingScreen = "14|t", -- name
	hideRewardedEvents = "14|t", -- name
	highestUnlockedTieredEntranceTier = "17",
	horizonClip = "1",
	horizonStart = "1",
	HotfixEventLog = "16",
	hotReloadModels = "16|t", -- help
	houseExterior_Hide_Decor = "14|t", -- help
	housingDecorFreePlaceEnabled = "14|t", -- help
	housingDecorGridSnapEnabled = "14|t", -- help
	housingDecorGridVisible = "14|t", -- help
	housingDecorLightRadiusIndicatorsEnabled = "14|t", -- ui
	housingExpertGizmos_Scale_FrameOffset = "14",
	housingExpertGizmos_Scale_Snap = "14",
	housingExpertGizmos_SnapOnHold = "14|t", -- help
	housingLayout_Camera_DefaultDistance = "14",
	housingLayout_Camera_DragFriction = "14",
	housingLayout_Camera_DragMomentum = "14",
	housingLayout_Camera_MaxDistance = "14",
	housingLayout_Camera_MaxDistanceIncr = "14",
	housingLayout_Camera_MinDistance = "14",
	housingLayout_Camera_Smoothness = "14",
	housingLayout_Camera_Speed = "14",
	housingOtherDecorLightRadiusIndicatorType = "14|c|0=ALWAYS|1=WHEN_OVERLAPPING|2=NEVER", -- ui
	housingSelectedDecorLightRadiusIndicatorType = "14|c|0=ALWAYS|1=WHEN_OVERLAPPING|2=NEVER", -- ui
	housingStoragePanelCollapsed = "17",
	housingStoragePanelHeight = "17",
	housingStoragePanelWidth = "17",
	housingTutorialsEnabled = "14|t", -- help
	hwDetect = "15",
	imageSharingPublishCooldown = "14",
	ImpactModelCollisionMelee = "1|t", -- help
	ImpactModelCollisionMissile = "1|t", -- help
	ImpactModelCollisionRanged = "1|t", -- help
	incompleteQuestPriorityThresholdDelta = "14",
	initialRealmListTimeout = "15",
	InputDeviceInterfaceStyle = "14|t", -- probe
	instantQuestText = "14|t", -- ui
	interactKeyWarningTutorial = "17",
	interactOnLeftClick = "10|t", -- ui
	interactQuestItems = "10|t", -- help
	InvalidateDeactivatedHandles = "16|t", -- help
	KioskCanAutoDeleteCharacters = "16|t", -- help
	KioskCanSessionExpire = "16|t", -- help
	KioskCharacterTemplateSet1 = "16",
	KioskCharacterTemplateSet2 = "16",
	KioskLobbyKickSeconds = "16",
	KioskWarmupSeconds = "16",
	lastAddonVersion = "17",
	lastAttemptedExternalEventURLHash = "17",
	lastCharacterIndex = "17",
	lastGarrisonMissionTutorial = "17",
	lastLockedTieredEntranceCompanionAbilities = "17",
	lastRenownForCovenant1 = "17",
	lastRenownForCovenant2 = "17",
	lastRenownForCovenant3 = "17",
	lastRenownForCovenant4 = "17",
	lastRenownForDelvesSeason = "17",
	lastSelectedClubId = "17",
	lastSelectedTieredEntranceTier = "17",
	lastTalkedToGM = "17",
	lastTransmogCustomSetIDNoSpec = "17",
	lastTransmogCustomSetIDSpec1 = "17",
	lastTransmogCustomSetIDSpec2 = "17",
	lastTransmogCustomSetIDSpec3 = "17",
	lastTransmogCustomSetIDSpec4 = "17",
	lastTransmogOutfitIDNoSpec = "17",
	latestSplashScreen = "17",
	latestTransmogSetSource = "17",
	launchAgent = "15|t", -- help
	lfdCollapsedHeaders = "17",
	lfdSelectedDungeons = "17",
	lfgListAdvancedFilterMinRating = "17",
	lfgListAdvancedFilterRemovedActivities = "17",
	lfgListAdvancedFilters = "17|f|1=TANK_ROLE_AVAILABLE|2=HEALER_ROLE_AVAILABLE|3=DAMAGE_ROLE_AVAILABLE|4=NO_ONE_OF_MY_CLASS|5=HAS_A_TANK|6=HAS_A_HEALER|7=NORMAL|8=HEROIC|9=MYTHIC|10=MYTHIC_PLUS|11=LEARNING|12=RELAXED|13=COMPETITIVE|14=CARRY_OFFERED", -- probe: set in game a field at a time through C_LFGList.SaveAdvancedFilter, flags 1, 2, 4, 6, 7, 10, 11 and 14 were its table's true or false fields in their order; the labels are the game's
	lfgListAdvancedFiltersVersion = "17",
	lfgListSearchLanguages = "17",
	lfgSelectedRoles = "17|f|1=LEADER|2=TANK|3=HEALER|4=DAMAGE", -- probe: set in game a role at a time through SetLFGRoles, leader was 1, tank 2 and damage 8; the game didn't take healer for a warrior, and it's 4 by the pattern
	linear = "1|t", -- help
	loadDeprecationFallbacks = "16|t", -- help
	locale = "15",
	locateViewerMaxJobs = "15",
	lockActionBars = "9|t", -- ui
	lodObjectCullDist = "1|s|1|200|1", -- probe
	lodObjectCullSize = "1",
	lodObjectFadeScale = "1",
	lodObjectMinSize = "1|s|0|1000|1", -- probe
	lodObjectSizeScale = "1",
	lootUnderMouse = "10|t", -- ui
	lossOfControl = "14|t", -- ui
	lossOfControlDisarm = "14",
	lossOfControlFull = "14",
	lossOfControlInterrupt = "14",
	lossOfControlRoot = "14",
	lossOfControlSilence = "14",
	LowLatencyMinInterval = "1",
	LowLatencyMode = "1|c|0=AUTO_DETECT|1=DISABLED|2=BUILT_IN|3=NVIDIA_REFLEX|4=NVIDIA_REFLEX_PLUS_BOOST|5=INTEL_XELL", -- ui
	luaErrorExceptions = "16|t", -- help
	M2ForceAdditiveParticleSort = "1",
	M2UseInstancing = "1|t", -- help
	M2UseThreads = "1|t", -- name
	MacDisableOsShortcuts = "11|t", -- ui
	MacUseCommandLeftClickAsRightClick = "11|t", -- ui
	MacWindowToggleHotkey = "11|t", -- help
	majorFactionRenownMap = "17",
	mapFade = "14|t", -- help
	MaxCharacterComponentLoadStartsPerFrame = "15|s|1|8|1", -- help
	maxFPS = "1|s|8|200|1", -- ui
	maxFPSBk = "1|s|8|200|1", -- ui
	maxFPSLoading = "1",
	maximumConnectionAttempts = "15",
	maxLevelSpecsUsed = "17",
	maxLightCount = "1",
	maxLightDist = "1",
	MaxObservedPetBattles = "14",
	minFontHeight = "13",
	miniCommunitiesFrame = "17",
	miniDressUpFrame = "17",
	minimapInsideZoom = "17",
	minimapPortalMax = "14",
	minimapShapeshiftTracking = "17",
	minimapShowPlayerCoords = "14|t", -- ui
	minimapTrackedInfov4 = "17",
	minimapTrackingClosestOnly = "14|t", -- help
	minimapTrackingShowAll = "14|t", -- help
	minimapZoom = "17",
	miniWorldMap = "17",
	missingTransmogSourceInItemTooltips = "14|t", -- help
	motionSicknessFocalCircle = "13|t", -- help
	motionSicknessLandscapeDarkening = "13|t", -- help
	mountJournalGeneralFilters = "17|f|1=COLLECTED|2=NOT_COLLECTED|3=UNUSABLE", -- probe: set in game a flag at a time through C_MountJournal.SetCollectedFilterSetting, filters 1, 2 and 3 were the bits of a number, each on while its filter is; the labels are the game's
	mountJournalShowPlayer = "14|t", -- help
	mountJournalSourcesFilter = "17|f|3=VENDOR|9=TRADING_CARD_GAME", -- probe: set in game a flag at a time through C_MountJournal.SetSourceFilter, sources 3 and 9 were bits 3 and 9 of a number, each on while its filter is; the only two C_MountJournal.IsValidSourceFilter takes in 1.60.1, and the labels are the game's
	mountJournalTypeFilter = "17|f|1=GROUND|2=FLYING|3=AQUATIC|5=RIDE_ALONG", -- probe: set in game a flag at a time through C_MountJournal.SetTypeFilter, types 1 and 5 were bits 1 and 5 of a number, each on while its filter is; type 4 is the one C_MountJournal.IsValidTypeFilter turns down in 1.60.1, and the labels are the game's
	mouseAcceleration = "11",
	MouseHiddenInRelativeMode = "11|t", -- help
	mouseInvertPitch = "11|t", -- ui
	mouseInvertYaw = "11",
	mouseSpeed = "11|s|0.5|1.4|0.05", -- ui
	MoveHistoryEventLog = "16",
	movePadInPressAndHoldMode = "11|t", -- help
	movePadLocked = "11|t", -- help
	movieSubtitle = "13|t", -- ui
	movieSubtitleBackground = "13|c|1=NONE|2=DARK|3=LIGHT", -- ui
	movieSubtitleBackgroundAlpha = "13|s|50|100|10", -- ui
	MSAAAlphaTest = "1|t", -- ui
	MSAAQuality = "1",
	nameplateAuraScale = "4|s|0.7|1.4|0.1", -- ui
	nameplateBottomInset = "4",
	nameplateCastBarDisplay = "4|f|1=SPELL_NAME|2=SPELL_ICON|3=SPELL_TARGET|4=HIGHLIGHT_IMPORTANT_CASTS|5=HIGHLIGHT_CASTS_AT_YOU", -- ui
	nameplateCheckDistanceForTarget = "4|t", -- help
	nameplateDebuffPadding = "4|s|0|50|1", -- ui
	nameplateEnemyNpcAuraDisplay = "4|f|1=BUFFS|2=DEBUFFS|3=CROWD_CONTROL", -- ui
	nameplateEnemyPlayerAuraDisplay = "4|f|1=BUFFS|2=DEBUFFS|3=LOSS_OF_CONTROL", -- ui
	nameplateForceShowUnitName = "4|t", -- help
	nameplateFriendlyPlayerAuraDisplay = "4|f|1=BUFFS|2=DEBUFFS|3=LOSS_OF_CONTROL", -- ui
	nameplateGameObjectMaxDistance = "4",
	nameplateInfoDisplay = "4|f|1=HEALTH_PERCENT|2=HEALTH_VALUE|3=RARITY_ICON", -- ui
	nameplateMaxAlpha = "4",
	nameplateMaxAlphaDistance = "4",
	nameplateMaxDistance = "4",
	nameplateMaxScale = "4",
	nameplateMaxScaleDistance = "4",
	nameplateMinAlpha = "4",
	nameplateMinAlphaDistance = "4",
	nameplateMinScale = "4",
	nameplateMinScaleDistance = "4",
	nameplateMotionSpeed = "4",
	nameplateNotSelectedAlpha = "4",
	nameplateOccludedAlphaMult = "4",
	nameplateOtherAtBase = "4",
	nameplateOverlapH = "4",
	nameplateOverlapV = "4",
	nameplatePlayerMaxDistance = "4",
	nameplatePlayRemovalAnimation = "4|t", -- help
	nameplateSelectedAlpha = "4",
	nameplateSelectedScale = "4",
	nameplateShowAll = "4|t", -- ui
	nameplateShowAllPersonalAuras = "4|t", -- help
	nameplateShowCastBars = "4",
	nameplateShowClassColor = "4|t", -- ui
	nameplateShowDebuffsOnFriendly = "4|t", -- help
	nameplateShowEnemies = "4|t", -- ui
	nameplateShowEnemyGuardians = "4|t", -- help
	nameplateShowEnemyMinions = "4|t", -- ui
	nameplateShowEnemyMinus = "4|t", -- ui
	nameplateShowEnemyPets = "4|t", -- help
	nameplateShowEnemyTotems = "4|t", -- help
	nameplateShowFriendlyClassColor = "4|t", -- name
	nameplateShowFriendlyNpcs = "4|t", -- ui
	nameplateShowFriendlyPlayerGuardians = "4|t", -- help
	nameplateShowFriendlyPlayerMinions = "4|t", -- ui
	nameplateShowFriendlyPlayerPets = "4|t", -- help
	nameplateShowFriendlyPlayers = "4|t", -- ui
	nameplateShowFriendlyPlayerTotems = "4|t", -- help
	nameplateShowFriendlyRealmName = "4|t", -- ui
	nameplateShowOffscreen = "4|t", -- ui
	nameplateShowOnlyNameForFriendlyPlayerUnits = "4|t", -- ui
	nameplateShowSelf = "4|t", -- ui
	nameplateSimplifiedScale = "4",
	nameplateSimplifiedTypes = "4|f|1=MINIONS|2=MINOR_ENEMIES|3=FRIENDLY_PLAYERS|4=FRIENDLY_NPCS", -- ui
	nameplateSize = "4|s|1|5|1", -- ui
	nameplateStackingTypes = "4|f|1=ENEMY_UNITS|2=FRIENDLY_UNITS", -- ui
	nameplateStyle = "4|c|1=THIN|0=MODERN|2=BLOCK|4=CAST_FOCUS", -- ui
	nameplateTargetBehindMaxDistance = "4",
	nameplateTargetRadialPosition = "4",
	nameplateThreatDisplay = "4|f|1=PROGRESSIVE|2=FLASH|3=HEALTH_BAR_COLOR", -- ui
	nameplateTopInset = "4",
	nameplateUseClassColorForFriendlyPlayerUnitNames = "4|t", -- ui
	nearclip = "1",
	newDelvesSeason = "17",
	newMythicPlusSeason = "17",
	newPvpSeason = "17",
	noBuffDebuffFilterOnTarget = "8|t", -- code
	NonEmitterCombatRange = "1",
	NotchedDisplayMode = "14|c|0=OVERLAP|1=SHIFT_UI|2=WINDOW_BELOW|window", -- ui, restart: ui
	notifiedOfNewMail = "17",
	numCurrencyCategories = "17",
	numReputationHeaders = "17",
	ObjectSelectionCircle = "1",
	occludedSilhouettePlayer = "1|t", -- ui
	occlusionMaxJobs = "15",
	onlyShowCollectedItemsInJournal = "14|t", -- code
	optOutIngameSurveys = "15|t", -- help
	orderHallMissionTutorial = "17",
	otherRolesAzeriteEssencesHidden = "14|t", -- help
	outdoorMinAltitudeDistance = "14",
	Outline = "1",
	OutlineEngineMode = "1",
	outlineModeShowLootEffectWhenDisabled = "1",
	outlineMouseOverFadeDuration = "1",
	outlineSelectionFadeDuration = "1",
	outlineSoftInteractFadeDuration = "1",
	overrideArchive = "15|t", -- help
	overrideScreenFlash = "13|t", -- ui
	particleDensity = "1",
	particleMTDensity = "1|s|0|100|1", -- probe
	particulatesEnabled = "1|t", -- help
	partyBackgroundOpacity = "8",
	partyInvitesCollapsed_Glue = "17",
	Pathing = "16",
	pathSmoothing = "16",
	pbrLiquidDetail = "1|s|0|2|1", -- probe
	pendingInviteInfoShown = "17",
	performedDeathTutorial = "17",
	performedVendorTutorial = "17",
	perksActivitiesCurrentMonth = "17",
	perksActivitiesLastPoints = "17",
	perksActivitiesPendingCompletion = "17",
	persistMoveLogOnTransfer = "16|t", -- help
	petJournalFilters = "17|f|-1=COLLECTED|-2=NOT_COLLECTED", -- probe: set in game a flag at a time through C_PetJournal.SetFilterChecked, flags 1 and 2, each on while its filter is off; the labels are the game's
	petJournalFilterVersion = "17",
	petJournalSort = "17|c|0=NAME|1=LEVEL|2=RARITY|3=PET_TYPE", -- probe: set in game through C_PetJournal.SetPetSortParameter, level was 1 and pet type 3: the game's four sorts counted from 0
	petJournalSourceFilters = "17|f|1=DROP|2=QUEST|3=VENDOR|4=PROFESSION|5=PET_BATTLE|6=ACHIEVEMENT|7=WORLD_EVENT|8=PROMOTION|9=TRADING_CARD_GAME|10=IN_GAME_SHOP|11=DISCOVERY|12=TRADING_POST", -- probe: set in game a flag at a time through C_PetJournal.SetPetSourceChecked, sources 1 and 12 were bits 1 and 12 of a number, each on while its filter is, and 0 with all twelve on; the labels are the game's
	petJournalTab = "17",
	petJournalTypeFilters = "17|f|1=HUMANOID|2=DRAGONKIN|3=FLYING|4=UNDEAD|5=CRITTER|6=MAGIC|7=ELEMENTAL|8=BEAST|9=AQUATIC|10=MECHANICAL", -- probe: set in game a flag at a time through C_PetJournal.SetPetTypeFilter, types 1 and 10 were bits 1 and 10 of a number, each on while its filter is, and 0 with all ten on; the labels are the game's
	petStableShowExoticOnly = "14|t", -- help
	petStableSort = "17",
	PhaseHistory = "16",
	physicsLevel = "1|c|0=NO_ENVIRONMENT_INTERACTION|1=PLAYER_ONLY_INTERACTION|2=PLAYER_AND_NPC_INTERACTION|client", -- ui, restart: ui
	pingCategoryTutorialShown = "17",
	pingMode = "14|c|0=KEY_DOWN|1=CLICK_AND_DRAG", -- ui
	pingTarget = "14|c|1=ENVIRONMENT|2=UNITS|0=ALL", -- ui
	playerColorOverrides = "14",
	PlayerInfoTempCache = "16",
	PlayerInfoTempCacheDebug = "16",
	PlayerSpawnTracking = "16",
	playIntroMovie = "14",
	plunderstormRealm = "17",
	POIShiftComplete = "16",
	portal = "15",
	PraiseTheSun = "16|t", -- code
	PreemptiveCastEnable = "9|t", -- help
	preloadLoadingDistObject = "15",
	preloadLoadingDistTerrain = "15",
	preloadPlayerModels = "15",
	preloadStreamingDistObject = "15",
	preloadStreamingDistTerrain = "15",
	PreventOsIdleSleep = "15|t", -- help
	primaryProfessionsFilter = "14|t", -- help
	ProcDebugEventLog = "16",
	profanityFilter = "6|t", -- ui
	professionAccessorySlotsExampleShown = "17",
	professionsAllocateBestQualityReagents = "14|t", -- help
	professionsAllocateBestQualityReagentsCustomer = "14|t", -- help
	professionsFlyoutHideUnowned = "14|t", -- help
	professionsOrderDurationDropdown = "17",
	professionsOrderRecipientDropdown = "17",
	professionToolSlotsExampleShown = "17",
	projectedTextures = "1",
	PushToTalkSound = "5",
	pvpFramesDisplayClassColor = "8|t", -- ui
	pvpFramesDisplayOnlyHealerPowerBars = "8|t", -- ui
	pvpFramesDisplayPowerBars = "8|t", -- ui
	pvpFramesHealthText = "8|c|none=NONE|health=HEALTH|losthealth=LOST_HEALTH|perc=PERCENTAGE", -- ui
	pvpOptionDisplayPets = "8|t", -- ui
	pvpSelectedRoles = "17|f|2=TANK|3=HEALER|4=DAMAGE", -- probe: set in game a role at a time through SetPVPRoles, tank was 2 and damage 8; the game didn't take healer for a warrior, and it's 4 by the pattern
	QuestEventLog = "16",
	questLogOpen = "14|t", -- help
	questPOI = "14|t", -- ui
	questPOILocalStory = "14|t", -- code
	questPOIWQ = "14|t", -- code
	questTextContrast = "13|c|0=DEFAULT|1=LIGHT_1|2=LIGHT_2|3=LIGHT_3|4=DARK", -- ui
	RAIDclusteredShading = "2|t", -- help
	RAIDcomponentTextureLevel = "2|c|0=FULL_DETAIL|1=REDUCED|2=LOWEST", -- as componentTextureLevel
	RAIDDepthBasedOpacity = "2|t", -- help
	RAIDdoodadLodScale = "2|s|50|150|5", -- as doodadLodScale
	RAIDentityLodDist = "2|s|5|10|1", -- as entityLodDist
	RAIDentityShadowFadeScale = "2|s|10|50|5", -- as entityShadowFadeScale
	RAIDfarclip = "2|s|1000|10000|100", -- as farclip
	raidFramesCenterBigDefensive = "8|t", -- ui
	raidFramesDispelIndicatorAnimatedBorder = "8|t", -- ui
	raidFramesDispelIndicatorOverlay = "8|c|0=DISABLED|1=DEBUFF_COLOR|2=BLACK", -- ui
	raidFramesDispelIndicatorOverlayAnimation = "8|t", -- ui
	raidFramesDispelIndicatorType = "8|c|0=DISABLED|1=ME|2=ALL", -- ui
	raidFramesDisplayAggroHighlight = "8|t", -- ui
	raidFramesDisplayBuffs = "8|t", -- help
	raidFramesDisplayClassColor = "8|t", -- ui
	raidFramesDisplayDebuffs = "8|t", -- ui
	raidFramesDisplayIncomingHeals = "8|t", -- ui
	raidFramesDisplayLargerRoleSpecificDebuffs = "8|t", -- ui
	raidFramesDisplayOnlyDispellableDebuffs = "8|t", -- ui
	raidFramesDisplayOnlyHealerPowerBars = "8|t", -- ui
	raidFramesDisplayPowerBars = "8|t", -- ui
	raidFramesHealthBarColor = "8|h", -- ui
	raidFramesHealthBarColorBG = "8|h", -- ui
	raidFramesHealthText = "8|c|none=NONE|health=HEALTH|losthealth=LOST_HEALTH|perc=PERCENTAGE", -- ui
	raidFramesHeight = "8",
	raidFramesPosition = "8",
	raidFramesWidth = "8",
	RAIDgiQuality = "2|s|1|4|1", -- as giQuality
	raidGraphicsComputeEffects = "2|c|0=LOW|1=FAIR|2=MEDIUM|3=HIGH|4=ULTRA", -- as graphicsComputeEffects
	raidGraphicsDepthEffects = "2|c|0=DISABLED|1=LOW|2=MEDIUM|3=HIGH", -- as graphicsDepthEffects
	raidGraphicsEnvironmentDetail = "2|s|0|9|1", -- as graphicsEnvironmentDetail
	raidGraphicsGroundClutter = "2|s|0|9|1", -- as graphicsGroundClutter
	raidGraphicsLightMode = "2|c|0=FAIR|1=MEDIUM|2=HIGH|3=ULTRA", -- as graphicsLightMode
	raidGraphicsLiquidDetail = "2|c|0=LOW|1=FAIR|2=MEDIUM|3=HIGH", -- as graphicsLiquidDetail
	raidGraphicsOutlineMode = "2|c|0=DISABLED|1=MEDIUM|2=HIGH", -- as graphicsOutlineMode
	raidGraphicsParticleDensity = "2",
	raidGraphicsPBRLiquidDetail = "2|c|0=LOW|1=HIGH|2=ULTRA", -- as graphicsPBRLiquidDetail
	raidGraphicsProjectedTextures = "2|t", -- as graphicsProjectedTextures
	RAIDgraphicsQuality = "2|s|0|9|1", -- as graphicsQuality
	raidGraphicsShadowQuality = "2|c|0=LOW|1=FAIR|2=MEDIUM|3=HIGH|4=ULTRA|5=ULTRA_HIGH", -- as graphicsShadowQuality
	raidGraphicsSpellDensity = "2|c|0=MINIMUM|1=REDUCED|2=FULL", -- as graphicsSpellDensity
	raidGraphicsSSAO = "2|c|0=DISABLED|1=LOW|2=MEDIUM|3=HIGH|4=ULTRA", -- as graphicsSSAO
	raidGraphicsTextureResolution = "2|c|0=LOW|1=FAIR|2=HIGH", -- as graphicsTextureResolution
	raidGraphicsViewDistance = "2|s|0|9|1", -- as graphicsViewDistance
	RAIDgroundEffectDensity = "2|s|16|256|8", -- as groundEffectDensity
	RAIDgroundEffectDist = "2|s|40|500|10", -- as groundEffectDist
	RAIDgroundEffectFade = "2",
	RAIDhorizonClip = "2|s|1600|10000|100", -- as horizonClip
	RAIDhorizonStart = "2|s|400|4000|100", -- as horizonStart
	RAIDlodObjectCullDist = "2|s|1|200|1", -- as lodObjectCullDist
	RAIDlodObjectCullSize = "2|s|1|100|1", -- as lodObjectCullSize
	RAIDlodObjectFadeScale = "2|s|50|5000|10", -- as lodObjectFadeScale
	RAIDlodObjectMinSize = "2|s|0|1000|1", -- as lodObjectMinSize
	raidOptionDisplayMainTankAndAssist = "8|t", -- ui
	raidOptionDisplayPets = "8|t", -- ui
	raidOptionIsShown = "8|t", -- help
	raidOptionKeepGroupsTogether = "8",
	raidOptionLocked = "8",
	raidOptionShowBorders = "8|t", -- help
	raidOptionSortMode = "8",
	RAIDOutlineEngineMode = "2",
	RAIDparticleDensity = "2|s|0|100|5", -- as particleDensity
	RAIDparticleMTDensity = "2|s|0|100|1", -- as particleMTDensity
	RAIDParticulatesEnabled = "2|t", -- help
	RAIDpbrLiquidDetail = "2|s|0|2|1", -- as pbrLiquidDetail
	RAIDprojectedTextures = "2",
	RAIDreflectionMode = "2|c|0=NONE|1=SCREEN_SPACE_WITHOUT_THE_SKY|2=SCREEN_SPACE|3=PLANAR", -- as reflectionMode
	RAIDrefraction = "2|s|0|2|1", -- as refraction
	RAIDRenderFormat = "2|c|0=BGRA8UNORM|1=A2BGR10UNORM|2=RGBA16F|3=RGBA32F", -- help
	RAIDrippleDetail = "2|s|0|2|1", -- as rippleDetail
	RAIDsettingsEnabled = "2|t", -- ui
	RAIDshadowBlendCascades = "2|t", -- as shadowBlendCascades
	RAIDshadowMode = "2|c|0=BLOB_SHADOWS|1=N1_BAND_ON_UNITS|2=N2_BANDS_ON_UNITS_AND_TERRAIN|3=N3_BANDS_ON_UNITS_AND_TERRAIN|4=N4_BANDS_ON_UNITS_AND_TERRAIN", -- as shadowMode
	RAIDshadowNumCascades = "2|s|1|4|1", -- as shadowNumCascades
	RAIDshadowRt = "2|c|0=DISABLED|1=FAIR|2=MEDIUM", -- help
	RAIDshadowSoft = "2|t", -- help
	RAIDshadowTextureSize = "2|c|512=512|768=768|1024=1024|1536=1536|2048=2048|4096=4096", -- as shadowTextureSize
	RAIDspellClutter = "2|s|0|4|1", -- as spellClutter
	RAIDSSAO = "2|s|0|4|1", -- as SSAO
	RAIDsunShafts = "2|c|0=OFF|1=LOW|2=HIGH", -- as sunShafts
	RAIDterrainLodDist = "2|s|200|650|25", -- as terrainLodDist
	RAIDTerrainLodDiv = "2",
	RAIDterrainMipLevel = "2|c|0=FULL_DETAIL|1=REDUCED", -- as terrainMipLevel
	RAIDVolumeFog = "2|t", -- as volumeFog
	RAIDVolumeFogLevel = "2|s|0|4|1", -- as volumeFogLevel
	RAIDWaterDetail = "2|s|0|3|1", -- as waterDetail
	RAIDweatherDensity = "2|c|0=NONE|1=LIGHT|2=MEDIUM|3=HEAVY", -- as weatherDensity
	RAIDwmoLodDist = "2|s|250|400|10", -- as wmoLodDist
	RAIDworldBaseMip = "2",
	rawMouseEnable = "11|t", -- help
	reflectionDownscale = "1",
	reflectionMode = "1",
	refraction = "1",
	reloadUIOnAspectChange = "14",
	remoteTextToSpeech = "13|t", -- ui
	remoteTextToSpeechVoice = "13",
	RenderFormat = "1|c|0=BGRA8UNORM|1=A2BGR10UNORM|2=RGBA16F|3=RGBA32F", -- help
	RenderScale = "1",
	RenderScaleDowngradeBackgroundMinSize = "1",
	RenderScaleDowngradeForegroundMinSize = "1",
	ReplaceMyPlayerPortrait = "8|t", -- ui
	ReplaceOtherPlayerPortraits = "8|t", -- ui
	reputationsCollapsed = "17",
	ResampleAlwaysSharpen = "1",
	ResampleQuality = "1|c|0=POINT|1=BILINEAR|2=BICUBIC|3=FSR", -- ui
	ResampleSharpness = "1|s|0|2|0.1", -- ui
	ResizeConstraints = "1|c|0=NONE|1=ASPECT_RATIO_LOCKED|2=DISABLE_RESIZING", -- help
	restrictCalendarInvites = "6|t", -- ui
	rippleDetail = "1",
	rotateMinimap = "14|t", -- help
	runeFadeTime = "8",
	runeSpentFadeTime = "8",
	runeSpentFlashTime = "8",
	sceneOcclusionEnable = "1|t", -- name
	screenEdgeFlash = "14|t", -- help
	screenshotFormat = "1",
	screenshotQuality = "1",
	screenshotSizeOverride = "1",
	scriptErrors = "16|t", -- help
	scriptProfile = "16|t", -- help
	scriptWarnings = "16|t", -- help
	scrollToLogQuest = "14|t", -- help
	secondaryProfessionsFilter = "14|t", -- help
	secureAbilityToggle = "9|t", -- help
	seenAgeVerificationRestrictionState = "17",
	seenAlliedRaceUnlocks = "17",
	seenAsiaCharacterUpgradePopup = "17",
	seenCharacterUpgradePopup = "17",
	seenConfigurationWarnings = "17",
	seenExpansionTrialPopup = "17",
	seenLevelSquishPopup = "17",
	seenPurchasableClassCapstone = "17",
	seenRegionalChatDisabled = "17",
	seenTimerunningFirstLoginPopup = "17",
	serverAlert = "15",
	ServerMessageEventLog = "16",
	serviceTypeFilter = "14",
	shadowBlendCascades = "1",
	shadowMode = "1",
	shadowNumCascades = "1",
	shadowRt = "1|c|0=DISABLED|1=FAIR|2=MEDIUM|3=HIGH", -- ui
	shadowSoft = "1",
	shadowTextureSize = "1",
	ShakeStrengthCamera = "13|c|0=NONE|0.25=REDUCED|1=FULL", -- ui
	ShakeStrengthUI = "13|c|0=NONE|0.25=REDUCED|1=FULL", -- ui
	shipyardMissionTutorialAreaBuff = "17",
	shipyardMissionTutorialBlockade = "17",
	shipyardMissionTutorialFirst = "17",
	showAllItemsInTransmog = "14|t", -- name
	ShowAllSpellRanks = "9|t", -- name
	showArenaEnemyCastbar = "8|t", -- name
	showArenaEnemyFrames = "8|t", -- name
	showArenaEnemyPets = "8|t", -- name
	showBattlefieldMinimap = "14|t", -- help
	showBuilderFeedback = "9|t", -- name
	showCastableBuffs = "8|t", -- name
	showCreateCharacterRealmConfirmDialog = "14|t", -- name
	showCustomSetDetails = "14|t", -- help
	showDelveEntrancesOnMap = "14|t", -- help
	showDispelDebuffs = "8|t", -- name
	showDungeonEntrancesOnMap = "14|t", -- help
	showErrors = "16|t", -- name
	showfootprintparticles = "1",
	showHonorAsExperience = "14|t", -- name
	showInGameNavigation = "14|t", -- ui
	showKeyring = "14|t", -- name
	showLoadingScreenTips = "14|t", -- ui
	showLootSpam = "6|t", -- help
	showMaxLevelAnnouncements = "6|t", -- help
	showNPETutorials = "14|t", -- name
	showOutfitDetails = "14|t", -- help
	showPartyPets = "8|t", -- help
	showPhotosensitivityWarning = "13",
	showPingsInChat = "6|t", -- ui
	showPingsOnRaidFrames = "8|t", -- ui
	showQuestDifficultyColor = "14|t", -- help
	showQuestLevel = "14|t", -- help
	showQuestObjectivesInLog = "14|t", -- help
	ShowQuestUnitCircles = "14|t", -- name
	showScreenNarrationDialog = "13|t", -- name
	showSpectatorTeamCircles = "14|t", -- name
	showSpenderFeedback = "9|t", -- name
	showSwingTimer = "9|t", -- ui
	showTamers = "14|t", -- help
	showTamersWQ = "14|t", -- help
	showTargetCastbar = "8|t", -- name
	showTargetOfTarget = "8|t", -- ui
	showTaxiNodeLearnedIcon = "14|t", -- help
	showTempMaxHealthLoss = "8|t", -- help
	showTimestamps = "6|c|none=NONE|%I:%M =03:27|%I:%M:%S =03:27:32|%I:%M %p =03:27 PM|%I:%M:%S %p =03:27:32 PM|%H:%M =15:27|%H:%M:%S =15:27:32", -- ui
	showToastBroadcast = "6|t", -- help
	showToastClubInvitation = "6|t", -- help
	showToastConversation = "6|t", -- help
	showToastFriendRequest = "6|t", -- ui
	showToastOffline = "6|t", -- ui
	showToastOnline = "6|t", -- ui
	showToastWindow = "6|t", -- ui
	showTokenFrame = "17",
	showTutorials = "14|t", -- ui
	showVKeyCastbar = "8|t", -- name
	showVKeyCastbarOnlyOnTarget = "8|t", -- name
	showVKeyCastbarSpellName = "8|t", -- name
	simd = "15",
	skipTutorialAchievement = "14",
	SkyCloudLOD = "1",
	SlugOpticalWeight = "1",
	SmartNavigationCursorAnchor = "12",
	SmartNavigationCursorAppearance = "12",
	SmartNavigationCursorButtonAnchor = "12",
	SmartNavigationCursorFlipHorizontal = "12",
	SmartNavigationCursorFlipVertical = "12",
	SmartNavigationCursorRotationAngle = "12",
	SmartNavigationCursorScale = "12",
	SmartNavigationScrollSpeed = "12",
	smoothUnitPhasing = "1",
	smoothUnitPhasingActorPurgatoryTimeMs = "1",
	smoothUnitPhasingAliveTimeoutMs = "1",
	smoothUnitPhasingDestroyedPurgatoryTimeMs = "1",
	smoothUnitPhasingDistThreshold = "1",
	smoothUnitPhasingEnableAlive = "1|t", -- help
	smoothUnitPhasingUnseenPurgatoryTimeMs = "1",
	smoothUnitPhasingVehicleExtraTimeoutMs = "1",
	SoftTargetEnemy = "10|c|0=OFF|1=GAMEPAD|2=KEYBOARD_AND_MOUSE|3=ALWAYS", -- help
	SoftTargetEnemyArc = "10|c|0=NO_YAW_ARC_ALLOWANCE_DIRECTLY_IN_FRONT|1=MUST_BE_IN_FRONT_YAW_ARC|2=ANYWHERE_IN_TAB_TARGETING_AREA", -- help
	SoftTargetEnemyRange = "10",
	SoftTargetForce = "10",
	SoftTargetFriend = "10|c|0=OFF|1=GAMEPAD|2=KEYBOARD_AND_MOUSE|3=ALWAYS", -- help
	SoftTargetFriendArc = "10|c|0=NO_YAW_ARC_ALLOWANCE_DIRECTLY_IN_FRONT|1=MUST_BE_IN_FRONT_YAW_ARC|2=ANYWHERE_IN_TARGETING_AREA", -- help
	SoftTargetFriendRange = "10",
	SoftTargetIconEnemy = "10|t", -- help
	SoftTargetIconFriend = "10|t", -- help
	SoftTargetIconGameObject = "10|t", -- help
	SoftTargetIconInteract = "10|t", -- help
	SoftTargetInteract = "10|c|0=OFF|1=GAMEPAD|2=KEYBOARD_AND_MOUSE|3=ALWAYS", -- help
	SoftTargetInteractArc = "10|c|0=NO_YAW_ARC_ALLOWANCE_DIRECTLY_IN_FRONT|1=MUST_BE_IN_FRONT_YAW_ARC|2=ANYWHERE_IN_TARGETING_AREA", -- help
	softTargetInteractionTutorialTotalInteractions = "17",
	SoftTargetInteractOnlyInRange = "10|t", -- help
	SoftTargetInteractRange = "10",
	SoftTargetInteractRangeIsHard = "10|t", -- help
	SoftTargetLowPriorityIcons = "10|t", -- help
	SoftTargetMatchLocked = "10",
	SoftTargetNameplateEnemy = "10|t", -- help
	SoftTargetNameplateFriend = "10|t", -- help
	SoftTargetNameplateInteract = "10|t", -- help
	SoftTargetNameplateSize = "10",
	softTargettingInteractKeySound = "10|t", -- ui
	SoftTargetTooltipDurationMs = "10",
	SoftTargetTooltipEnemy = "10|t", -- ui
	SoftTargetTooltipFriend = "10",
	SoftTargetTooltipInteract = "10|t", -- ui
	SoftTargetTooltipLocked = "10",
	SoftTargetWithLocked = "10",
	SoftTargetWorldtextFarDist = "10",
	SoftTargetWorldtextNearDist = "10",
	SoftTargetWorldtextNearScale = "10",
	SoftTargetWorldtextSize = "10",
	sortCharListByLastActive = "14|t", -- help
	sortDiskReads = "15",
	soulbindsActivatedTutorial = "17",
	soulbindsLandingPageTutorial = "17",
	soulbindsViewedTutorial = "17",
	Sound_AllyPlayerHighpassDSPCutoff = "5",
	Sound_AlternateListener = "5|t", -- help
	Sound_AmbienceHighpassDSPCutoff = "5",
	Sound_AmbienceVolume = "5|s|0|1|0.05", -- ui
	Sound_DialogVolume = "5|s|0|1|0.05", -- ui
	Sound_DSPBufferSize = "5",
	Sound_EnableAllSound = "5|t", -- ui
	Sound_EnableAmbience = "5|t", -- ui
	Sound_EnableArmorFoleySoundForOthers = "5",
	Sound_EnableArmorFoleySoundForSelf = "5",
	Sound_EnableDialog = "5|t", -- ui
	Sound_EnableDSPEffects = "5",
	Sound_EnableEmoteSounds = "5|t", -- ui
	Sound_EnableEncounterWarningsSounds = "5|t", -- ui
	Sound_EnableErrorSpeech = "5|t", -- ui
	Sound_EnableGameplaySFX = "5|t", -- ui
	Sound_EnableMixMode2 = "5|t", -- name
	Sound_EnableMusic = "5|t", -- ui
	Sound_EnablePetBattleMusic = "5|t", -- ui
	Sound_EnablePetSounds = "5|t", -- ui
	Sound_EnablePingSounds = "5|t", -- ui
	Sound_EnablePositionalLowPassFilter = "5|t", -- ui
	Sound_EnableReverb = "5|t", -- ui
	Sound_EnableSFX = "5|t", -- ui
	Sound_EnableSoundWhenGameIsInBG = "5|t", -- ui
	Sound_EncounterWarningsVolume = "5|s|0|1|0.05", -- ui
	Sound_EnemyPlayerHighpassDSPCutoff = "5",
	Sound_GameplaySFX = "5|s|0|1|0.05", -- ui
	Sound_ListenerAtCharacter = "5",
	Sound_MasterVolume = "5|s|0|1|0.05", -- ui
	Sound_MaxCacheableSizeInBytes = "5",
	Sound_MaxCacheSizeInBytes = "5|c|67108864=SMALL_64_MB|134217728=LARGE_128_MB", -- ui
	Sound_MusicVolume = "5|s|0|1|0.05", -- ui
	Sound_NPCHighpassDSPCutoff = "5",
	Sound_NumChannels = "5|s|20|128|1", -- ui
	Sound_OutputDriverIndex = "5",
	Sound_OutputDriverName = "5",
	Sound_OutputSampleRate = "5",
	Sound_PingVolume = "5|s|0|1|0.05", -- ui
	Sound_SFXVolume = "5|s|0|1|0.05", -- ui
	Sound_VoiceChatInputDriverIndex = "5",
	Sound_VoiceChatInputDriverName = "5",
	Sound_VoiceChatOutputDriverIndex = "5",
	Sound_VoiceChatOutputDriverName = "5",
	Sound_ZoneMusicNoDelay = "5|t", -- ui
	SoundPerf_VariationCap = "5",
	SpawnRegion = "15",
	specular = "1",
	speechToText = "13|t", -- ui
	spellActivationOverlayOpacity = "9|s|0|1|0.05", -- ui
	spellBookHideFlyouts = "9|t", -- help
	spellBookHidePassives = "9|t", -- help
	spellBookMinimize = "9|t", -- help
	spellClutter = "1|s|0|4|1", -- probe
	SpellCooldownDebugger = "16",
	spellDiminishPVPEnemiesEnabled = "8|t", -- ui
	spellDiminishPVPOnlyTriggerableByMe = "8|t", -- ui
	SpellEventLog = "16",
	SpellOverrides = "16",
	SpellQueueWindow = "9",
	SpellScriptEventLog = "16",
	SpellTargeting = "9",
	spellVisualDensityFilterSetting = "1",
	SpellVisuals = "16",
	SplineOpt = "16|t", -- help
	SSAO = "1|s|0|4|1", -- probe
	ssaoMagicNormals = "1|t", -- help
	ssaoMagicThresholdHigh = "1",
	ssaoMagicThresholdLow = "1",
	statusText = "8|t", -- help
	statusTextDisplay = "8|c|NUMERIC=NUMERIC_VALUE|PERCENT=PERCENTAGE|BOTH=BOTH|NONE=NONE", -- ui
	stopAutoAttackOnTargetChange = "9|t", -- help
	streamingCameraLookAheadTime = "15",
	streamingCameraMaxRadius = "15",
	streamingCameraRadius = "15",
	streamStatusMessage = "15|t", -- help
	sunShafts = "1",
	superTrackerDist = "14",
	SuppressCpuMicrocodeChecks = "15|t", -- help
	synchronizeBindings = "14",
	synchronizeChatFrames = "6",
	synchronizeConfig = "14",
	taintLog = "16|c|0=DISABLED|1=BLOCKED_ACTIONS_AND_TAINT_EVENTS|2=TAINTED_GLOBAL_READS_AND_WRITES|3=TAINTED_UPVALUE_READS_AND_WRITES|4=TAINTED_TABLE_FIELD_READS_AND_WRITES", -- help
	taintLogObjectSecrets = "16|t", -- help
	talentPointsSpent = "17",
	TargetAutoEnemy = "10",
	TargetAutoFriend = "10",
	TargetAutoLock = "10",
	TargetEnemyAttacker = "10",
	targetFPS = "1|s|8|200|1", -- ui
	targetHighlightAlwaysShown = "10|t", -- help
	TargetNearestUseNew = "10|t", -- help
	TargetPriorityCombatLock = "10",
	TargetPriorityCombatLockContextualRelaxation = "10|t", -- help
	TargetPriorityCombatLockHighlight = "10",
	TargetPriorityPvp = "10",
	telemetryWowlabsPackage = "15",
	telemetryWowPackage = "15",
	teleportMaxNoLoadDist = "15",
	terrainLodDist = "1",
	TerrainLodDiv = "1",
	terrainMipLevel = "1",
	test_cameraDynamicPitch = "3",
	test_cameraDynamicPitchBaseFovPad = "3",
	test_cameraDynamicPitchBaseFovPadDownScale = "3",
	test_cameraDynamicPitchBaseFovPadFlying = "3",
	test_cameraDynamicPitchSmartPivotCutoffDist = "3",
	test_cameraHeadMovementDeadZone = "3",
	test_cameraHeadMovementFirstPersonDampRate = "3",
	test_cameraHeadMovementMovingDampRate = "3",
	test_cameraHeadMovementMovingStrength = "3",
	test_cameraHeadMovementRangeScale = "3",
	test_cameraHeadMovementStandingDampRate = "3",
	test_cameraHeadMovementStandingStrength = "3",
	test_cameraHeadMovementStrength = "3",
	test_cameraOverShoulder = "3",
	test_cameraTargetFocusEnemyEnable = "3",
	test_cameraTargetFocusEnemyStrengthPitch = "3",
	test_cameraTargetFocusEnemyStrengthYaw = "3",
	test_cameraTargetFocusInteractEnable = "3",
	test_cameraTargetFocusInteractStrengthPitch = "3",
	test_cameraTargetFocusInteractStrengthYaw = "3",
	textLocale = "15",
	textToSpeech = "13|t", -- ui
	textureErrorColors = "1|t", -- help
	textureFilteringMode = "1|c|0=BILINEAR|1=TRILINEAR|2=N2X_ANISOTROPIC|3=N4X_ANISOTROPIC|4=N8X_ANISOTROPIC|5=N16X_ANISOTROPIC", -- ui
	ThreadPoolLimitHP = "15",
	ThreadPoolLimitLP = "15",
	ThreadPoolLimitMP = "15",
	ThreadPoolPerThreadAllocator = "15|c|0=DISABLED|1=ALLOW|2=FORCE", -- help
	threatPlaySounds = "8|t", -- help
	threatShowNumeric = "8|t", -- help
	threatWarning = "8",
	threatWorldText = "7|t", -- help
	timeMgrAlarmEnabled = "14|t", -- help
	timeMgrAlarmMessage = "14",
	timeMgrAlarmTime = "14",
	timeMgrUseLocalTime = "14|t", -- help
	timeMgrUseMilitaryTime = "14|t", -- help
	titleBarShortName = "14",
	titleBarShowAccountName = "14|t", -- name
	titleBarShowBuildInfo = "14|t", -- name
	titleBarShowCharacterName = "14|t", -- name
	titleBarShowConfigName = "14|t", -- name
	titleBarShowGxInfo = "14|t", -- name
	titleBarShowPID = "14|t", -- name
	titleBarShowRealmName = "14|t", -- name
	toastDuration = "6",
	tooltipPointsShowMinAndMax = "14|t", -- help
	tooltipShowAuraCasterNames = "14|t", -- name
	tooltipShowAuraSpellIDs = "14|t", -- name
	toyBoxCollectedFilters = "14|f|-1=COLLECTED|-2=NOT_COLLECTED|-3=UNUSABLE", -- probe: set in game a flag at a time through C_ToyBox.SetCollectedShown, SetUncollectedShown and SetUnusableShown, flags 1, 2 and 3, each on while its filter is off; the labels are the game's
	toyBoxExpansionFilters = "14|f|-1=CLASSIC", -- probe: set in game a flag at a time through C_ToyBox.SetExpansionTypeFilter, expansion 1 was flag 1, on while its filter is off; GetNumExpansions() is 1 in 1.60.1, and the label is the game's
	toyBoxSourceFilters = "14|f|-1=DROP|-2=QUEST|-3=VENDOR|-4=PROFESSION|-5=PET_BATTLE|-6=ACHIEVEMENT|-7=WORLD_EVENT|-8=PROMOTION|-9=TRADING_CARD_GAME|-10=IN_GAME_SHOP|-11=DISCOVERY|-12=TRADING_POST", -- probe: set in game a flag at a time through C_ToyBox.SetSourceTypeFilter, sources 1 and 3 were flags 1 and 3, each on while its filter is off; the labels are the game's
	trackedAchievements = "17",
	trackedInitiativeTasks = "17",
	trackedPerksActivities = "17",
	trackedProfessionRecipes = "17",
	trackedProfessionRecraftRecipes = "17",
	trackedQuests = "17",
	trackedWorldQuests = "17",
	transmogCurrentSpecOnly = "14|t", -- help
	transmogDebug = "16|t", -- help
	transmogHideIgnoredSlots = "14|t", -- help
	transmogPreviewedWeaponToggle = "14|t", -- help
	transmogrifySetsFilters = "14|f|-1=COLLECTED|-2=NOT_COLLECTED|-3=PVE|-4=PVP", -- probe: set in game a flag at a time through C_TransmogSets.SetSetsFilter away from a transmogrifier, filters 1 and 4 were flags 1 and 4, each on while its filter is off; the labels are the game's
	transmogrifyShowCollected = "14|t", -- help
	transmogrifyShowUncollected = "14|t", -- help
	transmogrifySourceFilters = "14",
	transmogShowID = "14|t", -- name
	TTSUseCharacterSettings = "13|t", -- help
	TurnSpeed = "11|S|1|540|1|x", -- probe: 540 is the most the game keeps; help: capped by the server
	UberTooltips = "14|t", -- help
	uiScale = "14|s|0.65|1.15|0.01", -- ui
	uiScaleMultiplier = "14",
	unitClutter = "4|t", -- help
	unitClutterInstancesOnly = "4|t", -- help
	unitClutterPlayerThreshold = "4",
	UnitEnterCombatLog = "16",
	unitFacingPlayerDeadZoneDeg = "14",
	UnitNameEnemyGuardianName = "4",
	UnitNameEnemyMinionName = "4|t", -- ui
	UnitNameEnemyPetName = "4",
	UnitNameEnemyPlayerName = "4|t", -- ui
	UnitNameEnemyTotemName = "4",
	UnitNameFocused = "4|t", -- code
	UnitNameForceHideMinus = "4",
	UnitNameFriendlyGuardianName = "4",
	UnitNameFriendlyMinionName = "4|t", -- ui
	UnitNameFriendlyPetName = "4",
	UnitNameFriendlyPlayerName = "4|t", -- ui
	UnitNameFriendlySpecialNPCName = "4|t", -- code
	UnitNameFriendlyTotemName = "4",
	UnitNameGuildTitle = "4",
	UnitNameHostleNPC = "4|t", -- code
	UnitNameInteractiveNPC = "4|t", -- code
	UnitNameNonCombatCreatureName = "4|t", -- ui
	UnitNameNPC = "4|t", -- code
	UnitNameOwn = "4|t", -- ui
	UnitNamePlayerGuild = "4",
	UnitNamePlayerPVPTitle = "4",
	unitsLookAtPlayers = "14|t", -- help
	UnitSurnameOwn = "4|t", -- ui
	UnitVisibility = "1",
	unlockedMajorFactions = "17",
	useBLEEP = "15|t", -- name
	useCommentatorSelectionCircles = "14|t", -- help
	useHDRBrightness = "1",
	useHDRPeakBrightness = "1",
	useHighResTextures = "1|t", -- ui
	useIPv6 = "15|t", -- ui
	UseKeyHeldSpellErrorPollTime = "9",
	useMaxFPS = "1|t", -- ui
	useMaxFPSBk = "1|t", -- ui
	userFontScale = "14|c|0.8571=SMALL|1=MEDIUM|1.1429=LARGE|1.4286=EXTRA_LARGE|1.7143=HUGE|2=GIGANTIC", -- ui
	userFontScaleGlue = "14",
	UseSlug = "16|t", -- name
	useTargetFPS = "1|t", -- ui
	useUiScale = "14|t", -- ui
	validateFrameXML = "16|t", -- help
	VerboseSpellScriptEventLog = "16",
	videoOptionsVersion = "17",
	videoOptionsVersionDefault = "1",
	violenceLevel = "1",
	VoiceChatMasterVolumeScale = "5|s|0|1|0.01", -- ui
	VoiceCommunicationMode = "5",
	VoiceEnableWhenGameIsInBG = "5|t", -- help
	VoiceInputDevice = "5",
	VoiceInputVolume = "5|s|0|100|1", -- ui
	VoiceOutputDevice = "5",
	VoiceOutputVolume = "5|s|0|100|1", -- ui
	voiceProvider = "5|c|0=LEGACY|1=DISCORD", -- ui
	VoiceProxyEventLog = "16",
	VoicePushToTalkKeybind = "5",
	VoiceSelfDeafened = "5",
	VoiceSelfMuted = "5",
	voiceUseDiscordSettings = "5|t", -- ui
	VoiceVADSensitivity = "5|s|0|100|1", -- ui
	volumeFog = "1",
	volumeFogInterior = "1",
	volumeFogLevel = "1",
	vrsParticles = "1",
	vrsValar = "1|c|0=DISABLED|1=STANDARD|2=AGGRESSIVE", -- ui
	vrsValarAlwaysOn = "1|t", -- help
	vrsValarEnvLuma = "1",
	vrsValarGPUMode = "1|c|0=AUTO_DETECT_2|1=STANDARD|2=LOW_POWER", -- help
	vrsValarLPUseCornerSampling = "1|t", -- help
	vrsValarUseAsyncCompute = "1|t", -- help
	vrsValarUseMotionVectors = "1|t", -- help
	vrsValarUseWeberFechner = "1|t", -- help
	vrsValarWeberFechnerConstant = "1",
	vrsWorldGeo = "1",
	vsync = "1|t|window", -- ui, restart: ui
	WalkableSurfacesValidationLog = "16",
	wardrobeSetsFilters = "14|f|-1=COLLECTED|-2=NOT_COLLECTED|-3=PVE|-4=PVP", -- probe: set in game a flag at a time through C_TransmogSets.SetBaseSetsFilter, filters 1 and 4 were flags 1 and 4, each on while its filter is off; the labels are the game's
	wardrobeShowAllFactions = "14|t", -- help
	wardrobeShowAllRaces = "14|t", -- help
	wardrobeShowCollected = "14|t", -- help
	wardrobeShowUncollected = "14|t", -- help
	wardrobeSourceFilters = "14|f|-2=BOSS_DROP|-3=QUEST|-4=VENDOR|-5=WORLD_DROP|-8=ACHIEVEMENT|-9=PROFESSION", -- probe: set in game a flag at a time through C_TransmogCollection.SetSourceTypeFilter, sources 1 to 6 were flags 2 to 5, 8 and 9, each on while its filter is off; the labels are the game's
	waterDetail = "1|s|0|3|1", -- probe
	weatherDensity = "1",
	webChallengeURLTimeout = "15",
	whisperMode = "6|c|popout=POP_OUT|inline=INLINE|popout_and_inline=POP_OUT_AND_INLINE", -- ui
	wholeChatWindowClickable = "6|t", -- help
	winePlatformTTS = "13|t", -- help
	wmoDoodadDist = "1",
	wmoLodDist = "1",
	wmoLodDistScale = "1",
	wmoPortalFadeScale = "1",
	wmoPortalInteriorFade = "1",
	WorldActionsLog = "16",
	worldBaseMip = "1",
	worldIntersectMaxJobs = "15",
	worldLoadSort = "15",
	worldMapShowCursorCoords = "14|t", -- ui
	worldMapShowPlayerCoords = "14|t", -- ui
	worldPreloadHighResTextures = "15",
	worldPreloadNonCritical = "15",
	worldPreloadNonCriticalTimeout = "15",
	worldPreloadSort = "15",
	worldQuestFilterAnima = "14|t", -- help
	worldQuestFilterArtifactPower = "14|t", -- help
	worldQuestFilterEquipment = "14|t", -- help
	worldQuestFilterGold = "14|t", -- help
	worldQuestFilterProfessionMaterials = "14|t", -- help
	worldQuestFilterReputation = "14|t", -- help
	worldQuestFilterResources = "14|t", -- help
	WorldTextCritScreenY_v2 = "7",
	WorldTextGravity_v2 = "7",
	WorldTextMinAlpha_v2 = "7",
	WorldTextMinSize = "7|s|0|64|2", -- ui
	WorldTextNonRandomZ_v2 = "7",
	WorldTextRampDuration_v2 = "7",
	WorldTextRampPow_v2 = "7",
	WorldTextRampPowCrit_v2 = "7",
	WorldTextRandomXY_v2 = "7",
	WorldTextRandomZMax_v2 = "7",
	WorldTextRandomZMin_v2 = "7",
	WorldTextScale_v2 = "7",
	WorldTextScreenY_v2 = "7",
	WorldTextStartPosRandomness_v2 = "7",
	worldViewCullMaxJobs = "15",
	xpBarText = "14|t", -- help
}

-- Retail's own lines, as WoW retail 12.1.5 (build 70783) has its CVars, in the same
-- form. In retail each takes the place of the line above for its CVar. "ui" on one
-- of these is retail's settings code (the `live` branch of wow-ui-source).
EverySetting.RETAIL_CVARS = {
	-- The CVars only retail has. One with just its section says why. The two an
	-- addon makes (Details' LibOpenRaidTempCache and LibOpenRaidTempCacheDebug)
	-- aren't the game's: like any other addon's CVar, they're listed under the
	-- last section, with a box.
	activeCUFProfile = "17", -- an earlier version's, kept in the saved settings of the account it was found on: another account's client hadn't it at all, the client gives it no default or help, and retail's interface code doesn't read it
	auctionDisplayOnCharacter = "17", -- an earlier version's, as activeCUFProfile
	cacaoBilateralSimilarityDistanceSigma = "1", -- help: any number above 0, with no top, so just the box
	KioskCharacterTemplateSet = "16", -- kiosk mode's, as Forever's KioskCharacterTemplateSet1 and 2; read-only
	lastLaunchedExternalEventURL = "17", -- the last event page the game opened outside it, kept per account; locked
	nameplateShowFriends = "17", -- an earlier version's, as activeCUFProfile: retail's menu shows friendly players' nameplates with nameplateShowFriendlyPlayers
	playerStatLeftDropdown = "17", -- an earlier version's, as activeCUFProfile
	playerStatRightDropdown = "17", -- an earlier version's, as activeCUFProfile
	SSAOType = "1|c|0=0|1=1", -- probe: the engine kept 0 and 1, and turned down 2, 3 and 9 ("Unsupported SSAO type."); the game names neither
	unlockedExpansionLandingPages = "17", -- an earlier version's, as activeCUFProfile
	useShadowMapping = "1|t", -- name: the engine kept 2 too
	volumeFogDisableLightScattering = "1|t", -- help
	volumeFogDisableNoise = "1|t", -- help
	volumeFogDisableShadows = "1|t", -- help
	volumeFogUse16BitTexture = "1|t|gx", -- help, restart: help
	-- The CVars both games have, whose control retail's options menu gives and
	-- Forever's doesn't, or gives another way.
	advFlyKeyboardMaxPitchFactor = "11|s|1|10|0.5", -- ui
	advFlyKeyboardMaxTurnFactor = "11|s|1|10|0.5", -- ui
	advFlyKeyboardMinPitchFactor = "11|s|1|10|0.5", -- ui
	advFlyKeyboardMinTurnFactor = "11|s|1|10|0.5", -- ui
	advFlyPitchControl = "11|c|3=DEFAULT|2=BACKWARD_UP|1=FORWARD_UP", -- ui
	advFlyPitchControlCameraChase = "3|s|10|30|1", -- ui
	encounterTimelineEnabled = "14|t", -- ui
	encounterTimelineHideForOtherRoles = "14|t", -- ui
	encounterTimelineHideLongCountdowns = "14|t", -- ui
	encounterTimelineHideQueuedCountdowns = "14|t", -- ui
	graphicsComputeEffects = "1|c|0=DISABLED|1=LOW|2=MEDIUM|3=HIGH|4=ULTRA", -- ui
	graphicsParticleDensity = "1|c|0=DISABLED|1=LOW|2=FAIR|3=MEDIUM|4=HIGH|5=ULTRA", -- ui
	LowLatencyMode = "1|c|0=DISABLED|1=BUILT_IN|2=NVIDIA_REFLEX|3=NVIDIA_REFLEX_PLUS_BOOST|4=INTEL_XELL", -- ui
	nameplateStyle = "4|c|0=MODERN|1=THIN|2=BLOCK|3=CLEAN_HEALTH|4=CAST_FOCUS|5=LEGACY_RED", -- ui
	Outline = "1|c|0=DISABLED|1=QUEST_OBJECTIVES_ONLY|2=QUEST_OBJECTIVES_AND_MOUSEOVER|3=QUEST_OBJECTIVES_MOUSEOVER_AND_TARGET", -- ui
	raidGraphicsComputeEffects = "2|c|0=DISABLED|1=LOW|2=MEDIUM|3=HIGH|4=ULTRA", -- as graphicsComputeEffects
	raidGraphicsParticleDensity = "2|c|0=DISABLED|1=LOW|2=FAIR|3=MEDIUM|4=HIGH|5=ULTRA", -- as graphicsParticleDensity
}
if EverySetting.Client() == "retail" then
	for name, line in pairs(EverySetting.RETAIL_CVARS) do EverySetting.CVARS[name] = line end
end

-- What a console command that isn't a CVar does, where the game's own help says
-- nothing (or not enough). The window lists every such command under Console
-- commands, with this or else the game's help as its description, and a command
-- with neither says so. Said only where the name leaves no doubt, or it was tried.
EverySetting.COMMANDS = {
	GetSwapChainSize = L.COMMAND_GETSWAPCHAINSIZE,
	GetWindowSize = L.COMMAND_GETWINDOWSIZE,
	GxCurrentAPI = L.COMMAND_GXCURRENTAPI,
	GxCurrentGPU = L.COMMAND_GXCURRENTGPU,
	GxListGPUs = L.COMMAND_GXLISTGPUS,
	GxRestart = L.COMMAND_GXRESTART,
	logout = L.COMMAND_LOGOUT,
	quit = L.COMMAND_QUIT,
	TakeScreenshot = L.COMMAND_TAKESCREENSHOT,
	ToggleWindowMode = L.COMMAND_TOGGLEWINDOWMODE,
	UpdateWindow = L.COMMAND_UPDATEWINDOW,
	ver = L.COMMAND_VER,
}

-- The console commands the Run button runs. Each was clicked with nothing after
-- it in the Forever 1.60.1 and retail 12.1.5 clients, and none was refused, raised
-- an error or disconnected. None changed a CVar but ToggleWindowMode, which sets
-- GxMaximize, as switching between a window and full screen does. showPlayer,
-- LogFps and ToggleWindowMode are toggles: a second click undoes the first. Every
-- other command can only be copied: the game refuses some from an addon (logout,
-- quit), and some do harm with nothing after them (cvar_default resets every
-- CVar, NeighborhoodGetInvites disconnects in Forever).
EverySetting.RUNNABLE = {
	ActionCam = true, clear = true, clearSeenCustomizationChoices = true, clearSeenDelvesCurios = true,
	closeconsole = true, cvarlist = true, DefragmentGPU = true, enable = true, FrameBufferCacheGpuFootprint = true,
	GamePadListDevices = true, GetSwapChainSize = true, GetWindowSize = true, GxCurrentAPI = true,
	GxCurrentGPU = true, GxFrameStats = true, GxGetVideoMemory = true, GxIsPrism = true, GxListGPUs = true,
	GxLogFlush = true, GxLogFullGPUInfo = true, GxMemReport = true, GxRestart = true, help = true, LogFps = true,
	physCulling = true, physCullingDist = true, physVegMinPushDist = true, physVegPosMaxPush = true,
	physVegPosPushAmt = true, physVegPosRelaxSpeed = true, physVegVelMaxPush = true, physVegVelSpeed = true,
	reloadUI = true, showPlayer = true, TakeScreenshot = true, testOutput = true, ToggleWindowMode = true,
	UpdateWindow = true, ver = true,
}

-- A plain name for a CVar that has no knob in Knobs.lua and that the game's options
-- don't name: one players know by a name, each one only Windows has, and in Graphics
-- and Camera each one whose help or own name says what it does. Where one game's menu
-- names it and the other's doesn't (cameraTerrainTilt), the other takes this. Its row
-- is called this, the search finds it by it, and its tooltip still gives the CVar's own
-- name.
EverySetting.NAMES = {
	ActionCombatCameraEnable = L.ACTION_COMBAT_CAMERA,
	AdvFlyingDynamicFOVEnabled = L.DYNAMIC_FLYING_FOV,
	AllowSoftwareRenderer = L.SOFTWARE_RENDERER,
	AllowSoftwareRendererDX12 = L.DX12_SOFTWARE_RENDERER,
	AllowWinRT = L.WINDOWS_GAME_BAR,
	assaoAdaptiveQualityLimit = L.ASSAO_ADAPTIVE_QUALITY_LIMIT,
	assaoBlurPassCount = L.ASSAO_BLUR_PASSES,
	assaoDetailShadowStrength = L.ASSAO_DETAIL_SHADOW_STRENGTH,
	assaoNormals = L.ASSAO_NORMALS,
	assaoShadowClamp = L.ASSAO_SHADOW_CLAMP,
	assaoShadowMult = L.ASSAO_SHADOW_MULTIPLIER,
	assaoShadowPower = L.ASSAO_SHADOW_POWER,
	assaoSharpness = L.ASSAO_SHARPNESS,
	assaoTemporalSSRadiusOffset = L.ASSAO_TEMPORAL_RADIUS_OFFSET,
	autoLootRate = L.AUTO_LOOT_SPEED,
	cameraBobbing = L.HEAD_BOB,
	CameraFollowOnStick = L.FOLLOW_CAMERA_ON_A_STICK,
	cameraIndirectOffset = L.SEEING_THROUGH_OBSTACLES_OFFSET,
	cameraIndirectVisibility = L.SEEING_THROUGH_OBSTACLES,
	cameraPivot = L.SMART_PIVOT,
	cameraTerrainTilt = L.FOLLOW_TERRAIN,
	ChromaEffectsEnable = L.CHROMA_LIGHTING,
	ChromaEffectsFactionColor = L.CHROMA_FACTION_COLOR,
	clusteredShading = L.CLUSTERED_SHADING,
	CMAA2HalfFloat = L.CMAA2_PRECISION,
	disableHorizonStart = L.DISABLE_HORIZON_START,
	DriveDynamicFOVEnabled = L.DYNAMIC_DRIVING_FOV,
	dynamicLod = L.DYNAMIC_LOD,
	emphasizeMySpellEffects = L.EMPHASIZE_MY_SPELL_EFFECTS,
	flightAngleLookAhead = L.FLIGHT_ANGLE_LOOK_AHEAD,
	groundEffectFade = L.GRASS_FADE,
	GxAllowCachelessShaderMode = L.CACHELESS_SHADER_MODE,
	GxCompatAllowSM6 = L.DX12_SHADER_MODEL_6,
	GxCompatAsyncComputeQueue = L.ASYNC_COMPUTE_QUEUE,
	GxCompatCopyQueue = L.GPU_COPY_QUEUE,
	GxCompatLowLatencyCallbacks = L.LOW_LATENCY_GPU_READBACKS,
	gxMTDecals = L.MULTITHREADED_DECALS,
	gxMTDisable = L.DISABLE_RENDER_MULTITHREADING,
	HDRBrightness = L.HDR_BRIGHTNESS,
	HDRFactor = L.HDR_FACTOR,
	HDRPeakBrightness = L.HDR_PEAK_BRIGHTNESS,
	ImpactModelCollisionMelee = L.MELEE_IMPACT_COLLISION,
	ImpactModelCollisionMissile = L.MISSILE_IMPACT_COLLISION,
	ImpactModelCollisionRanged = L.RANGED_IMPACT_COLLISION,
	lodObjectCullDist = L.LOD_OBJECT_CULL_DISTANCE,
	lodObjectMinSize = L.LOD_OBJECT_MIN_SIZE,
	luaErrorExceptions = L.LUA_ERROR_EXCEPTIONS,
	M2UseInstancing = L.HARDWARE_INSTANCING,
	M2UseThreads = L.MULTITHREADED_MODEL_ANIMATIONS,
	nameplateMaxDistance = L.NAMEPLATE_DISTANCE,
	particleMTDensity = L.MULTI_TEXTURE_PARTICLE_DENSITY,
	particulatesEnabled = L.PARTICULATES,
	rawMouseEnable = L.RAW_MOUSE_INPUT,
	RenderFormat = L.RENDER_FORMAT,
	ResizeConstraints = L.WINDOW_RESIZING,
	sceneOcclusionEnable = L.SOFTWARE_OCCLUSION_CULLING,
	spellClutter = L.SPELL_CLUTTER,
	SSAO = L.SSAO_LEVEL,
	ssaoMagicNormals = L.SSAO_COMBINED_NORMALS,
	SSAOType = L.SSAO_TYPE,
	textureErrorColors = L.PURPLE_MISSING_TEXTURES,
	useHighResTextures = L.HD_TEXTURES,
	useShadowMapping = L.SHADOW_MAPPING,
	violenceLevel = L.VIOLENCE_LEVEL,
	volumeFogDisableLightScattering = L.VOLUMETRIC_FOG_NO_LIGHT_SCATTERING,
	volumeFogDisableNoise = L.VOLUMETRIC_FOG_NO_NOISE,
	volumeFogDisableShadows = L.VOLUMETRIC_FOG_NO_SHADOWS,
	volumeFogUse16BitTexture = L.VOLUMETRIC_FOG_16_BIT,
	vrsValarAlwaysOn = L.VRS_ALWAYS_ON,
	vrsValarEnvLuma = L.VRS_ENVIRONMENT_LUMA,
	vrsValarGPUMode = L.VRS_GPU_MODE,
	vrsValarLPUseCornerSampling = L.VRS_CORNER_SAMPLING,
	vrsValarUseAsyncCompute = L.VRS_ASYNC_COMPUTE,
	vrsValarUseMotionVectors = L.VRS_MOTION_VECTORS,
	vrsValarUseWeberFechner = L.VRS_WEBER_FECHNER,
	vrsValarWeberFechnerConstant = L.VRS_WEBER_FECHNER_CONSTANT,
	waterDetail = L.WATER_DETAIL,
	winePlatformTTS = L.WINE_WINDOWS_TTS,
	WorldTextScale_v2 = L.COMBAT_TEXT_SIZE,
}
