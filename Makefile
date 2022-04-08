# \ var
MODULE  = $(notdir $(CURDIR))
OS      = $(shell uname -o|tr / _)
NOW     = $(shell date +%d%m%y)
REL     = $(shell git rev-parse --short=4 HEAD)
BRANCH  = $(shell git rev-parse --abbrev-ref HEAD)
PEPS    = E26,E302,E305,E401,E402,E701,E702
# / var

# \ dir
CWD = $(CURDIR)
BIN = $(CWD)/bin
DOC = $(CWD)/doc
LIB = $(CWD)/lib
SRC = $(CWD)/src
TMP = $(CWD)/tmp
# / dir

# \ tool
CURL    = curl -L -o
CF      = clang-format-11 -i
PY      = $(shell which python3)
PIP     = $(shell which pip3)
PEP     = $(shell which autopep8) --ignore=$(PEPS) --in-place
LATEX   = pdflatex -halt-on-error -output-directory=$(TMP)
# / tool

# \ src
Y += $(MODULE).meta.py metaL.py
S += $(Y)

TEX  = tex/$(MODULE).tex tex/header.tex tex/bib.tex tmp/build.tex
TEX += tex/intro.tex tex/install.tex
TEX += tex/makefile.tex tex/git.tex
# / src

# \ all
all:
	$^
	$(MAKE) format

meta: $(PY) $(MODULE).meta.py
	$^
	$(MAKE) format

.PHONY: pdf
pdf: tmp/$(MODULE).pdf
# / all

# \ format
.PHONY: format
format: tmp/format_py
tmp/format_py: $(Y)
	$(PEP) $? && touch $@
# / format

# \ rule
tmp/$(MODULE).pdf: $(TEX) $(FIG)
	$(LATEX) $< && $(LATEX) $<
tmp/%.png: tex/fig/%.dot
	dot -Tpng -o $@ $<
tmp/build.tex: .git/index
	echo "\date{ver: $(BRANCH)-$(REL)-$(NOW)}" > $@
# / rule

# \ doc
doc: doc/.gitignore
doc/.gitignore:
	git clone -o bb git@bitbucket.org:ponyatov/doc.git

doxy: doxy.gen
	rm -rf docs ; doxygen $< 1>/dev/null
# / doc

# \ install
.PHONY: install update
install: $(OS)_install gz doc
	$(MAKE) update

update: $(OS)_update
	$(PIP) install --user -U pip autopep8 pytest

.PHONY: GNU_Linux_install GNU_Linux_update
GNU_Linux_install GNU_Linux_update:
	sudo apt update
	sudo apt install -u `cat apt.txt apt.dev`

# \ gz
.PHONY: gz
gz:
# / gz
# / install

# \ merge
MERGE  = Makefile README.md .gitignore apt.txt apt.dev .clang-format $(S)
MERGE += .vscode bin doc lib src tmp

.PHONY: dev shadow release zip

dev:
	git push -v
	git checkout $@
	git pull -v
	git checkout shadow -- $(MERGE)

shadow:
	git push -v
	git checkout $@
	git pull -v

release:
	git tag $(NOW)-$(REL)
	git push -v --tags
	$(MAKE) shadow

ZIP = tmp/$(MODULE)_$(BRANCH)_$(NOW)_$(REL).src.zip
zip:
	git archive --format zip --output $(ZIP) HEAD
	$(MAKE) doxy ; zip -r $(ZIP) docs
# / merge
