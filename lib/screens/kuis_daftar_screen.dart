import 'package:flutter/material.dart';
import '../services/kelas_service.dart';
import '../services/kuis_service.dart';
import '../utils/format_waktu.dart';
import '../widgets/error_view.dart';
import 'kuis_screen.dart';

/// Mahasiswa: daftar kuis di satu kelas (per pertemuan) beserta statusnya.
class KuisDaftarScreen extends StatefulWidget {
  final Kelas kelas;

  const KuisDaftarScreen({super.key, required this.kelas});

  @override
  State<KuisDaftarScreen> createState() => _KuisDaftarScreenState();
}

class _KuisDaftarScreenState extends State<KuisDaftarScreen> {
  late Future<List<KuisMahasiswa>> _future =
      KuisService.daftarKuisMahasiswa(widget.kelas.id);

  void _muat() {
    setState(() {
      _future = KuisService.daftarKuisMahasiswa(widget.kelas.id);
    });
  }

  Future<void> _buka(KuisMahasiswa k) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => KuisScreen(kuis: k)),
    );
    if (mounted) _muat();
  }

  IconData _ikon(StatusKuis s) => switch (s) {
        StatusKuis.selesai => Icons.check_circle,
        StatusKuis.belumSelesai => Icons.error_outline,
        StatusKuis.belumDibuka => Icons.schedule,
        StatusKuis.ditutup => Icons.lock_outline,
        StatusKuis.dibuka => Icons.play_circle_outline,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kuis: ${widget.kelas.nama}')),
      body: FutureBuilder<List<KuisMahasiswa>>(
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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada kuis di kelas ini. Dosen akan menambahkannya.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: daftar.length,
            itemBuilder: (context, i) {
              final k = daftar[i];
              final warna = k.status == StatusKuis.dibuka
                  ? Theme.of(context).colorScheme.primary
                  : null;
              return Card(
                child: ListTile(
                  isThreeLine: true,
                  leading: Icon(_ikon(k.status), color: warna),
                  title: Text(
                    k.judul,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${jadwalKuis(k.bukaPada, k.tutupPada)}\n${k.labelStatus}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _buka(k),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
