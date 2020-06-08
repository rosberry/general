prefix ?= /usr/local
bindir = $(prefix)/bin
binary ?= general
release_binary?=.build/release/General

build:
	swift build -c release --disable-sandbox

install: build
	mkdir -p $(bindir)
	cp -f $(release_binary) $(bindir)/$(binary)

uninstall:
	rm -rf "$(bindir)/$(binary)"

clean:
	rm -rf .build

.PHONY: build install uninstall clean