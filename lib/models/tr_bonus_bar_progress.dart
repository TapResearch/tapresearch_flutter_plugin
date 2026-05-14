import 'tr_error.dart';

class TRBonusTier {
  final int? tierNumber;
  final int? completesNeeded;
  final double? rewardAmount;
  final String? status;

  TRBonusTier({
    this.tierNumber,
    this.completesNeeded,
    this.rewardAmount,
    this.status,
  });

  factory TRBonusTier.fromJson(Map<String, dynamic> json) => TRBonusTier(
        tierNumber: json['tier_number'] as int?,
        completesNeeded: json['completes_needed'] as int?,
        rewardAmount: (json['reward_amount'] as num?)?.toDouble(),
        status: json['status'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'tier_number': tierNumber,
        'completes_needed': completesNeeded,
        'reward_amount': rewardAmount,
        'status': status,
      };
}

class TRBonusBarProgress {
  final bool? isActive;
  final int? currentCompletes;
  final String? bonusWindowEndAt;
  final List<TRBonusTier>? bonusTiers;
  final TRError? error;

  TRBonusBarProgress({
    this.isActive,
    this.currentCompletes,
    this.bonusWindowEndAt,
    this.bonusTiers,
    this.error,
  });

  factory TRBonusBarProgress.fromJson(Map<String, dynamic> json) =>
      TRBonusBarProgress(
        isActive: json['is_active'] as bool?,
        currentCompletes: json['current_completes'] as int?,
        bonusWindowEndAt: json['bonus_window_end_at'] as String?,
        bonusTiers: (json['bonus_tiers'] as List<dynamic>?)
            ?.map((e) => TRBonusTier.fromJson(e as Map<String, dynamic>))
            .toList(),
        error: json['error'] != null
            ? TRError.fromJson(json['error'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'is_active': isActive,
        'current_completes': currentCompletes,
        'bonus_window_end_at': bonusWindowEndAt,
        'bonus_tiers': bonusTiers?.map((e) => e.toJson()).toList(),
        'error': error?.toJson(),
      };
}