# Zig Roulette

<p align="center">
  <img src="assets/logo.svg" alt="Zig Roulette logo" width="220">
</p>

Zig Roulette is a native GTK4/libadwaita desktop roulette game written in Zig. It implements a European roulette table with a drawn wheel, clickable betting areas, session balance, active bets, result history, and unit-tested payout logic.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Commands](#commands)
- [Testing](#testing)
- [Desktop Metadata](#desktop-metadata)
- [License](#license)

## Overview

The app is a small native casino game for Linux desktops. The UI uses GTK4/libadwaita, while the roulette rules live in a separate Zig module so payout behavior can be tested without launching the GUI.

Supported roulette bets:

- Straight number: `0-36`
- Color: red or black
- Parity: even or odd
- Dozens: `1-12`, `13-24`, `25-36`
- Columns: `COL 1`, `COL 2`, `COL 3`

## Features

- European roulette wheel drawn with Cairo
- Clickable betting table
- Direct bet placement from table clicks
- Session balance starting at `1000` credits
- Active bet list and result history
- Last-bet undo button
- Reset balance button
- Dark casino-style GTK theme
- SVG logo, rendered PNG icon variants, and Linux `.desktop` launcher metadata
- Unit tests for core game rules

## Tech Stack

- Zig `0.16.0`
- GTK4
- libadwaita
- GLib/GObject
- Cairo drawing through GTK

## Prerequisites

Install Zig and the GTK development packages.

Fedora:

```bash
sudo dnf install zig gtk4-devel libadwaita-devel pkgconf-pkg-config
```

Ubuntu/Debian:

```bash
sudo apt install zig libgtk-4-dev libadwaita-1-dev pkg-config
```

The project was validated locally with:

- Zig `0.16.0`
- GTK `4.22.4`
- libadwaita `1.9.1`

## Installation

Build the project:

```bash
zig build
```

Install to the default Zig prefix:

```bash
zig build install
```

Install to a custom prefix:

```bash
zig build install --prefix ~/.local
```

This installs:

- `bin/zig-roulette`
- `share/applications/dev.instazdll.ZigRoulette.desktop`
- `share/icons/hicolor/scalable/apps/dev.instazdll.ZigRoulette.svg`
- `share/icons/hicolor/<size>x<size>/apps/dev.instazdll.ZigRoulette.png` for `16`, `32`, `48`, `64`, `128`, `256`, and `512`

## Usage

Run from the source tree:

```bash
zig build run
```

After installation:

```bash
zig-roulette
```

Gameplay flow:

1. Choose a bet amount.
2. Click a zone on the roulette table to add that bet.
3. Add more bets, repeat the selected bet, or undo the last bet if needed.
4. Press `Lancer`.
5. Read the result, updated balance, and history in the right panel.

## Project Structure

```text
.
├── assets/
│   ├── icons/
│   └── logo.svg
├── data/
│   └── dev.instazdll.ZigRoulette.desktop
├── src/
│   ├── game.zig
│   └── main.zig
├── build.zig
├── build.zig.zon
└── README.md
```

## Commands

```bash
zig build        # Compile the application
zig build run    # Run the GTK app
zig build test   # Run unit tests for roulette logic
zig fmt src/*.zig build.zig
```

## Testing

The tests cover core roulette behavior in `src/game.zig`:

- Straight number payout
- Zero losing color/parity bets
- Dozen and column payouts
- Invalid and over-balance bets
- Undoing the last active bet
- Balance reset behavior

Run them with:

```bash
zig build test
```

## Desktop Metadata

The project includes:

- `assets/logo.svg`
- `assets/icons/logo-*.png`
- `data/dev.instazdll.ZigRoulette.desktop`

The build installs the SVG and PNG icon variants using the app id `dev.instazdll.ZigRoulette`, so desktop menus can resolve the icon after installation.

## License

Licensed under the European Union Public Licence v1.2. See [LICENSE](LICENSE).
