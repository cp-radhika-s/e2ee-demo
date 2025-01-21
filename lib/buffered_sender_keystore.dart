import 'dart:collection';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class BufferedSenderKeystore extends SenderKeyStore {


  final _store = HashMap<SenderKeyName, SenderKeyRecord>();

  @override
  Future<SenderKeyRecord> loadSenderKey(SenderKeyName senderKeyName) async {
    try {
      final record = _store[senderKeyName];
      if (record == null) {
        return SenderKeyRecord();
      } else {
        return SenderKeyRecord.fromSerialized(record.serialize());
      }
    } on Exception catch (e) {
      throw AssertionError(e);
    }
  }

  @override
  Future<void> storeSenderKey(SenderKeyName senderKeyName,
      SenderKeyRecord record) async {
    _store[senderKeyName] = record;
  }
}