class TRSurvey {
  final String? surveyId;
  final int? lengthInMinutes;
  final double? rewardAmount;
  final String? currencyName;
  final bool? isSale;
  final String? saleEndDate;
  final double? saleMultiplier;
  final double? preSaleRewardAmount;
  final bool? isHotTile;
  final String? category;

  TRSurvey({
    this.surveyId,
    this.lengthInMinutes,
    this.rewardAmount,
    this.currencyName,
    this.isSale,
    this.saleEndDate,
    this.saleMultiplier,
    this.preSaleRewardAmount,
    this.isHotTile,
    this.category,
  });

  factory TRSurvey.fromJson(Map<String, dynamic> json) => TRSurvey(
        surveyId: json['survey_identifier'] as String?,
        lengthInMinutes: json['length_in_minutes'] as int?,
        rewardAmount: (json['reward_amount'] as num?)?.toDouble(),
        currencyName: json['currency_name'] as String?,
        isSale: json['is_sale'] as bool?,
        saleEndDate: json['sale_end_date'] as String?,
        saleMultiplier: (json['sale_multiplier'] as num?)?.toDouble(),
        preSaleRewardAmount: (json['pre_sale_reward_amount'] as num?)?.toDouble(),
        isHotTile: json['is_hot_tile'] as bool?,
        category: json['category'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'survey_identifier': surveyId,
        'length_in_minutes': lengthInMinutes,
        'reward_amount': rewardAmount,
        'currency_name': currencyName,
        'is_sale': isSale,
        'sale_end_date': saleEndDate,
        'sale_multiplier': saleMultiplier,
        'pre_sale_reward_amount': preSaleRewardAmount,
        'is_hot_tile': isHotTile,
        'category': category,
      };
}

class TRSurveyRefreshPayload {
  final String? placementTag;

  TRSurveyRefreshPayload({this.placementTag});

  factory TRSurveyRefreshPayload.fromJson(Map<String, dynamic> json) =>
      TRSurveyRefreshPayload(
        placementTag: json['placement_tag'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'placement_tag': placementTag,
      };
}