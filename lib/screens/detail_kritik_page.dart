import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/database_helper.dart';
import '../theme/app_colors.dart';
import 'kritik_page.dart';

class DetailKritikPage extends StatefulWidget {
  final Map<String, dynamic> kritik;

  const DetailKritikPage({super.key, required this.kritik});

  @override
  State<DetailKritikPage> createState() => _DetailKritikPageState();
}

class _DetailKritikPageState extends State<DetailKritikPage> {
  late TextEditingController _judulCtrl;
  late TextEditingController _isiCtrl;
  String? _base64BuktiKeluhan;
  bool _isEditMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _judulCtrl = TextEditingController(text: widget.kritik['judul_keluhan']);
    _isiCtrl = TextEditingController(text: widget.kritik['isi_critic']);
    _base64BuktiKeluhan = widget.kritik['bukti_keluhan'];
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _isiCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihFotoKerusakan() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 30);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _base64BuktiKeluhan = base64Encode(bytes);
      });
    }
  }

  Future<void> _simpanPerubahan() async {
    if (_judulCtrl.text.isEmpty ||
        _isiCtrl.text.isEmpty ||
        _base64BuktiKeluhan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Lengkapi semua field!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await DatabaseHelper.instance.updateData(
        'kritik',
        {
          'judul_keluhan': _judulCtrl.text,
          'isi_critic': _isiCtrl.text,
          'bukti_keluhan': _base64BuktiKeluhan!,
        },
        widget.kritik['id'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Perubahan berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditMode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Gagal menyimpan perubahan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _hapusKritik() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Laporan?'),
        content: const Text('Yakin ingin menghapus laporan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteData('kritik', widget.kritik['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Laporan berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const KritikPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Laporan Aduan'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
            },
            icon: Icon(_isEditMode ? Icons.close : Icons.edit),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Pelapor',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    Text(widget.kritik['nama_pelapor'],
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    const Text('Waktu Lapor',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textSecondary)),
                                    const SizedBox(height: 2),
                                    Text(widget.kritik['tanggal_lapor'],
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.secondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isEditMode ? 'Edit Laporan' : 'Detail Laporan',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          if (_isEditMode)
                            TextField(
                              controller: _judulCtrl,
                              decoration: InputDecoration(
                                labelText: 'Judul Keluhan',
                                prefixIcon: const Icon(Icons.edit_note),
                                prefixIconColor: AppColors.primary,
                                border: const OutlineInputBorder(),
                              ),
                            )
                          else
                            Text(
                              _judulCtrl.text,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          const SizedBox(height: 16),
                          if (_isEditMode)
                            TextField(
                              controller: _isiCtrl,
                              maxLines: 5,
                              decoration: InputDecoration(
                                labelText: 'Deskripsi Detail',
                                alignLabelWithHint: true,
                                prefixIcon: const Icon(Icons.description),
                                prefixIconColor: AppColors.primary,
                                border: const OutlineInputBorder(),
                              ),
                            )
                          else
                            Text(
                              _isiCtrl.text,
                              style: const TextStyle(fontSize: 14),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Foto Bukti Lapangan',
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.bold)),
                              if (_isEditMode)
                                TextButton.icon(
                                  onPressed: _pilihFotoKerusakan,
                                  icon: const Icon(Icons.add_a_photo, color: AppColors.primary),
                                  label: const Text('Ganti Foto', style: TextStyle(color: AppColors.primary)),
                                )
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_base64BuktiKeluhan != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(
                                base64Decode(_base64BuktiKeluhan!),
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.secondary.withOpacity(0.4)),
                              ),
                              child: const Center(
                                child: Text('Tidak ada foto', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isEditMode) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _simpanPerubahan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('SIMPAN PERUBAHAN',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _hapusKritik,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('HAPUS LAPORAN',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
