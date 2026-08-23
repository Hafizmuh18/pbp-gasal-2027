# Roadmap Situs PBP Gasal 2026/2027 (Quarto)

Status terkini:
- ✅ Feature 1 - Jadwal semester: selesai (digabung ke homepage `index.qmd`,
  bukan halaman `schedule.qmd` terpisah lagi).
- ✅ Feature 2 - Unduhan PDF & DOCX untuk tutorial/tugas: selesai.
- ✅ Feature 3 - Template slide (revealjs) per tutorial/tugas: selesai.
- ❌ Feature 4 - Admin CMS berbasis web (Decap CMS + GitHub OAuth): **dibatalkan**,
  digantikan alur manual lewat Git (lihat bagian "Cara Menambah Konten" di
  bawah).
- ❌ Feature "Playground": **dihapus total** dari navbar & homepage.
- ✅ Feature 5 - Situs bilingual (Indonesia/Inggris) via Quarto Project
  Profiles: sistem selesai + 1 contoh tutorial/slide penuh bilingual.
- ✅ Feature 6 - Audit & perbaikan responsive (device size, zoom, revealjs).
- ✅ Feature 7 - Template konten reusable (`_templates/`) dengan struktur
  bilingual siap pakai.
- ✅ Feature 8 - Dekorasi navbar (toggle bahasa, toggle dark/light diperbesar,
  polish sidebar).

---

## Context

Situs lama PBP (Docusaurus) sudah dimigrasikan strukturnya ke Quarto di
`website-quarto/` sebagai kerangka (isi tutorial/tugas masih punya konten
tahun lalu, 2025/2026 - akan ditulis ulang belakangan oleh dosen/asdos untuk
2026/2027). Alasan utama pindah ke Quarto: satu sumber konten yang bisa
menghasilkan halaman web **dan** dokumen unduhan (PDF/DOCX) **dan** slide
presentasi, plus tampilan timeline/jadwal semester, plus (baru) dukungan
dua bahasa.

Repo tujuan: **https://github.com/Hafizmuh18/pbp-gasal-2027** (privat, akun
personal `Hafizmuh18`).

> **Catatan soal repo privat + GitHub Pages:** GitHub Pages hanya tersedia
> untuk repo publik di akun Free personal - repo privat baru bisa pakai
> Pages kalau akun upgrade ke GitHub Pro/Team/Enterprise. Begitu situs mau
> live publik, perlu pilih: (a) repo dijadikan publik saat deploy, atau
> (b) upgrade ke GitHub Pro. Keputusan ini bisa ditunda sampai fase deploy.

## Cara Menambah Konten (final)

Tidak ada CMS/form web. Semua materi, tutorial, dan latihan ditambahkan
dengan cara biasa lewat Git, **memakai template di `_templates/`** supaya
struktur multi-format + bilingual selalu konsisten:

1. Clone repo `Hafizmuh18/pbp-gasal-2027`.
2. Copy template yang sesuai dari `website-quarto/_templates/` (lihat
   `_templates/README.md` untuk panduan lengkap) ke folder target
   (`tutorial/`, `assignments/individual/`, `assignments/group/`,
   `slides/`), isi versi Bahasa Indonesia **dan** Inggris.
3. Daftarkan file baru di sidebar `_quarto.yml` (profile id) **dan**
   `_quarto-en.yml` (profile en).
4. `quarto preview` untuk cek lokal, lalu commit & push seperti biasa.
5. Deploy ke GitHub Pages (manual `quarto publish gh-pages` atau lewat
   GitHub Actions - belum disetup, menyusul kalau dibutuhkan). **Render
   dua profile sebelum publish** - lihat bagian "Render & Deploy" di
   bawah, jangan cuma `quarto render` biasa (itu cuma bikin versi id).

Akses menambah konten = siapa saja yang punya write access ke repo GitHub
ini (dikelola lewat Settings → Collaborators seperti repo biasa).

---

## Feature 1 - Jadwal Semester ✅

Tabel jadwal digabung ke `index.qmd` (homepage), bukan halaman terpisah.
Berisi tabel mingguan (materi/tutorial/tugas individu) dan tabel tugas
kelompok & ujian. Tanggal berstatus **estimasi** (digeser 52 minggu dari
kalender Ganjil 2025/2026) sampai kalender akademik resmi 2026/2027 terbit.

