# Template Konten PBP

Folder ini (prefix `_`) **tidak ikut di-render** oleh Quarto - aman untuk
menyimpan berkas contoh/template di sini secara permanen.

## Model kelas Gasal 2026/2027 (penting dibaca dulu)

Format kelas tahun ini beda dari tahun sebelumnya - semua template di sini
sudah disesuaikan, tapi kalau kamu bingung liat halaman lama (tahun lalu)
sebagai acuan, jangan, isinya masih pola lama. Model yang berlaku sekarang:

- Tiap minggu ada **Sesi 1 (Senin)** = kuliah/Topik, dan **Sesi 2 (Rabu)** =
  Tutorial hands-on. Lihat jadwal lengkap di homepage.
- **Tutorial dibangun berkelanjutan** di atas SATU aplikasi tema yang sama
  sepanjang semester (bukan latihan berdiri sendiri per minggu) - Tutorial
  02 melanjutkan proyek dari Tutorial 01, dst.
- **Tidak ada lagi Tugas Individu mingguan.** Penilaian individu sekarang:
  - **Kuis 1/2/3** - lewat SCELE langsung, tidak butuh halaman di situs ini.
  - **2x Tutorial Asynchronous** - pakai `tutorial-template.qmd` seperti
    biasa (bukan `assignment-template.qmd`), tandai "(Asynchronous)" di judul.
  - **1 Proyek Individu** (website portofolio pribadi) yang dikerjakan
    berkelanjutan sepanjang semester, dinilai per Tugas/checkpoint - pakai
    `assignment-template.qmd` (bentuknya deskripsi target singkat, TANPA
    screenshot atau langkah step-by-step seperti Tutorial).
- **Tugas kelompok (PTS/PAS)** punya halaman sendiri di `assignments/group/`
  (lihat `midterm.qmd`/`finalterm.qmd` yang sudah ada), **tidak** memakai
  `assignment-template.qmd`.
- **Tutorial dan Tugas sekarang satu domain yang sama** (personal
  portfolio), bukan dua tema terpisah seperti rencana awal. Tugas-N
  melanjutkan LANGSUNG dari kode Tutorial-N minggu yang sama. Branch kode
  referensi: jalur `tutorial-N` berurutan (`tutorial-2` dari `tutorial-1`,
  dst, TIDAK dari tugas manapun), jalur `tugas-N` masing-masing bercabang
  dari `tutorial-N` (bukan dari `tugas-(N-1)`) karena tugas sifatnya
  bebas/open-ended dan tidak boleh jadi prasyarat tutorial berikutnya.
  Lihat `personal-portofolio/README.md`.
- Setiap Tutorial **wajib** ada section "Menghubungkan ke Proyek Kamu" yang
  menjelaskan eksplisit bagian mana dari proyek individu mahasiswa bisa
  memakai pola yang sama dengan yang baru dikerjakan di tutorial itu - ini
  intinya supaya mahasiswa paham tugas mereka mengikuti pola yang sama
  dengan tutorial, cuma bagiannya beda (dasar vs. lanjutan/bebas).

## Isi

- `tutorial-template.qmd` - kerangka Tutorial mingguan (Sesi 2), multi-format
  (HTML/PDF via Typst/DOCX/Slide revealjs), bilingual (ID/EN), dengan
  section recap ("Yang Sudah Kita Bangun") dan section jembatan ke proyek
  individu ("Menghubungkan ke Proyek Kamu"). Detail dan step-by-step -
  boleh panjang, sertakan screenshot hasil menjalankan proyeknya.
- `assignment-template.qmd` - kerangka Tugas Proyek Individu, multi-format,
  bilingual. Deskripsi target + checklist singkat SAJA - **tidak perlu**
  screenshot atau langkah step-by-step (beda dari Tutorial). **Bukan**
  untuk tugas kelompok (pakai halaman sendiri di `assignments/group/`)
  atau Kuis (lewat SCELE).
- `slide-template.qmd` - kerangka revealjs standalone (dipakai lewat tombol
  "Lihat Slide"), bilingual per-slide.

## Cara membuat konten baru

1. **Copy** template yang sesuai ke lokasi target:
   - Tutorial mingguan → `tutorial/tutorial-N.qmd`
   - Tugas proyek individu → `assignments/individual/tugas-N.qmd`
   - Tugas kelompok → `assignments/group/<nama>.qmd` (contoh sudah ada,
     tidak perlu template ini)
   - Slide pendamping → `slides/tutorial-N.qmd`
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
   blok** - kalau salah satu bahasa belum siap, isi sementara dengan
   terjemahan kasar daripada dihapus, supaya switch bahasa di navbar tidak
   menampilkan halaman kosong. **Jangan taruh APAPUN yang tampil ke
   pembaca di luar kedua blok ini** - termasuk baris "Pemrograman Berbasis
   Platform..." dan link "Lihat Slide", keduanya harus muncul DUA KALI, di
   dalam tiap blok bahasa masing-masing, bukan sekali di atas/luar blok.
