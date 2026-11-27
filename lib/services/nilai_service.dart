import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hasil_kuis.dart';

/// Rekap hasil kuis satu siswa (untuk halaman guru).
class RekapSiswa {
  final String nama;
  final List<HasilKuis> percobaan; // yang terbaru di urutan pertama

  const RekapSiswa({required this.nama, required this.percobaan});

  int get jumlah => percobaan.length;

  int get rataRata {
    if (percobaan.isEmpty) return 0;
    final total = percobaan.map((h) => h.skor).reduce((a, b) => a + b);
    return (total / percobaan.length).round();
  }

  int? get terakhir => percobaan.isEmpty ? null : percobaan.first.skor;
}

class NilaiService {
  static SupabaseClient get _db => Supabase.instance.client;

  /// Mengambil semua siswa dan hasil kuisnya.
  /// Hanya berhasil untuk akun guru (dibatasi RLS di database).
  static Future<List<RekapSiswa>> fetchRekap() async {
    final siswa =
        await _db.from('profiles').select().eq('role', 'siswa').order('nama');
    final hasil = await _db
        .from('hasil_kuis')
        .select()
        .order('created_at', ascending: false);

    final perSiswa = <String, List<HasilKuis>>{};
    for (final m in hasil) {
      final id = m['user_id'] as String;
      perSiswa.putIfAbsent(id, () => []).add(HasilKuis.fromMap(m));
    }

    return siswa.map<RekapSiswa>((p) {
      final nama = ((p['nama'] as String?) ?? '').trim();
      return RekapSiswa(
        nama: nama.isEmpty ? 'Tanpa nama' : nama,
        percobaan: perSiswa[p['id'] as String] ?? [],
      );
    }).toList();
  }
}
