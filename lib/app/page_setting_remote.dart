import 'package:crpe/app/registry/bloc_registry.dart';
import 'package:crpe/flutter/flutter.dart';
import 'package:crpe/flutter/ui.dart';
import 'package:crpe/registry/remote/registry_remote.dart';
import 'package:roundtripper/roundtripper.dart';

class PageSettingRemote extends HookWidget {
  const PageSettingRemote({Key? key}) : super(key: key);

  static show(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: false,
        builder: (context) => const PageSettingRemote(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("配置镜像源"),
      ),
      body: FormSettingRemote(),
    );
  }
}

class FormSettingRemote extends HookWidget {
  final _form = GlobalKey<FormState>();

  FormSettingRemote({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final blocRegistry = BlocRegistry.read(context);

    final endpoint = useTextEditingController(
      text: blocRegistry.state.remote?.endpoint,
    );
    final username = useTextEditingController(
      text: blocRegistry.state.remote?.username,
    );

    final password = useTextEditingController(
      text: blocRegistry.state.remote?.password,
    );

    final showPassword = useState(false);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _form,
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: endpoint,
              decoration: const InputDecoration(
                labelText: 'Endpoint',
              ),
            ),
            TextFormField(
              controller: username,
              decoration: const InputDecoration(
                labelText: 'Username',
              ),
            ),
            TextFormField(
              controller: password,
              obscureText: !showPassword.value,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    showPassword.value = !showPassword.value;
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _form.currentState?.validate().ifTrueOrNull(() async {
                      var remote = RegistryRemoteOptions.fromJson({
                        "endpoint": endpoint.value.text,
                        "username": username.value.text,
                        "password": password.value.text,
                      });

                      try {
                        var rr = RegistryRemote(remote);
                        await rr.apiCheck();
                        blocRegistry.updateRemote(remote);

                        Navigator.of(context).pop();
                      } on ResponseException catch (err) {
                        showSnackBar(
                          context,
                          content: Text("错误 ${err.statusCode} ${err.response}"),
                        );
                      }
                    });
                  },
                  child: const Text('验证并更新'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
