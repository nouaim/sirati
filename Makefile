.PHONY: examples cv-ar

CC = lualatex
EXAMPLES_DIR = examples
RESUME_DIR = examples/resume
CV_DIR = examples/cv
RESUME_SRCS = $(shell find $(RESUME_DIR) -name '*.tex')
CV_SRCS = $(shell find $(CV_DIR) -name '*.tex')

# Arabic (RTL) example CV.
# Built with XeLaTeX, not the LuaLaTeX used by the class-based examples above,
# because it relies on polyglossia for right-to-left typesetting.
# Build it with:  make cv-ar
AR_CC = xelatex
CV_AR_DIR = $(EXAMPLES_DIR)/cv-ar
CV_AR_SRCS = $(shell find $(CV_AR_DIR) -name '*.tex')

examples: $(foreach x, coverletter cv resume, $x.pdf)

cv-ar: $(EXAMPLES_DIR)/cv-ar.pdf

$(EXAMPLES_DIR)/cv-ar.pdf: $(EXAMPLES_DIR)/cv-ar.tex $(CV_AR_SRCS)
	cd $(EXAMPLES_DIR) && $(AR_CC) -interaction=nonstopmode cv-ar.tex

resume.pdf: $(EXAMPLES_DIR)/resume.tex $(RESUME_SRCS)
	$(CC) -output-directory=$(EXAMPLES_DIR) $<

cv.pdf: $(EXAMPLES_DIR)/cv.tex $(CV_SRCS)
	$(CC) -output-directory=$(EXAMPLES_DIR) $<

coverletter.pdf: $(EXAMPLES_DIR)/coverletter.tex
	$(CC) -output-directory=$(EXAMPLES_DIR) $<

clean:
	rm -rf $(EXAMPLES_DIR)/*.pdf