## Feature 2 - Multi-format (PDF & DOCX) untuk Tutorial/Tugas ✅

Setiap tutorial/tugas punya frontmatter:

```yaml
format:
  html: default
  typst: default
  docx: default
  revealjs:
    output-file: <nama>-slide.html
    scrollable: true
format-links:
  - html
  - format: typst
    text: PDF
    icon: file-pdf
  - docx
  - format: revealjs
    text: Slide
    icon: easel
```

Isu yang ditemukan & diperbaiki selama proses:
- **Typst engine**: dipasang via `brew install typst` (tanpa sudo).
- **Callout + `pdf-engine: typst` tidak jalan** (bug: "unknown variable:
  callout") - solusinya pakai `format: typst` langsung (bukan
  `format: pdf` dengan `pdf-engine: typst`), tetap menghasilkan file
  `.pdf` biasa.
- **Gambar `/img/...` (root-absolute)** tidak ke-resolve dengan benar di
  Typst/DOCX (beda dengan HTML yang auto-rewrite) - diganti jadi path
  relatif eksplisit (`../img/...` atau `../../img/...` sesuai kedalaman
  folder) langsung di source.
- **Gambar hosting eksternal** (GitHub user-images, Figma thumbnail, dll)
  gagal di-fetch oleh Typst writer - semua didownload otomatis ke
  `img/` lokal saat migrasi, dengan ekstensi file ditentukan dari
  `Content-Type` response (bukan cuma tebak dari URL) untuk hindari
  file `.png` yang isinya sebenarnya JPEG.
- **`@kata` di dalam teks (misal `@login_required` decorator Python)**
  salah diparsing sebagai sitasi akademik oleh Pandoc, menyebabkan error
  "document does not contain a bibliography" saat compile Typst -
  diperbaiki dengan menonaktifkan ekstensi citations di level project:
  `from: markdown-citations` di `_quarto.yml`.

## Feature 3 - Template Slide (revealjs) per Tutorial ✅

`slides/tutorial-0.qmd` adalah contoh nyata (flagship) lengkap bilingual.
Tombol "Lihat Slide"/"View Slide" ada di atas halaman tutorial masing-masing.
`scrollable: true` **wajib di-set per-dokumen** (di dalam `format.revealjs`
masing-masing file), bukan di level project - kalau ditaruh di project
level, key format itu leak ke SEMUA dokumen termasuk yang bukan revealjs.

## Feature 4 - dibatalkan

Sebelumnya direncanakan pakai Decap CMS + GitHub OAuth + Cloudflare Worker
proxy supaya bisa tambah materi lewat form web. Ini sudah **dibongkar
total**: worker `pbp-gasal-2027-decap-proxy` dihapus dari Cloudflare, repo
`decap-proxy` lokal dihapus, link `/admin/` di footer dihapus. Alasan:
disederhanakan kembali ke alur Git manual (lihat "Cara Menambah Konten").

---

## Feature 5 - Situs Bilingual (Indonesia/Inggris) ✅

### Arsitektur

Dipakai **Quarto Project Profiles** - Quarto tidak punya i18n bawaan
seperti Docusaurus, tapi mekanisme profile + `.content-visible` cocok
dipakai untuk situs paralel `/en/`:

- `_quarto.yml` - config **bersama** (project type, resources, format
  html, `profile: default: id`). **Sengaja TIDAK berisi `website.navbar`
  / `website.sidebar` / `website.title`** - lihat catatan penting di
  bawah soal kenapa.
- `_quarto-id.yml` - override khusus profile `id`: `lang: id`,
  `website.title`, `website.navbar`, `website.sidebar`,
  `website.page-footer` versi Bahasa Indonesia.
- `_quarto-en.yml` - override khusus profile `en`: sama strukturnya tapi
  versi Inggris + `project.output-dir: _site/en`.
- Di dalam `.qmd`, konten dibungkus
  `::: {.content-visible when-profile="id"} ... :::` dan
  `::: {.content-visible when-profile="en"} ... :::` - Quarto otomatis
  menampilkan blok yang cocok dengan profile aktif saat render, dan
  membuang (bukan cuma CSS-hide) blok yang tidak cocok.

### ⚠️ Catatan penting #1 - array di profile config di-CONCATENATE, bukan di-replace

