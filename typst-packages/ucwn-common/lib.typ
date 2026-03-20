#import "@preview/touying:0.6.1": (
  components,
  config-colors,
  config-common,
  config-info,
  config-methods,
  config-page,
  config-store,
  pause,
  touying-slide,
  touying-slide-wrapper,
  touying-slides,
  utils,
)
#import "@preview/metropolyst:0.1.0": (
  focus-slide as metropolyst-focus-slide,
)

#let ucwn-presentable = sys.inputs.at("ucwn_mode", default: "handout") == "presentable"

#let focus-slide = metropolyst-focus-slide
#let next_item() = if ucwn-presentable { pause }

#let nonincremental(body) = utils.label-it(
  metadata((
    kind: "ucwn-nonincremental",
    body: body,
  )),
  "touying-temporary-mark",
)

#let auto-increment-content(it, enabled: true) = {
  let is-ignorable(child) = {
    if child in ([], [ ], parbreak(), linebreak()) {
      true
    } else if type(child) == content and child.has("text") and type(child.text) == str {
      child.text.trim() == ""
    } else if utils.is-sequence(child) {
      child.children.all(is-ignorable)
    } else {
      false
    }
  }

  let rebuild-item(item, pause-after: false) = {
    let item-body = auto-increment-content(item.body, enabled: enabled)
    if enabled and ucwn-presentable and pause-after {
      utils.reconstruct(item, [#item-body #next_item()])
    } else {
      utils.reconstruct(item, item-body)
    }
  }

  let rebuild-children(children) = {
    let rebuilt = ()
    for (index, child) in children.enumerate() {
      let next-child = children
        .slice(index + 1)
        .filter(candidate => not is-ignorable(candidate))
        .at(0, default: none)
      if type(child) == content and child.func() in (list.item, enum.item) {
        let pause-after = type(next-child) == content and next-child.func() == child.func()
        rebuilt.push(rebuild-item(child, pause-after: pause-after))
      } else {
        rebuilt.push(auto-increment-content(child, enabled: enabled))
      }
    }
    rebuilt
  }

  if type(it) == array {
    return rebuild-children(it)
  }

  if type(it) != content {
    return it
  }

  if utils.is-kind(it, "ucwn-nonincremental") {
    return auto-increment-content(it.value.body, enabled: false)
  }

  if utils.is-sequence(it) {
    return rebuild-children(it.children).sum(default: none)
  }

  if utils.is-styled(it) {
    return utils.reconstruct-styled(it, auto-increment-content(it.child, enabled: enabled))
  }

  if it.func() in (list, enum) {
    let fields = it.fields()
    fields.remove("children")
    let children = rebuild-children(it.children)
    return (it.func())(..fields, ..children)
  }

  if it.func() in (table, grid, stack) {
    return utils.reconstruct-table-like(
      it,
      rebuild-children(it.children),
    )
  }

  if it.func() in (list.item, enum.item, align, link) {
    return utils.reconstruct(it, auto-increment-content(it.body, enabled: enabled))
  }

  if it.has("body") {
    return utils.reconstruct(named: true, it, auto-increment-content(it.body, enabled: enabled))
  }

  it
}

#let footer-course(self) = {
  if self.info.subtitle != none {
    self.info.subtitle
  } else {
    self.info.title
  }
}

#let footer-deck(self) = self.info.title

#let footer-segment(fill, align, body) = grid.cell(
  fill: fill,
  inset: (x: 0.75em, y: 0.22em),
  align: align,
)[
  #set text(fill: white)
  #utils.fit-to-width(grow: false, 100%, body)
]

#let footer-slide-number() = {
  let current-slide = here().page()
  let total-slides = counter(page).final().first()
  [#current-slide/#total-slides]
}

