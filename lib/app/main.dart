import 'package:crpe/app/kubepkg/bloc_kube_pkg.dart';
import 'package:crpe/app/page_home.dart';
import 'package:crpe/app/registry/registry.dart';
import 'package:crpe/app/theme.dart';
import 'package:crpe/flutter/flutter.dart';

void main() async {
  FlutterServicesBinding.ensureInitialized();

  var s = await HydratedStorage.build(
    storageDirectory: await getTemporaryDirectory(),
  );

  HydratedBlocOverrides.runZoned(
    () => runApp(const App()),
    storage: s,
  );
}

class App extends HookWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CacheDirectoryProvider(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<BlocRegistry>(
            lazy: false,
            create: (ctx) => BlocRegistry(CacheDirectoryProvider.read(ctx)),
          ),
          BlocProvider<BlocKubePkg>(
            lazy: false,
            create: (_) => BlocKubePkg(),
          ),
        ],
        child: MaterialApp(
          theme: theme,
          home: const PageHome(),
        ),
      ),
    );
  }
}
