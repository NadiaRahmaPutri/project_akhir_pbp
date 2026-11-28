import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/soal.dart';

DateTime _waktu(dynamic v) => DateTime.parse(v as String).toLocal();
DateTime? _waktuOpsional(dynamic v) => v == null ? null : _waktu(v);
int? _angka(dynamic v) => v == null ? null : (v as num).toInt();

/// Kuis yang dibuat dosen untuk satu pertemuan.
class Kuis {
  final int id;
  final int kelasId;
  final String judul;
  final DateTime bukaPada;
  final DateTime tutupPada;
  final bool acak;
  final int jumlahSoal;

  const Kuis({
    required this.id,
    required this.kelasId,
    required this.judul,
    required this.bukaPada,
    required this.tutupPada,
    required this.acak,
    required this.jumlahSoal,
  });

  factory Kuis.fromMap(Map<String, dynamic> m) {
    var jumlah = 0;
    final soal = m['soal'];
    if (soal is List && soal.isNotEmpty) {
      final c = (soal.first as Map)['count'];
      if (c is num) jumlah = c.toInt();
    }
    return Kuis(
      id: (m['id'] as num).toInt(),
      kelasId: (m['kelas_id'] as num).toInt(),
      judul: m['judul'] as String,
      bukaPada: _waktu(m['buka_pada']),
      tutupPada: _waktu(m['tutup_pada']),
      acak: (m['acak'] as bool?) ?? true,
      jumlahSoal: jumlah,
    );
  }
}

enum StatusKuis { belumDibuka, dibuka, ditutup, selesai, belumSelesai }

/// Kuis dari sudut pandang mahasiswa, lengkap dengan status percobaannya.
class KuisMahasiswa {
  final int kuisId;
  final String judul;
  final DateTime bukaPada;
  final DateTime tutupPada;
  final bool acak;
  final int jumlahSoal;
  final int totalWaktu; // detik
  final int? percobaanId;
  final DateTime? mulaiPada;
  final DateTime? selesaiPada;
  final int? skor;
  final int? poin;
  final int? poinMaks;
  final DateTime sekarang; // jam server

  const KuisMahasiswa({
    required this.kuisId,
    required this.judul,
    required this.bukaPada,
    required this.tutupPada,
    required this.acak,
    required this.jumlahSoal,
    required this.totalWaktu,
    required this.sekarang,
    this.percobaanId,
    this.mulaiPada,
    this.selesaiPada,
    this.skor,
    this.poin,
    this.poinMaks,
  });

  factory KuisMahasiswa.fromMap(Map<String, dynamic> m) => KuisMahasiswa(
        kuisId: (m['kuis_id'] as num).toInt(),
        judul: m['judul'] as String,
        bukaPada: _waktu(m['buka_pada']),
        tutupPada: _waktu(m['tutup_pada']),
        acak: (m['acak'] as bool?) ?? true,
        jumlahSoal: _angka(m['jumlah_soal']) ?? 0,
        totalWaktu: _angka(m['total_waktu']) ?? 0,
        percobaanId: _angka(m['percobaan_id']),
        mulaiPada: _waktuOpsional(m['mulai_pada']),
        selesaiPada: _waktuOpsional(m['selesai_pada']),
        skor: _angka(m['skor']),
        poin: _angka(m['poin']),
        poinMaks: _angka(m['poin_maks']),
        sekarang: _waktu(m['sekarang']),
      );

  StatusKuis get status {
    if (selesaiPada != null) return StatusKuis.selesai;
    if (percobaanId != null) return StatusKuis.belumSelesai;
    if (sekarang.isBefore(bukaPada)) return StatusKuis.belumDibuka;
    if (sekarang.isAfter(tutupPada)) return StatusKuis.ditutup;
    return StatusKuis.dibuka;
  }

  String get labelStatus => switch (status) {
        StatusKuis.selesai => 'Selesai • Nilai ${skor ?? 0}',
        StatusKuis.belumSelesai => 'Belum selesai',
        StatusKuis.belumDibuka => 'Belum dibuka',
        StatusKuis.ditutup => 'Ditutup • Tidak dikerjakan',
        StatusKuis.dibuka => 'Dibuka',
      };

  /// Salinan dengan hasil setelah kuis diselesaikan.
  KuisMahasiswa denganHasil(HasilPercobaan h) => KuisMahasiswa(
        kuisId: kuisId,
        judul: judul,
        bukaPada: bukaPada,
        tutupPada: tutupPada,
        acak: acak,
        jumlahSoal: jumlahSoal,
        totalWaktu: totalWaktu,
        sekarang: sekarang,
        percobaanId: percobaanId,
        mulaiPada: mulaiPada,
        selesaiPada: h.selesaiPada,
        skor: h.skor,
        poin: h.poin,
        poinMaks: h.poinMaks,
      );
}

class HasilPercobaan {
  final int skor;
  final int poin;
  final int poinMaks;
  final DateTime selesaiPada;

  const HasilPercobaan({
    required this.skor,
    required this.poin,
    required this.poinMaks,
    required this.selesaiPada,
  });
}

