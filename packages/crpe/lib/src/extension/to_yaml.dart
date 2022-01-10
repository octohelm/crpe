extension ListToYaml on List {
  String toYaml() {
    return _toYaml(this, 0);
  }

  static String _toYaml(List element, int level) {
    var res = '';
    for (var elem in element) {
      var padding = '  ' * level + '- ';
      if (elem is Map) {
        res += padding + MapToYaml._toYaml(elem, level + 1, true);
        continue;
      }
      if (elem is List) {
        if (elem.isEmpty) {
          res += '$padding[]\n';
          continue;
        }
        res += padding + '\n';
        res += _toYaml(elem, level + 1);
        continue;
      }
      res += _valToYaml(elem, level);
    }
    return res;
  }
}

extension MapToYaml on Map {
  String toYaml() {
    return _toYaml(this, 0);
  }

  static String _toYaml(Map element, int level, [bool ignoreLevel = false]) {
    var res = '';
    for (var key in element.keys) {
      res += '  ' * level * (ignoreLevel ? 0 : 1) + '$key:';
      ignoreLevel = false;
      var value = element[key]!;

      if (value is Map) {
        res += '\n' + _toYaml(value, level + 1);
        continue;
      }
      if (value is List) {
        if (value.isEmpty) {
          res += ' []\n';
          continue;
        }
        res += '\n' + ListToYaml._toYaml(value, level);
        continue;
      }

      res += _valToYaml(value, level);
    }
    return res;
  }
}

String _valToYaml(dynamic value, int level) {
  if (value is String) {
    var space = '  ' * (level + 1);

    if (value.contains('\n') || value.contains('"')) {
      return ' |-\n${space}${value.replaceAll('\n', '\n$space')}\n';
    }
    return ' "${value}"\n';
  }

  return ' ${value}\n';
}
