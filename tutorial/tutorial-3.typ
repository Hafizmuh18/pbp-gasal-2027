// Simple numbering for non-book documents
#let equation-numbering = "(1)"
#let callout-numbering = "1"
#let subfloat-numbering(n-super, subfloat-idx) = {
  numbering("1a", n-super, subfloat-idx)
}

// Theorem configuration for theorion
// Simple numbering for non-book documents (no heading inheritance)
#let theorem-inherited-levels = 0

// Theorem numbering format (can be overridden by extensions for appendix support)
// This function returns the numbering pattern to use
#let theorem-numbering(loc) = "1.1"

// Default theorem render function
#let theorem-render(prefix: none, title: "", full-title: auto, body) = {
  if full-title != "" and full-title != auto and full-title != none {
    strong[#full-title.]
    h(0.5em)
  }
  body
}
// Some definitions presupposed by pandoc's typst output.
#let content-to-string(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(content-to-string).join("")
  } else if content.has("body") {
    content-to-string(content.body)
  } else if content == [ ] {
    " "
  }
}

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms.item: it => block(breakable: false)[
  #text(weight: "bold")[#it.term]
  #block(inset: (left: 1.5em, top: -0.4em))[#it.description]
]

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let fields = old_block.fields()
  let _ = fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => {
          let subfloat-idx = quartosubfloatcounter.get().first() + 1
          subfloat-numbering(n-super, subfloat-idx)
        })
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => block({
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          })

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let children = old_title_block.body.body.children
  let old_title = if children.len() == 1 {
    children.at(0)  // no icon: title at index 0
  } else {
    children.at(1)  // with icon: title at index 1
  }

  // TODO use custom separator if available
  // Use the figure's counter display which handles chapter-based numbering
  // (when numbering is a function that includes the heading counter)
  let callout_num = it.counter.display(it.numbering)
  let new_title = if empty(old_title) {
    [#kind #callout_num]
  } else {
    [#kind #callout_num: #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block,
    block_with_new_content(
      old_title_block.body,
      if children.len() == 1 {
        new_title  // no icon: just the title
      } else {
        children.at(0) + new_title  // with icon: preserve icon block + new title
      }))

  align(left, block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1)))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color,
        width: 100%,
        inset: 8pt)[#if icon != none [#text(icon_color, weight: 900)[#icon] ]#title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}


// syntax highlighting functions from skylighting:
/* Function definitions for syntax highlighting generated by skylighting: */
#let EndLine() = raw("\n")
#let Skylighting(fill: none, number: false, start: 1, sourcelines) = {
   let blocks = []
   let lnum = start - 1
   let bgcolor = rgb("#f1f3f5")
   for ln in sourcelines {
     if number {
       lnum = lnum + 1
       blocks = blocks + box(width: if start + sourcelines.len() > 999 { 30pt } else { 24pt }, text(fill: rgb("#aaaaaa"), [ #lnum ]))
     }
     blocks = blocks + ln + EndLine()
   }
   block(fill: bgcolor, blocks)
}
#let AlertTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let AnnotationTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let AttributeTok(s) = text(fill: rgb("#657422"),raw(s))
#let BaseNTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let BuiltInTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let CharTok(s) = text(fill: rgb("#20794d"),raw(s))
#let CommentTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let CommentVarTok(s) = text(style: "italic",fill: rgb("#5e5e5e"),raw(s))
#let ConstantTok(s) = text(fill: rgb("#8f5902"),raw(s))
#let ControlFlowTok(s) = text(weight: "bold",fill: rgb("#003b4f"),raw(s))
#let DataTypeTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let DecValTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let DocumentationTok(s) = text(style: "italic",fill: rgb("#5e5e5e"),raw(s))
#let ErrorTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let ExtensionTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let FloatTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let FunctionTok(s) = text(fill: rgb("#4758ab"),raw(s))
#let ImportTok(s) = text(fill: rgb("#00769e"),raw(s))
#let InformationTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let KeywordTok(s) = text(weight: "bold",fill: rgb("#003b4f"),raw(s))
#let NormalTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let OperatorTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let OtherTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let PreprocessorTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let RegionMarkerTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let SpecialCharTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let SpecialStringTok(s) = text(fill: rgb("#20794d"),raw(s))
#let StringTok(s) = text(fill: rgb("#20794d"),raw(s))
#let VariableTok(s) = text(fill: rgb("#111111"),raw(s))
#let VerbatimStringTok(s) = text(fill: rgb("#20794d"),raw(s))
#let WarningTok(s) = text(style: "italic",fill: rgb("#5e5e5e"),raw(s))



#let article(
  title: none,
  subtitle: none,
  authors: none,
  keywords: (),
  date: none,
  abstract-title: none,
  abstract: none,
  thanks: none,
  cols: 1,
  lang: "en",
  region: "US",
  font: none,
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: none,
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  mathfont: none,
  codefont: none,
  linestretch: 1,
  sectionnumbering: none,
  linkcolor: none,
  citecolor: none,
  filecolor: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  // Set document metadata for PDF accessibility
  set document(title: title, keywords: keywords)
  set document(
    author: authors.map(author => content-to-string(author.name)).join(", ", last: " & "),
  ) if authors != none and authors != ()
  set par(
    justify: true,
    leading: linestretch * 0.65em
  )
  set text(lang: lang,
           region: region,
           size: fontsize)
  set text(font: font) if font != none
  show math.equation: set text(font: mathfont) if mathfont != none
  show raw: set text(font: codefont) if codefont != none

  set heading(numbering: sectionnumbering)

  show link: set text(fill: rgb(content-to-string(linkcolor))) if linkcolor != none
  show ref: set text(fill: rgb(content-to-string(citecolor))) if citecolor != none
  show link: this => {
    if filecolor != none and type(this.dest) == label {
      text(this, fill: rgb(content-to-string(filecolor)))
    } else {
      text(this)
    }
   }

  let has-title-block = title != none or (authors != none and authors != ()) or date != none or abstract != none
  if has-title-block {
    place(
      top,
      float: true,
      scope: "parent",
      clearance: 4mm,
      block(below: 1em, width: 100%)[

        #if title != none {
          align(center, block(inset: 2em)[
            #set par(leading: heading-line-height) if heading-line-height != none
            #set text(font: heading-family) if heading-family != none
            #set text(weight: heading-weight)
            #set text(style: heading-style) if heading-style != "normal"
            #set text(fill: heading-color) if heading-color != black

            #text(size: title-size)[#title #if thanks != none {
              footnote(thanks, numbering: "*")
              counter(footnote).update(n => n - 1)
            }]
            #(if subtitle != none {
              parbreak()
              text(size: subtitle-size)[#subtitle]
            })
          ])
        }

        #if authors != none and authors != () {
          let count = authors.len()
          let ncols = calc.min(count, 3)
          grid(
            columns: (1fr,) * ncols,
            row-gutter: 1.5em,
            ..authors.map(author =>
                align(center)[
                  #author.name \
                  #author.affiliation \
                  #author.email
                ]
            )
          )
        }

        #if date != none {
          align(center)[#block(inset: 1em)[
            #date
          ]]
        }

        #if abstract != none {
          block(inset: 2em)[
          #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
          ]
        }
      ]
    )
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  doc
}

#set table(
  inset: 6pt,
  stroke: none
)
#import "@preview/fontawesome:0.5.0": *
#let brand-color = (:)
#let brand-color-background = (:)
#let brand-logo = (:)

#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
  columns: 1,
)

#show: doc => article(
  title: [Tutorial 03: Form dan Data Delivery],
  lang: "id",
  toc_title: [Daftar Isi],
  toc_depth: 3,
  doc,
)

= Tutorial 03: Form dan Data Delivery
<tutorial-03-form-dan-data-delivery>
Pemrograman Berbasis Platform (CSGE602022) - diselenggarakan oleh Fakultas Ilmu Komputer Universitas Indonesia, Semester Gasal 2026/2027

#strong[Kontributor:] FERN - Vazha Khayri, EHW - Evan Haryo Widodo, DUH - Bermulya Anugrah Putra

#horizontalrule

=== Tujuan Pembelajaran
<tujuan-pembelajaran>
Setelah menyelesaikan tutorial ini, mahasiswa diharapkan untuk dapat:

- Mengetahui konsep #emph[data delivery] menggunakan XML dan JSON.
- Memahami struktur, perbedaan format, dan cara membaca data dalam bentuk XML dan JSON.

#block[
#callout(
body: 
[
#strong[Tutorial ini adalah prasyarat wajib untuk Individual Assignment minggu ini] - jika Tutorial ini belum diselesaikan, Individual Assignment tersebut tidak akan dinilai. Deadline Tutorial 03 adalah #strong[Rabu, 16 September 2026]\; deadline Individual Assignment 3 adalah #strong[Senin, 21 September 2026]. Lihat #link("../index.qmd#jadwal-semester")[halaman Jadwal] untuk tanggal lengkap.

]
, 
title: 
[
Peringatan
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]
Tutorial ini adalah #strong[Tutorial 03], lanjutan langsung dari #link("tutorial-2.qmd")[Tutorial 02] - tutorial keempat dari proyek yang akan kamu bangun berkelanjutan sepanjang semester: sebuah #strong[website portofolio pribadi]. Semua tutorial berikutnya akan melanjutkan langsung dari hasil tutorial ini, jadi pastikan proyekmu berjalan dengan baik sebelum lanjut ke tutorial berikutnya.

Sepanjang tutorial ini, contoh yang dipakai adalah portofolio milik #strong[Burhan], maskot mata kuliah PBP. Setiap kali ada bagian yang berisi data pribadi Burhan (nama, NPM, bio, foto), akan ada catatan eksplisit yang bilang "ganti ini dengan data kamu sendiri" - jangan sampai kelewat.

#block[
#callout(
body: 
[
#strong[Yang Sudah Kita Bangun Sejauh Ini] - Di Tutorial 2, kamu memindahkan data profil yang masih ditulis langsung di HTML ke dalam #emph[context] dan membuat halaman #strong[Experience] yang mengambil data dari model.

/ Pada tutorial ini, kita akan mempelajari konsep #emph[Data Delivery] menggunakan XML dan JSON, sebagai fondasi sebelum kita mengimplementasikannya pada proyek myportofolio.: #block[
:#NormalTok("## Pengenalan Data Delivery"); Dalam mengembangkan suatu #emph[platform] web atau perangkat lunak modern, ada kalanya kita perlu mengirimkan data dari satu #emph[stack] ke #emph[stack] lainnya (misalnya dari #emph[backend server] ke #emph[frontend client], atau dari satu layanan web ke layanan web lainnya).
]

Data yang dikirimkan bisa bermacam-macam bentuknya. Beberapa format penyajian data yang umum digunakan antara lain HTML, XML, dan JSON. Implementasi #emph[data delivery] dalam bentuk HTML yang dirender oleh server sudah kamu pelajari pada tutorial sebelumnya. Pada bagian ini, kita akan berfokus pada dua format populer lainnya: #strong[XML dan JSON].

=== XML (Extensible Markup Language)
<xml-extensible-markup-language>
#strong[XML] (#emph[eXtensible Markup Language]) adalah sebuah format teks yang dirancang agar mudah dimengerti hanya dengan membacanya, karena setiap elemen dalam XML mendeskripsikan dirinya sendiri (#emph[self-descriptive]). XML banyak digunakan dalam berbagai aplikasi #emph[web] dan #emph[mobile] generasi terdahulu maupun sistem #emph[enterprise] untuk tujuan penyimpanan dan pertukaran data.

File XML hanya berisi data yang dikemas dalam #emph[tag] tertentu. Untuk dapat mengirim, menerima, menyimpan, atau menampilkan informasi dari #emph[file] tersebut, kita perlu membuat program yang dapat memproses strukturnya.

Contoh Format XML:

