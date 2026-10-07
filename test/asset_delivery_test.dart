import 'dart:typed_data';

import 'package:asset_delivery/asset_delivery.dart';
import 'package:asset_delivery/asset_delivery_method_channel.dart';
import 'package:asset_delivery/asset_delivery_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAssetDeliveryPlatform
    with MockPlatformInterfaceMixin
    implements AssetDeliveryPlatform {
  String? lastWatchedPack;

  @override
  Future<void> fetch(String assetPackName) async {
    // Simulate a successful fetch call.
  }

  @override
  Future<void> fetchAssetPackState(String assetPackName) async {
    // Simulate fetching asset pack state.
  }

  @Deprecated('Mirrors the deprecated platform member.')
  @override
  void getAssetPackStatus(Function(Map<String, dynamic>) onUpdate) {
    // Simulate setting a listener.
  }

  @override
  Future<String?> getAssetPackPath({
    required String assetPackName,
    required int count,
    required String namingPattern,
    required String fileExtension,
  }) async {
    return null;

    // Simulate fetching asset pack state.
  }

  @override
  Future<Uint8List?> getInstallTimeAssetBytes(String relativeAssetPath) async {
    return null;
    // Simulate fetching asset pack state.
  }

  @override
  Stream<AssetPackStatusUpdate> watchAssetPackStatus(String assetPackName) {
    lastWatchedPack = assetPackName;
    return Stream<AssetPackStatusUpdate>.value(
      AssetPackStatusUpdate(
        name: assetPackName,
        status: AssetPackStatus.completed,
        downloadProgress: 1.0,
      ),
    );
  }
}

/// A platform implementation written before `watchAssetPackStatus` existed.
class LegacyPlatform extends AssetDeliveryPlatform {
  @override
  Future<void> fetch(String assetPackName) async {}

  @override
  Future<void> fetchAssetPackState(String assetPackName) async {}

  @Deprecated('Mirrors the deprecated platform member.')
  @override
  void getAssetPackStatus(Function(Map<String, dynamic>) onUpdate) {}

  @override
  Future<String?> getAssetPackPath({
    required String assetPackName,
    required int count,
    required String namingPattern,
    required String fileExtension,
  }) async =>
      null;

  @override
  Future<Uint8List?> getInstallTimeAssetBytes(String relativeAssetPath) async =>
      null;
}

void main() {
  final AssetDeliveryPlatform initialPlatform = AssetDeliveryPlatform.instance;

  test('$MethodChannelAssetDelivery is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAssetDelivery>());
  });

  test('a mock platform can replace the default instance', () async {
    final fakePlatform = MockAssetDeliveryPlatform();
    AssetDeliveryPlatform.instance = fakePlatform;
    expect(AssetDeliveryPlatform.instance, same(fakePlatform));
  });

  test('fetch method', () async {
    const assetPackName = 'samplePack';
    await AssetDelivery.fetch(assetPackName);
    // No exceptions should occur for a successful call.
  });

  test('fetchAssetPackState method', () async {
    const assetPackName = 'samplePack';
    await AssetDelivery.fetchAssetPackState(assetPackName);
    // Again, just verifying that the method runs without exception.
  });

  test('getAssetPackStatus', () {
    callback(Map<String, dynamic> data) {
      // Handle data here in the listener callback.
    }

    // ignore: deprecated_member_use_from_same_package
    AssetDelivery.getAssetPackStatus(callback);
    // This should complete without error.
  });

  test('watchAssetPackStatus forwards the pack name to the platform', () async {
    final fakePlatform = MockAssetDeliveryPlatform();
    AssetDeliveryPlatform.instance = fakePlatform;

    final update = await AssetDelivery.watchAssetPackStatus('samplePack').first;

    expect(fakePlatform.lastWatchedPack, 'samplePack');
    expect(update.name, 'samplePack');
    expect(update.status, AssetPackStatus.completed);
  });

  test('an implementation predating watchAssetPackStatus still constructs', () {
    // The method is non-abstract precisely so that adding it does not break
    // third-party platform implementations at compile time.
    final legacy = LegacyPlatform();
    expect(
      () => legacy.watchAssetPackStatus('samplePack'),
      throwsUnimplementedError,
    );
  });
}
