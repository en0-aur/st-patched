# st-patched

st (the suckless simple terminal for X) built from the 0.9.3 release tarball
with the following patches applied:

- [scrollback][1] — scroll through terminal history with Shift+PageUp/PageDown
  and the mouse wheel.
- [xresources][2] — runtime configuration via X Resources (`st.font`,
  `st.color0`–`st.color15`, `st.foreground`, `st.background`, `st.borderpx`,
  etc.). Reloads on `SIGUSR1` (`pkill -USR1 -x st`).
- `config-tweaks.diff` — local changes to `config.def.h`: underline cursor
  (`cursorshape = 4`), zoom bound to Ctrl+Shift+Plus/Underscore/Parenright, and
  the mouse wheel bound to scrollback.

Colors and font are driven by `~/.Xresources` at runtime rather than compiled
in, so `config.def.h` keeps the upstream color defaults.

Declares `provides=('st')` and `conflicts=('st')`, so it replaces any
repository `st` package.

## Adding more patches

Because the build patches `config.def.h` (not a frozen `config.h`), new patches
that touch `config.def.h` stay in sync. To add one:

1. Add the patch URL and its `sha256sum` to the `source`/`sha256sums` arrays.
2. Add a `patch -p1` line in `prepare()`. Keep `config-tweaks.diff` last, since
   it is generated against the other patches' changes to `config.def.h`.

## Manual install

```sh
makepkg -si
```

This builds and installs the package. Because it conflicts with the repo `st`,
pacman will prompt to remove that package first; accept it.

To build without installing:

```sh
makepkg -f
```

The resulting `st-patched-*.pkg.tar.zst` can then be installed with
`sudo pacman -U <file>`.

[1]: https://st.suckless.org/patches/scrollback/
[2]: https://st.suckless.org/patches/xresources/
