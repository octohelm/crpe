import 'dart:io';

import 'package:contextdart/contextdart.dart';
import 'package:crpe/extension.dart';
import 'package:crpe/kubepkg.dart';
import 'package:crpe/registry.dart';
import 'package:roundtripper/roundtripbuilders.dart';
import 'package:roundtripper/roundtripper.dart';
import 'package:rxdart/rxdart.dart';

class NodeMeta {
  final String ip;
  final String id;
  final List<String>? platforms;

  static const httpHeader = "X-Node-Agent";

  const NodeMeta({
    required this.id,
    required this.ip,
    this.platforms,
  });

  List<String> get _defaultPlatforms => ["linux/amd64", "linux/arm64"];

  factory NodeMeta.fromHeaders(String ip, Map<String, String> headers) {
    var hv = HeaderValue.parse(
      headers[httpHeader.toLowerCase()] ?? "",
    );

    return NodeMeta(
      ip: ip,
      id: hv.value,
      platforms: hv.parameters["platforms"]?.split(","),
    );
  }

  String normalize() {
    return "${id}; platforms=${(platforms ?? _defaultPlatforms).join(",")}";
  }
}

class NodeAdapter {
  int port;

  NodeAdapter({required this.port});

  Client get client {
    return Client(
      roundTripBuilders: [
        RequestBodyConvert(),
        RoundTripperThrowResponseError(),
      ],
    );
  }

  String endpoint(String ip) {
    return "http://${ip}:${port}";
  }

  Future<NodeMeta> find(String ip) async {
    var ctx = Context.withTimeout(Duration(seconds: 1));

    var req = Request.uri("${endpoint(ip)}/kubepkgs", method: "HEAD");

    var resp = await ctx.run(
      () => client.fetch(req),
    );

    return NodeMeta.fromHeaders(
      ip,
      resp.headers.map((key, value) => MapEntry(key, value.first)),
    );
  }

  Future upload(
    String ip,
    Digest digest,
    Stream<List<int>> tgzFile, {
    int? size,
    Sink<Progress>? process$,
  }) async {
    var p = Progress(total: size ?? 0);

    var req = Request(
      uri: Uri.parse("${endpoint(ip)}/kubepkgs"),
      method: "PUT",
      headers: size?.let((s) => {
            "content-length": "${s}",
            "content-digest": digest.toString(),
          }),
      requestBody: tgzFile.doOnData((data) => process$?.add(
            p = p.incrComplete(data.length),
          )),
    );

    return await client.fetch(req);
  }

  Future<List<KubePkg>> getKubePkgs(String ip) async {
    var req = Request.uri("${endpoint(ip)}/kubepkgs", method: "GET");

    var ctx = Context.withTimeout(Duration(seconds: 5));

    var resp = await ctx.run(
      () => client.fetch(req),
    );

    return (await resp.json() as List<dynamic>)
        .map((item) => KubePkg.fromJson(item))
        .toList();
  }

  Stream<NodeMeta> scan(String ip) {
    var parts = ip.split(".").map((e) => int.parse(e)).toList();
    return _findDevice(parts);
  }

  Stream<NodeMeta> _findDevice(
    List<int> parts,
  ) {
    var workers = 16;
    var ps$ = PublishSubject<NodeMeta>();

    () async {
      for (var i = 0; i < 256 / workers; i++) {
        if (ps$.isClosed) {
          return;
        }

        await Future.wait(List.generate(
          workers,
          (j) => [parts[0], parts[1], parts[2], workers * j + i],
        ).map((p) async {
          try {
            var endpoint = await find(p.join("."));
            ps$.add(endpoint);
          } catch (_) {}
        }));
      }
    }();

    return ps$;
  }
}
