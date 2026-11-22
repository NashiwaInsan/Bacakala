-- =====================================================================
-- Bacakala - Tes Row Level Security dengan dua akun
-- Syarat: sudah ada minimal 2 pengguna di Authentication > Users.
-- Skrip membuat data uji, menjalankan tiap tes sebagai akun A atau B
-- (meniru pengguna login), mencatat hasilnya, lalu ROLLBACK, jadi tidak
-- ada data yang tersisa. Hasil tampil sebagai tabel di akhir.
-- A = pengguna tertua di auth.users, B = pengguna tertua kedua. Kedua akun sebaiknya
-- belum berbagi klub; jika sudah, tes "profil A sebelum satu klub" bisa gagal.
-- =====================================================================
begin;

create temp table hasil (
  no     serial,
  tes    text,
  harapan text,
  hasil  text,
  status text
);
grant all on hasil to authenticated, anon;
grant usage on sequence hasil_no_seq to authenticated, anon;

-- Data uji: view admin untuk mengambil klub uji tanpa terkena RLS
create temp view clubs_admin_view as select * from public.clubs where nama = 'Klub Uji RLS';
grant select on clubs_admin_view to authenticated, anon;

do $uji$
declare
  a  uuid; b uuid;
  bk uuid := gen_random_uuid();
  n  bigint;
  r  record;
