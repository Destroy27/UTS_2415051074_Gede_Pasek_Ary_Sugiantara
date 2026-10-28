/// Model Dart #2: Representasi data stok barang & catatan kulakan pedagang
/// pada tabel database `merchant_inventory` di Supabase PostgreSQL.
///
/// Memenuhi spesifikasi minimum tabel database UTS:
/// - Primary key (`id`)
/// - Lebih dari 4 field data (`student_id`, `product_id`, `product_title`,
///   `category`, `buy_price`, `sell_price`, `stock_qty`, `restock_status`,
///   `merchant_note`, `rating`, `thumbnail_url`, `created_at`).
class MerchantItem {
  const MerchantItem({
    this.id,
    required this.studentId,
    required this.productId,
    required this.productTitle,
    required this.category,
    required this.buyPrice,
    required this.sellPrice,
    required this.stockQty,
    required this.restockStatus,
    required this.merchantNote,
    required this.rating,
    this.thumbnailUrl = '',
    this.createdAt,
  });

  final int? id;
  final String studentId;
  final int productId;
  final String productTitle;
  final String category;
  final int buyPrice;
  final int sellPrice;
  final int stockQty;
  final String restockStatus;
  final String merchantNote;
  final int rating;
  final String thumbnailUrl;
  final DateTime? createdAt;

  /// Daftar status stok standar yang dapat dipilih pedagang.
  static const List<String> validStatuses = <String>[
    'Stok Aman',
    'Perlu Kulakan',
    'Habis',
    'Rencana Beli',
  ];

  /// Daftar kategori barang dagangan standar.
  static const List<String> standardCategories = <String>[
    'Sembako & Harian',
    'Minuman & Jajanan',
    'Kosmetik & Sabun',
    'Parfum & Pewangi',
    'Perlengkapan Rumah',
    'Alat Tulis & Lainnya',
  ];

  /// Keuntungan bersih per unit barang (Harga Jual - Harga Beli Modal).
  int get profitPerUnit => sellPrice - buyPrice;

  /// Persentase margin laba terhadap harga modal.
  double get marginPercentage {
    if (buyPrice <= 0) return 0;
    return ((sellPrice - buyPrice) / buyPrice) * 100;
  }

  /// Total nilai modal tertanam pada stok barang ini.
  int get totalCapital => buyPrice * stockQty;

  /// Total potensi omzet jika seluruh stok barang ini terjual.
  int get totalRevenuePotential => sellPrice * stockQty;

  /// Total potensi laba bersih dari stok barang yang tersedia.
  int get totalProfitPotential => profitPerUnit * stockQty;

  /// Apakah barang ini memerlukan perhatian restock / kulakan segera.
  bool get needsAttention =>
      restockStatus == 'Perlu Kulakan' ||
      restockStatus == 'Habis' ||
      stockQty <= 5;

  MerchantItem copyWith({
    int? id,
    String? studentId,
    int? productId,
    String? productTitle,
    String? category,
    int? buyPrice,
    int? sellPrice,
    int? stockQty,
    String? restockStatus,
    String? merchantNote,
    int? rating,
    String? thumbnailUrl,
    DateTime? createdAt,
  }) {
    return MerchantItem(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      category: category ?? this.category,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stockQty: stockQty ?? this.stockQty,
      restockStatus: restockStatus ?? this.restockStatus,
      merchantNote: merchantNote ?? this.merchantNote,
      rating: rating ?? this.rating,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MerchantItem.fromJson(Map<String, dynamic> json) {
    return MerchantItem(
      id: (json['id'] as num?)?.toInt(),
      studentId: (json['student_id'] as String?) ?? '2415051074',
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      productTitle:
          (json['product_title'] as String?)?.trim() ?? 'Barang Dagangan',
      category: (json['category'] as String?)?.trim() ?? 'Sembako & Harian',
      buyPrice: (json['buy_price'] as num?)?.toInt() ?? 0,
      sellPrice: (json['sell_price'] as num?)?.toInt() ?? 0,
      stockQty: (json['stock_qty'] as num?)?.toInt() ?? 0,
      restockStatus: (json['restock_status'] as String?) ?? 'Stok Aman',
      merchantNote: (json['merchant_note'] as String?) ?? '',
      rating: ((json['rating'] as num?)?.toInt() ?? 5).clamp(1, 5),
      thumbnailUrl: (json['thumbnail_url'] as String?) ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final Map<String, dynamic> map = <String, dynamic>{
      'student_id': studentId,
      'product_id': productId,
      'product_title': productTitle,
      'category': category,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'stock_qty': stockQty,
      'restock_status': restockStatus,
      'merchant_note': merchantNote,
      'rating': rating,
      'thumbnail_url': thumbnailUrl,
    };
    if (includeId && id != null) {
      map['id'] = id;
    }
    return map;
  }
}
