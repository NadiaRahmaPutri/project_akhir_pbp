import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_akhir_pbp/screens/login_screen.dart';

Future<void> tekan(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  testWidgets('form masuk kosong menampilkan pesan validasi', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tekan(tester, find.widgetWithText(FilledButton, 'Masuk'));

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi minimal 6 karakter'), findsOneWidget);
  });

  testWidgets('email tanpa @ ditolak', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'bukanemail');
    await tekan(tester, find.widgetWithText(FilledButton, 'Masuk'));

    expect(find.text('Format email tidak valid'), findsOneWidget);
  });

  testWidgets('form daftar menampilkan kolom NIM dan memvalidasinya',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tekan(tester, find.text('Belum punya akun? Daftar'));
    expect(find.widgetWithText(TextFormField, 'NIM'), findsOneWidget);

    await tekan(tester, find.widgetWithText(FilledButton, 'Daftar'));
    expect(find.text('Nama wajib diisi'), findsOneWidget);
    expect(find.text('NIM wajib diisi'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'NIM'), 'AB');
    await tekan(tester, find.widgetWithText(FilledButton, 'Daftar'));
    expect(find.text('NIM tidak valid (4-25 huruf atau angka)'),
        findsOneWidget);
  });
}