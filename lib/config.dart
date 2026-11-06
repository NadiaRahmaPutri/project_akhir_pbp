// Nilai diisi lewat --dart-define saat menjalankan aplikasi (lihat panduan),
// supaya URL dan key tidak tertulis di kode yang di-push ke GitHub.
class Config {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseKey = String.fromEnvironment('SUPABASE_KEY');
}
