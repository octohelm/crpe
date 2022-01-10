import 'dart:ui';

import 'package:crpeapp/flutter/flutter.dart';
import 'package:crpeapp/kubepkg/bloc_kube_pkg.dart';
import 'package:crpeapp/registry/registry.dart';
import 'package:registry/mirror/syncer.dart';
import 'package:registry/mirror/types.dart';
import 'package:registry/schema/distribution.dart';
import 'package:rxdart/rxdart.dart';

class RegistrySyncer extends HookWidget {
  const RegistrySyncer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var blocRegistry = BlocRegistry.watch(context);
    var mirror = blocRegistry.mirror;
    var blocKubePkg = BlocKubePkg.watch(context);
    var images = blocKubePkg.state.images();

    var s = useMemoized(() => Syncer(mirror), []);

    var jobStatusesState = useState<Map<Digest, MirrorJob>>({});

    useObservableEffect(() {
      return s.statuses$.doOnData((statuses) {
        jobStatusesState.value = statuses;
      });
    }, []);

    useEffect(() {
      s.start();
      return;
    }, []);

    useEffect(() {
      for (var tag in images.keys) {
        s.addWithImageTag(tag, images[tag]!);
      }
      return;
    }, []);

    var jobStatus = jobStatusesState.value;

    return SingleChildScrollView(
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          fontFeatures: [
            FontFeature.tabularFigures(),
          ],
        ),
        child: Column(children: [
          ...jobStatus.values
              .where((job) =>
                  job.type == MirrorJobType.manifest && job.platform == null)
              .map((job) => _buildManifestListTile(context, job, jobStatus))
        ]),
      ),
    );
  }

  Widget _buildManifestListTile(
    BuildContext context,
    MirrorJob job,
    Map<Digest, MirrorJob> jobStatus,
  ) {
    return ListTile(
      onLongPress: () {
        BlocRegistry.read(context).state.service?.let(
              (s) => Clipboard.setData(
                ClipboardData(
                  text:
                      "${s.ip}:${s.port}/${job.name}${job.tag != null ? ":${job.tag}" : "@${job.digest}"}",
                ),
              ),
            );
      },
      title: Stack(
        children: [
          ...?job.tag?.let((tag) => [
                Positioned(
                  right: 0,
                  top: 0,
                  child: Text(
                    tag,
                    style: const TextStyle(fontSize: 10),
                  ),
                )
              ]),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              job.name,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
      subtitle: Wrap(
        spacing: 2,
        runSpacing: -2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              "${job.digest}",
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9),
            ),
          ),
          ...?job.children?.expand((d) =>
              jobStatus[d]?.let((sub) => [
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 2,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ...?sub.children?.map(
                                  (d) => _buildBlob(context, jobStatus[d]))
                            ],
                          ),
                        ),
                        Text(
                          "${sub.platform}",
                          style: const TextStyle(
                            fontSize: 8,
                            fontFeatures: [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ]) ??
              [])
        ],
      ),
    );
  }

  Widget _buildBlob(BuildContext context, MirrorJob? job) {
    return Container(
      decoration: BoxDecoration(
        color: _colorForJob(job),
      ),
      width: 6,
      height: 6,
    );
  }

  Color _colorForJob(MirrorJob? job) {
    if (job == null) {
      return Colors.grey;
    }
    switch (job.stage) {
      case MirrorJobStage.success:
        return Colors.green;
      case MirrorJobStage.doing:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
