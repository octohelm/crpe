import 'package:crpe/registry.dart';
import 'package:crpeapp/common/flutter.dart';
import 'package:crpeapp/common/validator.dart';
import 'package:crpeapp/domain/registry.dart';

class PageEditRemote extends HookWidget {
  static show(BuildContext context, {RegistryRemoteOptions? remote}) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: false,
        builder: (context) => PageEditRemote(remote: remote),
      ),
    );
  }

  final RegistryRemoteOptions? remote;

  const PageEditRemote({this.remote, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _form = useMemoized(() => GlobalKey<FormState>(), []);

    final endpoint = useTextEditingController(
      text: remote?.endpoint,
    );
    final username = useTextEditingController(
      text: remote?.username,
    );

    final password = useTextEditingController(
      text: remote?.password,
    );

    final showPassword = useState(false);

    handleSubmit() {
      _form.currentState?.validate().ifTrueOrNull(() async {
        var remote = RegistryRemoteOptions.fromJson({
          "endpoint": endpoint.value.text,
          "username": username.value.text,
          "password": password.value.text,
        });

        BlocRegistry.read(context).updateRemote(remote);

        safePop(context);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: remote == null ? const Text("新建镜像源") : const Text("配置镜像源"),
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
      body: Form(
        key: _form,
        child: Column(
          children: [
            ...[
              TextFormField(
                controller: endpoint,
                decoration: const InputDecoration(
                  labelText: '访问地址',
                ),
                readOnly: remote != null,
                validator: Validator.required,
              ),
              TextFormField(
                controller: username,
                decoration: const InputDecoration(
                  labelText: '用户名',
                ),
              ),
              TextFormField(
                controller: password,
                obscureText: !showPassword.value,
                decoration: InputDecoration(
                  labelText: '密码',
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
