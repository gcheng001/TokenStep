# TokenStep 0.2.8

TokenStep 0.2.8 refines the Event Horizon theme selector icon and fixes its artwork overflowing the preview tile.

## Event Horizon icon refinement

- Rebuilds the theme selector preview around a centered event horizon, a thin accretion disk, and upper and lower gravitational-lensing arcs.
- Keeps every visual element inside the 58 × 48 point preview safe area.
- Adds rounded-rectangle clipping so glow and stroke effects cannot escape the tile boundary.
- Uses a restrained pearl-ivory and champagne gradient instead of the previous oversized bright band.

## Compatibility and scope

- The main Event Horizon artwork and motion in the popover, dashboard, and other interfaces are unchanged.
- Classic and Odyssey theme packs are unchanged.
- Token, cost, quota, leaderboard, updater, and local collection behavior are unchanged.

## Validation

- Swift unit suite: 107 tests, 0 failures.
- Deterministic Settings render checked at 1840 × 1904 pixels.
- Developer ID signing, Apple notarization, stapling, DMG validation, and isolated installer verification remain release gates.
