-- Tes trigger di SQL Editor (berjalan sebagai postgres, lalu di-ROLLBACK
-- sehingga tidak ada data yang tersisa). Butuh minimal 1 buku di tabel books.
begin;

create temp table _b on commit drop as
  select id, user_id, total_halaman from public.books
  where total_halaman >= 20 and status <> 'selesai' limit 1;

-- Sesi 1: baca halaman 0-10 -> halaman_terakhir 10, status sedang_dibaca
insert into public.reading_sessions (book_id, user_id, durasi_menit, halaman_awal, halaman_akhir)
select id, user_id, 15, 0, 10 from _b;
select 'setelah sesi 1' as langkah, judul, halaman_terakhir, status, tanggal_selesai
from public.books where id = (select id from _b);

-- Sesi 2: baca sampai halaman terakhir -> status selesai + tanggal_selesai terisi
insert into public.reading_sessions (book_id, user_id, durasi_menit, halaman_awal, halaman_akhir)
select id, user_id, 30, 10, total_halaman from _b;
select 'setelah sesi 2' as langkah, judul, halaman_terakhir, status, tanggal_selesai
from public.books where id = (select id from _b);

rollback;
