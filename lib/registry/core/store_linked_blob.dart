import 'dart:io';

import 'package:crpe/registry/schema/distribution.dart';
import 'package:crpe/registry/schema/errorcodes.dart';

import 'interfaces.dart';

class StoreLinkedBlob implements BlobService {
  final String name;
  final BlobService blobService;
  final List<LinkPathFunc> linkPathFuncs;

  StoreLinkedBlob({
    required this.name,
    required this.linkPathFuncs,
    required this.blobService,
  });

  @override
  Future<Descriptor> stat(Digest digest) async {
    Digest? target;

    for (var linkPathFunc in linkPathFuncs) {
      try {
        target = await Digest.fromLinkFile(linkPathFunc(name, digest) as File);
        break;
      } catch (e) {
        //  ignore not found
        if (e is FileSystemException) {
          if (e.osError?.errorCode == 2) {
            continue;
          }
        }
        rethrow;
      }
    }

    if (target == null) {
      throw ErrBlobUnknown(digest: digest);
    }

    return blobService.stat(target);
  }

  @override
  Future<List<int>> get(Digest digest) async {
    var canonical = await stat(digest); // access check
    return blobService.get(canonical.digest!);
  }

  @override
  Future<Stream<List<int>>> openRead(
    digest, {
    int? start,
    int? end,
  }) async {
    var canonical = await stat(digest); // access check
    return blobService.openRead(canonical.digest!, start: start, end: end);
  }

  @override
  Future<void> delete(digest) {
    return blobService.delete(digest);
  }

  @override
  Future<IOSink> openWrite(digest) async {
    for (var linkPathFunc in linkPathFuncs) {
      var linkPath = linkPathFunc(name, digest) as File;
      await linkPath.create(recursive: true);
      await linkPath.writeAsString(digest.toString());
    }
    return blobService.openWrite(digest);
  }
}
