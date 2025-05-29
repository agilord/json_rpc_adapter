## Automatic RPC bindings using mirrors

Takes an abstract class API definition with at most one argument on each method:

```dart
abstract class TestApi {
  Future<ObjRs> incrementObject(ObjRq rq);
  Future<String> incrementInt(int x);

  Future<void> setter(int x);
  /// Note: `int?` is not supported here yet, only non-null `int`.
  Future<int?> getter();
}
```

Use reflection to get a `shelf` handler:

```dart
    final api = TestApiImpl();
    final handler = JsonRpcShelfHandler()
      ..registerApi<TestApi>(api);
```

User reflection to get a `http`-based client:

```dart
class TestApiClient extends ReflectedApiClient<TestApi> implements TestApi {
  TestApiClient(super.client);
}
```

```dart
    final client = JsonRpcHttpClient(
      endpoint: 'http://localhost:8080/',
    );
    final reflectedApi = TestApiClient(client);
```

## See more

See usage in the test directory:
https://github.com/agilord/json_rpc_adapter/tree/master/test
