import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rxdart/rxdart.dart';

void useObservableEffect(Stream? Function() effect, [List<Object?>? keys]) {
  return useEffect(() {
    final ob$ = effect();
    if (ob$ == null) {
      return null;
    }
    final subscription = ob$.listen(null);
    return () => subscription.cancel();
  }, keys);
}

T useObservable<T>(BehaviorSubject<T> ob$, [T? defaultValue]) {
  final vn = useState(defaultValue ?? ob$.value);

  useEffect(() {
    final subscription = ob$.listen((v) => vn.value = v);

    return () {
      subscription.cancel();
    };
  }, [ob$]);

  return vn.value;
}
