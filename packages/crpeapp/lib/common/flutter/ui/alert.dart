import 'package:crpeapp/common/flutter.dart';
import 'package:crpeapp/common/flutter/extension.dart';

import 'nav.dart';

void showAlert(
  BuildContext context, {
  required Widget content,
  Function()? onConfirm,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: SingleChildScrollView(
          child: content,
        ),
        actions: <Widget>[
          ...?(onConfirm != null).ifTrueOrNull(() => [
                TextButton(
                  onPressed: () {
                    safePop(context);
                  },
                  child: const Text("取消"),
                )
              ]),
          TextButton(
            onPressed: () {
              if (onConfirm != null) {
                onConfirm();
              }
              safePop(context);
            },
            child: const Text("确认"),
          ),
        ],
      );
    },
  );
}
