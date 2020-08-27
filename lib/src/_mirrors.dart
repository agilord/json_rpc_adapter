import 'dart:mirrors';

import 'package:meta/meta.dart';

class Method {
  final String name;
  final ClassMirror inputClass;
  final bool inputIsJsonNative;
  final TypeMirror outputType;
  final ClassMirror outputClass;
  final bool outputIsJsonNative;

  Method({
    @required this.name,
    @required this.inputClass,
    @required this.inputIsJsonNative,
    @required this.outputType,
    @required this.outputClass,
    @required this.outputIsJsonNative,
  });
}

List<Method> reflectMethods(Type t) {
  final results = <Method>[];

  void addAll(ClassMirror clazz) {
    for (final entry in clazz.declarations.entries) {
      if (entry.value is! MethodMirror) continue;
      final method = entry.value as MethodMirror;
      if (!method.isRegularMethod) continue;
      if (method.isOperator) continue;
      if (method.parameters.length > 1) continue;
      if (method.qualifiedName.toString().contains('dart.core')) continue;

      ClassMirror inputClass;
      var inputIsJsonNative = true;
      if (method.parameters.length == 1) {
        inputClass = reflectClass(method.parameters.single.type.reflectedType);
        inputIsJsonNative = !inputClass.declarations.values
            .whereType<MethodMirror>()
            .any((m) => m.isRegularMethod && m.simpleName == Symbol('toJson'));
      }

      final outputType = method.returnType.typeArguments.single;
      final outputClass = outputType is ClassMirror ? outputType : null;
      final outputIsJsonNative = outputClass == null ||
          !outputClass.declarations.values.whereType<MethodMirror>().any(
              (m) => m.isRegularMethod && m.simpleName == Symbol('toJson'));
      final methodName = method.simpleName.toString().split('"')[1];
      results.add(Method(
        name: methodName,
        inputClass: inputClass,
        inputIsJsonNative: inputIsJsonNative,
        outputType: outputType,
        outputClass: outputClass,
        outputIsJsonNative: outputIsJsonNative,
      ));
    }
    for (final si in clazz.superinterfaces) {
      addAll(si);
    }
  }

  addAll(reflectClass(t));

  return results;
}
