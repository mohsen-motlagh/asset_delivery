import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'asset_delivery_platform_interface.dart';

/// An implementation of [AssetDeliveryPlatform] that uses method channels.
class MethodChannelAssetDelivery extends AssetDeliveryPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('asset_delivery');

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
      await methodChannel
          .invokeMethod('fetchAssetPackState', {'assetPack': assetPackName});
    } on PlatformException catch (e) {
      print("Failed to fetch asset pack state: ${e.message}");
    }
  }

  @override
  void setAssetPackStateUpdateListener(
      Function(Map<String, dynamic>) onUpdate) {
    methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'onAssetPackStateUpdate') {
        onUpdate(call.arguments as Map<String, dynamic>);
      }
    });
  }
}
