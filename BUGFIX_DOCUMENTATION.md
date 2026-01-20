# Dokumentasi Perbaikan Bug - Geofence Presensi App

## Tanggal Perbaikan
Tanggal: $(date)

## Ringkasan Masalah

Aplikasi mengalami tiga masalah utama terkait alur autentikasi dan navigasi:

1. **App selalu dimulai dari verifikasi PIN** padahal seharusnya dari login
2. **Stuck setelah logout dan login** - harus close app dulu baru bisa login
3. **Bottom navigator menghilang** - widget bottom navigation tidak muncul

---

## Detail Masalah dan Solusi

### 1. ❌ Masalah: App Selalu Dimulai dari Verifikasi PIN

#### Penjelasan Masalah:
Saat app di-run atau di-refresh, aplikasi langsung menampilkan halaman **VerifyPinScreen** padahal seharusnya menampilkan **LoginScreen** terlebih dahulu.

#### Root Cause:
Di file `lib/providers/AuthProvider.dart`, method `checkLogin()` melakukan:
1. Query database mencari user dengan `isLogin = 1`
2. Jika ditemukan, state di-set: `_loggedIn = true`, `_hasPin = true`, `_pinVerified = false`
3. Kemudian baru reset `isLogin = 0` di database

Akibatnya, meskipun `isLogin` sudah di-reset di database, state di memory masih menunjukkan user sudah login, sehingga `AppGate` menampilkan **VerifyPinScreen**.

#### Solusi:
**File:** `lib/providers/AuthProvider.dart`

Method `checkLogin()` diubah untuk:
- **Selalu reset `isLogin` ke 0** di database terlebih dahulu
- **Selalu reset state** ke logged out
- **Tidak ada query** untuk mencari user yang sudah login

**Perubahan Kode:**
```dart
// SEBELUM:
final res = await db.query('users', where: 'isLogin = 1', limit: 1);
await db.update('users', {'isLogin': 0});
if (res.isNotEmpty) {
  // Set state ke logged in
}

// SESUDAH:
await db.update('users', {'isLogin': 0}); // Reset dulu
_resetState(); // Selalu reset state
```

**Dampak:**
- ✅ App selalu mulai dari **LoginScreen** saat restart/refresh
- ✅ User harus login ulang setiap kali app dibuka
- ✅ Tidak ada shortcut langsung ke PIN verification

---

### 2. ❌ Masalah: Stuck Setelah Logout dan Login

#### Penjelasan Masalah:
Setelah melakukan logout, ketika user mencoba login lagi (akun yang sama atau berbeda), aplikasi menjadi **stuck** dan tidak langsung pindah ke halaman verifikasi PIN. User harus menutup aplikasi terlebih dahulu baru bisa masuk ke halaman verifikasi PIN.

#### Root Cause:
Di file `lib/screens/ProfileScreen.dart`, saat logout dilakukan:
1. Method `logout()` dipanggil untuk reset state
2. **Manual navigation** dilakukan: `Navigator.pushAndRemoveUntil(..., LoginScreen())`

Konflik terjadi karena:
- `AppGate` sudah mengelola navigasi berdasarkan state `AuthProvider`
- Manual navigation menambahkan route baru ke navigation stack
- Ketika state berubah, `AppGate` mencoba mengubah widget, tapi navigation stack sudah berbeda
- Akibatnya terjadi stuck/konflik navigasi

#### Solusi:
**File:** `lib/screens/ProfileScreen.dart`

Hapus manual navigation dan biarkan `AppGate` yang mengelola navigasi secara otomatis.

**Perubahan Kode:**
```dart
// SEBELUM:
onPressed: () async {
  await context.read<AuthProvider>().logout();
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (_) => false,
  );
}

// SESUDAH:
onPressed: () async {
  Navigator.pop(context); // Tutup dialog
  await context.read<AuthProvider>().logout();
  // Tidak ada manual navigation
  // AppGate akan otomatis mendeteksi perubahan state dan menampilkan LoginScreen
}
```

**Dampak:**
- ✅ Logout berjalan mulus tanpa stuck
- ✅ Navigasi ke LoginScreen otomatis dilakukan oleh `AppGate`
- ✅ Tidak ada konflik navigasi
- ✅ Login ulang langsung berfungsi tanpa perlu close app

---

### 3. ❌ Masalah: Bottom Navigator Menghilang

#### Penjelasan Masalah:
Widget bottom navigation yang sudah dibuat tidak muncul di layar aplikasi.

#### Root Cause:
Di file `lib/app_gate.dart`, saat user sudah login dan terverifikasi, `AppGate` menampilkan:
```dart
return const HomeScreen();
```

Padahal di aplikasi ada `MainNavigationScreen` yang memiliki:
- `PageView` dengan 3 halaman: History, Home, Profile
- `CustomBottomNav` widget untuk bottom navigation

