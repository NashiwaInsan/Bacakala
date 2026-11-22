# Supabase Bacakala

Skrip database Bacakala (PostgreSQL di Supabase). Rancangannya dijelaskan di Bab 3.3 laporan.

## Setup dari nol

1. Buat project di [supabase.com](https://supabase.com).
2. Buka **SQL Editor > New query**, lalu jalankan berurutan:
   1. `01_schema.sql` - tabel, trigger pembuatan profil, fungsi bantu, dan Row Level Security.
   2. `02_club_functions.sql` - fungsi `create_club`, `join_club`, dan `get_club_progress`.
   3. `03_migration_week12.sql` - kolom `avatar_url` dan `tanggal_selesai`, bucket Storage `avatars` dan `covers`, serta hak akses tabel.
   4. `04_trigger_sesi_baca.sql` - trigger progres buku otomatis dan RLS yang lebih ketat.
3. Buka **Authentication > Sign In / Providers**, pastikan Email aktif. Matikan **Confirm email** selama pengembangan.
4. Salin Project URL dan anon/publishable key dari **Project Settings > API Keys** ke file `.env`
   (lihat `.env.example`). Jangan memakai `service_role` key di aplikasi dan jangan meng-commit `.env`.

## Isi folder

| File | Fungsi |
| --- | --- |
| `01_schema.sql` | Tujuh tabel, trigger `handle_new_user`, fungsi `is_club_member`, dan policy RLS |
| `02_club_functions.sql` | Fungsi klub (`security definer`) beserta `grant execute` |
| `03_migration_week12.sql` | Penyesuaian skema dengan kode Flutter dan Storage |
| `04_trigger_sesi_baca.sql` | Trigger progres buku otomatis saat sesi baca disimpan, dan pengetatan RLS |
| `05_tes_trigger.sql` | Skrip uji trigger (di-rollback, tidak meninggalkan data) |
| `06_tes_rls.sql` | Tes RLS dengan dua akun (36 tes, hasil berupa tabel, di-rollback) |
| `erd_drawsql.sql` | DDL ringkas untuk diimpor ke drawSQL (khusus diagram ERD) |

## Tabel

`profiles`, `books`, `reading_sessions`, `notes`, `clubs`, `club_members`, `club_posts`.

## Catatan

- Pembuatan klub dan bergabung ke klub harus lewat `rpc('create_club')` dan `rpc('join_club')`, karena tabel `clubs` dan `club_members` tidak punya policy INSERT.
- `erd_drawsql.sql` hanya untuk diagram, bukan untuk dijalankan di Supabase.
