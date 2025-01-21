import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import 'buffered_sender_keystore.dart';

class DistributionKeyGeneratorTest {
  static SenderKeyDistributionMessageWrapper? message = null;
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E2EE Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GroupChatScreen(),
    );
  }
}

class GroupChatScreen extends StatefulWidget {
  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  String message = "Hello, group!";
  String encryptedMessage = "";
  String decryptedMessage = "";

  final senderKeystore = BufferedSenderKeystore();
  final deviceId = 1111;
  final spaceId = "111";

  @override
  void initState() {
    super.initState();

    _init();

    // _workingSolution();
  }



  Future<void> _init() async {
    // Initialize GroupSessionBuilder for Alice and Bob

    final groupAddress = SignalProtocolAddress(spaceId, deviceId);
    final sessionBuilder = GroupSessionBuilder(senderKeystore);
    final senderKey = SenderKeyName(spaceId, groupAddress);
    DistributionKeyGeneratorTest.message =
        await sessionBuilder.create(senderKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('E2EE Group Messaging'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Original Message: $message",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              "Encrypted Message: $encryptedMessage",
              style: TextStyle(fontSize: 16, color: Colors.blue),
            ),
            SizedBox(height: 16),
            Text(
              "Decrypted Message: $decryptedMessage",
              style: TextStyle(fontSize: 16, color: Colors.green),
            ),
            OutlinedButton(
                onPressed: () {
                  sendMessage();
                },
                child: Text("Encypt")),
            OutlinedButton(
                onPressed: () {
                  receive();
                },
                child: Text("receive"))
          ],
        ),
      ),
    );
  }

  void sendMessage() async {
    setState(() {
      encryptedMessage = "";
      decryptedMessage = "";
    });
    final groupAddress = SignalProtocolAddress(spaceId, deviceId);
    final senderKey = SenderKeyName(spaceId, groupAddress);

    await GroupSessionBuilder(senderKeystore)
        .process(senderKey, DistributionKeyGeneratorTest.message!);

    final aliceGroupCipher = GroupCipher(senderKeystore, senderKey);

    final ciphertext =
        await aliceGroupCipher.encrypt(Uint8List.fromList(message.codeUnits));
    final encrypted = String.fromCharCodes(ciphertext);

    setState(() {
      encryptedMessage = encrypted;
    });
  }

  void receive() async {
    final groupAddress = SignalProtocolAddress(spaceId, deviceId);
    final senderKey = SenderKeyName(spaceId, groupAddress);

    await GroupSessionBuilder(senderKeystore)
        .process(senderKey, DistributionKeyGeneratorTest.message!);

    final aliceGroupCipher = GroupCipher(senderKeystore, senderKey);

    final plaintext = await aliceGroupCipher
        .decrypt(Uint8List.fromList(encryptedMessage.codeUnits));
    final decryptedByBob = String.fromCharCodes(plaintext);

    setState(() {
      decryptedMessage = "Bob: $decryptedByBob";
    });
  }

  Future<void> _workingSolution() async {
    // Initialize Alice's identity
    const aliceAddress = SignalProtocolAddress('+00000000001', 1);
    const groupSenderKey = SenderKeyName('group-123', aliceAddress);

    final aliceStore = InMemorySenderKeyStore();

    // Initialize Bob's identity
    final bobStore = InMemorySenderKeyStore();

    // Initialize GroupSessionBuilder for Alice and Bob
    final groupSessionAlice = GroupSessionBuilder(aliceStore);
    final groupSessionBob = GroupSessionBuilder(bobStore);

    final senderKeyDistributionMessage =
    await groupSessionAlice.create(groupSenderKey);

    // Bob processes Alice's group session
    groupSessionBob.process(groupSenderKey, senderKeyDistributionMessage);

    // Create GroupCiphers
    final aliceGroupCipher = GroupCipher(aliceStore, groupSenderKey);
    final bobGroupCipher = GroupCipher(bobStore, groupSenderKey);

    final ciphertext =
    await aliceGroupCipher.encrypt(Uint8List.fromList(message.codeUnits));
    final encrypted = String.fromCharCodes(ciphertext);

    final plaintext =
    await bobGroupCipher.decrypt(Uint8List.fromList(encrypted.codeUnits));
    final decryptedByBob = String.fromCharCodes(plaintext);

    setState(() {
      encryptedMessage = encrypted;
      decryptedMessage = "Bob: $decryptedByBob";
    });
  }

}



