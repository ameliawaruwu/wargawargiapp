import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart'; 
import 'rt_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nikCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _passwordHidden = true;

  Future<void> _prosesLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final user = await DatabaseHelper.instance.checkLogin(_nikCtrl.text, _passCtrl.text);
    
    if (user != null) {
      final userRole = user['role'] ?? 'Warga Mandiri';

      final sp = await SharedPreferences.getInstance();
      await sp.setBool('is_logged_in', true);
      await sp.setString('nik', user['nik']);
      await sp.setString('nama_warga', user['nama']);
      await sp.setString('role_user', userRole);
      await sp.setString('kode_wilayah', 'RT10_RW04');
      await sp.setInt('total_akses_aplikasi', 1);
      await sp.setBool('fitur_dark_tema', false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Selamat datang kembali, ${user['nama']}!'), backgroundColor: Colors.green),
        );
        
        if (userRole == 'Pengurus RT') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RtHomeScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NIK atau Password salah / belum terdaftar!'), backgroundColor: Colors.redAccent),
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
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE5E7EB))),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.holiday_village, size: 50, color: Color(0xFF6366F1)),
                    const SizedBox(height: 12),
                    const Text('PORTAL WARGAWARGI', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B365D))),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nikCtrl, 
                      decoration: const InputDecoration(labelText: 'Masukkan NIK Anda', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passCtrl, 
                      obscureText: true, 
                      decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _prosesLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('MASUK SEBAGAI WARGA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: const Text('Belum punya akun? Registrasi Akun Warga Di Sini', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12)),
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