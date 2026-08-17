# Product Requirements Document (PRD)
## Meko Poin – Modul Keuangan (Transformasi Kas Tunai) & Penyesuaian Penghapusan Transaksi

**Versi:** 1.0 (Draft dari Catatan Klien 2026-08-16)
**Tanggal:** 2026-08-16
**Platform:** Flutter (Android, iOS, Desktop/Web)
**Status:** Draft – menunggu konfirmasi keputusan desain (lihat bagian "Keputusan yang Perlu Dikonfirmasi")

---

## Ringkasan Eksekutif

Catatan klien menuntut transformasi modul **"Kas Tunai"** menjadi **"Keuangan"** dengan dua variabel saldo terpisah:

- **Cash** (tunai) – dari transaksi tunai atau penambahan manual (seperti yang sudah ada sekarang).
- **Saldo** (QRIS/e-wallet) – dari transaksi QRIS atau penambahan manual.

Total saldo = **Cash + Saldo**. Modul ini juga menambah jenis transaksi **Transfer** antar cash/saldo, kategori keuangan, autocomplete keterangan, dan mengubah aturan penghapusan transaksi (rollback inventory + rollback keuangan, Admin Only).

Dokumen ini menerjemahkan catatan klien menjadi PRD yang dapat ditindaklanjuti, dengan mengacu pada implementasi saat ini.

---

## Tujuan

1. Mengganti modul "Kas Tunai" menjadi **"Keuangan"** dengan dua variabel terpisah: **Cash** dan **Saldo**.
2. Menambahkan tipe keuangan **Transfer** untuk memindahkan dana antara Cash dan Saldo.
3. Memastikan total keuangan (Total Saldo) = Cash + Saldo.
4. Menambahkan **Kategori Keuangan** (opsional) yang bisa ditambahkan dari combobox atau dari master CRUD.
5. Implementasi **autocomplete** pada kolom Keterangan dari data yang sudah ada di database.
6. Menyesuaikan aturan otorisasi: Admin dapat add/edit keuangan & transfer; Operator hanya dapat **transfer dari tunai ke saldo**, dengan Keterangan wajib diisi.
7. **Penghapusan transaksi (Admin Only)** harus melakukan rollback inventory **dan** rollback keuangan.
8. Menyesuaikan kasus ketika metode pembayaran diubah (cash ↔ qris).

---

## Catatan Klien (Referensi)

> **Notes 2026-08-16** — Total Saldo = kas tunai + QRIS
>
> 1. Delete transaction should rollback inventory and rollback keuangan (Admin Only)
> 2. Dashboard kas tunai change module name into "Keuangan". There are 2 different variable:
>    a. Cash (From transaction or add new like existing)
>    b. Saldo (From transaction or can add new)
>    Cases: I have money Rp50.000, Cash Rp10.000, balance in e-wallet BCA (Saldo) Rp40.000. From sales earn 100K which Rp20.000 Cash and Rp80.000 Qris. Total earn will became Rp150.000, Total Cash Rp30.000, and Total Saldo Rp120.000. User Admin can transfer amount from Cash to Saldo, or vice versa.
>    Admin can add/edit keuangan and transfer keuangan.
>    Operator can only transfer dari tunai ke saldo. Keterangan make mandatory field
> 3. When add/edit keuangan in Keterangan field implement autocomplete or suggestion from existing keterangan data from database.
> 4. Add tipe keuangan "Transfer" when user selected transfer then show "dari" field with combobox "Cash" or "Saldo", and show "Ke" field with combobox "Cash" or "Saldo" (if user select "dari" with "Cash" then "ke" field only has "Saldo", or vice versa).
> 5. Add field Kategori Keuangan (Optional)
> 6. Kategori Keuangan can added from combobox or from master CRUD Kategori Keuangan.
> 7. Adjust case when payment method changed from cash to qris or vice versa.

---

## Kondisi Saat Ini (Referensi Implementasi)

