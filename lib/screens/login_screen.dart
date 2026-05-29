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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.holiday_village, size: 50, color: AppColors.primary),
                  const SizedBox(height: 12),
                  const Text('PORTAL WARGAWARGI', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  const Text(
                    'Masuk dengan akun warga Anda untuk mengakses layanan RT',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nikCtrl,
                              keyboardType: TextInputType.number,
                              maxLength: 16,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.badge, color: AppColors.primary),
                                labelText: 'NIK',
                                hintText: 'Masukkan 16 digit NIK',
                                counterText: "",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'NIK wajib diisi!';
                                if (val.trim().length != 16) return 'NIK harus tepat 16 digit!';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _passwordHidden,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
                                labelText: 'Password',
                                hintText: 'Masukkan password',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                suffixIcon: IconButton(
                                  icon: Icon(_passwordHidden ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                                  onPressed: () => setState(() => _passwordHidden = !_passwordHidden),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Password wajib diisi!';
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _prosesLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 18),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                );
                              },
                              child: const Text('Belum punya akun? Daftar', style: TextStyle(color: AppColors.primary, fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}