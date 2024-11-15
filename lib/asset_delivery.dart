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

  static Future<String?> getAssetPackPath(String assetPackName) {
    return AssetDeliveryPlatform.instance.getAssetPackPath(assetPackName);
  }

  // static Future<void> assetPackStatusListener(String assetPackName) {
  //   return AssetDeliveryPlatform.instance.(onUpdate)
  // }

  /// Sets up a listener for asset pack state updates.
  static void setAssetPackStateUpdateListener(
      Function(Map<String, dynamic>) onUpdate) {
    AssetDeliveryPlatform.instance.setAssetPackStateUpdateListener(onUpdate);
  }
}