Karena `AppGate` langsung menampilkan `HomeScreen` (yang tidak memiliki bottom nav), maka bottom navigation tidak muncul.

#### Solusi:
**File:** `lib/app_gate.dart`

Ganti `HomeScreen()` dengan `MainNavigationScreen()` saat semua validasi selesai.

**Perubahan Kode:**
```dart
// SEBELUM:
import 'package:geofence_presensi/screens/HomeScreen.dart';

// ...
else {
  return const HomeScreen();
}

// SESUDAH:
import 'package:geofence_presensi/screens/MainNavigatorScreen.dart';

// ...
else {
  return const MainNavigationScreen();
}
```

**Dampak:**
- ✅ Bottom navigation muncul di layar
- ✅ User bisa navigasi antara History, Home, dan Profile
- ✅ Swipe gesture bekerja untuk berpindah halaman
- ✅ `HomeScreen` tetap digunakan sebagai salah satu tab di `MainNavigationScreen`

---

## File yang Diubah

1. **lib/providers/AuthProvider.dart**
   - Method `checkLogin()` di-refactor untuk selalu reset state

2. **lib/screens/ProfileScreen.dart**
   - Method `_showLogoutDialog()` diubah untuk menghapus manual navigation

3. **lib/app_gate.dart**
   - Import `MainNavigationScreen` menggantikan `HomeScreen`
   - Return `MainNavigationScreen` saat user terverifikasi

---

## Cara Testing

### Test Case 1: App Start dari Login
1. Close aplikasi sepenuhnya
2. Buka aplikasi kembali
3. **Expected:** Menampilkan **LoginScreen**, bukan VerifyPinScreen
4. ✅ **Hasil:** App mulai dari LoginScreen

### Test Case 2: Logout dan Login Ulang
1. Login dengan akun (apapun)
2. Setelah masuk, lakukan logout
3. Login kembali dengan akun yang sama atau berbeda
4. **Expected:** Tidak stuck, langsung bisa login dan masuk ke PIN verification
5. ✅ **Hasil:** Logout dan login berjalan mulus tanpa stuck

### Test Case 3: Bottom Navigation Muncul
1. Login dan verifikasi PIN hingga masuk ke home
2. **Expected:** Ada bottom navigation bar dengan 3 tab: History, Home, Profile
3. Test navigasi dengan tap icon atau swipe
4. ✅ **Hasil:** Bottom navigation muncul dan berfungsi

---

## Arsitektur Navigasi

### Flow Autentikasi:
```
App Start
  ↓
SplashScreen (jika belum initialized)
  ↓
LoginScreen (jika belum login)
  ↓
CreatePinScreen (jika login tapi belum ada PIN)
  ↓
VerifyPinScreen (jika login dan ada PIN tapi belum verifikasi)
  ↓
MainNavigationScreen (jika semua valid)
  ├── HistoryScreen
  ├── HomeScreen
  └── ProfileScreen
```

### State Management:
- `AuthProvider` mengelola state autentikasi
- `AppGate` membaca state `AuthProvider` dan menampilkan screen yang sesuai
- **Tidak ada manual navigation** yang konflik dengan `AppGate`
- Semua navigasi otomatis berdasarkan state

---

## Best Practices yang Diterapkan

1. **Single Source of Truth**
   - `AuthProvider` adalah satu-satunya sumber kebenaran untuk state autentikasi
   - `AppGate` hanya membaca state, tidak mengubah state

2. **Reactive Navigation**
   - Navigasi berdasarkan state, bukan manual navigation
   - Menggunakan `context.watch<AuthProvider>()` untuk reactive updates

3. **Clean Architecture**
   - Screen hanya fokus pada UI
   - Provider mengelola business logic
   - AppGate mengelola routing berdasarkan state

---

## Catatan Tambahan

### Mengapa App Selalu Mulai dari Login?

Perubahan ini sengaja dilakukan untuk keamanan. Setiap kali app dibuka, user harus:
1. Login dengan email dan password
2. Verifikasi PIN (jika sudah ada)

Ini mencegah akses langsung ke aplikasi meskipun `isLogin` masih `1` di database.

### Alternatif (Jika Diperlukan)

Jika diinginkan untuk mempertahankan session login (tidak perlu login ulang), bisa menggunakan SharedPreferences atau secure storage untuk menyimpan session token yang expire setelah waktu tertentu, bukan hanya mengandalkan `isLogin` di database.

---

## Kesimpulan

Ketiga masalah telah diperbaiki dengan:
- ✅ Refactor `checkLogin()` untuk konsistensi state
- ✅ Menghapus manual navigation yang konflik
- ✅ Menggunakan `MainNavigationScreen` untuk menampilkan bottom nav

Aplikasi sekarang memiliki alur autentikasi yang konsisten dan navigasi yang mulus.
