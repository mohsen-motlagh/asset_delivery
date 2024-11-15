import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'asset_delivery_method_channel.dart';

abstract class AssetDeliveryPlatform extends PlatformInterface {
  /// Constructs a AssetDeliveryPlatform.
  AssetDeliveryPlatform() : super(token: _token);

  static final Object _token = Object();

  static AssetDeliveryPlatform _instance = MethodChannelAssetDelivery();

  /// The default instance of [AssetDeliveryPlatform] to use.
  ///
  /// Defaults to [MethodChannelAssetDelivery].
  static AssetDeliveryPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AssetDeliveryPlatform] when
  /// they register themselves.
  static set instance(AssetDeliveryPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> fetch(String assetPackName);
  Future<void> fetchAssetPackState(String assetPackName);
  Future<void> getAssetPackPath(String assetPackName);
  void setAssetPackStateUpdateListener(Function(Map<String, dynamic>) onUpdate);
}
