prefix ?= /usr/local
bindir = $(prefix)/bin
binary ?= general
release_binary?=.build/release/General
completions_folder=Scripts/completions
zsh_completions_folder=/usr/local/share/zsh/site-functions

$(binary): $(release_binary)
	cp $(release_binary) $(binary)

$(release_binary):
	swift build -c release --disable-sandbox

completions: $(binary)
	./$(binary) --generate-completion-script zsh >  $(completions_folder)/_general
	./$(binary) --generate-completion-script bash > $(completions_folder)/general
	./$(binary) --generate-completion-script fish > $(completions_folder)/general.fish

install: build completions
	mkdir -p $(bindir)
	cp -f $(release_binary) $(bindir)/$(binary)
	cp -f $(completions_folder)/_general $(zsh_completions_folder)

build:
	swift build -c release --disable-sandbox

uninstall:
	rm -rf "$(bindir)/$(binary)"

clean:
	rm -rf .build

.PHONY: build install uninstall clean completions
