import 'package:supabase_flutter/supabase_flutter.dart';
import 'trivia_service.dart';

/// Operasi tambah, ubah, dan hapus (CRUD) materi dan soal.
/// Hanya berhasil untuk akun berperan 'guru' karena dibatasi RLS di database.
class KelolaService {
  static SupabaseClient get _db => Supabase.instance.client;

  // ---------- Materi ----------
  static Future<void> tambahMateri(
    String judul,
    String ringkasan,
    String isi, {
    String? gambarUrl,
  }) async {
    await _db.from('materi').insert({
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

  // ---------- Soal ----------
  static Future<void> tambahSoal(
    String pertanyaan,
    List<String> pilihan,
    int jawabanBenar,
    int waktuDetik,
  ) async {
    await _db.from('soal').insert({
      'pertanyaan': pertanyaan,
      'pilihan': pilihan,
      'jawaban_benar': jawabanBenar,
      'waktu_detik': waktuDetik,
    });
  }

  static Future<void> ubahSoal(
    int id,
    String pertanyaan,
    List<String> pilihan,
    int jawabanBenar,
    int waktuDetik,
  ) async {
    await _db.from('soal').update({
      'pertanyaan': pertanyaan,
      'pilihan': pilihan,
      'jawaban_benar': jawabanBenar,
      'waktu_detik': waktuDetik,
    }).eq('id', id);
  }

  static Future<void> hapusSoal(int id) async {
    await _db.from('soal').delete().eq('id', id);
  }

  /// Menyimpan beberapa soal sekaligus (hasil impor dari Open Trivia DB).
  static Future<void> imporSoal(List<SoalImpor> daftar) async {
    await _db.from('soal').insert(
          daftar
              .map((s) => {
                    'pertanyaan': s.pertanyaan,
                    'pilihan': s.pilihan,
                    'jawaban_benar': s.jawabanBenar,
                  })
              .toList(),
        );
  }
}