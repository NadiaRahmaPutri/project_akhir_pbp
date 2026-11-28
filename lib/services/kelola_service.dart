import 'package:supabase_flutter/supabase_flutter.dart';
import 'trivia_service.dart';

/// Operasi tambah, ubah, dan hapus (CRUD) materi dan soal.
/// Hanya berhasil untuk guru pemilik kelas karena dibatasi RLS di database.
class KelolaService {
  static SupabaseClient get _db => Supabase.instance.client;

  /// Kelas yang sedang dikelola guru. Diisi saat halaman kelola dibuka.
  static int? kelasAktifId;

  static int get _kelasId {
    final id = kelasAktifId;
    if (id == null) throw StateError('Kelas belum dipilih');
    return id;
  }

  // ---------- Materi ----------
  static Future<void> tambahMateri(
    String judul,
    String ringkasan,
    String isi, {
    String? gambarUrl,
  }) async {
    await _db.from('materi').insert({
      'kelas_id': _kelasId,
      'judul': judul,
      'ringkasan': ringkasan,
      'isi': isi,
      if (gambarUrl != null) 'gambar_url': gambarUrl,
    });
  }

  static Future<void> ubahMateri(
    int id,
    String judul,
    String ringkasan,
    String isi, {
    String? gambarUrl,
  }) async {
    await _db.from('materi').update({
      'judul': judul,
      'ringkasan': ringkasan,
      'isi': isi,
      if (gambarUrl != null) 'gambar_url': gambarUrl,
    }).eq('id', id);
  }

  static Future<void> hapusMateri(int id) async {
    await _db.from('materi').delete().eq('id', id);
  }

  // ---------- Soal (milik sebuah kuis, tiap pilihan punya bobot) ----------
  static Future<void> tambahSoal({
    required int kelasId,
    required int kuisId,
    required String pertanyaan,
    required List<String> pilihan,
    required List<int> bobot,
    required int waktuDetik,
  }) async {
    await _db.from('soal').insert({
      'kelas_id': kelasId,
      'kuis_id': kuisId,
      'pertanyaan': pertanyaan,
      'pilihan': pilihan,
      'bobot': bobot,
      'waktu_detik': waktuDetik,
    });
  }

  static Future<void> ubahSoal(
    int id,
    String pertanyaan,
    List<String> pilihan,
    List<int> bobot,
    int waktuDetik,
  ) async {
    await _db.from('soal').update({
      'pertanyaan': pertanyaan,
      'pilihan': pilihan,
      'bobot': bobot,
      'waktu_detik': waktuDetik,
    }).eq('id', id);
  }

  static Future<void> hapusSoal(int id) async {
    await _db.from('soal').delete().eq('id', id);
  }

  /// Menyimpan beberapa soal sekaligus (hasil impor dari Open Trivia DB)
  /// ke kuis tertentu. Jawaban benar berbobot 1, sisanya 0.
  static Future<void> imporSoal(
    int kelasId,
    int kuisId,
    List<SoalImpor> daftar,
  ) async {
    await _db.from('soal').insert(
          daftar
              .map((s) => {
                    'kelas_id': kelasId,
                    'kuis_id': kuisId,
                    'pertanyaan': s.pertanyaan,
                    'pilihan': s.pilihan,
                    'bobot': List<int>.generate(
                      s.pilihan.length,
                      (i) => i == s.jawabanBenar ? 1 : 0,
                    ),
                  })
              .toList(),
        );
  }
}
