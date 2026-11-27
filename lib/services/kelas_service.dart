import 'package:supabase_flutter/supabase_flutter.dart';

class Kelas {
  final int id;
  final String nama;

  const Kelas({required this.id, required this.nama});

  factory Kelas.fromMap(Map<String, dynamic> m) => Kelas(
        id: m['id'] as int,
        nama: m['nama'] as String,
      );
}

/// Satu baris daftar mahasiswa di sebuah kelas (dilihat dosen).
class MahasiswaKelas {
  final String nim;
  final String nama;
  final bool sudahDaftar;
  final String? namaAkun;

  const MahasiswaKelas({
    required this.nim,
    required this.nama,
    required this.sudahDaftar,
    this.namaAkun,
  });

  factory MahasiswaKelas.fromMap(Map<String, dynamic> m) => MahasiswaKelas(
        nim: m['nim'] as String,
        nama: m['nama'] as String,
        sudahDaftar: (m['sudah_daftar'] as bool?) ?? false,
        namaAkun: m['nama_akun'] as String?,
      );
}

/// Ringkasan hasil menempel daftar mahasiswa.
class HasilImpor {
  final int diproses;
  final int dilewati;
  final int terhubungBaru;

  const HasilImpor({
    required this.diproses,
    required this.dilewati,
    required this.terhubungBaru,
  });
}

/// Operasi kelas. Dosen membuat kelas dan memasukkan daftar mahasiswa (NIM);
/// mahasiswa otomatis masuk kelas saat NIM-nya cocok dengan daftar itu.
class KelasService {
  static SupabaseClient get _db => Supabase.instance.client;

  /// Dosen: kelas miliknya. Mahasiswa: kelas yang diikuti (dibatasi RLS).
  static Future<List<Kelas>> fetchKelas() async {
    final data =
        await _db.from('kelas').select().order('created_at', ascending: false);
    return data.map<Kelas>((m) => Kelas.fromMap(m)).toList();
  }

  static Future<Kelas> buatKelas(String nama) async {
    final data =
        await _db.from('kelas').insert({'nama': nama}).select().single();
    return Kelas.fromMap(data);
  }

  static Future<void> hapusKelas(int id) async {
    await _db.from('kelas').delete().eq('id', id);
  }

  /// Dosen menempel daftar "NIM [tab] Nama", satu baris per mahasiswa.
  static Future<HasilImpor> imporMahasiswa(int kelasId, String teks) async {
    final data = await _db.rpc(
      'impor_mahasiswa',
      params: {'p_kelas_id': kelasId, 'p_data': teks},
    );
    final m = Map<String, dynamic>.from(data as Map);
    return HasilImpor(
      diproses: (m['diproses'] as num).toInt(),
      dilewati: (m['dilewati'] as num).toInt(),
      terhubungBaru: (m['terhubung_baru'] as num).toInt(),
    );
  }

  static Future<List<MahasiswaKelas>> daftarMahasiswa(int kelasId) async {
    final data =
        await _db.rpc('daftar_mahasiswa', params: {'p_kelas_id': kelasId});
    return (data as List)
        .map<MahasiswaKelas>(
            (m) => MahasiswaKelas.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  static Future<void> hapusMahasiswa(int kelasId, String nim) async {
    await _db.rpc(
      'hapus_mahasiswa',
      params: {'p_kelas_id': kelasId, 'p_nim': nim},
    );
  }

  /// Mahasiswa mengisi atau memperbaiki NIM-nya sendiri.
  static Future<void> perbaikiNim(String nim) async {
    await _db.rpc('perbaiki_nim', params: {'p_nim': nim});
  }
}