- **Tabel DB:** `Data_Kas` — kolom: `id, amount, description, type (income|outcome), cash_date, transaction_id, created_at, updated_at, deleted_at, created_by, updated_by, deleted_by`. **Belum** ada kolom `category`/`kategori`, `variable`/`saldo`, atau `from`/`to`.
- **Model:** `lib/models/kas.dart` (`Kas`)
- **Repository:** `lib/services/kas_repository.dart`
- **Form:** `lib/views/Dashboard/components/form/kas_form.dart`
  - Field saat ini: Jenis Transaksi (income/outcome; operator hanya 'outcome'), Tanggal, Nominal, Keterangan.
  - **Keterangan saat ini sudah wajib** (`Validators.validateRequired`).
- **Content/Page:** `lib/views/Dashboard/contents/kas_content.dart`
- **Sidebar menu:** `lib/views/Dashboard/components/sidebar.dart` → label **"Kas Tunai"** (baris 94 & 98), `dashboard_page.dart` → menu `'Kas Tunai'` (baris 278, 296, 360, 525-526).
- **Penghapusan transaksi:** `lib/services/transaction_repository.dart::deleteTransaction` — **sudah diimplementasikan** pada iterasi sebelumnya untuk rollback inventory + kas (soft-delete kas by `transaction_id` OR `description LIKE '%Invoice <no>%'`; rollback stok dari `Data_Inventory_Log` dengan fallback rekonstruksi dari item). Masih perlu **penyesuaian** untuk konsep dua variabel (Cash/Saldo) & pembatasan Admin Only.
- **Perubahan metode pembayaran:** `lib/services/transaction_repository.dart::updatePaymentMethodWithHistory` — **sudah ada** logika kas cenderung cash ↔ qris (buang kas saat cash→qris, buat kas saat qris→cash). Perlu penyesuaian ke variabel Cash/Saldo.
- **Migrasi DB:** `lib/services/database_helper.dart` — saat ini **versi 13**. Migrasi baru harus menaikkan ke **versi 14**.

---

## Ruang Lingkup Perubahan

---

### 1. Penghapusan Transaksi → Rollback Inventory + Rollback Keuangan (Admin Only)

**Lokasi:** `lib/services/transaction_repository.dart::deleteTransaction`, `lib/views/Dashboard/components/detail/transaction_detail.dart` (tombol Hapus).

#### 1.1 Aturan Otorisasi
- Tombol **Hapus** pada detail transaksi hanya boleh tampil untuk **Admin** (`roleId == 1`). Saat ini sudah dibatasi `_isAdmin` di `transaction_detail.dart` (baris 1235). **Pertahankan**.
- Operator **tidak** dapat menghapus transaksi.

#### 1.2 Rollback Inventory
- Sudah diimplementasikan: kembalikan stok berdasarkan `Data_Inventory_Log` (`transaction_id`, `type='decrement'`) atau rekonstruksi dari `Data_Transaction_Item`.
- **Pertahankan** perilaku ini; pastikan tetap berjalan setelah perubahan variabel keuangan.

#### 1.3 Rollback Keuangan (dengan dua variabel)
- Saat transaksi dihapus, **semua** entri keuangan yang terkait harus di-rollback (soft-delete):
  - Entri Cash (jika transaksi asli tunai).
  - Entri Saldo (jika transaksi asli QRIS).
- Pencocokan entri keuangan tetap memakai `transaction_id` **ATAU** `description LIKE '%Invoice <no>%'` (untuk data legacy).
- **Catatan desain:** karena saldo kini punya variabel Cash/Saldo, entri keuangan yang dihasilkan dari transaksi harus bisa dibedakan variabelnya (lihat Bagian 2).

---

### 2. Modul "Kas Tunai" → "Keuangan" dengan Dua Variabel (Cash & Saldo)

**Lokasi:** sidebar, dashboard page, `kas_content.dart`, `kas_form.dart`, `kas_repository.dart`, `Data_Kas` schema.

