import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'statuserror.dart';

part "__generated__/range.freezed.dart";
part "__generated__/range.g.dart";

class Range {
  String unit;
  int start;
  int? end;

  Range(
    this.unit, {
    required this.start,
    this.end,
  });

  factory Range.parse(String range) {
    String unit = "";
    int start = 0;
    int? end;

    var parts = range.toLowerCase().split("=");

    unit = parts[0];

    if (unit.length != 2) {
      throw ErrRangeInvalid(range: range);
    }

    var startAndEnd = parts[1].split("-");

    try {
      start = int.parse(startAndEnd[0]);
      if (startAndEnd[1] != "") {
        end = int.parse(startAndEnd[1]);
      }
    } catch (_) {
      throw ErrRangeInvalid(range: range);
    }

    return Range(unit, start: start, end: end);
  }

  @override
  String toString() {
    return "$unit=$start-${end ?? ""}";
  }
}

@freezed
class ErrRangeInvalid with _$ErrRangeInvalid implements StatusError {
  ErrRangeInvalid._();

  factory ErrRangeInvalid({
    required String range,
  }) = _ErrRangeInvalid;

  factory ErrRangeInvalid.fromJson(json) => _ErrRangeInvalid.fromJson(json);

  @override
  int get status => HttpStatus.notFound;

  @override
  String get code => "RANGE_INVALID";

  @override
  String toString() => "invalid content range";
}
