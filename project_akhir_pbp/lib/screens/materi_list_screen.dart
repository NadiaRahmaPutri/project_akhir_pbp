import 'package:flutter/material.dart';
import '../data/data_materi.dart';
import 'materi_detail_screen.dart';

class MateriListScreen extends StatelessWidget {
  const MateriListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Materi')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dataMateri.length,
        itemBuilder: (context, index) {
          final materi = dataMateri[index];
          return Card(
            child: ListTile(
              title: Text(materi.judul),
              subtitle: Text(materi.ringkasan),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MateriDetailScreen(materi: materi),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
