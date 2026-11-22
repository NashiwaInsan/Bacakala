-- Fungsi database untuk fitur Klub Baca dan kolom tambahan tabel notes.
-- Jalankan sekali di Supabase: SQL Editor -> New query -> tempel -> Run.
-- Aman dijalankan ulang (create or replace / if not exists).
--
-- Versi revisi: clubs.id = uuid (sesuai skema awal), DROP FUNCTION ditambahkan.
--   bigint/int8 -> biarkan file ini apa adanya
--   uuid        -> ganti semua "p_club_id uuid" dan "(bigint)" menjadi uuid
-- club_members harus punya primary key / unique (club_id, user_id)
-- supaya "on conflict do nothing" di join_club bekerja.

-- ---------------------------------------------------------------
-- 1. Kolom tambahan tabel notes (Form Catatan & daftar catatan)
-- ---------------------------------------------------------------
alter table public.notes add column if not exists created_at timestamptz not null default now();
alter table public.notes add column if not exists foto_url text;

-- Kode undangan harus unik.
create unique index if not exists clubs_kode_undangan_key on public.clubs (kode_undangan);

-- ---------------------------------------------------------------
-- 2. create_club: membuat klub + kode undangan + owner
--    Kode = 3 huruf awal nama klub + 4 angka acak, contoh SBP-2093.
-- ---------------------------------------------------------------
drop function if exists public.create_club(text, text, text, date);
drop function if exists public.get_club_progress(bigint);

create or replace function public.create_club(
  p_nama text,
  p_deskripsi text,
  p_judul_buku text,
  p_target_selesai date
) returns public.clubs
language plpgsql
security definer
set search_path = public
as $$
declare
  v_prefix text;
  v_kode text;
  v_club public.clubs;
begin
  if auth.uid() is null then
    raise exception 'BELUM_LOGIN';
  end if;
  if coalesce(trim(p_nama), '') = '' or coalesce(trim(p_judul_buku), '') = '' then
    raise exception 'DATA_TIDAK_LENGKAP';
  end if;
  if p_target_selesai < current_date then
    raise exception 'TARGET_SUDAH_LEWAT';
  end if;

  v_prefix := rpad(upper(left(regexp_replace(p_nama, '[^A-Za-z]', '', 'g'), 3)), 3, 'X');

  loop
    v_kode := v_prefix || '-' || lpad((floor(random() * 10000))::int::text, 4, '0');
    exit when not exists (select 1 from public.clubs where kode_undangan = v_kode);
  end loop;

  insert into public.clubs (nama, deskripsi, judul_buku, target_selesai, kode_undangan, owner_id)
  values (trim(p_nama), trim(p_deskripsi), trim(p_judul_buku), p_target_selesai, v_kode, auth.uid())
  returning * into v_club;

  insert into public.club_members (club_id, user_id, peran)
  values (v_club.id, auth.uid(), 'owner');

  return v_club;
end;
$$;

-- ---------------------------------------------------------------
-- 3. join_club: bergabung lewat kode undangan
-- ---------------------------------------------------------------
create or replace function public.join_club(p_kode text)
returns public.clubs
language plpgsql
security definer
set search_path = public
as $$
declare
  v_club public.clubs;
begin
  if auth.uid() is null then
    raise exception 'BELUM_LOGIN';
  end if;

  select * into v_club from public.clubs
  where kode_undangan = upper(trim(p_kode));

  if v_club.id is null then
    raise exception 'KODE_TIDAK_DITEMUKAN';
  end if;

  insert into public.club_members (club_id, user_id, peran)
  values (v_club.id, auth.uid(), 'anggota')
  on conflict do nothing;

  return v_club;
end;
$$;

-- ---------------------------------------------------------------
-- 4. get_club_progress: progres tiap anggota pada buku klub.
--    Progres diambil dari buku di rak anggota yang judulnya sama
--    dengan judul_buku klub. Hanya anggota klub yang boleh memanggil.
-- ---------------------------------------------------------------
create or replace function public.get_club_progress(p_club_id uuid)
returns table (user_id uuid, nama text, persen int)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.club_members m
    where m.club_id = p_club_id and m.user_id = auth.uid()
  ) then
    raise exception 'BUKAN_ANGGOTA';
  end if;

  return query
  select m.user_id,
         p.nama,
         coalesce(least(100, round(100.0 * b.halaman_terakhir / nullif(b.total_halaman, 0)))::int, 0)
  from public.club_members m
  join public.clubs c on c.id = m.club_id
  join public.profiles p on p.id = m.user_id
  left join lateral (
    select bk.halaman_terakhir, bk.total_halaman
    from public.books bk
    where bk.user_id = m.user_id
      and lower(bk.judul) = lower(c.judul_buku)
    order by bk.halaman_terakhir desc
    limit 1
  ) b on true
  where m.club_id = p_club_id
  order by 3 desc;
end;
$$;

grant execute on function public.create_club(text, text, text, date) to authenticated;
grant execute on function public.join_club(text) to authenticated;
grant execute on function public.get_club_progress(uuid) to authenticated;
