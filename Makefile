MAIN = main
LATEX = pdflatex
LATEXFLAGS = -interaction=nonstopmode

AUXFILES = $(MAIN).aux $(MAIN).bbl $(MAIN).blg $(MAIN).fdb_latexmk \
           $(MAIN).fls $(MAIN).log $(MAIN).out $(MAIN).toc \
           $(MAIN).synctex.gz $(MAIN).pdf

.PHONY: all clean \
        gen-caches bench bench-release \
        sp1-e2e sp1-e2e-groth16 sp1-bench-groth16 sp1-contracts-test

all: $(MAIN).pdf

$(MAIN).pdf: $(MAIN).tex packages.tex macros.tex \
             $(wildcard sections/*.tex) $(wildcard games/*.tex)
	$(LATEX) $(LATEXFLAGS) $(MAIN)
	$(LATEX) $(LATEXFLAGS) $(MAIN)

clean:
	rm -f $(AUXFILES)

# ── ZKP cache generation ──────────────────────────────────────────────────────
#
# Run once per TREE_DEPTH (edit circuit/src/merkle_circuit.rs, then run this).
# Generates test_tree_depth{D}.bin and setup_depth{D}.bin in zkp/target/.
gen-caches:
	cargo run --release --manifest-path zkp/Cargo.toml -p benchmarks --bin gen_caches

# ── ZKP benchmarks ────────────────────────────────────────────────────────────
#
# Debug (quick sanity check — slow due to unoptimised code):
bench:
	cargo bench --manifest-path zkp/Cargo.toml --bench batch_bench

# Release (real numbers — use these for the paper):
bench-release:
	cargo bench --release --manifest-path zkp/Cargo.toml --bench batch_bench

# ── SP1 / zkvm-wc ────────────────────────────────────────────────────────────

# E2E smoke test (compressed proof):
sp1-e2e:
	cd zkvm-wc && SP1_PROVER=cpu ./scripts/run_e2e.sh

# E2E smoke test (Groth16 proof — requires Docker or native-gnark):
sp1-e2e-groth16:
	cd zkvm-wc && SP1_PROVER=cpu ./scripts/run_e2e.sh --groth16

# Groth16 benchmarks across batch sizes:
sp1-bench-groth16:
	cd zkvm-wc && SP1_PROVER=cpu ./scripts/run_bench_groth16.sh

# Foundry contract tests:
sp1-contracts-test:
	cd zkvm-wc/contracts && forge test -vvv
