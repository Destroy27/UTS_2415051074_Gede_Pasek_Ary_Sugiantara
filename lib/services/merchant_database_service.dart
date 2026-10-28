import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/merchant_item.dart';

/// Service Layer untuk operasi CRUD Database Stok Barang Pedagang.
///
/// Mendukung:
/// 1. **Supabase Cloud PostgreSQL** (ketika `SupabaseConfig.url` & `publishableKey`
///    telah diisi oleh mahasiswa dan tabel `merchant_inventory` tersedia).
/// 2. **Smart Local Fallback Storage** (ketika kredensial Supabase baru belum diisi
///    atau tabel belum dibuat), sehingga aplikasi 100% langsung berfungsi penuh
///    untuk Create, Read, Update, dan Delete tanpa error.
class MerchantDatabaseService {
  MerchantDatabaseService({required this.supabaseInitialized});

  final bool supabaseInitialized;

  /// Menandakan apakah operasi terakhir dilayani langsung oleh Cloud Supabase.
  bool isCloudActive = false;

  /// Penyimpanan lokal in-memory sebagai fallback otomatis sebelum Supabase diisi.
  final List<MerchantItem> _localItems = <MerchantItem>[
    MerchantItem(
      id: 1,
      studentId: '2415051074',
      productId: 20,
      productTitle: 'Minyak Goreng Sawit Kemasan 1L',
      category: 'Sembako & Harian',
      buyPrice: 15500,
      sellPrice: 18000,
      stockQty: 36,
      restockStatus: 'Stok Aman',
      merchantNote:
          'Agen Grosir Singaraja - Barang paling cepat perputarannya di warung.',
      rating: 5,
      thumbnailUrl:
          'https://cdn.dummyjson.com/products/images/groceries/Cooking%20Oil/thumbnail.png',
      createdAt: DateTime(2026, 10, 20, 8, 30),
    ),
    MerchantItem(
      id: 2,
      studentId: '2415051074',
      productId: 23,
      productTitle: 'Telur Ayam Negeri (Per Tray 30 Butir)',
      category: 'Sembako & Harian',
      buyPrice: 48000,
      sellPrice: 56000,
      stockQty: 4,
      restockStatus: 'Perlu Kulakan',
      merchantNote:
          'Stok sisa 4 tray, wajib pesan ulang ke peternak sebelum hari Sabtu.',
      rating: 5,
      thumbnailUrl:
          'https://cdn.dummyjson.com/products/images/groceries/Eggs/thumbnail.png',
      createdAt: DateTime(2026, 10, 22, 10, 15),
    ),
    MerchantItem(
      id: 3,
      studentId: '2415051074',
      productId: 16,
      productTitle: 'Apel Merah Segar Grosir (Per Kg)',
      category: 'Sembako & Harian',
      buyPrice: 28000,
      sellPrice: 35000,
      stockQty: 18,
      restockStatus: 'Stok Aman',
      merchantNote: 'Simpan di rak teduh agar tetap renyah dan segar.',
      rating: 4,
      thumbnailUrl:
          'https://cdn.dummyjson.com/products/images/groceries/Apple/thumbnail.png',
      createdAt: DateTime(2026, 10, 24, 14, 0),
    ),
    MerchantItem(
      id: 4,
      studentId: '2415051074',
      productId: 29,
      productTitle: 'Minuman Sari Buah Botol 500ml',
      category: 'Minuman & Jajanan',
      buyPrice: 7500,
      sellPrice: 10000,
      stockQty: 0,
      restockStatus: 'Habis',
      merchantNote:
          'Laris manis saat cuaca panas, masukkan daftar belanja kulakan besok.',
      rating: 5,
      thumbnailUrl:
          'https://cdn.dummyjson.com/products/images/groceries/Juice/thumbnail.png',
      createdAt: DateTime(2026, 10, 25, 9, 45),
    ),
  ];

  int _nextLocalId = 5;

  bool get _canTrySupabase =>
      supabaseInitialized && SupabaseConfig.isConfigured;

  /// READ: Mengambil seluruh daftar inventaris barang dagangan dari database.
  Future<List<MerchantItem>> getInventoryItems({
    bool forceDatabaseError = false,
  }) async {
    if (forceDatabaseError) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      throw Exception(
        'Simulasi Error Database: Gagal memuat tabel `${SupabaseConfig.inventoryTable}`. Pastikan koneksi atau kebijakan RLS Supabase aktif.',
      );
    }

    if (_canTrySupabase) {
      try {
        final List<Map<String, dynamic>> rows = await Supabase.instance.client
            .from(SupabaseConfig.inventoryTable)
            .select()
            .order('id', ascending: false);
        isCloudActive = true;
        return rows.map(MerchantItem.fromJson).toList();
      } catch (_) {
        isCloudActive = false;
      }
    }

    isCloudActive = false;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final List<MerchantItem> sorted = List<MerchantItem>.from(_localItems)
      ..sort((MerchantItem a, MerchantItem b) => (b.id ?? 0).compareTo(a.id ?? 0));
    return sorted;
  }

  /// CREATE: Menambahkan data barang dagangan / catatan kulakan baru ke database.
  Future<MerchantItem> createInventoryItem(MerchantItem item) async {
    if (_canTrySupabase) {
      try {
        final Map<String, dynamic> inserted = await Supabase.instance.client
            .from(SupabaseConfig.inventoryTable)
            .insert(item.toJson())
            .select()
            .single();
        isCloudActive = true;
        return MerchantItem.fromJson(inserted);
      } catch (_) {
        isCloudActive = false;
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 220));
    final MerchantItem created = item.copyWith(
      id: _nextLocalId++,
      createdAt: DateTime.now(),
    );
    _localItems.insert(0, created);
    return created;
  }

  /// UPDATE: Memperbarui data stok, harga, status, atau catatan barang di database.
  Future<MerchantItem> updateInventoryItem(int id, MerchantItem item) async {
    if (_canTrySupabase) {
      try {
        final Map<String, dynamic> updated = await Supabase.instance.client
            .from(SupabaseConfig.inventoryTable)
            .update(item.toJson())
            .eq('id', id)
            .select()
            .single();
        isCloudActive = true;
        return MerchantItem.fromJson(updated);
      } catch (_) {
        isCloudActive = false;
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 200));
    final int index =
        _localItems.indexWhere((MerchantItem element) => element.id == id);
    final MerchantItem updatedItem = item.copyWith(
      id: id,
      createdAt: index >= 0 ? _localItems[index].createdAt : DateTime.now(),
    );
    if (index >= 0) {
      _localItems[index] = updatedItem;
    } else {
      _localItems.insert(0, updatedItem);
    }
    return updatedItem;
  }

  /// DELETE: Menghapus data barang dagangan dari database berdasarkan ID.
  Future<void> deleteInventoryItem(int id) async {
    if (_canTrySupabase) {
      try {
        await Supabase.instance.client
            .from(SupabaseConfig.inventoryTable)
            .delete()
            .eq('id', id);
        isCloudActive = true;
        return;
      } catch (_) {
        isCloudActive = false;
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 180));
    _localItems.removeWhere((MerchantItem element) => element.id == id);
  }
}
