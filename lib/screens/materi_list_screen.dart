import 'package:flutter/material.dart';
import '../models/materi.dart';
import '../services/supabase_service.dart';
import '../widgets/error_view.dart';
import 'materi_detail_screen.dart';

class MateriListScreen extends StatefulWidget {
  const MateriListScreen({super.key});

  @override
  State<MateriListScreen> createState() => _MateriListScreenState();
}

class _MateriListScreenState extends State<MateriListScreen> {
  late Future<List<Materi>> _future = SupabaseService.fetchMateri();

  void _muatUlang() {
    setState(() => _future = SupabaseService.fetchMateri());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Materi')),
      body: FutureBuilder<List<Materi>>(
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
            return const Center(child: Text('Belum ada materi.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: daftar.length,
            itemBuilder: (context, index) {
              final materi = daftar[index];
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
          );
        },
      ),
    );
  }
}
