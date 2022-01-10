import 'package:crpeapp/common/flutter.dart';

void safePop(BuildContext context) {
  if (Navigator.canPop(context)) {
    Navigator.of(context).pop();
  }
}
