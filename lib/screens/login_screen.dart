import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';
import 'home_screen.dart';
import 'rt_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nikCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;  

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
      await sp.setString('nik', user['nik']);
      await sp.setString('nama_warga', user['nama']);
      
      // ✓ PERBAIKAN: Ambil role dari database dan simpan dengan benar
      final roleFromDb = user['role'] ?? 'Warga Mandiri';
      print('🔐 LOGIN: Role dari database = $roleFromDb');
      await sp.setString('role_user', roleFromDb);
      await sp.setString('kode_wilayah', 'RT10_RW04');
      await sp.setInt('total_akses_aplikasi', 1);
      await sp.setBool('fitur_dark_tema', false);
      
      // Verifikasi bahwa role tersimpan dengan benar
      final savedRole = sp.getString('role_user');
      print('✓ SAVED: Role yang tersimpan = $savedRole');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Selamat datang, ${user['nama']}!'), backgroundColor: Colors.green),
        );
        
        // ✓ PERBAIKAN: Routing berdasarkan role dengan logic yang lebih jelas
        await Future.delayed(const Duration(milliseconds: 500));
        
        final role = savedRole ?? 'Warga Mandiri';
        print('📍 ROUTING: Mengecek role = $role');
        
        Widget nextScreen;
        if (role.contains('RT') || role.contains('Pengurus') || role.toLowerCase().contains('rt')) {
          print('✅ MASUK KE: RtHomeScreen');
          nextScreen = const RtHomeScreen();
        } else {
          print('✅ MASUK KE: HomeScreen (Warga)');
          nextScreen = const HomeScreen();
        }
        
        if (mounted) {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => nextScreen),
          );
        }
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
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE5E7EB))),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.holiday_village, size: 50, color: Color(0xFF334E68)),
                    const SizedBox(height: 12),
                    const Text('PORTAL WARGAWARGI', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF334E68))),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nikCtrl, 
                      decoration: const InputDecoration(labelText: 'Masukkan NIK Anda', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passCtrl, 
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        // ✓ ADDED: Password visibility toggle icon
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF334E68),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _prosesLoginWarga,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF334E68), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('MASUK SEBAGAI WARGA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: const Text('Belum punya akun? Registrasi Akun Warga Di Sini', style: TextStyle(color: Color(0xFF334E68), fontSize: 12)),
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