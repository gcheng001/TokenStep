#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SWIFT_DIR="$ROOT_DIR/TokenStepSwift"
BUILD_DIR="$SWIFT_DIR/.build/popover-panel-render"
OVERLAY_DIR="$BUILD_DIR/vfs-overlay"
OVERLAY_FILE="$OVERLAY_DIR/overlay.yaml"
EMPTY_MODULEMAP="$OVERLAY_DIR/empty.modulemap"
EXECUTABLE="$BUILD_DIR/popover-panel-render"
OUTPUT_DIR="${1:-$ROOT_DIR/docs/validation/v0.2.4-popover-theme-packs}"

mkdir -p "$BUILD_DIR" "$OVERLAY_DIR" "$OUTPUT_DIR"
cat > "$EMPTY_MODULEMAP" <<'EOF'
// Intentionally empty.
EOF
cat > "$OVERLAY_FILE" <<EOF
{"version":0,"roots":[{"type":"directory","name":"/Library/Developer/CommandLineTools/usr/include/swift","contents":[{"type":"file","name":"module.modulemap","external-contents":"$EMPTY_MODULEMAP"}]}]}
EOF

SOURCES=()
while IFS= read -r source; do SOURCES+=("$source"); done < <(find "$SWIFT_DIR/Sources/TokenStepSwift" -type f -name '*.swift' ! -path '*/App/TokenStepApp.swift' | sort)

swiftc -D TOKENSTEP_TESTING -target arm64-apple-macos14.0 -vfsoverlay "$OVERLAY_FILE" -Xcc -ivfsoverlay -Xcc "$OVERLAY_FILE" -parse-as-library "${SOURCES[@]}" "$SWIFT_DIR/Tests/Fixtures/PopoverPanelRender.swift" -o "$EXECUTABLE"

for theme in green voyage; do
  test_root="$(mktemp -d "${TMPDIR:-/tmp}/tokenstep-popover-v024-${theme}.XXXXXX")"
  TOKENSTEP_TEST_APP_SUPPORT_ROOT="$test_root/app-support" \
  TOKENSTEP_ICON_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/TokenStepIcon.icns" \
  TOKENSTEP_ODYSSEY_AEGEAN_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyAegeanPopover.png" \
  TOKENSTEP_ODYSSEY_TROJAN_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyTrojanPopover.png" \
  TOKENSTEP_ODYSSEY_ASH_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyAshMarblePopover.png" \
  TOKENSTEP_ODYSSEY_CHAPTER="${TOKENSTEP_ODYSSEY_CHAPTER:-aegean_mist}" \
  TOKENSTEP_POPOVER_THEME="$theme" \
  TOKENSTEP_POPOVER_RENDER_PATH="$OUTPUT_DIR/${theme}.png" \
  "$EXECUTABLE"
  test -s "$OUTPUT_DIR/${theme}.png"
  rm -rf "$test_root"
done

test_root="$(mktemp -d "${TMPDIR:-/tmp}/tokenstep-popover-v024-voyage-no-rank.XXXXXX")"
TOKENSTEP_TEST_APP_SUPPORT_ROOT="$test_root/app-support" \
TOKENSTEP_ICON_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/TokenStepIcon.icns" \
TOKENSTEP_ODYSSEY_AEGEAN_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyAegeanPopover.png" \
TOKENSTEP_ODYSSEY_TROJAN_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyTrojanPopover.png" \
TOKENSTEP_ODYSSEY_ASH_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyAshMarblePopover.png" \
TOKENSTEP_ODYSSEY_CHAPTER="${TOKENSTEP_ODYSSEY_CHAPTER:-aegean_mist}" \
TOKENSTEP_POPOVER_THEME="voyage" \
TOKENSTEP_POPOVER_RANK="hidden" \
TOKENSTEP_POPOVER_RENDER_PATH="$OUTPUT_DIR/voyage-no-rank.png" \
"$EXECUTABLE"
test -s "$OUTPUT_DIR/voyage-no-rank.png"
rm -rf "$test_root"
