import 'package:crpeapp/common/flutter.dart';
import 'package:crpeapp/domain/cluster.dart';
import 'package:crpeapp/view/scaffold.dart';

import 'page_cluster_node_add.dart';
import 'page_cluster_node_detail.dart';

class PageClusterNode extends HookWidget {
  static get route => RouteMeta(
        icon: const Icon(Icons.smartphone),
        label: '设备',
        widget: const PageClusterNode(),
      );

  const PageClusterNode({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var st = ScaffoldContext.of(context);

    var blocCluster = BlocCluster.watch(context);

    var cluster = blocCluster.current;

    return Scaffold(
      drawer: st.drawer,
      appBar: AppBar(
        title: Text(st.current?.label ?? ""),
        actions: [
          IconButton(
            onPressed: () {
              PageClusterNodeAdd.show(context, cluster.name);
            },
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ...?cluster.nodes?.let(
              (nodes) => nodes.keys.map((key) {
                return ListTileClusterNode(
                  clusterName: cluster.name,
                  clusterNode: nodes[key]!,
                );
              }),
            )
          ],
        ),
      ),
      bottomNavigationBar: st.bottomNavigationBar,
    );
  }
}

class ListTileClusterNode extends HookWidget {
  final String clusterName;
  final ClusterNode clusterNode;

  const ListTileClusterNode({
    required this.clusterNode,
    required this.clusterName,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var ready$ = useMemoized(() => BehaviorSubject<bool>(), []);

    useObservableEffect(() {
      Future<bool> check() async {
        try {
          var nodeMeta =
              await BlocCluster.read(context).adapter.find(clusterNode.ip);
          return nodeMeta.ip == clusterNode.ip;
        } catch (_) {}
        return false;
      }

      return Rx.merge([
        Stream.periodic(const Duration(seconds: 3))
            .asyncMap((_) async => await check()),
        Stream.fromFuture(check()),
      ]).doOnData(ready$.add);
    }, [clusterNode]);

    return ListTile(
      onLongPress: () {
        showAlert(
          context,
          content: Text("是否解绑设备 ${clusterNode.id}(${clusterNode.ip}) ?"),
          onConfirm: () {
            BlocCluster.read(context).disconnectNode(
              clusterName,
              clusterNode.id,
            );
          },
        );
      },
      onTap: () {
        if (ready$.valueOrNull ?? false) {
          PageClusterNodeDetail.show(context, clusterName, clusterNode.id);
        }
      },
      trailing: StreamBuilder<bool>(
        stream: ready$,
        builder: (ctx, as) {
          return ActiveStatus(
            size: 10,
            active: as.data,
          );
        },
      ),
      title: Text(clusterNode.ip),
      subtitle: Text(clusterNode.id, style: const TextStyle(fontSize: 12)),
    );
  }
}
