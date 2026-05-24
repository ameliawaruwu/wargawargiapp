import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';
import 'home_screen.dart'; // Mengarah ke home_screen baru
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nikCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  Future<void> _prosesLoginWarga() async {
    if (_nikCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ NIK dan Password tidak boleh kosong!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final user = await DatabaseHelper.instance.checkLogin(_nikCtrl.text, _passCtrl.text);
    
    if (user != null) {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('is_logged_in', true);
      await sp.setString('nama_warga', user['nama']);
      await sp.setString('role_user', 'Warga Mandiri');
      await sp.setString('kode_wilayah', 'RT10_RW04');
      await sp.setInt('total_akses_aplikasi', 1);
      await sp.setBool('fitur_dark_tema', false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Selamat datang kembali, ${user['nama']}!'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ NIK atau Password salah / belum terdaftar!'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.holiday_village, size: 50, color: Color(0xFF6366F1)),
                    const SizedBox(height: 12),
                    const Text('PORTAL WARGAWARGI', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B365D))),
                    const SizedBox(height: 24),
                    TextField(controller: _nikCtrl, decoration: const InputDecoration(labelText: 'Masukkan NIK Anda', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(onPressed: _prosesLoginWarga, child: const Text('MASUK SEBAGAI WARGA')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: const Text('Belum punya akun? Registrasi Akun Warga Di Sini'),
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