import 'package:crpe/kubepkg.dart';
import 'package:crpeapp/common/flutter.dart';
import 'package:filesize/filesize.dart';

class KubePkgProgress extends HookWidget {
  final Progress? progress;
  final String? label;

  const KubePkgProgress({
    this.progress,
    this.label,
    Key? key,
  }) : super(key: key);

  final _color = Colors.green;
  final double _height = 16;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_height / 2),
        border: Border.all(color: _color, width: 1.5),
      ),
      clipBehavior: Clip.hardEdge,
      height: _height,
      child: progress?.let((p) => Progressing(
                color: _color,
                height: _height,
                label: "${filesize(p.complete)} / ${filesize(p.total)}",
                percent: p.percent,
              )) ??
          Progressing(
            color: _color,
            height: _height,
            label: label ?? "安装包已就绪",
            percent: 1,
          ),
    );
  }
}

class Progressing extends HookWidget {
  final double height;
  final MaterialColor color;
  final double percent;
  final String? label;

  const Progressing({
    Key? key,
    this.label,
    required this.percent,
    required this.color,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: TextStyle(
        color: percent == 1 ? Colors.white : color,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            right: 0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Opacity(
                opacity: percent == 1 ? 1 : 0.2,
                child: FractionallySizedBox(
                  widthFactor: percent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              label ?? "-",
              style: TextStyle(fontSize: height / 2),
            ),
          ),
        ],
      ),
    );
  }
}
