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
}
