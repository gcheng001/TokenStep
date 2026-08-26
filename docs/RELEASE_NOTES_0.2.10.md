# TokenStep 0.2.10

TokenStep 0.2.10 reworks the plunge approach of the Event Horizon gravity motion so it reads as falling into the black hole rather than the frame drifting upward.

## The pivot now sits on the black hole

- The approach zoom pivot moves from mid-canvas to the hole itself — the event-horizon shadow in the upper-left — making the hole the vanishing point of the dive.
- Every feature streams radially outward from the hole: the right-hand arc, the dominant landmark, swells and rushes past the right edge of the frame; the arc crest flows rightward along the top band (measured +256 px within 6 seconds); the lower arcs sweep out of frame.
- There is no whole-frame translation in any direction; the region that barely moves is the hole itself, because that is what the camera is falling toward.

## Speed and intensity unchanged

- The dive keeps the 0.2.9 rhythm: 9 seconds to full closest approach with a hold at the end, up to 36% scale travel and a 16% brightness swell.
- Frame-diff perceptibility improves to 31.5% of the frame beyond an 8/255 delta within the first 3 seconds and 69.1% across the full dive (0.2.9: 26.9% / 64.0%).

## Compatibility and scope

- Quiet and Orbit modes, the hotspot orbit, the token plunge pulse, and the popover selector are unchanged.
- Classic and Odyssey theme packs are unchanged.
- Token, cost, quota, leaderboard, updater, and local collection behavior are unchanged.

## Validation

- Swift unit suite: 113 tests, 0 failures.
- Deterministic motion-lab renders re-measured at 1800 × 1118; direction verified by patch tracking (crest flows right, right-arc exits the frame by the end of the dive).
- Developer ID signing, Apple notarization, stapling, DMG validation, and isolated installer verification remain release gates.
