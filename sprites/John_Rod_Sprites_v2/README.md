# John Rod — sprite replacement pack v2

30 individually generated designs, exported as separate transparent PNGs. Each size folder contains 31 files, including one compatibility alias.

## Contents

- `sprites_64/`: 64×64 PNGs matching the frame dimensions documented in GAME_DEV_LOG.md.
- `sprites_128/`: 128×128 versions with more shading detail. These are alternative exports, not additional animation frames.
- `preview.png`: labeled overview on a dark background, for reference only.
- `manifest.json`: filenames, pixel dimensions, visible bounds, and baseline information.

## Pose coverage

| Group | Files |
| --- | --- |
| 0D | point, pulse |
| 1D | rod, rod_active |
| 2D | idle, crouch, jump, land, walk_1–4 |
| 2.5D | idle, front, back, turn, walk_1–2 |
| 3D | front, back, side, iso: idle and walk_1–2 for each view |
| Compatibility | john_rod_idle.png duplicates john_rod_3d_front_idle.png |

## Using the files

Use the individual PNGs from one size folder. The 64×64 folder preserves the documented texture dimensions. Filenames follow the screenshot and dev log. The .png.import files visible in the screenshot are engine metadata, not image assets, and are not included.

Humanoid frames have their lowest visible pixel aligned immediately above y=56 in the 64px export, and y=112 in the 128px export. Point and rod frames are centered. Use the existing player origin and check its vertical placement when replacing the textures.

The source artwork was created with the built-in image generator. Technical export removed the temporary background where needed, preserved native transparency where supplied, and used nearest-neighbor resizing. Backgrounds, head openings and spaces between limbs are genuinely transparent; no green or painted checkerboard remains.

The pack is intentionally simpler than the first chrome sheet: neutral silver, broad highlights, clear head loops, and less reflective noise.

## Validation and limits

All 62 PNGs were checked for correct dimensions, transparency, remaining green pixels, and frame-edge clipping. The overview was visually inspected. The actual Godot project was not supplied, so engine integration and animation timing have not been tested. These are short pose sets, not new eight-direction animation cycles; the 3D filenames cover the four views shown in the screenshot. For 4D rewind, the documented controller replays the existing spatial frames; no separate rewind character is included here.
