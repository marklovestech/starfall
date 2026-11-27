# Starfall (1986 MS-DOS Original)

This directory archives the original 1986 MS-DOS version of **Starfall** written
by Mark Porter in Turbo Pascal 3.0, with documentation and artwork by Jeanne
Barnett and Susan Gager, guidance and design overview from John Stevens, and
support from Professor Charles Howerton.

The native macOS port in `../macOS/` reads the original artwork, resource
catalog, Voltar sample world, help archive, Hall of Fame scores, and title song
directly from this directory rather than duplicating them.

## Contents

- `product-build/` — Shipped DOS `.COM` binaries, overlay files (`.000`–`.010`), data/art files (`RESOURCE.DAT`, `VOLTAR.DAT`, `SCORFILE.DAT`, `STARFALL.PIC`, `SURFMATR.DAT`, `PARMS.DAT`), `READ.ME`, `MADISON.LTR`, and `Starfall install.doc`.
- `source/` — Original Turbo Pascal 3.0 source code (`.PAS`).
- `utils/` — DOS utility binaries (`GRAFEDIT.COM`/`.000`, `MAKEHELP.COM`, `MYLIST.COM`, `WRLDSHAK.COM`/`.000`/`.001`).
- `docs/` — WordStar-encoded documentation (`MANUAL`, `CHARTS`, `SPECS.TXT`).
- Top-level `.COM`, `.000`, and `.DAT` files — Original disk contents, including the installer (`INSTALL.COM`), form-feed printer utility (`FORMFEED.COM`), help files (`HELPFILE.DAT`, `HELPINDX.DAT`), and graphics editor (`GRAFEDIT.COM`, `GRAFEDIT.000`).

## Running the DOS game in DOSBox-X / DOSBox

From the repository root, install DOSBox-X (or set `DOSBOX` to a compatible
DOSBox executable such as `dosbox`) and run:

```sh
./scripts/run-dos.sh
```

This script:

1. Stages a writable copy of the game under `build/dos/game/` and the `PLAYGAME.0*` overlays under `build/dos/overlays/`.
2. Launches DOSBox with `-machine cga` (required so the CGA palette renders terrain properly), mounting `C:` to the game directory and `D:` to the overlay directory.
3. Runs `STARFALL.COM`.

At the title screen press **S**, wait for initialization, then enter
`VOLTAR.DAT` at the filename prompt to load the sample colony. Set
`STARFALL_DOS_DIR` to keep the staged DOS copy and its saves in a different
directory.

## Original MS-DOS instructions (from `product-build/READ.ME`)

1. Run `INSTALL.COM` and configure a RAM disk (128K minimum).
2. Run `STARFALL.COM`.

Starfall loads the overlay files (`PLAYGAME.0xx`) and data files (`RESOURCE.DAT`,
`VOLTAR.DAT`, etc.) automatically, so there is no need to copy the overlays to
the RAM disk.

## Original disk contents (from `product-build/READ.ME`)

- **Disk 1** — Binary `.COM` images and overlay files. These are the programs that are actually run; the only one the user normally runs directly is `STARFALL.COM`.
- **Disk 2** — Data files for the simulation, including help files, matrix files, and resource information.
- **Disk 3** — `VOLTAR.DAT`, a sample world that has already been started.
