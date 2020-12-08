prefix ?= /usr/local
bindir = $(prefix)/bin
binary ?= general
release_binary?=.build/release/General

install: build completion
	mkdir -p $(bindir)
	cp -f $(release_binary) $(bindir)/$(binary)

build:
	swift build -c release --disable-sandbox

uninstall:
	rm -rf "$(bindir)/$(binary)"

clean:
	rm -rf .build

completion:
	general --generate-completion-script zsh > /usr/local/share/zsh/site-functions/_general

.PHONY: build install uninstall clean
