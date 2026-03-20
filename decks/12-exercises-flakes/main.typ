#import "@local/ucwn-common:0.1.0": nonincremental, title-slide, ucwn-theme

#show: ucwn-theme(
  title: [Изграждане на пакети върху flake системата],
  date: [20.05.2025],
)

#set text(lang: "bg")
#title-slide()

== Преговор
#nonincremental[
- Запознахме се с flake-овете
- Запознахме се с V3 команди
- Разгледахме какво са overlay функции

]

---
```nix
{
  inputs = {
    a.url = "github:edolstra/dwarffs";
    b.url = "path:./stuff/myflake";
  };
  outputs = { self, ... }@inputs: {
    packages."<system>"."<name>" = derivation;
    legacyPackages."<system>"."<name>" = derivation;
    apps."<system>"."<name>" = derivation;
    devShells."<system>"."<name>" = derivation;
  
    nixosModules."<name>" = { config, ... }: { options = {}; config = {}; };
    nixosConfigurations."<hostname>" = {};
  
    overlays."<name>" = final: prev: { };
  };
}
```

= Задачи
- Ако не е казано друго, може да използвате функции в `builtins` и
  `nixpkgs`

- #strong[Не] може да използвате (други) външни библиотеки за пакетиране

- Използвайте интернет, особено
  #link("https://search.nixos.org/packages") и
  #link("https://search.nixos.org/options")

== Тривиални flake-ове
#strong[Задача 1:] #emph[В тази задача НЕ можете да използвате `nixpkgs`
(но може `builtins`)!] Реализирайте flake без входове и който връща два
атрибута:

- `separator` - низ, който съдържа една запетая
- `columns` - функция, която приема #emph[три] аргумента: низ, начална
  колона (първата е номер едно) и крайна колона. Използвайки
  `separator`, низът трябва да се раздели на колони (с разделител
  `separator`), от тях да се премахнат тези между началната и крайната
  (включително) и колоните да се обединят обратно в един низ (с
  разделител `separator`). Върната стойност е този финален низ.

---
=== Пример
==== Извикване
```nix
columns "First,Second,Third,Fourth" 3 4
```

==== Върната стойност
```nix
"First,Second"
```

---
#strong[Задача 2:] Реализирайте flake, който приема flake-а от
предходната задача като вход и връща атрибут `columns`. Това е функция,
подобна на тази от предходната задача, която обаче приема път към файл и
премахва колоните от всеки #strong[ред] на файла.

---
=== Пример
==== ./example.csv
```csv
First,Second,Third,Fourth,Fifth
Apple,Bottom,Jeans,Looking,At
```

==== Извикване на `columns`
```nix
columns ./example.csv 2 3
```

==== Резултат
```csv
First,Fourth,Fifth
Apple,Looking,At
```

---
#strong[Задача 3:] Реализирайте flake, който приема flake-овете от
предходните две задачи и връща атрибут `columns`, който работи подобно
на предходните, обаче първия аргумент може да бъде низ #strong[или] път.
Функцията трябва да избере коректната #strong[вече направена]
имплементация от зависимостите спрямо типа.

== Семантични flake-ове
#strong[Задача 4:] Реализирайте flake, който приема
#link("https://github.com/NixOS/nixpkgs")[`nixpkgs`] и връща три
#strong[пакета]: `english_text_normalization`, `ts` и `cloak`. Тези
пакети бяха дефинирани в лекция 6 "Функции над `mkDerivation`" (може да
намерите тогавашните реализации
#link("https://github.com/universal-configurations-with-nix/academy-2025/tree/main/src/06-build-helpers")[тук],
но ще са нужни модификации).

#strong[Не може да използвате `<nixpkgs>`!!!] Използвайте този
`nixpkgs`, който сте дефинирали като вход.

Всеки пакет трябва да може да бъде компилиран чрез `nix build` и пуснат
чрез `nix run`. Примерно: `nix run .#cloak`

#strong[Упътване:] Може да използвате
#link("https://nix.dev/tutorials/callpackage.html")[`callPackage`]
функцията

---
#strong[Задача 5:] Реализирайте flake, който приема
#link("https://github.com/NixOS/nixpkgs")[`nixpkgs`] и връща две NixOS
конфигурации.

+ Първата е на име `smiths` и e модуляризираната конфигурация, която бе
  дефинирана от задача 5 на занятие (упражнение) 10 "Изграждане на
  системи върху NixOS" (може да намерите решение на задачата
  #link("https://github.com/universal-configurations-with-nix/academy-2025/tree/main/src/10-exercises-nixos/ex05")[тук];).
+ Втората е на име `johnny` и e немодуляризираната конфигурация, която
  бе разглеждана на лекция 9 "Конкетики в модулната система на NixOS"
  (може да я намерите
  #link("https://github.com/universal-configurations-with-nix/academy-2025/blob/main/src/09-module-system-specifics/single-configuration.nix")[тук];).

---
Може да компилирате виртуална машина за конфигурация чрез \
`nixos-rebuild build-vm --flake .#smiths` или \
`nixos-rebuild build-vm --flake .#johnny`

Пускането на виртуалната машина става чрез `./result/bin/run-nixos-vm`.

Най-вероятно нямате командата `nixos-rebuild`. Най-лесния начин да си я
докарате в shell е постаро му чрез `nix-shell`:

```sh
nix-shell -p nixos-rebuild
```

или чрез новия `nix shell`:

```sh
nix shell nixpkgs#nixos-rebuild
```

---
#strong[Задача 6:] Към flake-а от предходната задача добавете като изход
модулите `international` и `rust-dev-improved`, които бяха дефинирани в
задачи 7 и 8 от занятие (упражнение) 10 "Изграждане на системи върху
NixOS" (може да намерите решения на задачите
#link("https://github.com/universal-configurations-with-nix/academy-2025/tree/main/src/10-exercises-nixos")[тук];).

---
#strong[Задача 7:] Реализирайте нов flake, който връща NixOS
конфигурация на име `modo`, която е модуляризираната конфигурация от
лекция 9 "Конкетики в модулната система на NixOS" (може да я намерите
#link("https://github.com/universal-configurations-with-nix/academy-2025/blob/main/src/09-module-system-specifics/modularized")[тук];).

Допълнително нека да приема и използва модулите `international` и
`rust-dev-improved`, които дефинирахме в предходната задача.
Интернационалните локации трябва да бъдат `Sofia` и `London`.
`rust-dev-improved` трябва да добавя програмите си #strong[само] за
потребител `john`.

---
#strong[Задача 8:] Разширете flake-а от задача 4, така че да връща и две
overlay функции:

+ Първата наименувана `mypkgs`, която би добавила трите пакета в
  `nixpkgs`
+ Втората наименувана `acepe`, която променя опциите `lexiconPath` и
  `pname` на пакета
  #link("https://github.com/NixOS/nixpkgs/blob/97ec7b1f71185b0cba8061cd388be6384b452a0a/pkgs/applications/misc/ape/default.nix#L7-L8")[ape]

#strong[Задача 9:] Разширете flake-а от задача 7, така че overlay
функциите, дефинирани в предходната задача, да бъдат приложени и
използвани.
