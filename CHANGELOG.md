# Changelog

All notable changes to this repository will be documented in this file.

The format is based on "Keep a Changelog" and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Private vulnerability reporting and CI build/test checks.
- Unit tests for input, output, and duplex audio-device capability handling.

### Changed
- Preserve existing user audio defaults instead of selecting a hard-coded microphone at startup.
- Document that app and DMG builds are not Developer ID-signed or notarized.

## [0.1.0]

### Added
- Swift Package build targeting macOS 27 with Swift 6.4.
- Makefile targets for building, running, packaging the app, and creating a compressed DMG.

### Changed
- Reorganized Swift sources under `src/` and resources under categorized `assets/` directories.
- Use `assets/icons/icon.icns` as the app bundle icon.

### Removed
- Legacy Xcode and CocoaPods project files.
- The unused asset-catalog app icon set, now replaced by `icon.icns`.
