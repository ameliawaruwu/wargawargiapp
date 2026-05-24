import 'package:flutter/material.dart';
import '../data/database_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nikCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  Future<void> _prosesRegistrasiWarga() async {
    if (_nikCtrl.text.isEmpty || _namaCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Gagal: Semua kolom wajib diisi!'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_nikCtrl.text.length != 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Format Salah: NIK KTP Warga harus tepat 16 digit!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final result = await DatabaseHelper.instance.insertUser({
      'nik': _nikCtrl.text,
      'nama': _namaCtrl.text,
      'password': _passCtrl.text,
    });

    if (result != -1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Akun warga berhasil disimpan ke SQLite!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Gagal: NIK sudah terdaftar sebelumnya!'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(title: const Text('Registrasi Warga Baru')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('BUAT AKUN WARGA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B365D))),
                    const SizedBox(height: 20),
                    TextField(controller: _nikCtrl, decoration: const InputDecoration(labelText: 'Nomor Induk Kependudukan (NIK)', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextField(controller: _namaCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap Sesuai KTP', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Buat Password', border: OutlineInputBorder())),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(onPressed: _prosesRegistrasiWarga, child: const Text('DAFTARKAN AKUN SAYA')),
                    )
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