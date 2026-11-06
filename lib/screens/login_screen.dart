import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _daftar = false;
  bool _loading = false;

  @override
  void dispose() {
    _namaC.dispose();
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  void _pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (_daftar) {
        final res = await SupabaseService.register(
          _namaC.text.trim(),
          _emailC.text.trim(),
          _passC.text,
        );
        if (res.session == null) {
          // Terjadi jika konfirmasi email di Supabase masih aktif.
          _pesan('Pendaftaran berhasil. Cek email untuk konfirmasi, lalu masuk.');
          if (mounted) setState(() => _daftar = false);
        }
        // Jika session ada, AuthGate otomatis membuka beranda.
      } else {
        await SupabaseService.login(_emailC.text.trim(), _passC.text);
      }
    } on AuthException catch (e) {
      _pesan(e.message);
    } catch (_) {
      _pesan('Terjadi kesalahan. Periksa koneksi internet lalu coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Media Pembelajaran & Kuis', style: tema.headlineSmall),
                    const SizedBox(height: 4),
                    Text(_daftar ? 'Buat akun baru' : 'Masuk ke akunmu'),
                    const SizedBox(height: 24),
                    if (_daftar) ...[
                      TextFormField(
                        controller: _namaC,
                        decoration: const InputDecoration(
                          labelText: 'Nama',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _emailC,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final teks = v?.trim() ?? '';
                        if (teks.isEmpty) return 'Email wajib diisi';
                        if (!teks.contains('@')) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passC,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Kata sandi',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Kata sandi minimal 6 karakter'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_daftar ? 'Daftar' : 'Masuk'),
                    ),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() => _daftar = !_daftar),
                      child: Text(_daftar
                          ? 'Sudah punya akun? Masuk'
                          : 'Belum punya akun? Daftar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
