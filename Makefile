STD       = FIDUCIAL-MESH-STD-001.md
HDBK      = FIDUCIAL-MESH-HDBK-001.md
OUT_DIR   = build
STD_OUT   = $(OUT_DIR)/fiducial-mesh-std-001.pdf
HDBK_OUT  = $(OUT_DIR)/fiducial-mesh-hdbk-001.pdf
STD_LOG   = $(OUT_DIR)/std.build.log
HDBK_LOG  = $(OUT_DIR)/hdbk.build.log

# LaTeX build for Fiducial Mesh STD-001 + HDBK-001
#
# Engines: lualatex (preferred — best Unicode coverage) via pandoc.
# Requirements:
#   - pandoc            (brew install pandoc)
#   - lualatex          (MacTeX or TeX Live; ships with both)
#   - STIX Two fonts    (system on macOS; install via TeX Live otherwise)
#
# Targets:
#   make pdf      build both PDFs
#   make std      build the Standard only
#   make hdbk     build the Handbook only
#   make clean    remove build/
#
# Known follow-ons:
#   - Font tuning: STIX Two Text lacks some Unicode arrow glyphs (→, ↔).
#     Render shows missing-glyph boxes where the spec uses arrows in
#     diagrams. Fix path: configure a fallback font chain (Symbola,
#     Apple Symbols, or a custom Fiducial Mesh font stack). Cosmetic;
#     does not block the build.
#   - House-style template: currently using pandoc defaults.
#     Custom Fiducial Mesh template lands as a follow-on.

PANDOC_COMMON = \
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
	-V urlcolor=blue

.PHONY: pdf std hdbk clean

pdf: std hdbk

std: $(STD_OUT)

hdbk: $(HDBK_OUT)

$(STD_OUT): $(STD)
	@mkdir -p $(OUT_DIR)
	@pandoc $(STD) $(PANDOC_COMMON) \
		-V title="FIDUCIAL-MESH-STD-001 — Fiducial Mesh Platform Standard" \
		-V author="Fiducial Mesh Group" \
		-V date="2026-06-10" \
		-o $(STD_OUT) 2> $(STD_LOG) || (echo "STD PDF build failed — see $(STD_LOG)" && exit 1)
	@echo "Built: $(STD_OUT)"
	@warn=$$(grep -c "Missing character" $(STD_LOG) 2>/dev/null || echo 0); \
		if [ "$$warn" -gt 0 ]; then \
		echo "Note: $$warn missing-character warnings in STD (see Known follow-ons in Makefile)"; \
		fi

$(HDBK_OUT): $(HDBK)
	@mkdir -p $(OUT_DIR)
	@pandoc $(HDBK) $(PANDOC_COMMON) \
		-V title="FIDUCIAL-MESH-HDBK-001 — Fiducial Mesh Handbook" \
		-V author="Fiducial Mesh Group" \
		-V date="2026-06-10" \
		-o $(HDBK_OUT) 2> $(HDBK_LOG) || (echo "HDBK PDF build failed — see $(HDBK_LOG)" && exit 1)
	@echo "Built: $(HDBK_OUT)"
	@warn=$$(grep -c "Missing character" $(HDBK_LOG) 2>/dev/null || echo 0); \
		if [ "$$warn" -gt 0 ]; then \
		echo "Note: $$warn missing-character warnings in HDBK (see Known follow-ons in Makefile)"; \
		fi

clean:
	rm -rf $(OUT_DIR)
