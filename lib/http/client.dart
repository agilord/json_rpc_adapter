import 'dart:convert';

import 'package:http/http.dart';

import '../json_rpc_adapter.dart';
export '../json_rpc_adapter.dart';

typedef ErrorDecoder = dynamic Function(dynamic error);

/// Utility class to call RPC methods over HTTP.
class JsonRpcHttpClient {
  final Client _client;
  final Uri _endpoint;
  final ErrorDecoder? _errorDecoder;
  final RpcExceptionDecoder _rpcExceptionDecoder;
  final Map<String, String>? _headers;
  final Codec<Object?, List<int>> _jsonUtf8;
  final bool _omitRequestId;
  final bool _omitRpcVersion;
  int _id = 0;

  JsonRpcHttpClient({
    Client? client,
    required /* String | Uri */ endpoint,
    JsonCodec? jsonCodec,
    ErrorDecoder? errorDecoder,
    RpcExceptionDecoder? rpcExceptionDecoder,
    Map<String, String>? headers,
    bool? omitRequestId,
    bool? omitRpcVersion,
  }) : _client = client ?? Client(),
       _endpoint = endpoint is Uri ? endpoint : Uri.parse(endpoint.toString()),
       _errorDecoder = errorDecoder,
       _rpcExceptionDecoder = rpcExceptionDecoder ?? RpcExceptionDecoder(),
       _headers = headers,
       _jsonUtf8 = (jsonCodec ?? json).fuse(utf8),
       _omitRequestId = omitRequestId ?? false,
       _omitRpcVersion = omitRpcVersion ?? false;

  Future invoke(String method, dynamic params) async {
    final rq = {
      if (!_omitRpcVersion) 'jsonrpc': '2.0',
      'method': method,
      if (params != null) 'params': params,
      if (!_omitRequestId) 'id': '${_id++}',
    };

    final request = Request('POST', _endpoint)
      ..bodyBytes = _jsonUtf8.encode(rq)
      ..headers['Content-Type'] = 'application/json';
    if (_headers != null) {
      request.headers.addAll(_headers);
    }
    final rs = await _client.send(request);
    final map = await _jsonUtf8.decoder.bind(rs.stream).single;
    if (map is! Map<String, dynamic>) {
      throw FormatException('Unknown response format: $map');
    }
    if (map['error'] != null) {
      final value = map['error'];
      var error = _rpcExceptionDecoder.tryDecode(value);
      if (_errorDecoder != null) {
        error ??= _errorDecoder(value);
      }
      error ??= InternalException('Not recognized error: $error');
      throw error as Exception;
    } else {
      return map['result'];
    }
  }

  /// Closes the underlying `package:http` client.
  void close() {
    _client.close();
  }
}
