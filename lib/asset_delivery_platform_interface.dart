import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'asset_delivery_method_channel.dart';
import 'src/asset_pack_status.dart';

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

  /// Watches delivery status for a single asset pack.
  ///
  /// Deliberately not `abstract`: adding a required member to a
  /// [PlatformInterface] breaks every existing third-party implementation at
  /// compile time. Implementations that predate this method keep working and
  /// only fail if the method is actually called.
  Stream<AssetPackStatusUpdate> watchAssetPackStatus(String assetPackName) {
    throw UnimplementedError(
        'watchAssetPackStatus() has not been implemented.');
  }

  Future<String?> getAssetPackPath({
    required String assetPackName,
    required int count,
    required String namingPattern,
    required String fileExtension,
  });

  Future<Uint8List?> getInstallTimeAssetBytes(String relativeAssetPath);

  @Deprecated(
    'Use watchAssetPackStatus, which is typed and reports which pack each '
    'update belongs to. Will be removed in 2.0.0.',
  )
  void getAssetPackStatus(Function(Map<String, dynamic>) onUpdate);
}
