#import "@local/ucwn-common:0.1.0": nonincremental, title-slide, ucwn-theme

#show: ucwn-theme(
  title: [Задачи по пакетиране на програми с Nix],
  date: [24.04.2025],
)

#set text(lang: "bg")
#title-slide()

== Преговор
#nonincremental[
- Разгледали сме до сега пакетиране на програми чрез:

  - `builtins.derivation`
  - `stdenv.mkDerivation`
  - `buildGoModule`
  - `buildRustPackage`
  - `buildDotnetModule`
  - `buildNimPackage`
  - `buildPythonApplication`

]
= Задачи
- Може (трябва) да използвате функции в `builtins` и `nixpkgs`

- #strong[Не] може да използвате (други) външни библиотеки за пакетиране

- Може да зачитате, че програма е пакетирана ако `program --help`
  #emph[или] `program --version` върнат резултат

- Пакетирайте най-новия releasе, ако такъв съществува

- При доста пакети, `check` фазата няма да тръгне директно. Не е проблем
  да я изключите.

== Пакетирайте Python програми
#strong[Задача 1] - #link("https://github.com/OpenTTD/nml")

#strong[Задача 2] - #link("https://github.com/LoLei/razer-cli")

#strong[Задача 3] - #link("https://codeberg.org/svartstare/pass2csv") \
#emph[Упътване: използвайте `fetchFromGitea`, документация
#link("https://ryantm.github.io/nixpkgs/builders/fetchers/#fetchfromgitea")[тук];]

== Пакетирайте Rust програми
#strong[Задача 4] - #link("https://github.com/evmar/n2")

#strong[Задача 5] - #link("https://gitlab.com/kornelski/mandown") \
#emph[Упътване: използвайте `fetchFromGitLab`, използва се по същия
начин като `fetchFromGitHub`]

#strong[Задача 6] - #link("https://crates.io/crates/petname") \
#emph[Упътване: използвайте `fetchCrate`, за да си спестите
`Cargo.lock`. То приема `pname` и `version` от crates.io, и също приема
`hash`.]

== Пакетирайте Go програми
#strong[Задача 7] - #link("https://github.com/cfoust/cy")

#strong[Задача 8] - #link("https://github.com/lestrrat-go/jwx") \
#emph[Упътване: забележете в коя директория в хранилището се намира jwx
и използвайте `modRoot`]

#strong[Задача 9] -
#link("https://chromium.googlesource.com/infra/luci/luci-go") \
#emph[Упътване: използвайте `fetchFromGitiles`, документация
#link("https://ryantm.github.io/nixpkgs/builders/fetchers/#fetchfromgitiles")[тук];]

== Пакетирайте Nim програми
#strong[Задача 10] - #link("https://github.com/nim-lang/c2nim")

#strong[Задача 11] - #link("https://git.sr.ht/~ehmry/base45") \
#emph[Упътване: използвайте `fetchFromSourcehut`, документация
#link("https://ryantm.github.io/nixpkgs/builders/fetchers/#fetchfromsourcehut")[тук];]

#strong[Задача 12] - #link("https://github.com/jiro4989/nimtetris") \
#emph[Упътване: създайте "lock" файл през `nim_lk`]
