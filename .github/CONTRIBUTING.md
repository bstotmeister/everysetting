# Contributing to Every Setting

## Bugs and feature requests

Open an [issue](https://github.com/bstotmeister/everysetting/issues/new/choose) with the
Bug report or Feature request form. New issues get the `triage` label. The maintainer
removes it once the issue is confirmed, and sets a milestone if it's planned.

## Labels

| Label | Meaning |
| --- | --- |
| `enhancement` | New feature, knob or option |
| `bug` | Something isn't working |
| `compatibility` | Support for a game client version or another addon |
| `documentation` | README, CurseForge description, repo docs |
| `triage` | Needs a maintainer look |

PR labels also group the release notes (see `.github/release.yml`).

## Milestones

There's one milestone per release, named after its tag (`v1.0.0`). An issue or PR's
milestone is the release it's planned for, and no milestone means not planned yet.
When the tag ships, CI closes the milestone, so each closed milestone lists what went
into that release.

## Branches and pull requests

- Branch from an up-to-date `origin/main` (`git fetch && git switch -c my-change origin/main`), one change per branch.
- Open a PR into `main`, put `Closes #N` in the description, and set a label and milestone.
- [luacheck](https://github.com/lunarmodules/luacheck) runs on `EverySetting/` and `tests/` (config in `.luacheckrc`) and must pass.
- The tests must pass: `lua tests/run.lua`. They run outside the game, on any Lua from 5.1 to 5.5.
- `.vscode/settings.json` lists the game's globals for the Lua language server. When your editor adds one, commit it in the same PR as the code that uses it.
- PRs are squash-merged, and the branch is deleted after the merge.

## Translations

Every Setting's own words are in `EverySetting/Locales/enUS.lua`, one line each, by key:
`L["UNDO"] = "Undo"`. The code uses the key (`L.UNDO`), and the tests fail if a word for
people is written anywhere else (`tests/locale_test.lua`). The game's own names for the
settings its options menu has aren't there: they come from the game, in its language
(`Labels.lua`).

`Locales/` has a file for each other language the game ships in (`deDE.lua`, `ruRU.lua`...).
In the repository each holds one line for the packager:

```lua
--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="ignore")@
```

As it builds a release, the packager puts in that line's place the translations on the
CurseForge project's localization page, an `L["KEY"] = "..."` line for each one there. A
word nobody has translated stays in English. So translations are made on that page:

1. The maintainer imports `enUS.lua` there as the English, and again each time it changes:
   on the project's Localization page (under its legacy settings), Import, the format
   **Table Additions**, the language English (US), and every `L["KEY"] = "..."` line of the
   file pasted in. It's already in that form, a line per word.
2. Translators fill in their language on the page.
3. The build that uploads to CurseForge fills the files in (Releasing, step 3). It needs the
   project's ID in the `.toc` and a CurseForge API key. The Release workflow has no key, so
   the zip on the GitHub release has the English only.

A translation keeps:

- each `%s` and `%d` (and `%.1f`), which are filled in as the line is shown. The game
  takes `%2$s` for the second one, where the order of the words has to change.
- each colour, `|cffrrggbb` to `|r`, around the same words, and each `\n`, a new line.
- the commands as they are: `/every apply`, `/console`, `/reload`.

Where a count is said, there's a key for one (`..._ONE`) and one for more. The window was laid
out for English: a name too long for its column is cut short with `...` and shown whole in
its tooltip, and German and Russian run about a third longer.

## Releasing

1. Bump `## Version` in `EverySetting/EverySetting.toc` in a `Release vX.Y.Z` PR. Merge it last,
   after everything else in the milestone.

   In the same PR, write the release's `RANGES.md` again: where each range comes from, and
   what the client kept.

   ```sh
   lua scripts/gen-ranges.lua > RANGES.md
   ```

   It names the addon's version and the game build `data/cvars.lua` is from, so the tests
   fail until it's written again. If the game has updated since that build, save its CVar
   list again first (`scripts/gen-cvars.lua`), then the names of its labels from both
   games' interface code (`scripts/gen-labels.lua`, which reads a checkout of each).
   `data/ranges/README.md` says how results are added.
2. Tag the squash commit on `main` and push the tag:

   ```sh
   git fetch && git tag -a vX.Y.Z -m vX.Y.Z origin/main && git push origin vX.Y.Z
   ```

   The Release workflow runs the [BigWigs packager](https://github.com/BigWigsMods/packager)
   to build `EverySetting-vX.Y.Z.zip` (dev files are excluded by `.pkgmeta`). `RANGES.md` isn't
   excluded: it ships in the zip, beside the addon's files. The raw results in `data/ranges/`
   stay in the repo. It then creates the GitHub release, with notes that list the release's
   PRs, and closes the milestone.
3. Upload to CurseForge. Only the maintainer does this, from their own machine. The
   Release workflow would upload too if the repo had a `CF_API_KEY` secret, but it has
   none, so CI stops at the GitHub release.

   Put `CF_API_KEY=...` in a gitignored `.env` at the repo root, check out the tag, and
   run `scripts/curseforge.sh`. It writes `CHANGELOG.md` (the same PR list as the GitHub
   release), then runs the packager's `scripts/release.sh`, which needs bash 4.3+
   (`brew install bash`). Pass `-d` to build without uploading.

   The upload needs the CurseForge project's ID in the `.toc`, as
   `## X-Curse-Project-ID` (1804075). With it, this
   build fills in `Locales/` from the project's localization page (Translations, above).
   If it stops at "You do not have permission to manage localization on this project",
   the project's localization page has no words yet: import the English (Translations,
   step 1), or pass `-l` to build without the translations.
