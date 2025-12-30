import 'dart:convert';

class CameraMacOSException implements Exception {
  CameraMacOSException({
    this.code = '',
    this.message = '',
    this.details,
  });

  factory CameraMacOSException.fromMap(Map<String, dynamic> map) {
    return CameraMacOSException(
      code: map['code'] ?? '',
      message: map['message'] ?? '',
      details: map['details'],
    );
  }
  String code;
  String message;
  Object? details;

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'message': message,
      'details': details,
    };
  }

  String toJson() => json.encode(toMap());
}
