import 'tr_qualification_answer.dart';

class TRQualification {
  final int? questionId;
  final String? questionText;
  final String? enTranslation;
  final String? answerType;
  final List<TRQualificationAnswer>? qualificationAnswers;
  final String? previousError;

  TRQualification({
    this.questionId,
    this.questionText,
    this.enTranslation,
    this.answerType,
    this.qualificationAnswers,
    this.previousError,
  });

  factory TRQualification.fromJson(Map<String, dynamic> json) => TRQualification(
        questionId: json['question_id'] as int?,
        questionText: json['question_text'] as String?,
        enTranslation: json['en_translation'] as String?,
        answerType: json['answer_type'] as String?,
        qualificationAnswers: (json['qualification_answers'] as List<dynamic>?)
            ?.map((e) => TRQualificationAnswer.fromJson(
                (e as Map).cast<String, dynamic>()))
            .toList(),
        previousError: json['previous_error'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'question_text': questionText,
        'en_translation': enTranslation,
        'answer_type': answerType,
        'qualification_answers':
            qualificationAnswers?.map((e) => e.toJson()).toList(),
        'previous_error': previousError,
      };
}
