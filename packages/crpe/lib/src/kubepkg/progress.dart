import 'package:freezed_annotation/freezed_annotation.dart';

import 'digest_meta.dart';

part '__generated__/progress.freezed.dart';
part '__generated__/progress.g.dart';

@freezed
class Progress with _$Progress {
  Progress._();

  factory Progress({
    required int total,
    @Default(0) int complete,
    String? error,
  }) = _Progress;

  factory Progress.fromIterable(Iterable<DigestMeta> list) {
    return Progress(
      total: list.fold(0, (previousValue, e) => previousValue + e.size),
    );
  }

  factory Progress.fromJson(Map<String, dynamic> json) =>
      _Progress.fromJson(json);

  Progress incrComplete(int delta) {
    return copyWith(complete: complete + delta);
  }

  Progress incrTotal(int delta) {
    return copyWith(total: total + delta);
  }

  double get percent => complete / total;

  Progress withError(dynamic e) {
    return copyWith(
      error: e.toString(),
    );
  }
}
