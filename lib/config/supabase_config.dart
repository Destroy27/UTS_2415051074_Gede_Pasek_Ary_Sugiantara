/// Konfigurasi Supabase untuk Backend Database Project UTS LapakPintar.
///
/// CARA MENGISI PROJECT SUPABASE BARU:
/// 1. Buka dashboard Supabase (https://supabase.com/dashboard) -> buat project baru.
/// 2. Masuk ke SQL Editor -> jalankan isi file `supabase_setup.sql` pada root project.
/// 3. Masuk ke Project Settings > API Keys:
///    - Salin Project URL ke konstanta [url] di bawah ini.
///    - Salin `anon` / `publishable` key ke konstanta [publishableKey] di bawah ini.
///
/// CATATAN KEAMANAN (Sesuai Panduan UTS):
/// - Dilarang memasukkan `service_role` / `secret` key ke dalam kode aplikasi.
/// - Jika [url] atau [publishableKey] masih berupa placeholder (`YOUR_SUPABASE_...`),
///   aplikasi otomatis berjalan menggunakan Local Fallback Storage sehingga seluruh
///   fitur CRUD (Create, Read, Update, Delete) tetap dapat langsung diuji tanpa error.
class SupabaseConfig {
  const SupabaseConfig._();

  /// Ganti dengan Project URL dari Supabase baru Anda, contoh:
  /// 'https://abcdefghijklm.supabase.co'
  static const String url = 'https://YOUR_PROJECT_ID.supabase.co';

  /// Ganti dengan Anon / Publishable Key dari Supabase baru Anda:
  static const String publishableKey = 'YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY';

  /// Nama tabel utama pada database PostgreSQL Supabase.
  static const String inventoryTable = 'merchant_inventory';

  /// Mengecek apakah kredensial Supabase sudah diisi oleh pengguna.
  static bool get isConfigured =>
      url.isNotEmpty &&
      publishableKey.isNotEmpty &&
      !url.contains('YOUR_PROJECT_ID') &&
      !publishableKey.contains('YOUR_SUPABASE');
}
