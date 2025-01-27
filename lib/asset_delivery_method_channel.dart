import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'asset_delivery_platform_interface.dart';

/// An implementation of [AssetDeliveryPlatform] that uses method channels.
class MethodChannelAssetDelivery extends AssetDeliveryPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('asset_delivery');
  final progressChannel = const MethodChannel('on_demand_resources_progress');

  static void Function(String status, double progress)? onStatusChange;

  /// Fetches the specified asset pack from the platform.
  ///
  /// This method triggers the platform's asset delivery mechanism to download
  /// the specified asset pack. It is particularly useful for on-demand
  /// resources.
  ///
  /// - [assetPackName]: The name of the asset pack to fetch.
  ///
  /// Throws a [PlatformException] if fetching the asset pack fails.
  @override
  Future<void> fetch(String assetPackName) async {
    try {
      await methodChannel.invokeMethod('fetch', {'assetPack': assetPackName});
    } on PlatformException catch (e) {
      debugPrint("Failed to fetch asset pack: ${e.message}");
      rethrow; // Re-throw the error if higher-level handling is needed
    }
  }

  /// Fetches the state of the specified asset pack.
  ///
  /// This method retrieves the current state (e.g., downloading, completed) of
  /// the specified asset pack.
  ///
  /// - [assetPackName]: The name of the asset pack whose state is to be fetched.
  ///
  /// If the operation fails, a message is logged but no exception is thrown.
  @override
  Future<void> fetchAssetPackState(String assetPackName) async {
    try {
      await methodChannel
          .invokeMethod('fetchAssetPackState', {'assetPack': assetPackName});
    } on PlatformException catch (e) {
      debugPrint("Failed to fetch asset pack state: ${e.message}");
    }
  }

  /// Gets the file path for the specified asset pack.
  ///
  /// This method determines the storage location of an asset pack, downloading
  /// it if necessary, depending on the platform:
  /// - On Android, it fetches the asset pack path.
  /// - On iOS, it downloads the assets and returns the path to the folder where
  ///   the resources are stored.
  ///
  /// Parameters:
  /// - [assetPackName]: The name of the asset pack to fetch.
  /// - [count]: The number of assets in the asset pack.
  /// - [namingPattern]: The naming pattern for the assets (e.g., "asset_%d").
  /// - [fileExtension]: The file extension for the assets (e.g., "png", "mp3").
  ///
  /// Returns:
  /// - A [String] representing the path to the asset pack folder, or `null`
  ///   if an error occurs.
  ///
  /// Throws:
  /// - [PlatformException] if an error occurs on the platform side.
  /// - [UnsupportedError] if the platform is unsupported.
  @override
  Future<String?> getAssetPackPath({
    required String
        assetPackName, // specify the name of the asset pack to fetch
    required int count, // specify the number of assets in the pack to fetch
    required String namingPattern, // specify the naming pattern of the assets
    required String fileExtension, // Specify the file extension for the asset
  }) async {
    String? assetPath;
    try {
      if (Platform.isAndroid) {
        assetPath = await methodChannel
            .invokeMethod('getAssets', {'assetPack': assetPackName});
      } else if (Platform.isIOS) {
        assetPath = await methodChannel.invokeMethod('getDownloadResources', {
          'tag': assetPackName,
          'namingPattern': namingPattern,
          'assetRange': count,
          'extension': fileExtension,
        });
      } else {
        debugPrint('Unsupported platform');
        throw UnsupportedError('Platform not supported');
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to fetch asset pack path: ${e.message}");
      return null;
    } on UnsupportedError catch (e) {
      debugPrint("Error: ${e.message}");
      return null;
    }
    return assetPath;
  }

  /// Subscribes to asset pack status updates.
  ///
  /// This method listens for updates about the status of asset pack downloads
  /// (e.g., "downloading", "completed") and passes the information to the
  /// provided callback function.
  ///
  /// - [onUpdate]: A callback function that takes a [Map<String, dynamic>] with
  ///   status details.
  ///
  /// Supported platforms:
  /// - Android: Listens for `onAssetPackStatusChange` events.
  /// - iOS: Listens for `updateProgress` events.
  ///
  /// Logs a message if the platform is unsupported.
  @override
  void getAssetPackStatus(Function(Map<String, dynamic>) onUpdate) {
    if (Platform.isAndroid) {
      methodChannel.setMethodCallHandler((call) async {
        if (call.method == 'onAssetPackStatusChange') {
          Map<String, dynamic> statusMap =
              Map<String, dynamic>.from(call.arguments);
          onUpdate(statusMap);
        }
      });
    } else if (Platform.isIOS) {
      progressChannel.setMethodCallHandler((call) async {
        if (call.method == 'updateProgress') {
          print('download progress ${call.arguments}');
          double? progress = call.arguments as double?;
          print('download progress $progress');
          onUpdate({'status': 'downloading', 'downloadProgress': progress});
        }
      });
    } else {
      debugPrint('Unsupported platform for progress updates');
    }
  }
}

/// Represents the status of an asset pack download.
class StatusMap {
  String status;
  double downloadProgress;
  StatusMap({required this.status, required this.downloadProgress});

  StatusMap.fromJson(Map<String, dynamic> json)
      : status = json['status'],
        downloadProgress = json['downloadProgress'];
}