#let footer-section-number(level: 1) = {
  let current-slide = here().page()
  if current-slide <= 1 {
    return none
  }
  let sections = query(heading.where(level: level)).filter(h => h.location().page() <= current-slide)
  if sections == () {
    return none
  }

  let current-section = sections.at(-1)
  let start-slide = current-section.location().page()
  let next-sections = query(heading.where(level: level)).filter(h => h.location().page() > start-slide)
  let end-slide = if next-sections == () {
    counter(page).final().first()
  } else {
    next-sections.at(0).location().page() - 1
  }

  let current-in-section = current-slide - start-slide + 1
  let total-in-section = end-slide - start-slide + 1
  [§#current-in-section/#total-in-section]
}

#let footer-corner(self) = context {
  let section-number = footer-section-number()
  if section-number == none {
    [#utils.display-info-date(self) | #footer-slide-number()]
  } else {
    [#utils.display-info-date(self) | #section-number | #footer-slide-number()]
  }
}

#let ucwn-footer(self) = {
  set std.align(bottom)
  set text(
    size: self.store.footer-size,
    font: self.store.footer-font,
    weight: self.store.footer-weight,
  )
  box(width: 100%)[
    #grid(
      columns: (1.9fr, 2.1fr, 1.5fr, auto),
      gutter: 0pt,
      footer-segment(self.store.footer-course-fill, left, footer-course(self)),
      footer-segment(self.store.footer-deck-fill, horizon, footer-deck(self)),
      footer-segment(self.store.footer-author-fill, horizon, self.info.author),
      footer-segment(self.store.footer-page-fill, right, footer-corner(self)),
    )
  ]
}

#let ucwn-title-slide(
  config: (:),
  extra: none,
  ..args,
) = touying-slide-wrapper(self => {
  self = utils.merge-dicts(
    self,
    config,
    config-page(
      fill: self.store.main-background-color,
      footer: ucwn-footer,
    ),
  )
  let info = self.info + args.named()
  let body = {
    set text(
      fill: self.store.main-text-color,
      font: self.store.title-font,
    )
    set std.align(horizon)
    block(
      width: 100%,
      inset: 2em,
      {
        components.left-and-right(
          {
            text(
              size: self.store.title-size,
              weight: self.store.title-weight,
              info.title,
            )
            if info.subtitle != none {
              v(-0.4em)
              text(
                size: self.store.subtitle-size,
                weight: self.store.subtitle-weight,
                info.subtitle,
              )
            }
          },
          text(
            size: self.store.logo-size,
            utils.call-or-display(self, info.logo),
          ),
        )
        v(0.8em)
        line(length: 100%, stroke: 0.4pt + self.store.line-separator-color)
        set text(
          size: self.store.author-size,
          weight: self.store.author-weight,
        )
        if info.author != none {
          block(above: 2.5em, below: 0em, info.author)
        }
        if info.date != none {
          block(
            above: 1.0em,
            below: 0em,
            text(
              size: self.store.date-size,
              weight: self.store.date-weight,
              utils.display-info-date(self),
            ),
          )
        }
        if info.institution != none {
          block(
            above: 1.4em,
            below: 0em,
            text(
              size: self.store.institution-size,
              weight: self.store.institution-weight,
              info.institution,
            ),
          )
        }
        if extra != none {
          block(
            above: 1.0em,
            below: 0em,
            text(
              size: self.store.extra-size,
              weight: self.store.extra-weight,
              extra,
            ),
          )
        }
      },
    )
  }
  touying-slide(self: self, body)
})

#let ucwn-section-slide(
  config: (:),
  level: 1,
  numbered: true,
  body,
) = touying-slide-wrapper(self => {
  let slide-body = {
    set std.align(horizon)
    show: pad.with(20%)
    set text(
      size: self.store.section-size,
      font: self.store.section-font,
      weight: self.store.section-weight,
    )
    set text(fill: self.store.main-text-color)
    stack(
      dir: ttb,
      spacing: 1em,
      utils.display-current-heading(level: level, numbered: numbered),
      block(
        height: 2pt,
        width: 100%,
        spacing: 0pt,
        components.progress-bar(
          height: 2pt,
          self.store.progress-bar-color,
          self.store.progress-bar-background,
        ),
      ),
    )
    body
  }
  self = utils.merge-dicts(
    self,
    config-page(
      fill: self.store.main-background-color,
      footer: ucwn-footer,
    ),
  )
  touying-slide(self: self, config: config, slide-body)
})

