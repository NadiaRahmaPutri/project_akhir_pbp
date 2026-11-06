class HasilKuis {
  final DateTime waktu;
  final int benar;
  final int total;

  const HasilKuis({
    required this.waktu,
    required this.benar,
    required this.total,
  });

  int get skor => total == 0 ? 0 : ((benar / total) * 100).round();

  factory HasilKuis.fromMap(Map<String, dynamic> map) {
    return HasilKuis(
      waktu: DateTime.parse(map['created_at'] as String).toLocal(),
      benar: map['benar'] as int,
      total: map['total'] as int,
    );
  }
}
