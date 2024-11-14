import 'package:flutter_test/flutter_test.dart';
import 'package:asset_delivery/asset_delivery.dart';
import 'package:asset_delivery/asset_delivery_platform_interface.dart';
import 'package:asset_delivery/asset_delivery_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAssetDeliveryPlatform
    with MockPlatformInterfaceMixin
    implements AssetDeliveryPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AssetDeliveryPlatform initialPlatform = AssetDeliveryPlatform.instance;

  test('$MethodChannelAssetDelivery is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAssetDelivery>());
  });

  test('getPlatformVersion', () async {
    AssetDelivery assetDeliveryPlugin = AssetDelivery();
    MockAssetDeliveryPlatform fakePlatform = MockAssetDeliveryPlatform();
    AssetDeliveryPlatform.instance = fakePlatform;

    expect(await assetDeliveryPlugin.getPlatformVersion(), '42');
  });
}
