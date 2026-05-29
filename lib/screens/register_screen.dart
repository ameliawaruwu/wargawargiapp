import 'package:flutter/material.dart';
import 'login_screen.dart'; 
import '../data/database_helper.dart';
import '../theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nikCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;

  Future<void> _eksekusiPendaftaranWarga() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    try {
      await DatabaseHelper.instance.insertUser({
        'nik': _nikCtrl.text.trim(),
        'nama': _namaCtrl.text.trim(),
        'password': _passCtrl.text,
        'role': 'Warga Mandiri',
        'warga_phone': _phoneCtrl.text.trim(),
        'warga_alamat': _alamatCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Registrasi berhasil! Silakan login.'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = '❌ Terjadi kesalahan sistem.';
        String errorString = e.toString().toLowerCase();
        
        // Pengecekan pintar tipe eror asli SQLite
        if (errorString.contains('unique') || errorString.contains('constraint')) {
          errorMessage = '❌ Gagal! NIK sudah terdaftar.';
        } else if (errorString.contains('no column')) {
          errorMessage = '❌ Kolom tabel belum sinkron! SIlakan UNINSTALL lalu RUN ULANG aplikasimu.';
        } else {
          errorMessage = '❌ Gagal: $e';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _nikCtrl.dispose();
    _namaCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _phoneCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
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
                    'Buat akun warga dan akses layanan RT dengan mudah',
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
                              maxLength: 16, // Mengunci input keyboard hanya sampai 16 karakter
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.badge, color: AppColors.primary),
                                labelText: 'NIK',
                                hintText: 'Masukkan NIK Anda',
                                counterText: "", // Menghilangkan teks "0/16" agar rapi
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
                              controller: _namaCtrl,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                                labelText: 'Nama Lengkap',
                                hintText: 'Nama sesuai KTP',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Nama wajib diisi!' : null,
                            ),
                            const SizedBox(height: 14),
                            
                            TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.phone_android, color: AppColors.primary),
                                labelText: 'Nomor WhatsApp',
                                hintText: 'Contoh: 0812xxxxxxxx',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Nomor WhatsApp wajib diisi!' : null,
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _alamatCtrl,
                              maxLines: 2,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                                labelText: 'Alamat Rumah Tinggal (Wajib RT/RW)',
                                hintText: 'Contoh: Jl. Merdeka No. 12, RT 03/RW 04',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Alamat lengkap wajib diisi!';
                                if (!val.toLowerCase().contains('rt') || !val.toLowerCase().contains('rw')) {
                                  return 'Mohon sertakan info RT dan RW secara spesifik!';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscurePass,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
                                labelText: 'Password',
                                hintText: 'Buat password baru',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Password wajib diisi!';
                                if (val.length < 4) return 'Password minimal 4 karakter!';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmPassCtrl,
                              obscureText: _obscureConfirmPass,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                                labelText: 'Konfirmasi Password',
                                hintText: 'Ulangi password',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirmPass ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                                  onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Konfirmasi password wajib diisi!';
                                if (val != _passCtrl.text) return 'Password tidak cocok!';
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _eksekusiPendaftaranWarga,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Sign Up', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 18),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                              child: const Text('Sudah punya akun? Masuk', style: TextStyle(color: AppColors.primary, fontSize: 14)),
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