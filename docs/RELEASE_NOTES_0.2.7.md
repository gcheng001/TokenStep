# TokenStep 0.2.7

TokenStep 0.2.7 adds the complete “Event Horizon” black-hole skin pack and makes update checks resilient to GitHub API rate limits.

## New: Event Horizon skin pack

- Adds a third theme pack beside Classic and Odyssey.
- Uses an original close-up event-horizon composition with a monumental black-hole shadow, ivory accretion disk, upper gravitational lensing arc, and dimmer inverted lower arc.
- Applies the skin to the popover, Today, History, Privacy, Settings, update window, Token Island, and daily/rhythm share cards.
- Switches the in-app TokenStep mark to an event-horizon/accretion-disk mark while the theme is active.
- Uses restrained graphite, midnight blue, pearl ivory, cream, and muted champagne; green remains reserved for synchronization success.
- Adds a 24 fps maximum ambient layer with slow phase drift and cusp breathing.
- Pauses motion while rendering screenshots, when the window is inactive, and when macOS Reduce Motion is enabled.

## Update reliability

- Falls back from the GitHub Releases API to GitHub’s public latest-release redirect when the API is rate-limited or temporarily unavailable.
- Constructs the official versioned DMG URL from the resolved stable release tag.
- Adds a 10-second cooldown to repeated manual checks so rapid clicks cannot consume the anonymous API quota or leave a spinner appearing stuck.
- Shows a specific rate-limit recovery message if both channels fail.
- Keeps the existing signed/notarized DMG verification, replacement, and automatic relaunch flow.

## Compatibility and privacy

- Existing Classic and Odyssey choices continue to decode unchanged.
- The Event Horizon choice is stored as a dedicated theme value and survives settings round-trips.
- Token, cost, quota, leaderboard, and local collection semantics are unchanged.
- The bundled artwork is original and contains no movie logo, actor, still, spacecraft, or third-party watermark.

## Validation

- Swift unit suite, including theme migration, motion policy, update fallback, cooldown, and update presentation tests.
- Deterministic renders for all major Event Horizon interfaces.
- App bundle resource check for both hero and quiet artwork.
- Signed DMG, Developer ID verification, Apple notarization, and installer verification are release gates.
