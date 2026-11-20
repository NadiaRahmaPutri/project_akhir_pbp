import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// Soal hasil ambil dari Open Trivia DB, sudah dalam format aplikasi kita.
class SoalImpor {
  final String pertanyaan;
  final List<String> pilihan;
  final int jawabanBenar; // indeks pilihan yang benar (mulai 0)

  const SoalImpor({
    required this.pertanyaan,
    required this.pilihan,
    required this.jawabanBenar,
  });
}

class TriviaException implements Exception {
  final String pesan;
  TriviaException(this.pesan);

  @override
  String toString() => pesan;
}

/// Integrasi REST API pihak ketiga: https://opentdb.com (tanpa API key).
/// Batas layanan: 1 permintaan per 5 detik per alamat IP.
class TriviaService {
  static const int _kategoriKomputer = 18; // Science: Computers

  static Future<http.Response> _kirim(Uri uri) async {
    try {
      return await http.get(uri).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw TriviaException(
        'Tidak bisa terhubung ke Open Trivia DB. Periksa koneksi internet.',
      );
    }
  }

  static String _dekode(String teks) => Uri.decodeComponent(teks);

  static Future<List<SoalImpor>> ambilSoal({int jumlah = 5}) async {
    final uri = Uri.https('opentdb.com', '/api.php', {
      'amount': '$jumlah',
      'category': '$_kategoriKomputer',
      'type': 'multiple',
      'encode': 'url3986', // teks dikodekan agar karakter khusus aman
    });

    final res = await _kirim(uri);

    if (res.statusCode == 429) {
      throw TriviaException('Terlalu sering meminta soal. Tunggu 5 detik, lalu coba lagi.');
    }
    if (res.statusCode != 200) {
      throw TriviaException('Open Trivia DB gagal merespons (kode ${res.statusCode}).');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final kode = data['response_code'];
    if (kode == 5) {
      throw TriviaException('Terlalu sering meminta soal. Tunggu 5 detik, lalu coba lagi.');
    }
    if (kode != 0) {
      throw TriviaException('Tidak ada soal yang bisa diambil saat ini.');
    }

    final acak = Random();
    final hasil = (data['results'] as List).cast<Map<String, dynamic>>();

    return hasil.map((m) {
      final benar = _dekode(m['correct_answer'] as String);
      final salah = (m['incorrect_answers'] as List).map((e) => _dekode(e as String));
      final pilihan = <String>[benar, ...salah]..shuffle(acak);
      return SoalImpor(
        pertanyaan: _dekode(m['question'] as String),
        pilihan: pilihan,
        jawabanBenar: pilihan.indexOf(benar),
      );
    }).toList();
  }
}
