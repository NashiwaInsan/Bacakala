-- =====================================================================
-- Bacakala - Skema Database Supabase (PostgreSQL)
-- Jalankan di: Supabase Dashboard > SQL Editor > New query > Run
-- =====================================================================

-- ---------- 1. TABEL ----------

-- profiles: 1 baris per pengguna, id sama dengan auth.users.id
create table public.profiles (
  id             uuid primary key references auth.users(id) on delete cascade,
  nama           text not null,
  email          text not null,
  target_tahunan integer not null default 12 check (target_tahunan > 0),
  created_at     timestamptz not null default now()
);

create table public.books (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.profiles(id) on delete cascade,
  judul            text not null,
  penulis          text not null,
  total_halaman    integer not null check (total_halaman > 0),
  halaman_terakhir integer not null default 0 check (halaman_terakhir >= 0),
  status           text not null default 'ingin_dibaca'
                   check (status in ('ingin_dibaca','sedang_dibaca','selesai')),
  cover_url        text,
  created_at       timestamptz not null default now(),
  check (halaman_terakhir <= total_halaman)
);

create table public.reading_sessions (
  id           uuid primary key default gen_random_uuid(),
  book_id      uuid not null references public.books(id) on delete cascade,
  user_id      uuid not null references public.profiles(id) on delete cascade,
  waktu_mulai  timestamptz not null default now(),
  durasi_menit integer not null check (durasi_menit >= 0),
  halaman_awal integer not null check (halaman_awal >= 0),
  halaman_akhir integer not null check (halaman_akhir >= halaman_awal)
);

create table public.notes (
  id         uuid primary key default gen_random_uuid(),
  book_id    uuid not null references public.books(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  halaman    integer check (halaman > 0),
  jenis      text not null default 'catatan' check (jenis in ('kutipan','catatan')),
  isi        text not null,
  created_at timestamptz not null default now()
);

create table public.clubs (
  id             uuid primary key default gen_random_uuid(),
  nama           text not null,
  deskripsi      text,
  judul_buku     text not null,
  target_selesai date,
  kode_undangan  text not null unique
                 default upper(substr(md5(gen_random_uuid()::text), 1, 6)),
  owner_id       uuid not null references public.profiles(id) on delete cascade,
  created_at     timestamptz not null default now()
);

create table public.club_members (
  club_id   uuid not null references public.clubs(id) on delete cascade,
  user_id   uuid not null references public.profiles(id) on delete cascade,
  peran     text not null default 'anggota' check (peran in ('owner','anggota')),
  joined_at timestamptz not null default now(),
  primary key (club_id, user_id)
);

create table public.club_posts (
  id         uuid primary key default gen_random_uuid(),
  club_id    uuid not null references public.clubs(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  isi        text not null,
  created_at timestamptz not null default now()
);

-- Index untuk foreign key yang sering di-query
create index on public.books(user_id, status);
create index on public.reading_sessions(book_id);
create index on public.reading_sessions(user_id, waktu_mulai);
create index on public.notes(book_id, jenis);
create index on public.club_posts(club_id, created_at);

-- ---------- 2. TRIGGER: buat profil otomatis saat register ----------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, nama, email)
  values (new.id,
          coalesce(new.raw_user_meta_data->>'nama', split_part(new.email,'@',1)),
          new.email);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- 3. FUNGSI BANTU (menghindari rekursi RLS) ----------

create or replace function public.is_club_member(p_club uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.club_members
                 where club_id = p_club and user_id = auth.uid());
$$;

-- Buat klub + otomatis jadikan pembuat sebagai owner
create or replace function public.create_club(
  p_nama text, p_deskripsi text, p_judul_buku text, p_target date)
returns public.clubs
language plpgsql security definer set search_path = public
as $$
declare c public.clubs;
begin
  insert into public.clubs (nama, deskripsi, judul_buku, target_selesai, owner_id)
  values (p_nama, p_deskripsi, p_judul_buku, p_target, auth.uid())
  returning * into c;
  insert into public.club_members (club_id, user_id, peran)
  values (c.id, auth.uid(), 'owner');
  return c;
end;
$$;

-- Gabung klub lewat kode undangan
create or replace function public.join_club(p_kode text)
returns public.clubs
language plpgsql security definer set search_path = public
as $$
declare c public.clubs;
begin
  select * into c from public.clubs where kode_undangan = upper(trim(p_kode));
  if not found then
    raise exception 'Kode undangan tidak ditemukan';
  end if;
  insert into public.club_members (club_id, user_id)
  values (c.id, auth.uid())
  on conflict do nothing;
  return c;
end;
$$;

-- ---------- 4. ROW LEVEL SECURITY ----------

alter table public.profiles         enable row level security;
alter table public.books            enable row level security;
alter table public.reading_sessions enable row level security;
alter table public.notes            enable row level security;
alter table public.clubs            enable row level security;
alter table public.club_members     enable row level security;
alter table public.club_posts       enable row level security;

-- profiles: baca profil sendiri dan profil sesama anggota klub; ubah hanya milik sendiri
create policy "profiles_select" on public.profiles for select to authenticated
  using (id = auth.uid()
         or exists (select 1 from public.club_members a
                    join public.club_members b on a.club_id = b.club_id
                    where a.user_id = auth.uid() and b.user_id = profiles.id));
create policy "profiles_update" on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- books, reading_sessions, notes: data pribadi, CRUD hanya oleh pemilik
create policy "books_owner" on public.books for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "sessions_owner" on public.reading_sessions for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "notes_owner" on public.notes for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- clubs: hanya anggota yang bisa melihat; hanya owner yang bisa ubah/hapus
-- (insert dilakukan lewat fungsi create_club)
create policy "clubs_select" on public.clubs for select to authenticated
  using (public.is_club_member(id));
create policy "clubs_update" on public.clubs for update to authenticated
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "clubs_delete" on public.clubs for delete to authenticated
  using (owner_id = auth.uid());

-- club_members: lihat sesama anggota; keluar dari klub = hapus baris sendiri
create policy "members_select" on public.club_members for select to authenticated
  using (public.is_club_member(club_id));
create policy "members_leave" on public.club_members for delete to authenticated
  using (user_id = auth.uid());

-- club_posts: anggota membaca & menulis; penulis boleh menghapus postingannya
create policy "posts_select" on public.club_posts for select to authenticated
  using (public.is_club_member(club_id));
create policy "posts_insert" on public.club_posts for insert to authenticated
  with check (user_id = auth.uid() and public.is_club_member(club_id));
create policy "posts_delete" on public.club_posts for delete to authenticated
  using (user_id = auth.uid());
