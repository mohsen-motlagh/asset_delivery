import 'package:asset_delivery/asset_delivery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssetPackStatus.fromWireName', () {
    test('maps every native status name onto an enum value', () {
      const wireNames = {
        'pending': AssetPackStatus.pending,
        'downloading': AssetPackStatus.downloading,
        'transferring': AssetPackStatus.transferring,
        'completed': AssetPackStatus.completed,
        'failed': AssetPackStatus.failed,
        'canceled': AssetPackStatus.canceled,
        'notInstalled': AssetPackStatus.notInstalled,
        'waitingForWifi': AssetPackStatus.waitingForWifi,
        'unknown': AssetPackStatus.unknown,
      };
      wireNames.forEach((wire, expected) {
        expect(AssetPackStatus.fromWireName(wire), expected, reason: wire);
      });
    });

    test('falls back to unknown instead of throwing', () {
      // A native layer newer than the Dart layer must not kill the stream.
      expect(AssetPackStatus.fromWireName('someFutureState'),
          AssetPackStatus.unknown);
      expect(AssetPackStatus.fromWireName(null), AssetPackStatus.unknown);
      expect(AssetPackStatus.fromWireName(''), AssetPackStatus.unknown);
    });

    test('isTerminal marks only the final states', () {
      expect(AssetPackStatus.completed.isTerminal, isTrue);
      expect(AssetPackStatus.failed.isTerminal, isTrue);
      expect(AssetPackStatus.canceled.isTerminal, isTrue);
      expect(AssetPackStatus.downloading.isTerminal, isFalse);
      expect(AssetPackStatus.transferring.isTerminal, isFalse);
    });
  });

  group('AssetPackStatusUpdate.fromMap', () {
    test('reads a well-formed payload', () {
      final update = AssetPackStatusUpdate.fromMap(const {
        'name': 'my_pack',
        'status': 'downloading',
        'downloadProgress': 0.42,
        'bytesDownloaded': 420,
        'totalBytesToDownload': 1000,
        'errorCode': null,
      });

      expect(update.name, 'my_pack');
      expect(update.status, AssetPackStatus.downloading);
      expect(update.downloadProgress, 0.42);
      expect(update.bytesDownloaded, 420);
      expect(update.totalBytesToDownload, 1000);
      expect(update.errorCode, isNull);
    });

    test('survives an empty payload rather than throwing', () {
      // A throw here would tear the stream down for every listener.
      final update = AssetPackStatusUpdate.fromMap(const {});

      expect(update.name, '');
      expect(update.status, AssetPackStatus.unknown);
      expect(update.downloadProgress, 0.0);
      expect(update.bytesDownloaded, 0);
      expect(update.totalBytesToDownload, 0);
      expect(update.errorCode, isNull);
    });

    test('coerces NaN progress to zero', () {
      // Arises natively from a 0/0 byte ratio on an already-resident pack.
      final update = AssetPackStatusUpdate.fromMap(
        {'downloadProgress': double.nan},
      );
      expect(update.downloadProgress, 0.0);
      expect(update.downloadProgress.isNaN, isFalse);
    });

    test('clamps progress into the 0..1 range', () {
      expect(
        AssetPackStatusUpdate.fromMap({'downloadProgress': 100.0})
            .downloadProgress,
        1.0,
      );
      expect(
        AssetPackStatusUpdate.fromMap({'downloadProgress': -3.0})
            .downloadProgress,
        0.0,
      );
    });

    test('accepts integer progress and byte counts', () {
      // The platform channel may deliver a whole number as int, not double.
      final update = AssetPackStatusUpdate.fromMap(const {
        'downloadProgress': 1,
        'bytesDownloaded': 10,
        'totalBytesToDownload': 10,
      });
      expect(update.downloadProgress, 1.0);
      expect(update.bytesDownloaded, 10);
    });

    test('carries the error code on failure', () {
      final update = AssetPackStatusUpdate.fromMap(const {
        'name': 'my_pack',
        'status': 'failed',
        'errorCode': -6,
      });
      expect(update.status, AssetPackStatus.failed);
      expect(update.errorCode, -6);
    });
  });
}
