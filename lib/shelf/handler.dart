import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../json_rpc_adapter.dart';
export '../json_rpc_adapter.dart';

typedef RpcMethod = Future Function(dynamic rq);

/// Utility class to register and handle RPC methods.
class JsonRpcShelfHandler {
  final _methods = <String, RpcMethod>{};
  final bool _omitRpcVersion;

  JsonRpcShelfHandler({
    Map<String, RpcMethod> methods,
    bool omitRpcVersion,
  }) : _omitRpcVersion = omitRpcVersion ?? false {
    if (methods != null) _methods.addAll(methods);
  }

  void registerMethod(String method, RpcMethod fn) {
    if (_methods.containsKey(method)) {
      throw ArgumentError('Method "$method" is already registered.');
    }
    _methods[method] = fn;
  }

  Future<Response> handler(Request request) async {
    final body = await request.readAsString();
    final rq = json.decode(body) as Map<String, dynamic>;
    final method = rq['method'] as String;
    final params = rq['params'];
    final id = rq['id'];
    if (!_methods.containsKey(method)) {
      return null;
    }

    try {
      final rs = await _methods[method](params);
      return Response(
        200,
        body: json.encode({
          if (!_omitRpcVersion) 'jsonrpc': '2.0',
          if (id != null) 'id': id,
          'result': rs,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );
    } catch (e, _) {
      final ex = e is RpcException ? e : ServerException(e.toString());
      final error = {
        'code': ex.code,
        'message': ex.message,
        if (ex.data != null) 'data': ex.data,
      };

      return Response(
        400,
        body: json.encode({
          if (!_omitRpcVersion) 'jsonrpc': '2.0',
          if (id != null) 'id': id,
          'error': error,
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );
    }
  }
}
