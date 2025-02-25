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

  final settingsFiles = [File('$rootDir/android/settings.gradle'), File('$rootDir/android/settings.gradle.kts')];

  File? settingsFile;
  for (var file in settingsFiles) {
    if (file.existsSync()) {
      settingsFile = file;
      break;
    }
  }

  if (settingsFile == null) {
    print('Error: settings.gradle or settings.gradle.kts not found in the Android directory.');
    exit(1);
  }

  final isKotlinDsl = settingsFile.path.endsWith('.kts');
  final includeStatement = isKotlinDsl ? 'include(":$assetPackName")' : "include ':$assetPackName'";
  final settingsContent = settingsFile.readAsStringSync();

  final lines = settingsContent.split('\n');
  if (!lines.contains(includeStatement)) {
    final insertIndex = lines.indexWhere((line) => line.trim() == (isKotlinDsl ? 'include(":app")' : 'include ":app"'));
    if (insertIndex != -1) {
      lines.insert(insertIndex + 1, includeStatement);
    } else {
      lines.add(includeStatement);
    }

    settingsFile.writeAsStringSync(lines.join('\n'));
    print('Added "$includeStatement" to ${settingsFile.path}.');
  } else {
    print('"$includeStatement" already exists in ${settingsFile.path}.');
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

  final appBuildGradleFiles = [
    File('$rootDir/android/app/build.gradle'),
    File('$rootDir/android/app/build.gradle.kts')
  ];

  File? appBuildGradleFile;
  for (var file in appBuildGradleFiles) {
    if (file.existsSync()) {
      appBuildGradleFile = file;
      break;
    }
  }

  if (appBuildGradleFile == null) {
    print('Error: build.gradle or build.gradle.kts not found in the android/app directory.');
    exit(1);
  }

  final appBuildGradleContent = appBuildGradleFile.readAsStringSync();
  final assetPacksPattern = RegExp(r'assetPacks\s*=\s*\[([^\]]*)\]');

  String updatedAppBuildGradleContent = appBuildGradleContent;
  if (assetPacksPattern.hasMatch(updatedAppBuildGradleContent)) {
    // Append the new asset pack to the existing list
    updatedAppBuildGradleContent = updatedAppBuildGradleContent.replaceAllMapped(
      assetPacksPattern,
      (match) {
        final existingPacks = match.group(1)!.split(',').map((e) => e.trim()).toList();
        if (!existingPacks.contains('":$assetPackName"')) {
          existingPacks.add('":$assetPackName"');
          return 'assetPacks = [${existingPacks.join(', ')}]';
        }
        return match.group(0)!; // No change needed
      },
    );
    print('Updated assetPacks in ${appBuildGradleFile.path} with ":$assetPackName"');
  } else {
    // Add a new `assetPacks` property if it doesn't exist
    final androidBlockPattern = RegExp(r'android\s*{');
    if (androidBlockPattern.hasMatch(updatedAppBuildGradleContent)) {
      updatedAppBuildGradleContent = updatedAppBuildGradleContent.replaceFirst(
        androidBlockPattern,
        'android {\n    assetPacks = [":$assetPackName"]',
      );
      print('Added assetPacks to ${appBuildGradleFile.path} with ":$assetPackName"');
    } else {
      print('Error: Could not locate the `android` block in ${appBuildGradleFile.path}');
      exit(1);
    }
  }
  appBuildGradleFile.writeAsStringSync(updatedAppBuildGradleContent);
}