Awalnya `website.navbar`/`website.sidebar` id ditaruh langsung di
`_quarto.yml` (base) dan versi Inggris di `_quarto-en.yml`. Ini **bug**:
Quarto men-merge base + profile file dengan aturan *"arrays are
union-concatenated, objects are deep-merged"* - jadi saat profile `en`
aktif, navbar `en` **ditambahkan ke** (bukan menggantikan) navbar `id` dari
base, menghasilkan navbar dobel 11 item yang berantakan. Scalar/object
(judul, `lang`, `output-dir`) aman di-override karena deep-merge object
memang meng-override leaf value, tapi **array (navbar.left/right, sidebar,
page-footer.right) tidak pernah di-replace, selalu concatenate**.

**Fix**: base `_quarto.yml` tidak boleh punya array-array itu sama sekali.
Navbar/sidebar/footer HARUS 100% hanya ada di file profile spesifik
(`_quarto-id.yml` / `_quarto-en.yml`), supaya saat profile X aktif, hanya
base (tanpa array) + file profile X yang ke-merge - tidak ada array lain
yang ikut concatenate.

### ⚠️ Catatan penting #2 - `.content-visible` HARUS berupa fenced Div, bukan atribut heading

`## Judul Slide {.content-visible when-profile="id"}` **tidak berfungsi
sama sekali** - Quarto hanya memfilter node Div (`::: {...} ... :::`),
bukan atribut yang ditempel ke Header. Kalau dipakai sebagai atribut
heading, KEDUA bahasa akan tetap muncul berdampingan di output (sudah
diverifikasi lewat sandbox test - heading dengan atribut ini lolos filter
tanpa dihapus). Ini sempat kejadian nyata di draft awal
`slides/tutorial-0.qmd` (setiap `##` diberi atribut per-bahasa) - hasilnya
slide ID dan EN muncul berselang-seling semua, bukan terfilter. **Fix**:
selalu bungkus SELURUH rangkaian heading satu bahasa (`#` dan `##`
sekaligus) dalam satu blok `:::` penuh, baru susul blok bahasa kedua -
persis pola di `slides/tutorial-0.qmd` final dan `_templates/slide-template.qmd`.

### ⚠️ Catatan penting #3 - `overflow-x: hidden` di `html, body` merusak `position: sticky`

Sidebar kiri (Materi/Tutorial/Tugas) dan panel kanan "Di halaman ini" +
"Format Lain" memakai `position: sticky` supaya tetap terlihat saat
halaman di-scroll. Sejak awal proyek, `styles.css` punya
`html, body { overflow-x: hidden }` (dipasang untuk cegah scrollbar
horizontal dari teks/tabel panjang) - ternyata ini **membuat sticky
berhenti berfungsi begitu halaman di-scroll cukup jauh** (elemen malah
ikut ter-scroll keluar viewport, terlihat seperti section "hilang" dari
panel navigasi). Terverifikasi lewat sandbox test: dengan
`overflow-x:hidden` aktif, `getBoundingClientRect().top` panel sticky jadi
angka negatif besar (proporsional ke posisi scroll) begitu discroll jauh;
setelah `overflow-x:hidden` dihapus, panel benar-benar tetap di
`top: 0` seberapa jauh pun discroll.

**Fix**: `overflow-x: hidden` dihapus dari `html, body`. Perlindungan
horizontal-overflow tetap ada lewat `overflow-wrap: anywhere` (elemen
teks) dan `overflow-x: auto` di `pre`/`.table-responsive` (blok kode &
tabel), yang TIDAK merusak sticky karena diterapkan di elemen spesifik,
bukan di html/body. Menghapus `overflow-x:hidden` juga **mengungkap 2 bug
konten yang sebelumnya ter-mask secara visual** (halaman tetap terlihat
normal karena overflow-nya disembunyikan, bukan benar-benar hilang):
- Beberapa fenced code block yang gagal diparsing Pandoc jadi `<pre>`
  yang benar (biasanya karena terlalu dalam nested di list item dengan
  indentasi tab) - hasilnya `<code>` polos yang mewarisi default browser
  `white-space: pre` (tidak wrap), jadi baris panjang mendorong lebar
  halaman. Fix CSS: `code { white-space: normal }` (supaya fallback ke
  wrap kalau memang fence-nya gagal), lalu `pre code { white-space: pre }`
  dikembalikan supaya kode yang BENAR di-fence tetap mempertahankan
  format aslinya, dengan `pre { overflow-x: auto }` untuk scroll
  horizontal di dalam kotak kode itu sendiri (bukan mendorong halaman).
