## 0.0.1

* TODO: Describe initial release.

## 1.0.0

1. **Added Example for Plugin Usage**
   - Included a comprehensive usage example to help developers integrate and use the plugin easily in their projects.

2. **Improved Documentation**
   - Added detailed DartDoc comments for all methods and classes.
   - Improved explanations for better clarity on functionality, parameters, return values, and platform-specific behaviors.

3. **Updated `getAssetPackPath` Method**
   - Introduced a new required parameter `fileExtension` to specify the file type when fetching the asset pack path. This ensures assets are correctly identified and fetched.

## 1.1.0
   - Improve the script for adding the necessary code for Android

## 1.2.0

Nothing in this release is breaking. The previous status API keeps working
exactly as it did in 1.1.0; it is now deprecated and will be removed in 2.0.0.

### Added

- **`AssetDelivery.watchAssetPackStatus(name)`** — a typed `Stream` of
  `AssetPackStatusUpdate`, replacing the callback-based status API.
  - Updates are **filtered by asset pack**, so several packs can be tracked
    at once without their events being mixed together.
  - **Multiple listeners are supported.** The old API was backed by a
    `MethodChannel` handler, which allowed only one listener at a time — a
    second caller silently replaced the first.
  - Carries `name`, `status`, `downloadProgress`, `bytesDownloaded`,
    `totalBytesToDownload` and `errorCode`.
- **`AssetPackStatus` enum** replaces the free-form status strings, with the
  failure reason moved out of the message into a separate `errorCode` field.
- `AssetPackStatus.isTerminal`, for deciding when to stop listening.
- iOS now reports `completed` and `failed`; previously it only ever emitted
  download progress and never signalled that a tag had finished.
- `AssetDelivery.getInstallTimeAssetBytes(path)` for reading install-time
  packs, which are fused into the APK rather than stored as a pack location.
  (Android only. Contributed by @VividSoda.)

### Deprecated

Each of these still behaves exactly as in 1.1.0, and will be removed in 2.0.0:

- `AssetDelivery.getAssetPackStatus(callback)` — use `watchAssetPackStatus`.
  It is now implemented on top of the new stream, with its payload translated
  back to the old format, including the quirks: Android continues to report
  completion as `100.0` and transferring as `0.99`, and continues to send
  `'DOWNLOADING'` where iOS sends `'downloading'`.
- `StatusMap` — use `AssetPackStatusUpdate`.
- `MethodChannelAssetDelivery.onStatusChange` — never emitted anything.

### Fixed

- Progress no longer becomes `NaN` for a pack that is already on the device.
  The native side divided bytes-downloaded by a total of zero.
- `COMPLETED` reported progress as `100.0` on Android while every other state
  used a `0.0`–`1.0` fraction. The new API always reports `1.0`; the
  deprecated API keeps the old value. (Contributed by @VividSoda.)
- `WAITING_FOR_WIFI` was not handled on Android and produced no update.
  (Contributed by @VividSoda.)
- `AssetPackStateListener` had no `package` declaration and was imported from
  the default package. (Contributed by @VividSoda.)
- A malformed or partial status payload no longer throws, which previously
  tore down the stream for every listener.
- iOS: the `NSBundleResourceRequest` was held in a local and could be released
  while the download was still in flight.
- iOS: requesting a pack with a count of `0` crashed on an empty range.
- `setup_asset_pack` generated `assetPacks += listOf(myPack)` for Kotlin DSL
  projects — an unquoted identifier that fails to compile — and wrote Groovy
  array syntax into `build.gradle.kts` when a project mixed the two dialects.
- `setup_asset_pack` now accepts a delivery type argument
  (`on-demand`, `install-time`, `fast-follow`) and supports `.kts` build
  files. (Contributed by @VividSoda.)

### Changed

- Android Gradle Plugin raised to 8.2.1. Flutter 3.35+ requires at least
  8.1.1, and AGP below 8.2.1 cannot build under Java 21.