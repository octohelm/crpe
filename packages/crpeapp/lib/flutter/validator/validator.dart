typedef ValidateFn<T> = String? Function(T? value);

class Validator {
  static ValidateFn<T> compose<T>(List<ValidateFn> fns) {
    return (T? value) {
      for (var fn in fns) {
        var err = fn(value);
        if (err != null) {
          return err;
        }
      }
      return null;
    };
  }

  static String? required<T>(T? value) {
    if (value == null || value == "") {
      return "不能为空";
    }
    return null;
  }

  static String? ip<T>(T? value) {
    if (value is String &&
        RegExp("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)(\\.(?!\$)|\$)){4}\$")
            .hasMatch(value)) {
      return null;
    }
    return "请输入合法的 IP 地址";
  }
}
