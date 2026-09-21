.PHONY: examples cv-ar coverletter-ar previews colours docker-image docker docker-previews docker-test clean

EXAMPLES_DIR = examples

# The examples ARE the Arabic documents: a CV and a cover letter.  Both are
# self-contained XeLaTeX documents that use polyglossia for right-to-left
# typesetting, so no other engine is needed.
# Build everything with:  make
CC = xelatex

CV_AR_DIR = $(EXAMPLES_DIR)/cv-ar
CV_AR_SRCS = $(shell find $(CV_AR_DIR) -name '*.tex')
COVERLETTER_AR_DIR = $(EXAMPLES_DIR)/coverletter-ar
COVERLETTER_AR_SRCS = $(shell find $(COVERLETTER_AR_DIR) -name '*.tex')

examples: cv-ar coverletter-ar

# The icon set and its style are arguments to the document targets rather than
# targets of their own:
#
#   make cv-ar                                  # Font Awesome, filled: the default
#   make cv-ar ICONS=material STYLE=outlined    # Material Icons, outlined
#   make ICONS=material                         # both documents, that set
#
# Nothing under examples/ changes: both switches go to XeLaTeX on the command
# line.  The default pair keeps the plain names the READMEs, the previews and the
# test suite use; any other pair lands beside them as
# examples/cv-ar-<set>-<style>.pdf, which is build output and is never committed.
# STYLE is filled, outlined, round, sharp or twotone, where outlined is Font
# Awesome's regular; the Material families come from install.sh.
ICONS ?= fa
STYLE ?= filled
ICON_SUFFIX = $(if $(filter-out fa-filled,$(ICONS)-$(STYLE)),-$(ICONS)-$(STYLE),)

cv-ar: $(EXAMPLES_DIR)/cv-ar$(ICON_SUFFIX).pdf
coverletter-ar: $(EXAMPLES_DIR)/coverletter-ar$(ICON_SUFFIX).pdf

$(EXAMPLES_DIR)/cv-ar$(ICON_SUFFIX).pdf: $(EXAMPLES_DIR)/cv-ar.tex $(CV_AR_SRCS)
	cd $(EXAMPLES_DIR) && $(CC) -interaction=nonstopmode -jobname=cv-ar$(ICON_SUFFIX) \
	  '\def\cvIconSet{$(ICONS)}\def\cvIconStyle{$(STYLE)}\input{cv-ar.tex}'

$(EXAMPLES_DIR)/coverletter-ar$(ICON_SUFFIX).pdf: $(EXAMPLES_DIR)/coverletter-ar.tex $(COVERLETTER_AR_SRCS)
	cd $(EXAMPLES_DIR) && $(CC) -interaction=nonstopmode -jobname=coverletter-ar$(ICON_SUFFIX) \
	  '\def\cvIconSet{$(ICONS)}\def\cvIconStyle{$(STYLE)}\input{coverletter-ar.tex}'

# Regenerate the README preview images from the built PDFs.
# Needs poppler-utils for pdftoppm; not required by the normal build.
# 200 dpi: the README shows a preview up to 820px wide, so the file must carry
# 1640px to stay sharp on a 2x display.  The test suite reads this number.
previews: $(EXAMPLES_DIR)/cv-ar.pdf $(EXAMPLES_DIR)/coverletter-ar.pdf
	cd $(EXAMPLES_DIR) && for d in cv-ar coverletter-ar; do \
	  pdftoppm -r 200 -png -f 1 -l 1 $$d.pdf $$d && mv $$d-1.png $$d.png; \
	done

# The same document in four other accents, for the README.  They are committed,
# and the Refresh colour previews workflow regenerates them whenever the sources
# change, so they have one owner: a rendering made here would differ from the
# container's by a fraction of a percent and cause a commit every time.  This
# target is for looking at a colour you are considering.
colours:
	scripts/make-colours.sh

clean:
	rm -rf $(EXAMPLES_DIR)/*.pdf


# The same build with nothing installed on this machine: these targets build the
# image from the Dockerfile and run the build inside it.  The explicit form is
#
#   docker build -t sirati .
#   docker run --rm --user $$(id -u):$$(id -g) -v "$$PWD":/doc -w /doc sirati make
#
# That trailing `make` is this same Makefile, run inside the image, so replace it
# with any target to build just that one - `make cv-ar` for the CV alone, or
# `make previews`.  The `docker` target does the same through a variable, and the
# icon arguments travel with it:
#
#   make docker                              # both documents
#   make docker TARGET=cv-ar                 # just cv-ar, inside the image
#   make docker TARGET=cv-ar ICONS=material  # and with another icon set
#
# `--user` keeps the generated PDFs owned by you rather than root.
#
# Note the split: `make`, `make cv-ar` and `make previews` run on this machine and
# need XeLaTeX installed here.  The `docker-*` targets and `TARGET=` are what you
# use when it is not installed, and they hand the work to the image.
TARGET ?=
IMAGE = sirati
DOCKER_RUN = docker run --rm --user "$$(id -u):$$(id -g)" -v "$(CURDIR)":/doc -w /doc $(IMAGE)

docker-image:
	docker build -t $(IMAGE) .

docker: docker-image
	$(DOCKER_RUN) make $(TARGET) ICONS=$(ICONS) STYLE=$(STYLE)

docker-previews: docker-image
	$(DOCKER_RUN) make previews

docker-test: docker-image
	$(DOCKER_RUN) tests/check-arabic-examples.sh
