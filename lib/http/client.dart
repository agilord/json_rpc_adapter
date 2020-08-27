import 'dart:convert';

import 'package:http/http.dart';
import 'package:meta/meta.dart';

import '../json_rpc_adapter.dart';
export '../json_rpc_adapter.dart';

typedef ErrorDecoder = dynamic Function(dynamic error);

/// Utility class to call RPC methods over HTTP.
class JsonRpcHttpClient {
  final Client _client;
  final Uri _endpoint;
  final ErrorDecoder _errorDecoder;
  final RpcExceptionDecoder _rpcExceptionDecoder;

  final bool _omitRequestId;
  final bool _omitRpcVersion;
  int _id = 0;

  JsonRpcHttpClient({
    Client client,
    @required /* String | Uri */ endpoint,
    ErrorDecoder errorDecoder,
    RpcExceptionDecoder rpcExceptionDecoder,
    bool omitRequestId,
    bool omitRpcVersion,
  })  : _client = client ?? Client(),
        _endpoint = endpoint is Uri ? endpoint : Uri.parse(endpoint.toString()),
        _errorDecoder = errorDecoder,
        _rpcExceptionDecoder = rpcExceptionDecoder ?? RpcExceptionDecoder(),
        _omitRequestId = omitRequestId ?? false,
        _omitRpcVersion = omitRpcVersion ?? false;

  Future invoke(String method, dynamic params) async {
    final rq = {
      if (!_omitRpcVersion) 'jsonrpc': '2.0',
      'method': method,
      if (params != null) 'params': params,
      if (!_omitRequestId) 'id': '${_id++}',
    };

    final rs = await _client.send(
      Request('POST', _endpoint)
        ..body = json.encode(rq)
        ..headers['Content-Type'] = 'application/json',
    );
    final body = await rs.stream.bytesToString();
    final map = json.decode(body) as Map<String, dynamic>;
    if (map['error'] != null) {
      final value = map['error'];
      dynamic error = _rpcExceptionDecoder?.tryDecode(value);
      if (_errorDecoder != null) {
        error ??= _errorDecoder(value);
      }
      error ??= InternalException('Not recognized error: $error');
      throw error;
    } else {
      return map['result'];
    }
  }

  /// Closes the underlying `package:http` client.
  void close() {
    _client.close();
  }
}
