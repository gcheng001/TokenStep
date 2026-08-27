# TokenStep 0.2.11

TokenStep 0.2.11 fixes the one-frame flash that could appear when opening the menu-bar popover with Odyssey's Trojan Inferno chapter selected.

## Fixed

- Keep the Trojan SpriteKit renderer mounted while the popover is hidden, instead of inserting it after the window becomes visible.
- Pause and resume the existing scene with window visibility, preserving the previous background, screenshot, and energy-saving behavior.
- Add regression coverage that separates renderer mounting from animation eligibility.

Token totals, costs, quotas, rankings, collectors, and all other theme chapters are unchanged.
