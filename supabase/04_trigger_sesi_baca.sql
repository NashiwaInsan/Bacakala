-- =====================================================================
-- Bacakala - Trigger sesi baca + pengetatan RLS
-- Jalankan di: Supabase SQL Editor. Aman dijalankan ulang.
-- =====================================================================

-- 1. Setelah sesi membaca disimpan, perbarui progres buku otomatis (Bab 2.2.5)
--    - halaman_terakhir naik ke halaman_akhir sesi (tidak pernah turun)
--    - halaman_akhir >= total_halaman  -> status 'selesai' + tanggal_selesai
--    - status 'ingin_dibaca'           -> menjadi 'sedang_dibaca'
create or replace function public.apply_reading_session()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  b public.books;
  halaman_baru integer;
begin
  select * into b from public.books where id = new.book_id for update;

  if not found or b.user_id <> new.user_id then
    raise exception 'BUKU_BUKAN_MILIK_ANDA';
  end if;
  if new.halaman_akhir > b.total_halaman then
    raise exception 'HALAMAN_MELEBIHI_TOTAL';
  end if;

  halaman_baru := greatest(b.halaman_terakhir, new.halaman_akhir);

  update public.books
  set halaman_terakhir = halaman_baru,
      status = case
                 when halaman_baru >= b.total_halaman then 'selesai'
                 when b.status = 'ingin_dibaca'        then 'sedang_dibaca'
                 else b.status
               end,
      tanggal_selesai = case
                 when halaman_baru >= b.total_halaman then coalesce(b.tanggal_selesai, now())
                 else b.tanggal_selesai
               end
  where id = b.id;

  return new;
end;
$$;

drop trigger if exists on_reading_session_created on public.reading_sessions;
create trigger on_reading_session_created
  after insert on public.reading_sessions
  for each row execute function public.apply_reading_session();

-- 2. Pengetatan RLS: sesi dan catatan hanya boleh dibuat pada buku milik sendiri
--    (sebelumnya hanya user_id yang dicek, book_id milik orang lain masih lolos)
drop policy if exists "sessions_owner" on public.reading_sessions;
create policy "sessions_owner" on public.reading_sessions for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid()
              and exists (select 1 from public.books b
                          where b.id = book_id and b.user_id = auth.uid()));

drop policy if exists "notes_owner" on public.notes;
create policy "notes_owner" on public.notes for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid()
              and exists (select 1 from public.books b
                          where b.id = book_id and b.user_id = auth.uid()));
