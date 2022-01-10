import 'package:crpeapp/domain/cluster.dart';
import 'package:crpeapp/flutter/flutter.dart';
import 'package:crpeapp/flutter/ui.dart';
import 'package:crpeapp/view/cluster_kubepkg/page_kube_pkg.dart';
import 'package:crpeapp/view/cluster_node/page_cluster_node.dart';
import 'package:crpeapp/view/registry.dart';
import 'package:crpeapp/view/scaffold.dart';

import 'page_edit_cluster_info.dart';

class ScaffoldCluster extends HookWidget {
  const ScaffoldCluster({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var blocCluster = BlocCluster.watch(context);

    if (blocCluster.state.clusters.isEmpty) {
      return const PageEditClusterInfo();
    }

    return ScaffoldWithBottomNavigation(
      drawer: _buildDrawer(context),
      routes: [
        PageClusterNode.route,
        PageKubePkg.route,
      ],
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    var blocCluster = BlocCluster.read(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: Text("")),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    "CRPE",
                    style: TextStyle(
                      fontSize: 24,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              ],
            ),
          ),
          ...blocCluster.state.clusters.values.map(
            (cluster) => ListTile(
              title: Wrap(
                spacing: 8,
                children: [
                  Text(cluster.name.toUpperCase()),
                  Opacity(
                    opacity: 0.6,
                    child: Text(cluster.desc ?? " "),
                  )
                ],
              ),
              tileColor: (cluster.name == blocCluster.current.name)
                  .ifTrueOrNull(() => Theme.of(context).focusColor),
              onTap: () {
                blocCluster.switchCluster(cluster.name);
                safePop(context);
              },
            ),
          ),
          ListTile(
            title: const Text('集群管理'),
            onTap: () {
              PageEditClusterInfo.show(context);
            },
          ),
          const Divider(
            height: 0,
          ),
          ListTile(
            title: const Text('容器镜像源管理'),
            onTap: () {
              PageRemote.show(context);
            },
          ),
          // ListTile(
          //   leading: const Icon(Icons.help),
          //   title: const Text('关于'),
          //   onTap: () {},
          // ),
        ],
      ),
    );
  }
}

class ListCluster extends HookWidget {
  const ListCluster({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final blocCluster = BlocCluster.watch(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          ...blocCluster.state.clusters.values.map((cluster) => ListTileCluster(
                cluster: cluster,
              ))
        ],
      ),
    );
  }
}

class ListTileCluster extends HookWidget {
  final Cluster cluster;

  const ListTileCluster({
    required this.cluster,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(cluster.name),
      subtitle: cluster.desc?.let((t) => Text(t.trim())),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
