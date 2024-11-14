
import 'asset_delivery_platform_interface.dart';

class AssetDelivery {
  Future<String?> getPlatformVersion() {
    return AssetDeliveryPlatform.instance.getPlatformVersion();
  }
}
