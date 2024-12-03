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

  @override
  Future<void> fetch(String assetPackName) async {
    try {
      await methodChannel.invokeMethod('fetch', {'assetPack': assetPackName});
    } on PlatformException catch (e) {
      debugPrint("Failed to fetch asset pack: ${e.message}");
      rethrow; // Re-throw the error if higher-level handling is needed
    }
  }

  @override
  Future<void> fetchAssetPackState(String assetPackName) async {
    try {
      await methodChannel.invokeMethod('fetchAssetPackState', {'assetPack': assetPackName});
    } on PlatformException catch (e) {
      debugPrint("Failed to fetch asset pack state: ${e.message}");
    }
  }

  @override
  Future<String?> getAssetPackPath(String assetPackName) async {
    String? assetPath;
    try {
      if (Platform.isAndroid) {
        assetPath = await methodChannel.invokeMethod('getAssets', {'assetPack': assetPackName});
      } else if (Platform.isIOS) {
        assetPath = await methodChannel.invokeMethod('getDownloadResources', {'tag': assetPackName});
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

  @override
  void setAssetPackStateUpdateListener(Function(Map<String, dynamic>) onUpdate) {
    if (Platform.isAndroid) {
      methodChannel.setMethodCallHandler((call) async {
        if (call.method == 'onAssetPackStatusChange') {
          onUpdate(call.arguments as Map<String, dynamic>);
        }
      });
    } else if (Platform.isIOS) {
      progressChannel.setMethodCallHandler((call) async {
        if (call.method == 'updateProgress') {
          final progress = (call.arguments as double?) ?? 0.0;
          onUpdate({'status': 'downloading', 'downloadProgress': progress});
        }
      });
    } else {
      debugPrint('Unsupported platform for progress updates');
    }
  }
}
