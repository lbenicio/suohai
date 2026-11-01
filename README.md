# Suohai

Audio input/output source locking tool for macOS.

## Installation

Check the [GitHub Releases](https://github.com/lbenicio/suohai/releases) page for published builds. To build a local app and disk image, run `make dmg`, open `.build/Suohai.dmg`, and drag `Suohai.app` into Applications.

No Developer ID identity is used and the app is not notarized. Swift's linker adds a local ad-hoc signature to the executable (with no signing Team ID). macOS may warn or block the downloaded app; only open it if you trust the source, or build it yourself from this repository.

## Build

Requires macOS 27 or later and Swift 6.4 or later.

- `make build` builds the package executable.
- `make test` runs the unit tests.
- `make run` runs the menu bar app from the package.
- `make pkg` creates `.build/Suohai.app`.
- `make dmg` creates `.build/Suohai.dmg` with the app and license notices.
- `make clean` removes SwiftPM build artifacts and generated app/disk-image bundles.

The app does not choose a hard-coded device. It changes system audio defaults when you choose a device and reapplies a previously selected lock at startup. Selected device IDs are stored locally in `UserDefaults`; the app does not capture audio or send data over the network.

## Security

Please report suspected vulnerabilities privately to [hi@lbenicio.dev](mailto:hi@lbenicio.dev), following [SECURITY.md](SECURITY.md).

## Credit


- Maintained by [Leonardo Benicio](https://github.com/lbenicio) ([hi@lbenicio.dev](mailto:hi@lbenicio.dev)).

## License

This project is licensed under the [GNU General Public License v3.0 only](LICENSE.txt).
