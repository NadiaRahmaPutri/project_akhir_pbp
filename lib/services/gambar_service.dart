import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Memilih gambar dari galeri dan mengunggahnya ke Supabase Storage.
class GambarService {
  static const String _bucket = 'materi-gambar';

  /// Ukuran maksimal gambar (2 MB), sama dengan batas di bucket.
  static const int batasUkuran = 2 * 1024 * 1024;

  static SupabaseClient get _db => Supabase.instance.client;

  /// Membuka galeri. Hasilnya null jika pengguna membatalkan.
  static Future<XFile?> pilihGambar() {
    return ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
  }

  static String _tipe(String ekstensi) {
    switch (ekstensi) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Mengunggah gambar dan mengembalikan alamat publiknya.
  /// Hanya berhasil untuk akun guru (dibatasi policy di database).
  static Future<String> unggah(XFile file) async {
    final bytes = await file.readAsBytes();
    final nama = file.name.toLowerCase();
    final ekstensi = nama.contains('.') ? nama.split('.').last : 'jpg';
    final path = 'materi/${DateTime.now().millisecondsSinceEpoch}.$ekstensi';

    await _db.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _tipe(ekstensi)),
        );
    return _db.storage.from(_bucket).getPublicUrl(path);
  }
}
