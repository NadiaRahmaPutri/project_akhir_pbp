import 'package:flutter/material.dart';
import '../data/data_soal.dart';
import '../data/riwayat_sementara.dart';
import '../models/hasil_kuis.dart';
import 'hasil_screen.dart';

class KuisScreen extends StatefulWidget {
  const KuisScreen({super.key});

  @override
  State<KuisScreen> createState() => _KuisScreenState();
}

class _KuisScreenState extends State<KuisScreen> {
  int _indeks = 0;
  final List<int?> _jawaban = List<int?>.filled(dataSoal.length, null);

  bool get _soalTerakhir => _indeks == dataSoal.length - 1;

  void _lanjut() {
    if (!_soalTerakhir) {
      setState(() => _indeks++);
      return;
    }

    int benar = 0;
    for (var i = 0; i < dataSoal.length; i++) {
      if (_jawaban[i] == dataSoal[i].jawabanBenar) benar++;
    }

    final hasil = HasilKuis(
      waktu: DateTime.now(),
      benar: benar,
      total: dataSoal.length,
    );
    riwayatSementara.insert(0, hasil);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HasilScreen(hasil: hasil)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final soal = dataSoal[_indeks];

    return Scaffold(
      appBar: AppBar(title: const Text('Kuis')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: (_indeks + 1) / dataSoal.length),
            const SizedBox(height: 12),
            Text('Soal ${_indeks + 1} dari ${dataSoal.length}'),
            const SizedBox(height: 8),
            Text(
              soal.pertanyaan,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: soal.pilihan.length,
                itemBuilder: (context, i) {
                  final dipilih = _jawaban[_indeks] == i;
                  return Card(
                    child: ListTile(
                      title: Text(soal.pilihan[i]),
                      selected: dipilih,
                      trailing: dipilih ? const Icon(Icons.check_circle) : null,
                      onTap: () => setState(() => _jawaban[_indeks] = i),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _jawaban[_indeks] == null ? null : _lanjut,
                child: Text(_soalTerakhir ? 'Selesai' : 'Lanjut'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
