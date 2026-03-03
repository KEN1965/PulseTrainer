# PulseTrainer

PulseTrainer is an iOS training app that reproduces pulse palpation patterns with haptics.

## App Store
- [PulseTrainer on the App Store (Japan)](https://apps.apple.com/jp/app/%E3%83%91%E3%83%AB%E3%82%B9%E3%83%88%E3%83%AC%E3%83%BC%E3%83%8A%E3%83%BC/id1228463311)

## Screenshots
Add your screenshots under `docs/screenshots/`, then update this section if needed.

![Home](docs/screenshots/home.png)
![Measurement](docs/screenshots/measurement.png)
![Set Data](docs/screenshots/set-data.png)

## Features
- Home screen with quick navigation
- Pulse measurement screen (`START/STOP`) with black-screen playback
- Double-tap to stop during playback
- Pulse strength mode: `Pulse (Normal)` / `Pulse (Weak)`
- Arrhythmia simulation:
  - `Arrhythmia (PVC)`
  - `Arrhythmia (AF)`
- Settings sheet for arrhythmia parameters
- Set Data workflow:
  - Create and save pulse sets
  - Play saved sets in full-screen black playback
  - Swipe-to-delete on saved rows
- AdMob banner placements:
  - Home bottom
  - Set Data screen
  - Measurement screen bottom
- Localization:
  - English (base)
  - Japanese
  - Portuguese
  - Spanish
  - Korean
  - Chinese (Simplified)
  - Chinese (Traditional)

## Tech Stack
- SwiftUI
- CoreHaptics
- GoogleMobileAds (SPM)

## Requirements
- Xcode 15+
- iOS 17+
- Real device recommended for haptics validation

## Project Setup
1. Open `PulseTrainer.xcodeproj`.
2. Make sure SPM dependencies resolve.
3. Confirm plist file is set to `AppInfo.plist` in target build settings.
4. Build and run on a physical iPhone.

## AdMob Setup
This project includes test ad unit IDs by default.

1. Open `AppInfo.plist` and set:
- `GADApplicationIdentifier` to your AdMob App ID
2. Update ad unit IDs in `ContentView.swift`:
- `AdMobConfig.homeBottomUnitID`
- `AdMobConfig.setDataUnitID`
- `AdMobConfig.measurementBottomUnitID`

## Notes
- Haptic feel can vary by device model and iOS runtime state.
- For App Store release, replace all test ad IDs with production IDs.
