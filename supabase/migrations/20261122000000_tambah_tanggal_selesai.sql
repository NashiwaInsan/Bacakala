-- USULAN migrasi: belum dijalankan otomatis.
-- Jalankan manual di Supabase Dashboard > SQL Editor.
--
-- Menambah kolom tanggal selesai membaca di tabel books.
-- Aplikasi sudah siap: selama kolom ini belum ada, tanggal di tab "Selesai"
-- diambil dari created_at. Setelah ada, kolom ini dipakai otomatis dan
-- buku baru berstatus "selesai" langsung diisi tanggalnya.

alter table public.books
  add column if not exists tanggal_selesai timestamptz;

-- Isi buku yang sudah selesai dengan created_at sebagai perkiraan awal.
update public.books
  set tanggal_selesai = created_at
  where status = 'selesai' and tanggal_selesai is null;
