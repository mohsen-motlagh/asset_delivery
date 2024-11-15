import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'asset_delivery_platform_interface.dart';

/// An implementation of [AssetDeliveryPlatform] that uses method channels.
class MethodChannelAssetDelivery extends AssetDeliveryPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('asset_delivery');

  static void Function(String status, double progress)? onStatusChange;

  @override
  Future<void> fetch(String assetPackName) async {
    try {
      await methodChannel.invokeMethod('fetch', {'assetPack': assetPackName});
    } on PlatformException catch (e) {
      print("Failed to fetch asset pack: ${e.message}");
    }
  }

  // MethodChannelAssetDelivery() {
  // Listen for method calls from the native side
  // methodChannel.setMethodCallHandler(_handleMethodCall);
  // }

  // @override
  // Future<void> onAssetPackStatusChange() async {
  //   methodChannel.setMethodCallHandler(
  //       'onAssetPackStatusChange', {'assetPack': assetPackName});
  //       if (call.method == 'onAssetPackStatusChange') {
  //       Map<String, dynamic> statusMap =
  //           Map<String, dynamic>.from(call.arguments);
  //       StatusMap status = StatusMap.fromJson(statusMap);
  //       _assetStatusController.add(status);
  //     }
  // }

  @override
  Future<void> fetchAssetPackState(String assetPackName) async {
    try {
      await methodChannel
          .invokeMethod('fetchAssetPackState', {'assetPack': assetPackName});
    } on PlatformException catch (e) {
      print("Failed to fetch asset pack state: ${e.message}");
    }
  }

  @override
  Future<String?> getAssetPackPath(String assetPackName) async {
    String? assetPath;
    try {
      final String? result = await methodChannel
          .invokeMethod('getAssets', {'assetPack': assetPackName});
      assetPath = result;
    } on PlatformException catch (e) {
      print("Failed to fetch asset pack state: ${e.message}");
    }
    return assetPath;
  }

  @override
  void setAssetPackStateUpdateListener(
      Function(Map<String, dynamic>) onUpdate) {
    methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'onAssetPackStatusChange') {
        onUpdate(call.arguments as Map<String, dynamic>);
      }
    });
  }

//   static Future<void> _handleMethodCall(MethodCall call) async {
//     switch (call.method) {
//       case 'onAssetPackStatusChange':
//         final Map<dynamic, dynamic> args = call.arguments;
//         final String status = args['status'] ?? 'unknown';
//         final double progress = (args['downloadProgress'] ?? 0.0).toDouble();
//         // Notify the listener, if set
//         onStatusChange?.call(status, progress);
//         break;
//       default:
//         throw PlatformException(
//           code: 'Unimplemented',
//           details: 'The method ${call.method} is not implemented',
//         );
//     }
//   }
}
