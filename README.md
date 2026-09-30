# Rust Verification Benchmark v1.0

**100 Harbor environments that measure whether an AI agent can formally prove
that real-world Rust code meets its specification.**

Each environment gives the agent production code from an open-source Rust
crate, a faithful Lean 4 model of that code, and a specification written from
the crate authors' own intent. The agent writes a Lean proof. The Lean kernel
checks it and gives a reward of **1 or 0: no partial credit, no LLM judge,
nothing to game.**

## Why it matters

- **A reward you can trust.** A machine-checked proof, not tests or a model's
  opinion. That makes it a clean signal for RL and an unambiguous benchmark
  for evaluation.
- **Real code.** 34 crates: integer and big-number arithmetic, encodings,
  bit manipulation, checksums, finite fields, containers, parsers.
- **Separates frontier models.** Tasks range from short proofs to multi-lemma
  developments: 21 easy, 47 medium, 32 hard.
- **Commercially clean.** Every crate is MIT, Apache-2.0, Unlicense or CC0.
  Each task records its repository, commit and license.

Every task has a hidden, verified reference proof and a train/eval split
(76 / 24), and runs fully offline. One verification takes about 19 s and
0.6 GiB (median).

## Anti-cheating (validated on all 100 tasks)

- The reference proof scores 1.
- These all score 0: an empty proof, `sorry` or `admit`, an extra `axiom`, a
  forbidden import, a weakened statement, a redefined specification. Only
  Lean's standard axioms are accepted.
- The agent never sees the solution or the grader.
- Grading runs in a **separate, pristine container**. An agent that rewrites
  the specification in its own environment, so that a fake proof compiles
  there, still scores 0 (tested end to end).
- Infrastructure failures give no reward, never a false 0.

## Contents

| file | contents |
|---|---|
| `rvb-tasks-v1.0.tar.zst` | the 100 Harbor tasks |
| `tasks-index.json` | per task: id, difficulty, property class, split, source project, license, fingerprints |
| `DATASET.md` | task format, scoring, splits, metadata, resources |
| `validation-v1.0.json` | per-task validation results |
| `sample-trajectories/` | 6 GLM 5.3 Flash runs (5 solved): conversation, tool calls, proofs, verdict |

## Quick start

Requirements: Docker, Python ≥ 3.12, x86_64 Linux, about 20 GB of disk.
The shared Lean image (3.6 GB) is private. Log in to `ghcr.io` with the
credentials we provide (`read:packages`).

```bash
pip install harbor==0.9.0
echo <TOKEN> | docker login ghcr.io -u <GITHUB_USER> --password-stdin
docker pull ghcr.io/lfglabs-dev/rvb-lean-deps@sha256:a31dc0e4b707a3f419cdfa34af1ba5c5f7d147a401caad720e2e5b17cc3293e2
tar --zstd -xf rvb-tasks-v1.0.tar.zst
harbor run -p tasks/rvb-uint--u64--associative-add -a oracle -e docker   # reference proof: 1.0
harbor run -p tasks/rvb-uint--u64--associative-add -a nop -e docker      # empty submission: 0.0
harbor run -p tasks -a <your-agent> -m <model> -e docker -n 4            # full run
```

All task and verifier images build `FROM` this digest, so the image is pulled
once.

## Coming next

- Full trajectory set (one attempt per task) and the final validation report
  with checksums.
- On request: larger volumes at the same quality, **prove-or-refute** tasks
  (disprove false statements with a counterexample), and more source languages.
