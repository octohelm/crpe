import 'dart:async';

import 'package:registry/extension/std.dart';
import 'package:registry/mirror/mirror.dart';
import 'package:registry/schema/distribution.dart';
import 'package:registry/schema/manifest.dart';
import 'package:rxdart/rxdart.dart';

class Syncer {
  final BehaviorSubject<Map<Digest, MirrorJob>> statuses$ = BehaviorSubject();
  final BehaviorSubject<bool> done$ = BehaviorSubject();
  final RegistryMirror mirror;
  final PublishSubject<MirrorJob> _jobQueue$ = PublishSubject();

  Syncer(this.mirror);

  Future addWithImageTag(String name, String digest) async {
    var nameAndTag = name.split(":");
    if (nameAndTag.length == 2) {
      return await add(
        nameAndTag[0],
        tag: nameAndTag[1],
        digest: (digest != "").ifTrueOrNull(() => Digest.parse(digest)),
      );
    }
    var nameAndDigest = name.split("@");
    if (nameAndDigest.length == 2) {
      return await add(
        nameAndDigest[0],
        digest: Digest.parse(nameAndDigest[1]),
      );
    }
    return;
  }

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
      if (job.stage == MirrorJobStage.todo) {
        var d = await mirror.remote.manifest(job.name, job.digest.toString());
        raw = d.jsonRaw();
      } else {
        var d = await repo.manifests().get(job.digest);
        raw = d.jsonRaw();
      }
    }

    var m = Manifest.fromManifestJsonRaw(job.name, job.digest, raw);

    if (job.stage == MirrorJobStage.todo) {
      await repo.manifests().put(job.digest, m);

      if (job.tag != null) {
        await repo.tags().tag(job.tag!, Descriptor.fromDigest(job.digest));
      }
    }

    List<Digest> children = [];

    if (m is ManifestListSpec) {
      for (var sub in m.manifests) {
        if (mirror.requiredPlatform(sub.platform!)) {
          children.add(sub.digest!);
          _jobQueue$.add(MirrorJob.manifest(
            job.name,
            sub.digest!,
            platform: sub.platform!.normalize(),
          ));
        }
      }
    }

    if (m is ManifestSpec) {
      for (var l in m.references()) {
        children.add(l.digest!);

        var subJob = MirrorJob.blob(job.name, l.digest!, size: l.size);

        try {
          var d = await repo.blobs().stat(l.digest!);
          if (d.size != l.size) {
            _jobQueue$.add(subJob);
          } else {
            _jobQueue$.add(
              subJob.copyWith(
                stage: MirrorJobStage.success,
                complete: l.size,
              ),
            );
          }
        } catch (e) {
          _jobQueue$.add(subJob);
        }
      }
    }

    updateStatus(
      job.digest,
      update: (j) => j.copyWith(
        children: children,
        stage: MirrorJobStage.success,
      ),
    );
  }

  Future syncBlob(MirrorJob job) async {
    if (job.stage != MirrorJobStage.todo) {
      return;
    }

    var repo = await mirror.local.repository(job.name);

    var resp = await mirror.remote.blob(job.name, job.digest);

    var f = await repo.blobs().openWrite(job.digest);

    var complete$ = BehaviorSubject.seeded(0);

    complete$.bufferTime(const Duration(seconds: 1)).listen((complete) {
      if (complete.isNotEmpty) {
        updateStatus(
          job.digest,
          update: (j) => j.copyWith(
            complete: complete.last,
            stage: MirrorJobStage.doing,
          ),
        );
      }
    });

    await resp.responseBody.map((data) {
      complete$.value += data.length;
      return data;
    }).pipe(f);

    complete$.close();

    updateStatus(
      job.digest,
      update: (j) => j.copyWith(
        complete: complete$.value,
        stage: MirrorJobStage.success,
      ),
    );

    await f.close();
  }

  StreamSubscription? _sub;

  start() {
    _sub ??= _jobQueue$.stream.listen((job) async {
      updateStatus(job.digest, update: (job) => job, initial: job);

      try {
        switch (job.type) {
          case MirrorJobType.manifest:
            await syncManifest(job);
            break;
          case MirrorJobType.blob:
            await syncBlob(job);
            break;
          default:
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
    });
  }

  close() {
    _sub?.cancel();
    done$.add(true);
  }
}
