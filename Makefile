.PHONY: examples cv-ar coverletter-ar

CC = lualatex
EXAMPLES_DIR = examples
RESUME_DIR = examples/resume
RESUME_SRCS = $(shell find $(RESUME_DIR) -name '*.tex')

# Arabic (RTL) examples.
# Built with XeLaTeX, not the LuaLaTeX used by the class-based resume above,
# because they rely on polyglossia for right-to-left typesetting.
# Build them with:  make cv-ar    /    make coverletter-ar
AR_CC = xelatex
CV_AR_DIR = $(EXAMPLES_DIR)/cv-ar
CV_AR_SRCS = $(shell find $(CV_AR_DIR) -name '*.tex')
COVERLETTER_AR_DIR = $(EXAMPLES_DIR)/coverletter-ar
COVERLETTER_AR_SRCS = $(shell find $(COVERLETTER_AR_DIR) -name '*.tex')

examples: resume.pdf

cv-ar: $(EXAMPLES_DIR)/cv-ar.pdf
coverletter-ar: $(EXAMPLES_DIR)/coverletter-ar.pdf

$(EXAMPLES_DIR)/cv-ar.pdf: $(EXAMPLES_DIR)/cv-ar.tex $(CV_AR_SRCS)
	cd $(EXAMPLES_DIR) && $(AR_CC) -interaction=nonstopmode cv-ar.tex

$(EXAMPLES_DIR)/coverletter-ar.pdf: $(EXAMPLES_DIR)/coverletter-ar.tex $(COVERLETTER_AR_SRCS)
	cd $(EXAMPLES_DIR) && $(AR_CC) -interaction=nonstopmode coverletter-ar.tex

resume.pdf: $(EXAMPLES_DIR)/resume.tex $(RESUME_SRCS)
	$(CC) -output-directory=$(EXAMPLES_DIR) $<

clean:
	rm -rf $(EXAMPLES_DIR)/*.pdf
