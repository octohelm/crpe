import 'dart:convert';

import 'package:crpe/kubepkg.dart';
import 'package:crpeapp/common/flutter.dart';
import 'package:crpeapp/domain/cluster.dart';

class PageKubePkgAdd extends HookWidget {
  const PageKubePkgAdd({Key? key}) : super(key: key);

  static show(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: false,
        builder: (context) => const PageKubePkgAdd(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocCluster = BlocCluster.read(context);

    final _form = useMemoized(() => GlobalKey<FormState>(), []);

    var json = useTextEditingController();

    handleSubmit() {
      _form.currentState?.validate().ifTrueOrNull(() async {
        var pkg = KubePkg.fromJson(jsonDecode(json.value.text));

        try {
          blocCluster.updatePkg(blocCluster.current.name, pkg);
          Navigator.of(context).pop();
        } catch (e) {
          showAlert(
            context,
            content: Text("添加失败: $e"),
            onConfirm: () {},
          );
        }
      });
    }

    return Form(
      key: _form,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("添加应用"),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                primary: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: handleSubmit,
              child: const Text('确定'),
            )
          ],
        ),
        body: Column(
          children: [
            ...[
              TextFormField(
                controller: json,
                decoration: const InputDecoration(
                  labelText: 'kubepkg.json',
                ),
                validator: (input) {
                  try {
                    KubePkg.fromJson(jsonDecode(input ?? "{}"));
                    return null;
                  } catch (e) {
                    return "$e";
                  }
                },
                keyboardType: TextInputType.multiline,
                maxLines: 10,
                enableInteractiveSelection: true,
                autofocus: true,
              )
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