4. **Judul halaman harus manual, bukan andalkan frontmatter `title:`.**
   Quarto tidak bisa membuat frontmatter `title:` berbeda per profile -
   dia dipakai apa adanya untuk tab browser DAN untuk judul otomatis di
   atas halaman (`#title-block-header`), jadi kalau dibiarkan, judul akan
   selalu satu bahasa saja (biasanya Indonesia) walau isinya sudah
   di-translate. Solusinya: tulis heading `#` manual di baris pertama tiap
   blok bahasa dengan atribut `{.pbp-page-title}`:
   ```qmd
   ::: {.content-visible when-profile="id"}
   # Judul Halaman Versi Indonesia {.pbp-page-title}
   ...
   :::
   ::: {.content-visible when-profile="en"}
   # Page Title in English {.pbp-page-title}
   ...
   :::
   ```
   CSS di `styles.css` (`body:has(.pbp-banner, .pbp-page-title) #title-block-header { display: none }`)
   otomatis menyembunyikan judul frontmatter begitu `.pbp-page-title` ada
   di halaman. Kedua template di folder ini sudah pakai pola ini - contoh
   nyata lain: `tutorial/tutorial-1.qmd`.
5. **Daftarkan berkas baru** di sidebar `contents:` pada **kedua** berkas
   konfigurasi (`_quarto-id.yml` dan `_quarto-en.yml`), DAN beri `text:`
   eksplisit per bahasa untuk tiap entri - jangan biarkan Quarto menurunkan
   label sidebar dari frontmatter title (sama masalahnya seperti poin 4,
   dan ini juga memengaruhi label breadcrumb):
   ```yaml
   - text: "Tutorial 01: Setup Git Repository, ..."   # _quarto-id.yml
     href: tutorial/tutorial-1.qmd
   - text: "Tutorial 01: Set Up Git Repository, ..."  # _quarto-en.yml
     href: tutorial/tutorial-1.qmd
   ```
6. **Render & cek dua profile - WAJIB, jangan skip:**
   ```bash
   quarto render
   quarto render --profile en --no-clean
   ```
   Buka halaman ID dan `/en/` versi yang sama **berdampingan**, lalu
   periksa SEMUANYA sudah ikut ganti bahasa: judul tab/halaman, breadcrumb,
   label sidebar, isi body, tombol "Lihat Slide"/"View Slide". Kalau ada
   satu saja teks yang identik di kedua bahasa padahal seharusnya beda,
   berarti ada yang lolos dari `.content-visible`, dari `.pbp-page-title`,
   atau dari `text:` sidebar - telusuri balik ke tiga poin di atas. Ini
   langkah regresi WAJIB tiap kali bikin/edit tutorial atau tugas baru,
   bukan opsional.

## PENTING: jangan taruh `.content-visible` sebagai atribut heading

`## Judul Slide {.content-visible when-profile="id"}` **tidak berfungsi**
- Quarto hanya memfilter fenced Div (`::: {.content-visible ...} ... :::`),
bukan atribut yang ditempel langsung ke heading. Kalau dipakai sebagai
atribut heading, kedua bahasa akan tetap muncul berdampingan di output
(sudah terverifikasi lewat sandbox test). Ini yang harus dipakai di slide
revealjs (lihat `slide-template.qmd` - belum ada contoh nyata yang sudah
jadi per 2026-08-15, jadi ikuti template ini persis): bungkus **seluruh
rangkaian slide** (semua `#` dan `##` satu bahasa penuh) dalam satu `:::`
block, baru susul dengan block bahasa kedua - jangan interleave per-slide.

## Catatan tentang blok `.content-visible` di dalam list/callout

Jangan sisipkan pembatas `.content-visible` **di tengah-tengah** satu
list item atau satu fenced code block (mis. membagi satu langkah bernomor
menjadi setengah ID setengah EN) - ini pernah menyebabkan bug parsing
Pandoc (baris kosong di dalam fence yang bersarang dalam list item merusak
kontinuitas list). Pola yang aman dan sudah terbukti jalan di seluruh situs
ini:

- Untuk section pendek (banner, daftar aturan): bungkus section itu utuh,
  dua kali (id lalu en).
- Untuk halaman panjang (tutorial/tugas penuh, lihat
  `tutorial/tutorial-1.qmd` sebagai contoh nyata): bungkus **seluruh isi
  halaman** (dari sesudah frontmatter sampai akhir) jadi satu blok id dan
  satu blok en, bukan per-paragraf.
