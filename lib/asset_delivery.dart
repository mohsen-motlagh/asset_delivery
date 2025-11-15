import 'dart:typed_data';

import 'package:asset_delivery/asset_delivery_method_channel.dart';

import 'asset_delivery_platform_interface.dart';

class AssetDelivery {
  /// Fetches an asset pack by name.
  static Future<void> fetch(String assetPackName) {
    return AssetDeliveryPlatform.instance.fetch(assetPackName);
  }

  /// Fetches the state of an asset pack by name.
  static Future<void> fetchAssetPackState(String assetPackName) {
    return AssetDeliveryPlatform.instance.fetchAssetPackState(assetPackName);
  }

  static Future<String?> getAssetPackPath({
    required String assetPackName,
    required int count,
    required String namingPattern,
    required String fileExtension,
  }) {
    return AssetDeliveryPlatform.instance.getAssetPackPath(
      assetPackName: assetPackName,
      count: count,
      namingPattern: namingPattern,
      fileExtension: fileExtension,
    );
  }

  static Future<Uint8List?> getInstallTimeAssetBytes(String relativeAssetPath) {
    return AssetDeliveryPlatform.instance
        .getInstallTimeAssetBytes(relativeAssetPath);
  }

  static Stream<StatusMap> watchAssetPackStatus(String assetPackName) {
    return AssetDeliveryPlatform.instance.watchAssetPackStatus(assetPackName);
  }

  /// Sets up a listener for asset pack state updates.
  static void getAssetPackStatus(Function(Map<String, dynamic>) onUpdate) {
    AssetDeliveryPlatform.instance.getAssetPackStatus(onUpdate);
  }
}
