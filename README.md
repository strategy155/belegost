# belegost

A personal Gentoo overlay.

## Using it

belegost builds on [::guru](https://wiki.gentoo.org/wiki/Project:GURU) as well
as ::gentoo (`masters = gentoo guru`), so enable both:

```sh
eselect repository enable guru
eselect repository add belegost git https://github.com/strategy155/belegost.git
emaint sync --repo guru
emaint sync --repo belegost
```

From then on, a plain `emerge --sync` updates them together with your other
repositories.

## Distfiles

Dependency tarballs that upstream doesn't publish (Go module caches, vendored
crates, npm caches) are release assets in
[menegroth](https://github.com/strategy155/menegroth). Each release holds one
package version and is tagged `${P}`, for example `crush-0.60.0`, so ebuilds
fetch them from:

```
https://github.com/strategy155/menegroth/releases/download/${P}/<asset>
```

## Conventions

- Thin Manifests: DIST lines only.
- The metadata cache is not committed; Portage regenerates it locally.
- [pkgcheck](https://github.com/pkgcore/pkgcheck) runs on every push and pull
  request; repo-specific settings live in `metadata/pkgcheck.conf`.
