# Modo lectura — build, install and package.
#
#   make                       compile translations
#   make check                 run the tests (no root needed)
#   sudo make install          install for every user of this computer
#   sudo make uninstall
#   make plasmoid              build dist/*.plasmoid for the KDE Store
#   make dist                  build the source tarball (for RPM/COPR)

ID        := io.github.guillermoclaro.modolectura
VERSION   := $(shell python3 -c 'import json;print(json.load(open("package/metadata.json"))["KPlugin"]["Version"])')

PREFIX     ?= /usr/local
DESTDIR    ?=
BINDIR     ?= $(PREFIX)/bin
DATADIR    ?= $(PREFIX)/share
LIBEXECDIR ?= $(PREFIX)/libexec/modo-lectura
POLKITDIR  ?= /usr/share/polkit-1/actions
UNITDIR    ?= /etc/systemd/system
PLASMOIDDIR = $(DATADIR)/plasma/plasmoids/$(ID)

LANGS := $(basename $(notdir $(wildcard po/*.po)))
MO    := $(foreach l,$(LANGS),build/locale/$(l)/LC_MESSAGES/plasma_applet_$(ID).mo)

.PHONY: all check install uninstall install-system plasmoid dist pot clean

all: $(MO)

build/locale/%/LC_MESSAGES/plasma_applet_$(ID).mo: po/%.po tools/build-mo.py
	python3 -I tools/build-mo.py $< $@

pot:
	python3 -I tools/extract-messages.py > po/template.pot

check: all
	bash -n package/contents/code/modo-lectura package/contents/code/install-system.sh package/contents/system/hosts-helper
	python3 -I -c "import ast,sys; [ast.parse(open(f).read(), f) for f in sys.argv[1:]]" package/contents/code/do-not-disturb.py tools/*.py tests/*.py
	bash tests/test-helper.sh
	bash tests/test-cli.sh
	python3 -I tests/test-translations.py

install-system:
	DESTDIR="$(DESTDIR)" LIBEXECDIR="$(LIBEXECDIR)" POLKITDIR="$(POLKITDIR)" UNITDIR="$(UNITDIR)" \
		bash package/contents/code/install-system.sh

install: all install-system
	rm -rf "$(DESTDIR)$(PLASMOIDDIR)" "$(DESTDIR)$(DATADIR)/plasma/plasmoids/org.guillermo.modolectura"
	mkdir -p "$(DESTDIR)$(PLASMOIDDIR)"
	cp -r package/. "$(DESTDIR)$(PLASMOIDDIR)/"
	cp -r build/locale "$(DESTDIR)$(PLASMOIDDIR)/contents/"
	find "$(DESTDIR)$(PLASMOIDDIR)" -type d -exec chmod 0755 {} + -o -type f -exec chmod 0644 {} +
	chmod 0755 "$(DESTDIR)$(PLASMOIDDIR)/contents/code/modo-lectura" \
	           "$(DESTDIR)$(PLASMOIDDIR)/contents/code/install-system.sh" \
	           "$(DESTDIR)$(PLASMOIDDIR)/contents/system/hosts-helper"
	mkdir -p "$(DESTDIR)$(BINDIR)"
	ln -sf "$(PLASMOIDDIR)/contents/code/modo-lectura" "$(DESTDIR)$(BINDIR)/modo-lectura"

uninstall:
	DESTDIR="$(DESTDIR)" LIBEXECDIR="$(LIBEXECDIR)" POLKITDIR="$(POLKITDIR)" UNITDIR="$(UNITDIR)" \
		bash package/contents/code/install-system.sh --uninstall
	rm -rf "$(DESTDIR)$(PLASMOIDDIR)"
	rm -f "$(DESTDIR)$(BINDIR)/modo-lectura"

plasmoid: all
	rm -rf build/plasmoid && mkdir -p build/plasmoid dist
	cp -r package/. build/plasmoid/
	cp -r build/locale build/plasmoid/contents/
	rm -f dist/modo-lectura-$(VERSION).plasmoid
	cd build/plasmoid && zip -qr ../../dist/modo-lectura-$(VERSION).plasmoid . -x "*__pycache__*"
	@echo "dist/modo-lectura-$(VERSION).plasmoid"

dist:
	mkdir -p dist
	git archive --format=tar.gz --prefix=modo-lectura-$(VERSION)/ -o dist/modo-lectura-$(VERSION).tar.gz HEAD
	@echo "dist/modo-lectura-$(VERSION).tar.gz"

clean:
	rm -rf build dist
