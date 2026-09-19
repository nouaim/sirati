.PHONY: examples cv-ar coverletter-ar previews

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

cv-ar: $(EXAMPLES_DIR)/cv-ar.pdf
coverletter-ar: $(EXAMPLES_DIR)/coverletter-ar.pdf

$(EXAMPLES_DIR)/cv-ar.pdf: $(EXAMPLES_DIR)/cv-ar.tex $(CV_AR_SRCS)
	cd $(EXAMPLES_DIR) && $(CC) -interaction=nonstopmode cv-ar.tex

$(EXAMPLES_DIR)/coverletter-ar.pdf: $(EXAMPLES_DIR)/coverletter-ar.tex $(COVERLETTER_AR_SRCS)
	cd $(EXAMPLES_DIR) && $(CC) -interaction=nonstopmode coverletter-ar.tex

# Regenerate the README preview images from the built PDFs.
# Needs poppler-utils for pdftoppm; not required by the normal build.
previews: $(EXAMPLES_DIR)/cv-ar.pdf $(EXAMPLES_DIR)/coverletter-ar.pdf
	cd $(EXAMPLES_DIR) && for d in cv-ar coverletter-ar; do \
	  pdftoppm -r 130 -png -f 1 -l 1 $$d.pdf $$d && mv $$d-1.png $$d.png; \
	done

clean:
	rm -rf $(EXAMPLES_DIR)/*.pdf
