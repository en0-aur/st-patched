# Maintainer: Ian

pkgname=st-patched
pkgver=0.9.3
pkgrel=1
pkgdesc="Simple terminal for X, patched with scrollback and runtime X Resources support"
arch=('x86_64')
url="https://st.suckless.org/"
license=('MIT')
depends=('libxft' 'libxext' 'freetype2' 'fontconfig' 'libxrender')
makedepends=('ncurses')
provides=('st')
conflicts=('st')
source=("https://dl.suckless.org/st/st-${pkgver}.tar.gz"
        "st-scrollback-0.9.2.diff::https://st.suckless.org/patches/scrollback/st-scrollback-0.9.2.diff"
        "st-xresources-20260524-688f70a.diff::https://st.suckless.org/patches/xresources/st-xresources-20260524-688f70a.diff"
        "config-tweaks.diff")
sha256sums=('9ed9feabcded713d4ded38c8cebf36a3b08f0042ef7934a0e2b2409da56e649b'
            '8db63bf83df06cba12cdb02e578cb49afc789c726b4c85f66e95b372562bac7a'
            '8925ff871e44e669d86666b7c72b554a900f2c727e97a30da09a6e1f28c1aac4'
            'ac3f00798a9210a8fdfd6f64519d86e719bed818d19723469edeb2912beff80c')

prepare() {
	cd "st-${pkgver}"
	# Patch order matters: scrollback and xresources both touch config.def.h,
	# and config-tweaks.diff is generated against the result, so apply it last.
	patch -p1 < "${srcdir}/st-scrollback-0.9.2.diff"
	patch -p1 < "${srcdir}/st-xresources-20260524-688f70a.diff"
	patch -p1 < "${srcdir}/config-tweaks.diff"
}

build() {
	cd "st-${pkgver}"
	# Build from config.def.h (generated into config.h); no frozen config.h,
	# so new patches that touch config.def.h stay in sync.
	make X11INC=/usr/include/X11 X11LIB=/usr/lib/X11
}

package() {
	cd "st-${pkgver}"
	# Install the binary and man page.
	install -Dm755 st "${pkgdir}/usr/bin/st"
	install -Dm644 st.1 "${pkgdir}/usr/share/man/man1/st.1"
	sed -i "s/VERSION/${pkgver}/g" "${pkgdir}/usr/share/man/man1/st.1"

	# Install terminfo. The Makefile's `tic -sx st.info` writes to the host
	# terminfo db and fails/escapes under fakeroot, so run tic with an explicit
	# output dir instead.
	install -d "${pkgdir}/usr/share/terminfo"
	tic -sx -o "${pkgdir}/usr/share/terminfo" st.info

	install -Dm644 LICENSE "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
