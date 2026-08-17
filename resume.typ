// PDF résumé.
//
// This reads exactly the same files the website does — config.toml, the
// markdown under content/resume/, and data/*.yaml — so there is no generated
// intermediate and nothing to keep in sync. Typst loads structured data
// natively, which is the whole reason this isn't a template emitting a
// template the way the old Hugo/LaTeX pipeline was.
//
// Build:  nix build .#resume

#import "@preview/cmarker:0.1.10"

#let cfg = toml("config.toml").extra.resume
#let accent = rgb("#8a4f26")

// ---------------------------------------------------------------- loading --

// Split Zola's `+++` TOML frontmatter off a content file.
#let split-front(path) = {
  let parts = read(path).split("+++")
  assert(parts.len() >= 3, message: "no +++ frontmatter in " + path)
  (
    meta: toml(bytes(parts.at(1))),
    // Rejoin the tail so a `+++` inside the body survives.
    body: parts.slice(2).join("+++").trim(),
  )
}

// Membership AND order both come from the config.toml lists, which the web
// template walks in the same order — so the two outputs cannot disagree.
#let load-all(dir, files) = files.map(f => split-front(dir + f))

#let experience = load-all("content/resume/experience/", cfg.experience)
#let projects = load-all("content/resume/projects/", cfg.projects)
#let certifications = yaml("data/certifications.yaml")
#let education = yaml("data/education.yaml")
#let summary = split-front("content/resume/_index.md").body

// ----------------------------------------------------------------- layout --

#set document(title: cfg.name + " — Résumé", author: cfg.name)
#set page(
  paper: "us-letter",
  margin: (left: 1.4cm, right: 1.4cm, top: 1.1cm, bottom: 1.6cm),
  footer: context [
    #set text(size: 7.5pt, fill: luma(140))
    #grid(
      columns: (1fr, auto),
      cfg.name + " · Résumé",
      counter(page).display("1 / 1", both: true),
    )
  ],
)
#set text(font: "Roboto", size: 9pt, fill: rgb("#333333"))
#set par(justify: false, leading: 0.62em)

// Section heading: accent-coloured, rule underneath. Mirrors the old
// Awesome-CV look closely enough to feel continuous.
#let section(title) = {
  v(0.7em)
  text(size: 12pt, weight: "bold", fill: accent, tracking: 0.06em, upper(title))
  v(-0.55em)
  line(length: 100%, stroke: 0.6pt + accent)
  v(0.15em)
}

// Two-line entry header: bold title + right-aligned meta on each line.
#let entry(title, meta, subtitle, submeta) = {
  grid(
    columns: (1fr, auto),
    row-gutter: 0.25em,
    text(size: 10pt, weight: "bold", title),
    text(size: 9pt, fill: luma(110), meta),
    text(size: 9pt, style: "italic", subtitle),
    text(size: 8.5pt, fill: luma(110), style: "italic", submeta),
  )
}

// Tighter list than the default; matches a dense one-page résumé.
#let bullets(md) = {
  set list(indent: 0.6em, body-indent: 0.45em, spacing: 0.45em, marker: [•])
  block(inset: (top: 0.35em), cmarker.render(md))
}

// ------------------------------------------------------------------ header --

#align(center)[
  #text(size: 26pt, weight: 300, tracking: 0.04em)[
    #cfg.name.split(" ").at(0) #text(weight: "bold", cfg.name.split(" ").at(1))
  ]
  #v(-0.3em)
  #text(size: 9pt, fill: luma(110), cfg.title.replace(", ", " · "))
  #v(-0.35em)
  #text(size: 8pt, fill: luma(130))[
    #cfg.location
    #h(0.6em) | #h(0.6em) #link("mailto:" + cfg.email, cfg.email)
    #h(0.6em) | #h(0.6em) #link("https://github.com/" + cfg.github)[github.com/#cfg.github]
    #h(0.6em) | #h(0.6em) #link("https://gitlab.com/" + cfg.gitlab)[gitlab.com/#cfg.gitlab]
    #h(0.6em) | #h(0.6em) #link("https://linkedin.com/in/" + cfg.linkedin)[linkedin.com/in/#cfg.linkedin]
  ]
]

#v(0.4em)

// ---------------------------------------------------------------- sections --

#section("Summary")
#cmarker.render(summary)

#section("Work Experience")
#for e in experience {
  block(breakable: false, inset: (top: 0.45em))[
    #entry(
      e.meta.extra.employer,
      e.meta.extra.location,
      e.meta.title,
      e.meta.extra.start + " – " + e.meta.extra.end,
    )
    #bullets(e.body)
  ]
}

#section("Certifications")
#block(inset: (top: 0.35em))[
  #grid(
    columns: (auto, 1fr, auto),
    column-gutter: 0.9em,
    row-gutter: 0.42em,
    ..certifications
      .map(c => (
        text(fill: luma(110), size: 8.5pt, c.date),
        [*#c.name*#text(fill: luma(110))[, Credential ID: #c.id]],
        text(fill: luma(110), size: 8.5pt, style: "italic", c.org),
      ))
      .flatten(),
  )
]

#section("Notable Projects")
#for p in projects {
  block(breakable: false, inset: (top: 0.45em))[
    #entry(
      p.meta.title,
      p.meta.extra.link,
      p.meta.extra.role,
      p.meta.extra.tools,
    )
    #block(inset: (top: 0.3em), cmarker.render(p.body))
  ]
}

#section("Education")
#for e in education {
  block(breakable: false, inset: (top: 0.45em))[
    #entry(e.university, e.location, e.degree, e.start + " – " + e.end)
  ]
}
