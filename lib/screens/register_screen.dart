import 'package:flutter/material.dart';
import '../data/database_helper.dart';

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
  
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;

  Future<void> _eksekusiPendaftaranWarga() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    try {
      // BAGIAN ROLE OTOMATIS DISET KE 'Warga Mandiri' DI SINI
      await DatabaseHelper.instance.insertUser({
        'nik': _nikCtrl.text,
        'nama': _namaCtrl.text,
        'password': _passCtrl.text,
        'role': 'Warga Mandiri', 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Registrasi Berhasil! Silakan Login.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Gagal! NIK sudah terdaftar.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.app_registration_rounded, size: 50, color: Color(0xFF6366F1)),
                      const SizedBox(height: 12),
                      const Text('REGISTRASI WARGA BARU', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B365D))),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _nikCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Masukkan NIK Anda', border: OutlineInputBorder()),
                        validator: (val) => val == null || val.isEmpty ? 'NIK wajib diisi!' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _namaCtrl,
                        decoration: const InputDecoration(labelText: 'Nama Lengkap (Sesuai KTP)', border: OutlineInputBorder()),
                        validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi!' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        decoration: InputDecoration(
                          labelText: 'Buat Password Baru',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        validator: (val) => val == null || val.length < 4 ? 'Password minimal 4 karakter!' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmPassCtrl,
                        obscureText: _obscureConfirmPass,
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPass ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Konfirmasi password wajib diisi!';
                          if (val != _passCtrl.text) return 'Password tidak cocok!';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _eksekusiPendaftaranWarga,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('DAFTARKAN AKUN WARGA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Sudah punya akun? Kembali ke Gerbang Login', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12)),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}