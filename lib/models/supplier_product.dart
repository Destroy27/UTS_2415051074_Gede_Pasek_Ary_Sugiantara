import '../config/api_config.dart';

/// Model Dart #1: Representasi produk katalog grosir/supplier dari REST API.
///
/// Mengonversi JSON dari `GET https://dummyjson.com/products` menjadi objek Dart
/// dengan null safety dan perhitungan harga modal/rekomendasi jual dalam Rupiah.
class SupplierProduct {
  const SupplierProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priceUsd,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.brand,
    required this.sku,
    required this.thumbnail,
    required this.images,
    required this.minimumOrderQuantity,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final double priceUsd;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String brand;
  final String sku;
  final String thumbnail;
  final List<String> images;
  final int minimumOrderQuantity;

  /// Harga modal grosir per unit dalam Rupiah (dibulatkan ke kelipatan Rp 500).
  int get wholesalePriceIdr {
    final double rawIdr = priceUsd * ApiConfig.usdToIdrRate;
    final int rounded = ((rawIdr / 500).round() * 500);
    return rounded < 2500 ? 2500 : rounded;
  }

  /// Rekomendasi harga jual eceran pedagang (+22% margin, dibulatkan Rp 500).
  int get suggestedRetailPriceIdr {
    final double suggested = wholesalePriceIdr * 1.22;
    return ((suggested / 500).round() * 500);
  }

  /// Estimasi keuntungan per unit jika dijual dengan harga rekomendasi.
  int get estimatedProfitPerUnit => suggestedRetailPriceIdr - wholesalePriceIdr;

  /// Label kategori dalam Bahasa Indonesia agar ramah pedagang UMKM.
  String get categoryLabel {
    switch (category.toLowerCase()) {
      case 'groceries':
        return 'Sembako & Harian';
      case 'beauty':
        return 'Kosmetik & Sabun';
      case 'fragrances':
        return 'Parfum & Pewangi';
      case 'furniture':
        return 'Perlengkapan Rumah';
      default:
        return category.isEmpty
            ? 'Barang Umum'
            : '${category[0].toUpperCase()}${category.substring(1)}';
    }
  }

  factory SupplierProduct.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawImages =
        (json['images'] as List<dynamic>?) ?? const <dynamic>[];
    return SupplierProduct(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?)?.trim() ?? 'Produk Tanpa Nama',
      description:
          (json['description'] as String?)?.trim() ?? 'Tidak ada deskripsi.',
      category: (json['category'] as String?)?.trim() ?? 'groceries',
      priceUsd: (json['price'] as num?)?.toDouble() ?? 1.0,
      discountPercentage:
          (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      stock: (json['stock'] as num?)?.toInt() ?? 10,
      brand: (json['brand'] as String?)?.trim() ?? 'Grosir Nusantara',
      sku: (json['sku'] as String?)?.trim() ?? 'SKU-UMKM',
      thumbnail: (json['thumbnail'] as String?)?.trim() ?? '',
      images: rawImages.map((dynamic e) => e.toString()).toList(),
      minimumOrderQuantity:
          (json['minimumOrderQuantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'price': priceUsd,
      'discountPercentage': discountPercentage,
      'rating': rating,
      'stock': stock,
      'brand': brand,
      'sku': sku,
      'thumbnail': thumbnail,
      'images': images,
      'minimumOrderQuantity': minimumOrderQuantity,
    };
  }
}
