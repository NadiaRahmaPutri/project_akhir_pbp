import 'package:flutter/material.dart';
import '../models/hasil_kuis.dart';
import '../models/soal.dart';
import '../services/supabase_service.dart';
import '../widgets/error_view.dart';
import 'hasil_screen.dart';

class KuisScreen extends StatefulWidget {
  const KuisScreen({super.key});

  @override
  State<KuisScreen> createState() => _KuisScreenState();
}

class _KuisScreenState extends State<KuisScreen> {
  late Future<List<Soal>> _future = SupabaseService.fetchSoal();

  void _muatUlang() {
    setState(() => _future = SupabaseService.fetchSoal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kuis')),
      body: FutureBuilder<List<Soal>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(onRetry: _muatUlang);
          }
          final daftar = snapshot.data ?? [];
          if (daftar.isEmpty) {
            return const Center(child: Text('Belum ada soal.'));
          }
          return _KuisBody(soal: daftar);
        },
      ),
    );
  }
}

class _KuisBody extends StatefulWidget {
  final List<Soal> soal;

  const _KuisBody({required this.soal});

  @override
  State<_KuisBody> createState() => _KuisBodyState();
}

class _KuisBodyState extends State<_KuisBody> {
  int _indeks = 0;
  bool _menyimpan = false;
  late final List<int?> _jawaban =
      List<int?>.filled(widget.soal.length, null);

  bool get _soalTerakhir => _indeks == widget.soal.length - 1;

  Future<void> _lanjut() async {
    if (!_soalTerakhir) {
      setState(() => _indeks++);
      return;
    }

    setState(() => _menyimpan = true);

    int benar = 0;
    for (var i = 0; i < widget.soal.length; i++) {
      if (_jawaban[i] == widget.soal[i].jawabanBenar) benar++;
    }
    final total = widget.soal.length;

    try {
      await SupabaseService.simpanHasil(benar, total);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hasil belum tersimpan ke riwayat. Periksa koneksi internet.'),
          ),
        );
      }
    }

    if (!mounted) return;
    final hasil = HasilKuis(waktu: DateTime.now(), benar: benar, total: total);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HasilScreen(hasil: hasil)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final soal = widget.soal[_indeks];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (_indeks + 1) / widget.soal.length,
          ),
          const SizedBox(height: 12),
          Text('Soal ${_indeks + 1} dari ${widget.soal.length}'),
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
                    onTap: _menyimpan
                        ? null
                        : () => setState(() => _jawaban[_indeks] = i),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  (_jawaban[_indeks] == null || _menyimpan) ? null : _lanjut,
              child: Text(_soalTerakhir ? 'Selesai' : 'Lanjut'),
            ),
          ),
        ],
      ),
    );
  }
}
