import 'dart:convert';
import 'dart:io';

import 'package:logr/logr.dart';
import 'package:registry/middleware/middleware.dart';
import 'package:registry/middleware/middleware_log.dart';
import 'package:registry/registry.dart';
import 'package:registry/schema/digest.dart';
import 'package:registry/schema/range.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'schema/statuserror.dart';

part '__generated__/registry_routes.g.dart';

class RegistryRoutes implements MiddlewareBuilder {
  late Registry registry;

  RegistryRoutes({
    required this.registry,
  });

  static void serve(HttpServer s, Registry r, [Logger? logger]) {
    var router = RegistryRoutes(registry: r);

    logger?.info("registry serve on ${s.address.host}:${s.port}");

    serveRequests(
      s,
      MiddlewareBuilder.composeMiddlewares([
        MiddlewareBuilder.injectContext(() => Logger.withLogger(logger)),
        MiddlewareLog(),
        router,
      ])(router.router),
    );
  }

  @Route.get('/mirrors/<mirror>/v2/')
  Future<Response> mirrorXApiVersionCheck(
    Request request,
    String mirror,
  ) async {
    return Response.ok("");
  }

  @Route.head("/mirrors/<mirror>/v2/<name|.+>/manifests/<reference>")
  @Route.get("/mirrors/<mirror>/v2/<name|.+>/manifests/<reference>")
  Future<Response> mirrorXGetManifest(
    Request request,
    String mirror,
    String name,
    String reference,
  ) async {
    return await getManifest(request, "$mirror/$name", reference);
  }

  @Route.head("/mirrors/<mirror>/v2/<name|.+>/blobs/<digest>")
  @Route.get("/mirrors/<mirror>/v2/<name|.+>/blobs/<digest>")
  Future<Response> mirrorXFetchBlob(
    Request request,
    String mirror,
    String name,
    String digest,
  ) async {
    return await fetchBlob(request, "$mirror/$name", digest);
  }

  @Route.get('/v2/')
  Future<Response> apiVersionCheck(Request request) async {
    return Response.ok("");
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
