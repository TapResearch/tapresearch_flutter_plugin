enum PayoutTypes {
  profileReward(0),
  partialPayout(1),
  fullPayout(3),
  quickQuestionsPayout(9);

  final int value;
  const PayoutTypes(this.value);

  static PayoutTypes? fromInt(int value) {
    for (final type in PayoutTypes.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

class TRReward {
  final String? transactionIdentifier;
  final String? placementIdentifier;
  final String? currencyName;
  final double? rewardAmount;
  final PayoutTypes? payoutEventType;
  final String? placementTag;

  TRReward({
    this.transactionIdentifier,
    this.placementIdentifier,
    this.currencyName,
    this.rewardAmount,
    this.payoutEventType,
    this.placementTag,
  });

  factory TRReward.fromJson(Map<String, dynamic> json) => TRReward(
        transactionIdentifier: json['transactionIdentifier'] as String?,
        placementIdentifier: json['placementIdentifier'] as String?,
        currencyName: json['currencyName'] as String?,
        rewardAmount: (json['rewardAmount'] as num?)?.toDouble(),
        payoutEventType: json['payoutEventType'] != null
            ? PayoutTypes.fromInt(json['payoutEventType'] as int)
            : null,
        placementTag: json['placementTag'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'transactionIdentifier': transactionIdentifier,
        'placementIdentifier': placementIdentifier,
        'currencyName': currencyName,
        'rewardAmount': rewardAmount,
        'payoutEventType': payoutEventType?.value,
        'placementTag': placementTag,
      };
}