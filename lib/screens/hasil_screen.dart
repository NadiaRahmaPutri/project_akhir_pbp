import 'package:flutter/material.dart';
import '../models/hasil_kuis.dart';
import 'riwayat_screen.dart';

class HasilScreen extends StatelessWidget {
  final HasilKuis hasil;

  const HasilScreen({super.key, required this.hasil});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil kuis'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Skor kamu', style: tema.titleMedium),
              Text('${hasil.skor}', style: tema.displayLarge),
              const SizedBox(height: 8),
              Text('Benar ${hasil.benar} dari ${hasil.total} soal'),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Kembali ke beranda'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RiwayatScreen()),
                ),
                child: const Text('Lihat riwayat nilai'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
