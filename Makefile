SPEC      = FIDUCIAL-MESH-SPEC.md
OUT_DIR   = build
OUT       = $(OUT_DIR)/fiducial-mesh-spec.pdf
LOG       = $(OUT_DIR)/build.log

# LaTeX build for FIDUCIAL-MESH-SPEC.md
#
# Engines: lualatex (preferred — best Unicode coverage) via pandoc.
# Requirements:
#   - pandoc            (brew install pandoc)
#   - lualatex          (MacTeX or TeX Live; ships with both)
#   - STIX Two fonts    (system on macOS; install via TeX Live otherwise)
#
# Targets:
#   make pdf     build the PDF (build/fiducial-mesh-spec.pdf)
#   make clean   remove build/
#
# Known follow-ons:
#   - Font tuning: STIX Two Text lacks some Unicode arrow glyphs (→, ↔).
#     Render shows missing-glyph boxes where the spec uses arrows in
#     diagrams. Fix path: configure a fallback font chain (Symbola,
#     Apple Symbols, or a custom Fiducial Mesh font stack). Cosmetic;
#     does not block the build.
#   - House-style template: currently using pandoc defaults.
#     Custom Fiducial Mesh template lands as a follow-on.

.PHONY: pdf clean

pdf: $(OUT)

$(OUT): $(SPEC)
	@mkdir -p $(OUT_DIR)
	@pandoc $(SPEC) \
		--pdf-engine=lualatex \
		--toc --toc-depth=3 \
		--number-sections \
		-V documentclass=report \
		-V papersize=letter \
		-V geometry:margin=1in \
		-V mainfont="STIX Two Text" \
		-V monofont=Menlo \
		-V mathfont="STIX Two Math" \
		-V colorlinks=true \
		-V linkcolor=blue \
		-V urlcolor=blue \
		-V title="Fiducial Mesh Specification" \
		-V author=Watson \
		-V date="2026-06-08" \
		-o $(OUT) 2> $(LOG) || (echo "PDF build failed — see $(LOG)" && exit 1)
	@echo "Built: $(OUT)"
	@warn=$$(grep -c "Missing character" $(LOG) 2>/dev/null || echo 0); \
		if [ "$$warn" -gt 0 ]; then \
		echo "Note: $$warn missing-character warnings (see Known follow-ons in Makefile)"; \
		fi

clean:
	rm -rf $(OUT_DIR)
