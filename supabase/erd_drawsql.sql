-- Bacakala - DDL untuk import ke drawSQL (PostgreSQL)
-- Versi ringkas khusus diagram: tanpa trigger, fungsi, RLS, dan CHECK.

CREATE TABLE profiles (
  id             uuid PRIMARY KEY,
  nama           varchar(100) NOT NULL,
  email          varchar(255) NOT NULL,
  target_tahunan integer NOT NULL DEFAULT 12,
  avatar_url     text,
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE books (
  id               uuid PRIMARY KEY,
  user_id          uuid NOT NULL,
  judul            varchar(255) NOT NULL,
  penulis          varchar(255) NOT NULL,
  total_halaman    integer NOT NULL,
  halaman_terakhir integer NOT NULL DEFAULT 0,
  status           varchar(20) NOT NULL DEFAULT 'ingin_dibaca',
  cover_url        text,
  tanggal_selesai  timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT fk_books_user FOREIGN KEY (user_id) REFERENCES profiles (id)
);

CREATE TABLE reading_sessions (
  id            uuid PRIMARY KEY,
  book_id       uuid NOT NULL,
  user_id       uuid NOT NULL,
  waktu_mulai   timestamptz NOT NULL DEFAULT now(),
  durasi_menit  integer NOT NULL,
  halaman_awal  integer NOT NULL,
  halaman_akhir integer NOT NULL,
  CONSTRAINT fk_sessions_book FOREIGN KEY (book_id) REFERENCES books (id),
  CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES profiles (id)
);

CREATE TABLE notes (
  id         uuid PRIMARY KEY,
  book_id    uuid NOT NULL,
  user_id    uuid NOT NULL,
  halaman    integer,
  jenis      varchar(20) NOT NULL DEFAULT 'catatan',
  isi        text NOT NULL,
  foto_url   text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT fk_notes_book FOREIGN KEY (book_id) REFERENCES books (id),
  CONSTRAINT fk_notes_user FOREIGN KEY (user_id) REFERENCES profiles (id)
);

CREATE TABLE clubs (
  id             uuid PRIMARY KEY,
  nama           varchar(100) NOT NULL,
  deskripsi      text,
  judul_buku     varchar(255) NOT NULL,
  target_selesai date,
  kode_undangan  varchar(10) NOT NULL UNIQUE,
  owner_id       uuid NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT fk_clubs_owner FOREIGN KEY (owner_id) REFERENCES profiles (id)
);

CREATE TABLE club_members (
  club_id   uuid NOT NULL,
  user_id   uuid NOT NULL,
  peran     varchar(20) NOT NULL DEFAULT 'anggota',
  joined_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (club_id, user_id),
  CONSTRAINT fk_members_club FOREIGN KEY (club_id) REFERENCES clubs (id),
  CONSTRAINT fk_members_user FOREIGN KEY (user_id) REFERENCES profiles (id)
);

CREATE TABLE club_posts (
  id         uuid PRIMARY KEY,
  club_id    uuid NOT NULL,
  user_id    uuid NOT NULL,
  isi        text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT fk_posts_club FOREIGN KEY (club_id) REFERENCES clubs (id),
  CONSTRAINT fk_posts_user FOREIGN KEY (user_id) REFERENCES profiles (id)
);
