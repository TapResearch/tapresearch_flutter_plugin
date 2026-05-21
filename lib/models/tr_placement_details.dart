import 'tr_bonus_bar_progress.dart';

class TRPlacementDetails {
  final String? name;
  final String? contentType;
  final String? currencyName;
  final bool? isSale;
  final String? saleType;
  final String? saleEndDate;
  final double? saleMultiplier;
  final String? saleDisplayName;
  final String? saleTag;
  final TRBonusBarProgress? bonusBarProgress;

  TRPlacementDetails({
    this.name,
    this.contentType,
    this.currencyName,
    this.isSale,
    this.saleType,
    this.saleEndDate,
    this.saleMultiplier,
    this.saleDisplayName,
    this.saleTag,
    this.bonusBarProgress,
  });

  factory TRPlacementDetails.fromJson(Map<String, dynamic> json) =>
      TRPlacementDetails(
        name: json['name'] as String?,
        contentType: json['content_type'] as String?,
        currencyName: json['currency_name'] as String?,
        isSale: json['is_sale'] as bool?,
        saleType: json['sale_type'] as String?,
        saleEndDate: json['sale_end_date'] as String?,
        saleMultiplier: (json['sale_multiplier'] as num?)?.toDouble(),
        saleDisplayName: json['sale_display_name'] as String?,
        saleTag: json['sale_tag'] as String?,
        bonusBarProgress: json['bonus_bar_progress'] != null
            ? TRBonusBarProgress.fromJson(
                (json['bonus_bar_progress'] as Map).cast<String, dynamic>())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'content_type': contentType,
        'currency_name': currencyName,
        'is_sale': isSale,
        'sale_type': saleType,
        'sale_end_date': saleEndDate,
        'sale_multiplier': saleMultiplier,
        'sale_display_name': saleDisplayName,
        'sale_tag': saleTag,
        'bonus_bar_progress': bonusBarProgress?.toJson(),
      };
}