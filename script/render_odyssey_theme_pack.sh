#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_ROOT="${1:-$ROOT_DIR/docs/validation/v0.2.4-odyssey-theme-pack}"
EXECUTABLE="$ROOT_DIR/TokenStepSwift/.build/voyage-interface-render/voyage-interface-render"

mkdir -p "$OUTPUT_ROOT"

TOKENSTEP_ODYSSEY_CHAPTER=directors_cut \
  "$ROOT_DIR/script/render_voyage_interfaces.sh" "$OUTPUT_ROOT/directors_cut"

for chapter in aegean_mist trojan_inferno ash_marble; do
  test_root="$(mktemp -d "${TMPDIR:-/tmp}/tokenstep-odyssey-v024-${chapter}.XXXXXX")"
  mkdir -p "$OUTPUT_ROOT/$chapter"
  TOKENSTEP_TEST_APP_SUPPORT_ROOT="$test_root/app-support" \
  TOKENSTEP_ICON_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/TokenStepIcon.icns" \
  TOKENSTEP_ODYSSEY_AEGEAN_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyAegeanPopover.png" \
  TOKENSTEP_ODYSSEY_TROJAN_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyTrojanPopover.png" \
  TOKENSTEP_ODYSSEY_ASH_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyAshMarblePopover.png" \
  TOKENSTEP_ODYSSEY_CHAPTER="$chapter" \
  TOKENSTEP_VOYAGE_RENDER_DIR="$OUTPUT_ROOT/$chapter" \
    "$EXECUTABLE"
  rm -rf "$test_root"
done

classic_root="$(mktemp -d "${TMPDIR:-/tmp}/tokenstep-classic-v024.XXXXXX")"
mkdir -p "$OUTPUT_ROOT/classic"
TOKENSTEP_TEST_APP_SUPPORT_ROOT="$classic_root/app-support" \
TOKENSTEP_ICON_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/TokenStepIcon.icns" \
TOKENSTEP_ODYSSEY_AEGEAN_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyAegeanPopover.png" \
TOKENSTEP_ODYSSEY_TROJAN_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyTrojanPopover.png" \
TOKENSTEP_ODYSSEY_ASH_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyAshMarblePopover.png" \
TOKENSTEP_THEME_PACK=classic \
TOKENSTEP_ODYSSEY_CHAPTER=directors_cut \
TOKENSTEP_VOYAGE_RENDER_DIR="$OUTPUT_ROOT/classic" \
  "$EXECUTABLE"
rm -rf "$classic_root"

for chapter in directors_cut aegean_mist trojan_inferno ash_marble; do
  test -s "$OUTPUT_ROOT/$chapter/popover.png"
  test -s "$OUTPUT_ROOT/$chapter/main-today.png"
  test -s "$OUTPUT_ROOT/$chapter/settings-general.png"
  test -s "$OUTPUT_ROOT/$chapter/share-daily.png"
done


test -s "$OUTPUT_ROOT/classic/popover.png"
test -s "$OUTPUT_ROOT/classic/main-today.png"
test -s "$OUTPUT_ROOT/classic/settings-general.png"