begin
  select id into a from auth.users order by created_at limit 1;
  select id into b from auth.users order by created_at offset 1 limit 1;
  if a is null or b is null then
    raise exception 'Butuh minimal 2 pengguna di Authentication > Users';
  end if;

  -- Buku & catatan: A menambah buku sendiri
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', a::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('insert into public.books (id, user_id, judul, penulis, total_halaman) values (%1$L, %2$L, ''Buku Uji RLS'', ''Penulis'', 100)', bk, a, b);
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: A menambah buku sendiri', 'Berhasil', 'Berhasil', 'LULUS');
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: A menambah buku sendiri', 'Berhasil', 'Gagal: ' || sqlerrm, 'GAGAL');
  end;

  -- Buku & catatan: A menambah catatan di buku sendiri
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', a::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('insert into public.notes (book_id, user_id, halaman, jenis, isi) values (%1$L, %2$L, 5, ''kutipan'', ''Catatan uji A'')', bk, a, b);
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: A menambah catatan di buku sendiri', 'Berhasil', 'Berhasil', 'LULUS');
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: A menambah catatan di buku sendiri', 'Berhasil', 'Gagal: ' || sqlerrm, 'GAGAL');
  end;

  -- Buku & catatan: A menambah sesi baca di buku sendiri
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', a::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('insert into public.reading_sessions (book_id, user_id, durasi_menit, halaman_awal, halaman_akhir) values (%1$L, %2$L, 10, 0, 30)', bk, a, b);
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: A menambah sesi baca di buku sendiri', 'Berhasil', 'Berhasil', 'LULUS');
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: A menambah sesi baca di buku sendiri', 'Berhasil', 'Gagal: ' || sqlerrm, 'GAGAL');
  end;

  -- Buku & catatan: Trigger: progres buku A naik ke 30 dan status sedang_dibaca
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', a::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('select count(*) from public.books where id = %1$L and halaman_terakhir = 30 and status = ''sedang_dibaca''', bk, a, b) into n;
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: Trigger: progres buku A naik ke 30 dan status sedang_dibaca', '1 baris', n || ' baris', case when n = 1 then 'LULUS' else 'GAGAL' end);
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: Trigger: progres buku A naik ke 30 dan status sedang_dibaca', '1 baris', 'Error: ' || sqlerrm, 'GAGAL');
  end;

  -- Buku & catatan: B melihat buku milik A
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('select count(*) from public.books where id = %1$L', bk, a, b) into n;
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: B melihat buku milik A', '0 baris', n || ' baris', case when n = 0 then 'LULUS' else 'GAGAL' end);
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: B melihat buku milik A', '0 baris', 'Error: ' || sqlerrm, 'GAGAL');
  end;

  -- Buku & catatan: B melihat catatan milik A
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('select count(*) from public.notes where book_id = %1$L', bk, a, b) into n;
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: B melihat catatan milik A', '0 baris', n || ' baris', case when n = 0 then 'LULUS' else 'GAGAL' end);
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: B melihat catatan milik A', '0 baris', 'Error: ' || sqlerrm, 'GAGAL');
  end;

  -- Buku & catatan: B melihat sesi baca milik A
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('select count(*) from public.reading_sessions where book_id = %1$L', bk, a, b) into n;
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: B melihat sesi baca milik A', '0 baris', n || ' baris', case when n = 0 then 'LULUS' else 'GAGAL' end);
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: B melihat sesi baca milik A', '0 baris', 'Error: ' || sqlerrm, 'GAGAL');
  end;

  -- Buku & catatan: B mengubah buku milik A
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('with x as (update public.books set judul = ''DIRETAS'' where id = %1$L returning 1) select count(*) from x', bk, a, b) into n;
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: B mengubah buku milik A', '0 baris berubah', n || ' baris', case when n = 0 then 'LULUS' else 'GAGAL' end);
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: B mengubah buku milik A', '0 baris berubah', 'Error: ' || sqlerrm, 'GAGAL');
  end;

  -- Buku & catatan: B menghapus buku milik A
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('with x as (delete from public.books where id = %1$L returning 1) select count(*) from x', bk, a, b) into n;
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: B menghapus buku milik A', '0 baris terhapus', n || ' baris', case when n = 0 then 'LULUS' else 'GAGAL' end);
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: B menghapus buku milik A', '0 baris terhapus', 'Error: ' || sqlerrm, 'GAGAL');
  end;

  -- Buku & catatan: B menambah sesi baca di buku milik A
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('insert into public.reading_sessions (book_id, user_id, durasi_menit, halaman_awal, halaman_akhir) values (%1$L, %3$L, 5, 0, 5)', bk, a, b);
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: B menambah sesi baca di buku milik A', 'Ditolak RLS', 'Lolos (seharusnya ditolak)', 'GAGAL');
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: B menambah sesi baca di buku milik A', 'Ditolak RLS', 'Ditolak: ' || sqlerrm, case when sqlerrm ilike '%row-level security%' then 'LULUS' else 'GAGAL' end);
  end;

  -- Buku & catatan: B menambah catatan di buku milik A
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('insert into public.notes (book_id, user_id, halaman, jenis, isi) values (%1$L, %3$L, 1, ''catatan'', ''x'')', bk, a, b);
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: B menambah catatan di buku milik A', 'Ditolak RLS', 'Lolos (seharusnya ditolak)', 'GAGAL');
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: B menambah catatan di buku milik A', 'Ditolak RLS', 'Ditolak: ' || sqlerrm, case when sqlerrm ilike '%row-level security%' then 'LULUS' else 'GAGAL' end);
  end;

  -- Buku & catatan: A mengisi sesi dengan halaman melebihi total buku
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', a::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('insert into public.reading_sessions (book_id, user_id, durasi_menit, halaman_awal, halaman_akhir) values (%1$L, %2$L, 5, 0, 500)', bk, a, b);
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: A mengisi sesi dengan halaman melebihi total buku', 'Ditolak (HALAMAN_MELEBIHI_TOTAL)', 'Lolos (seharusnya ditolak)', 'GAGAL');
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Buku & catatan: A mengisi sesi dengan halaman melebihi total buku', 'Ditolak (HALAMAN_MELEBIHI_TOTAL)', 'Ditolak: ' || sqlerrm, case when sqlerrm ilike '%HALAMAN_MELEBIHI_TOTAL%' then 'LULUS' else 'GAGAL' end);
  end;

  -- Profil: B mengubah profil A
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('with x as (update public.profiles set nama = ''DIRETAS'' where id = %2$L returning 1) select count(*) from x', bk, a, b) into n;
    insert into hasil(tes, harapan, hasil, status) values ('Profil: B mengubah profil A', '0 baris berubah', n || ' baris', case when n = 0 then 'LULUS' else 'GAGAL' end);
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Profil: B mengubah profil A', '0 baris berubah', 'Error: ' || sqlerrm, 'GAGAL');
  end;

  -- Profil: B melihat profil A sebelum satu klub
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('select count(*) from public.profiles where id = %2$L', bk, a, b) into n;
    insert into hasil(tes, harapan, hasil, status) values ('Profil: B melihat profil A sebelum satu klub', '0 baris', n || ' baris', case when n = 0 then 'LULUS' else 'GAGAL' end);
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Profil: B melihat profil A sebelum satu klub', '0 baris', 'Error: ' || sqlerrm, 'GAGAL');
  end;

  -- Profil: A mengubah profilnya sendiri
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', a::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('with x as (update public.profiles set target_tahunan = target_tahunan where id = %2$L returning 1) select count(*) from x', bk, a, b) into n;
    insert into hasil(tes, harapan, hasil, status) values ('Profil: A mengubah profilnya sendiri', '1 baris berubah', n || ' baris', case when n = 1 then 'LULUS' else 'GAGAL' end);
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Profil: A mengubah profilnya sendiri', '1 baris berubah', 'Error: ' || sqlerrm, 'GAGAL');
  end;

  -- Klub: A membuat klub lewat create_club
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', a::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('select public.create_club(''Klub Uji RLS'', ''Deskripsi'', ''Buku Uji RLS'', current_date + 30)', bk, a, b);
    insert into hasil(tes, harapan, hasil, status) values ('Klub: A membuat klub lewat create_club', 'Berhasil', 'Berhasil', 'LULUS');
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Klub: A membuat klub lewat create_club', 'Berhasil', 'Gagal: ' || sqlerrm, 'GAGAL');
  end;

  -- Klub: A tercatat sebagai owner klub
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', a::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('select count(*) from public.club_members m join public.clubs c on c.id = m.club_id where c.nama = ''Klub Uji RLS'' and m.user_id = %2$L and m.peran = ''owner''', bk, a, b) into n;
    insert into hasil(tes, harapan, hasil, status) values ('Klub: A tercatat sebagai owner klub', '1 baris', n || ' baris', case when n = 1 then 'LULUS' else 'GAGAL' end);
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Klub: A tercatat sebagai owner klub', '1 baris', 'Error: ' || sqlerrm, 'GAGAL');
  end;

  -- Klub: B melihat klub A (belum anggota)
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('select count(*) from public.clubs where nama = ''Klub Uji RLS''', bk, a, b) into n;
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B melihat klub A (belum anggota)', '0 baris', n || ' baris', case when n = 0 then 'LULUS' else 'GAGAL' end);
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B melihat klub A (belum anggota)', '0 baris', 'Error: ' || sqlerrm, 'GAGAL');
  end;

  -- Klub: B menambah postingan di klub A (belum anggota)
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('insert into public.club_posts (club_id, user_id, isi) select id, %3$L, ''spam'' from clubs_admin_view', bk, a, b);
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B menambah postingan di klub A (belum anggota)', 'Ditolak RLS', 'Lolos (seharusnya ditolak)', 'GAGAL');
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B menambah postingan di klub A (belum anggota)', 'Ditolak RLS', 'Ditolak: ' || sqlerrm, case when sqlerrm ilike '%row-level security%' then 'LULUS' else 'GAGAL' end);
  end;

  -- Klub: B langsung insert ke clubs (tanpa fungsi)
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('insert into public.clubs (nama, judul_buku, kode_undangan, owner_id) values (''Klub Palsu'', ''X'', ''ZZZ-0000'', %3$L)', bk, a, b);
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B langsung insert ke clubs (tanpa fungsi)', 'Ditolak RLS', 'Lolos (seharusnya ditolak)', 'GAGAL');
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B langsung insert ke clubs (tanpa fungsi)', 'Ditolak RLS', 'Ditolak: ' || sqlerrm, case when sqlerrm ilike '%row-level security%' then 'LULUS' else 'GAGAL' end);
  end;

  -- Klub: B memasukkan diri langsung ke club_members klub A
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('insert into public.club_members (club_id, user_id) select id, %3$L from clubs_admin_view', bk, a, b);
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B memasukkan diri langsung ke club_members klub A', 'Ditolak RLS', 'Lolos (seharusnya ditolak)', 'GAGAL');
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B memasukkan diri langsung ke club_members klub A', 'Ditolak RLS', 'Ditolak: ' || sqlerrm, case when sqlerrm ilike '%row-level security%' then 'LULUS' else 'GAGAL' end);
  end;

  -- Klub: B memanggil get_club_progress (belum anggota)
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('select * from public.get_club_progress((select id from clubs_admin_view))', bk, a, b);
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B memanggil get_club_progress (belum anggota)', 'Ditolak (BUKAN_ANGGOTA)', 'Lolos (seharusnya ditolak)', 'GAGAL');
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B memanggil get_club_progress (belum anggota)', 'Ditolak (BUKAN_ANGGOTA)', 'Ditolak: ' || sqlerrm, case when sqlerrm ilike '%BUKAN_ANGGOTA%' then 'LULUS' else 'GAGAL' end);
  end;

  -- Klub: B join dengan kode yang salah
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('select public.join_club(''ZZZ-0000'')', bk, a, b);
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B join dengan kode yang salah', 'Ditolak (KODE_TIDAK_DITEMUKAN)', 'Lolos (seharusnya ditolak)', 'GAGAL');
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B join dengan kode yang salah', 'Ditolak (KODE_TIDAK_DITEMUKAN)', 'Ditolak: ' || sqlerrm, case when sqlerrm ilike '%KODE_TIDAK_DITEMUKAN%' then 'LULUS' else 'GAGAL' end);
  end;

  -- Klub: B join dengan kode yang benar (huruf kecil juga diterima)
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('select public.join_club(lower((select kode_undangan from clubs_admin_view)))', bk, a, b);
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B join dengan kode yang benar (huruf kecil juga diterima)', 'Berhasil', 'Berhasil', 'LULUS');
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B join dengan kode yang benar (huruf kecil juga diterima)', 'Berhasil', 'Gagal: ' || sqlerrm, 'GAGAL');
  end;

  -- Klub: B kini melihat klub A
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('select count(*) from public.clubs where nama = ''Klub Uji RLS''', bk, a, b) into n;
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B kini melihat klub A', '1 baris', n || ' baris', case when n = 1 then 'LULUS' else 'GAGAL' end);
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B kini melihat klub A', '1 baris', 'Error: ' || sqlerrm, 'GAGAL');
  end;

  -- Klub: B kini melihat profil A (sesama anggota)
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('select count(*) from public.profiles where id = %2$L', bk, a, b) into n;
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B kini melihat profil A (sesama anggota)', '1 baris', n || ' baris', case when n = 1 then 'LULUS' else 'GAGAL' end);
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B kini melihat profil A (sesama anggota)', '1 baris', 'Error: ' || sqlerrm, 'GAGAL');
  end;

  -- Klub: B kini memanggil get_club_progress
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('select count(*) from public.get_club_progress((select id from clubs_admin_view))', bk, a, b) into n;
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B kini memanggil get_club_progress', '2 baris (A dan B)', n || ' baris', case when n = 2 then 'LULUS' else 'GAGAL' end);
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B kini memanggil get_club_progress', '2 baris (A dan B)', 'Error: ' || sqlerrm, 'GAGAL');
  end;

  -- Klub: B menulis postingan di klub (anggota)
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('insert into public.club_posts (club_id, user_id, isi) select id, %3$L, ''Halo dari B'' from public.clubs where nama = ''Klub Uji RLS''', bk, a, b);
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B menulis postingan di klub (anggota)', 'Berhasil', 'Berhasil', 'LULUS');
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B menulis postingan di klub (anggota)', 'Berhasil', 'Gagal: ' || sqlerrm, 'GAGAL');
  end;

  -- Klub: B menulis postingan atas nama A
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('insert into public.club_posts (club_id, user_id, isi) select id, %2$L, ''palsu'' from public.clubs where nama = ''Klub Uji RLS''', bk, a, b);
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B menulis postingan atas nama A', 'Ditolak RLS', 'Lolos (seharusnya ditolak)', 'GAGAL');
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B menulis postingan atas nama A', 'Ditolak RLS', 'Ditolak: ' || sqlerrm, case when sqlerrm ilike '%row-level security%' then 'LULUS' else 'GAGAL' end);
  end;

  -- Klub: A menghapus postingan milik B
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', a::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('with x as (delete from public.club_posts where user_id = %3$L returning 1) select count(*) from x', bk, a, b) into n;
    insert into hasil(tes, harapan, hasil, status) values ('Klub: A menghapus postingan milik B', '0 baris terhapus', n || ' baris', case when n = 0 then 'LULUS' else 'GAGAL' end);
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Klub: A menghapus postingan milik B', '0 baris terhapus', 'Error: ' || sqlerrm, 'GAGAL');
  end;

  -- Klub: B mengubah klub (bukan owner)
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('with x as (update public.clubs set nama = ''DIRETAS'' where nama = ''Klub Uji RLS'' returning 1) select count(*) from x', bk, a, b) into n;
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B mengubah klub (bukan owner)', '0 baris berubah', n || ' baris', case when n = 0 then 'LULUS' else 'GAGAL' end);
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B mengubah klub (bukan owner)', '0 baris berubah', 'Error: ' || sqlerrm, 'GAGAL');
  end;

  -- Klub: B menghapus klub (bukan owner)
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', b::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('with x as (delete from public.clubs where nama = ''Klub Uji RLS'' returning 1) select count(*) from x', bk, a, b) into n;
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B menghapus klub (bukan owner)', '0 baris terhapus', n || ' baris', case when n = 0 then 'LULUS' else 'GAGAL' end);
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Klub: B menghapus klub (bukan owner)', '0 baris terhapus', 'Error: ' || sqlerrm, 'GAGAL');
  end;

  -- Klub: A mengubah klubnya sendiri (owner)
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', a::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('with x as (update public.clubs set deskripsi = ''Diubah owner'' where nama = ''Klub Uji RLS'' returning 1) select count(*) from x', bk, a, b) into n;
    insert into hasil(tes, harapan, hasil, status) values ('Klub: A mengubah klubnya sendiri (owner)', '1 baris berubah', n || ' baris', case when n = 1 then 'LULUS' else 'GAGAL' end);
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Klub: A mengubah klubnya sendiri (owner)', '1 baris berubah', 'Error: ' || sqlerrm, 'GAGAL');
  end;

  -- Tanpa login: Pengguna anon membaca tabel books
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', '', 'role', 'anon')::text, true);
  execute 'set local role anon';
  begin
    execute format('select count(*) from public.books', bk, a, b);
    insert into hasil(tes, harapan, hasil, status) values ('Tanpa login: Pengguna anon membaca tabel books', 'Ditolak (permission denied)', 'Lolos (seharusnya ditolak)', 'GAGAL');
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Tanpa login: Pengguna anon membaca tabel books', 'Ditolak (permission denied)', 'Ditolak: ' || sqlerrm, case when sqlerrm ilike '%permission denied%' then 'LULUS' else 'GAGAL' end);
  end;

  -- Hapus berantai: A menghapus buku, sesi dan catatan ikut terhapus
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', a::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('delete from public.books where id = %1$L', bk, a, b);
    insert into hasil(tes, harapan, hasil, status) values ('Hapus berantai: A menghapus buku, sesi dan catatan ikut terhapus', 'Berhasil', 'Berhasil', 'LULUS');
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Hapus berantai: A menghapus buku, sesi dan catatan ikut terhapus', 'Berhasil', 'Gagal: ' || sqlerrm, 'GAGAL');
  end;

  -- Hapus berantai: Sisa sesi dan catatan pada buku yang dihapus
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', a::text, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    execute format('select (select count(*) from public.notes where book_id = %1$L) + (select count(*) from public.reading_sessions where book_id = %1$L)', bk, a, b) into n;
    insert into hasil(tes, harapan, hasil, status) values ('Hapus berantai: Sisa sesi dan catatan pada buku yang dihapus', '0 baris', n || ' baris', case when n = 0 then 'LULUS' else 'GAGAL' end);
  exception when others then
    insert into hasil(tes, harapan, hasil, status) values ('Hapus berantai: Sisa sesi dan catatan pada buku yang dihapus', '0 baris', 'Error: ' || sqlerrm, 'GAGAL');
  end;

  execute 'reset role';
end
$uji$;

select no, tes, harapan, hasil, status from hasil order by no;

rollback;