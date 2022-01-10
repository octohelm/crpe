import 'package:crpeapp/flutter/flutter.dart';
import 'package:provider/provider.dart';

class Topic {
  Icon icon;
  String label;
  Widget widget;

  Topic({
    required this.icon,
    required this.label,
    required this.widget,
  });
}

class ScaffoldTopicContext {
  final BottomNavigationBar bottomNavigationBar;
  final Topic current;

  const ScaffoldTopicContext({
    required this.bottomNavigationBar,
    required this.current,
  });
}

class ScaffoldTopicProvider extends HookWidget {
  final List<Topic> topics;

  static ScaffoldTopicContext of(BuildContext context) {
    return context.read<ScaffoldTopicContext>();
  }

  const ScaffoldTopicProvider({
    Key? key,
    required this.topics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _selectedIndex = useState(0);
    final selected = topics.elementAt(_selectedIndex.value);

    return Provider<ScaffoldTopicContext>.value(
      value: ScaffoldTopicContext(
        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Theme.of(context).unselectedWidgetColor,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex.value,
          onTap: (index) => _selectedIndex.value = index,
          items: [
            ...topics.map(
              (e) => BottomNavigationBarItem(icon: e.icon, label: e.label),
            ),
          ],
        ),
        current: selected,
      ),
      child: selected.widget,
    );
  }
}