#### 2.1 Penamaan
- Ganti semua label **"Kas Tunai"** menjadi **"Keuangan"**:
  - `sidebar.dart` baris 94 & 98.
  - `dashboard_page.dart` baris 278, 296, 360, 525-526.
  - `kas_content.dart` baris 216, 221 dan label header terkait.
- Header subpage: "Detail Kas Bulanan" → **"Detail Keuangan Bulanan"** (dashboard_page.dart:304).

#### 2.2 Dua Variabel Saldo
Tambah kolom baru pada `Data_Kas` untuk membedakan variabel:

| Kolom | Tipe | Keterangan |
|---|---|---|
| `variable` | TEXT | Nilai: `'cash'` atau `'saldo'` (default `'cash'` untuk kompatibilitas data lama). |

- **Cash** (`variable='cash'`): berasal dari transaksi tunai atau penambahan manual.
- **Saldo** (`variable='saldo'`): berasal dari transaksi QRIS atau penambahan manual.

#### 2.3 Perhitungan Total
- **Total Keuangan (Total Saldo)** = **Total Cash + Total Saldo**.
- Kasus contoh klien: modal Rp50.000 (Cash 10.000 + Saldo 40.000) + penjualan 100K (Cash 20.000 + Saldo 80.000) → **Total Rp150.000, Cash Rp30.000, Saldo Rp120.000**.
- Repository perlu menambah method agregasi per variabel, mis. `getTotalCash()`, `getTotalSaldo()`, `getTotalKeuangan()`.

---

### 3. Otorisasi: Admin vs Operator

| Aksi | Admin (`roleId==1`) | Operator (`roleId==2`) |
|---|---|---|
| Tambah Keuangan (income/outcome) | ✅ | ❌ (kecuali diizinkan — perlu konfirmasi) |
| Edit Keuangan | ✅ | ❌ |
| Transfer Cash ↔ Saldo | ✅ (dua arah) | ✅ **hanya Cash → Saldo** |
| Hapus Transaksi | ✅ | ❌ |
| Keterangan pada Transfer | Wajib | **Wajib** |

- **Operator hanya dapat transfer dari tunai ke saldo** (`dari=Cash`, `ke=Saldo`). Field "dari"/"ke" untuk operator terkunci menjadi Cash→Saldo.
- **Keterangan selalu wajib** untuk semua jenis keuangan (saat ini sudah wajib untuk kas; pastikan tetap wajib untuk Transfer).

---

### 4. Form Keuangan: Tipe "Transfer" + Field dari/ke

**Lokasi:** `lib/views/Dashboard/components/form/kas_form.dart`.

#### 4.1 Jenis Transaksi (Tipe Keuangan)
Dropdown "Jenis Transaksi" sekarang berisi:
- **Pemasukan** (`income`)
- **Pengeluaran** (`outcome`)
- **Transfer** (`transfer`) — baru

#### 4.2 Saat Tipe = Transfer
Muncul dua field tambahan:
- **"Dari"** – combobox: `Cash` | `Saldo`.
- **"Ke"** – combobox: `Cash` | `Saldo`.
- Aturan dependensi: jika "Dari" = `Cash`, maka "Ke" **hanya** `Saldo` (dan sebaliknya). Tidak boleh "Dari" == "Ke".
- **Admin:** bisa Cash→Saldo atau Saldo→Cash.
- **Operator:** hanya Cash→Saldo (pilihan terkunci).
- Validasi: `dari != ke` wajib.

#### 4.3 Pemrosesan Transfer (dampak saldo)
Satu aksi Transfer harus menciptakan **dua baris** di `Data_Kas` (jurnal) agar total tetap konsisten:
- Baris **outcome** pada variabel asal (`dari`): `type='outcome'`, `variable=<dari>`.
- Baris **income** pada variabel tujuan (`ke`): `type='income'`, `variable=<ke>`.

