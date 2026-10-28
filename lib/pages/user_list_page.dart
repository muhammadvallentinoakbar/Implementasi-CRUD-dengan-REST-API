import 'package:flutter/material.dart';

import 'package:crud_reqres/models/user_model.dart';
import 'package:crud_reqres/services/user_service.dart';
import 'package:crud_reqres/pages/user_form_page.dart';

/// Halaman utama yang menampilkan daftar semua user dari reqres.in.
class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final UserService _service = UserService();

  // Future yang digunakan FutureBuilder; di-reinit untuk refresh.
  late Future<List<UserModel>> _futureUsers;

  // Cache list lokal agar operasi CRUD langsung terlihat di UI.
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  /// Memuat ulang data user dari API.
  void _loadUsers() {
    setState(() {
      _futureUsers = _service.getUsers().then((list) {
        _users = List.from(list);
        return _users;
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Navigasi ke form
  // ---------------------------------------------------------------------------

  /// Membuka form create; setelah kembali perbarui list lokal.
  Future<void> _openCreateForm() async {
    final newUser = await Navigator.push<UserModel>(
      context,
      MaterialPageRoute(builder: (_) => const UserFormPage()),
    );
    if (!mounted) return;
    if (newUser != null) {
      setState(() => _users = [newUser, ..._users]);
    }
  }

  /// Membuka form edit; setelah kembali perbarui item di list lokal.
  Future<void> _openEditForm(UserModel user) async {
    final updated = await Navigator.push<UserModel>(
      context,
      MaterialPageRoute(builder: (_) => UserFormPage(user: user)),
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() {
        final idx = _users.indexWhere((u) => u.id == updated.id);
        if (idx != -1) _users[idx] = updated;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Hapus
  // ---------------------------------------------------------------------------

  /// Menampilkan dialog konfirmasi lalu menghapus user.
  Future<void> _confirmDelete(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus User'),
        content: Text(
          'Yakin ingin menghapus "${user.fullName}"?\nTindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteUser(user.id);
      if (!mounted) return;
      setState(() => _users.removeWhere((u) => u.id == user.id));
      _showSnackBar('"${user.fullName}" berhasil dihapus.', isError: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message, isError: true);
    }
  }

  // ---------------------------------------------------------------------------
  // SnackBar helper
  // ---------------------------------------------------------------------------

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar User'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            onPressed: _loadUsers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateForm,
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah User'),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _futureUsers,
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat data...'),
                ],
              ),
            );
          }

          // Error
          if (snapshot.hasError) {
            final msg = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : snapshot.error.toString();
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      msg,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _loadUsers,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Kosong
          if (_users.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada data user.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // Daftar user
          return RefreshIndicator(
            onRefresh: () async => _loadUsers(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _users.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = _users[index];
                return _UserTile(
                  user: user,
                  onEdit: () => _openEditForm(user),
                  onDelete: () => _confirmDelete(user),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget tile user
// ---------------------------------------------------------------------------

class _UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserTile({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _Avatar(user: user),
      title: Text(
        user.fullName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(user.email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            color: Colors.blue,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus',
            color: Colors.red,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget avatar dengan fallback inisial
// ---------------------------------------------------------------------------

class _Avatar extends StatelessWidget {
  final UserModel user;

  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(user.firstName, user.lastName);

    if (user.avatar.isEmpty) {
      return CircleAvatar(child: Text(initials));
    }

    return CircleAvatar(
      backgroundImage: NetworkImage(user.avatar),
      onBackgroundImageError: (_, _) {},
      child: user.avatar.isEmpty ? Text(initials) : null,
    );
  }

  String _initials(String first, String last) {
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final l = last.isNotEmpty ? last[0].toUpperCase() : '';
    return '$f$l';
  }
}
