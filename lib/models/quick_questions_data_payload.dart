class Complete {
  final String completeIdentifier;
  final String completedAt;

  Complete({
    required this.completeIdentifier,
    required this.completedAt,
  });

  factory Complete.fromJson(Map<String, dynamic> json) => Complete(
        completeIdentifier: json['complete_identifier'] as String,
        completedAt: json['completed_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'complete_identifier': completeIdentifier,
        'completed_at': completedAt,
      };
}

class UserAnswer {
  final String value;
  final List<String> identifiers;

  UserAnswer({
    required this.value,
    required this.identifiers,
  });

  factory UserAnswer.fromJson(Map<String, dynamic> json) => UserAnswer(
        value: json['value'] as String,
        identifiers: List<String>.from(json['identifiers'] as List),
      );

  Map<String, dynamic> toJson() => {
        'value': value,
        'identifiers': identifiers,
      };
}

class QuickQuestionsDataPayloadQuestion {
  final String questionIdentifier;
  final String questionText;
  final String questionType;
  final int? ratingScaleSize;
  final UserAnswer? userAnswer;

  QuickQuestionsDataPayloadQuestion({
    required this.questionIdentifier,
    required this.questionText,
    required this.questionType,
    this.ratingScaleSize,
    this.userAnswer,
  });

  factory QuickQuestionsDataPayloadQuestion.fromJson(
          Map<String, dynamic> json) =>
      QuickQuestionsDataPayloadQuestion(
        questionIdentifier: json['question_identifier'] as String,
        questionText: json['question_text'] as String,
        questionType: json['question_type'] as String,
        ratingScaleSize: json['rating_scale_size'] as int?,
        userAnswer: json['user_answer'] != null
            ? UserAnswer.fromJson((json['user_answer'] as Map).cast<String, dynamic>())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'question_identifier': questionIdentifier,
        'question_text': questionText,
        'question_type': questionType,
        'rating_scale_size': ratingScaleSize,
        'user_answer': userAnswer?.toJson(),
      };
}

class QuickQuestionsDataPayloadTargetFilter {
  final String filterAttributeName;
  final String filterOperator;
  final String filterValue;
  final String userValue;

  QuickQuestionsDataPayloadTargetFilter({
    required this.filterAttributeName,
    required this.filterOperator,
    required this.filterValue,
    required this.userValue,
  });

  factory QuickQuestionsDataPayloadTargetFilter.fromJson(
          Map<String, dynamic> json) =>
      QuickQuestionsDataPayloadTargetFilter(
        filterAttributeName: json['filter_attribute_name'] as String,
        filterOperator: json['filter_operator'] as String,
        filterValue: json['filter_value'] as String,
        userValue: json['user_value'] as String,
      );

  Map<String, dynamic> toJson() => {
        'filter_attribute_name': filterAttributeName,
        'filter_operator': filterOperator,
        'filter_value': filterValue,
        'user_value': userValue,
      };
}

class QuickQuestionsDataPayload {
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
  final List<QuickQuestionsDataPayloadQuestion> questions;
  final List<QuickQuestionsDataPayloadTargetFilter>? targetAudience;

  QuickQuestionsDataPayload({
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

  factory QuickQuestionsDataPayload.fromJson(Map<String, dynamic> json) =>
      QuickQuestionsDataPayload(
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
            ? Complete.fromJson((json['complete'] as Map).cast<String, dynamic>())
            : null,
        questions: (json['questions'] as List<dynamic>)
            .map((e) => QuickQuestionsDataPayloadQuestion.fromJson(
                (e as Map).cast<String, dynamic>()))
            .toList(),
        targetAudience: (json['target_audience'] as List<dynamic>?)
            ?.map((e) => QuickQuestionsDataPayloadTargetFilter.fromJson(
                (e as Map).cast<String, dynamic>()))
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
        'target_audience': targetAudience?.map((e) => e.toJson()).toList(),
      };
}