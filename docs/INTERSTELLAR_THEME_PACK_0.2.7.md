# TokenStep 0.2.7 “Event Horizon” theme implementation

## Product identity

Public theme name: **引力边界 / Event Horizon**.

“Gargantua” and *Interstellar* were used only as research and design references. The shipping theme uses an original name, original generated artwork, TokenStep typography, and a custom event-horizon mark.

## Visual system

- Near-field black-hole shadow extends beyond the upper-left canvas.
- The horizontal accretion disk is wider than 2.4 times the visible shadow diameter.
- A bright ivory gravitational cusp rises near the center.
- The upper lensed arc and thinner inverted lower arc remain visible.
- UI surfaces use graphite glass with stable contrast independent of the image.
- Theme accents are pearl ivory, cream, and restrained champagne; synchronization success is the only persistent green status signal.

## Production assets

- `TokenUsageMenuApp/assets/interstellar/InterstellarEventHorizonHero.png`
- `TokenUsageMenuApp/assets/interstellar/InterstellarEventHorizonQuiet.png`

The hero plate is used for the popover, Today, Token Island, and share surfaces. The quiet plate is used for denser settings, history, privacy, update, and reduced-motion contexts.

## Motion

The image remains the semantic baseline; all data and progress are understandable with motion disabled. A lightweight SwiftUI overlay adds:

- a 36-second accretion-flow phase drift;
- low-amplitude cusp breathing;
- a secondary thin-band drift;
- a 24 fps ceiling.

Motion is disabled for deterministic screenshots, macOS Reduce Motion, and inactive window surfaces.

## Interface coverage

- Horizontal menu-bar popover and compact/expanded data states
- Today dashboard
- History
- Privacy
- Settings, including the three-pack selector
- Update window and download progress
- Token Island collapsed and expanded states
- Daily and rhythm share cards

## Theme storage and migration

- New stored theme value: `event_horizon`
- Theme pack: `interstellar` internally, shown as “引力边界” in the product
- Classic palette and Odyssey chapter remain independently remembered
- Older settings without the new value decode unchanged

## Copyright boundary

The release bundles no official poster, film frame, logo, actor likeness, spacecraft, robot, quote, or movie typeface. The black-hole structure follows general scientific visualization features; the final plates are original generated assets.
