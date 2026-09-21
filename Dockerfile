# The whole toolchain, so that nothing has to be installed on the host.
#
#   docker build -t sirati .
#   docker run --rm --user $(id -u):$(id -g) -v "$PWD":/doc -w /doc sirati make
#
# The plain `texlive/texlive:latest` image is not enough on its own: it carries
# every LaTeX package these documents use (polyglossia, bidi and fontawesome7
# included) and the Roboto family, but not the Arabic font, not the Material Icons
# family `make material-cv` draws with, and no poppler-utils.
FROM texlive/texlive:latest

# pdftoppm, pdfinfo and pdftotext come from poppler-utils: `make previews` and
# tests/check-arabic-examples.sh both need them.
RUN apt-get update \
 && apt-get install --yes --no-install-recommends poppler-utils ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

# Tajawal has no Debian or Ubuntu package, so fetch it from upstream Google Fonts
# (SIL OFL 1.1) and install it as a system font family.  Material Icons, the other
# icon set the documents can draw with, comes from Google as well (Apache 2.0);
# the base image has neither.
ARG TAJAWAL_BASE=https://raw.githubusercontent.com/google/fonts/main/ofl/tajawal
ARG MATERIALICONS_BASE=https://raw.githubusercontent.com/google/material-design-icons/master/font
RUN mkdir -p /usr/local/share/fonts/tajawal /usr/local/share/fonts/materialicons \
 && for f in Tajawal-Regular.ttf Tajawal-Bold.ttf Tajawal-Medium.ttf; do \
      curl -fsSL -o "/usr/local/share/fonts/tajawal/$f" "$TAJAWAL_BASE/$f"; \
    done \
 && curl -fsSL -o /usr/local/share/fonts/materialicons/MaterialIcons-Regular.ttf \
      "$MATERIALICONS_BASE/MaterialIcons-Regular.ttf" \
 && fc-cache -f

# Fail the build here rather than in LaTeX: fc-match silently substitutes a
# fallback when a family is missing.
RUN fc-match Tajawal | grep -qi tajawal && fc-match Roboto | grep -qi roboto \
 && fc-match "Material Icons" | grep -qi "material icons"

WORKDIR /doc
CMD ["make"]
