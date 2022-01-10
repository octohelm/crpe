import 'package:crpeapp/flutter/flutter.dart';

class ActiveStatus extends HookWidget {
  final double size;
  final bool? active;

  const ActiveStatus({required this.size, required this.active, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color:
            active?.let((it) => it ? Colors.green : Colors.red) ?? Colors.grey,
      ),
      width: size,
      height: size,
    );
  }
}
