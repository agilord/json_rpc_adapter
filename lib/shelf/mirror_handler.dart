import 'dart:mirrors';

import '../src/_mirrors.dart';

import 'handler.dart';

/// Extends [JsonRpcShelfHandler] with mirror-based API registration.
extension JsonRpcShelfHandlerMirror on JsonRpcShelfHandler {
  /// Registers [T] as an API.
  void registerApi<T>(T instance) {
    final instanz = reflect(instance);
    for (final method in reflectMethods(T)) {
      registerMethod(method.name, (js) async {
        final param = method.inputIsJsonNative
            ? js
            : method.inputClass!
                .newInstance(Symbol('fromJson'), [js]).reflectee;
        final rsf = instanz.invoke(
          Symbol(method.name),
          [if (method.inputClass != null) param],
        ).reflectee as Future?;
        final rs = await rsf;
        if (method.outputIsJsonNative) {
          return rs;
        } else {
          return reflect(rs).invoke(Symbol('toJson'), []).reflectee;
        }
      });
    }
  }
}
