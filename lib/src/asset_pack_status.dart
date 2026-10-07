/// The delivery state of an asset pack.
///
/// These values are platform-neutral. On Android they map onto
/// `com.google.android.play.core.assetpacks.model.AssetPackStatus`; on iOS
/// they are derived from the lifecycle of an `NSBundleResourceRequest`, which
/// reports fewer distinct states.
enum AssetPackStatus {
  /// The download has been requested but has not started yet.
  ///
  /// Android only.
  pending,

  /// Bytes are actively being downloaded.
  downloading,

  /// The download finished and the pack is being unpacked onto the device.
  ///
  /// Android only.
  transferring,

  /// The pack is fully downloaded and ready to read.
  completed,

  /// The download failed. See [AssetPackStatusUpdate.errorCode].
  failed,

  /// The download was canceled, either by the user or by the platform.
  canceled,

  /// The pack is not present on the device and no download is in progress.
  ///
  /// Android only.
  notInstalled,

  /// The download is deferred until the device is on an unmetered network.
  ///
  /// Android only.
  waitingForWifi,

  /// The platform reported a state this plugin does not recognise.
  unknown;

  /// Parses the wire value sent by the native side.
  ///
  /// Falls back to [unknown] rather than throwing, so that a native layer
  /// newer than the Dart layer cannot crash the stream.
  static AssetPackStatus fromWireName(String? value) {
    for (final status in AssetPackStatus.values) {
      if (status.name == value) return status;
    }
    return AssetPackStatus.unknown;
  }

  /// Whether this state is final — no further updates will arrive for the
  /// current request.
  bool get isTerminal =>
      this == completed || this == failed || this == canceled;
}

/// A single status update for one asset pack.
///
/// Delivered by `AssetDelivery.watchAssetPackStatus`.
class AssetPackStatusUpdate {
  /// The asset pack this update refers to.
  ///
  /// On Android this is the asset pack name; on iOS it is the On-Demand
  /// Resources tag. Used to route updates when several packs are in flight.
  final String name;

  /// The current delivery state.
  final AssetPackStatus status;

  /// Download progress in the range `0.0`–`1.0`.
  ///
  /// Always `1.0` once [status] is [AssetPackStatus.completed]. Reported as
  /// `0.0` when the total size is not yet known.
  final double downloadProgress;

  /// Bytes transferred so far, or `0` when the platform does not report it.
  final int bytesDownloaded;

  /// Total bytes to transfer, or `0` when not yet known.
  final int totalBytesToDownload;

  /// Platform error code, set only when [status] is [AssetPackStatus.failed].
  final int? errorCode;

  const AssetPackStatusUpdate({
    required this.name,
    required this.status,
    required this.downloadProgress,
    this.bytesDownloaded = 0,
    this.totalBytesToDownload = 0,
    this.errorCode,
  });

  /// Builds an update from a native payload.
  ///
  /// Every field is read defensively: a malformed or partial map yields a
  /// usable object rather than a thrown exception, because these values cross
  /// a platform channel and a throw here would tear down the stream for all
  /// listeners.
  factory AssetPackStatusUpdate.fromMap(Map<Object?, Object?> map) {
    final rawProgress = (map['downloadProgress'] as num?)?.toDouble() ?? 0.0;
    return AssetPackStatusUpdate(
      name: map['name'] as String? ?? '',
      status: AssetPackStatus.fromWireName(map['status'] as String?),
      // NaN survives clamp(), so it has to be screened out separately: it
      // arises natively from a 0/0 byte ratio when a pack is already resident.
      downloadProgress:
          rawProgress.isNaN ? 0.0 : rawProgress.clamp(0.0, 1.0).toDouble(),
      bytesDownloaded: (map['bytesDownloaded'] as num?)?.toInt() ?? 0,
      totalBytesToDownload: (map['totalBytesToDownload'] as num?)?.toInt() ?? 0,
      errorCode: (map['errorCode'] as num?)?.toInt(),
    );
  }

  @override
  String toString() => 'AssetPackStatusUpdate(name: $name, '
      'status: ${status.name}, progress: $downloadProgress'
      '${errorCode != null ? ', errorCode: $errorCode' : ''})';
}
