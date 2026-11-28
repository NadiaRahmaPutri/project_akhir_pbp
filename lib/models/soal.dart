class Soal {
  final int id;
  final int? kuisId;
  final String pertanyaan;
  final List<String> pilihan;

  /// Bobot nilai tiap pilihan (sejajar dengan [pilihan]). Tidak ada jawaban
  /// salah: skor ditentukan oleh bobot pilihan yang dipilih mahasiswa.
  final List<int> bobot;
  final int waktuDetik; // batas waktu mengerjakan soal ini (detik)

  const Soal({
    required this.id,
    this.kuisId,
    required this.pertanyaan,
    required this.pilihan,
    required this.bobot,
    this.waktuDetik = 30,
  });

  /// Indeks pilihan dengan bobot tertinggi.
  int get jawabanBenar {
    var terbaik = 0;
    for (var i = 1; i < bobot.length; i++) {
      if (bobot[i] > bobot[terbaik]) terbaik = i;
    }
    return terbaik;
  }

  int get bobotMaks => bobot.isEmpty ? 0 : bobot.reduce((a, b) => a > b ? a : b);

  factory Soal.fromMap(Map<String, dynamic> map) {
    final pilihan = List<String>.from(map['pilihan'] as List);
    final mentah = map['bobot'];
    List<int> bobot;
    if (mentah is List) {
      bobot = mentah.map<int>((e) => (e as num).toInt()).toList();
    } else {
      // Data lama: satu jawaban benar berbobot 1, sisanya 0.
      final benar = (map['jawaban_benar'] as int?) ?? 0;
      bobot = List<int>.generate(pilihan.length, (i) => i == benar ? 1 : 0);
    }
    return Soal(
      id: map['id'] as int,
      kuisId: map['kuis_id'] as int?,
      pertanyaan: map['pertanyaan'] as String,
      pilihan: pilihan,
      bobot: bobot,
      waktuDetik: (map['waktu_detik'] as int?) ?? 30,
    );
  }
}