- `tutorial-4.qmd` punya satu blok kode dengan baris sangat panjang
  (script tag CDN) yang butuh scroll horizontal di dalam `pre`-nya -
  sekarang sudah scroll dengan benar alih-alih mendorong lebar halaman.

**Pelajaran ke depan**: kalau menemukan overflow horizontal baru,
JANGAN tambah `overflow-x:hidden` di `html`/`body` sebagai solusi cepat -
itu akan mematikan sticky sidebar lagi. Selalu terapkan `overflow-wrap`/
`overflow-x:auto` di elemen spesifik yang bermasalah.

### Pola penulisan konten bilingual

Dua pola dipakai, tergantung panjang halaman (lihat juga
`_templates/README.md`):
- **Section pendek** (banner judul/subtitle, daftar aturan pendek) - bungkus
  section itu utuh, dua kali (id lalu en). Contoh: `index.qmd`,
  `tutorial/index.qmd`, `assignments/index.qmd`, `materi/index.qmd`.
- **Halaman panjang** (tutorial/tugas penuh, semua slide dalam satu deck) -
  bungkus **SELURUH isi** (dari sesudah frontmatter/link slide sampai akhir)
  jadi satu blok id dan satu blok en, bukan per-paragraf/per-slide. Contoh
  nyata: `tutorial/tutorial-0.qmd` (940 baris asli → 1871 baris setelah
  dobel bilingual), `slides/tutorial-0.qmd`, `awards.qmd`.

  *Alasan:* menyisipkan pembatas `:::` di tengah satu list item atau di
  tengah satu fenced code block pernah menyebabkan bug parsing Pandoc
  (baris kosong di dalam fence yang bersarang dalam list item merusak
  kontinuitas list, sudah pernah kejadian di sesi migrasi awal) - bungkus
  utuh per-bahasa jauh lebih aman.

### Cakupan terjemahan saat ini

- **Chrome/struktural (navbar, sidebar, footer, halaman index setiap
  section)**: 100% bilingual - `index.qmd`, `tutorial/index.qmd`,
  `assignments/index.qmd`, `materi/index.qmd`, `awards.qmd`.
- **1 contoh tutorial + slide penuh bilingual (flagship)**:
  `tutorial/tutorial-0.qmd` + `slides/tutorial-0.qmd`.
- **9 tutorial (`tutorial-1..9`) + 12 tugas individu/kelompok lainnya**:
  **BELUM diterjemahkan** - masih versi Indonesia saja di kedua profile
  (karena kontennya sendiri masih placeholder tahun lalu, 2025/2026, akan
  ditulis ulang untuk 2026/2027 oleh dosen/asdos). Tulis versi final
  langsung bilingual pakai `_templates/tutorial-template.qmd` /
  `assignment-template.qmd`.

### Toggle bahasa (navbar)

`lang-toggle.js` (di-include lewat `lang-toggle-include.html` -
`include-after-body` butuh file `.html`, bukan `.js` mentah) mendeteksi
bahasa aktif dari `document.documentElement.lang` (bukan pattern path,
karena path relatif tiap profile dihitung dari root-nya sendiri-sendiri,
jadi path-matching pernah menghasilkan bug double-prefix `en/en/...`) dan
menghitung URL halaman yang SAMA di bahasa lain (bukan selalu balik ke
homepage).

## Feature 6 - Audit Responsive ✅

Dicek dengan Chrome headless + CDP (`--remote-debugging-port`,
`--remote-allow-origins=*` wajib di Chrome versi baru) di breakpoint
375/768/1280/1920px pada homepage (id+en), `tutorial/tutorial-0.html`
(id+en), `materi/index.html`, `assignments/index.html`, plus slide deck
`slides/tutorial-0.html` (id+en) - tidak ada horizontal overflow
(`scrollWidth === innerWidth`) di semua kombinasi. CSS dasar sudah ada
sebelumnya (`overflow-wrap: anywhere`, `.pbp-banner` flex-wrap,
`.table-responsive` fallback) dan masih valid.

## Feature 7 - Template Konten Reusable ✅

