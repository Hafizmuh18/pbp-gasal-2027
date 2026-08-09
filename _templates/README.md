# Template Konten PBP

Folder ini (prefix `_`) **tidak ikut di-render** oleh Quarto — aman untuk
menyimpan berkas contoh/template di sini secara permanen.

## Model kelas Gasal 2026/2027 (penting dibaca dulu)

Format kelas tahun ini beda dari tahun sebelumnya — semua template di sini
sudah disesuaikan, tapi kalau kamu bingung liat halaman lama (tahun lalu)
sebagai acuan, jangan, isinya masih pola lama. Model yang berlaku sekarang:

- Tiap minggu ada **Sesi 1 (Senin)** = kuliah/Topik, dan **Sesi 2 (Rabu)** =
  Tutorial hands-on. Lihat jadwal lengkap di homepage.
- **Tutorial dibangun berkelanjutan** di atas SATU aplikasi tema yang sama
  sepanjang semester (bukan latihan berdiri sendiri per minggu) — Tutorial
  02 melanjutkan proyek dari Tutorial 01, dst.
- **Tidak ada lagi Tugas Individu mingguan.** Penilaian individu sekarang:
  - **Kuis 1/2/3** — lewat Moodle langsung, tidak butuh halaman di situs ini.
  - **2x Tutorial Asynchronous** — pakai `tutorial-template.qmd` seperti
    biasa (bukan `assignment-template.qmd`), tandai "(Asynchronous)" di judul.
  - **1 Proyek Individu** (mis. website portofolio) yang dikerjakan
    berkelanjutan sepanjang semester, dinilai per milestone/checkpoint —
    pakai `assignment-template.qmd` (sekarang bentuknya milestone brief,
    bukan tugas mingguan berdiri sendiri).
- **Tugas kelompok (PTS/PAS)** punya halaman sendiri di `assignments/group/`
  (lihat `midterm.qmd`/`finalterm.qmd` yang sudah ada), **tidak** memakai
  `assignment-template.qmd`.
- Setiap Tutorial **wajib** ada section "Menghubungkan ke Proyek Kamu" yang
  menjelaskan eksplisit bagian mana dari proyek individu mahasiswa bisa
  memakai pola yang sama dengan yang baru dikerjakan di tutorial itu — ini
  intinya supaya mahasiswa paham tugas mereka mengikuti pola yang sama
  dengan tutorial, cuma tema/domainnya beda.

## Isi

- `tutorial-template.qmd` — kerangka Tutorial mingguan (Sesi 2), multi-format
  (HTML/PDF via Typst/DOCX/Slide revealjs), bilingual (ID/EN), dengan
  section recap ("Yang Sudah Kita Bangun") dan section jembatan ke proyek
  individu ("Menghubungkan ke Proyek Kamu").
- `assignment-template.qmd` — kerangka milestone Proyek Individu, multi-format,
  bilingual. **Bukan** untuk tugas kelompok (pakai halaman sendiri di
  `assignments/group/`) atau Kuis (lewat Moodle).
- `slide-template.qmd` — kerangka revealjs standalone (dipakai lewat tombol
  "Lihat Slide"), bilingual per-slide.

## Cara membuat konten baru

1. **Copy** template yang sesuai ke lokasi target:
   - Tutorial mingguan → `tutorial/tutorial-N.qmd`
   - Milestone proyek individu → `assignments/individual/milestone-N.qmd`
   - Tugas kelompok → `assignments/group/<nama>.qmd` (contoh sudah ada,
     tidak perlu template ini)
   - Slide pendamping → `slides/tutorial-N.qmd` atau `slides/milestone-N.qmd`
2. **Ganti** placeholder (judul, `output-file`, dst.) dengan nomor/judul
   yang sesuai, mengikuti urutan Topik/Tutorial di jadwal homepage.
3. **Isi kedua versi bahasa.** Setiap section dibungkus dua kali:
   ```qmd
   ::: {.content-visible when-profile="id"}
   ... versi Bahasa Indonesia ...
   :::
   ::: {.content-visible when-profile="en"}
   ... versi Bahasa Inggris ...
   :::
   ```
   Quarto otomatis menampilkan blok yang sesuai dengan profile aktif saat
   render (`id` = default, `en` = `--profile en`). **Jangan hapus salah satu
   blok** — kalau salah satu bahasa belum siap, isi sementara dengan
   terjemahan kasar daripada dihapus, supaya switch bahasa di navbar tidak
   menampilkan halaman kosong.
4. **Daftarkan berkas baru** di sidebar `contents:` pada **kedua** berkas
   konfigurasi:
   - `_quarto.yml` (profile `id`)
   - `_quarto-en.yml` (profile `en`, biasanya path sama, cuma label section
     yang beda)
5. **Render & cek dua profile:**
   ```bash
   quarto render
   quarto render --profile en --no-clean
   ```
   Buka halaman ID dan `/en/` versi yang sama, pastikan teksnya beda bahasa
   dan tombol "Lihat Slide"/"View Slide" mengarah ke slide yang benar.

## PENTING: jangan taruh `.content-visible` sebagai atribut heading

`## Judul Slide {.content-visible when-profile="id"}` **tidak berfungsi**
— Quarto hanya memfilter fenced Div (`::: {.content-visible ...} ... :::`),
bukan atribut yang ditempel langsung ke heading. Kalau dipakai sebagai
atribut heading, kedua bahasa akan tetap muncul berdampingan di output
(sudah terverifikasi lewat sandbox test). Ini yang harus dipakai di slide
revealjs (lihat `slide-template.qmd` dan `slides/tutorial-0.qmd` sebagai
contoh nyata yang sudah benar): bungkus **seluruh rangkaian slide** (semua
`#` dan `##` satu bahasa penuh) dalam satu `:::` block, baru susul dengan
block bahasa kedua — jangan interleave per-slide.

## Catatan tentang blok `.content-visible` di dalam list/callout

Jangan sisipkan pembatas `.content-visible` **di tengah-tengah** satu
list item atau satu fenced code block (mis. membagi satu langkah bernomor
menjadi setengah ID setengah EN) — ini pernah menyebabkan bug parsing
Pandoc (baris kosong di dalam fence yang bersarang dalam list item merusak
kontinuitas list). Pola yang aman dan sudah terbukti jalan di seluruh situs
ini:

- Untuk section pendek (banner, daftar aturan): bungkus section itu utuh,
  dua kali (id lalu en).
- Untuk halaman panjang (tutorial/tugas penuh, lihat
  `tutorial/tutorial-0.qmd` sebagai contoh nyata): bungkus **seluruh isi
  halaman** (dari sesudah frontmatter sampai akhir) jadi satu blok id dan
  satu blok en, bukan per-paragraf.
