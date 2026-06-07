# FarmHub - Aplikasi Manajemen Bisnis Peternakan & Perikanan Terintegrasi

FarmHub adalah aplikasi manajemen bisnis peternakan dan perikanan modern berbasis **Flutter** yang dirancang untuk membantu peternak dan pembudidaya mengelola siklus ternak, memantau keuangan, melacak pemberian pakan, serta memonitor kondisi kandang/kolam secara cerdas dan terintegrasi.

Aplikasi ini hadir dengan tema gelap premium (Dark Theme), navigasi yang responsif, serta dilengkapi dengan fitur pencatatan luring (offline-first) dan integrasi sensor IoT (Internet of Things).

---

## ✨ Fitur Utama

### 📋 1. Manajemen Siklus Ternak & Perikanan (Batches)
* **Pencatatan Siklus:** Kelola siklus budidaya/ternak dari awal mulai hingga masa panen. Catat populasi awal, kategori hewan, dan modal awal investasi.
* **Riwayat Catatan Harian:** Tab khusus untuk melihat gabungan riwayat harian dari seluruh siklus. Anda dapat memantau pemberian pakan, tingkat kematian (mortality), estimasi berat, melakukan penyaringan filter per siklus, dan menghapus log yang salah dengan mudah.
* **Pencatatan Panen:** Catat penjualan panen secara borongan maupun per ekor/kilogram yang terintegrasi langsung dengan laporan kas masuk keuangan.

### 📋 2. Asisten Aktivitas Harian (Configurable Activity Assistant)
* **Jadwal Kustom:** Atur sendiri berapa kali hewan ternak diberi makan dalam sehari (1 hingga 4 kali sehari).
* **Waktu Makan Presisi:** Atur jam dan menit pemberian pakan secara kustom menggunakan Time Picker bawaan yang bersih dan responsif.
* **Push Notification (Pengingat Otomatis):** Sistem dilengkapi dengan **Notifikasi Alarm Lokal** yang akan memunculkan *pop-up* peringatan di jam yang sudah Anda atur. Tidak perlu takut lupa memberi makan ternak!
* **Checklist Interaktif:** Ketuk langsung aktivitas hari ini di dashboard untuk memberikan centang hijau secara manual. Status penyelesaian disimpan secara lokal (`SharedPreferences`) dan akan otomatis direset menjadi kosong ketika hari berganti.

### 💰 3. Pencatatan Keuangan (Cashflow) & Laporan Profit
* **Arus Kas Terperinci:** Catat pemasukan (penjualan ternak, telur, susu, dll.) dan pengeluaran (pembelian pakan, bibit, vitamin, gaji karyawan, listrik, air, dll.) lengkap dengan kategori yang relevan.
* **Dashboard Profit Bersih:** Pantau saldo kas saat ini, total kas masuk bulan ini, serta keuntungan/profit bersih secara real-time langsung dari beranda.

### 🪙 4. Pemformatan Rupiah Dinamis (Bebas Pecahan Desimal)
* **Input Ribuan Otomatis:** Saat mengetik modal awal, nominal kas, atau harga pakan, angka secara otomatis akan diformat menggunakan pemisah ribuan titik (contoh: `300.000` bukan `300000` atau `300000.0`).
* **Pencegahan Error Desimal:** Semua formulir menampilkan input data berupa bilangan bulat bersih sehingga memudahkan kalkulasi keuangan bagi peternak tanpa adanya trailing desimal `.0`.

### 🌾 5. Manajemen Pakan & Gudang Stok Terintegrasi (Real-time Sync)
* **Stok Pakan Dinamis:** Lacak jumlah stok pakan Anda layaknya gudang virtual. Saat Anda mencatat pengeluaran di **Cashflow** untuk pembelian pakan, stok pakan akan otomatis bertambah.
* **Otomatisasi Real-time:** Sistem pemantauan 2 arah yang cerdas. Jika Anda menghapus catatan pakan di Cashflow, stok akan dikurangi (*revert*). Jika Anda menghapus catatan pemberian makan, stok akan kembali bertambah secara otomatis ke dalam gudang.
* **Riwayat Mutasi Stok:** Periksa riwayat lalu-lintas keluar masuk stok pakan (pembelian dan penggunaan) layaknya mutasi rekening tabungan.
* **Konversi Satuan:** Input pakan harian bisa menggunakan satuan Gram (g), Ons (ons), atau Kilogram (kg).
* **Kesehatan Hewan:** Pantau dan catat pemberian vaksin, obat-obatan, serta vitamin mingguan/bulanan agar kondisi kesehatan ternak tetap terjaga.

### 🔌 6. Integrasi Sensor IoT (Adaptive IoT Monitoring)
* **Kategori Adaptif:** Tampilan dashboard IoT menyesuaikan dengan kategori usaha aktif:
  * **Perikanan (Ikan/Udang):** Memantau parameter kualitas air seperti **pH air**, **suhu air**, **Dissolved Oxygen (DO)**, dan **TDS Air (ppm)**.
  * **Peternakan (Sapi/Ayam/Kambing):** Memantau parameter kondisi kandang seperti **suhu kandang**, **kelembaban udara**, dan **sisa kapasitas pakan (kg)**.

---

## 🛠️ Arsitektur & Teknologi

Aplikasi ini dibangun menggunakan praktik pengembangan modern untuk memastikan kinerja tinggi, keandalan luring, dan kemudahan skalabilitas:
* **Framework Utama:** [Flutter](https://flutter.dev) (Dart SDK `>=3.3.0 <4.0.0`)
* **State Management:** [Riverpod](https://riverpod.dev) (`flutter_riverpod ^2.5.1`) - Mengelola state aplikasi secara reaktif, asinkron, dan modular.
* **Local Database:** [Sqflite](https://pub.dev/packages/sqflite) & [Path](https://pub.dev/packages/path) - Penyimpanan database lokal relasional (SQLite) agar aplikasi tetap dapat bekerja 100% secara offline.
* **Local Storage Cache:** [SharedPreferences](https://pub.dev/packages/shared_preferences) - Digunakan untuk menyimpan pengaturan kustom jadwal asisten aktivitas dan status centang harian.
* **Routing:** [GoRouter](https://pub.dev/packages/go_router) - Deklaratif routing yang aman untuk navigasi halaman.
* **Date & Formatting:** [Intl](https://pub.dev/packages/intl) - Penanganan pemformatan mata uang Rupiah (`id_ID`) dan penanggalan tanggal Indonesia secara otomatis.

---

## 🚀 Memulai Proyek

### Prasyarat
Sebelum memulai, pastikan perangkat Anda telah terpasang:
* Flutter SDK (Versi terbaru direkomendasikan, minimal `3.3.0`)
* Android Studio / VS Code dengan plugin Flutter/Dart
* Android Device / Emulator

### Cara Menjalankan Aplikasi
1. Clone repositori ini:
   ```bash
   git clone https://github.com/hantu060614/ManajemenBisnisApp.git
   ```
2. Masuk ke direktori proyek:
   ```bash
   cd ManajemenBisnisApp
   ```
3. Unduh dependensi Flutter:
   ```bash
   flutter pub get
   ```
4. Jalankan aplikasi dalam mode pengembangan:
   ```bash
   flutter run
   ```

### Membangun File APK Rilis (Production Ready)
Untuk membuat paket aplikasi Android yang siap diunduh dan dipasang di handphone:
```bash
flutter build apk --release
```
Hasil file APK yang siap dipasang dapat Anda temukan di direktori proyek:
`build/app/outputs/flutter-apk/app-release.apk`
