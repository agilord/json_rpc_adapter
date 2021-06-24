import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:json_rpc_adapter/shelf/handler.dart';
import 'package:json_rpc_adapter/shelf/mirror_handler.dart';

import 'shared_api.dart';

void main() {
  group('API mirror test', () {
    final api = TestApiImpl();
    final handler = JsonRpcShelfHandler(
      omitRpcVersion: true,
    )..registerApi<TestApi>(api);

    test('incrementObject', () async {
      final rs = await handler.handler(
        Request(
          'POST',
          Uri.parse('http://localhost/'),
          body: json.encode(
            {
              'method': 'incrementObject',
              'params': {
                'value': 7,
              }
            },
          ),
        ),
      );
      expect(json.decode(await rs!.readAsString()), {
        'result': {'value': 8}
      });
    });

    test('incrementInt', () async {
      final rs = await handler.handler(
        Request(
          'POST',
          Uri.parse('http://localhost/'),
          body: json.encode(
            {
              'method': 'incrementInt',
              'params': 6,
            },
          ),
        ),
      );
      expect(json.decode(await rs!.readAsString()), {
        'result': '7',
      });
    });

    test('getter returning null', () async {
      final rs = await handler.handler(
        Request(
          'POST',
          Uri.parse('http://localhost/'),
          body: json.encode(
            {
              'method': 'getter',
              'params': null,
            },
          ),
        ),
      );
      expect(json.decode(await rs!.readAsString()), {
        'result': null,
      });
    });

    test('setter', () async {
      final rs = await handler.handler(
        Request(
          'POST',
          Uri.parse('http://localhost/'),
          body: json.encode(
            {
              'method': 'setter',
              'params': 5,
            },
          ),
        ),
      );
      expect(json.decode(await rs!.readAsString()), {
        'result': null,
      });
    });

    test('getter', () async {
      final rs = await handler.handler(
        Request(
          'POST',
          Uri.parse('http://localhost/'),
          body: json.encode(
            {
              'method': 'getter',
              'params': null,
            },
          ),
        ),
      );
      expect(json.decode(await rs!.readAsString()), {
        'result': 5,
      });
    });
  });
}
