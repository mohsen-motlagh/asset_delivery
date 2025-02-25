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
  final settingsKtsFile = File('$rootDir/android/settings.gradle.kts');
  final settingsFileToUse = settingsFile.existsSync() ? settingsFile : settingsKtsFile;

  if (!settingsFileToUse.existsSync()) {
    print('Error: Neither settings.gradle nor settings.gradle.kts found in the Android directory.');
    exit(1);
  }

  final includeStatement = "include ':$assetPackName'";
  final settingsContent = settingsFileToUse.readAsStringSync();
  final lines = settingsContent.split('\n');

  if (!lines.contains(includeStatement)) {
    final insertIndex = lines.indexWhere((line) => line.trim().contains('include ":app"'));
    if (insertIndex != -1) {
      lines.insert(insertIndex + 1, includeStatement);
    } else {
      lines.add(includeStatement);
    }

    settingsFileToUse.writeAsStringSync(lines.join('\n'));
    print('Added "$includeStatement" to ${settingsFileToUse.path}.');
  } else {
    print('"$includeStatement" already exists in ${settingsFileToUse.path}.');
  }

  if (!androidDir.existsSync()) {
    androidDir.createSync(recursive: true);
    print('Created asset pack directory: $androidDir');

    final buildGradleKtsFile = File('${androidDir.path}/build.gradle.kts');
    buildGradleKtsFile.writeAsStringSync('''
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
  final appBuildGradleKtsFile = File('$rootDir/android/app/build.gradle.kts');
  final appBuildFileToUse = appBuildGradleFile.existsSync() ? appBuildGradleFile : appBuildGradleKtsFile;

  if (!appBuildFileToUse.existsSync()) {
    print('Error: Neither build.gradle nor build.gradle.kts found in the android/app directory.');
    exit(1);
  }

  final assetPacksPattern = RegExp(r'assetPacks\s*=\s*\[([^\]]*)\]');
  String appBuildGradleContent = appBuildFileToUse.readAsStringSync();

  if (assetPacksPattern.hasMatch(appBuildGradleContent)) {
    appBuildGradleContent = appBuildGradleContent.replaceAllMapped(
      assetPacksPattern,
      (match) {
        final existingPacks = match.group(1)!.split(',').map((e) => e.trim()).toList();
        if (!existingPacks.contains('":$assetPackName"')) {
          existingPacks.add('":$assetPackName"');
          return 'assetPacks = [${existingPacks.join(', ')}]';
        }
        return match.group(0)!;
      },
    );
    print('Updated assetPacks in ${appBuildFileToUse.path} with ":$assetPackName"');
  } else {
    final androidBlockPattern = RegExp(r'android\s*{');
    if (androidBlockPattern.hasMatch(appBuildGradleContent)) {
      appBuildGradleContent = appBuildGradleContent.replaceFirst(
        androidBlockPattern,
        'android {\n    assetPacks = [":$assetPackName"]',
      );
      print('Added assetPacks to ${appBuildFileToUse.path} with ":$assetPackName"');
    } else {
      print('Error: Could not locate the `android` block in ${appBuildFileToUse.path}');
      exit(1);
    }
  }
  appBuildFileToUse.writeAsStringSync(appBuildGradleContent);
}
