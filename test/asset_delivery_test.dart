import 'package:asset_delivery/asset_delivery.dart';
import 'package:asset_delivery/asset_delivery_method_channel.dart';
import 'package:asset_delivery/asset_delivery_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAssetDeliveryPlatform with MockPlatformInterfaceMixin implements AssetDeliveryPlatform {
  @override
  Future<void> fetch(String assetPackName) async {
    // Simulate a successful fetch call.
  }

  @override
  Future<void> fetchAssetPackState(String assetPackName) async {
    // Simulate fetching asset pack state.
  }

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
}

void main() {
  final AssetDeliveryPlatform initialPlatform = AssetDeliveryPlatform.instance;

  test('$MethodChannelAssetDelivery is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAssetDelivery>());
  });

  test('getPlatformVersion', () async {
    //AssetDelivery assetDeliveryPlugin = AssetDelivery();
    MockAssetDeliveryPlatform fakePlatform = MockAssetDeliveryPlatform();
    AssetDeliveryPlatform.instance = fakePlatform;
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
    AssetDelivery.getAssetPackStatus(callback);
    // This should complete without error.
  });
}