Contoh Transfer Rp10.000 Cash → Saldo:
- Baris 1: `amount=10000, type='outcome', variable='cash'` (Cash berkurang).
- Baris 2: `amount=10000, type='income', variable='saldo'` (Saldo bertambah).
- **Total Keuangan tidak berubah** (Rp tetap sama), hanya redistribusi variabel.

---

### 5. Field Kategori Keuangan (Opsional)

- Tambah field **"Kategori Keuangan"** pada form Keuangan (opsional, boleh kosong).
- Nilai diambil dari **combobox** yang datanya berasal dari **master CRUD Kategori Keuangan** (lihat Bagian 6).
- Kolom DB baru: `category_id` (atau `category`) pada `Data_Kas`.

---

### 6. Master CRUD Kategori Keuangan

- Buat modul/entitas baru **"Kategori Keuangan"** dengan operasi CRUD (tambah, lihat, edit, hapus).
- Kategori dapat dipilih dari combobox pada form Keuangan, **atau ditambahkan langsung** dari combobox (inline create).
- Tabel DB baru: `Data_Keuangan_Kategori` (id, name, created_at, updated_at, deleted_at).
- Tersedia untuk **Admin** (perlu konfirmasi apakah operator dapat mengelola kategori).

---

### 7. Autocomplete Keterangan

- Pada field **Keterangan** (saat tambah/edit keuangan), implementasikan **autocomplete/suggestion** dari data keterangan yang sudah ada di `Data_Kas.description`.
- Saat user mengetik, tampilkan daftar suggestion keterangan unik yang cocok dari database (dari entri yang belum dihapus).
- Mengurangi input manual & menjaga konsistensi data.

---

### 8. Penyesuaian Perubahan Metode Pembayaran (Cash ↔ QRIS)

**Lokasi:** `lib/services/transaction_repository.dart::updatePaymentMethodWithHistory`.

Saat ini sudah ada logika:
- `cash → qris`: soft-delete entri kas terkait.
- `qris → cash`: buat entri kas income.

**Penyesuaian** untuk dua variabel:
- Transaksi **tunai** → entri keuangan `variable='cash'`.
- Transaksi **QRIS** → entri keuangan `variable='saldo'`.
- Saat metode berubah:
  - `cash → qris`: soft-delete entri keuangan `variable='cash'` terkait; **buat** entri `variable='saldo'`.
  - `qris → cash`: soft-delete entri `variable='saldo'`; **buat** entri `variable='cash'`.
- Pencocokan tetap via `transaction_id` ATAU `description LIKE '%Invoice <no>%'` (legacy).

---

## Kebutuhan Database (Migrasi v13 → v14)

| Perubahan | Detail |
|---|---|
| `Data_Kas.variable` | `TEXT` — `'cash'` / `'saldo'`, default `'cash'`. Backfill: entri income terkait transaksi QRIS (payment_method != cash) → `'saldo'`; sisanya `'cash'`. |
| `Data_Kas.category_id` | `INTEGER` (opsional) → FK ke `Data_Keuangan_Kategori`. |
| `Data_Keuangan_Kategori` (baru) | `id, name, created_at, updated_at, deleted_at`. |
| Versi DB | `13 → 14` di `database_helper.dart` (dua tempat: `_initDB` & `openAtPathForTesting`). |

**Perhatian migrasi:** saat menaikkan versi, tambahkan blok `if (oldVersion < 14) { ... }` di `_onUpgrade`. Jangan lupa backfill `variable` untuk data lama berdasarkan payment method transaksi terkait (via `transaction_id` atau invoice di deskripsi).

---

## File yang Perlu Diubah (Estimasi)

