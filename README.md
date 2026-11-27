# Starfall

Starfall is an MS-DOS game written by Mark Porter in 1986, with documentation and artwork by Jeanne Barnett and Susan Gager, guidance and design overview from John Stevens, and support from Professor Charles Howerton.

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
transport. It uses native controls and automatically routes vehicles to the
chosen destination rather than requiring DOS-style waypoint entry. Title music
and recording new Hall of Fame scores are not yet ported. Worlds generated in
either the native app or the DOS version can be opened in both.

`macOS/Sources/StarfallCore` holds the archive codecs and colony simulation;
`macOS/Sources/StarfallApp` is the SwiftUI/AppKit interface. The build script
packages the original assets directly from the checkout rather than duplicating
them. Run the Swift tests with `swift test --package-path macOS`.

## Repository layout

- `product-build/` — Shipped binaries, overlay files, data files, and the original `READ.ME`.
- `source/` — Pascal source code (`.PAS`).
- `utils/` — Utility programs and tools (graphics editor, world shaker, list utility, etc.).
- `docs/` — Manual, charts, and specification documents.
- Root-level `.COM` and `.DAT` files — Original disk contents, including the installer (`INSTALL.COM`), help files (`HELPFILE.DAT`, `HELPINDX.DAT`), and graphics editor (`GRAFEDIT`).

## Running the original DOS game

Install DOSBox-X and run `./scripts/run-dos.sh`. This stages a writable copy
under `build/dos/`, mounts the overlay directory as drive D, and starts the
original binary. At the title screen press **S**, wait for initialization, then
enter `VOLTAR.DAT` at the filename prompt. Set `STARFALL_DOS_DIR` to keep the
DOS copy and its saves in a different directory.

From the original `product-build/READ.ME`:

1. Run `INSTALL.COM` and configure a RAM disk (128K minimum).
2. Run `STARFALL.COM`.

Starfall loads the overlay files (`PLAYGAME.0xx`) and data files (`RESOURCE.DAT`, `VOLTAR.DAT`, etc.) automatically, so there is no need to copy the overlays to the RAM disk.

## Original disk contents (from `product-build/READ.ME`)

- **Disk 1** — Binary `.COM` images and overlay files. These are the programs that are actually run; the only one the user normally runs directly is `STARFALL.COM`.
- **Disk 2** — Data files for the simulation, including help files, matrix files, and resource information.
- **Disk 3** — `VOLTAR.DAT`, a sample world that has already been started.
