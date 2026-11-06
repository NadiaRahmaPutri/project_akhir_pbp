import 'package:flutter/material.dart';
import '../models/hasil_kuis.dart';
import '../services/supabase_service.dart';
import '../widgets/error_view.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  late Future<List<HasilKuis>> _future = SupabaseService.fetchRiwayat();

  void _muatUlang() {
    setState(() => _future = SupabaseService.fetchRiwayat());
  }

  String _format(DateTime w) {
    final menit = w.minute.toString().padLeft(2, '0');
    return '${w.day}/${w.month}/${w.year} ${w.hour}:$menit';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat nilai')),
      body: FutureBuilder<List<HasilKuis>>(
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
            return const Center(
              child: Text('Belum ada riwayat. Kerjakan kuis terlebih dulu.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: daftar.length,
            itemBuilder: (context, index) {
              final h = daftar[index];
              return Card(
                child: ListTile(
                  title: Text('Skor ${h.skor}'),
                  subtitle: Text(
                    'Benar ${h.benar} dari ${h.total} • ${_format(h.waktu)}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
