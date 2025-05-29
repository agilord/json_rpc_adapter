abstract class TestApi {
  Future<ObjRs> incrementObject(ObjRq rq);
  Future<String> incrementInt(int x);

  Future<void> setter(int x);

  /// Note: `int?` is not supported here yet, only non-null `int`.
  Future<int?> getter();
}

class TestApiImpl implements TestApi {
  int? _value;

  @override
  Future<ObjRs> incrementObject(ObjRq rq) async {
    return ObjRs(rq.value! + 1);
  }

  @override
  Future<String> incrementInt(int x) async {
    return (x + 1).toString();
  }

  @override
  Future<void> setter(int x) async {
    _value = x;
  }

  @override
  Future<int?> getter() async {
    return _value;
  }
}

class ObjRq {
  final int? value;

  ObjRq(this.value);

  factory ObjRq.fromJson(Map<String, dynamic> json) =>
      ObjRq(json['value'] as int?);

  Map<String, dynamic> toJson() => <String, dynamic>{'value': value};
}

class ObjRs {
  final int? value;

  ObjRs(this.value);

  factory ObjRs.fromJson(Map<String, dynamic> json) =>
      ObjRs(json['value'] as int?);

  Map<String, dynamic> toJson() => <String, dynamic>{'value': value};
}
