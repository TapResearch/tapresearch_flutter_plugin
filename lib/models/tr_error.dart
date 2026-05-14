class TRError {
  final int? code;
  final String? description;

  TRError({
    this.code,
    this.description,
  });

  factory TRError.fromJson(Map<String, dynamic> json) => TRError(
        code: json['error_code'] as int?,
        description: json['message'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'error_code': code,
        'message': description,
      };
}