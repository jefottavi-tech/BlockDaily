#!/usr/bin/env bash
# Builds the signed Play bundle with an automatic build number (versionCode): the number of
# commits on main, so every upload is higher than the last one. The version name (1.0.0) stays
# in pubspec.yaml. Run from a clean, up-to-date main: tools/build_release.sh
set -euo pipefail
cd "$(dirname "$0")/.."

branch=$(git rev-parse --abbrev-ref HEAD)
[ "$branch" = main ] || { echo "Switch to main first (on $branch)." >&2; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "Commit or stash your changes first." >&2; exit 1; }
git pull --ff-only --quiet
[ -f android/key.properties ] || { echo "android/key.properties is missing: the bundle would be signed with the debug key." >&2; exit 1; }
[ -f android/app/google-services.json ] || { echo "android/app/google-services.json is missing (see README)." >&2; exit 1; }

build=$(git rev-list --count HEAD)
name=$(sed -n 's/^version: *\([^+]*\).*/\1/p' pubspec.yaml)

flutter test
flutter build appbundle --release --build-number="$build"

out="build/app/outputs/bundle/release/block-daily-$name-$build.aab"
cp build/app/outputs/bundle/release/app-release.aab "$out"
echo
echo "Built $out (version $name, build $build)."
echo "Upload it in Play Console › Block Daily › Test and release › Internal testing › Create new release."
