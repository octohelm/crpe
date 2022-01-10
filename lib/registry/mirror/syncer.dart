import 'dart:async';

import 'package:crpe/extension/std.dart';
import 'package:crpe/flutter/flutter.dart';
import 'package:crpe/registry/mirror/mirror.dart';
import 'package:crpe/registry/mirror/types.dart';
import 'package:crpe/registry/schema/distribution.dart';
import 'package:crpe/registry/schema/manifest.dart';
import 'package:rxdart/rxdart.dart';

class Syncer {
  final BehaviorSubject<Map<Digest, MirrorJob>> statuses$ = BehaviorSubject();
  final BehaviorSubject<bool> done$ = BehaviorSubject();
  final RegistryMirror mirror;
  final PublishSubject<MirrorJob> _jobQueue$ = PublishSubject();

  Syncer(this.mirror);

  Future add(
    String name, {
    Digest? digest,
    String? tag,
  }) async {
    if (digest == null) {
      var d = await mirror.remote.manifest(name, tag ?? "latest");
      _jobQueue$.add(MirrorJob.manifest(
        name,
        d.digest!,
        tag: tag,
        raw: d.jsonRaw(),
      ));
      return;
    }
    _jobQueue$.add(MirrorJob.manifest(
      name,
      digest,
      tag: tag,
    ));
  }

  updateStatus(
    Digest digest, {
    MirrorJob Function(MirrorJob job)? update,
    MirrorJob? initial,
  }) {
    (statuses$.valueOrNull?[digest] ?? initial)?.let((job) {
      statuses$.add({
        ...?statuses$.valueOrNull,
        digest: update != null ? update(job) : job,
      });
    });
  }

  Future syncManifest(MirrorJob job) async {
    var repo = await mirror.local.repository(job.name);

    var raw = job.raw;

    if (raw == null) {
      var d = await mirror.remote.manifest(job.name, job.digest.toString());
      raw = d.jsonRaw();
    }

    var m = Manifest.fromManifestJsonRaw(job.name, job.digest, raw);
    await repo.manifests().put(job.digest, m);

    if (job.tag != null) {
      await repo.tags().tag(job.tag!, Descriptor.fromDigest(job.digest));
    }

    if (m is ManifestListSpec) {
      for (var sub in m.manifests) {
        if (mirror.options?.platforms?.contains(sub.platform!.normalize()) ??
            true) {
          if (!(await repo.manifests().exists(sub.digest!))) {
            _jobQueue$.add(MirrorJob.manifest(job.name, sub.digest!));
          }
        }
      }
    }

    if (m is ManifestSpec) {
      for (var l in m.layers) {
        try {
          var d = await repo.blobs().stat(l.digest!);
          if (d.size != l.size) {
            _jobQueue$.add(MirrorJob.blob(job.name, l.digest!, size: l.size));
          }
        } catch (e) {
          _jobQueue$.add(MirrorJob.blob(job.name, l.digest!, size: l.size));
        }
      }
    }

    updateStatus(
      job.digest,
      update: (j) => j.copyWith(
        stage: MirrorJobStage.success,
      ),
    );
  }

  Future syncBlob(MirrorJob job) async {
    var repo = await mirror.local.repository(job.name);

    var resp = await mirror.remote.blob(job.name, job.digest);

    var f = await repo.blobs().openWrite(job.digest);

    var complete = 0;

    await resp.responseBody.map((data) {
      complete += data.length;

      updateStatus(
        job.digest,
        update: (j) => j.copyWith(
          complete: complete,
          stage: MirrorJobStage.doing,
        ),
      );

      return data;
    }).pipe(f);

    updateStatus(
      job.digest,
      update: (j) => j.copyWith(
        complete: complete,
        stage: MirrorJobStage.success,
      ),
    );

    await f.close();
  }

  StreamSubscription? _sub;

  start() {
    _sub ??= _jobQueue$.stream.listen((job) async {
      if (job.stage == MirrorJobStage.todo) {
        updateStatus(job.digest, update: (job) => job, initial: job);

        try {
          if (job.type == MirrorJobType.manifest) {
            await syncManifest(job);
          } else if (job.type == MirrorJobType.blob) {
            await syncBlob(job);
          }
        } catch (e) {
          updateStatus(
            job.digest,
            update: (job) => job.copyWith(
              stage: MirrorJobStage.failed,
              error: e.toString(),
            ),
          );
        }
      }
    });
  }

  close() {
    _sub?.cancel();
    done$.add(true);
  }
}
