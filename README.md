# Starfall

Starfall is an MS-DOS game written by Mark Porter in 1986, with documentation and artwork by Jeanne Barnett and Susan Gager, guidance and design overview from John Stevens, and support from Professor Charles Howerton. This repository focuses on the native macOS port; the original 1986 DOS source, binaries, and run instructions live in [`orig1986/README.md`](orig1986/README.md).

## Native macOS app

On macOS 14 or later, with a Swift 6 toolchain:

```sh
./scripts/build-macos.sh
open build/Starfall.app
```

Choose **New World…** to generate a new planet with the ported 1986 world
generator, **Load Voltar** to continue the original sample colony, or
**Open World…** to load a Starfall world archive. Click the map or use the arrow
keys (Shift moves eight blocks); Space switches between the world and sector
maps. Use **Inspect** to work with the selected block's resources, the **Clock**
menu to fast-forward, and **Save World…** to write a Pascal-format world file.

The port bundles the original artwork, resource catalog, Voltar save, help,
and Hall of Fame. The native game supports new world generation, colony trade,
exploration, extraction, development, refinement, production, supply links, and
transport. To transport a vehicle, choose **Transport** in the block inspector,
select a mode and vehicle, then **Plot Route**. Use the arrow keys or click
adjacent map blocks to add waypoints, retrace a step to undo it, and
**Dispatch** from a land block.

In **Inspect**, split a stack to set aside equipment or cargo, or combine
matching stacks without moving their linked supplies. **World Inventory** shows
resources by block and can take you directly to that block's inspector.
**Pending Actions** and **World Log** can show the entire world or just the
selected block. Cancel a pending job there to release its equipment and keep
any work already completed. The **Clock** menu also adjusts the simulation rate
in one-minute or one-hour steps.

The original title music plays on the main menu (use **Skip Title Music** to
stop it early). Worlds generated in either the native app or the DOS version can
be opened in both.

Choose **End Game…** to finish the colony and enter your name if the score
qualifies for the Hall of Fame. The app starts with the original leaderboard
and writes new scores to `~/Library/Application Support/Starfall/SCORFILE.DAT`.
To view those scores in DOSBox-X, copy that file to `build/dos/game/SCORFILE.DAT`
(back up any existing DOS scores first), then open the original Hall of Fame.

`macOS/Sources/StarfallCore` holds the archive codecs and colony simulation;
`macOS/Sources/StarfallApp` is the SwiftUI/AppKit interface. The build script
packages the original assets directly from `orig1986/` rather than duplicating
them. Run the Swift tests with `swift test --package-path macOS`.

## 1986 Turbo Pascal vs. Swift

The original 1986 game is **15,539 lines of Turbo Pascal across 100 files** (in `orig1986/source/`). The native macOS port is **3,480 lines of Swift across 14 files**, plus **902 lines of tests across 5 files** — roughly a quarter the size of the original app code.

The difference comes mostly from what a 1986 MS-DOS program had to build by hand that modern macOS frameworks and Swift's standard library provide out of the box:

- **Screen drawing, windows, and menus:** Turbo Pascal had no GUI toolkit, so the original drew CGA graphics, text boxes, pop-up windows, cursor movement, and keyboard-driven menus manually. SwiftUI and AppKit handle layout, controls, menus, and dialogs declaratively.
- **File handling and memory limits:** The DOS version managed fixed-record binary files, 16-bit memory constraints, and `.0xx` code overlays explicitly across many small `.PAS` modules. Swift's `Data`, value types, and modern memory model eliminate the overlay plumbing and boilerplate.
- **Data structures and standard library:** Manual linked lists, tree/inventory helpers, string/math utilities, and timing loops in Pascal collapse into Swift arrays, dictionaries, and standard library operations.
- **Audio and system integration:** Low-level PC speaker tone loops and raw keyboard polling are replaced by `AVAudioEngine` and standard macOS event handling.

## Repository layout

- `macOS/` — Native Swift 6 macOS app (`StarfallCore` simulation/codecs, `StarfallApp` SwiftUI/AppKit UI, and `StarfallCoreTests`).
- `scripts/` — Helper scripts to build the macOS app (`build-macos.sh`) and run the original DOS game (`run-dos.sh`).
- `.github/workflows/macos.yml` — macOS CI workflow (tests, app build, and codesign verification).
- `orig1986/` — Archived 1986 MS-DOS original (Turbo Pascal source, shipped `.COM` binaries and overlays, utilities, data files, and WordStar docs). See [`orig1986/README.md`](orig1986/README.md) for full details.

## Running the original 1986 DOS game

To run the original DOS binary in DOSBox-X (or another DOSBox via `DOSBOX=...`),
run `./scripts/run-dos.sh` from the repository root. See
[`orig1986/README.md`](orig1986/README.md) for DOSBox instructions, original
RAM-disk setup notes, and the 1986 disk layout.
