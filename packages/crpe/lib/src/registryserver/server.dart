import 'dart:convert';
import 'dart:io';

import 'package:crpe/extension.dart';
import 'package:crpe/kubepkg.dart';
import 'package:crpe/registry.dart';
import 'package:logr/logr.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'client.dart';
import 'middleware/middleware.dart';
import 'middleware/middleware_log.dart';

part '__generated__/server.g.dart';

class RegistryRoutes implements MiddlewareBuilder {
  late RegistryLocal local;
  NodeMeta meta;
  RegistryRemote? remote;

  RegistryRoutes({
    required this.local,
    required this.meta,
    this.remote,
  });

  Registry? _registry;

  Map<String, String> withDeviceHeaders(Map<String, String> headers) {
    return {
      ...headers,
      NodeMeta.httpHeader: meta.normalize(),
    };
  }

  Registry get registry {
    _registry ??= remote?.let((r) => r.options.endpoint != ""
            ? RegistryProxy(
                local: local,
                remote: r,
              )
            : null) ??
        local;
    return _registry!;
  }

  KubePkgRegistry? _kubePkgRegistry;

  KubePkgRegistry get kubePkgRegistry {
    _kubePkgRegistry ??= KubePkgRegistry.fromRegistryLocal(local);
    return _kubePkgRegistry!;
  }

  static void serve(
    HttpServer s, {
    required RegistryLocal local,
    required NodeMeta meta,
    RegistryRemote? remote,
    Logger? logger,
  }) {
    var router = RegistryRoutes(local: local, remote: remote, meta: meta);

    logger?.info(
        "registry serve on ${s.address.host}:${s.port} for [${meta.normalize()}]");

    if (remote?.options.endpoint != "") {
      logger?.info("remote fallback (${remote?.options.endpoint}) enabled");
    }

    serveRequests(
      s,
      MiddlewareBuilder.composeMiddlewares([
        MiddlewareBuilder.injectContext(() => Logger.withLogger(logger)),
        MiddlewareLog(),
        router,
      ])(router.router),
    );
  }

  @Route.head("/v2/<name|.+>/manifests/<reference>")
  @Route.get("/v2/<name|.+>/manifests/<reference>")
  Future<Response> getManifest(
    Request request,
    String name,
    String reference,
  ) async {
    var repo = await registry.repository(name);

    Digest digest;

    try {
      digest = Digest.parse(reference);
    } catch (_) {
      digest = (await repo.tags().get(reference)).digest!;
    }

    var m = await repo.manifests().get(digest);

    var jsonRaw = m.jsonRaw();

    return Response.ok(
      request.method.toUpperCase() == "HEAD" ? "" : jsonRaw,
      headers: {
        "Content-Type": m.type(),
        "Content-Length": "${jsonRaw.length}",
        "Docker-Content-Digest": digest.toString(),
        "Etag": '"$digest"',
      },
    );
  }

  @Route.get("/v2/<name|.+>/blobs/<digest>")
  Future<Response> fetchBlob(
    Request request,
    String name,
    String digest,
  ) async {
    var repo = await registry.repository(name);
    var bs = repo.blobs();

    var d = await bs.stat(Digest.parse(digest));

    if (request.headers.containsKey("range")) {
      var rng = Range.parse(request.headers["range"]!);

      if (rng.unit == "bytes") {
        var end = (rng.end ?? d.size!) > d.size! ? d.size : rng.end;

        var o$ = await bs.openRead(d.digest!, start: rng.start, end: end);

        return Response(
          HttpStatus.partialContent,
          body: o$,
          headers: {
            "Docker-Content-Digest": d.digest!.toString(),
            "Content-Type": d.mediaType!.toString(),
            "Content-Length": o$.length,
            "Content-Range": "bytes ${rng.start}-$end/${d.size!.toString()}",
          },
        );
      }
    }

    var o$ = await bs.openRead(d.digest!);

    return Response.ok(
      o$,
      headers: {
        "Content-Type": d.mediaType!.toString(),
        "Content-Length": d.size!.toString(),
        "Docker-Content-Digest": d.digest!.toString(),
        "Etag": '"${d.digest!.toString()}"',
      },
    );
  }

  @Route.get('/v2/')
  Future<Response> apiVersionCheck(Request request) async {
    return Response.ok("", headers: {
      "Docker-Distribution-API-Version": "registry/v2",
    });
  }

  @Route.all("/mirrors/<path|.+>")
  @Route.all("/hub-prefix-mirrors/<path|.+>")
  Future<Response> mirrorX(
    Request request,
    String path,
  ) async {
    var pp = request.url.path.split("/");

    if (pp.first == "mirrors" || pp.first == "hub-prefix-mirrors") {
      pp.removeAt(0);
    }

    var mirror = pp.first;
    pp.removeAt(0);

    if (pp.first == "v2") {
      pp.removeAt(0);
    }

    if (pp.getOrNull(pp.length - 2) == "blobs") {
      return await fetchBlob(
        request,
        [
          mirror,
          ...pp.take(pp.length - 2),
        ].join("/"),
        pp.last,
      );
    }

    return await getManifest(
      request,
      [
        mirror,
        ...pp.take(pp.length - 2),
      ].join("/"),
      pp.last,
    );
  }

  Router get router => _$RegistryRoutesRouter(this);

  @override
  Handler build(Handler next) {
    return (request) async {
      Response response;

      try {
        response = await next(request);
      } catch (e) {
        if (e is StatusError) {
          response = Response(
            e.status,
            body: jsonEncode({
              "errors": [StatusError.convertToJson(e)],
            }),
            headers: {
              "Content-Type": "application/json; charset=utf-8",
            },
          );
        } else {
          response = Response(
            HttpStatus.internalServerError,
            body: jsonEncode({
              "errors": [
                {
                  "code": "INTERNAL_SERVER_ERROR",
                  "message": "$e",
                }
              ],
            }),
            headers: {
              "Content-Type": "application/json; charset=utf-8",
            },
          );
        }
      }

      return response.change(headers: {
        "Docker-Distribution-API-Version": "registry/v2",
      });
    };
  }
}
