import 'dart:io';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../schema.dart';
import 'interfaces.dart';
import 'paths.dart';

class StoreBlob implements BlobService, BlobIngester {
  Directory root;

  StoreBlob(this.root);

  Future<Digest> upload(
    Stream<List<int>> input$, {
    String? uuid,
    Digest? digest,
  }) async {
    if (digest != null) {
      try {
        await stat(digest);
        return digest;
      } catch (e) {}
    }

    var uploadedBlob = PathUploads(uuid ?? Uuid().v1()).path(root) as File;

    await uploadedBlob.create(recursive: true);
    await input$.pipe(uploadedBlob.openWrite());

    digest = await Digest.fromStream(uploadedBlob.openRead());

    try {
      await stat(digest);
      await uploadedBlob.delete();
      return digest;
    } catch (_) {
      var fileBlobData = PathBlobData(digest).path(root) as File;
      await fileBlobData.create(recursive: true);
      await uploadedBlob.rename(fileBlobData.absolute.path);
      return digest;
    }
  }

  @override
  Future<Descriptor> stat(digest) async {
    var dataFile = PathBlobData(digest).path(root) as File;

    if (await dataFile.exists()) {
      var fi = await dataFile.stat();

      return Descriptor(
        digest: digest,
        mediaType: "application/octet-stream",
        size: fi.size,
      );
    }

    throw ErrBlobUnknown(digest: digest);
  }

  @override
  Future<void> delete(digest) {
    var fileBlobData = PathBlobData(digest).path(root) as File;
    return fileBlobData.delete(recursive: true);
  }

  @override
  Future<Uint8List> get(digest) {
    var fileBlobData = PathBlobData(digest).path(root) as File;
    return fileBlobData.readAsBytes();
  }

  @override
  Future<Stream<List<int>>> openRead(
    digest, {
    int? start,
    int? end,
  }) async {
    var fileBlobData = PathBlobData(digest).path(root) as File;
    return fileBlobData.openRead(start, end);
  }

  @override
  Future<IOSink> openWrite(digest) async {
    var fileBlobData = PathBlobData(digest).path(root) as File;
    await fileBlobData.create(recursive: true);
    return fileBlobData.openWrite();
  }
}
