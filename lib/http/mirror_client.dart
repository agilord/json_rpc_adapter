import 'dart:async';
import 'dart:mirrors';

import '../src/_mirrors.dart';

import 'client.dart';
export 'client.dart';

/// Utility class to call RPC methods over HTTP.
/// Uses mirrors to map JSON-RPC methods to Dart API.
abstract class ReflectedApiClient<T> {
  final JsonRpcHttpClient _client;
  final _methods = <Symbol, Method>{};

  ReflectedApiClient(this._client, [List<Type> types]) {
    _registerType(T);
    types?.forEach(_registerType);
  }

  Future<void> close() async {
    _client.close();
  }

  void _registerType(Type t) {
    for (final m in reflectMethods(t)) {
      final key = Symbol(m.name);
      if (_methods.containsKey(key)) {
        throw ArgumentError('Method already registered: ${m.name}.');
      }
      _methods[key] = m;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final m = _methods[invocation.memberName];
    if (m == null) {
      throw NoSuchMethodError.withInvocation(this, invocation);
    }
    final c = m.outputType.qualifiedName.toString() == 'Symbol("void")'
        ? reflect(Completer<void>())
        : (reflectType(Completer, [m.outputType.reflectedType]) as ClassMirror)
            .newInstance(Symbol(''), []);

    _client
        .invoke(
            m.name,
            invocation.positionalArguments.isEmpty
                ? null
                : invocation.positionalArguments.single)
        .then(
      (v) {
        if (m.outputIsJsonNative) return v;
        return m.outputClass.newInstance(Symbol('fromJson'), [v]).reflectee;
      },
    ).then(
      (r) {
        c.invoke(Symbol('complete'), [r]);
      },
      onError: (e, st) {
        c.invoke(Symbol('completeError'), [e, st]);
      },
    );

    return c.getField(Symbol('future')).reflectee;
  }
}
