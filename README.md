# Asset Delivery Plugin for Flutter

## Introduction

The **Asset Delivery Plugin** simplifies managing **on-demand asset delivery** in Flutter applications. It integrates with Play Asset Delivery (Android) and On-Demand Resources (iOS), enabling dynamic asset downloads and seamless user experiences.

### Key Features
- **On-Demand Asset Delivery:** Download and access assets dynamically at runtime.
- **Customizable Resource Management:** Flexible naming patterns and ranges for asset files.
- **Progress Tracking:** Real-time download progress updates.
- **Cross-Platform Support:** Compatible with both Android and iOS.

---

## Installation

Add the following line to your `pubspec.yaml` file:
```yaml
dependencies:
  asset_delivery: 
    git:
      url: https://github.com/mohsen-motlagh/asset_delivery.git
      ref: main

flutter:
  generate: true      
```

## Setup

### Android

#### Minimum SDK Version: 24

1. Add the Play Asset Delivery library to your Gradle file:
    ```gradle
    implementation "com.google.android.play:asset-delivery:2.2.2"
    ```

2. Run the setup command in the terminal:
    ```bash
    dart run asset_delivery:setup_asset_pack "YourAssetPackName"
    ```

3. A folder named after your asset pack will be created, containing:
    - A `build.gradle.kts` file.
    - A `manifest` folder with an `AndroidManifest.xml` file.

4. Add your assets in the following path:
    ```bash
    ProjectDirectory/Android/YourAssetFolder/src/main/assets/"PUT YOUR ASSETS IN THIS DIRECTORY"
    ```

5. Once published to the Play Store, you can retrieve assets dynamically. To test before publishing, follow the **Testing** steps below.

6. For multiple asset packs, repeat these steps for each asset pack.

---

### Android Testing
## This method of testing is only available for Android versions below 12. Alternatively, you can publish your app to the Google Play Store for internal testing.

1. Download the [BundleTool](https://github.com/google/bundletool/releases).

2. Build your app bundle and use the following commands:

    - **Generate the APKs:**
        ```bash
        java -jar bundletool.jar build-apks --bundle=<your_app_project_dir>/build/app/outputs/bundle/release/app-release.aab --output=<your_temp_dir>/app.apks --local-testing
        ```

    - **Install the APKs on your device:**
        ```bash
        java -jar bundletool.jar install-apks --apks=<your_temp_dir>/app.apks
        ```

3. To get the final APK size:
    ```bash
    java -jar bundletool.jar get-size total --apks=<your_temp_dir>/app.apks --dimensions=SDK
    ```

---

### iOS

1. Open Xcode and navigate to your **Runner** project.

2. Add your assets to the **Assets** folder.

3. Configure the asset pack:
    - Select the asset or folder.
    - In the right panel, find **On-Demand Resource Tags** under the settings icon.
    - Add your **Asset Pack Name** (this should match the name used for Android).

4. Ensure all assets are tagged appropriately.

---

### iOS Testing

You can test your iOS app by running it from Xcode on a real device or simulator, as well as using flutter run --release.

## Usage

All methods on `AssetDelivery` are **static** — there is no instance to create.

### 1. Track download status

Subscribe *before* calling `fetch`, so no early updates are missed. The stream
is filtered by asset pack, so several packs can be tracked independently, and
any number of listeners can subscribe to the same pack.

```dart
import 'package:asset_delivery/asset_delivery.dart';

final subscription =
    AssetDelivery.watchAssetPackStatus('my_asset_pack').listen((update) {
  switch (update.status) {
    case AssetPackStatus.downloading:
      print('${(update.downloadProgress * 100).toStringAsFixed(0)}%');
    case AssetPackStatus.completed:
      print('Ready to use');
    case AssetPackStatus.failed:
      print('Failed with code ${update.errorCode}');
    default:
      break;
  }
});
```

`AssetPackStatusUpdate` carries:

| Field | Description |
| --- | --- |
| `name` | The asset pack (Android) or ODR tag (iOS) this update is about |
| `status` | An `AssetPackStatus` value |
| `downloadProgress` | `0.0`–`1.0`; always `1.0` once completed |
| `bytesDownloaded` | Bytes transferred so far (Android; `0` on iOS) |
| `totalBytesToDownload` | Total size, or `0` when not yet known |
| `errorCode` | Platform error code, set only when `status` is `failed` |

The stream never closes. Cancel the subscription once
`update.status.isTerminal` is true:

```dart
if (update.status.isTerminal) subscription.cancel();
```

`AssetPackStatus` values are `pending`, `downloading`, `transferring`,
`completed`, `failed`, `canceled`, `notInstalled`, `waitingForWifi` and
`unknown`. Only `downloading`, `completed` and `failed` occur on iOS.

### 2. Download assets

```dart
await AssetDelivery.fetch('my_asset_pack');
```

- If the assets are already on the device, the download is skipped.
- On iOS this step is not required; assets are fetched by `getAssetPackPath`.

### 3. Retrieve the asset path

```dart
final path = await AssetDelivery.getAssetPackPath(
  assetPackName: 'my_asset_pack',
  count: 10,
  namingPattern: 'ASSET_%d',
  fileExtension: 'mp3',
);
```

| Parameter | Description |
| --- | --- |
| `assetPackName` | The asset pack name (Android) or ODR tag (iOS) |
| `count` | Number of assets in the pack — **iOS only** |
| `namingPattern` | Naming convention, e.g. `ASSET_%d` — **iOS only** |
| `fileExtension` | File extension, e.g. `mp3` — **iOS only** |

The last three are ignored on Android, where the pack is returned as a
directory. On iOS the assets are enumerated by name and copied out of the
bundle, which is why the count and pattern are needed.

Returns `null` if the path could not be resolved.

### 4. Read an install-time asset (Android)

Install-time packs are fused into the APK rather than stored as a pack
location, so they are read as bytes rather than by path:

```dart
final bytes = await AssetDelivery.getInstallTimeAssetBytes('images/logo.png');
```

---

## Migrating from 1.1.0

`getAssetPackStatus` and `StatusMap` are deprecated and will be removed in
**2.0.0**. They still behave exactly as before, so upgrading to 1.2.0 requires
no changes.

```dart
// Before — one listener only, no way to tell which pack an update was for,
// and status compared against a raw string.
AssetDelivery.getAssetPackStatus((status) {
  if (status['status'] == 'COMPLETED') { /* ready */ }
});

// After
AssetDelivery.watchAssetPackStatus('my_asset_pack').listen((update) {
  if (update.status == AssetPackStatus.completed) { /* ready */ }
});
```

Two differences to be aware of when you migrate:

- The new API reports completion as `downloadProgress == 1.0`. The deprecated
  API reported `100.0` on Android, on a scale where every other value was a
  `0.0`–`1.0` fraction.
- A failure code is now a separate `errorCode` field rather than being
  embedded in the status string as `'Failed: -6'`.

### Example
[Example App](https://github.com/mohsen-motlagh/asset_delivery_example)

### Suppor
Please support the plugin by give a thumbs up in pub.dev and github

### Contributions
Contributions are welcome! Feel free to submit issues or pull requests on GitHub.

### License
This plugin is licensed under the MIT License. See the LICENSE file for details.
