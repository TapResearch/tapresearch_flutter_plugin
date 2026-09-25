class TRQualificationAnswer {
  final String? optionText;
  final String? enTranslation;
  final String? preCode;

  TRQualificationAnswer({
    this.optionText,
    this.enTranslation,
    this.preCode,
  });

  factory TRQualificationAnswer.fromJson(Map<String, dynamic> json) =>
      TRQualificationAnswer(
        optionText: json['option_text'] as String?,
        enTranslation: json['en_translation'] as String?,
        preCode: json['pre_code'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'option_text': optionText,
        'en_translation': enTranslation,
        'pre_code': preCode,
      };
}
