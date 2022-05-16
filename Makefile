BIN := arch-secure-boot
VERSION := 1.3.2

PREFIX ?= /usr
BIN_DIR = $(DESTDIR)$(PREFIX)/bin
SHARE_DIR = $(DESTDIR)$(PREFIX)/share

.PHONY: clean
clean:
	rm -rf dist

.PHONY: install
install:
	install -Dm755 -t "$(BIN_DIR)/" $(BIN)
	install -Dm644 -t "$(DESTDIR)/etc/$(BIN)/" recovery.nsh
	install -Dm644 -t "$(SHARE_DIR)/libalpm/hooks" pacman-hooks/*
	install -Dm644 -t "$(SHARE_DIR)/licenses/$(BIN)/" LICENSE
	install -Dm644 -t "$(SHARE_DIR)/doc/$(BIN)/" README.md

.PHONY: dist
dist: clean
	mkdir -p dist
	git archive -o "dist/$(BIN)-$(VERSION).tar.gz" --format tar.gz --prefix "$(BIN)-$(VERSION)/" "$(VERSION)"
	gpg --detach-sign --armor "dist/$(BIN)-$(VERSION).tar.gz"
	rm -f "dist/$(BIN)-$(VERSION).tar.gz"
