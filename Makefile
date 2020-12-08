prefix ?= /usr/local
bindir = $(prefix)/bin
binary ?= general
release_binary?=.build/release/General

install: build completions
	mkdir -p $(bindir)
	cp -f $(release_binary) $(bindir)/$(binary)

build:
	swift build -c release --disable-sandbox

uninstall:
	rm -rf "$(bindir)/$(binary)"

clean:
	rm -rf .build

completions:
	general --generate-completion-script zsh > _general
	general --generate-completion-script bash > general
	general --generate-completion-script fish > general.fish

.PHONY: build install uninstall clean
