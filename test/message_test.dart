import 'dart:async';
import 'dart:typed_data';

import 'package:dart_nats/dart_nats.dart';
import 'package:test/test.dart';

void main() {
  group('all', () {
    test('simple', () async {
      var client = Client();
      await client.connect(Uri.parse('ws://localhost:8080'), retryInterval: 1);
      var sub = client.sub('subject1');
      client.pub('subject1', Uint8List.fromList('message1'.codeUnits));
      var msg = await sub.stream.first;
      await client.close();
      expect(String.fromCharCodes(msg.byte), equals('message1'));
    });
    test('respond', () async {
      var server = Client();
      await server.connect(Uri.parse('ws://localhost:8080'));
      var service = server.sub('service');
      service.stream.listen((m) {
        m.respondString('respond');
      });

      var requester = Client();
      await requester.connect(Uri.parse('ws://localhost:8080'));
      var inbox = newInbox();
      var inboxSub = requester.sub(inbox);

      requester.pubString('service', 'request', replyTo: inbox);

      var receive = await inboxSub.stream.first;

      await requester.close();
      await service.close();
      expect(receive.string, equals('respond'));
    });
    test('resquest', () async {
      var server = Client();
      await server.connect(Uri.parse('ws://localhost:8080'));
      var service = server.sub('service');
      unawaited(service.stream.first.then((m) {
        m.respond(Uint8List.fromList('respond'.codeUnits));
      }));

      var client = Client();
      await client.connect(Uri.parse('ws://localhost:8080'));
      var receive = await client.request(
          'service', Uint8List.fromList('request'.codeUnits));

      await client.close();
      await service.close();
      expect(receive.string, equals('respond'));
    });
    test('long message', () async {
      var txt =
          '12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';
      var client = Client();
      await client.connect(Uri.parse('ws://localhost:8080'), retryInterval: 1);
      var sub = client.sub('subject1');
      client.pub('subject1', Uint8List.fromList(txt.codeUnits));
      // client.pub('subject1', Uint8List.fromList(txt.codeUnits));
      var msg = await sub.stream.first;
      // msg = await sub.stream.first;
      await client.close();
      expect(String.fromCharCodes(msg.byte), equals(txt));
    });
    test('message with header', () async {
      var txt = 'this is text';
      var client = Client();
      await client.connect(Uri.parse('ws://localhost:8080'), retryInterval: 1);
      var sub = client.sub('subject1');
      Map<String, String> headers = {};
      headers['key1'] = 'value1';
      headers['key2'] = 'value2';
      var header = Header(headers);
      client.pub('subject1', Uint8List.fromList(txt.codeUnits), header: header);
      var msg = await sub.stream.first;
      await client.close();
      expect(String.fromCharCodes(msg.byte), equals(txt));
      expect(msg.header, equals(header));
    });
  });
}
