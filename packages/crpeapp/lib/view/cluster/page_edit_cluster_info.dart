import 'package:crpeapp/common/flutter.dart';
import 'package:crpeapp/common/validator.dart';
import 'package:crpeapp/domain/cluster.dart';

class PageEditClusterInfo extends HookWidget {
  static show(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: false,
        builder: (context) => const PageEditClusterInfo(),
      ),
    );
  }

  const PageEditClusterInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = useTextEditingController(
      text: "",
    );

    final desc = useTextEditingController(
      text: "",
    );

    final formKey = useMemoized(() => GlobalKey<FormState>());

    handleSubmit() {
      formKey.currentState?.validate().ifTrueOrNull(() async {
        var clusterInfo = Cluster(
          name: name.value.text,
          desc: desc.value.text,
        );
        BlocCluster.read(context).updateClusterInfo(clusterInfo);
        safePop(context);
      });
    }

    return Form(
      key: formKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("创建集群"),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                primary: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: handleSubmit,
              child: const Text('保存'),
            )
          ],
        ),
        body: Column(
          children: [
            ...[
              TextFormField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: "集群名",
                  hintText: "[A-Za-z0-9]+",
                ),
                validator: Validator.required,
              ),
              TextFormField(
                controller: desc,
                decoration: const InputDecoration(
                  labelText: "集群备注",
                ),
                validator: Validator.required,
              ),
            ].map(
              (e) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: e,
              ),
            )
          ],
        ),
      ),
    );
  }
}
