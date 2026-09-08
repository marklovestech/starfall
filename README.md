# Starfall

Starfall is an MS-DOS game written by Mark Porter in 1986, with documentation and artwork by Jeanne Barnett and Susan Gager, guidance and design overview from John Stevens, and support from Professor Charles Howerton.

## Repository layout

- `product-build/` — Shipped binaries, overlay files, data files, and the original `READ.ME`.
- `source/` — Pascal source code (`.PAS`).
- `utils/` — Utility programs and tools (graphics editor, world shaker, list utility, etc.).
- `docs/` — Manual, charts, and specification documents.
- Root-level `.COM` and `.DAT` files — Original disk contents, including the installer (`INSTALL.COM`), help files (`HELPFILE.DAT`, `HELPINDX.DAT`), and graphics editor (`GRAFEDIT`).

## Running the game

From the original `product-build/READ.ME`:

1. Run `INSTALL.COM` and configure a RAM disk (128K minimum).
2. Run `STARFALL.COM`.

Starfall loads the overlay files (`PLAYGAME.0xx`) and data files (`RESOURCE.DAT`, `VOLTAR.DAT`, etc.) automatically, so there is no need to copy the overlays to the RAM disk.

## Original disk contents (from `product-build/READ.ME`)

- **Disk 1** — Binary `.COM` images and overlay files. These are the programs that are actually run; the only one the user normally runs directly is `STARFALL.COM`.
- **Disk 2** — Data files for the simulation, including help files, matrix files, and resource information.
- **Disk 3** — `VOLTAR.DAT`, a sample world that has already been started.
