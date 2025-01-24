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
  Future<String?> getAssetPackPath({required String assetPackName, required int count, String? namingPattern}) async {
    String? assetPath;
    try {
      if (Platform.isAndroid) {
        assetPath = await methodChannel.invokeMethod('getAssets', {'assetPack': assetPackName});
      } else if (Platform.isIOS) {
        assetPath = await methodChannel.invokeMethod(
            'getDownloadResources', {'tag': assetPackName, 'namingPattern': namingPattern, 'assetRange': count});
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
  void getAssetPackStatus(Function(Map<String, dynamic>) onUpdate) {
    if (Platform.isAndroid) {
      methodChannel.setMethodCallHandler((call) async {
        if (call.method == 'onAssetPackStatusChange') {
          Map<String, dynamic> statusMap = Map<String, dynamic>.from(call.arguments);
          onUpdate(statusMap);
        }
      });
    } else if (Platform.isIOS) {
      progressChannel.setMethodCallHandler((call) async {
        if (call.method == 'updateProgress') {
          print('download progress ===== ${call.arguments}');
          double? progress = call.arguments as double?;
          print('download progress ===== $progress');
          onUpdate({'status': 'downloading', 'downloadProgress': progress});
        }
      });
    } else {
      debugPrint('Unsupported platform for progress updates');
    }
  }
}

class StatusMap {
  String status;
  double downloadProgress;
  StatusMap({required this.status, required this.downloadProgress});

  StatusMap.fromJson(Map<String, dynamic> json)
      : status = json['status'],
        downloadProgress = json['downloadProgress'];
}
