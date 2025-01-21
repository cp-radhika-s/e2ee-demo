import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class DistributionKeyGeneratorTest {
  static SenderKeyDistributionMessageWrapper? message = null;
  static SignalProtocolAddress aliceAddress = SignalProtocolAddress('+00000000001', 1);
  static SenderKeyName groupSenderKey = SenderKeyName('group-123', aliceAddress);
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
  final message = "Hello, group!";
  String encryptedMessage = "";
  String decryptedMessage = "";
  final aliceStore = InMemorySenderKeyStore();


  @override
  void initState() {
    super.initState();

    //_init();
    _initializeServices();
  }
  Future<void> _init() async {
    final groupSessionAlice = GroupSessionBuilder(aliceStore);

    // Initialize GroupSessionBuilder for Alice and Bob

    DistributionKeyGeneratorTest.message  =
    await groupSessionAlice.create(DistributionKeyGeneratorTest.groupSenderKey);
    // Bob processes Alice's group session
  }


  Future<void> _initializeServices() async {
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

    final ciphertext = await aliceGroupCipher.encrypt(Uint8List.fromList(message.codeUnits));
    final encrypted =  String.fromCharCodes(ciphertext);

    final plaintext =
    await bobGroupCipher.decrypt(Uint8List.fromList(encrypted.codeUnits));
    final decryptedByBob =  String.fromCharCodes(plaintext);


    setState(() {
      encryptedMessage = encrypted;
      decryptedMessage = "Bob: $decryptedByBob";
    });
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
    // Create GroupCiphers
    final distributionMessage = DistributionKeyGeneratorTest.message!;
   // final aliceStore = InMemorySenderKeyStore();

    // // Bob processes Alice's group session
    // await GroupSessionBuilder(aliceStore).process(
    //     DistributionKeyGeneratorTest.groupSenderKey, distributionMessage);

    final aliceGroupCipher = GroupCipher(aliceStore, DistributionKeyGeneratorTest.groupSenderKey);

    final ciphertext = await aliceGroupCipher.encrypt(Uint8List.fromList(message.codeUnits));
    final encrypted =  String.fromCharCodes(ciphertext);

    setState(() {
      encryptedMessage = encrypted;
    });
  }

  void receive() async {
    // Initialize Alice's identity
    // const aliceAddress = SignalProtocolAddress('+00000000001', 1);
    // const groupSenderKey = SenderKeyName('group-123', aliceAddress);
    final bobStore = InMemorySenderKeyStore();


    // Initialize GroupSessionBuilder for Alice and Bob
    final groupSessionBob = GroupSessionBuilder(bobStore);
    final distributionMessage = DistributionKeyGeneratorTest.message!;

    // Bob processes Alice's group session
    await groupSessionBob.process(
        DistributionKeyGeneratorTest.groupSenderKey, distributionMessage!);

    // Create GroupCiphers
    final bobGroupCipher = GroupCipher(bobStore, DistributionKeyGeneratorTest.groupSenderKey);

    final plaintext =
    await bobGroupCipher.decrypt(Uint8List.fromList(encryptedMessage.codeUnits));
    final decryptedByBob =  String.fromCharCodes(plaintext);


    setState(() {
      decryptedMessage = "Bob: $decryptedByBob";
    });
  }
}
