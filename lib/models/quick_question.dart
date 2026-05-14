import 'quick_questions_data_payload.dart';

class QuickQuestion {
  final String type;
  final QQPayload payload;

  QuickQuestion({
    required this.type,
    required this.payload,
  });

  factory QuickQuestion.fromJson(Map<String, dynamic> json) => QuickQuestion(
        type: json['type'] as String,
        payload: QQPayload.fromJson(json['payload'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'payload': payload.toJson(),
      };
}

class QQPayload {
  final String surveyIdentifier;
  final String appName;
  final String apiToken;
  final String sdkVersion;
  final String platform;
  final String placementTag;
  final String userIdentifier;
  final String userLocale;
  final String seenAt;
  final Complete? complete;
  final List<Question> questions;
  final List<Map<String, String>>? targetAudience;

  QQPayload({
    required this.surveyIdentifier,
    required this.appName,
    required this.apiToken,
    required this.sdkVersion,
    required this.platform,
    required this.placementTag,
    required this.userIdentifier,
    required this.userLocale,
    required this.seenAt,
    this.complete,
    required this.questions,
    this.targetAudience,
  });

  factory QQPayload.fromJson(Map<String, dynamic> json) => QQPayload(
        surveyIdentifier: json['survey_identifier'] as String,
        appName: json['app_name'] as String,
        apiToken: json['api_token'] as String,
        sdkVersion: json['sdk_version'] as String,
        platform: json['platform'] as String,
        placementTag: json['placement_tag'] as String,
        userIdentifier: json['user_identifier'] as String,
        userLocale: json['user_locale'] as String,
        seenAt: json['seen_at'] as String,
        complete: json['complete'] != null
            ? Complete.fromJson(json['complete'] as Map<String, dynamic>)
            : null,
        questions: (json['questions'] as List<dynamic>)
            .map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList(),
        targetAudience: (json['target_audience'] as List<dynamic>?)
            ?.map((e) => Map<String, String>.from(e as Map))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'survey_identifier': surveyIdentifier,
        'app_name': appName,
        'api_token': apiToken,
        'sdk_version': sdkVersion,
        'platform': platform,
        'placement_tag': placementTag,
        'user_identifier': userIdentifier,
        'user_locale': userLocale,
        'seen_at': seenAt,
        'complete': complete?.toJson(),
        'questions': questions.map((e) => e.toJson()).toList(),
        'target_audience': targetAudience,
      };
}

class QQComplete {
  final String completeIdentifier;
  final String completedAt;

  QQComplete({
    required this.completeIdentifier,
    required this.completedAt,
  });

  factory QQComplete.fromJson(Map<String, dynamic> json) => QQComplete(
        completeIdentifier: json['complete_identifier'] as String,
        completedAt: json['completed_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'complete_identifier': completeIdentifier,
        'completed_at': completedAt,
      };
}

class Question {
  final String questionIdentifier;
  final String questionText;
  final String questionType;
  final UserAnswer? userAnswer;

  Question({
    required this.questionIdentifier,
    required this.questionText,
    required this.questionType,
    this.userAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        questionIdentifier: json['question_identifier'] as String,
        questionText: json['question_text'] as String,
        questionType: json['question_type'] as String,
        userAnswer: json['user_answer'] != null
            ? UserAnswer.fromJson(json['user_answer'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'question_identifier': questionIdentifier,
        'question_text': questionText,
        'question_type': questionType,
        'user_answer': userAnswer?.toJson(),
      };
}

class QQUserAnswer {
  final String value;
  final List<String> identifiers;

  QQUserAnswer({
    required this.value,
    required this.identifiers,
  });

  factory QQUserAnswer.fromJson(Map<String, dynamic> json) => QQUserAnswer(
        value: json['value'] as String,
        identifiers: List<String>.from(json['identifiers'] as List),
      );

  Map<String, dynamic> toJson() => {
        'value': value,
        'identifiers': identifiers,
      };
}