import 'package:flutter/material.dart';
import 'kuis_screen.dart';
import 'materi_list_screen.dart';
import 'riwayat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Media Pembelajaran & Kuis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _MenuTile(
            icon: Icons.menu_book,
            judul: 'Materi',
            keterangan: 'Baca modul pembelajaran',
            tujuan: MateriListScreen(),
          ),
          _MenuTile(
            icon: Icons.quiz,
            judul: 'Kuis',
            keterangan: 'Kerjakan soal pilihan ganda',
            tujuan: KuisScreen(),
          ),
          _MenuTile(
            icon: Icons.history,
            judul: 'Riwayat nilai',
            keterangan: 'Lihat hasil kuis sebelumnya',
            tujuan: RiwayatScreen(),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String keterangan;
  final Widget tujuan;

  const _MenuTile({
    required this.icon,
    required this.judul,
    required this.keterangan,
    required this.tujuan,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, size: 32),
        title: Text(judul),
        subtitle: Text(keterangan),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => tujuan),
        ),
      ),
    );
  }
}
