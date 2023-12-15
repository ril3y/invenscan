import 'dart:async';
import 'package:nfc_manager/nfc_manager.dart';
import 'dart:typed_data';

class NFCManager {
  static Future<void> writeToNFC(String message) async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      throw NFCNotAvailableException();
    }

    Completer<void> completer = Completer();

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          Ndef? ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            throw NFCWriteException('Tag is not NDEF writable or is null');
          }
          await ndef.write(NdefMessage([NdefRecord.createText(message)]));
          completer.complete();
        } catch (e) {
          completer.completeError(e);
        } finally {
          NfcManager.instance.stopSession();
        }
      },
      onError: (e) async {
        completer.completeError(e);
        return Future.value();
      },
    );

    return completer.future;
  }

  static Future<Uint8List?> readFromNFC() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      throw NFCNotAvailableException();
    }

    Completer<Uint8List?> completer = Completer();

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          Ndef? ndef = Ndef.from(tag);
          if (ndef == null) {
            throw NFCReadException('Tag is not NDEF formatted');
          }

          NdefMessage? message = await ndef.read();
          if (message.records.isEmpty) {
            throw NFCReadException('Empty or invalid NDEF message');
          }

          final record = message.records.first;
          completer.complete(record.payload);
        } catch (e) {
          completer.completeError(e);
        } finally {
          NfcManager.instance.stopSession();
        }
      },
      onError: (e) async {
        completer.completeError(e);
        return Future.value();
      },
    );
    return null;
  }
}

class NFCNotAvailableException implements Exception {
  @override
  String toString() => 'NFC is not available on this device';
}

class NFCWriteException implements Exception {
  final String message;
  NFCWriteException(this.message);
  @override
  String toString() => 'NFC Write Error: $message';
}

class NFCReadException implements Exception {
  final String message;
  NFCReadException(this.message);
  @override
  String toString() => 'NFC Read Error: $message';
}
