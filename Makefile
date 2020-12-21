prefix ?= /usr/local
bindir = $(prefix)/bin
binary ?= general
release_binary?=.build/release/General

$(binary): $(release_binary)
	cp $(release_binary) $(binary)

$(release_binary):
	swift build -c release --disable-sandbox

completions: $(binary)
	$(binary) --generate-completion-script zsh > _general
	$(binary) --generate-completion-script bash > general
	$(binary) --generate-completion-script fish > general.fish

install: build completions
	mkdir -p $(bindir)
	cp -f $(release_binary) $(bindir)/$(binary)

build:
	swift build -c release --disable-sandbox

uninstall:
	rm -rf "$(bindir)/$(binary)"

clean:
	rm -rf .build

.PHONY: build install uninstall clean completions
