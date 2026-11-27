import 'package:flutter/material.dart';
import '../models/materi.dart';

class MateriDetailScreen extends StatelessWidget {
  final Materi materi;

  const MateriDetailScreen({super.key, required this.materi});

  @override
  Widget build(BuildContext context) {
    final url = materi.gambarUrl;

    return Scaffold(
      appBar: AppBar(title: Text(materi.judul)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (url != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    height: 120,
                    color: const Color(0xFFE3EEFF),
                    alignment: Alignment.center,
                    child: const Text('Gambar tidak bisa dimuat'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              materi.isi,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
