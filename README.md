# Tugas Praktikum Mobile Programming
## Implementasi CRUD dengan REST API (reqres.in)

| Informasi | Detail |
|-----------|--------|
| **Nama** | Muhammad Vallentino Akbar |
| **NIM** | *(isi NIM Anda)* |
| **Mata Kuliah** | Mobile Programming |
| **Topik** | Implementasi CRUD dengan REST API |

---

## Deskripsi

Aplikasi Flutter yang mengimplementasikan operasi **Create, Read, Update, Delete (CRUD)** terhadap data pengguna menggunakan API publik [reqres.in](https://reqres.in). Aplikasi dibangun dengan pendekatan clean architecture sederhana: model, service, dan halaman terpisah.

---

## Fitur

| Operasi | Method HTTP | Endpoint | Keterangan |
|---------|-------------|----------|------------|
| Read | GET | `/api/users?page=1` | Menampilkan daftar user |
| Create | POST | `/api/users` | Menambah user baru |
| Update | PUT | `/api/users/{id}` | Mengubah data user |
| Delete | DELETE | `/api/users/{id}` | Menghapus user |

---

## Struktur Kode

```
lib/
├── main.dart                  # Entry point, MaterialApp (Material 3, indigo)
├── models/
│   └── user_model.dart        # Class UserModel, fromJson null-safe, getter fullName
├── services/
│   └── user_service.dart      # UserService: 4 fungsi CRUD + ApiException + helper _send
└── pages/
    ├── user_list_page.dart    # Halaman daftar user (FutureBuilder, manajemen state lokal)
    └── user_form_page.dart    # Form create/edit (validasi, loading state, error display)
```

---

## Error Handling

| Kondisi | Pesan ke Pengguna |
|---------|-------------------|
| Tidak ada internet (`SocketException` / `ClientException`) | "Tidak ada koneksi internet. Periksa jaringan Anda dan coba lagi." |
| Timeout (> 10 detik) | "Koneksi timeout, coba lagi." |
| Response tidak dapat di-parse | "Format response tidak valid." |
| Status code di luar yang diterima | "Server error (status code: xxx)" |

---

## Cara Menjalankan

### Prasyarat
- Flutter SDK ≥ 3.13.5
- Android emulator / device fisik (minimal Android 5.0)
- Koneksi internet

### Langkah
```bash
# 1. Clone / masuk ke direktori project
cd crud_reqres

# 2. Install dependensi
flutter pub get

# 3. Jalankan di emulator / device
flutter run
```

---

## Catatan

### API Key reqres.in
Sejak pertengahan 2024, **reqres.in** memerlukan API key gratis. Key diletakkan sebagai konstanta di `lib/services/user_service.dart`:
```dart
static const String _apiKey = 'reqres-free-v1';
```
Jika key berubah atau Anda mendapatkan key sendiri, cukup ubah nilai konstanta tersebut.

### Sifat Mock API
reqres.in adalah **mock API** — semua operasi POST/PUT/DELETE mengembalikan respons sukses tetapi data **tidak benar-benar tersimpan** di server. Oleh karena itu, setelah create/update/delete, perubahan hanya terlihat secara lokal (list di-update di memori, bukan dari server). Ini adalah perilaku yang diharapkan dan bukan bug.

---

## Screenshot

| Halaman | Screenshot |
|---------|-----------|
| Daftar User | ![List](screenshots/list.png) |
| Form Tambah/Edit | ![Form](screenshots/form.png) |
| Sukses Operasi | ![Success](screenshots/success.png) |
| Kondisi Error | ![Error](screenshots/error.png) |

> **Catatan:** Ambil screenshot sendiri setelah menjalankan aplikasi dan simpan di folder `screenshots/`.

---

## Dependensi

| Package | Versi | Kegunaan |
|---------|-------|---------|
| `http` | ^1.2.0 | HTTP client untuk request ke reqres.in |
| `flutter` | SDK | Framework utama |
| `cupertino_icons` | ^1.0.8 | Ikon tambahan |