| File | Perubahan |
|---|---|
| `lib/services/database_helper.dart` | Migrasi v14: kolom `variable`, `category_id`; tabel `Data_Keuangan_Kategori`. |
| `lib/models/kas.dart` | Tambah `variable`, `categoryId`. |
| `lib/models/additional/kas_with_balance.dart` | (mungkin) tambah info variabel. |
| `lib/services/kas_repository.dart` | Method agregasi per variabel; CRUD kategori; autocomplete keterangan; transfer. |
| `lib/services/keuangan_kategori_repository.dart` (baru) | CRUD kategori keuangan. |
| `lib/views/Dashboard/components/form/kas_form.dart` | Tipe Transfer + dari/ke; Kategori combobox; autocomplete keterangan. |
| `lib/views/Dashboard/contents/kas_content.dart` | Penamaan "Keuangan"; handler transfer (2 baris); kategori. |
| `lib/views/Dashboard/components/sidebar.dart` | Label "Kas Tunai" → "Keuangan". |
| `lib/views/Dashboard/dashboard_page.dart` | Label & routing "Kas Tunai" → "Keuangan"; mungkin tambah menu Kategori Keuangan. |
| `lib/services/transaction_repository.dart` | `deleteTransaction` (rollback per variabel, Admin Only), `updatePaymentMethodWithHistory` (cash→saldo variable). |
| `lib/views/Dashboard/components/detail/transaction_detail.dart` | Pastikan Hapus Admin Only (sudah); sesuaikan rollback. |
| `test/*` | Perbarui/perluas test (migration v14, kas dua variabel, transfer, delete rollback). |

---

## Kriteria Penerimaan

1. Modul bernama **"Keuangan"** dengan variabel **Cash** dan **Saldo** yang dihitung terpisah; Total = Cash + Saldo.
2. Kasus klien terpenuhi: modal 50K (Cash 10K + Saldo 40K) + penjualan 100K (Cash 20K + Saldo 80K) → Total 150K, Cash 30K, Saldo 120K.
3. Admin dapat: tambah/edit keuangan, transfer Cash↔Saldo dua arah.
4. Operator dapat: **hanya** transfer Cash→Saldo, dengan Keterangan **wajib**.
5. Tipe **Transfer** menampilkan field "Dari" dan "Ke" (combobox) dengan aturan: jika Dari=Cash maka Ke=Saldo, dan sebaliknya; Dari ≠ Ke.
6. Transfer menciptakan dua baris jurnal (outcome dari asal + income ke tujuan) tanpa mengubah total.
7. Field **Kategori Keuangan** opsional, bisa dipilih dari combobox atau ditambahkan dari master CRUD.
8. Field **Keterangan** menampilkan autocomplete dari data keterangan yang ada.
9. **Penghapusan transaksi (Admin Only)** melakukan rollback inventory + rollback keuangan (semua entri terkait per variabel).
10. Perubahan metode pembayaran cash ↔ qris menyesuaikan entri keuangan Cash/Saldo dengan benar.
11. Migrasi v13 → v14 berhasil, data lama tetap aman (backfill `variable`).

---

## Keputusan yang Perlu Dikonfirmasi (Open Questions)

1. **Operator tambah keuangan?** Catatan hanya menyebut "Admin can add/edit keuangan"; operator hanya transfer. Apakah operator boleh tambah pemasukan/pengeluaran manual (non-transfer)? Saat ini operator hanya bisa `outcome`.
2. **Nama variabel tampilan:** apakah istilah "Cash" dan "Saldo" persis seperti catatan, atau istilah lain (mis. "Tunai" dan "QRIS")?
3. **Master Kategori Keuangan:** hanya Admin yang kelola, atau operator juga? Muncul sebagai menu terpisah di sidebar, atau bagian dari modul Keuangan?
4. **Autocomplete keterangan:** scope suggestion dari semua keterangan (income/outcome/transfer) atau per variabel/per kategori?
5. **Transfer Operator Cash→Saldo:** apakah boleh memilih nominal bebas, atau terbatas pada jumlah Cash yang tersedia (validasi saldo cukup)?
6. **Kategori pada baris jurnal transfer:** diterapkan ke kedua baris (income & outcome) atau hanya salah satu?
