import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

import 'package:json_rpc_adapter/http/client.dart';
import 'package:json_rpc_adapter/http/mirror_client.dart';
import 'package:json_rpc_adapter/shelf/handler.dart';
import 'package:json_rpc_adapter/shelf/mirror_handler.dart';

import 'shared_api.dart';

void main() {
  group('mirror API client test', () {
    final api = TestApiImpl();
    final handler = JsonRpcShelfHandler(
      omitRpcVersion: true,
    )..registerApi<TestApi>(api);
    final mockClient = MockClient((rq) async {
      final rs = await handler.handler(shelf.Request(rq.method, rq.url,
          body: rq.bodyBytes, headers: rq.headers));
      return Response(await rs.readAsString(), rs.statusCode,
          headers: rs.headers);
    });
    final client = JsonRpcHttpClient(
      client: mockClient,
      endpoint: 'http://localhost/',
      omitRpcVersion: true,
    );
    final reflectedApi = TestApiClient(client);

    test('incrementObject', () async {
      final rs = await reflectedApi.incrementObject(ObjRq(7));
      expect(rs.toJson(), {'value': 8});
    });

    test('incrementInt', () async {
      final rs = await reflectedApi.incrementInt(6);
      expect(rs, '7');
    });

    test('getter returning null', () async {
      final rs = await reflectedApi.getter();
      expect(rs, null);
    });

    test('setter', () async {
      await reflectedApi.setter(5);
    });

    test('getter', () async {
      final rs = await reflectedApi.getter();
      expect(rs, 5);
    });
  });
}

class TestApiClient extends ReflectedApiClient<TestApi> implements TestApi {
  TestApiClient(JsonRpcHttpClient client) : super(client);
}
