import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'asset_delivery_platform_interface.dart';
import 'src/asset_pack_status.dart';

/// An implementation of [AssetDeliveryPlatform] that uses method channels.
class MethodChannelAssetDelivery extends AssetDeliveryPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('asset_delivery');

  /// Carries asset pack status updates from the host to Dart.
  ///
  /// An [EventChannel] rather than a method-call handler, because a
  /// [MethodChannel] supports only one handler at a time — which made it
  /// impossible for more than one caller to observe download status.
  @visibleForTesting
  final eventChannel = const EventChannel('asset_delivery/events');

  @Deprecated(
    'Unused and never emitted. Use watchAssetPackStatus instead. '
    'Will be removed in 2.0.0.',
  )
  static void Function(String status, double progress)? onStatusChange;

  Stream<AssetPackStatusUpdate>? _statuses;
  StreamSubscription<AssetPackStatusUpdate>? _legacySubscription;

  /// Lazily-created broadcast view over the native event stream.
  Stream<AssetPackStatusUpdate> get _statusStream {
    return _statuses ??= eventChannel
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map((event) =>
            AssetPackStatusUpdate.fromMap(event as Map<Object?, Object?>));
  }

  /// Fetches the specified asset pack from the platform.
  ///
  /// This method triggers the platform's asset delivery mechanism to download
  /// the specified asset pack. It is particularly useful for on-demand
  /// resources.
  ///
  /// - [assetPackName]: The name of the asset pack to fetch.
  ///
  /// Throws a [PlatformException] if fetching the asset pack fails.
  @override
  Future<void> fetch(String assetPackName) async {
    try {
      await methodChannel.invokeMethod('fetch', {'assetPack': assetPackName});
    } on PlatformException catch (e) {
      debugPrint("Failed to fetch asset pack: ${e.message}");
      rethrow; // Re-throw the error if higher-level handling is needed
    }
  }

  /// Fetches the state of the specified asset pack.
  ///
  /// This method retrieves the current state (e.g., downloading, completed) of
  /// the specified asset pack.
  ///
  /// - [assetPackName]: The name of the asset pack whose state is to be fetched.
  ///
  /// If the operation fails, a message is logged but no exception is thrown.
  @override
  Future<void> fetchAssetPackState(String assetPackName) async {
    try {
      await methodChannel
          .invokeMethod('fetchAssetPackState', {'assetPack': assetPackName});
    } on PlatformException catch (e) {
      debugPrint("Failed to fetch asset pack state: ${e.message}");
    }
  }

  /// Gets the file path for the specified asset pack.
  ///
  /// This method determines the storage location of an asset pack, downloading
  /// it if necessary, depending on the platform:
  /// - On Android, it fetches the asset pack path.
  /// - On iOS, it downloads the assets and returns the path to the folder where
  ///   the resources are stored.
  ///
  /// Parameters:
  /// - [assetPackName]: The name of the asset pack to fetch.
  /// - [count]: The number of assets in the asset pack.
  /// - [namingPattern]: The naming pattern for the assets (e.g., "asset_%d").
  /// - [fileExtension]: The file extension for the assets (e.g., "png", "mp3").
  ///
  /// Returns:
  /// - A [String] representing the path to the asset pack folder, or `null`
  ///   if an error occurs.
  ///
  /// Throws:
  /// - [PlatformException] if an error occurs on the platform side.
  /// - [UnsupportedError] if the platform is unsupported.
  @override
  Future<String?> getAssetPackPath({
    required String
        assetPackName, // specify the name of the asset pack to fetch
    required int count, // specify the number of assets in the pack to fetch
    required String namingPattern, // specify the naming pattern of the assets
    required String fileExtension, // Specify the file extension for the asset
  }) async {
    String? assetPath;
    try {
      if (Platform.isAndroid) {
        assetPath = await methodChannel
            .invokeMethod('getAssets', {'assetPack': assetPackName});
      } else if (Platform.isIOS) {
        assetPath = await methodChannel.invokeMethod('getDownloadResources', {
          'tag': assetPackName,
          'namingPattern': namingPattern,
          'assetRange': count,
          'extension': fileExtension,
        });
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

  /// Gets the file path for the specified install-time asset pack.
  ///
  /// The install time asset pack is fetched from the split-APK
  /// Parameters:
  /// - [assetPackName]: The name of the asset pack to fetch.
  ///
  /// Returns:
  /// - A [String] representing the path to the asset pack folder, or `null`
  ///   if an error occurs.
  ///
  /// Throws:
  /// - [PlatformException] if an error occurs on the platform side.
  /// - [UnsupportedError] if the platform is unsupported.
  @override
  Future<Uint8List?> getInstallTimeAssetBytes(String relativeAssetPath) async {
    Uint8List? assetPath;
    try {
      assetPath = await methodChannel.invokeMethod(
          'getInstallTimeAssetBytes', {'assetPack': relativeAssetPath});
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
  Stream<AssetPackStatusUpdate> watchAssetPackStatus(String assetPackName) {
    return _statusStream.where((update) => update.name == assetPackName);
  }

  /// Subscribes to asset pack status updates.
  ///
  /// Reimplemented on top of [watchAssetPackStatus]; the payload is translated
  /// back to the 1.1.0 wire format so existing callers keep working unchanged.
  @Deprecated(
    'Use watchAssetPackStatus, which is typed and reports which pack each '
    'update belongs to. Will be removed in 2.0.0.',
  )
  @override
  void getAssetPackStatus(Function(Map<String, dynamic>) onUpdate) {
    // 1.1.0 replaced the handler on each call rather than adding a second one.
    _legacySubscription?.cancel();
    _legacySubscription = _statusStream.listen((update) {
      onUpdate(legacyPayload(update, isIOS: Platform.isIOS));
    });
  }

  /// Rebuilds the pre-2.0.0 status map from a typed update.
  ///
  /// The two platforms shipped different vocabularies in 1.1.0 — Android sent
  /// `'DOWNLOADING'`, iOS sent `'downloading'` — and Android reported completion
  /// as `100.0` on a scale where every other value was a 0–1 fraction. Those
  /// quirks are reproduced here rather than fixed, so that upgrading to 1.2.0
  /// changes nothing for callers still using [getAssetPackStatus]. This function
  /// is deleted together with that method in 2.0.0.
  ///
  /// States a platform could not produce in 1.1.0 fall through to the new
  /// lowercase enum name; iOS only ever emitted `'downloading'`.
  @visibleForTesting
  static Map<String, dynamic> legacyPayload(
    AssetPackStatusUpdate update, {
    required bool isIOS,
  }) {
    if (isIOS) {
      return {
        'status': update.status == AssetPackStatus.downloading
            ? 'downloading'
            : update.status.name,
        'downloadProgress': update.downloadProgress,
      };
    }
    return {
      'status': switch (update.status) {
        AssetPackStatus.pending => 'Pending',
        AssetPackStatus.downloading => 'DOWNLOADING',
        AssetPackStatus.transferring => 'TRANSFERRING',
        AssetPackStatus.completed => 'COMPLETED',
        AssetPackStatus.failed => 'Failed: ${update.errorCode}',
        AssetPackStatus.canceled => 'CANCELED',
        AssetPackStatus.notInstalled => 'Not Installed',
        AssetPackStatus.waitingForWifi => 'Waiting For Wifi',
        AssetPackStatus.unknown => 'Unknown status.',
      },
      'downloadProgress': switch (update.status) {
        AssetPackStatus.completed => 100.0,
        AssetPackStatus.transferring => 0.99,
        _ => update.downloadProgress,
      },
    };
  }
}

/// Represents the status of an asset pack download.
@Deprecated(
  'Use AssetPackStatusUpdate, which carries the pack name, byte counts and '
  'error code. Will be removed in 2.0.0.',
)
class StatusMap {
  String status;
  double downloadProgress;
  StatusMap({required this.status, required this.downloadProgress});

  StatusMap.fromJson(Map<String, dynamic> json)
      : status = json['status'],
        downloadProgress = json['downloadProgress'];
}
