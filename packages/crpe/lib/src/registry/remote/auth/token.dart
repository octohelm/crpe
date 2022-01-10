import 'package:freezed_annotation/freezed_annotation.dart';

part '__generated__/token.freezed.dart';
part '__generated__/token.g.dart';

@freezed
class Token with _$Token {
  Token._();

  factory Token({
    @JsonKey(name: "type") String? type,
    @JsonKey(name: "token") String? accessToken,
    @JsonKey(name: "access_token") String? token,
    @JsonKey(name: "expires_in") int? expiresIn,
    @JsonKey(name: "issued_at") DateTime? issuedAt,
  }) = _Token;

  factory Token.fromJson(Map<String, dynamic> json) => _Token.fromJson(json);

  bool valid() {
    return validToken != "" && !tokenExpires();
  }

  bool tokenExpires() => DateTime.now().isBefore(
        (issuedAt ?? DateTime.now())
            .add(Duration(seconds: (expiresIn ?? 30) - 30)),
      );

  String get validToken => (accessToken != "" ? accessToken : token) ?? "";

  Map<String, dynamic> applyAuthHeader(Map<String, dynamic> headers) {
    return {...headers, "authorization": "$type $validToken"};
  }
}