/// Satu baris rekap dosen: satu mahasiswa untuk satu kuis.
class RekapBaris {
  final String userId;
  final String nim;
  final String nama;
  final int kuisId;
  final String kuisJudul;
  final int? skor;
  final int? poin;
  final int? poinMaks;
  final DateTime? mulaiPada;
  final DateTime? selesaiPada;

  const RekapBaris({
    required this.userId,
    required this.nim,
    required this.nama,
    required this.kuisId,
    required this.kuisJudul,
    this.skor,
    this.poin,
    this.poinMaks,
    this.mulaiPada,
    this.selesaiPada,
  });

  factory RekapBaris.fromMap(Map<String, dynamic> m) => RekapBaris(
        userId: m['user_id'] as String,
        nim: (m['nim'] as String?) ?? '',
        nama: (m['nama'] as String?) ?? '(tanpa nama)',
        kuisId: (m['kuis_id'] as num).toInt(),
        kuisJudul: m['kuis_judul'] as String,
        skor: _angka(m['skor']),
        poin: _angka(m['poin']),
        poinMaks: _angka(m['poin_maks']),
        mulaiPada: _waktuOpsional(m['mulai_pada']),
        selesaiPada: _waktuOpsional(m['selesai_pada']),
      );

  bool get adaPercobaan => mulaiPada != null;
  bool get selesai => selesaiPada != null;
}

class KuisService {
  static SupabaseClient get _db => Supabase.instance.client;

  // ---------- Dosen ----------
  static Future<List<Kuis>> fetchKuisKelas(int kelasId) async {
    final data = await _db
        .from('kuis')
        .select('*, soal(count)')
        .eq('kelas_id', kelasId)
        .order('buka_pada');
    return data.map<Kuis>((m) => Kuis.fromMap(m)).toList();
  }

  static Future<void> buatKuis(
    int kelasId,
    String judul,
    DateTime buka,
    DateTime tutup,
    bool acak,
  ) async {
    await _db.from('kuis').insert({
      'kelas_id': kelasId,
      'judul': judul,
      'buka_pada': buka.toUtc().toIso8601String(),
      'tutup_pada': tutup.toUtc().toIso8601String(),
      'acak': acak,
    });
  }

  static Future<void> ubahKuis(
    int id,
    String judul,
    DateTime buka,
    DateTime tutup,
    bool acak,
  ) async {
    await _db.from('kuis').update({
      'judul': judul,
      'buka_pada': buka.toUtc().toIso8601String(),
      'tutup_pada': tutup.toUtc().toIso8601String(),
      'acak': acak,
    }).eq('id', id);
  }

  static Future<void> hapusKuis(int id) async {
    await _db.from('kuis').delete().eq('id', id);
  }

  /// Soal satu kuis. Dosen pemilik kelas selalu bisa; mahasiswa hanya saat
  /// sedang mengerjakan (dibatasi RLS di database).
  static Future<List<Soal>> fetchSoalKuis(int kuisId) async {
    final data =
        await _db.from('soal').select().eq('kuis_id', kuisId).order('id');
    return data.map<Soal>((m) => Soal.fromMap(m)).toList();
  }

  static Future<List<RekapBaris>> rekapKelas(int kelasId) async {
    final data = await _db.rpc('rekap_kuis', params: {'p_kelas_id': kelasId});
    return (data as List)
        .map<RekapBaris>(
            (m) => RekapBaris.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  static Future<void> resetPercobaan(int kuisId, String userId) async {
    await _db.rpc(
      'reset_percobaan',
      params: {'p_kuis_id': kuisId, 'p_user_id': userId},
    );
  }

  // ---------- Mahasiswa ----------
  static Future<List<KuisMahasiswa>> daftarKuisMahasiswa(int kelasId) async {
    final data =
        await _db.rpc('daftar_kuis_mahasiswa', params: {'p_kelas_id': kelasId});
    return (data as List)
        .map<KuisMahasiswa>((m) =>
            KuisMahasiswa.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  /// Menandai kesempatan terpakai. Gagal kalau kuis belum dibuka, sudah
  /// ditutup, atau sudah pernah dikerjakan.
  static Future<void> mulaiKuis(int kuisId) async {
    await _db.rpc('mulai_kuis', params: {'p_kuis_id': kuisId});
  }

  /// [jawaban]: daftar {soal_id, indeks}; indeks null berarti tidak dijawab.
  static Future<HasilPercobaan> selesaiKuis(
    int kuisId,
    List<Map<String, dynamic>> jawaban,
  ) async {
    final data = await _db.rpc(
      'selesai_kuis',
      params: {'p_kuis_id': kuisId, 'p_jawaban': jawaban},
    );
    final m = Map<String, dynamic>.from(data as Map);
    return HasilPercobaan(
      skor: (m['skor'] as num).toInt(),
      poin: (m['poin'] as num).toInt(),
      poinMaks: (m['poin_maks'] as num).toInt(),
      selesaiPada: _waktu(m['selesai_pada']),
    );
  }
}
