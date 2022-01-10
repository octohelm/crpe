abstract class StatusError implements Exception {
  int get status;

  String get code;

  static Map<String, dynamic> convertToJson(StatusError s) {
    return {
      "code": s.code,
      "message": s.toString(),
      "detail": s,
    };
  }
}
