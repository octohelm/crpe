import 'dart:io';

import 'package:crpe/registry/core/core.dart';
import 'package:crpe/registry/remote/remote.dart';
import 'package:crpe/registry/schema/distribution.dart';
import 'package:crpe/registry/schema/errorcodes.dart';
import 'package:roundtripper/roundtripper.dart';

class ProxyBlob implements BlobService {
  RegistryRemote client;
  BlobService local;
  String name;

  ProxyBlob({
    required this.name,
    required this.client,
    required this.local,
  });

  @override
  Future<void> delete(Digest digest) async {
    return;
  }

  @override
  Future<Descriptor> stat(Digest digest) async {
    try {
      return await local.stat(digest);
    } catch (e) {
      try {
        var resp = await client.checkBlob(name, digest);
        return Descriptor(
          size: resp.contentLength,
          mediaType: resp.headers["content-type"]?.first,
          digest: digest,
        );
      } on ResponseException catch (e) {
        if (e.statusCode == HttpStatus.notFound) {
          throw ErrBlobUnknown(digest: digest);
        }
        rethrow;
      }
    }
  }

  @override
  Future<Stream<List<int>>> openRead(
    Digest digest, {
    int? start,
    int? end,
  }) async {
    try {
      return await local.openRead(digest);
    } catch (e) {
      var resp = await client.blob(name, digest);
      var r = resp.responseBody.asBroadcastStream();
      var f = await local.openWrite(digest);
      r.pipe(f);
      return r;
    }
  }

  @override
  Future<List<int>> get(Digest digest) async {
    return (await openRead(digest)).expand((e) => e).toList();
  }

  @override
  Future<IOSink> openWrite(Digest digest) async {
    return await local.openWrite(digest);
  }
}