#let render-topic-slide(self, title, config: (:)) = {
  let slide-body = {
    set std.align(horizon)
    show: pad.with(20%)
    set text(
      size: self.store.section-size,
      font: self.store.section-font,
      weight: self.store.section-weight,
    )
    set text(fill: self.store.main-text-color)
    stack(
      dir: ttb,
      spacing: 1em,
      title,
      block(
        height: 2pt,
        width: 100%,
        spacing: 0pt,
        components.progress-bar(
          height: 2pt,
          self.store.progress-bar-color,
          self.store.progress-bar-background,
        ),
      ),
    )
  }
  self = utils.merge-dicts(
    self,
    config-page(
      fill: self.store.main-background-color,
      footer: ucwn-footer,
    ),
  )
  touying-slide(self: self, config: config, slide-body)
}

#let topic-slide(
  config: (:),
  title,
) = touying-slide-wrapper(self => {
  render-topic-slide(self, title, config: config)
})

#let should-auto-topic-slide(it) = {
  let title = utils.markup-text(it.body).trim()
  title.match(regex("^`?[a-z][A-Za-z0-9 ._/-]*`?(?:\\b|$)")) != none
}

#let auto-topic-subsection-slide(body) = touying-slide-wrapper(self => {
  let current-heading = self.headings.at(-1, default: none)
  if current-heading != none and should-auto-topic-slide(current-heading) {
    render-topic-slide(self, current-heading.body)
  } else {
    none
  }
})

#let title-slide = ucwn-title-slide

#let ucwn-slide(
  title: auto,
  align: auto,
  config: (:),
  repeat: auto,
  setting: body => body,
  composer: auto,
  ..bodies,
) = touying-slide-wrapper(self => {
  if align != auto {
    self.store.align = align
  }

  let header(self) = {
    set std.align(top)
    show: components.cell.with(
      fill: self.store.header-background-color,
      inset: (top: 0.8em, bottom: 0.8em, x: 0.9em),
    )
    set std.align(horizon)
    set text(
      fill: self.store.header-text-color,
      weight: self.store.header-weight,
      size: self.store.header-size,
      font: self.store.header-font,
    )
    components.left-and-right(
      {
        if title != auto {
          utils.fit-to-width(grow: false, 100%, title)
        } else {
          utils.call-or-display(self, self.store.header)
        }
      },
      utils.call-or-display(self, self.store.header-right),
    )
  }

  let self = utils.merge-dicts(
    self,
    config-page(
      fill: self.store.main-background-color,
      header: header,
      footer: ucwn-footer,
    ),
  )
  let processed-bodies = bodies.pos().map(body => auto-increment-content(body))

  let new-setting = body => {
    show: std.align.with(self.store.align)
    set text(fill: self.store.main-text-color)
    show heading.where(level: 1): none
    show: setting
    body
  }

  touying-slide(
    self: self,
    config: config,
    repeat: repeat,
    setting: new-setting,
    composer: composer,
    ..processed-bodies,
  )
})

