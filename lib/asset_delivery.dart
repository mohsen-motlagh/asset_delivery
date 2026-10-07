import 'dart:typed_data';

import 'asset_delivery_platform_interface.dart';
import 'src/asset_pack_status.dart';

export 'src/asset_pack_status.dart' show AssetPackStatus, AssetPackStatusUpdate;

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

  /// Watches the delivery status of a single asset pack.
  ///
  /// Emits an [AssetPackStatusUpdate] whenever the platform reports progress
  /// for [assetPackName]. Updates for other packs are filtered out, so several
  /// packs can be observed independently at the same time.
  ///
  /// The returned stream is a broadcast stream and never closes; cancel the
  /// subscription when the pack reaches [AssetPackStatus.isTerminal].
  ///
  /// ```dart
  /// AssetDelivery.watchAssetPackStatus('my_pack').listen((update) {
  ///   if (update.status == AssetPackStatus.completed) { /* ready */ }
  /// });
  /// await AssetDelivery.fetch('my_pack');
  /// ```
  static Stream<AssetPackStatusUpdate> watchAssetPackStatus(
    String assetPackName,
  ) {
    return AssetDeliveryPlatform.instance.watchAssetPackStatus(assetPackName);
  }

  /// Sets up a listener for asset pack state updates.
  ///
  /// Calling this more than once replaces the previous callback.
  @Deprecated(
    'Use watchAssetPackStatus, which is typed and reports which pack each '
    'update belongs to. Will be removed in 2.0.0.',
  )
  static void getAssetPackStatus(Function(Map<String, dynamic>) onUpdate) {
    // ignore: deprecated_member_use_from_same_package
    AssetDeliveryPlatform.instance.getAssetPackStatus(onUpdate);
  }
}
