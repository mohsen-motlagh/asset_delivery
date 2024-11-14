import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'asset_delivery_platform_interface.dart';

/// An implementation of [AssetDeliveryPlatform] that uses method channels.
class MethodChannelAssetDelivery extends AssetDeliveryPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('asset_delivery');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
