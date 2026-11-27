import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hasil_kuis.dart';
import '../models/materi.dart';
import '../models/soal.dart';

/// Semua komunikasi ke Supabase dikumpulkan di sini
/// supaya layar (screen) tidak berisi kode database.
class SupabaseService {
  static SupabaseClient get _db => Supabase.instance.client;

  // ---------- Auth ----------
  static Future<void> login(String email, String password) async {
    await _db.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> register(
    String nama,
    String nim,
    String email,
    String password,
  ) {
    return _db.auth.signUp(
      email: email,
      password: password,
      data: {'nama': nama, 'nim': nim},
    );
  }

  static Future<void> logout() => _db.auth.signOut();

  /// Mengambil nama dan role (guru/siswa) pengguna yang sedang masuk.
  static Future<Map<String, dynamic>?> fetchProfil() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    return await _db.from('profiles').select().eq('id', uid).maybeSingle();
  }

  // ---------- Data (semuanya per kelas) ----------
  static Future<List<Materi>> fetchMateri(int kelasId) async {
    final data = await _db
        .from('materi')
        .select()
        .eq('kelas_id', kelasId)
        .order('id');
    return data.map<Materi>((m) => Materi.fromMap(m)).toList();
  }

  static Future<List<Soal>> fetchSoal(int kelasId) async {
    final data =
        await _db.from('soal').select().eq('kelas_id', kelasId).order('id');
    return data.map<Soal>((m) => Soal.fromMap(m)).toList();
  }

  static Future<void> simpanHasil(int benar, int total, int kelasId) async {
    // user_id diisi otomatis oleh database (auth.uid()).
    await _db.from('hasil_kuis').insert({
      'benar': benar,
      'total': total,
      'kelas_id': kelasId,
    });
  }

  static Future<List<HasilKuis>> fetchRiwayat(int kelasId) async {
    final data = await _db
        .from('hasil_kuis')
        .select()
        .eq('kelas_id', kelasId)
        .order('created_at', ascending: false);
    return data.map<HasilKuis>((m) => HasilKuis.fromMap(m)).toList();
  }
}