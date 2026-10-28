import 'package:flutter/material.dart';

import 'package:crud_reqres/models/user_model.dart';
import 'package:crud_reqres/services/user_service.dart';

/// Halaman form untuk membuat (create) atau mengubah (update) data user.
///
/// Jika [user] null → mode CREATE (POST).
/// Jika [user] tidak null → mode EDIT (PUT).
class UserFormPage extends StatefulWidget {
  final UserModel? user;

  const UserFormPage({super.key, this.user});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  final UserService _service = UserService();

  // Controllers untuk setiap field teks.
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;

  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill saat mode edit.
    _firstNameCtrl = TextEditingController(text: widget.user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: widget.user?.lastName ?? '');
    _emailCtrl = TextEditingController(text: widget.user?.email ?? '');
  }

  @override
  void dispose() {
    // Selalu dispose controller untuk mencegah memory leak.
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    // Sembunyikan pesan error lama.
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    try {
      UserModel result;

      if (_isEdit) {
        // Mode UPDATE (PUT)
        result = await _service.updateUser(
          widget.user!.id,
          firstName,
          lastName,
          email,
          widget.user!.avatar,
        );
      } else {
        // Mode CREATE (POST)
        result = await _service.createUser(firstName, lastName, email);
      }

      if (!mounted) return;

      // Kembali ke list dengan membawa data user baru/terupdate.
      Navigator.pop(context, result);

      // SnackBar konfirmasi ditampilkan oleh halaman pemanggil setelah push
      // selesai, namun reqres.in tidak menyimpan data asli sehingga kita tampilkan
      // SnackBar di sini via ScaffoldMessenger root.
      final action = _isEdit ? 'diperbarui' : 'dibuat';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User "$firstName $lastName" berhasil $action'
            '${_isEdit ? '' : ' (ID: ${result.id})'}.',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Validasi
  // ---------------------------------------------------------------------------

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong.';
    }
    final regex = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Format email tidak valid.';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Edit User' : 'Tambah User';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pesan error global
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Field First Name
              TextFormField(
                controller: _firstNameCtrl,
                enabled: !_isLoading,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  hintText: 'Contoh: Budi',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _validateRequired(v, 'First Name'),
              ),
              const SizedBox(height: 16),

              // Field Last Name
              TextFormField(
                controller: _lastNameCtrl,
                enabled: !_isLoading,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  hintText: 'Contoh: Santoso',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _validateRequired(v, 'Last Name'),
              ),
              const SizedBox(height: 16),

              // Field Email
              TextFormField(
                controller: _emailCtrl,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Contoh: budi@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _validateEmail,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 32),

              // Tombol submit
              FilledButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_isEdit ? Icons.save : Icons.add),
                label: Text(
                  _isLoading
                      ? 'Menyimpan...'
                      : (_isEdit ? 'Simpan Perubahan' : 'Tambah User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
