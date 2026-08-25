#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_ROOT="${1:-$ROOT_DIR/docs/validation/v0.2.5-popover-model-usage-a2/renders}"
EXECUTABLE="$ROOT_DIR/TokenStepSwift/.build/popover-panel-render/popover-panel-render"

mkdir -p "$OUTPUT_ROOT"
"$ROOT_DIR/script/render_popover_panel.sh" "$OUTPUT_ROOT/_compile-smoke"

render_case() {
  local name="$1"
  local theme="$2"
  local fixture="$3"
  local chapter="$4"
  local rank="$5"
  local quotas="$6"
  local language="$7"
  local update_state="${8:-idle}"
  local test_root
  test_root="$(mktemp -d "${TMPDIR:-/tmp}/tokenstep-a2-${name}.XXXXXX")"

  TOKENSTEP_TEST_APP_SUPPORT_ROOT="$test_root/app-support" \
  TOKENSTEP_ICON_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/TokenStepIcon.icns" \
  TOKENSTEP_ODYSSEY_AEGEAN_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyAegeanPopover.png" \
  TOKENSTEP_ODYSSEY_TROJAN_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyTrojanPopover.png" \
  TOKENSTEP_ODYSSEY_ASH_ART_PATH="$ROOT_DIR/TokenUsageMenuApp/assets/odyssey/OdysseyAshMarblePopover.png" \
  TOKENSTEP_ODYSSEY_CHAPTER="$chapter" \
  TOKENSTEP_POPOVER_THEME="$theme" \
  TOKENSTEP_POPOVER_FIXTURE="$fixture" \
  TOKENSTEP_POPOVER_RANK="$rank" \
  TOKENSTEP_POPOVER_QUOTAS="$quotas" \
  TOKENSTEP_POPOVER_LANGUAGE="$language" \
  TOKENSTEP_POPOVER_UPDATE_STATE="$update_state" \
  TOKENSTEP_POPOVER_RENDER_PATH="$OUTPUT_ROOT/$name.png" \
    "$EXECUTABLE"

  test -s "$OUTPUT_ROOT/$name.png"
  local width
  width="$(/usr/bin/sips -g pixelWidth "$OUTPUT_ROOT/$name.png" | /usr/bin/awk '/pixelWidth/ {print $2}')"
  test "$width" = "1800"
  rm -rf "$test_root"
}

render_case "V1-odyssey-trojan-models6" voyage models6 trojan_inferno visible visible zh-Hans
render_case "V2-classic-models5-no-optional-columns" green classic4 directors_cut hidden hidden zh-Hans
render_case "V3-odyssey-waiting-model-details" voyage waiting trojan_inferno hidden visible zh-Hans
render_case "V4-classic-zero-total" green zero directors_cut hidden hidden zh-Hans
render_case "V5-odyssey-long-names-large-values" voyage long trojan_inferno visible visible zh-Hans
render_case "V6-odyssey-english-dense" voyage english trojan_inferno visible visible en
render_case "V7-odyssey-five-agent-sources" voyage agents5 trojan_inferno visible visible zh-Hans
render_case "V8-odyssey-traditional-models6" voyage models6 trojan_inferno visible visible zh-Hant
render_case "V9-odyssey-update-available" voyage standard trojan_inferno hidden visible zh-Hans available
render_case "V10-classic-update-checking" green classic4 directors_cut hidden hidden zh-Hans checking

echo "A2 popover render matrix complete: $OUTPUT_ROOT"
