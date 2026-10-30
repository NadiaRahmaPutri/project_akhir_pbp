import 'package:flutter/material.dart';
import '../data/riwayat_sementara.dart';

class RiwayatScreen extends StatelessWidget {
  const RiwayatScreen({super.key});

  String _format(DateTime w) {
    final menit = w.minute.toString().padLeft(2, '0');
    return '${w.day}/${w.month}/${w.year} ${w.hour}:$menit';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat nilai')),
      body: riwayatSementara.isEmpty
          ? const Center(
              child: Text('Belum ada riwayat. Kerjakan kuis terlebih dulu.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: riwayatSementara.length,
              itemBuilder: (context, index) {
                final h = riwayatSementara[index];
                return Card(
                  child: ListTile(
                    title: Text('Skor ${h.skor}'),
                    subtitle: Text(
                      'Benar ${h.benar} dari ${h.total} • ${_format(h.waktu)}',
                    ),
                  ),
                );
              },
            ),
    );
  }
}