#let ucwn-theme(
  title: none,
  date: none,
  subtitle: [Универсални конфигурации с Nix],
  author: [Павел Атанасов, Камен Младенов],
  institution: [ФМИ, СУ],
  logo: none,
) = body => {
  let footer-course-fill = rgb("#48586b")
  let footer-deck-fill = rgb("#566578")
  let footer-author-fill = rgb("#667386")
  let footer-page-fill = rgb("#263243")
  let font = ("Maple Mono",)
  let accent-color = rgb("#0f766e")
  let hyperlink-color = accent-color
  let line-separator-color = accent-color
  let progress-bar-color = accent-color
  let progress-bar-background = rgb("#d9e4e4")
  let header-background-color = rgb("#0f172a")
  let focus-background-color = header-background-color
  let main-background-color = rgb("#f8fafc")
  let main-text-color = rgb("#0f172a")
  let header-text-color = main-background-color
  let focus-text-color = main-background-color
  let footer-text-color = main-text-color

  show raw.where(block: false): set text(font: font, weight: "regular")
  show raw.where(block: true): set text(font: font, size: 0.9em, weight: "regular")

  set text(lang: "bg")
  set text(size: 18pt, font: font, weight: "regular", stretch: 100%)
  set strong(delta: 120)

  show link: it => text(fill: hyperlink-color, it)
  show: touying-slides.with(
    config-page(
      paper: "presentation-16-9",
      header-ascent: 28%,
      footer-descent: 22%,
      margin: (top: 3.2em, bottom: 1.1em, x: 1.5em),
    ),
    config-common(
      handout: not ucwn-presentable,
      slide-fn: ucwn-slide,
      new-section-slide-fn: ucwn-section-slide,
      new-subsection-slide-fn: auto-topic-subsection-slide,
      receive-body-for-new-section-slide-fn: false,
      receive-body-for-new-subsection-slide-fn: false,
      show-strong-with-alert: false,
      nontight-list-enum-and-terms: false,
      align-list-marker-with-baseline: true,
      scale-list-items: 0.94,
    ),
    config-methods(
      alert: (self: none, it) => text(fill: self.colors.primary, it),
      cover: (self: none, body) => box(scale(x: 0%, body)),
    ),
    config-colors(
      primary: accent-color,
      primary-light: progress-bar-background,
      secondary: rgb("#23373b"),
      neutral-lightest: rgb("#fafafa"),
      neutral-dark: rgb("#23373b"),
      neutral-darkest: rgb("#23373b"),
    ),
    config-store(
      align: horizon,
      header: self => utils.display-current-heading(
        setting: utils.fit-to-width.with(grow: false, 100%),
        depth: self.slide-level,
      ),
      header-right: self => self.info.logo,
      footer: none,
      footer-right: none,
      footer-progress: false,
      hyperlink-color: hyperlink-color,
      line-separator-color: line-separator-color,
      progress-bar-color: progress-bar-color,
      progress-bar-background: progress-bar-background,
      header-background-color: header-background-color,
      focus-background-color: focus-background-color,
      main-background-color: main-background-color,
      main-text-color: main-text-color,
      header-text-color: header-text-color,
      focus-text-color: focus-text-color,
      footer-text-color: footer-text-color,
      footer-course-fill: footer-course-fill,
      footer-deck-fill: footer-deck-fill,
      footer-author-fill: footer-author-fill,
      footer-page-fill: footer-page-fill,
      header-font: font,
      header-size: 1.0em,
      header-weight: "medium",
      footer-font: font,
      footer-size: 0.58em,
      footer-weight: "regular",
      title-font: font,
      title-size: 1.35em,
      title-weight: "medium",
      subtitle-size: 1.0em,
      subtitle-weight: "regular",
      author-size: 0.8em,
      author-weight: "regular",
      date-size: 0.8em,
      date-weight: "regular",
      institution-size: 0.8em,
      institution-weight: "regular",
      extra-size: 0.8em,
      extra-weight: "regular",
      logo-size: 2em,
      section-font: font,
      section-size: 1.25em,
      section-weight: "medium",
      focus-font: font,
      focus-size: 1.25em,
      focus-weight: "medium",
    ),
    config-info(
      title: title,
      subtitle: subtitle,
      author: author,
      date: date,
      institution: institution,
      logo: logo,
    ),
  )

  body
}
