SPEC      = FIDUCIAL-MESH-SPEC-001.md
HDBK      = FIDUCIAL-MESH-HDBK-001.md
OUT_DIR   = build
SPEC_OUT  = $(OUT_DIR)/fiducial-mesh-spec-001.pdf
HDBK_OUT  = $(OUT_DIR)/fiducial-mesh-hdbk-001.pdf
SPEC_LOG  = $(OUT_DIR)/spec.build.log
HDBK_LOG  = $(OUT_DIR)/hdbk.build.log

# LaTeX build for Fiducial Mesh SPEC-001 + HDBK-001
#
# Engines: lualatex (preferred — best Unicode coverage) via pandoc.
# Requirements:
#   - pandoc            (brew install pandoc)
#   - lualatex          (MacTeX or TeX Live; ships with both)
#   - STIX Two fonts    (system on macOS; install via TeX Live otherwise)
#
# Targets:
#   make pdf      build both PDFs
#   make spec     build the Specification only
#   make hdbk     build the Handbook only
#   make clean    remove build/
#
# Glyph coverage: templates/glyph-fallback.tex maps prose Unicode symbols
# absent from STIX Two Text (→ ↔ ≥ ≠ ⊃ ∈) onto STIX Two Math equivalents,
# so prose renders clean. Verbatim/code blocks change catcodes, so the
# fenced lifecycle diagrams keep rendering literally in the monofont (Menlo,
# which has the arrows). Both docs build with zero missing-character warnings.

PANDOC_COMMON = \
	--pdf-engine=lualatex \
	--toc --toc-depth=3 \
	--number-sections \
	--include-in-header=templates/glyph-fallback.tex \
	-V documentclass=report \
	-V papersize=letter \
	-V geometry:margin=1in \
	-V mainfont="STIX Two Text" \
	-V monofont=Menlo \
	-V mathfont="STIX Two Math" \
	-V colorlinks=true \
	-V linkcolor=blue \
	-V urlcolor=blue \
	-V author="Gregory A. Beam (KI7MT), for the Fiducial Mesh Group"

.PHONY: pdf spec hdbk clean

pdf: spec hdbk

spec: $(SPEC_OUT)

hdbk: $(HDBK_OUT)

$(SPEC_OUT): $(SPEC) templates/glyph-fallback.tex
	@mkdir -p $(OUT_DIR)
	@pandoc $(SPEC) $(PANDOC_COMMON) \
		-V title="FIDUCIAL-MESH-SPEC-001 — Fiducial Mesh Specification" \
		-o $(SPEC_OUT) 2> $(SPEC_LOG) || (echo "SPEC PDF build failed — see $(SPEC_LOG)" && exit 1)
	@echo "Built: $(SPEC_OUT)"
	@warn=$$(grep -c "Missing character" $(SPEC_LOG) 2>/dev/null); \
		if [ "$${warn:-0}" -gt 0 ]; then \
		echo "Note: $$warn missing-character warnings in SPEC (add the glyph to templates/glyph-fallback.tex)"; \
		fi

$(HDBK_OUT): $(HDBK) templates/glyph-fallback.tex
	@mkdir -p $(OUT_DIR)
	@pandoc $(HDBK) $(PANDOC_COMMON) \
		-V title="FIDUCIAL-MESH-HDBK-001 — Fiducial Mesh Handbook" \
		-o $(HDBK_OUT) 2> $(HDBK_LOG) || (echo "HDBK PDF build failed — see $(HDBK_LOG)" && exit 1)
	@echo "Built: $(HDBK_OUT)"
	@warn=$$(grep -c "Missing character" $(HDBK_LOG) 2>/dev/null); \
		if [ "$${warn:-0}" -gt 0 ]; then \
		echo "Note: $$warn missing-character warnings in HDBK (add the glyph to templates/glyph-fallback.tex)"; \
		fi

clean:
	rm -rf $(OUT_DIR)
