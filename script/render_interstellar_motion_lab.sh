#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SWIFT_DIR="$ROOT_DIR/TokenStepSwift"
BUILD_DIR="$SWIFT_DIR/.build/interstellar-motion-lab-render"
OVERLAY_DIR="$BUILD_DIR/vfs-overlay"
OVERLAY_FILE="$OVERLAY_DIR/overlay.yaml"
EMPTY_MODULEMAP="$OVERLAY_DIR/empty.modulemap"
EXECUTABLE="$BUILD_DIR/interstellar-motion-lab-render"
OUTPUT_DIR="${1:-$ROOT_DIR/docs/validation/v0.2.9-motion-lab}"

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

render_frame() {
  local mode="$1"
  local time="$2"
  local pulse_start="$3"
  local name="$4"
  local test_root
  test_root="$(mktemp -d "${TMPDIR:-/tmp}/tokenstep-motion-lab-${mode}.XXXXXX")"

  TOKENSTEP_TEST_APP_SUPPORT_ROOT="$test_root/app-support" \
  TOKENSTEP_ICON_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/TokenStepIcon.icns" \
  TOKENSTEP_ODYSSEY_AEGEAN_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyAegeanPopover.png" \
  TOKENSTEP_ODYSSEY_TROJAN_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyTrojanPopover.png" \
  TOKENSTEP_ODYSSEY_ASH_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyAshMarblePopover.png" \
  TOKENSTEP_INTERSTELLAR_HERO_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/interstellar/InterstellarEventHorizonHero.png" \
  TOKENSTEP_INTERSTELLAR_QUIET_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/interstellar/InterstellarEventHorizonQuiet.png" \
  TOKENSTEP_INTERSTELLAR_MOTION_LAB=1 \
  TOKENSTEP_INTERSTELLAR_MOTION_MODE="$mode" \
  TOKENSTEP_INTERSTELLAR_PREVIEW_TIME="$time" \
  TOKENSTEP_INTERSTELLAR_PREVIEW_PULSE_START="$pulse_start" \
  TOKENSTEP_POPOVER_THEME="event_horizon" \
  TOKENSTEP_POPOVER_RENDER_PATH="$OUTPUT_DIR/$name.png" \
  "$EXECUTABLE"

  test -s "$OUTPUT_DIR/$name.png"
  rm -rf "$test_root"
}

render_frame quiet 0 -10 quiet-00
render_frame quiet 6 -10 quiet-06
render_frame orbit 0 -10 orbit-00
render_frame orbit 2 -10 orbit-02
render_frame orbit 4 -10 orbit-04
render_frame orbit 6 -10 orbit-06
render_frame gravity_tide 0 -10 tide-dolly-000
render_frame gravity_tide 3 -10 tide-dolly-003
render_frame gravity_tide 6 -10 tide-dolly-006
render_frame gravity_tide 9 -10 tide-dolly-009
render_frame gravity_tide 0.35 0 tide-pulse-035
render_frame gravity_tide 0.70 0 tide-pulse-070

echo "Interstellar Motion Lab frames: $OUTPUT_DIR"
