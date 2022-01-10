import 'package:crpeapp/common/flutter.dart';
import 'package:crpeapp/common/validator.dart';
import 'package:crpeapp/domain/cluster.dart';
import 'package:crpeapp/domain/registry.dart';

class PageClusterNodeAdd extends HookWidget {
  final String clusterName;

  const PageClusterNodeAdd({
    Key? key,
    required this.clusterName,
  }) : super(key: key);

  static show(BuildContext context, String clusterName) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: false,
        builder: (context) => PageClusterNodeAdd(
          clusterName: clusterName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("添加设备"),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              indicatorColor: Theme.of(context).primaryColor,
              labelColor: Theme.of(context).primaryColor,
              tabs: [
                Tab(child: Text(FormClusterNodeAdd.label)),
                Tab(child: Text(ClusterNodeFinder.label)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  FormClusterNodeAdd(clusterName: clusterName),
                  ClusterNodeFinder(clusterName: clusterName),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ClusterNodeFinder extends HookWidget {
  final String clusterName;

  const ClusterNodeFinder({
    Key? key,
    required this.clusterName,
  }) : super(key: key);

  static String label = "同网段搜索";

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
        future: BlocRegistry.read(context).getWifiIP(),
        builder: (context, as) {
          var ip = as.data;

          if (ip == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return HookBuilder(builder: (context) {
            final founded = useState<List<ClusterNode>>([]);

            useEffect(() {
              var adapter = BlocCluster.read(context).adapter;

              var sub = adapter.scan(ip).listen((nodeMeta) {
                founded.value = [
                  ...founded.value,
                  ClusterNode.fromNodeMeta(nodeMeta),
                ];
              });

              return () {
                sub.cancel();
              };
            }, []);

            return Column(
              children: [
                ...founded.value.map((nodeMeta) {
                  return ListTile(
                    onTap: () {
                      BlocCluster.read(context)
                          .connectNode(clusterName, nodeMeta);
                      Navigator.of(context).pop();
                    },
                    title: Text(nodeMeta.id),
                    subtitle: Text(nodeMeta.ip),
                    trailing: const Icon(Icons.link),
                  );
                }),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const Text(""),
                      Text("根据 $ip 所在网段查询")
                    ],
                  ),
                )
              ],
            );
          });
        });
  }
}

class FormClusterNodeAdd extends HookWidget {
  final _form = GlobalKey<FormState>();

  static String label = "通过 IP 直接添加";

  final String clusterName;

  FormClusterNodeAdd({
    Key? key,
    required this.clusterName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ip = useTextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _form,
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: ip,
              decoration: const InputDecoration(
                labelText: 'IP 地址',
              ),
              keyboardType: TextInputType.number,
              validator: Validator.ip,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _form.currentState?.validate().ifTrueOrNull(() async {
                      var finder = BlocCluster.read(context).adapter;

                      try {
                        var nodeMeta = await finder.find(ip.text);

                        BlocCluster.read(context).connectNode(
                          clusterName,
                          ClusterNode.fromNodeMeta(nodeMeta),
                        );

                        safePop(context);
                      } catch (e) {
                        showAlert(
                          context,
                          content: Text("找不到设备: $e"),
                          onConfirm: () {},
                        );
                      }
                    });
                  },
                  child: const Text('验证并添加'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
