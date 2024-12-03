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
      print("Failed to fetch asset pack: ${e.message}");
    }
  }

  @override
  Future<void> fetchAssetPackState(String assetPackName) async {
    try {
      await methodChannel.invokeMethod('fetchAssetPackState', {'assetPack': assetPackName});
    } on PlatformException catch (e) {
      print("Failed to fetch asset pack state: ${e.message}");
    }
  }

  @override
  Future<String?> getAssetPackPath(String assetPackName) async {
    String? assetPath;
    if (Platform.isAndroid) {
      print('went inside android');
      try {
        final String? result = await methodChannel.invokeMethod('getAssets', {'assetPack': assetPackName});
        assetPath = result;
      } on PlatformException catch (e) {
        print("Failed to fetch asset pack state: ${e.message}");
        return null;
      }
    } else if (Platform.isIOS) {
      print('went inside ios');
      try {
        final String? path = await methodChannel.invokeMethod('getDownloadResources', {'tag': assetPackName});
        assetPath = path;
      } on PlatformException catch (e) {
        debugPrint("Failed to download resources: ${e.message}");
        return null;
      }
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
          final double progress = call.arguments as double;
          onUpdate({'status': 'downloading', 'progress': progress});
        }
      });
    }
  }
}
