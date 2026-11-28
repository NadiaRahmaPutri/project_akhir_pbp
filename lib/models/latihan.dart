/// Soal latihan di bawah sebuah materi. Tidak dinilai dan boleh diulang.
class Latihan {
  final int id;
  final int materiId;
  final String pertanyaan;
  final List<String> pilihan;
  final int jawabanBenar; // indeks pilihan yang benar (mulai 0)
  final String? pembahasan;

  const Latihan({
    required this.id,
    required this.materiId,
    required this.pertanyaan,
    required this.pilihan,
    required this.jawabanBenar,
    this.pembahasan,
  });

  factory Latihan.fromMap(Map<String, dynamic> m) {
    final bahas = (m['pembahasan'] as String?)?.trim();
    return Latihan(
      id: (m['id'] as num).toInt(),
      materiId: (m['materi_id'] as num).toInt(),
      pertanyaan: m['pertanyaan'] as String,
      pilihan: List<String>.from(m['pilihan'] as List),
      jawabanBenar: (m['jawaban_benar'] as num).toInt(),
      pembahasan: (bahas == null || bahas.isEmpty) ? null : bahas,
    );
  }
}
