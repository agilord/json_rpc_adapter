import 'package:json_rpc_2/error_code.dart';
import 'package:json_rpc_2/json_rpc_2.dart' show RpcException;

export 'package:json_rpc_2/json_rpc_2.dart' show RpcException;

/// Exception thrown when a parser error occurs.
class ParseException extends RpcException {
  ParseException(String message) : super(PARSE_ERROR, message);
}

/// Exception thrown when an invalid request is received.
class InvalidRequestException extends RpcException {
  InvalidRequestException(String message) : super(INVALID_REQUEST, message);
}

/// Exception thrown when the method is not found.
class MethodNotFoundException extends RpcException {
  MethodNotFoundException(String message) : super(METHOD_NOT_FOUND, message);

  MethodNotFoundException.withMethodName(String methodName)
      : super.methodNotFound('Method `$methodName` not found.');
}

/// Exception thrown when the parameters are invalid.
class InvalidParamsException extends RpcException {
  InvalidParamsException(String message) : super.invalidParams(message);
}

/// Exception thrown when there was an unhandled internal exception.
class InternalException extends RpcException {
  InternalException(String message) : super(INTERNAL_ERROR, message);
}

/// Exception thrown when there was a server error.
class ServerException extends RpcException {
  ServerException(String message, {data})
      : super(SERVER_ERROR, message, data: data);
}

typedef RpcExceptionDecoderFn = RpcException Function(
    int code, String message, dynamic data);

class RpcExceptionDecoder {
  final _decoders = <int, RpcExceptionDecoderFn>{
    PARSE_ERROR: (c, m, d) => ParseException(m),
    INVALID_REQUEST: (c, m, d) => InvalidRequestException(m),
    METHOD_NOT_FOUND: (c, m, d) => MethodNotFoundException(m),
    INVALID_PARAMS: (c, m, d) => InvalidParamsException(m),
    INTERNAL_ERROR: (c, m, d) => InternalException(m),
    SERVER_ERROR: (c, m, d) => ServerException(m, data: d),
  };

  RpcExceptionDecoder([Map<int, RpcExceptionDecoderFn> decoders]) {
    decoders?.forEach(registerDecoder);
  }

  void registerDecoder(int code, RpcExceptionDecoderFn fn) {
    _decoders[code] = fn;
  }

  dynamic tryDecode(dynamic error) {
    if (error is Map && error.containsKey('code')) {
      final code = error['code'];
      final message = error['message'];
      final data = error['data'];
      if (code is int && message is String) {
        final decoder = _decoders[code];
        if (decoder != null) {
          return decoder(code, message, data);
        }
        return RpcException(code, message, data: data);
      }
    }
    return null;
  }
}
