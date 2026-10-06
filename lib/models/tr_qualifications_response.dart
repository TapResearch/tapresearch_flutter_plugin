import 'tr_error.dart';
import 'tr_qualification.dart';
import 'tr_qualifications_result.dart';

class TRQualificationsResponse {
  final String? countryCode;
  final String? locale;
  final bool? isProfiled;
  final List<TRQualification>? qualifications;
  final TRError? error;
  final TRQualificationsResult? qualificationsResult;

  TRQualificationsResponse({
    this.countryCode,
    this.locale,
    this.isProfiled,
    this.qualifications,
    this.error,
    this.qualificationsResult,
  });

  factory TRQualificationsResponse.fromJson(Map<String, dynamic> json) =>
      TRQualificationsResponse(
        countryCode: json['country_code'] as String?,
        locale: json['locale'] as String?,
        isProfiled: json['is_profiled'] as bool?,
        qualifications: (json['qualifications'] as List<dynamic>?)
            ?.map((e) => TRQualification.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        error: json['error'] != null
            ? TRError.fromJson((json['error'] as Map).cast<String, dynamic>())
            : null,
        qualificationsResult: json['result'] != null
            ? TRQualificationsResult.fromJson(
                (json['result'] as Map).cast<String, dynamic>())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'country_code': countryCode,
        'locale': locale,
        'is_profiled': isProfiled,
        'qualifications': qualifications?.map((e) => e.toJson()).toList(),
        'error': error?.toJson(),
        'result': qualificationsResult?.toJson(),
      };
}
