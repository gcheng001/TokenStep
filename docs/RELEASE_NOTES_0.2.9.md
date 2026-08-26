# TokenStep 0.2.9

TokenStep 0.2.9 ships the Gravity Motion Lab: the Event Horizon theme stops being a static poster and gains a real sense of gravity. Opening the popover or the dashboard now drops you toward the black hole.

## Three signature motion modes

A compact selector lives in the popover header next to the sync badge:

- **Quiet**: only a slow ambient breathing over the plate — for people who want the theme essentially still.
- **Orbit**: a white-hot plasma knot with a comet tail orbits along the baked-in lensed arc every 8 seconds, while disk-flow filaments and falling stars ride the visible top band.
- **Plunge** (default): the black hole swells in place around its own structural center — edges rush out of frame, the whole scene brightens by up to 16%, and after 9 seconds the approach holds at its closest point. Closing the popover resets the dive; every open is a fresh approach.

## Token plunge pulse

In Plunge mode, a one-shot feeding wavefront radiates from the event-horizon region when today's token count grows or when the waveform button in the lab selector is pressed.

## Motion stays honest and cheap

- 24 fps ceiling; low-power mode drops to 12 fps and freezes the approach while the hotspot keeps orbiting.
- Fully static for screenshot rendering and macOS Reduce Motion; motion pauses automatically when a window is occluded or closed (surface-visibility gating, not focus state).
- Every frame is sampled from a pure function (`InterstellarMotionSample`), so the render script can produce deterministic frames at fixed timestamps and the validation harness measures frame-to-frame perceptibility: the full plunge changes 64% of the frame beyond an 8/255 delta, with 27% within the first 3 seconds.
- The arc-following hotspot shares the plate's transform exactly, so it never detaches from the disk during the approach.

## Compatibility and scope

- Classic and Odyssey theme packs are unchanged.
- Token, cost, quota, leaderboard, updater, and local collection behavior are unchanged.
- The motion lab graduates from its experimental gate: it ships enabled with the Event Horizon theme, and the selector is part of the popover UI.

## Validation

- Swift unit suite: 113 tests, 0 failures, including approach monotonicity/cap, hotspot periodicity and arc attachment, pulse one-shot bounds, and low-power frame caps.
- Deterministic motion-lab renders at 1800 × 1118 for quiet/orbit/plunge phases, archived with frame-diff metrics under `docs/validation/v0.2.9-motion-lab/`.
- Developer ID signing, Apple notarization, stapling, DMG validation, and isolated installer verification remain release gates.
