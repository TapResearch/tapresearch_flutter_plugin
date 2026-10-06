import 'tr_error.dart';

class TRQualificationsResult {
  final int? acceptedCount;
  final int? invalidCount;
  final List<TRError>? errors;

  TRQualificationsResult({
    this.acceptedCount,
    this.invalidCount,
    this.errors,
  });

  factory TRQualificationsResult.fromJson(Map<String, dynamic> json) =>
      TRQualificationsResult(
        acceptedCount: json['accepted'] as int?,
        invalidCount: json['invalid'] as int?,
        errors: (json['errors'] as List<dynamic>?)
            ?.map((e) => TRError.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'accepted': acceptedCount,
        'invalid': invalidCount,
        'errors': errors?.map((e) => e.toJson()).toList(),
      };
}
