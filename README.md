# asset_delivery

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

This plugin give you the option to upload your assets to Play Store alongside the application and download them whenever you need them.
Now we just have the this option functionality in Android but in near future we will have it for IOS as well.

Lets start:

1- Add the plugin to your pubspec.yaml

2- run this command in terminal:
    dart run asset_delivery:setup_asset_pack.dart <assetPackName>
3- Now you should have a folder with the name of thr assset pack you specify in the command, inside the folder you must have a build.gradle.kts file and a folder name manifest and inside that a manifest file.

Now you can retrieve the assets from Play Store after publishing your app to the Play Store, and before that for testing you have another option which we will learn later.

We can download the assets and install them with assetDelivery.fetch("$assetpackName")
    - it can be smart and if its already exist, stop the downloading

during the download we can have the status of the download and installing by calling assetDelivery.    
with assetDelivery.getAssetPath("$assetpackName"), you can get the location of the assets which would be String



