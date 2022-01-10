import 'dart:convert';

import 'package:crpeapp/flutter/flutter.dart';

import 'kubepkg/kubepkg.dart';

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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("添加 KubePkg"),
      ),
      body: FormKubePkgAdd(),
    );
  }
}

class FormKubePkgAdd extends HookWidget {
  final _form = GlobalKey<FormState>();

  FormKubePkgAdd({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final blocKubePkg = BlocKubePkg.read(context);

    final json = useTextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _form,
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: json,
              decoration: const InputDecoration(
                labelText: 'KubePkg.json',
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
              minLines: 10,
              enableInteractiveSelection: true,
              autofocus: true,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _form.currentState?.validate().ifTrueOrNull(() async {
                      blocKubePkg.add(
                        KubePkg.fromJson(jsonDecode(json.value.text)),
                      );

                      Navigator.of(context).pop();
                    });
                  },
                  child: const Text('添加'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
