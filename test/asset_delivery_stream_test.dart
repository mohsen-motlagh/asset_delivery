import 'package:asset_delivery/asset_delivery.dart';
import 'package:asset_delivery/asset_delivery_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const String _eventChannelName = 'asset_delivery/events';

/// Pushes an event down the platform side of the [EventChannel].
void _emit(Object? payload) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
    _eventChannelName,
    const StandardMethodCodec().encodeSuccessEnvelope(payload),
    (_) {},
  );
}

Map<String, Object?> _update(
  String name,
  String status, {
  double progress = 0.0,
  int? errorCode,
}) =>
    <String, Object?>{
      'name': name,
      'status': status,
      'downloadProgress': progress,
      'bytesDownloaded': 0,
      'totalBytesToDownload': 0,
      'errorCode': errorCode,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelAssetDelivery platform;

  setUp(() {
    platform = MethodChannelAssetDelivery();
    // EventChannel sends listen/cancel over a MethodChannel of the same name.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(_eventChannelName),
      (MethodCall call) async => null,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(_eventChannelName), null);
  });

  group('watchAssetPackStatus', () {
    test('yields only updates for the requested pack', () async {
      // The bug this replaces: the pack name was accepted and then ignored,
      // so every subscriber saw every pack's events.
      final received = <AssetPackStatusUpdate>[];
      final sub = platform.watchAssetPackStatus('pack_a').listen(received.add);
      await pumpEventQueue();

      _emit(_update('pack_a', 'downloading', progress: 0.25));
      _emit(_update('pack_b', 'downloading', progress: 0.90));
      _emit(_update('pack_a', 'completed', progress: 1.0));
      await pumpEventQueue();

      expect(received.map((u) => u.name), everyElement('pack_a'));
      expect(received.map((u) => u.status), [
        AssetPackStatus.downloading,
        AssetPackStatus.completed,
      ]);
      await sub.cancel();
    });

    test('routes two packs watched at the same time independently', () async {
      final a = <AssetPackStatusUpdate>[];
      final b = <AssetPackStatusUpdate>[];
      final subA = platform.watchAssetPackStatus('pack_a').listen(a.add);
      final subB = platform.watchAssetPackStatus('pack_b').listen(b.add);
      await pumpEventQueue();

      _emit(_update('pack_a', 'downloading', progress: 0.5));
      _emit(_update('pack_b', 'failed', errorCode: -6));
      await pumpEventQueue();

      expect(a, hasLength(1));
      expect(a.single.status, AssetPackStatus.downloading);
      expect(a.single.downloadProgress, 0.5);

      expect(b, hasLength(1));
      expect(b.single.status, AssetPackStatus.failed);
      expect(b.single.errorCode, -6);

      await subA.cancel();
      await subB.cancel();
    });

    test('delivers to multiple subscribers on the same pack', () async {
      // A MethodChannel handler allowed exactly one listener; a broadcast
      // stream must serve all of them.
      final first = <AssetPackStatusUpdate>[];
      final second = <AssetPackStatusUpdate>[];
      final sub1 = platform.watchAssetPackStatus('pack_a').listen(first.add);
      final sub2 = platform.watchAssetPackStatus('pack_a').listen(second.add);
      await pumpEventQueue();

      _emit(_update('pack_a', 'completed', progress: 1.0));
      await pumpEventQueue();

      expect(first, hasLength(1));
      expect(second, hasLength(1));
      await sub1.cancel();
      await sub2.cancel();
    });

    test('ignores non-map events without breaking the stream', () async {
      final received = <AssetPackStatusUpdate>[];
      final sub = platform.watchAssetPackStatus('pack_a').listen(received.add);
      await pumpEventQueue();

      _emit('unexpected string');
      _emit(42);
      _emit(_update('pack_a', 'completed', progress: 1.0));
      await pumpEventQueue();

      expect(received, hasLength(1));
      expect(received.single.status, AssetPackStatus.completed);
      await sub.cancel();
    });

    test('a partial payload does not stop later events arriving', () async {
      final received = <AssetPackStatusUpdate>[];
      final sub = platform.watchAssetPackStatus('').listen(received.add);
      await pumpEventQueue();

      _emit(<String, Object?>{}); // no name, no status
      await pumpEventQueue();
      _emit(<String, Object?>{'status': 'completed'});
      await pumpEventQueue();

      expect(received, hasLength(2));
      expect(received.first.status, AssetPackStatus.unknown);
      expect(received.last.status, AssetPackStatus.completed);
      await sub.cancel();
    });
  });

  group('legacyPayload (pre-2.0.0 compatibility)', () {
    Map<String, dynamic> android(AssetPackStatus status, {int? errorCode}) =>
        MethodChannelAssetDelivery.legacyPayload(
          AssetPackStatusUpdate(
            name: 'pack_a',
            status: status,
            downloadProgress: 0.5,
            errorCode: errorCode,
          ),
          isIOS: false,
        );

    test('reproduces the exact 1.1.0 Android status strings', () {
      expect(android(AssetPackStatus.pending)['status'], 'Pending');
      expect(android(AssetPackStatus.downloading)['status'], 'DOWNLOADING');
      expect(android(AssetPackStatus.transferring)['status'], 'TRANSFERRING');
      expect(android(AssetPackStatus.completed)['status'], 'COMPLETED');
      expect(android(AssetPackStatus.canceled)['status'], 'CANCELED');
      expect(android(AssetPackStatus.notInstalled)['status'], 'Not Installed');
      expect(android(AssetPackStatus.waitingForWifi)['status'],
          'Waiting For Wifi');
      expect(android(AssetPackStatus.unknown)['status'], 'Unknown status.');
    });

    test('keeps the error code embedded in the failure string', () {
      expect(
        android(AssetPackStatus.failed, errorCode: -6)['status'],
        'Failed: -6',
      );
    });

    test('preserves the 100.0 completion value from 1.1.0', () {
      // 1.1.0 reported completion as 100.0 on an otherwise 0..1 scale. The new
      // API reports 1.0; the deprecated path must not change under callers.
      expect(android(AssetPackStatus.completed)['downloadProgress'], 100.0);
    });

    test('preserves the 0.99 transferring sentinel from 1.1.0', () {
      expect(android(AssetPackStatus.transferring)['downloadProgress'], 0.99);
    });

    test('passes fractional download progress through unchanged', () {
      expect(android(AssetPackStatus.downloading)['downloadProgress'], 0.5);
    });

    test('uses the lowercase iOS spelling for downloading', () {
      // iOS shipped 'downloading' where Android shipped 'DOWNLOADING'.
      final payload = MethodChannelAssetDelivery.legacyPayload(
        const AssetPackStatusUpdate(
          name: 'pack_a',
          status: AssetPackStatus.downloading,
          downloadProgress: 0.25,
        ),
        isIOS: true,
      );
      expect(payload['status'], 'downloading');
      expect(payload['downloadProgress'], 0.25);
    });
  });
}
