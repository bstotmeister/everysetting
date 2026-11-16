#!/usr/bin/env bash
# Writes CHANGELOG.md for a release tag. The packager uses it as the GitHub release
# body and the CurseForge changelog (manual-changelog in .pkgmeta).
#
# - docs/changelog/<tag>.md, when it exists, is used as written. The first release
#   needs one: a repo that starts from a single commit has no PRs to list.
# - Otherwise it's GitHub's generated release notes: the PRs since the previous tag,
#   grouped by label (.github/release.yml), or every PR when there's no earlier tag.
#
# Usage: scripts/changelog.sh [tag]    (default: the tag checked out)
set -euo pipefail
cd "$(dirname "$0")/.."

tag=${1:-$(git describe --tags --exact-match)}

if [ -f "docs/changelog/$tag.md" ]; then
	cp "docs/changelog/$tag.md" CHANGELOG.md
	echo "Wrote CHANGELOG.md for $tag from docs/changelog/$tag.md"
	exit 0
fi

# The tag's commit may be the repo's first, which has no parent to look behind.
prev=$(git describe --tags --abbrev=0 "$tag^" 2>/dev/null || true)
args=(-f tag_name="$tag")
[ -n "$prev" ] && args+=(-f previous_tag_name="$prev")

# Drop GitHub's "generated using" comment, and turn bare PR and compare URLs into
# markdown links, since CurseForge doesn't link bare URLs.
gh api "repos/{owner}/{repo}/releases/generate-notes" "${args[@]}" --jq .body \
	| sed -E \
		-e '/^<!--.*-->$/d' \
		-e 's|https://github\.com/[^ ]+/pull/([0-9]+)|[#\1](&)|g' \
		-e 's|https://github\.com/[^ ]+/compare/([^ ]+)|[\1](&)|g' \
	| sed '/./,$!d' > CHANGELOG.md

echo "Wrote CHANGELOG.md for $tag (since ${prev:-the first commit})"
