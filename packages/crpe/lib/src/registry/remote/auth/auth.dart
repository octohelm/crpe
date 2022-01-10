import 'dart:convert';

import 'package:crpe/extension.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:roundtripper/roundtripper.dart';

import 'repository_scope.dart';
import 'token.dart';

class HttpAuth implements RoundTripBuilder {
  String? username;
  String? password;

  HttpAuth({
    this.username,
    this.password,
  });

  final Map<String, Token> _tokens = {};

  Token? validTokenFor(String scope) {
    return (_tokens[scope]?.valid() ?? false) ? _tokens[scope] : null;
  }

  @override
  RoundTrip build(RoundTrip next) {
    return (request) async {
      var tok = validTokenFor(
        RepositoryScope.fromUri(request.method, request.uri).toString(),
      );

      if (tok != null) {
        return next(
          request.copyWith(
            headers: tok.applyAuthHeader(request.headers ?? {}),
          ),
        );
      }

      try {
        return await next(request);
      } on ResponseException catch (err) {
        if (err.statusCode != HttpStatus.unauthorized) {
          rethrow;
        }

        var token = await exchangeTokenIfNeed(
          next,
          err.response?.headers["www-authenticate"]?.first ?? "",
        );

        if (token != null) {
          return retryWithToken(next, token, request);
        }

        return err.response!;
      }
    };
  }

  retryWithToken(RoundTrip next, Token token, Request request) {
    return next(
      request.copyWith(
        headers: token.applyAuthHeader(request.headers ?? {}),
      ),
    );
  }

  Future<Token?> exchangeTokenIfNeed(
    RoundTrip rt,
    String wwwAuthHeader,
  ) async {
    var params = parseWwwAuthHeader(wwwAuthHeader);

    if (params["realm"] != "") {
      var scope = params["scope"]?.let((v) => v) ?? "";

      var resp = await rt(
        Request.uri(
          params["realm"]!,
          method: "GET",
          queryParameters: {
            ...?params["service"]?.let((v) => {"service": v}),
            ...?params["scope"]?.let((v) => {"scope": v}),
          },
          headers: applyAuthHeaderIfNeed({}),
        ),
      );

      _tokens[scope] = Token.fromJson({
        ...(await resp.json()),
        "type": params["type"],
      });

      return _tokens[scope];
    }

    return null;
  }

  Map<String, String?> parseWwwAuthHeader(String wwwAuthHeader) {
    return wwwAuthHeader
        .split(RegExp(r'[, ]'))
        .foldIndexed<Map<String, String?>>({}, (i, ret, v) {
      if (i == 0) {
        return {
          ...ret,
          "type": v,
        };
      }

      return {
        ...ret,
        ...Uri.splitQueryString(v).map(
          (key, value) => MapEntry(
            key,
            _unquote(value),
          ),
        ),
      };
    });
  }

  String _unquote(String value) =>
      value[0] == '"' ? value.substring(1, value.length - 1) : value;

  Map<String, String> applyAuthHeaderIfNeed(Map<String, String> headers) {
    return username?.let((username) => {
              ...headers,
              "authorization":
                  "Basic ${base64Encode(utf8.encode("$username:$password"))}"
            }) ??
        headers;
  }
}
