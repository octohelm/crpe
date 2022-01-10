import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:roundtripper/roundtripper.dart';

part '__generated__/response_error.freezed.dart';
part '__generated__/response_error.g.dart';

@freezed
class Error with _$Error {
  factory Error({
    required String code,
    required String message,
    dynamic detail,
  }) = _Error;

  factory Error.fromJson(Map<String, dynamic> json) => _Error.fromJson(json);
}

@freezed
class ResponseError with _$ResponseError {
  factory ResponseError({
    required List<Error>? errors,
  }) = _ResponseError;

  factory ResponseError.fromJson(Map<String, dynamic> json) =>
      _ResponseError.fromJson(json);
}

class RoundTripperThrowResponseError implements RoundTripBuilder {
  RoundTripperThrowResponseError();

  @override
  RoundTrip build(RoundTrip next) {
    return (request) async {
      var resp = await next(request);
      if (resp.statusCode >= HttpStatus.badRequest) {
        var bytes = await resp.blob();
        if (bytes.isNotEmpty &&
            (resp.headers["content-type"]?.contains("json") ?? false)) {
          resp.body = ResponseError.fromJson(await resp.json());
          throw ResponseException(
            resp.statusCode,
            response: resp,
          );
        } else {
          resp.body = resp.text();
          throw ResponseException(resp.statusCode, response: resp);
        }
      }
      return resp;
    };
  }
}
