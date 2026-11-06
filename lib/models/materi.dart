class Materi {
  final int id;
  final String judul;
  final String ringkasan;
  final String isi;

  const Materi({
    required this.id,
    required this.judul,
    required this.ringkasan,
    required this.isi,
  });

  factory Materi.fromMap(Map<String, dynamic> map) {
    return Materi(
      id: map['id'] as int,
      judul: map['judul'] as String,
      ringkasan: (map['ringkasan'] ?? '') as String,
      isi: (map['isi'] ?? '') as String,
    );
  }
}
