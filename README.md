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
    dart run asset_delivery:setup_asset_pack.dart "YourAssetPackName"
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

1. Download the [BundleTool](https://github.com/google/bundletool/releases).

2. Build your app bundle and use the following commands:

    - **Generate the APKs:**
        ```bash
        java -jar bundletool.jar build-apks \
          --bundle=<your_app_project_dir>/build/app/outputs/bundle/release/app-release.aab \
          --output=<your_temp_dir>/app.apks \
          --local-testing
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

Run your app on a real device from Xcode to test the on-demand resource functionality, just as if it were downloaded from the App Store.

## Usage

1. **Download Assets**  
   On Android devices, download and install assets dynamically using:  
   ```dart
   await assetDelivery.fetch("$assetpackName");

   - If the assets already exist on the device, the download will be skipped automatically.
   - On iOS, this step is not necessary as assets are accessed directly.

2. Track Download Progress
    During the download, track the status of the asset pack by calling:
    ```
    await assetDelivery.getAssetPackStatus();
    ```

3. Retrieve Asset Path    
    Get the local path to the downloaded assets using:
    ```
    final path = await assetDelivery.getAssetPath("$assetpackName");
    ```

### Contributions
Contributions are welcome! Feel free to submit issues or pull requests on GitHub.    

### License
This plugin is licensed under the MIT License. See the LICENSE file for details.