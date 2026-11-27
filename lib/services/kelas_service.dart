import 'package:supabase_flutter/supabase_flutter.dart';

class Kelas {
  final int id;
  final String nama;
  final String kode;

  const Kelas({required this.id, required this.nama, required this.kode});

  factory Kelas.fromMap(Map<String, dynamic> m) => Kelas(
        id: m['id'] as int,
        nama: m['nama'] as String,
        kode: m['kode'] as String,
      );
}

/// Operasi kelas: guru membuat kelas, siswa bergabung dengan kode.
class KelasService {
  static SupabaseClient get _db => Supabase.instance.client;

  /// Guru: kelas miliknya. Siswa: kelas yang diikuti (dibatasi RLS).
  static Future<List<Kelas>> fetchKelas() async {
    final data =
        await _db.from('kelas').select().order('created_at', ascending: false);
    return data.map<Kelas>((m) => Kelas.fromMap(m)).toList();
  }

  /// Kode kelas dibuat otomatis oleh database.
  static Future<Kelas> buatKelas(String nama) async {
    final data =
        await _db.from('kelas').insert({'nama': nama}).select().single();
    return Kelas.fromMap(data);
  }

  static Future<void> hapusKelas(int id) async {
    await _db.from('kelas').delete().eq('id', id);
  }

  /// Mengembalikan nama kelas yang dimasuki.
  static Future<String> gabung(String kode) async {
    final hasil = await _db.rpc('gabung_kelas', params: {'p_kode': kode});
    return hasil as String;
  }
}