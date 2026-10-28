import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:crud_reqres/models/user_model.dart';

/// Exception kustom yang dilempar oleh [UserService] agar UI bisa
/// menampilkan pesan yang ramah pengguna.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

/// Service untuk seluruh operasi CRUD ke reqres.in.
class UserService {
  // ---------------------------------------------------------------------------
  // Konstanta
  // ---------------------------------------------------------------------------

  static const String _baseUrl = 'https://reqres.in/api';
  static const String _apiKey = 'reqres-free-v1';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'x-api-key': _apiKey,
  };

  static const Duration _timeout = Duration(seconds: 10);

  // ---------------------------------------------------------------------------
  // Helper privat
  // ---------------------------------------------------------------------------

  /// Mengirim request HTTP dan menangani semua error umum.
  ///
  /// [requester] adalah fungsi yang mengembalikan `Future<http.Response>`.
  /// [acceptedStatuses] adalah daftar kode status yang dianggap sukses.
  Future<http.Response> _send(
    Future<http.Response> Function() requester,
    List<int> acceptedStatuses,
  ) async {
    try {
      final response = await requester().timeout(_timeout);
      if (!acceptedStatuses.contains(response.statusCode)) {
        throw ApiException(
          'Server error (status code: ${response.statusCode})',
        );
      }
      return response;
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(
        'Tidak ada koneksi internet. Periksa jaringan Anda dan coba lagi.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Tidak ada koneksi internet. Periksa jaringan Anda dan coba lagi.',
      );
    } on TimeoutException {
      throw const ApiException('Koneksi timeout, coba lagi.');
    } on FormatException {
      throw const ApiException('Format response tidak valid.');
    }
  }

  // ---------------------------------------------------------------------------
  // GET /users?page={page}
  // ---------------------------------------------------------------------------

  /// Mengambil daftar user dari API (GET /users).
  ///
  /// Mengembalikan [List<UserModel>] untuk halaman [page].
  Future<List<UserModel>> getUsers({int page = 1}) async {
    final uri = Uri.parse('$_baseUrl/users?page=$page');

    final response = await _send(() => http.get(uri, headers: _headers), [200]);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // POST /users
  // ---------------------------------------------------------------------------

  /// Membuat user baru melalui API (POST /users).
  ///
  /// Mengembalikan [UserModel] dengan id dari response dan data yang dikirim.
  Future<UserModel> createUser(
    String firstName,
    String lastName,
    String email,
  ) async {
    final uri = Uri.parse('$_baseUrl/users');
    final body = jsonEncode({
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
    });

    final response = await _send(
      () => http.post(uri, headers: _headers, body: body),
      [200, 201],
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // reqres.in mengembalikan id (String), gabungkan dengan input.
    final id = int.tryParse(json['id']?.toString() ?? '0') ?? 0;
    return UserModel(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      avatar: '',
    );
  }

  // ---------------------------------------------------------------------------
  // PUT /users/{id}
  // ---------------------------------------------------------------------------

  /// Memperbarui data user melalui API (PUT /users/{id}).
  ///
  /// Mengembalikan [UserModel] yang mencerminkan data yang dikirim.
  Future<UserModel> updateUser(
    int id,
    String firstName,
    String lastName,
    String email,
    String avatar,
  ) async {
    final uri = Uri.parse('$_baseUrl/users/$id');
    final body = jsonEncode({
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
    });

    await _send(() => http.put(uri, headers: _headers, body: body), [200, 201]);

    return UserModel(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      avatar: avatar,
    );
  }

  // ---------------------------------------------------------------------------
  // DELETE /users/{id}
  // ---------------------------------------------------------------------------

  /// Menghapus user melalui API (DELETE /users/{id}).
  Future<void> deleteUser(int id) async {
    final uri = Uri.parse('$_baseUrl/users/$id');

    await _send(() => http.delete(uri, headers: _headers), [200, 201, 204]);
  }
}
