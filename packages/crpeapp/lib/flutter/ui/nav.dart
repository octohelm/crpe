import 'package:crpeapp/flutter/flutter.dart';

void safePop(BuildContext context) {
  if (Navigator.canPop(context)) {
    Navigator.of(context).pop();
  }
}
