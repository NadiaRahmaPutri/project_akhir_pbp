import 'package:flutter/material.dart';
import '../services/kelas_service.dart';
import 'kuis_daftar_screen.dart';
import 'materi_list_screen.dart';

/// Halaman di dalam satu kelas untuk siswa.
class SiswaKelasScreen extends StatelessWidget {
  final Kelas kelas;

  const SiswaKelasScreen({super.key, required this.kelas});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(kelas.nama)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Menu(
            icon: Icons.menu_book,
            judul: 'Materi',
            keterangan: 'Baca modul pembelajaran',
            tujuan: MateriListScreen(kelasId: kelas.id),
          ),
          _Menu(
            icon: Icons.quiz,
            judul: 'Kuis',
            keterangan: 'Daftar kuis, pengerjaan, dan nilaimu',
            tujuan: KuisDaftarScreen(kelas: kelas),
          ),
        ],
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String keterangan;
  final Widget tujuan;

  const _Menu({
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
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE3EEFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          judul,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
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