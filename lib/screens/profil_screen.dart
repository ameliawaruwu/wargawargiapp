import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscurePass = true;
  String _nik = '';
  String _role = 'Warga Mandiri';
  String _phoneWarga = '-';   // Tampungan data No. HP
  String _alamatWarga = '-';  // Tampungan data Alamat
  String _currentPassword = '';
  String _statusMessage = '';
  String? _fotoProfilBase64;
  Uint8List? _fotoProfilBytes;
  bool _isPengurusRT = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final sp = await SharedPreferences.getInstance();
    final storedNik = sp.getString('nik') ?? '';
    if (storedNik.isEmpty) {
      setState(() {
        _statusMessage = 'Tidak ada user aktif. Silakan login ulang.';
        _isLoading = false;
      });
      return;
    }

    final user = await DatabaseHelper.instance.getUserByNik(storedNik);
    if (user == null) {
      setState(() {
        _statusMessage = 'Data pengguna tidak ditemukan.';
        _isLoading = false;
      });
      return;
    }

    final storedPhoto = sp.getString('foto_profil_$storedNik');
    setState(() {
      _nik = user['nik'] ?? '';
      _role = user['role'] ?? 'Warga Mandiri';
      _isPengurusRT = _role == 'Pengurus RT';
      _namaCtrl.text = user['nama'] ?? '';
      _currentPassword = user['password'] ?? '';
      
      // TARIK DATA NO HP DAN ALAMAT DARI DATABASE
      _phoneWarga = user['warga_phone'] ?? '-';
      _alamatWarga = user['warga_alamat'] ?? '-';
      
      _fotoProfilBase64 = storedPhoto;
      _fotoProfilBytes = storedPhoto != null ? base64Decode(storedPhoto) : null;
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final updatedPassword = _passCtrl.text.isEmpty ? _currentPassword : _passCtrl.text;
    final updateRow = {
      'nama': _namaCtrl.text.trim(),
      'password': updatedPassword,
    };

    final result = await DatabaseHelper.instance.updateUserByNik(_nik, updateRow);
    if (result > 0) {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('nama_warga', _namaCtrl.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui.'), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan profil. Coba lagi.'), backgroundColor: Colors.redAccent),
        );
      }
    }

    setState(() {
      _isSaving = false;
      _passCtrl.clear();
    });
  }

  Future<void> _pilihFotoProfil() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final encoded = base64Encode(bytes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('foto_profil_$_nik', encoded);

    setState(() {
      _fotoProfilBase64 = encoded;
      _fotoProfilBytes = bytes;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil dipilih.'), backgroundColor: AppColors.primary),
      );
    }
  }

  Future<void> _logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('is_logged_in');
    
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Profil Saya'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _pilihFotoProfil,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 38,
                                backgroundColor: Colors.white.withOpacity(0.18),
                                backgroundImage: _fotoProfilBytes != null ? MemoryImage(_fotoProfilBytes!) : null,
                                child: _fotoProfilBytes == null ? const Icon(Icons.person, color: Colors.white, size: 40) : null,
                              ),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt, size: 16, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Halo, ${_namaCtrl.text.isEmpty ? 'Warga' : _namaCtrl.text}',
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(_role, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(height: 12),
                              const Text('Ubah data akun Anda di sini untuk menjaga profil tetap up-to-date.',
                                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 36,
                                child: TextButton.icon(
                                  onPressed: _pilihFotoProfil,
                                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                  label: const Text('Ubah Foto Profil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_statusMessage.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Text(_statusMessage, style: const TextStyle(color: Color(0xFF991B1B))),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(22.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Data Akun', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildReadOnlyField(label: 'NIK', value: _nik),
                            const SizedBox(height: 16),
                            _buildEditableField(label: 'Nama Lengkap', controller: _namaCtrl, hint: 'Masukkan nama lengkap'),
                            const SizedBox(height: 16),
                            
                            // TAMPILKAN INFO NOMOR HP (READ-ONLY)
                            _buildReadOnlyField(label: 'Nomor WhatsApp', value: _phoneWarga),
                            const SizedBox(height: 16),
                            
                            // TAMPILKAN INFO ALAMAT (READ-ONLY)
                            _buildReadOnlyField(label: 'Alamat Domisili', value: _alamatWarga),
                            const SizedBox(height: 16),
                            
                            _buildReadOnlyField(label: 'Peran Akun', value: _role),
                            const SizedBox(height: 16),
                            _buildPasswordField(context),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _isSaving
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _logout,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text('Keluar (Logout)', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        ),
      ],
    );
  }

  Widget _buildEditableField({required String label, required TextEditingController controller, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary)),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Kolom tidak boleh kosong' : null,
        ),
      ],
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Password Baru', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscurePass,
          decoration: InputDecoration(
            hintText: 'Kosongkan jika tidak ingin mengganti password',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary)),
            suffixIcon: IconButton(
              icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
        ),
      ],
    );
  }
}