`website-quarto/_templates/` (prefix `_` → otomatis TIDAK di-render oleh
Quarto sebagai halaman situs, terverifikasi lewat dokumentasi resmi Quarto):
- `tutorial-template.qmd`, `assignment-template.qmd` - frontmatter
  multi-format lengkap + struktur bilingual per-section siap isi.
- `slide-template.qmd` - kerangka revealjs, `scrollable: true`, struktur
  bilingual per-blok (bukan per-heading, lihat Catatan Penting #2 di atas).
- `README.md` - panduan pakai + kedua catatan penting di atas supaya tidak
  terulang di konten baru.

## Feature 8 - Dekorasi Navbar ✅

`styles.css`:
- Toggle dark/light diperbesar lagi (62×30px → **84×42px** desktop,
  50×24px → 64×32px mobile).
- Toggle bahasa (`.pbp-lang-toggle`, class ditambahkan lewat
  `lang-toggle.js` karena Quarto tidak render `aria-label` sebagai atribut
  nyata untuk navbar text item) di-styling jadi pill button senada tema,
  ditempatkan tepat di sebelah toggle dark/light.
- Navbar: hover state + spacing antar item ditambahkan.
- Sidebar: accent border kiri oranye untuk item aktif
  (`.sidebar-item-container:has(.sidebar-link.active)`), warna teks aktif
  ikut tema (`--pbp-blue-dark` / `#8ec3f0` di dark mode) - pakai selector
  asli Quarto (`.sidebar-link.active`), BUKAN `.sidebar-title`/
  `.sidebar-section-title` yang ternyata tidak ada di DOM docked sidebar.
- Title-block otomatis (`#title-block-header`) di-hide di halaman yang
  sudah punya `.pbp-banner` sendiri (`body:has(.pbp-banner) #title-block-header { display: none }`)
  - sebelumnya judul frontmatter (Indonesia-only, tidak ikut translate)
  tampil dobel dengan judul banner yang sudah bilingual, jadi
  membingungkan di profile `en`.

---

## Render & Deploy (dua profile)

**Render satu profile saja TIDAK CUKUP** untuk situs bilingual - harus dua
langkah:

```bash
quarto render                        # profile default "id" → _site/
quarto render --profile en --no-clean   # profile "en" → _site/en/ (--no-clean wajib, supaya output id tidak terhapus)
```

Preview lokal (`quarto preview`) hanya menampilkan satu profile aktif
sekaligus (default `id`) - untuk cek versi `en` saat development, render
manual seperti di atas lalu buka `_site/en/index.html` lewat static file
server (`python3 -m http.server --directory _site`), bukan lewat
`quarto preview`.

## Model Branch Mingguan (mulai 2026-08-16)

Sejak konten Tutorial/Tugas mulai ditulis satu minggu satu per satu,
repo ini memakai **branch berurutan per minggu**, mirip pola yang sudah
dipakai di proyek referensi `personal-portofolio/`:

```
main → tutorial-0 → tutorial-1 → tugas-1 → tutorial-2 → tugas-2 → ...
```

- `main` = kerangka situs SEBELUM ada konten Tutorial/Tugas mingguan
  (navbar, sidebar dasar, template, perbaikan infra/tema) - **belum
  di-publish ke situs live** kalau belum siap.
- `tutorial-N` = cabang dari `tutorial-(N-1)` (bukan dari `tugas`
  manapun), menambahkan `tutorial/tutorial-N.qmd` + gambar + entri
  sidebar-nya saja.
- `tugas-N` = cabang dari `tutorial-N` (bukan dari `tugas-(N-1)`),
  menambahkan `assignments/individual/tugas-N.qmd` + entri sidebar-nya.

**Status saat ini (2026-08-16):** branch `main`, `tutorial-0`,
`tutorial-1`, `tugas-1` sudah ada secara lokal, **belum di-push ke
remote**. `main` sengaja TIDAK memuat konten Tutorial 0/01/Individual
Assignment 1 dulu - itu semua ada di branch masing-masing sebagai
staging, supaya publish ke situs live (`git push` ke `main`, yang otomatis
men-trigger `deploy.yml`) bisa dikontrol manual kapan waktunya, bukan
otomatis begitu kode selesai ditulis. Kapan `main` di-update/di-merge
untuk publish sungguhan adalah keputusan terpisah, tanyakan dulu sebelum
push/merge ke `main` atau ke remote.
