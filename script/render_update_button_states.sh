#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SWIFT_DIR="$ROOT_DIR/TokenStepSwift"
BUILD_DIR="$SWIFT_DIR/.build/update-button-render"
OVERLAY_DIR="$BUILD_DIR/vfs-overlay"
OVERLAY_FILE="$OVERLAY_DIR/overlay.yaml"
EMPTY_MODULEMAP="$OVERLAY_DIR/empty.modulemap"
EXECUTABLE="$BUILD_DIR/update-button-render"
OUTPUT_ROOT="${1:-$ROOT_DIR/docs/validation/v0.2.5-popover-model-usage-a2/update-button-states}"

mkdir -p "$BUILD_DIR" "$OVERLAY_DIR" "$OUTPUT_ROOT"
printf '%s\n' '// Intentionally empty.' > "$EMPTY_MODULEMAP"
printf '%s\n' "{\"version\":0,\"roots\":[{\"type\":\"directory\",\"name\":\"/Library/Developer/CommandLineTools/usr/include/swift\",\"contents\":[{\"type\":\"file\",\"name\":\"module.modulemap\",\"external-contents\":\"$EMPTY_MODULEMAP\"}]}]}" > "$OVERLAY_FILE"

SOURCES=()
while IFS= read -r source; do SOURCES+=("$source"); done < <(find "$SWIFT_DIR/Sources/TokenStepSwift" -type f -name '*.swift' ! -path '*/App/TokenStepApp.swift' | sort)

swiftc -D TOKENSTEP_TESTING -target arm64-apple-macos14.0 \
  -vfsoverlay "$OVERLAY_FILE" -Xcc -ivfsoverlay -Xcc "$OVERLAY_FILE" \
  -parse-as-library "${SOURCES[@]}" \
  "$SWIFT_DIR/Tests/Fixtures/MainWindowUpdateStateRender.swift" \
  -o "$EXECUTABLE"

render_state() {
  local name="$1"
  local state="$2"
  local theme="$3"
  local language="$4"
  local test_root
  test_root="$(mktemp -d "${TMPDIR:-/tmp}/tokenstep-update-${name}.XXXXXX")"

  TOKENSTEP_TEST_APP_SUPPORT_ROOT="$test_root/app-support" \
  TOKENSTEP_ICON_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/TokenStepIcon.icns" \
  TOKENSTEP_ODYSSEY_AEGEAN_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyAegeanPopover.png" \
  TOKENSTEP_ODYSSEY_TROJAN_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyTrojanPopover.png" \
  TOKENSTEP_ODYSSEY_ASH_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyAshMarblePopover.png" \
  TOKENSTEP_UPDATE_RENDER_STATE="$state" \
  TOKENSTEP_UPDATE_RENDER_THEME="$theme" \
  TOKENSTEP_UPDATE_RENDER_LANGUAGE="$language" \
  TOKENSTEP_UPDATE_RENDER_PATH="$OUTPUT_ROOT/$name.png" \
    "$EXECUTABLE"

  test -s "$OUTPUT_ROOT/$name.png"
  rm -rf "$test_root"
}

render_state "U1-odyssey-idle-zh-Hans" idle odyssey zh-Hans
render_state "U2-odyssey-checking-zh-Hans" checking odyssey zh-Hans
render_state "U3-odyssey-up-to-date-zh-Hans" up-to-date odyssey zh-Hans
render_state "U4-odyssey-available-zh-Hans" available odyssey zh-Hans
render_state "U5-odyssey-failed-zh-Hans" failed odyssey zh-Hans
render_state "U6-classic-idle-zh-Hans" idle classic zh-Hans
render_state "U7-classic-available-en" available classic en
render_state "U8-odyssey-failed-zh-Hant" failed odyssey zh-Hant

echo "Update button render matrix complete: $OUTPUT_ROOT"
