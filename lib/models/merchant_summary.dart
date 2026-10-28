import 'merchant_item.dart';

/// Model Dart #3: Ringkasan analitik modal, stok, dan potensi keuntungan pedagang.
class MerchantSummary {
  const MerchantSummary({
    required this.totalSkuCount,
    required this.totalUnitsInStock,
    required this.totalCapitalIdr,
    required this.totalRevenuePotentialIdr,
    required this.totalProfitPotentialIdr,
    required this.needsRestockCount,
    required this.averageMarginPercent,
  });

  final int totalSkuCount;
  final int totalUnitsInStock;
  final int totalCapitalIdr;
  final int totalRevenuePotentialIdr;
  final int totalProfitPotentialIdr;
  final int needsRestockCount;
  final double averageMarginPercent;

  factory MerchantSummary.fromItems(List<MerchantItem> items) {
    if (items.isEmpty) {
      return const MerchantSummary(
        totalSkuCount: 0,
        totalUnitsInStock: 0,
        totalCapitalIdr: 0,
        totalRevenuePotentialIdr: 0,
        totalProfitPotentialIdr: 0,
        needsRestockCount: 0,
        averageMarginPercent: 0,
      );
    }

    int units = 0;
    int capital = 0;
    int revenue = 0;
    int profit = 0;
    int restock = 0;
    double marginSum = 0;

    for (final MerchantItem item in items) {
      units += item.stockQty;
      capital += item.totalCapital;
      revenue += item.totalRevenuePotential;
      profit += item.totalProfitPotential;
      marginSum += item.marginPercentage;
      if (item.needsAttention) {
        restock++;
      }
    }

    return MerchantSummary(
      totalSkuCount: items.length,
      totalUnitsInStock: units,
      totalCapitalIdr: capital,
      totalRevenuePotentialIdr: revenue,
      totalProfitPotentialIdr: profit,
      needsRestockCount: restock,
      averageMarginPercent: marginSum / items.length,
    );
  }
}
