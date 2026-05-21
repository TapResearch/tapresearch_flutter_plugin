import 'tr_error.dart';

class TRGrantBoostResponse {
  final String? boostTag;
  final bool? success;
  final TRError? error;

  TRGrantBoostResponse({
    this.boostTag,
    this.success,
    this.error,
  });

  factory TRGrantBoostResponse.fromJson(Map<String, dynamic> json) =>
      TRGrantBoostResponse(
        boostTag: json['boost_tag'] as String?,
        success: json['success'] as bool?,
        error: json['error'] != null
            ? TRError.fromJson((json['error'] as Map).cast<String, dynamic>())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'boost_tag': boostTag,
        'success': success,
        'error': error?.toJson(),
      };
}