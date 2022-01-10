import 'package:crpe/kubepkg.dart';
import 'package:crpeapp/domain/cluster.dart';
import 'package:crpeapp/domain/registry.dart';
import 'package:crpeapp/flutter/flutter.dart';
import 'package:crpeapp/view/cluster_kubepkg.dart';
import 'package:rxdart/rxdart.dart';

class PageClusterNodeDetail extends HookWidget {
  static show(BuildContext context, String clusterName, String id) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: false,
        builder: (context) => PageClusterNodeDetail(
          clusterName: clusterName,
          id: id,
        ),
      ),
    );
  }

  final String clusterName;
  final String id;

  const PageClusterNodeDetail({
    required this.clusterName,
    required this.id,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var blocCluster = BlocCluster.watch(context);
    var cluster = blocCluster.cluster(clusterName);

    var node = cluster.node(id)!;

    var ss$ = useMemoized(() => BehaviorSubject<List<KubePkg>>(), []);

    var reload = useMemoized(
        () => () => blocCluster.adapter.getKubePkgs(node.ip).then((list) {
              ss$.add(list);
            }),
        []);

    useEffect(() {
      reload();
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text("${node.ip} ${node.name ?? ""}"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Stack(
        children: [
          StreamBuilder<List<KubePkg>>(
            stream: ss$,
            builder: (context, as) {
              if (as.hasData) {
                return ListClusterKubePkg(
                  node: node,
                  installed: as.data!,
                  toInstall: cluster.pkgs?.values.toList() ?? [],
                );
              }

              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          )
        ],
      ),
    );
  }
}

class ListClusterKubePkg extends HookWidget {
  final ClusterNode node;
  final List<KubePkg> installed;
  final List<KubePkg> toInstall;

  const ListClusterKubePkg({
    required this.node,
    required this.installed,
    required this.toInstall,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var currentKubePkgs = useMemoized(() {
      return installed.fold<Map<String, KubePkg>>(
        {},
        (ret, pkg) => {
          ...ret,
          pkg.metadata.name: pkg,
        },
      );
    }, [installed]);

    return SingleChildScrollView(
      child: Column(
        children: [
          ...toInstall.map(
            (kubePkg) => ListTileKubePkgDiff(
              node: node,
              toInstall: kubePkg,
              installed: currentKubePkgs[kubePkg.metadata.name],
            ),
          )
        ],
      ),
    );
  }
}

class ListTileKubePkgDiff extends HookWidget {
  final ClusterNode node;
  final KubePkg toInstall;
  final KubePkg? installed;

  const ListTileKubePkgDiff({
    required this.node,
    required this.toInstall,
    this.installed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var blocCluster = BlocCluster.read(context);
    var kubePkgRegistry = BlocRegistry.read(context).kubePkgRegistry;

    var p$ = useMemoized(() => BehaviorSubject<Progress>(), []);

    var startUpload = useMemoized(() {
      return () async {
        print("upload");

        if (toInstall.tgzCreated) {
          try {
            var tgzDigest = toInstall.status!.tgzDigest!;

            var d = await kubePkgRegistry.stat(tgzDigest);

            var tgz$ = await kubePkgRegistry.openRead(tgzDigest);

            await blocCluster.adapter.upload(
              node.ip,
              d.digest!,
              tgz$,
              size: d.size,
              process$: p$,
            );
          } catch (e) {
            print("failed: $e");
          }
        }
      };
    }, []);

    return ListTile(
      onTap: () {
        if ((p$.valueOrNull?.percent ?? 1) == 1) {
          startUpload();
        }
      },
      title: Text(toInstall.metadata.name),
      subtitle: _buildVersion(),
      trailing: SizedBox(
        width: 100,
        child: installed?.let((v) {
          return StreamBuilder<Progress?>(
            stream: p$,
            builder: (c, as) {
              return KubePkgProgress(
                progress: as.data?.percent == 1 ? null : as.data,
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildVersion() {
    if (installed?.spec.version == toInstall.spec.version) {
      return Text(toInstall.spec.version);
    }
    return Row(
      children: [
        Text(installed?.spec.version ?? "-"),
        const Icon(Icons.arrow_right),
        Text(toInstall.spec.version),
      ],
    );
  }
}