#Skylighting(([#FunctionTok("<?xml");#NormalTok(" ");#OtherTok("version=");#StringTok("\"1.0\"");#NormalTok(" ");#OtherTok("encoding=");#StringTok("\"UTF-8\"");#FunctionTok("?>");],
[#NormalTok("<");#KeywordTok("person");#NormalTok(">");],
[#NormalTok("    <");#KeywordTok("name");#NormalTok(">Burhan</");#KeywordTok("name");#NormalTok(">");],
[#NormalTok("    <");#KeywordTok("age");#NormalTok(">25</");#KeywordTok("age");#NormalTok(">");],
[#NormalTok("    <");#KeywordTok("address");#NormalTok(">");],
[#NormalTok("        <");#KeywordTok("street");#NormalTok(">Jl. PeBePe No.1</");#KeywordTok("street");#NormalTok(">");],
[#NormalTok("        <");#KeywordTok("city");#NormalTok(">Depok</");#KeywordTok("city");#NormalTok(">");],
[#NormalTok("        <");#KeywordTok("province");#NormalTok(">Jawa Barat</");#KeywordTok("province");#NormalTok(">");],
[#NormalTok("        <");#KeywordTok("zip");#NormalTok(">16424</");#KeywordTok("zip");#NormalTok(">");],
[#NormalTok("    </");#KeywordTok("address");#NormalTok(">");],
[#NormalTok("</");#KeywordTok("person");#NormalTok(">");],));
XML di atas sangatlah #emph[self-descriptive]: - Ada informasi nama (#NormalTok("name");) - Ada informasi umur (#NormalTok("age");) - Ada informasi alamat (#NormalTok("address");) yang bersarang (#emph[nested]), mencakup: - jalan (#NormalTok("street");) - kota (#NormalTok("city");) - provinsi (#NormalTok("province");) - kode pos (#NormalTok("zip");)

Dokumen XML membentuk struktur hierarki seperti #emph[tree] yang dimulai dari elemen #emph[root], lalu ke cabang (#emph[branch]), hingga berakhir pada daun (#emph[leaves]). Dokumen XML #strong[harus mengandung sebuah #emph[root element]] yang merupakan induk (#emph[parent]) dari elemen lainnya. Pada contoh di atas, #NormalTok("<person>"); adalah #emph[root element].

Baris #NormalTok("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"); disebut sebagai #strong[XML Prolog]. Prolog ini bersifat opsional, tetapi jika ada, posisinya harus berada paling awal di dokumen. Pada dokumen XML, #strong[semua elemen wajib memiliki #emph[closing tag]]. #emph[Tag] pada XML juga bersifat #strong[#emph[case sensitive]], sehingga tag #NormalTok("<person>"); dianggap #strong[berbeda] dengan tag #NormalTok("<Person>");.

=== JSON (JavaScript Object Notation)
<json-javascript-object-notation>
#strong[JSON] (#emph[JavaScript Object Notation]) adalah sebuah format pertukaran data ringan yang sangat populer saat ini. Seperti XML, JSON dirancang agar mudah dimengerti manusia (karena juga bersifat #emph[self-describing]) dan mudah di-#emph[parsing] atau di-#emph[generate] oleh mesin.

Meskipun sintaks JSON berasal dari notasi objek bahasa pemrograman JavaScript, JSON sebenarnya adalah format teks murni yang independen terhadap bahasa. Hampir seluruh bahasa pemrograman modern memiliki dukungan bawaan (#emph[built-in]) untuk membaca dan membuat struktur JSON.

Contoh format JSON:

#Skylighting(([#FunctionTok("{");],
[#NormalTok("  ");#DataTypeTok("\"name\"");#FunctionTok(":");#NormalTok(" ");#StringTok("\"Burhan\"");#FunctionTok(",");],
[#NormalTok("  ");#DataTypeTok("\"age\"");#FunctionTok(":");#NormalTok(" ");#DecValTok("25");#FunctionTok(",");],
[#NormalTok("  ");#DataTypeTok("\"address\"");#FunctionTok(":");#NormalTok(" ");#FunctionTok("{");],
[#NormalTok("    ");#DataTypeTok("\"street\"");#FunctionTok(":");#NormalTok(" ");#StringTok("\"Jl. PeBePe No.1\"");#FunctionTok(",");],
[#NormalTok("    ");#DataTypeTok("\"city\"");#FunctionTok(":");#NormalTok(" ");#StringTok("\"Depok\"");#FunctionTok(",");],
[#NormalTok("    ");#DataTypeTok("\"province\"");#FunctionTok(":");#NormalTok(" ");#StringTok("\"Jawa Barat\"");#FunctionTok(",");],
[#NormalTok("    ");#DataTypeTok("\"zip\"");#FunctionTok(":");#NormalTok(" ");#StringTok("\"16424\"");],
[#NormalTok("  ");#FunctionTok("}");],
[#FunctionTok("}");],));
Data pada JSON direpresentasikan dalam bentuk pasangan #strong[#emph[key]] dan #strong[#emph[value]] (kunci-nilai). Pada contoh di atas, yang menjadi #emph[key] adalah #NormalTok("\"name\"");, #NormalTok("\"age\"");, dan #NormalTok("\"address\"");. #emph[Value] pada JSON dapat berupa tipe data primitif (#emph[string], #emph[number], #emph[boolean], #emph[null]), himpunan (#emph[array]), ataupun sekumpulan pasangan #emph[key-value] lain (berupa objek bersarang/ #emph[nested object]).

Saat ini, JSON lebih disukai dibandingkan XML pada aplikasi modern (terutama pada arsitektur #emph[RESTful API]) karena ukurannya yang lebih ringkas, #emph[parser] yang sangat cepat, dan integrasi yang sangat natural dengan JavaScript di sisi #emph[frontend].

#block[
#callout(
body: 
[
#strong[Menghubungkan ke Proyek Kamu] - Pemahaman mengenai XML dan JSON adalah langkah awal yang esensial agar aplikasi portofolio yang kamu bangun dapat berkomunikasi dengan sistem lain. Seiring dengan berkembangnya kompleksitas proyekmu, aplikasi tidak lagi sekadar mengembalikan dokumen HTML utuh. Kamu akan dihadapkan pada kebutuhan untuk menyediakan data mentah (seperti JSON) yang dapat diproses secara asinkronus, misalnya melalui AJAX, untuk meningkatkan interaktivitas pada sisi #emph[frontend].

]
, 
title: 
[
Penting
]
, 
background_color: 
rgb("#f7dddc")
, 
icon_color: 
rgb("#CC1914")
, 
icon: 
fa-exclamation()
, 
body_background_color: 
white
)
]
== Pre-Tutorial Notes
<pre-tutorial-notes>
Sebelum melanjutkan tutorial 2 ini, kami mengharapkan kamu memastikan hal-hal berikut di bawah ini:

- #strong[Jika tidak sengaja push file sensitif seperti #NormalTok(".env");, #NormalTok(".env.prod");, #NormalTok("db.sqlite3");, atau folder #NormalTok("env/");, hapus dari Git menggunakan:]

  #Skylighting(([#FunctionTok("git");#NormalTok(" rm ");#AttributeTok("--cached");#NormalTok(" .env .env.prod db.sqlite3");],
  [#FunctionTok("git");#NormalTok(" rm ");#AttributeTok("-r");#NormalTok(" ");#AttributeTok("--cached");#NormalTok(" env/");],));
  #strong[Catatan]: Perintah di atas menghapus file sensitif dari tracking Git ke depannya.

  Cek apakah #NormalTok(".gitignore"); sudah berisi file sensitif tersebut:

  #Skylighting(([#FunctionTok("cat");#NormalTok(" .gitignore");],));
  Jika belum ada, tambahkan ke #NormalTok(".gitignore");:

  #Skylighting(([#NormalTok(".env*");],
  [#NormalTok("db.sqlite3");],
  [#NormalTok("env/");],));
  Kemudian buat commit clean up:

  #Skylighting(([#FunctionTok("git");#NormalTok(" add .");],
  [#FunctionTok("git");#NormalTok(" commit ");#AttributeTok("-m");#NormalTok(" ");#StringTok("\"cleanup\"");],));
  Dengan demikian, kita dapat meminimalisasi risiko keamanan dari credential yang ter-expose di repository publik.

- #strong[Struktur direktori myportofolio]

  #Skylighting(([#NormalTok("myportofolio");],
  [#NormalTok("├── env/");],
  [#NormalTok("├── .git/");],
  [#NormalTok("├── .gitignore");],
  [#NormalTok("├── requirements.txt");],
  [#NormalTok("├── db.sqlite3");],
  [#NormalTok("├── manage.py");],
  [#NormalTok("├── portofolio  ");],
  [#NormalTok("│   ├── migrations");],
  [#NormalTok("│   ├── __init__.py");],
  [#NormalTok("│   ├── admin.py");],
  [#NormalTok("│   ├── apps.py");],
  [#NormalTok("│   ├── models.py");],
  [#NormalTok("│   ├── tests.py");],
  [#NormalTok("│   ├── urls.py");],
  [#NormalTok("│   ├── views.py");],
  [#NormalTok("├── portofolio              # folder konfigurasi utama proyek");],
  [#NormalTok("│   ├── __init__.py");],
  [#NormalTok("│   ├── asgi.py");],
  [#NormalTok("│   ├── settings.py         # semua konfigurasi proyek ada di sini");],
  [#NormalTok("│   ├── urls.py             # daftar routing URL");],
  [#NormalTok("│   ├── views.py");],
  [#NormalTok("│   └── wsgi.py        ");],
  [#NormalTok("├── requirements.txt");],
  [#NormalTok("├── static");],
  [#NormalTok("│   ├── css");],
  [#NormalTok("│   │   └── style.css");],
  [#NormalTok("│   └── img");],
  [#NormalTok("│       └── burhan.png");],
  [#NormalTok("└── templates");],
  [#NormalTok("    └── index.html");],
  [#NormalTok("    └── experience.html");],));

#block[
#callout(
body: 
[
#strong[Jika ada tambahan atau perubahan minor pada struktur folder] yang kamu lakukan pada tugas 1, tidak masalah, ya! Perubahan minor yang dimaksud adalah adanya penambahan file, seperti html, css, \.png, atau sejenisnya yang digunakan untuk menyajikan informasi pada halaman web

]
, 
title: 
[
Tip
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]
== Tutorial: Implementasi Skeleton Sebagai Kerangka Utama Tampilan Web
<tutorial-implementasi-skeleton-sebagai-kerangka-utama-tampilan-web>
Sebelum kita masuk ke materi utama, yakni pembuatan form, kita perlu membuat suatu skeleton yang berfungsi sebagai kerangka utama tampilan halaman situs web kita. Pembuatan skeleton ini bertujuan untuk memastikan bahwa desain situs web kita selalu konsisten dan memperkecil kemungkinan terjadinya redundansi kode. Cara pembuatan skeleton ini, adalah

+ Buat berkas #strong[base.html] pada direktori templates yang berada pada #strong[direktori utama (root folder)]. Berkas #strong[base.html] ini berfungsi sebagai template dasar yang digunakan sebagai kerangka umum untuk halaman web lainnya yang berada pada setiap aplikasi.

+ Di dalam #strong[base.html], letakkan #NormalTok("{% load static %}"); di bagian paling atas untuk memuat setiap static files yang didefinisikan pada berkas html

  #Skylighting(([#NormalTok("{% load static %}");],
  [#DataTypeTok("<!DOCTYPE");#NormalTok(" html");#DataTypeTok(">");],
  [#DataTypeTok("<");#KeywordTok("html");#OtherTok(" lang");#OperatorTok("=");#StringTok("\"en\"");#DataTypeTok(">");],
  [#DataTypeTok("<");#KeywordTok("head");#DataTypeTok(">");],
  [#NormalTok("    ");#DataTypeTok("<");#KeywordTok("meta");#OtherTok(" charset");#OperatorTok("=");#StringTok("\"UTF-8\"");#OtherTok(" ");#DataTypeTok("/>");],
  [#NormalTok("    ");#DataTypeTok("<");#KeywordTok("meta");#OtherTok(" name");#OperatorTok("=");#StringTok("\"viewport\"");#OtherTok(" content");#OperatorTok("=");#StringTok("\"width=device-width, initial-scale=1.0\"");#OtherTok(" ");#DataTypeTok("/>");],
  [#DataTypeTok("</");#KeywordTok("head");#DataTypeTok(">");],
  [#DataTypeTok("</");#KeywordTok("html");#DataTypeTok(">");],));

+ Letakkan setiap package yang akan sering digunakan di dalam #NormalTok("<head>");. Lalu, tambahkan #NormalTok("{% block meta %}{% endblock meta %}"); yang berguna untuk menambahkan metadata lainnya pada berkas html lain yang melakukan extend pada kerangka ini. Berikut contoh isinya:

  #Skylighting(([#DataTypeTok("<");#KeywordTok("head");#DataTypeTok(">");],
  [#NormalTok("    ");#DataTypeTok("<");#KeywordTok("meta");#OtherTok(" charset");#OperatorTok("=");#StringTok("\"UTF-8\"");#OtherTok(" ");#DataTypeTok("/>");],
  [#NormalTok("    ");#DataTypeTok("<");#KeywordTok("meta");#OtherTok(" name");#OperatorTok("=");#StringTok("\"viewport\"");#OtherTok(" content");#OperatorTok("=");#StringTok("\"width=device-width, initial-scale=1.0\"");#OtherTok(" ");#DataTypeTok("/>");],
  [#NormalTok("    ");#DataTypeTok("<");#KeywordTok("link");#OtherTok(" rel");#OperatorTok("=");#StringTok("\"preconnect\"");#OtherTok(" href");#OperatorTok("=");#StringTok("\"https://fonts.googleapis.com\"");#DataTypeTok(">");],
  [#NormalTok("    ");#DataTypeTok("<");#KeywordTok("link");#OtherTok(" rel");#OperatorTok("=");#StringTok("\"preconnect\"");#OtherTok(" href");#OperatorTok("=");#StringTok("\"https://fonts.gstatic.com\"");#OtherTok(" crossorigin");#DataTypeTok(">");],
  [#NormalTok("    ");#DataTypeTok("<");#KeywordTok("link");#OtherTok(" href");#OperatorTok("=");#StringTok("\"https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@500;700");#ErrorTok("&");#StringTok("display=swap\"");#OtherTok(" rel");#OperatorTok("=");#StringTok("\"stylesheet\"");#DataTypeTok(">");],
  [#NormalTok("    ");#DataTypeTok("<");#KeywordTok("link");#OtherTok(" rel");#OperatorTok("=");#StringTok("\"stylesheet\"");#OtherTok(" href");#OperatorTok("=");#StringTok("\"/static/css/style.css\"");#DataTypeTok(">");],
  [#NormalTok("    {% block meta %} {% endblock meta %}");],
  [#DataTypeTok("</");#KeywordTok("head");#DataTypeTok(">");],));

+ Pindahkan #NormalTok("<header>"); yang berguna untuk pembuatan navbar dan #NormalTok("<footer>"); yang berguna untuk pembuatan footer pada halaman web pada berkas #strong[index.html], lalu letakkan di dalam #NormalTok("<body>"); pada berkas #strong[base.html]. Setelah itu, pada #NormalTok("<body>"); di berkas #strong[base.html], tambahkan #NormalTok("{% block content %}{% endblock %}"); pada tag body yang nantinya berguna untuk mengisi konten untuk halaman webnya.

  #Skylighting(([#DataTypeTok("<");#KeywordTok("body");#DataTypeTok(">");],
  [#NormalTok("  ");#DataTypeTok("<");#KeywordTok("header");#OtherTok(" class");#OperatorTok("=");#StringTok("\"site-header\"");#DataTypeTok(">");],
  [#NormalTok("    ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"container\"");#DataTypeTok(">");],
  [#NormalTok("        ");#DataTypeTok("<");#KeywordTok("a");#OtherTok(" href");#OperatorTok("=");#StringTok("\"{% url 'main:show_main' %}\"");#OtherTok(" class");#OperatorTok("=");#StringTok("\"brand\"");#DataTypeTok(">");#NormalTok("{{ name }}");#DataTypeTok("</");#KeywordTok("a");#DataTypeTok(">");],
  [#NormalTok("        ");#DataTypeTok("<");#KeywordTok("nav");#DataTypeTok(">");],
  [#NormalTok("            ");#DataTypeTok("<");#KeywordTok("a");#OtherTok(" href");#OperatorTok("=");#StringTok("\"{% url 'main:show_main' %}\"");#DataTypeTok(">");#NormalTok("Profile");#DataTypeTok("</");#KeywordTok("a");#DataTypeTok(">");],
  [#NormalTok("            ");#DataTypeTok("<");#KeywordTok("a");#OtherTok(" href");#OperatorTok("=");#StringTok("\"{% url 'main:show_experience' %}\"");#DataTypeTok(">");#NormalTok("Experience");#DataTypeTok("</");#KeywordTok("a");#DataTypeTok(">");],
  [#NormalTok("            ");#DataTypeTok("<");#KeywordTok("a");#OtherTok(" href");#OperatorTok("=");#StringTok("\"{% url 'main:show_projects' %}\"");#DataTypeTok(">");#NormalTok("Projects");#DataTypeTok("</");#KeywordTok("a");#DataTypeTok(">");],
  [#NormalTok("        ");#DataTypeTok("</");#KeywordTok("nav");#DataTypeTok(">");],
  [#NormalTok("    ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
  [#NormalTok("  ");#DataTypeTok("</");#KeywordTok("header");#DataTypeTok(">");],
  [#NormalTok("  {% block content %} {% endblock content %}");],
  [],
  [#NormalTok("  ");#DataTypeTok("<");#KeywordTok("footer");#OtherTok(" class");#OperatorTok("=");#StringTok("\"site-footer\"");#DataTypeTok(">");],
  [#NormalTok("      ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"container\"");#DataTypeTok(">");],
  [#NormalTok("          ");#DataTypeTok("<");#KeywordTok("p");#DataTypeTok(">");#DecValTok("&copy;");#NormalTok(" 2026 {{ name }}. Fakultas Ilmu Komputer, Universitas Indonesia.");#DataTypeTok("</");#KeywordTok("p");#DataTypeTok(">");],
  [#NormalTok("      ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
  [#NormalTok("  ");#DataTypeTok("</");#KeywordTok("footer");#DataTypeTok(">");],
  [#DataTypeTok("</");#KeywordTok("body");#DataTypeTok(">");],));

+ Buka #strong[settings.py] yang ada pada direktori proyek (portofolio) dan carilah variabel #NormalTok("TEMPLATES");. Sesuaikan kode yang ada dengan potongan kode berikut agar berkas base.html terdeteksi sebagai berkas template.

  #Skylighting(([#NormalTok("  ...");],
  [#NormalTok("  TEMPLATES ");#OperatorTok("=");#NormalTok(" [");],
  [#NormalTok("      {");],
  [#NormalTok("          ");#StringTok("'BACKEND'");#NormalTok(": ");#StringTok("'django.template.backends.django.DjangoTemplates'");#NormalTok(",");],
  [#NormalTok("          ");#StringTok("'DIRS'");#NormalTok(": [BASE_DIR ");#OperatorTok("/");#NormalTok(" ");#StringTok("'templates'");#NormalTok("], ");#CommentTok("# Tambahkan konten baris ini");],
  [#NormalTok("          ");#StringTok("'APP_DIRS'");#NormalTok(": ");#VariableTok("True");#NormalTok(",");],
  [#NormalTok("          ...");],
  [#NormalTok("      }");],
  [#NormalTok("  ]");],
  [#NormalTok("  ...");],));

#block[
#callout(
body: 
[
Dalam beberapa kasus, #NormalTok("APP_DIRS"); pada konfigurasi #NormalTok("TEMPLATES"); kamu dapat bernilai False. Apabila nilainya False, kamu wajib mengubahnya menjadi True. Hal ini dilakukan agar templates milik aplikasi (contohnya main) lebih diprioritaskan daripada #strong[admin/base\_site.html] milik django.contrib.admin. Untuk informasi lebih lanjut, kamu dapat mengakses halaman #link("https://docs.djangoproject.com/en/6.1/ref/templates/api/#loading-templates")[ini].

]
, 
title: 
[
Catatan
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
#block[
#set enum(numbering: "1.", start: 6)
+ Pada berkas #strong[index.html] yang berada di direktori #strong[templates], ubahlah kode index.html dengan memasukkan setiap tag html pada body ke dalam block content. Contohnya sebagai berikut,

  #Skylighting(([#NormalTok("  {% extends 'base.html' %}");],
  [#NormalTok("  {% block content %}");],
  [#NormalTok("    ");#DataTypeTok("<");#KeywordTok("main");#DataTypeTok(">");],
  [#NormalTok("        ");#DataTypeTok("<");#KeywordTok("section");#OtherTok(" class");#OperatorTok("=");#StringTok("\"hero\"");#OtherTok(" id");#OperatorTok("=");#StringTok("\"profile\"");#DataTypeTok(">");],
  [#NormalTok("            ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"container hero-grid\"");#DataTypeTok(">");],
  [#NormalTok("                ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"hero-identity\"");#DataTypeTok(">");],
  [#NormalTok("                    ");#DataTypeTok("<");#KeywordTok("p");#OtherTok(" class");#OperatorTok("=");#StringTok("\"hero-kicker\"");#DataTypeTok(">");#NormalTok("Computer Science ");#DecValTok("&middot;");#NormalTok(" Universitas Indonesia");#DataTypeTok("</");#KeywordTok("p");#DataTypeTok(">");],
  [#NormalTok("                    ");#DataTypeTok("<");#KeywordTok("h1");#DataTypeTok(">");#NormalTok("{{ name }}");#DataTypeTok("</");#KeywordTok("h1");#DataTypeTok(">");],
  [#NormalTok("                ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
  [#NormalTok("                ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"hero-photo\"");#DataTypeTok(">");],
  [#NormalTok("                    ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"photo-block\"");#DataTypeTok("></");#KeywordTok("div");#DataTypeTok(">");],
  [#NormalTok("                    ");#DataTypeTok("<");#KeywordTok("img");#OtherTok(" class");#OperatorTok("=");#StringTok("\"avatar\"");#OtherTok(" src");#OperatorTok("=");#StringTok("\"/static/img/burhan.png\"");#OtherTok(" alt");#OperatorTok("=");#StringTok("\"Photo of {{ name }}\"");#DataTypeTok(">");],
  [#NormalTok("                ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
  [#NormalTok("                ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"hero-details\"");#DataTypeTok(">");],
  [#NormalTok("                    ");#DataTypeTok("<");#KeywordTok("p");#OtherTok(" class");#OperatorTok("=");#StringTok("\"bio\"");#DataTypeTok(">");#NormalTok("{{ bio }}");#DataTypeTok("</");#KeywordTok("p");#DataTypeTok(">");],
  [#NormalTok("                    ");#DataTypeTok("<");#KeywordTok("dl");#OtherTok(" class");#OperatorTok("=");#StringTok("\"meta-list\"");#DataTypeTok(">");],
  [#NormalTok("                        ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"meta-row\"");#DataTypeTok(">");],
  [#NormalTok("                            ");#DataTypeTok("<");#KeywordTok("dt");#DataTypeTok(">");#NormalTok("NPM");#DataTypeTok("</");#KeywordTok("dt");#DataTypeTok(">");],
  [#NormalTok("                            ");#DataTypeTok("<");#KeywordTok("dd");#DataTypeTok(">");#NormalTok("{{ npm }}");#DataTypeTok("</");#KeywordTok("dd");#DataTypeTok(">");],
  [#NormalTok("                        ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
  [#NormalTok("                        ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"meta-row\"");#DataTypeTok(">");],
  [#NormalTok("                            ");#DataTypeTok("<");#KeywordTok("dt");#DataTypeTok(">");#NormalTok("Program");#DataTypeTok("</");#KeywordTok("dt");#DataTypeTok(">");],
  [#NormalTok("                            ");#DataTypeTok("<");#KeywordTok("dd");#DataTypeTok(">");#NormalTok("{{ study_program }}");#DataTypeTok("</");#KeywordTok("dd");#DataTypeTok(">");],
  [#NormalTok("                        ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
  [#NormalTok("                    ");#DataTypeTok("</");#KeywordTok("dl");#DataTypeTok(">");],
  [#NormalTok("                    ");#DataTypeTok("<");#KeywordTok("ul");#OtherTok(" class");#OperatorTok("=");#StringTok("\"skills\"");#DataTypeTok(">");],
  [#NormalTok("                        ");#DataTypeTok("<");#KeywordTok("li");#DataTypeTok(">");#NormalTok("Programming Fundamentals");#DataTypeTok("</");#KeywordTok("li");#DataTypeTok(">");],
  [#NormalTok("                        ");#DataTypeTok("<");#KeywordTok("li");#DataTypeTok(">");#NormalTok("Java");#DataTypeTok("</");#KeywordTok("li");#DataTypeTok(">");],
  [#NormalTok("                        ");#DataTypeTok("<");#KeywordTok("li");#DataTypeTok(">");#NormalTok("Python");#DataTypeTok("</");#KeywordTok("li");#DataTypeTok(">");],
  [#NormalTok("                        ");#DataTypeTok("<");#KeywordTok("li");#DataTypeTok(">");#NormalTok("Data Structures");#DataTypeTok("</");#KeywordTok("li");#DataTypeTok(">");],
  [#NormalTok("                        ");#DataTypeTok("<");#KeywordTok("li");#DataTypeTok(">");#NormalTok("Teaching ");#DecValTok("&amp;");#NormalTok(" Mentoring");#DataTypeTok("</");#KeywordTok("li");#DataTypeTok(">");],
  [#NormalTok("                    ");#DataTypeTok("</");#KeywordTok("ul");#DataTypeTok(">");],
  [#NormalTok("                    ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"social-links\"");#DataTypeTok(">");],
  [#NormalTok("                        ");#DataTypeTok("<");#KeywordTok("a");#OtherTok(" href");#OperatorTok("=");#StringTok("\"https://github.com/\"");#OtherTok(" class");#OperatorTok("=");#StringTok("\"social-link\"");#DataTypeTok(">");#NormalTok("GitHub");#DataTypeTok("</");#KeywordTok("a");#DataTypeTok(">");],
  [#NormalTok("                        ");#DataTypeTok("<");#KeywordTok("a");#OtherTok(" href");#OperatorTok("=");#StringTok("\"https://linkedin.com/\"");#OtherTok(" class");#OperatorTok("=");#StringTok("\"social-link\"");#DataTypeTok(">");#NormalTok("LinkedIn");#DataTypeTok("</");#KeywordTok("a");#DataTypeTok(">");],
  [#NormalTok("                        ");#DataTypeTok("<");#KeywordTok("a");#OtherTok(" href");#OperatorTok("=");#StringTok("\"mailto:burhan@example.com\"");#OtherTok(" class");#OperatorTok("=");#StringTok("\"social-link\"");#DataTypeTok(">");#NormalTok("Email");#DataTypeTok("</");#KeywordTok("a");#DataTypeTok(">");],
  [#NormalTok("                    ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
  [#NormalTok("                ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
  [#NormalTok("            ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
  [#NormalTok("        ");#DataTypeTok("</");#KeywordTok("section");#DataTypeTok(">");],
  [#NormalTok("      ...");],
  [#NormalTok("    ");#DataTypeTok("</");#KeywordTok("main");#DataTypeTok(">");],
  [#NormalTok("  {% endblock content %}");],));
  Jika diperhatikan, berkas #strong[index.html] yang sebelumnya melakukan pendefinisian html dari awal, sekarang hanya berisi kontennya saja. Hal ini dikarenakan berkas index.html melakukan extend terhadap #strong[base.html] yang menjadi kerangka utama dari struktur html pada halaman web
]

#block[
#callout(
body: 
[
Baris-baris yang dikurung dalam #NormalTok("{% ... %}"); disebut dengan template tags Django. Baris-baris inilah yang akan berfungsi untuk memuat data secara dinamis dari Django ke HTML.

Pada contoh diatas, tag #NormalTok("{% block %}"); di Django digunakan untuk mendefinisikan area dalam template yang dapat diganti oleh template turunan. Template turunan akan extend template dasar, pada contoh ini #strong[base.html] dan mengganti konten di dalam block tersebut sesuai kebutuhan.

]
, 
title: 
[
Catatan
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
#block[
#callout(
body: 
[
Sekarang, kalian boleh menerapkan hal yang sama pada berkas html lainnya, seperti #strong[index.html] yang melakukan extend base.html #strong[\(template utama)] agar meminimalisir terjadinya redundansi kode.

]
, 
title: 
[
Tip
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]
== Tutorial: Implementasi Form & Data Delivery
<tutorial-implementasi-form-data-delivery>
Data delivery melibatkan kebutuhan untuk berkomunikasi antar client yang biasanya merupakan antarmuka yang dilihat pengguna dan server yang biasanya adalah backend yang mengelola database, pada implementasi kali ini, kita akan memanfaatkan library Form yang telah disediakan oleh Django untuk mengirim data ke server atau biasanya disebut #strong[request] dan menangkap balasan dari server atau biasanya disebut #strong[response].

=== Langkah 1: Implementasi Form
<langkah-1-implementasi-form>
Pada tugas 2, kamu diminta untuk membuat satu page untuk portfoliomu antara lain proyek, pendidikan, sertifikasi, atau bagian lain yang relevan. Kali ini, kita akan membuat konten tersebut dinamis. Pada tutorial ini saya akan menggunakan proyek sebagai contoh, tapi kalian bisa menyesuaikan dari apa yang telah dibaut di tutorial 2.

Pastikan kamu telah memiliki models untuk bagian baru dan sudah melakukan migration, disini konteksnya adalah project, seperti berikut:

#Skylighting(([#KeywordTok("class");#NormalTok(" Project(models.Model):");],
[#NormalTok("    ");#BuiltInTok("id");#NormalTok(" ");#OperatorTok("=");#NormalTok(" models.UUIDField(primary_key");#OperatorTok("=");#VariableTok("True");#NormalTok(", default");#OperatorTok("=");#NormalTok("uuid.uuid4, editable");#OperatorTok("=");#VariableTok("False");#NormalTok(")");],
[#NormalTok("    title ");#OperatorTok("=");#NormalTok(" models.CharField(max_length");#OperatorTok("=");#DecValTok("255");#NormalTok(")");],
[#NormalTok("    description ");#OperatorTok("=");#NormalTok(" models.TextField()");],
[#NormalTok("    tech_stack ");#OperatorTok("=");#NormalTok(" models.CharField(max_length");#OperatorTok("=");#DecValTok("255");#NormalTok(")");],
[#NormalTok("    project_url ");#OperatorTok("=");#NormalTok(" models.URLField(blank");#OperatorTok("=");#VariableTok("True");#NormalTok(")");],
[#NormalTok("    project_image_url ");#OperatorTok("=");#NormalTok(" models.URLField(blank");#OperatorTok("=");#VariableTok("True");#NormalTok(", max_length");#OperatorTok("=");#DecValTok("500");#NormalTok(")");],
[],
[#NormalTok("    ");#KeywordTok("def");#NormalTok(" ");#FunctionTok("__str__");#NormalTok("(");#VariableTok("self");#NormalTok("):");],
[#NormalTok("        ");#ControlFlowTok("return");#NormalTok(" ");#VariableTok("self");#NormalTok(".title");],));
Pada #NormalTok("main/"); kita akan membuat file baru bernama #NormalTok("forms.py"); dan buat class #NormalTok("ProjectForm");:

#Skylighting(([#ImportTok("from");#NormalTok(" django.forms ");#ImportTok("import");#NormalTok(" ModelForm, TextInput, Textarea, URLInput");],
[],
[#ImportTok("from");#NormalTok(" main.models ");#ImportTok("import");#NormalTok(" Project");],
[],
[#KeywordTok("class");#NormalTok(" ProjectForm(ModelForm):");],
[#NormalTok("    ");#KeywordTok("class");#NormalTok(" Meta:");],
[#NormalTok("        model ");#OperatorTok("=");#NormalTok(" Project");],
[#NormalTok("        fields ");#OperatorTok("=");#NormalTok(" [");],
[#NormalTok("            ");#StringTok("\"title\"");#NormalTok(",");],
[#NormalTok("            ");#StringTok("\"description\"");#NormalTok(",");],
[#NormalTok("            ");#StringTok("\"tech_stack\"");#NormalTok(",");],
[#NormalTok("            ");#StringTok("\"project_url\"");#NormalTok(",");],
[#NormalTok("            ");#StringTok("\"project_image_url\"");#NormalTok(",");],
[#NormalTok("        ]");],
[],
[#NormalTok("        widgets ");#OperatorTok("=");#NormalTok(" {");],
[#NormalTok("            ");#StringTok("\"title\"");#NormalTok(": TextInput(");],
[#NormalTok("                attrs");#OperatorTok("=");#NormalTok("{");],
[#NormalTok("                    ");#StringTok("\"class\"");#NormalTok(": ");#StringTok("\"form-input\"");#NormalTok(",");],
[#NormalTok("                    ");#StringTok("\"placeholder\"");#NormalTok(": ");#StringTok("\"Portfolio Website\"");#NormalTok(",");],
[#NormalTok("                    ");#StringTok("\"maxlength\"");#NormalTok(": ");#DecValTok("255");#NormalTok(",");],
[#NormalTok("                }");],
[#NormalTok("            ),");],
[#NormalTok("            ");#StringTok("\"description\"");#NormalTok(": Textarea(");],
[#NormalTok("                attrs");#OperatorTok("=");#NormalTok("{");],
[#NormalTok("                    ");#StringTok("\"class\"");#NormalTok(": ");#StringTok("\"form-input\"");#NormalTok(",");],
[#NormalTok("                    ");#StringTok("\"placeholder\"");#NormalTok(": ");#StringTok("\"Ceritakan Proyekmu\"");#NormalTok(",");],
[#NormalTok("                    ");#StringTok("\"rows\"");#NormalTok(": ");#DecValTok("3");#NormalTok(",");],
[#NormalTok("                }");],
[#NormalTok("            ),");],
[#NormalTok("            ");#StringTok("\"tech_stack\"");#NormalTok(": TextInput(");],
[#NormalTok("                attrs");#OperatorTok("=");#NormalTok("{");],
[#NormalTok("                    ");#StringTok("\"class\"");#NormalTok(": ");#StringTok("\"form-input\"");#NormalTok(",");],
[#NormalTok("                    ");#StringTok("\"placeholder\"");#NormalTok(": ");#StringTok("\"Django, Python, HTML, CSS\"");#NormalTok(",");],
[#NormalTok("                }");],
[#NormalTok("            ),");],
[#NormalTok("            ");#StringTok("\"project_url\"");#NormalTok(": URLInput(");],
[#NormalTok("                attrs");#OperatorTok("=");#NormalTok("{");],
[#NormalTok("                    ");#StringTok("\"class\"");#NormalTok(": ");#StringTok("\"form-input\"");#NormalTok(",");],
[#NormalTok("                    ");#StringTok("\"placeholder\"");#NormalTok(": ");#StringTok("\"https://github.com/kakBurhan/burhanquestv4\"");#NormalTok(",");],
[#NormalTok("                }");],
[#NormalTok("            ),");],
[#NormalTok("            ");#StringTok("\"project_image_url\"");#NormalTok(": URLInput(");],
[#NormalTok("                attrs");#OperatorTok("=");#NormalTok("{");],
[#NormalTok("                    ");#StringTok("\"class\"");#NormalTok(": ");#StringTok("\"form-input\"");#NormalTok(",");],
[#NormalTok("                    ");#StringTok("\"placeholder\"");#NormalTok(": ");#StringTok("\"https://drive.google.com/thumbnail?id=...&sz=w1000\"");#NormalTok(",");],
[#NormalTok("                }");],
[#NormalTok("            ),");],
[#NormalTok("        }");],));
#NormalTok("ModelForm"); adalah builtins library yang telah disediakan oleh Django untuk membuat boilerplate suatu form. Struktur dari form sendiri dapat dikustomasi menggunakan metadata atau class #NormalTok("Meta");.

#block[
#callout(
body: 
[
#strong[Boilerplate] dalam dunia pemrogramman adalah istilah bagi kode standar yang sifatnya reusable dengan sedikit/tidak ada perubahan.

]
, 
title: 
[
Catatan
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
#strong[Penjelasan Kode]

- #NormalTok("model"); digunakan untuk menentukan model Django yang menjadi sumber data dan struktur dari #NormalTok("ModelForm");. Field pada form akan dibuat berdasarkan field yang terdapat pada model tersebut.
- #NormalTok("fields"); digunakan untuk menentukan field model yang ingin ditampilkan pada form. Field dapat ditulis secara eksplisit, seperti #NormalTok("[\"title\", \"description\"]");, atau menggunakan #NormalTok("\"__all__\""); untuk menampilkan seluruh field yang tersedia.
- #NormalTok("widgets"); digunakan untuk mengatur tampilan dan jenis elemen HTML yang digunakan oleh setiap field pada form. Pada kode di atas, #NormalTok("TextInput"); digunakan untuk field teks satu baris, #NormalTok("Textarea"); digunakan untuk field deskripsi yang membutuhkan area teks lebih besar, dan #NormalTok("URLInput"); digunakan untuk field yang berisi URL. Atribut di dalam #NormalTok("attrs");, seperti #NormalTok("class");, #NormalTok("placeholder");, #NormalTok("maxlength");, dan #NormalTok("rows");, digunakan untuk mengatur styling, teks petunjuk, batas jumlah karakter, serta tinggi area input.

Setelah membuat Form, kita perlu membuat views untuk nantiya dapat menggunakan form tersebut. pergi ke #NormalTok("main/views.py"); lalu buat fungsi berikut:

#Skylighting(([#KeywordTok("def");#NormalTok(" create_project(request):");],
[#NormalTok("    form ");#OperatorTok("=");#NormalTok(" ProjectForm(request.POST ");#KeywordTok("or");#NormalTok(" ");#VariableTok("None");#NormalTok(")");],
[],
[#NormalTok("    ");#ControlFlowTok("if");#NormalTok(" request.method ");#OperatorTok("==");#NormalTok(" ");#StringTok("\"POST\"");#NormalTok(" ");#KeywordTok("and");#NormalTok(" form.is_valid():");],
[#NormalTok("        form.save()");],
[#NormalTok("        messages.success(request, ");#StringTok("\"Proyek baru berhasil ditambahkan!\"");#NormalTok(")");],
[#NormalTok("        ");#ControlFlowTok("return");#NormalTok(" redirect(");#StringTok("\"main:show_projects\"");#NormalTok(")");],
[],
[#NormalTok("    context ");#OperatorTok("=");#NormalTok(" {");],
[#NormalTok("        ");#StringTok("\"name\"");#NormalTok(": ");#StringTok("\"Burhan\"");#NormalTok(",");],
[#NormalTok("        ");#StringTok("\"form\"");#NormalTok(": form,");],
[#NormalTok("    }");],
[#NormalTok("    ");#ControlFlowTok("return");#NormalTok(" render(request, ");#StringTok("\"projects_form.html\"");#NormalTok(", context)");],
[],));
#strong[Penjelasan Kode]

- #NormalTok("ProjectForm(request.POST or None)"); digunakan untuk mentrigger class #NormalTok("ProjectForm"); dengan #NormalTok("request.POST"); yang nantinya akan dikirim dengan tag HTML yaitu #NormalTok("<form method=\"post\">");
- #NormalTok("form.save()"); digunakan untuk menyimpan value yang telah dimasukkan pengguna lewat form ke database.
- #NormalTok("messages.success(request, ...)"); digunakan untuk mengirim pesan ke client untuk dapat ditampilkan.
- #NormalTok("redirect(\"main:show_projects\")"); akan berjalan setelah form berhasil disimpan, halaman website akan diarahkan ke halaman projects yang bisa dilihat.

Lalu, pergi ke #NormalTok("urls.py");, tambahkan hal berikut:

#Skylighting(([#ImportTok("from");#NormalTok(" main.views ");#ImportTok("import");#NormalTok(" (");],
[#NormalTok("   ...");],
[#NormalTok("   create_project");],
[#NormalTok(")");],
[],
[#NormalTok("urlpatterns ");#OperatorTok("=");#NormalTok(" [");],
[#NormalTok("    ...");],
[#NormalTok("    path(");#StringTok("\"projects/add/\"");#NormalTok(", create_project, name");#OperatorTok("=");#StringTok("\"create_project\"");#NormalTok("),");],
[#NormalTok("]");],));
Sekarang kita akan membuat tampilan dari halaman Project Form, buat file baru pada folder templates, yaitu #NormalTok("projects_form.html");, isi dengan kode berikut:

#Skylighting(([#NormalTok("{% extends \"base.html\" %}");],
[#NormalTok("{% block meta %}");],
[#NormalTok("    ");#DataTypeTok("<");#KeywordTok("title");#DataTypeTok(">");#NormalTok("Add Project - {{ name }}");#DataTypeTok("</");#KeywordTok("title");#DataTypeTok(">");],
[#NormalTok("{% endblock meta %}");],
[#NormalTok("{% block content %}");],
[#NormalTok("    ");#DataTypeTok("<");#KeywordTok("main");#DataTypeTok(">");],
[#NormalTok("        ");#DataTypeTok("<");#KeywordTok("section");#OtherTok(" class");#OperatorTok("=");#StringTok("\"experience-section\"");#DataTypeTok(">");],
[#NormalTok("            ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"container\"");#DataTypeTok(">");],
[#NormalTok("                ");#DataTypeTok("<");#KeywordTok("h1");#DataTypeTok(">");#NormalTok("Add New Projects");#DataTypeTok("</");#KeywordTok("h1");#DataTypeTok(">");],
[#NormalTok("                ");#DataTypeTok("<");#KeywordTok("form");#OtherTok(" method");#OperatorTok("=");#StringTok("\"post\"");],
[#OtherTok("                      action");#OperatorTok("=");#StringTok("\"{% url 'main:create_project' %}\"");],
[#OtherTok("                      class");#OperatorTok("=");#StringTok("\"project-form\"");#DataTypeTok(">");],
[#NormalTok("                    {% csrf_token %}");],
[#NormalTok("                    {% for field in form %}");],
[#NormalTok("                        ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"form-group\"");#DataTypeTok(">");],
[#NormalTok("                            ");#DataTypeTok("<");#KeywordTok("label");#OtherTok(" for");#OperatorTok("=");#StringTok("\"{{ field.id_for_label }}\"");#DataTypeTok(">");#NormalTok("{{ field.label }}");#DataTypeTok("</");#KeywordTok("label");#DataTypeTok(">");],
[#NormalTok("                            {{ field }}");],
[#NormalTok("                            {% for error in field.errors %}");],
[#NormalTok("                                ");#DataTypeTok("<");#KeywordTok("p");#OtherTok(" class");#OperatorTok("=");#StringTok("\"form-error\"");#DataTypeTok(">");#NormalTok("{{ error }}");#DataTypeTok("</");#KeywordTok("p");#DataTypeTok(">");],
[#NormalTok("                            {% endfor %}");],
[#NormalTok("                        ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
[#NormalTok("                    {% endfor %}");],
[#NormalTok("                    ");#DataTypeTok("<");#KeywordTok("button");#OtherTok(" type");#OperatorTok("=");#StringTok("\"submit\"");#OtherTok(" class");#OperatorTok("=");#StringTok("\"button\"");#DataTypeTok(">");#NormalTok("Tambah Project");#DataTypeTok("</");#KeywordTok("button");#DataTypeTok(">");],
[#NormalTok("                    ");#DataTypeTok("<");#KeywordTok("a");#OtherTok(" href");#OperatorTok("=");#StringTok("\"{% url 'main:show_projects' %}\"");#OtherTok(" class");#OperatorTok("=");#StringTok("\"button button-secondary\"");#DataTypeTok(">");#NormalTok("Batal");#DataTypeTok("</");#KeywordTok("a");#DataTypeTok(">");],
[#NormalTok("                ");#DataTypeTok("</");#KeywordTok("form");#DataTypeTok(">");],
[#NormalTok("            ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
[#NormalTok("        ");#DataTypeTok("</");#KeywordTok("section");#DataTypeTok(">");],
[#NormalTok("    ");#DataTypeTok("</");#KeywordTok("main");#DataTypeTok(">");],
[#NormalTok("{% endblock content %}");],));
Dan pada #NormalTok("style.css");:

#Skylighting(([#FunctionTok(".project-form");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("width");#CharTok(":");#NormalTok(" ");#DecValTok("100");#DataTypeTok("%");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("max-width");#CharTok(":");#NormalTok(" ");#DecValTok("100");#DataTypeTok("%");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("margin-top");#CharTok(":");#NormalTok(" ");#DecValTok("1.5");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".form-group");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("margin-bottom");#CharTok(":");#NormalTok(" ");#DecValTok("1.25");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".form-group");#NormalTok(" label {");],
[#NormalTok("    ");#KeywordTok("display");#CharTok(":");#NormalTok(" ");#DecValTok("block");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("margin-bottom");#CharTok(":");#NormalTok(" ");#DecValTok("0.4");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("font-weight");#CharTok(":");#NormalTok(" ");#DecValTok("700");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".form-group");#NormalTok(" input");#OperatorTok(",");],
[#FunctionTok(".form-group");#NormalTok(" textarea {");],
[#NormalTok("    ");#KeywordTok("width");#CharTok(":");#NormalTok(" ");#DecValTok("100");#DataTypeTok("%");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("box-sizing");#CharTok(":");#NormalTok(" ");#DecValTok("border-box");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("padding");#CharTok(":");#NormalTok(" ");#DecValTok("0.7");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("border");#CharTok(":");#NormalTok(" ");#DecValTok("1");#DataTypeTok("px");#NormalTok(" ");#DecValTok("solid");#NormalTok(" ");#FunctionTok("var(");#VariableTok("--accent");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("border-radius");#CharTok(":");#NormalTok(" ");#FunctionTok("var(");#VariableTok("--radius");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("font");#CharTok(":");#NormalTok(" ");#BuiltInTok("inherit");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("transition");#CharTok(":");],
[#NormalTok("        ");#DecValTok("border-color 0.2");#DataTypeTok("s");#NormalTok(" ");#DecValTok("ease");#OperatorTok(",");],
[#NormalTok("        ");#DecValTok("outline-color 0.2");#DataTypeTok("s");#NormalTok(" ");#DecValTok("ease");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".form-group");#NormalTok(" input");#InformationTok(":focus");#OperatorTok(",");],
[#FunctionTok(".form-group");#NormalTok(" textarea");#InformationTok(":focus");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("outline");#CharTok(":");#NormalTok(" ");#DecValTok("2");#DataTypeTok("px");#NormalTok(" ");#DecValTok("solid");#NormalTok(" ");#FunctionTok("var(");#VariableTok("--accent");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("border-color");#CharTok(":");#NormalTok(" ");#FunctionTok("var(");#VariableTok("--accent");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".form-error");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("color");#CharTok(":");#NormalTok(" ");#ConstantTok("#b42318");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("font-size");#CharTok(":");#NormalTok(" ");#DecValTok("0.85");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("margin-top");#CharTok(":");#NormalTok(" ");#DecValTok("0.35");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".button");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("display");#CharTok(":");#NormalTok(" ");#DecValTok("inline-block");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("height");#CharTok(":");#NormalTok(" ");#DecValTok("fit-content");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("border");#CharTok(":");#NormalTok(" ");#DecValTok("0");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("border-radius");#CharTok(":");#NormalTok(" ");#FunctionTok("var(");#VariableTok("--radius");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("padding");#CharTok(":");#NormalTok(" ");#DecValTok("0.65");#DataTypeTok("rem");#NormalTok(" ");#DecValTok("1");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("background");#CharTok(":");#NormalTok(" ");#FunctionTok("var(");#VariableTok("--accent");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("color");#CharTok(":");#NormalTok(" ");#ConstantTok("white");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("cursor");#CharTok(":");#NormalTok(" ");#DecValTok("pointer");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("font");#CharTok(":");#NormalTok(" ");#BuiltInTok("inherit");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("font-weight");#CharTok(":");#NormalTok(" ");#DecValTok("700");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("text-decoration");#CharTok(":");#NormalTok(" ");#DecValTok("none");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".button-secondary");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("background");#CharTok(":");#NormalTok(" ");#FunctionTok("var(");#VariableTok("--ink");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("}");],));
Jika sudah, kalian dapat menjalankan django, dan masuk ke URL dengan route #NormalTok("/projects/add");. Tampilan jika berhasil akan seperti berikut:

#figure([
#box(image("../img/tutorial-3/form-project.png"))
], caption: figure.caption(
position: bottom, 
[
Tampilan Form Project
]), 
kind: "quarto-float-fig", 
supplement: "Gambar", 
)


#block[
#callout(
body: 
[
#strong[Google Drive Link]

Jika kamu ingin menambahkan gambar pada project, upload gambar tersebut ke Google Drive terlebih dahulu. Setelah itu, klik kanan pada gambar, pilih #strong[Share], lalu ubah aksesnya menjadi #strong[Anyone with the link] sebagai #strong[Viewer].

Gunakan ID file dari link Google Drive tersebut untuk membuat URL thumbnail dengan format berikut:

#Skylighting(([#NormalTok("https://drive.google.com/thumbnail?id=FILE_ID&sz=w1000");],));
Sebagai contoh, jika link Google Drive yang kamu miliki adalah:

#Skylighting(([#NormalTok("https://drive.google.com/file/d/1qbdofeOckPIbbj77svGTLNa2Ps8ogMET/view?usp=sharing");],));
Maka URL gambar yang dimasukkan ke form adalah:

#Skylighting(([#NormalTok("https://drive.google.com/thumbnail?id=1qbdofeOckPIbbj77svGTLNa2Ps8ogMET&sz=w1000");],));
Pastikan kamu memasukkan URL thumbnail tersebut ke field #strong[Project image url] pada form.

]
, 
title: 
[
Penting
]
, 
background_color: 
rgb("#f7dddc")
, 
icon_color: 
rgb("#CC1914")
, 
icon: 
fa-exclamation()
, 
body_background_color: 
white
)
]
=== Langkah 2: Menyesuaikan dengan Tugas 2
<langkah-2-menyesuaikan-dengan-tugas-2>
Setelah tugas dua, kamu diharapkan memiliki page HTML baru, disini sebagai contoh, saya telah memiliki #NormalTok("project.html");, isi kodenya adalah sebagai berikut:

#block[
#callout(
body: 
[
#strong[Kode Contoh] - Kode dan implementasi yang akan saya jelaskan adalah contoh, sesuaikan dengan hasil dari tugas anda, jangan melakukan kopi paste kode-kode ini jika page yang anda implementasikan berbeda!

]
, 
title: 
[
Penting
]
, 
background_color: 
rgb("#f7dddc")
, 
icon_color: 
rgb("#CC1914")
, 
icon: 
fa-exclamation()
, 
body_background_color: 
white
)
]
#Skylighting(([#DataTypeTok("<!DOCTYPE");#NormalTok(" html");#DataTypeTok(">");],
[#DataTypeTok("<");#KeywordTok("html");#OtherTok(" lang");#OperatorTok("=");#StringTok("\"en\"");#DataTypeTok(">");],
[#DataTypeTok("<");#KeywordTok("head");#DataTypeTok(">");],
[#NormalTok("    ");#DataTypeTok("<");#KeywordTok("meta");#OtherTok(" charset");#OperatorTok("=");#StringTok("\"UTF-8\"");#DataTypeTok(">");],
[#NormalTok("    ");#DataTypeTok("<");#KeywordTok("meta");#OtherTok(" name");#OperatorTok("=");#StringTok("\"viewport\"");#OtherTok(" content");#OperatorTok("=");#StringTok("\"width=device-width, initial-scale=1.0\"");#DataTypeTok(">");],
[#NormalTok("    ");#DataTypeTok("<");#KeywordTok("title");#DataTypeTok(">");#NormalTok("Projects - {{ name }}");#DataTypeTok("</");#KeywordTok("title");#DataTypeTok(">");],
[#NormalTok("    ");#DataTypeTok("<");#KeywordTok("link");#OtherTok(" rel");#OperatorTok("=");#StringTok("\"preconnect\"");#OtherTok(" href");#OperatorTok("=");#StringTok("\"https://fonts.googleapis.com\"");#DataTypeTok(">");],
[#NormalTok("    ");#DataTypeTok("<");#KeywordTok("link");#OtherTok(" rel");#OperatorTok("=");#StringTok("\"preconnect\"");#OtherTok(" href");#OperatorTok("=");#StringTok("\"https://fonts.gstatic.com\"");#OtherTok(" crossorigin");#DataTypeTok(">");],
[#NormalTok("    ");#DataTypeTok("<");#KeywordTok("link");#OtherTok(" href");#OperatorTok("=");#StringTok("\"https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@500;700");#ErrorTok("&");#StringTok("display=swap\"");#OtherTok(" rel");#OperatorTok("=");#StringTok("\"stylesheet\"");#DataTypeTok(">");],
[#NormalTok("    ");#DataTypeTok("<");#KeywordTok("link");#OtherTok(" rel");#OperatorTok("=");#StringTok("\"stylesheet\"");#OtherTok(" href");#OperatorTok("=");#StringTok("\"/static/css/style.css\"");#DataTypeTok(">");],
[#DataTypeTok("</");#KeywordTok("head");#DataTypeTok(">");],
[#DataTypeTok("<");#KeywordTok("body");#DataTypeTok(">");],
[#NormalTok("    ");#DataTypeTok("<");#KeywordTok("header");#OtherTok(" class");#OperatorTok("=");#StringTok("\"site-header\"");#DataTypeTok(">");],
[#NormalTok("        ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"container\"");#DataTypeTok(">");],
[#NormalTok("        ");#DataTypeTok("<");#KeywordTok("a");#OtherTok(" href");#OperatorTok("=");#StringTok("\"{% url 'main:show_main' %}\"");#OtherTok(" class");#OperatorTok("=");#StringTok("\"brand\"");#DataTypeTok(">");#NormalTok("{{ name }}");#DataTypeTok("</");#KeywordTok("a");#DataTypeTok(">");],
[#NormalTok("            ");#DataTypeTok("<");#KeywordTok("nav");#DataTypeTok(">");],
[#NormalTok("                ");#DataTypeTok("<");#KeywordTok("a");#OtherTok(" href");#OperatorTok("=");#StringTok("\"{% url 'main:show_main' %}\"");#DataTypeTok(">");#NormalTok("Profile");#DataTypeTok("</");#KeywordTok("a");#DataTypeTok(">");],
[#NormalTok("                ");#DataTypeTok("<");#KeywordTok("a");#OtherTok(" href");#OperatorTok("=");#StringTok("\"{% url 'main:show_experience' %}\"");#DataTypeTok(">");#NormalTok("Experience");#DataTypeTok("</");#KeywordTok("a");#DataTypeTok(">");],
[#NormalTok("                ");#DataTypeTok("<");#KeywordTok("a");#OtherTok(" href");#OperatorTok("=");#StringTok("\"{% url 'main:show_projects' %}\"");#DataTypeTok(">");#NormalTok("Projects");#DataTypeTok("</");#KeywordTok("a");#DataTypeTok(">");],
[#NormalTok("            ");#DataTypeTok("</");#KeywordTok("nav");#DataTypeTok(">");],
[#NormalTok("        ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
[#NormalTok("    ");#DataTypeTok("</");#KeywordTok("header");#DataTypeTok(">");],
[],
[#NormalTok("    ");#DataTypeTok("<");#KeywordTok("main");#DataTypeTok(">");],
[#NormalTok("        ");#DataTypeTok("<");#KeywordTok("section");#OtherTok(" class");#OperatorTok("=");#StringTok("\"experience-section\"");#OtherTok(" id");#OperatorTok("=");#StringTok("\"experience\"");#DataTypeTok(">");],
[#NormalTok("            ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"container\"");#DataTypeTok(">");],
[#NormalTok("            ");#DataTypeTok("<");#KeywordTok("p");#OtherTok(" class");#OperatorTok("=");#StringTok("\"section-kicker\"");#DataTypeTok(">");#NormalTok("Karya yang saya bangun");#DataTypeTok("</");#KeywordTok("p");#DataTypeTok(">");],
[#NormalTok("            ");#DataTypeTok("<");#KeywordTok("h1");#DataTypeTok(">");#NormalTok("Projects");#DataTypeTok("</");#KeywordTok("h1");#DataTypeTok(">");],
[],
[#NormalTok("                ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"experience-grid\"");#DataTypeTok(">");],
[#NormalTok("                    {% for project in project_list %}");],
[#NormalTok("                        ");#DataTypeTok("<");#KeywordTok("article");#OtherTok(" class");#OperatorTok("=");#StringTok("\"experience-card\"");#DataTypeTok(">");],
[#NormalTok("                            ");#DataTypeTok("<");#KeywordTok("span");#OtherTok(" class");#OperatorTok("=");#StringTok("\"experience-category\"");#DataTypeTok(">");#NormalTok("{{ project.tech_stack }}");#DataTypeTok("</");#KeywordTok("span");#DataTypeTok(">");],
[#NormalTok("                            ");#DataTypeTok("<");#KeywordTok("h2");#DataTypeTok(">");#NormalTok("{{ project.title }}");#DataTypeTok("</");#KeywordTok("h2");#DataTypeTok(">");],
[#NormalTok("                            ");#DataTypeTok("<");#KeywordTok("p");#OtherTok(" class");#OperatorTok("=");#StringTok("\"experience-description\"");#DataTypeTok(">");#NormalTok("{{ project.description }}");#DataTypeTok("</");#KeywordTok("p");#DataTypeTok(">");],
[],
[#NormalTok("                            {% if project.project_url %}");],
[#NormalTok("                                ");#DataTypeTok("<");#KeywordTok("p");#OtherTok(" class");#OperatorTok("=");#StringTok("\"experience-status\"");#DataTypeTok(">");],
[#NormalTok("                                    ");#DataTypeTok("<");#KeywordTok("a");#OtherTok(" href");#OperatorTok("=");#StringTok("\"{{ project.project_url }}\"");#DataTypeTok(">");#NormalTok("Lihat proyek");#DataTypeTok("</");#KeywordTok("a");#DataTypeTok(">");],
[#NormalTok("                                ");#DataTypeTok("</");#KeywordTok("p");#DataTypeTok(">");],
[#NormalTok("                            {% endif %}");],
[#NormalTok("                        ");#DataTypeTok("</");#KeywordTok("article");#DataTypeTok(">");],
[#NormalTok("                    {% empty %}");],
[#NormalTok("                        ");#DataTypeTok("<");#KeywordTok("p");#OtherTok(" class");#OperatorTok("=");#StringTok("\"empty-state\"");#DataTypeTok(">");],
[#NormalTok("                            Belum ada proyek yang ditambahkan.");],
[#NormalTok("                        ");#DataTypeTok("</");#KeywordTok("p");#DataTypeTok(">");],
[#NormalTok("                    {% endfor %}");],
[#NormalTok("                ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
[#NormalTok("            ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
[#NormalTok("        ");#DataTypeTok("</");#KeywordTok("section");#DataTypeTok(">");],
[#NormalTok("    ");#DataTypeTok("</");#KeywordTok("main");#DataTypeTok(">");],
[],
[#NormalTok("    ");#DataTypeTok("<");#KeywordTok("footer");#OtherTok(" class");#OperatorTok("=");#StringTok("\"site-footer\"");#DataTypeTok(">");],
[#NormalTok("        ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"container\"");#DataTypeTok(">");],
[#NormalTok("            ");#DataTypeTok("<");#KeywordTok("p");#DataTypeTok(">");#DecValTok("&copy;");#NormalTok(" 2026 {{ name }}. Fakultas Ilmu Komputer, Universitas Indonesia.");#DataTypeTok("</");#KeywordTok("p");#DataTypeTok(">");],
[#NormalTok("        ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
[#NormalTok("    ");#DataTypeTok("</");#KeywordTok("footer");#DataTypeTok(">");],
[#DataTypeTok("</");#KeywordTok("body");#DataTypeTok(">");],
[#DataTypeTok("</");#KeywordTok("html");#DataTypeTok(">");],));
Karena kita sudah membuat kerangka pada #NormalTok("base.html");, sekarang kita tinggal extends base html tersebut dengan #NormalTok("project.html"); agar elemen elemen seperti #strong[Navbar] dan #strong[Footer] dapat ditampilkan tanpa dibuat dua kali (redundant).

#Skylighting(([#NormalTok("{% extends \"base.html\" %}");],
[#NormalTok("{% block meta %}");],
[#NormalTok("    ");#DataTypeTok("<");#KeywordTok("title");#DataTypeTok(">");#NormalTok("Projects - {{ name }}");#DataTypeTok("</");#KeywordTok("title");#DataTypeTok(">");],
[#NormalTok("{% endblock meta %}");],
[#NormalTok("{% block content %}");],
[#ErrorTok("<!");#CommentTok(" -- Isi HTML kamu -- >");],
[#NormalTok("{% endblock content %}");],));
Isi konten dengan html dari #NormalTok("project.html"); yang dimulai dari tag #NormalTok("<main>"); dan keseluruhan isi konten pada tag tersebut. Tag diluar main tidak perlu kita tulis kembali karena telah diimplementasikan pada #NormalTok("base.html"); dan kita hanya tinggal extend saja seperti inheritance.

Lalu pada #NormalTok("main/views.py"); saya telah melakukan implementasi seperti ini:

#Skylighting(([#NormalTok("...");],
[#KeywordTok("def");#NormalTok(" show_projects(request):");],
[#NormalTok("    context ");#OperatorTok("=");#NormalTok(" {");],
[#NormalTok("        ");#StringTok("\"name\"");#NormalTok(": ");#StringTok("\"Burhan\"");#NormalTok(",");],
[#NormalTok("        ");#StringTok("\"project_list\"");#NormalTok(": Project.objects.");#BuiltInTok("all");#NormalTok("(),");],
[#NormalTok("    }");],
[#NormalTok("    ");#ControlFlowTok("return");#NormalTok(" render(request, ");#StringTok("\"project.html\"");#NormalTok(", context)");],));
dan pada #NormalTok("main/urls.py"); seperti ini:

#Skylighting(([#ImportTok("from");#NormalTok(" django.urls ");#ImportTok("import");#NormalTok(" path");],
[],
[#ImportTok("from");#NormalTok(" main.views ");#ImportTok("import");#NormalTok(" show_main, show_experience, show_projects");],
[],
[#NormalTok("app_name ");#OperatorTok("=");#NormalTok(" ");#StringTok("\"main\"");],
[],
[#NormalTok("urlpatterns ");#OperatorTok("=");#NormalTok(" [");],
[#NormalTok("    path(");#StringTok("\"\"");#NormalTok(", show_main, name");#OperatorTok("=");#StringTok("\"show_main\"");#NormalTok("),");],
[#NormalTok("    path(");#StringTok("\"experience/\"");#NormalTok(", show_experience, name");#OperatorTok("=");#StringTok("\"show_experience\"");#NormalTok("),");],
[#NormalTok("    path(");#StringTok("\"projects/\"");#NormalTok(", show_projects, name");#OperatorTok("=");#StringTok("\"show_projects\"");#NormalTok("),");],
[#NormalTok("]");],));
Cek kembali apakah kode pada portfolio kamu memiliki struktur yang serupa agar memudahkan dalam mengikuti implementasi berikutnya!

=== Langkah 3: Implementasi Data Delivery dengan JSON
<langkah-3-implementasi-data-delivery-dengan-json>
Sebagai gambaran, tampilan awal dari halaman projects yang saya buat adalah sebagai berikut:

#figure([
#box(image("../img/tutorial-3/projects-ui.png"))
], caption: figure.caption(
position: bottom, 
[
Tampilan Halaman Projects
]), 
kind: "quarto-float-fig", 
supplement: "Gambar", 
)


Sekarang kita akan merubah data delivery yang ada fungsi #NormalTok("show_projects"); yang awalnya langsung mengambil dari database, menjadi menggunakan JSON. pada #NormalTok("main/views.py"); buat fungsi #NormalTok("get_projects_json");:

#Skylighting(([#KeywordTok("def");#NormalTok(" get_projects_json(request):");],
[#NormalTok("    title_query ");#OperatorTok("=");#NormalTok(" request.GET.get(");#StringTok("\"title\"");#NormalTok(", ");#StringTok("\"\"");#NormalTok(").strip()");],
[#NormalTok("    projects ");#OperatorTok("=");#NormalTok(" Project.objects.");#BuiltInTok("all");#NormalTok("()");],
[],
[#NormalTok("    ");#ControlFlowTok("if");#NormalTok(" title_query:");],
[#NormalTok("        projects ");#OperatorTok("=");#NormalTok(" projects.");#BuiltInTok("filter");#NormalTok("(title__icontains");#OperatorTok("=");#NormalTok("title_query)");],
[],
[#NormalTok("    projects_json ");#OperatorTok("=");#NormalTok(" serializers.serialize(");#StringTok("\"json\"");#NormalTok(", projects)");],
[#NormalTok("    ");#ControlFlowTok("return");#NormalTok(" HttpResponse(projects_json, content_type");#OperatorTok("=");#StringTok("\"application/json\"");#NormalTok(")");],));
#strong[Penjelasan Kode]

- #NormalTok("request.GET.get(\"title\", \"\").strip()"); Mengambil query yang ditulis pada parameter, biasanya akan terlihat seperti #NormalTok("/example?title=HelloWorld");.
- #NormalTok("serializers.serialize(\"json\", projects)"); Mengubah object #NormalTok("projects"); menjadi format JSON.
- #NormalTok("HttpResponse(projects_json, content_type=\"application/json\")"); mengembalikan output dari suatu fungsi sebagai respons HTTP untuk dikirim ke client.

#block[
#callout(
body: 
[
#strong[Gimana Cara Melihat Implementasi Fungsi yang Dipanggil dari Library?]

- #strong[Neovim], kalian bisa mengarahkan kursor ke fungsi yang ingin diidentifikasi, lalu ketik #NormalTok("gd");, nanti akan diarahkan ke isi dari implementasi fungsi tersebut.
- #strong[VScode], kalian bisa menekan #NormalTok("Ctrl");, lalu klik fungsi yang ingin diidentifikasi
- #strong[IDE Lain], cari di google hehe.

]
, 
title: 
[
Tip
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]
#block[
#callout(
body: 
[
#strong[FUNFACT: Kenapa Harus HttpResponse?] - Server memiliki cara untuk berkomunikasi dengan website, dan cara yang terstandarisasi dengan protokol HTTP, protokol HTTP merupakan protokol standar untuk berinteraksi (request and response) antara server dengan client (web browser), methode interaksinya biasanya menggunakan GET, POST, PUT, PATCH, & DELETE. Terdapat metode interaksi lain seperti Websocket, SMTP, dan lainnya yang akan kalian pelajari di jarkom :D.

]
, 
title: 
[
Catatan
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
Pada #NormalTok("urls.py");, daftarkan fungsi #NormalTok("get_projects_json"); yang telah dibuat pada urlpatterns. Saya menulis seperti ini #NormalTok("path(\"api/projects/\", get_projects_json, name=\"get_projects_json\")");, penggunaan #NormalTok("/api"); sebagai notasi untuk membedakan mana endpoint yang digunakan oleh client, mana yang digunakan oleh server.

Setelah kamu mendaftarakn ke #NormalTok("urls.py");, kita dapat memanggilnya dalam bentuk API menggunakan Postman.

#figure([
#box(image("../img/tutorial-3/projects-api.png"))
], caption: figure.caption(
position: bottom, 
[
Tampilan Response API Projects dengan Postman
]), 
kind: "quarto-float-fig", 
supplement: "Gambar", 
)


#figure([
#box(image("../img/tutorial-3/projects-api-search.png"))
], caption: figure.caption(
position: bottom, 
[
Tampilan Response API Projects dengan Postman dan Filter by Title
]), 
kind: "quarto-float-fig", 
supplement: "Gambar", 
)


#block[
#callout(
body: 
[
#strong[Bagaimana Kalau Formatnya XML?] - Kontrak tidak harus JSON, salah satu contoh kontrak lainnya adalah XML, coba kalian ubah serializenya dari yang "json" ke "xml" dan #NormalTok("content_type=\"application/xml\""); dan lihat response yang diberikan seperti apa

]
, 
title: 
[
Catatan
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
Setelah berhasil, kita coba ubah implementasi dari fungsi #NormalTok("show_projects"); seolah olah menerima response berupa JSON dan di deserialize untuk menjadikan tipe data yang dikenali python

#Skylighting(([#KeywordTok("def");#NormalTok(" show_projects(request):");],
[#NormalTok("    json_response ");#OperatorTok("=");#NormalTok(" get_projects_json(request)");],
[],
[#NormalTok("    projects ");#OperatorTok("=");#NormalTok(" serializers.deserialize(");],
[#NormalTok("        ");#StringTok("\"json\"");#NormalTok(",");],
[#NormalTok("        json_response.content.decode(");#StringTok("\"utf-8\"");#NormalTok("),");],
[#NormalTok("    )");],
[#NormalTok("    projects ");#OperatorTok("=");#NormalTok(" [project.");#BuiltInTok("object");#NormalTok(" ");#ControlFlowTok("for");#NormalTok(" project ");#KeywordTok("in");#NormalTok(" projects]");],
[#NormalTok("    title_query ");#OperatorTok("=");#NormalTok(" request.GET.get(");#StringTok("\"title\"");#NormalTok(", ");#StringTok("\"\"");#NormalTok(").strip()");],
[],
[#NormalTok("    context ");#OperatorTok("=");#NormalTok(" {");],
[#NormalTok("        ");#StringTok("\"name\"");#NormalTok(": ");#StringTok("\"Burhan\"");#NormalTok(",");],
[#NormalTok("        ");#StringTok("\"project_list\"");#NormalTok(": projects,");],
[#NormalTok("        ");#StringTok("\"title_query\"");#NormalTok(": title_query,");],
[#NormalTok("    }");],
[#NormalTok("    ");#ControlFlowTok("return");#NormalTok(" render(request, ");#StringTok("\"project.html\"");#NormalTok(", context)");],));
Inti dari kode diatas adalah merubah implementasi yang awalnya langsung mengambil dari database, sekarang mengambil dari JSON terlebih dahulu, lalu di deserialize agar formatnya sesuai dengan tipedata python, lalu dikirim lagi ke halaman #NormalTok("project.html");.

#block[
#callout(
body: 
[
#strong[Terlihat redundant? Memang!] - Karena ini adalah contoh implementasi yang seharusnya dilakukan ketika kalian ingin mengimplementasikan aplikasi yang memiliki client dan server dengan repository yang berbeda atau implementasi menggunakan #NormalTok("fetch()"); javascript.

]
, 
title: 
[
Catatan
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
Sebelum kita mengimplementasikan semua fungsi ini ke client, saya ingin membuat fungsi #NormalTok("delete_projects"); terlebih dahulu untuk memudahkan nantinya untuk menghapus project. Implementasi pada #NormalTok("main/views.py");

#Skylighting(([#KeywordTok("def");#NormalTok(" delete_project(request, project_id):");],
[#NormalTok("    project ");#OperatorTok("=");#NormalTok(" get_object_or_404(Project, pk");#OperatorTok("=");#NormalTok("project_id)");],
[],
[#NormalTok("    ");#ControlFlowTok("if");#NormalTok(" request.method ");#OperatorTok("==");#NormalTok(" ");#StringTok("\"POST\"");#NormalTok(":");],
[#NormalTok("        project.delete()");],
[#NormalTok("        messages.success(request, ");#StringTok("\"Project berhasil dihapus!\"");#NormalTok(")");],
[#NormalTok("        ");#ControlFlowTok("return");#NormalTok(" redirect(");#StringTok("\"main:show_projects\"");#NormalTok(")");],
[],
[#NormalTok("    ");#ControlFlowTok("return");#NormalTok(" redirect(");#StringTok("\"main:show_projects\"");#NormalTok(")");],));
Tambahkan path ini pada #NormalTok("urlpatterns"); di #NormalTok("main/urls.py"); yaitu: \`\`\`path("projects//delete/",delete\_project,name="delete\_project")\`\`\`\`\`

Sekarang, pada folder templates, buat folder #NormalTok("components/"); dan tambahkan file bernama #NormalTok("project_delete_modal.html");:

#Skylighting(([#DataTypeTok("<");#KeywordTok("p");#OtherTok(" class");#OperatorTok("=");#StringTok("\"experience-status\"");#DataTypeTok(">");],
[#NormalTok("    ");#DataTypeTok("<");#KeywordTok("button");#OtherTok(" type");#OperatorTok("=");#StringTok("\"button\"");],
[#OtherTok("            class");#OperatorTok("=");#StringTok("\"button button-danger\"");],
[#OtherTok("            popovertarget");#OperatorTok("=");#StringTok("\"delete-project-{{ project.id }}\"");],
[#OtherTok("            aria-label");#OperatorTok("=");#StringTok("\"Hapus {{ project.title }}\"");],
[#OtherTok("            title");#OperatorTok("=");#StringTok("\"Hapus proyek\"");#DataTypeTok(">");],
[#NormalTok("        Hapus Proyek");],
[#NormalTok("    ");#DataTypeTok("</");#KeywordTok("button");#DataTypeTok(">");],
[#DataTypeTok("</");#KeywordTok("p");#DataTypeTok(">");],
[#DataTypeTok("<");#KeywordTok("div");#OtherTok(" id");#OperatorTok("=");#StringTok("\"delete-project-{{ project.id }}\"");],
[#OtherTok("     class");#OperatorTok("=");#StringTok("\"project-delete-modal\"");],
[#OtherTok("     popover");#OperatorTok("=");#StringTok("\"auto\"");],
[#OtherTok("     role");#OperatorTok("=");#StringTok("\"dialog\"");],
[#OtherTok("     aria-modal");#OperatorTok("=");#StringTok("\"true\"");],
[#OtherTok("     aria-labelledby");#OperatorTok("=");#StringTok("\"delete-project-title-{{ project.id }}\"");#DataTypeTok(">");],
[#NormalTok("    ");#DataTypeTok("<");#KeywordTok("button");#OtherTok(" type");#OperatorTok("=");#StringTok("\"button\"");],
[#OtherTok("            class");#OperatorTok("=");#StringTok("\"project-delete-modal__backdrop\"");],
[#OtherTok("            popovertarget");#OperatorTok("=");#StringTok("\"delete-project-{{ project.id }}\"");],
[#OtherTok("            popovertargetaction");#OperatorTok("=");#StringTok("\"hide\"");],
[#OtherTok("            aria-label");#OperatorTok("=");#StringTok("\"Tutup konfirmasi hapus\"");#DataTypeTok("></");#KeywordTok("button");#DataTypeTok(">");],
[#NormalTok("    ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"project-delete-modal__content\"");#DataTypeTok(">");],
[#NormalTok("        ");#DataTypeTok("<");#KeywordTok("button");#OtherTok(" type");#OperatorTok("=");#StringTok("\"button\"");],
[#OtherTok("                class");#OperatorTok("=");#StringTok("\"project-delete-modal__close\"");],
[#OtherTok("                popovertarget");#OperatorTok("=");#StringTok("\"delete-project-{{ project.id }}\"");],
[#OtherTok("                popovertargetaction");#OperatorTok("=");#StringTok("\"hide\"");],
[#OtherTok("                aria-label");#OperatorTok("=");#StringTok("\"Tutup konfirmasi hapus\"");#DataTypeTok(">");#NormalTok("×");#DataTypeTok("</");#KeywordTok("button");#DataTypeTok(">");],
[#NormalTok("        ");#DataTypeTok("<");#KeywordTok("h2");#OtherTok(" id");#OperatorTok("=");#StringTok("\"delete-project-title-{{ project.id }}\"");#DataTypeTok(">");#NormalTok("Hapus Projek?");#DataTypeTok("</");#KeywordTok("h2");#DataTypeTok(">");],
[#NormalTok("        ");#DataTypeTok("<");#KeywordTok("p");#DataTypeTok(">");],
[#NormalTok("            Apakah Anda yakin ingin menghapus");],
[#NormalTok("            ");#DataTypeTok("<");#KeywordTok("strong");#DataTypeTok(">");#NormalTok("{{ project.title }}");#DataTypeTok("</");#KeywordTok("strong");#DataTypeTok(">");#NormalTok("?");],
[#NormalTok("        ");#DataTypeTok("</");#KeywordTok("p");#DataTypeTok(">");],
[#NormalTok("        ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"project-delete-modal__actions\"");#DataTypeTok(">");],
[#NormalTok("            ");#DataTypeTok("<");#KeywordTok("button");#OtherTok(" type");#OperatorTok("=");#StringTok("\"button\"");],
[#OtherTok("                    class");#OperatorTok("=");#StringTok("\"button button-secondary\"");],
[#OtherTok("                    popovertarget");#OperatorTok("=");#StringTok("\"delete-project-{{ project.id }}\"");],
[#OtherTok("                    popovertargetaction");#OperatorTok("=");#StringTok("\"hide\"");#DataTypeTok(">");#NormalTok("Batal");#DataTypeTok("</");#KeywordTok("button");#DataTypeTok(">");],
[#NormalTok("            ");#DataTypeTok("<");#KeywordTok("form");#OtherTok(" method");#OperatorTok("=");#StringTok("\"post\"");#OtherTok(" action");#OperatorTok("=");#StringTok("\"{% url 'main:delete_project' project.id %}\"");#DataTypeTok(">");],
[#NormalTok("                {% csrf_token %}");],
[#NormalTok("                ");#DataTypeTok("<");#KeywordTok("button");#OtherTok(" type");#OperatorTok("=");#StringTok("\"submit\"");#OtherTok(" class");#OperatorTok("=");#StringTok("\"button button-danger\"");#DataTypeTok(">");#NormalTok("Ya, Hapus");#DataTypeTok("</");#KeywordTok("button");#DataTypeTok(">");],
[#NormalTok("            ");#DataTypeTok("</");#KeywordTok("form");#DataTypeTok(">");],
[#NormalTok("        ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
[#NormalTok("    ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
[#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],));
Dan ubah isi dari #NormalTok("project.html"); menjadi seperti berikut:

#Skylighting(([#NormalTok("{% extends \"base.html\" %}");],
[#NormalTok("{% block meta %}");],
[#NormalTok("    ");#DataTypeTok("<");#KeywordTok("title");#DataTypeTok(">");#NormalTok("Projects - {{ name }}");#DataTypeTok("</");#KeywordTok("title");#DataTypeTok(">");],
[#NormalTok("{% endblock meta %}");],
[#NormalTok("{% block content %}");],
[#NormalTok("    ");#DataTypeTok("<");#KeywordTok("main");#DataTypeTok(">");],
[#NormalTok("        ");#DataTypeTok("<");#KeywordTok("section");#OtherTok(" class");#OperatorTok("=");#StringTok("\"experience-section\"");#OtherTok(" id");#OperatorTok("=");#StringTok("\"experience\"");#DataTypeTok(">");],
[#NormalTok("            ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"container\"");#DataTypeTok(">");],
[#NormalTok("                ");#DataTypeTok("<");#KeywordTok("p");#OtherTok(" class");#OperatorTok("=");#StringTok("\"section-kicker\"");#DataTypeTok(">");#NormalTok("Karya yang saya bangun");#DataTypeTok("</");#KeywordTok("p");#DataTypeTok(">");],
[#NormalTok("                ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"project-header\"");#DataTypeTok(">");],
[#NormalTok("                    ");#DataTypeTok("<");#KeywordTok("h1");#DataTypeTok(">");#NormalTok("Projects");#DataTypeTok("</");#KeywordTok("h1");#DataTypeTok(">");],
[#NormalTok("                    ");#DataTypeTok("<");#KeywordTok("a");#OtherTok(" href");#OperatorTok("=");#StringTok("\"{% url 'main:create_project' %}\"");],
[#OtherTok("                       class");#OperatorTok("=");#StringTok("\"button project-add-button\"");#DataTypeTok(">");],
[#NormalTok("                        ");#DataTypeTok("<");#KeywordTok("span");#OtherTok(" aria-hidden");#OperatorTok("=");#StringTok("\"true\"");#DataTypeTok(">");#NormalTok("+");#DataTypeTok("</");#KeywordTok("span");#DataTypeTok(">");],
[#NormalTok("                        Tambah Proyek");],
[#NormalTok("                    ");#DataTypeTok("</");#KeywordTok("a");#DataTypeTok(">");],
[#NormalTok("                ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
[#NormalTok("                ");#DataTypeTok("<");#KeywordTok("form");#OtherTok(" method");#OperatorTok("=");#StringTok("\"get\"");],
[#OtherTok("                      action");#OperatorTok("=");#StringTok("\"{% url 'main:show_projects' %}\"");],
[#OtherTok("                      class");#OperatorTok("=");#StringTok("\"project-search\"");#DataTypeTok(">");],
[#NormalTok("                    ");#DataTypeTok("<");#KeywordTok("input");#OtherTok(" type");#OperatorTok("=");#StringTok("\"search\"");],
[#OtherTok("                           name");#OperatorTok("=");#StringTok("\"title\"");],
[#OtherTok("                           value");#OperatorTok("=");#StringTok("\"{{ title_query }}\"");],
[#OtherTok("                           placeholder");#OperatorTok("=");#StringTok("\"Cari berdasarkan nama proyek\"");],
[#OtherTok("                           class");#OperatorTok("=");#StringTok("\"project-search__input\"");],
[#OtherTok("                           aria-label");#OperatorTok("=");#StringTok("\"Cari berdasarkan nama proyek\"");#DataTypeTok(">");],
[#NormalTok("                    ");#DataTypeTok("<");#KeywordTok("button");#OtherTok(" type");#OperatorTok("=");#StringTok("\"submit\"");#OtherTok(" class");#OperatorTok("=");#StringTok("\"button\"");#DataTypeTok(">");#NormalTok("Cari");#DataTypeTok("</");#KeywordTok("button");#DataTypeTok(">");],
[#NormalTok("                ");#DataTypeTok("</");#KeywordTok("form");#DataTypeTok(">");],
[#NormalTok("                ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"experience-grid project-grid\"");#DataTypeTok(">");],
[#NormalTok("                    {% for project in project_list %}");],
[#NormalTok("                        ");#DataTypeTok("<");#KeywordTok("article");#OtherTok(" class");#OperatorTok("=");#StringTok("\"experience-card\"");#DataTypeTok(">");],
[#NormalTok("                            {% if project.project_image_url %}");],
[#NormalTok("                                ");#DataTypeTok("<");#KeywordTok("img");#OtherTok(" src");#OperatorTok("=");#StringTok("\"{{ project.project_image_url }}\"");],
[#OtherTok("                                     alt");#OperatorTok("=");#StringTok("\"Gambar {{ project.title }}\"");],
[#OtherTok("                                     class");#OperatorTok("=");#StringTok("\"project-image\"");#DataTypeTok(">");],
[#NormalTok("                            {% endif %}");],
[#NormalTok("                            ");#DataTypeTok("<");#KeywordTok("h2");#DataTypeTok(">");#NormalTok("{{ project.title }}");#DataTypeTok("</");#KeywordTok("h2");#DataTypeTok(">");],
[#NormalTok("                            ");#DataTypeTok("<");#KeywordTok("span");#OtherTok(" class");#OperatorTok("=");#StringTok("\"experience-category\"");#DataTypeTok(">");#NormalTok("{{ project.tech_stack }}");#DataTypeTok("</");#KeywordTok("span");#DataTypeTok(">");],
[#NormalTok("                            ");#DataTypeTok("<");#KeywordTok("p");#OtherTok(" class");#OperatorTok("=");#StringTok("\"experience-description\"");#DataTypeTok(">");#NormalTok("{{ project.description }}");#DataTypeTok("</");#KeywordTok("p");#DataTypeTok(">");],
[#NormalTok("                            ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"project-card-actions\"");#DataTypeTok(">");],
[#NormalTok("                                ");#DataTypeTok("<");#KeywordTok("div");#OtherTok(" class");#OperatorTok("=");#StringTok("\"project-actions\"");#DataTypeTok(">");],
[#NormalTok("                                    {% if project.project_url %}");],
[#NormalTok("                                        ");#DataTypeTok("<");#KeywordTok("a");#OtherTok(" href");#OperatorTok("=");#StringTok("\"{{ project.project_url }}\"");#OtherTok(" class");#OperatorTok("=");#StringTok("\"button\"");#DataTypeTok(">");#NormalTok("Lihat Project");#DataTypeTok("</");#KeywordTok("a");#DataTypeTok(">");],
[#NormalTok("                                    {% endif %}");],
[#NormalTok("                                    {% include \"components/project_delete_modal.html\" with project=project %}");],
[#NormalTok("                                ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
[#NormalTok("                            ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
[#NormalTok("                        ");#DataTypeTok("</");#KeywordTok("article");#DataTypeTok(">");],
[#NormalTok("                    {% empty %}");],
[#NormalTok("                        {% if title_query %}");],
[#NormalTok("                            ");#DataTypeTok("<");#KeywordTok("p");#OtherTok(" class");#OperatorTok("=");#StringTok("\"empty-state\"");#DataTypeTok(">");#NormalTok("Tidak ada proyek dengan nama tersebut.");#DataTypeTok("</");#KeywordTok("p");#DataTypeTok(">");],
[#NormalTok("                        {% else %}");],
[#NormalTok("                            ");#DataTypeTok("<");#KeywordTok("p");#OtherTok(" class");#OperatorTok("=");#StringTok("\"empty-state\"");#DataTypeTok(">");#NormalTok("Belum ada proyek yang ditambahkan.");#DataTypeTok("</");#KeywordTok("p");#DataTypeTok(">");],
[#NormalTok("                        {% endif %}");],
[#NormalTok("                    {% endfor %}");],
[#NormalTok("                ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
[#NormalTok("            ");#DataTypeTok("</");#KeywordTok("div");#DataTypeTok(">");],
[#NormalTok("        ");#DataTypeTok("</");#KeywordTok("section");#DataTypeTok(">");],
[#NormalTok("    ");#DataTypeTok("</");#KeywordTok("main");#DataTypeTok(">");],
[#NormalTok("{% endblock content %}");],));
Serta perubahan pada #NormalTok("style.css"); adalah sebagai berikut:

#Skylighting(([#NormalTok("...");],
[#CommentTok("/* projects */");],
[],
[#FunctionTok(".project-header");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("width");#CharTok(":");#NormalTok(" ");#DecValTok("100");#DataTypeTok("%");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("display");#CharTok(":");#NormalTok(" ");#DecValTok("flex");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("justify-content");#CharTok(":");#NormalTok(" ");#DecValTok("space-between");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("align-items");#CharTok(":");#NormalTok(" ");#DecValTok("center");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("gap");#CharTok(":");#NormalTok(" ");#DecValTok("1");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("margin-bottom");#CharTok(":");#NormalTok(" ");#DecValTok("1.5");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-grid");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("grid-template-columns");#CharTok(":");#NormalTok(" ");#FunctionTok("repeat(");#DecValTok("2");#OperatorTok(",");#NormalTok(" ");#FunctionTok("minmax(");#DecValTok("0");#OperatorTok(",");#NormalTok(" ");#DecValTok("1");#DataTypeTok("fr");#FunctionTok("))");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-grid");#NormalTok(" ");#FunctionTok(".experience-card");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("display");#CharTok(":");#NormalTok(" ");#DecValTok("flex");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("flex-direction");#CharTok(":");#NormalTok(" ");#DecValTok("column");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-image");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("display");#CharTok(":");#NormalTok(" ");#DecValTok("block");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("width");#CharTok(":");#NormalTok(" ");#DecValTok("100");#DataTypeTok("%");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("height");#CharTok(":");#NormalTok(" ");#BuiltInTok("auto");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("border");#CharTok(":");#NormalTok(" ");#DecValTok("1");#DataTypeTok("px");#NormalTok(" ");#DecValTok("solid");#NormalTok(" ");#ConstantTok("black");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("border-radius");#CharTok(":");#NormalTok(" ");#FunctionTok("var(");#VariableTok("--radius");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-header");#NormalTok(" h1 {");],
[#NormalTok("    ");#KeywordTok("margin-bottom");#CharTok(":");#NormalTok(" ");#DecValTok("0");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-add-button");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("display");#CharTok(":");#NormalTok(" ");#DecValTok("inline-flex");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("align-items");#CharTok(":");#NormalTok(" ");#DecValTok("center");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("gap");#CharTok(":");#NormalTok(" ");#DecValTok("0.45");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-add-button");#NormalTok(" span {");],
[#NormalTok("    ");#KeywordTok("font-size");#CharTok(":");#NormalTok(" ");#DecValTok("1.25");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("line-height");#CharTok(":");#NormalTok(" ");#DecValTok("1");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-search");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("display");#CharTok(":");#NormalTok(" ");#DecValTok("flex");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("gap");#CharTok(":");#NormalTok(" ");#DecValTok("0.75");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("margin-bottom");#CharTok(":");#NormalTok(" ");#DecValTok("1.5");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-search__input");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("width");#CharTok(":");#NormalTok(" ");#DecValTok("100");#DataTypeTok("%");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("min-width");#CharTok(":");#NormalTok(" ");#DecValTok("0");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("padding");#CharTok(":");#NormalTok(" ");#DecValTok("0.7");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("border");#CharTok(":");#NormalTok(" ");#DecValTok("1");#DataTypeTok("px");#NormalTok(" ");#DecValTok("solid");#NormalTok(" ");#FunctionTok("var(");#VariableTok("--line");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("border-radius");#CharTok(":");#NormalTok(" ");#FunctionTok("var(");#VariableTok("--radius");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("background");#CharTok(":");#NormalTok(" ");#ConstantTok("#fff");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("color");#CharTok(":");#NormalTok(" ");#FunctionTok("var(");#VariableTok("--ink");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("font");#CharTok(":");#NormalTok(" ");#BuiltInTok("inherit");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-search__input");#InformationTok(":focus");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("outline");#CharTok(":");#NormalTok(" ");#DecValTok("2");#DataTypeTok("px");#NormalTok(" ");#DecValTok("solid");#NormalTok(" ");#FunctionTok("var(");#VariableTok("--accent");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("border-color");#CharTok(":");#NormalTok(" ");#FunctionTok("var(");#VariableTok("--accent");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-actions");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("display");#CharTok(":");#NormalTok(" ");#DecValTok("flex");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("align-items");#CharTok(":");#NormalTok(" ");#DecValTok("center");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("flex-wrap");#CharTok(":");#NormalTok(" ");#DecValTok("wrap");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("gap");#CharTok(":");#NormalTok(" ");#DecValTok("20");#DataTypeTok("px");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("margin-top");#CharTok(":");#NormalTok(" ");#DecValTok("1");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-actions");#NormalTok(" ");#FunctionTok(".button");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("font-size");#CharTok(":");#NormalTok(" ");#DecValTok("0.85");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("font-weight");#CharTok(":");#NormalTok(" ");#DecValTok("600");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-card-actions");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("display");#CharTok(":");#NormalTok(" ");#DecValTok("flex");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("flex-direction");#CharTok(":");#NormalTok(" ");#DecValTok("column");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("margin-top");#CharTok(":");#NormalTok(" ");#BuiltInTok("auto");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".hide");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("display");#CharTok(":");#NormalTok(" ");#DecValTok("none");#NormalTok(" ");#AttributeTok("!important");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-actions");#NormalTok(" ");#FunctionTok(".experience-status");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("margin-top");#CharTok(":");#NormalTok(" ");#DecValTok("0");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-delete-modal");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("display");#CharTok(":");#NormalTok(" ");#DecValTok("none");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("position");#CharTok(":");#NormalTok(" ");#DecValTok("fixed");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("inset");#CharTok(":");#NormalTok(" ");#DecValTok("0");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("width");#CharTok(":");#NormalTok(" ");#DecValTok("100");#DataTypeTok("%");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("height");#CharTok(":");#NormalTok(" ");#DecValTok("100");#DataTypeTok("%");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("max-width");#CharTok(":");#NormalTok(" ");#DecValTok("none");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("max-height");#CharTok(":");#NormalTok(" ");#DecValTok("none");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("margin");#CharTok(":");#NormalTok(" ");#DecValTok("0");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("padding");#CharTok(":");#NormalTok(" ");#DecValTok("1");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("border");#CharTok(":");#NormalTok(" ");#DecValTok("0");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("background");#CharTok(":");#NormalTok(" ");#DecValTok("transparent");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("z-index");#CharTok(":");#NormalTok(" ");#DecValTok("10");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("align-items");#CharTok(":");#NormalTok(" ");#DecValTok("center");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("justify-content");#CharTok(":");#NormalTok(" ");#DecValTok("center");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-delete-modal");#InformationTok(":popover-open");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("display");#CharTok(":");#NormalTok(" ");#DecValTok("flex");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-delete-modal__backdrop");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("position");#CharTok(":");#NormalTok(" ");#DecValTok("absolute");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("inset");#CharTok(":");#NormalTok(" ");#DecValTok("0");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("width");#CharTok(":");#NormalTok(" ");#DecValTok("100");#DataTypeTok("%");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("height");#CharTok(":");#NormalTok(" ");#DecValTok("100");#DataTypeTok("%");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("border");#CharTok(":");#NormalTok(" ");#DecValTok("0");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("padding");#CharTok(":");#NormalTok(" ");#DecValTok("0");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("background");#CharTok(":");#NormalTok(" ");#FunctionTok("rgba(");#DecValTok("28");#OperatorTok(",");#NormalTok(" ");#DecValTok("25");#OperatorTok(",");#NormalTok(" ");#DecValTok("23");#OperatorTok(",");#NormalTok(" ");#DecValTok("0.58");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("cursor");#CharTok(":");#NormalTok(" ");#DecValTok("default");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-delete-modal__content");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("position");#CharTok(":");#NormalTok(" ");#DecValTok("relative");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("z-index");#CharTok(":");#NormalTok(" ");#DecValTok("1");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("width");#CharTok(":");#NormalTok(" ");#FunctionTok("min(");#DecValTok("100");#DataTypeTok("%");#OperatorTok(",");#NormalTok(" ");#DecValTok("480");#DataTypeTok("px");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("padding");#CharTok(":");#NormalTok(" ");#DecValTok("1.5");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("background");#CharTok(":");#NormalTok(" ");#FunctionTok("var(");#VariableTok("--paper");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("border");#CharTok(":");#NormalTok(" ");#DecValTok("1");#DataTypeTok("px");#NormalTok(" ");#DecValTok("solid");#NormalTok(" ");#FunctionTok("var(");#VariableTok("--line");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("border-radius");#CharTok(":");#NormalTok(" ");#FunctionTok("var(");#VariableTok("--radius");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("box-shadow");#CharTok(":");#NormalTok(" ");#DecValTok("0");#NormalTok(" ");#DecValTok("1");#DataTypeTok("rem");#NormalTok(" ");#DecValTok("3");#DataTypeTok("rem");#NormalTok(" ");#FunctionTok("rgba(");#DecValTok("28");#OperatorTok(",");#NormalTok(" ");#DecValTok("25");#OperatorTok(",");#NormalTok(" ");#DecValTok("23");#OperatorTok(",");#NormalTok(" ");#DecValTok("0.22");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-delete-modal__content");#NormalTok(" h2 {");],
[#NormalTok("    ");#KeywordTok("margin");#CharTok(":");#NormalTok(" ");#DecValTok("0");#NormalTok(" ");#DecValTok("0");#NormalTok(" ");#DecValTok("0.75");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("font-family");#CharTok(":");],
[#NormalTok("        ");#StringTok("\"Space Grotesk\"");#OperatorTok(",");],
[#NormalTok("        ");#DecValTok("-apple-system");#OperatorTok(",");],
[#NormalTok("        ");#DecValTok("sans-serif");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("font-size");#CharTok(":");#NormalTok(" ");#DecValTok("1.5");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-delete-modal__close");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("position");#CharTok(":");#NormalTok(" ");#DecValTok("absolute");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("top");#CharTok(":");#NormalTok(" ");#DecValTok("1");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("right");#CharTok(":");#NormalTok(" ");#DecValTok("1");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("border");#CharTok(":");#NormalTok(" ");#DecValTok("0");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("padding");#CharTok(":");#NormalTok(" ");#DecValTok("0");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("background");#CharTok(":");#NormalTok(" ");#DecValTok("transparent");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("color");#CharTok(":");#NormalTok(" ");#FunctionTok("var(");#VariableTok("--text-muted");#FunctionTok(")");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("font-size");#CharTok(":");#NormalTok(" ");#DecValTok("1.8");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("line-height");#CharTok(":");#NormalTok(" ");#DecValTok("1");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("cursor");#CharTok(":");#NormalTok(" ");#DecValTok("pointer");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#FunctionTok(".project-delete-modal__actions");#NormalTok(" {");],
[#NormalTok("    ");#KeywordTok("display");#CharTok(":");#NormalTok(" ");#DecValTok("flex");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("justify-content");#CharTok(":");#NormalTok(" ");#DecValTok("flex-end");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("gap");#CharTok(":");#NormalTok(" ");#DecValTok("0.75");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("margin-top");#CharTok(":");#NormalTok(" ");#DecValTok("1.5");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("}");],
[],
[#ImportTok("@media");#NormalTok(" ");#FunctionTok("(");#KeywordTok("max-width");#CharTok(":");#NormalTok(" ");#DecValTok("600");#DataTypeTok("px");#FunctionTok(")");#NormalTok(" {");],
[#NormalTok("    ");#FunctionTok(".project-header");#NormalTok(" {");],
[#NormalTok("        ");#KeywordTok("align-items");#CharTok(":");#NormalTok(" ");#DecValTok("flex-start");#OperatorTok(";");],
[#NormalTok("        ");#KeywordTok("flex-direction");#CharTok(":");#NormalTok(" ");#DecValTok("column");#OperatorTok(";");],
[#NormalTok("    }");],
[],
[#NormalTok("    ");#FunctionTok(".project-add-button");#NormalTok(" {");],
[#NormalTok("        ");#KeywordTok("width");#CharTok(":");#NormalTok(" ");#DecValTok("100");#DataTypeTok("%");#OperatorTok(";");],
[#NormalTok("        ");#KeywordTok("justify-content");#CharTok(":");#NormalTok(" ");#DecValTok("center");#OperatorTok(";");],
[#NormalTok("    }");],
[],
[#NormalTok("    ");#FunctionTok(".project-search");#NormalTok(" {");],
[#NormalTok("        ");#KeywordTok("flex-direction");#CharTok(":");#NormalTok(" ");#DecValTok("column");#OperatorTok(";");],
[#NormalTok("    }");],
[],
[#NormalTok("    ");#FunctionTok(".project-search");#NormalTok(" ");#FunctionTok(".button");#NormalTok(" {");],
[#NormalTok("        ");#KeywordTok("width");#CharTok(":");#NormalTok(" ");#DecValTok("100");#DataTypeTok("%");#OperatorTok(";");],
[#NormalTok("    }");],
[],
[#NormalTok("    ");#FunctionTok(".project-delete-modal");#NormalTok(" {");],
[#NormalTok("        ");#KeywordTok("align-items");#CharTok(":");#NormalTok(" ");#DecValTok("flex-end");#OperatorTok(";");],
[#NormalTok("        ");#KeywordTok("padding");#CharTok(":");#NormalTok(" ");#DecValTok("0");#OperatorTok(";");],
[#NormalTok("    }");],
[],
[#NormalTok("    ");#FunctionTok(".project-delete-modal__content");#NormalTok(" {");],
[#NormalTok("        ");#KeywordTok("width");#CharTok(":");#NormalTok(" ");#DecValTok("100");#DataTypeTok("%");#OperatorTok(";");],
[#NormalTok("        ");#KeywordTok("padding");#CharTok(":");#NormalTok(" ");#DecValTok("1.25");#DataTypeTok("rem");#OperatorTok(";");],
[#NormalTok("        ");#KeywordTok("border-radius");#CharTok(":");#NormalTok(" ");#FunctionTok("var(");#VariableTok("--radius");#FunctionTok(")");#NormalTok(" ");#FunctionTok("var(");#VariableTok("--radius");#FunctionTok(")");#NormalTok(" ");#DecValTok("0");#NormalTok(" ");#DecValTok("0");#OperatorTok(";");],
[#NormalTok("    }");],
[],
[#NormalTok("    ");#FunctionTok(".project-delete-modal__actions");#NormalTok(" {");],
[#NormalTok("        ");#KeywordTok("flex-direction");#CharTok(":");#NormalTok(" ");#DecValTok("column-reverse");#OperatorTok(";");],
[#NormalTok("    }");],
[],
[#NormalTok("    ");#FunctionTok(".project-delete-modal__actions");#NormalTok(" ");#FunctionTok(".button");#NormalTok(" {");],
[#NormalTok("        ");#KeywordTok("width");#CharTok(":");#NormalTok(" ");#DecValTok("100");#DataTypeTok("%");#OperatorTok(";");],
[#NormalTok("        ");#KeywordTok("text-align");#CharTok(":");#NormalTok(" ");#DecValTok("center");#OperatorTok(";");],
[#NormalTok("    }");],
[#NormalTok("}");],));
Tampilan akhir dari page #NormalTok("projects/"); adalah sebagai berikut:

#figure([
#box(image("../img/tutorial-3/projects-final.png"))
], caption: figure.caption(
position: bottom, 
[
Tampilan Halaman Projects Final
]), 
kind: "quarto-float-fig", 
supplement: "Gambar", 
)


Coba tambahkan project-project kamu, jika berhasil #strong[selamat!] Jika masih gagal, coba debug yaa.. :D

== Pengumpulan
<pengumpulan>
Tutorial ini dikumpulkan lewat slot submisi yang disediakan di SCELE, dalam bentuk #strong[tautan ke commit] (bukan sekadar tautan repositori) di GitHub yang menunjukkan hasil akhir Tutorial ini, di-#emph[push] #strong[sebelum tenggat waktu] di atas. Commit yang di-#emph[push] setelah tenggat waktu tidak akan diterima, sehingga Tutorial ini dianggap belum selesai dan Individual Assignment minggu ini tidak akan dinilai. Pastikan juga repositori GitHub kamu bersifat #strong[publik], supaya asisten dosen bisa mengaksesnya.

== Referensi Tambahan
<referensi-tambahan>
- #link("https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Objects/JSON")[JSON Introduction (MDN Web Docs)]
- #link("https://www.w3schools.com/xml/")[XML Tutorial (W3Schools)]

]
, 
title: 
[
Tip
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]



