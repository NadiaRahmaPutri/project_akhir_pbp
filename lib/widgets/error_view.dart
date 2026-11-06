import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final String pesan;

  const ErrorView({
    super.key,
    required this.onRetry,
    this.pesan = 'Data tidak bisa dimuat. Periksa koneksi internet, lalu coba lagi.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40),
            const SizedBox(height: 12),
            Text(pesan, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
