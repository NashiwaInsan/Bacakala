-- =====================================================================
-- Bacakala - Migrasi Week 12 (menyesuaikan Supabase dengan kode Flutter)
-- Jalankan di: Supabase Dashboard > SQL Editor > New query > Run
-- Aman dijalankan ulang.
-- =====================================================================

-- 1. Kolom yang dipakai aplikasi tetapi belum ada di skema awal
alter table public.profiles add column if not exists avatar_url text;           -- foto profil
alter table public.books    add column if not exists tanggal_selesai timestamptz; -- diisi saat status selesai

-- Buku yang sudah berstatus selesai sebelum kolom ini ada
update public.books set tanggal_selesai = created_at
where status = 'selesai' and tanggal_selesai is null;

-- 2. Bucket Storage: avatars (foto profil) dan covers (sampul buku)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 2097152, array['image/jpeg','image/png','image/webp']),
  ('covers',  'covers',  true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- 3. Kebijakan Storage: pengguna hanya mengelola file di folder miliknya
--    (path file = <user_id>/nama_file, sesuai ProfileService dan BookService).
--    Bucket publik, jadi membaca lewat tautan publik tidak butuh policy.
do $$
declare b text;
begin
  foreach b in array array['avatars','covers'] loop
    execute format('drop policy if exists "%1$s_select_own" on storage.objects', b);
    execute format('drop policy if exists "%1$s_insert_own" on storage.objects', b);
    execute format('drop policy if exists "%1$s_update_own" on storage.objects', b);
    execute format('drop policy if exists "%1$s_delete_own" on storage.objects', b);

    execute format($f$create policy "%1$s_select_own" on storage.objects for select to authenticated
      using (bucket_id = %2$L and (storage.foldername(name))[1] = auth.uid()::text)$f$, b, b);
    execute format($f$create policy "%1$s_insert_own" on storage.objects for insert to authenticated
      with check (bucket_id = %2$L and (storage.foldername(name))[1] = auth.uid()::text)$f$, b, b);
    execute format($f$create policy "%1$s_update_own" on storage.objects for update to authenticated
      using (bucket_id = %2$L and (storage.foldername(name))[1] = auth.uid()::text)$f$, b, b);
    execute format($f$create policy "%1$s_delete_own" on storage.objects for delete to authenticated
      using (bucket_id = %2$L and (storage.foldername(name))[1] = auth.uid()::text)$f$, b, b);
  end loop;
end $$;

-- 4. Pastikan hak akses tabel untuk role authenticated (kalau belum dijalankan)
grant usage on schema public to authenticated;
grant select, insert, update, delete on
  public.profiles, public.books, public.reading_sessions, public.notes,
  public.clubs, public.club_members, public.club_posts
to authenticated;

notify pgrst, 'reload schema';

-- 5. Cek hasil
-- select column_name from information_schema.columns
--   where table_schema='public' and table_name in ('profiles','books') order by table_name, ordinal_position;
-- select id, public from storage.buckets;
