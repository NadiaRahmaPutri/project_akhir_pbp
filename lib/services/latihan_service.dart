import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/latihan.dart';

/// Latihan per materi. Dosen pemilik kelas menulis; mahasiswa anggota kelas
/// membaca (dibatasi RLS di database).
class LatihanService {
  static SupabaseClient get _db => Supabase.instance.client;

  static Future<List<Latihan>> fetch(int materiId) async {
    final data = await _db
        .from('latihan')
        .select()
        .eq('materi_id', materiId)
        .order('id');
    return data.map<Latihan>((m) => Latihan.fromMap(m)).toList();
  }

  static Future<void> tambah({
    required int kelasId,
    required int materiId,
    required String pertanyaan,
    required List<String> pilihan,
    required int jawabanBenar,
    String? pembahasan,
  }) async {
    await _db.from('latihan').insert({
      'kelas_id': kelasId,
      'materi_id': materiId,
      'pertanyaan': pertanyaan,
      'pilihan': pilihan,
      'jawaban_benar': jawabanBenar,
      'pembahasan': pembahasan,
    });
  }

  static Future<void> ubah(
    int id,
    String pertanyaan,
    List<String> pilihan,
    int jawabanBenar,
    String? pembahasan,
  ) async {
    await _db.from('latihan').update({
      'pertanyaan': pertanyaan,
      'pilihan': pilihan,
      'jawaban_benar': jawabanBenar,
      'pembahasan': pembahasan,
    }).eq('id', id);
  }

  static Future<void> hapus(int id) async {
    await _db.from('latihan').delete().eq('id', id);
  }
}
