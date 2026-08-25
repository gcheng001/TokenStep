#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SWIFT_DIR="$ROOT_DIR/TokenStepSwift"
BUILD_DIR="$SWIFT_DIR/.build/odyssey-motion-prototype-render"
OVERLAY_DIR="$BUILD_DIR/vfs-overlay"
OVERLAY_FILE="$OVERLAY_DIR/overlay.yaml"
EMPTY_MODULEMAP="$OVERLAY_DIR/empty.modulemap"
EXECUTABLE="$BUILD_DIR/odyssey-motion-prototype-render"
OUTPUT_ROOT="${1:-$ROOT_DIR/docs/validation/v0.2.5-odyssey-motion/g0/particle-previews}"
TROJAN_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyTrojanPopover.png"

mkdir -p "$BUILD_DIR" "$OVERLAY_DIR" "$OUTPUT_ROOT"
test -f "$TROJAN_ART_PATH"
cat > "$EMPTY_MODULEMAP" <<'EOF'
// Intentionally empty.
EOF
cat > "$OVERLAY_FILE" <<EOF
{"version":0,"roots":[{"type":"directory","name":"/Library/Developer/CommandLineTools/usr/include/swift","contents":[{"type":"file","name":"module.modulemap","external-contents":"$EMPTY_MODULEMAP"}]}]}
EOF

SOURCES=()
while IFS= read -r source; do
  SOURCES+=("$source")
done < <(find "$SWIFT_DIR/Sources/TokenStepSwift" -type f -name '*.swift' ! -path '*/App/TokenStepApp.swift' | sort)

swiftc \
  -D TOKENSTEP_TESTING \
  -target arm64-apple-macos14.0 \
  -vfsoverlay "$OVERLAY_FILE" \
  -Xcc -ivfsoverlay \
  -Xcc "$OVERLAY_FILE" \
  -parse-as-library \
  "${SOURCES[@]}" \
  "$SWIFT_DIR/Tests/Fixtures/OdysseyMotionPrototypeRender.swift" \
  -o "$EXECUTABLE"

for mode in automatic cinematic; do
  output_dir="$OUTPUT_ROOT/$mode"
  mkdir -p "$output_dir"
  TOKENSTEP_ODYSSEY_MOTION_MODE="$mode" \
  TOKENSTEP_ODYSSEY_MOTION_RENDER_DIR="$output_dir" \
  TOKENSTEP_ODYSSEY_TROJAN_ART_PATH="$TROJAN_ART_PATH" \
    "$EXECUTABLE"
  test "$(find "$output_dir" -type f -name 'frame-*.png' | wc -l | tr -d ' ')" = "6"
done
