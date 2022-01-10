import 'dart:typed_data';

import 'package:crpe/registry.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:roundtripper/roundtripbuilders/request_log.dart';
import 'package:roundtripper/roundtripper.dart';

import 'auth/auth.dart';

part '__generated__/registry_remote.freezed.dart';
part '__generated__/registry_remote.g.dart';

@freezed
class RegistryRemoteOptions with _$RegistryRemoteOptions {
  RegistryRemoteOptions._();

  factory RegistryRemoteOptions({
    required String endpoint,
    String? username,
    String? password,
  }) = _RegistryRemoteOptions;

  factory RegistryRemoteOptions.fromJson(Map<String, dynamic> json) =>
      _RegistryRemoteOptions.fromJson(json);

  factory RegistryRemoteOptions.fromUri(String endpoint) {
    var u = Uri.parse(endpoint);

    var parts = u.userInfo.split(":");

    return RegistryRemoteOptions(
      endpoint: u.replace(userInfo: "").toString(),
      username: parts.firstOrNull,
      password: parts.length == 2 ? parts.lastOrNull : null,
    );
  }

  String text() {
    return Uri.parse(endpoint).replace(userInfo: username ?? "").toString();
  }
}

class RegistryRemote {
  RegistryRemoteOptions options;

  RegistryRemote(this.options);

  Client? _client;

  Client get client {
    _client ??= Client(
      roundTripBuilders: [
        HttpAuth(
          username: options.username,
          password: options.password,
        ),
        RoundTripperThrowResponseError(),
        RequestLog(),
      ],
    );
    return _client!;
  }

  Future<Response> apiCheck() async {
    return await client.fetch(Request.uri(
      "${options.endpoint}/v2/",
      method: "GET",
    ));
  }

  Future<String> existsManifest(String name,
      [String? tagOrDigest = "latest"]) async {
    var resp = await client.fetch(Request.uri(
      "${options.endpoint}/v2/$name/manifests/$tagOrDigest",
      method: "HEAD",
      headers: {
        "accept": acceptedManifests,
      },
    ));

    return resp.headers["docker-content-digest"]?.first ?? "";
  }

  Future<Manifest> getManifest(
    String name, {
    String tagOrDigest = "latest",
  }) async {
    var resp = await client.fetch(
      Request.uri(
        "${options.endpoint}/v2/$name/manifests/$tagOrDigest",
        method: "GET",
        headers: {
          "accept": acceptedManifests,
        },
      ),
    );

    var d = resp.headers["docker-content-digest"]?.first ?? "";

    return Manifest.fromManifestJsonRaw(
      name,
      Digest.fromJson(d),
      Uint8List.fromList(await resp.blob()),
    );
  }

  Future<Manifest> manifest(String name, String tagOrDigest) async {
    var d = await existsManifest(name, tagOrDigest);
    if (d == "") {
      throw HttpStatus.notFound;
    }
    return await getManifest(name, tagOrDigest: d);
  }

  Future<Response> checkBlob(
    String name,
    Digest digest, {
    int? start,
    int? end,
  }) async {
    return await client.fetch(
      Request.uri(
        "${options.endpoint}/v2/$name/blobs/$digest",
        method: "HEAD",
        headers: (start != null || end != null)
            ? {"Range": "bytes=${start ?? 0}-${end ?? 0}"}
            : null,
      ),
    );
  }

  Future<Response> blob(
    String name,
    Digest digest, {
    int? start,
    int? end,
  }) async {
    return await client.fetch(
      Request.uri(
        "${options.endpoint}/v2/$name/blobs/$digest",
        method: "GET",
        headers: (start != null || end != null)
            ? {"Range": "bytes=${start ?? 0}-${end ?? 0}"}
            : null,
      ),
    );
  }
}
