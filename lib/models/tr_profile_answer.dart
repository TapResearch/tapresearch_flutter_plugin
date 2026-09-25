class TRProfileAnswer {
  final int? questionId;
  final List<String>? actualUserAnswer;

  TRProfileAnswer({
    this.questionId,
    this.actualUserAnswer,
  });

  factory TRProfileAnswer.fromJson(Map<String, dynamic> json) => TRProfileAnswer(
        questionId: json['question_id'] as int?,
        actualUserAnswer: (json['values'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'values': actualUserAnswer,
      };
}
