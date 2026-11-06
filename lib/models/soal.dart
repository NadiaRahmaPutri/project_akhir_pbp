class Soal {
  final int id;
  final String pertanyaan;
  final List<String> pilihan;
  final int jawabanBenar; // indeks dari list pilihan (mulai dari 0)

  const Soal({
    required this.id,
    required this.pertanyaan,
    required this.pilihan,
    required this.jawabanBenar,
  });

  factory Soal.fromMap(Map<String, dynamic> map) {
    return Soal(
      id: map['id'] as int,
      pertanyaan: map['pertanyaan'] as String,
      pilihan: List<String>.from(map['pilihan'] as List),
      jawabanBenar: map['jawaban_benar'] as int,
    );
  }
}
