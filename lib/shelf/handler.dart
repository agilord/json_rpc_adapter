import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../json_rpc_adapter.dart';
export '../json_rpc_adapter.dart';

typedef RpcMethod = Future Function(dynamic rq);

/// Utility class to register and handle RPC methods.
class JsonRpcShelfHandler {
  final _methods = <String, RpcMethod>{};
  final bool _omitRpcVersion;
  final Codec<Object?, List<int>> _jsonUtf8;

  JsonRpcShelfHandler({
    Map<String, RpcMethod>? methods,
    JsonCodec? jsonCodec,
    bool? omitRpcVersion,
  }) : _jsonUtf8 = (jsonCodec ?? json).fuse(utf8),
       _omitRpcVersion = omitRpcVersion ?? false {
    if (methods != null) _methods.addAll(methods);
  }

  void registerMethod(String method, RpcMethod fn) {
    if (_methods.containsKey(method)) {
      throw ArgumentError('Method "$method" is already registered.');
    }
    _methods[method] = fn;
  }

  Future<Response?> handler(Request request) async {
    final rq = await _jsonUtf8.decoder.bind(request.read()).single;
    if (rq is! Map<String, dynamic>) {
      return null;
    }
    final method = rq['method'] as String?;
    final params = rq['params'];
    final id = rq['id'];
    if (!_methods.containsKey(method)) {
      return null;
    }

    try {
      final rs = await _methods[method!]!(params);
      return Response(
        200,
        body: _jsonUtf8.encode({
          if (!_omitRpcVersion) 'jsonrpc': '2.0',
          if (id != null) 'id': id,
          'result': rs,
        }),
        headers: {'Content-Type': 'application/json'},
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
        body: _jsonUtf8.encode({
          if (!_omitRpcVersion) 'jsonrpc': '2.0',
          if (id != null) 'id': id,
          'error': error,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
