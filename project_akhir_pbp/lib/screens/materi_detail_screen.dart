import 'package:flutter/material.dart';
import '../models/materi.dart';

class MateriDetailScreen extends StatelessWidget {
  final Materi materi;

  const MateriDetailScreen({super.key, required this.materi});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(materi.judul)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          materi.isi,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
