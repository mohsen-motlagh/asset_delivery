// ignore_for_file: avoid_print

import 'dart:io';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('Please provide an asset pack name.');
    print('Usage: dart run setup_asset_pack.dart <assetPackName>');
    exit(1);
  }
  final assetPackName = arguments[0];
  final androidDir = Directory('android/$assetPackName');
  final rootDir = Directory.current.path;

  final settingsFile = File('$rootDir/android/settings.gradle');
  if (!settingsFile.existsSync()) {
    print('Error: settings.gradle not found in the Android directory.');
    exit(1);
  }

  final includeStatement = "include ':$assetPackName'";
  final settingsContent = settingsFile.readAsStringSync();
  if (!settingsContent.contains(includeStatement)) {
    settingsFile.writeAsStringSync(
      '$settingsContent\n$includeStatement',
      mode: FileMode.append,
    );
    print('Added "$includeStatement" to settings.gradle.');
  } else {
    print('"$includeStatement" already exists in settings.gradle.');
  }

  if (!androidDir.existsSync()) {
    androidDir.createSync(recursive: true);
    print('Created asset pack directory: $androidDir');

    // Create build.gradle.kts for the asset pack
    final buildGradleFile = File('${androidDir.path}/build.gradle.kts');
    buildGradleFile.writeAsStringSync('''
        plugins {
            id("com.android.asset-pack")
        }

        assetPack {
            packName.set("$assetPackName")
            dynamicDelivery {
                deliveryType.set("on-demand")
            }
        }
      '''
        .trim());
    print('Created build.gradle.kts for $assetPackName.');

    // Create AndroidManifest.xml for the asset pack
    final manifestDir = Directory('${androidDir.path}/manifest');
    manifestDir.createSync(recursive: true);
    final manifestFile = File('${manifestDir.path}/AndroidManifest.xml');
    manifestFile.writeAsStringSync('''
        <manifest xmlns:android="http://schemas.android.com/apk/res/android" 
                  xmlns:dist="http://schemas.android.com/apk/distribution" 
                  package="basePackage" 
                  split="$assetPackName">
          <dist:module dist:type="asset-pack">
            <dist:fusing dist:include="true" />    
            <dist:delivery>
              <dist:on-demand/>
            </dist:delivery>
          </dist:module>
        </manifest>
      '''
        .trim());
    print('Created AndroidManifest.xml for $assetPackName.');
  } else {
    print('Asset pack directory "$assetPackName" already exists.');
  }

  final appBuildGradleFile = File('$rootDir/android/app/build.gradle');
  if (!appBuildGradleFile.existsSync()) {
    print('Error: build.gradle not found in the android/app directory.');
    exit(1);
  }

  final assetPacksPattern = RegExp(r'assetPacks\s*=\s*\[([^\]]*)\]');
  String appBuildGradleContent = appBuildGradleFile.readAsStringSync();

  if (assetPacksPattern.hasMatch(appBuildGradleContent)) {
    // Append the new asset pack to the existing list
    appBuildGradleContent = appBuildGradleContent.replaceAllMapped(
      assetPacksPattern,
      (match) {
        final existingPacks =
            match.group(1)!.split(',').map((e) => e.trim()).toList();
        if (!existingPacks.contains('":$assetPackName"')) {
          existingPacks.add('":$assetPackName"');
          return 'assetPacks = [${existingPacks.join(', ')}]';
        }
        return match.group(0)!; // No change needed
      },
    );
    print('Updated assetPacks in app/build.gradle with ":$assetPackName"');
  } else {
    // Add a new `assetPacks` property if it doesn't exist
    final androidBlockPattern = RegExp(r'android\s*{');
    if (androidBlockPattern.hasMatch(appBuildGradleContent)) {
      appBuildGradleContent = appBuildGradleContent.replaceFirst(
        androidBlockPattern,
        'android {\n    assetPacks = [":$assetPackName"]',
      );
      print('Added assetPacks to app/build.gradle with ":$assetPackName"');
    } else {
      print('Error: Could not locate the `android` block in app/build.gradle');
      exit(1);
    }
  }
  appBuildGradleFile.writeAsStringSync(appBuildGradleContent);
}
