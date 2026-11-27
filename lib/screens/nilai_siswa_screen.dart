import 'package:flutter/material.dart';
import '../services/nilai_service.dart';
import '../widgets/error_view.dart';

/// Halaman khusus guru: melihat hasil kuis semua siswa.
class NilaiSiswaScreen extends StatefulWidget {
  const NilaiSiswaScreen({super.key});

  @override
  State<NilaiSiswaScreen> createState() => _NilaiSiswaScreenState();
}

class _NilaiSiswaScreenState extends State<NilaiSiswaScreen> {
  late Future<List<RekapSiswa>> _future = NilaiService.fetchRekap();

  void _muat() {
    setState(() => _future = NilaiService.fetchRekap());
  }

  String _format(DateTime w) {
    final menit = w.minute.toString().padLeft(2, '0');
    return '${w.day}/${w.month}/${w.year} ${w.hour}:$menit';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nilai siswa'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: _muat,
          ),
        ],
      ),
      body: FutureBuilder<List<RekapSiswa>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(onRetry: _muat);
          }
          final daftar = snapshot.data ?? [];
          if (daftar.isEmpty) {
            return const Center(child: Text('Belum ada siswa terdaftar.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: daftar.length,
            itemBuilder: (context, i) {
              final r = daftar[i];

              if (r.jumlah == 0) {
                return Card(
                  child: ListTile(
                    title: Text(r.nama),
                    subtitle: const Text('Belum mengerjakan kuis'),
                  ),
                );
              }

              return Card(
                child: ExpansionTile(
                  title: Text(r.nama),
                  subtitle: Text(
                    '${r.jumlah} percobaan • rata-rata ${r.rataRata} • terakhir ${r.terakhir}',
                  ),
                  children: [
                    for (final h in r.percobaan)
                      ListTile(
                        dense: true,
                        title: Text('Skor ${h.skor}'),
                        subtitle: Text(
                          'Benar ${h.benar} dari ${h.total} • ${_format(h.waktu)}',
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
