# Rust Verification Benchmark v1.0

**100 ready-to-run Harbor environments that measure whether an AI agent can
formally prove that real-world Rust code meets its specification.**

In each environment, the agent receives production Rust code from a
widely used open-source crate, a faithful Lean 4 model of that code, and a
specification that expresses the crate authors' own intent. It must write a
Lean proof that the code satisfies the specification. The Lean kernel then
checks the proof: the reward is **1 or 0, with no partial credit, no LLM judge
and no way to game it.**

## Why it matters

- **A reward you can trust.** Grading is a machine-checked proof, not tests or
  a model's opinion. That makes it a clean reward signal for RL and a hard,
  unambiguous benchmark for evaluation.
- **Real code, not puzzles.** Tasks come from 34 open-source crates: integer
  and big-number arithmetic, encodings and serialization, bit manipulation,
  hashing and checksums, finite fields, containers and parsers.
- **It separates frontier models.** Tasks range from short proofs to long,
  multi-lemma developments (21 easy, 47 medium, 32 hard).
- **Hardened against cheating** (details below): every known shortcut scores 0.
- **Commercially clean.** Every source crate is MIT, Apache-2.0, Unlicense or
  CC0, with the repository, commit and license recorded for each task.

## What's in this repository

| file | contents |
|---|---|
| `rvb-tasks-v1.0.tar.zst` | the 100 Harbor tasks (extract with `tar --zstd -xf`) |
| `tasks-index.json` | one row per task: id, difficulty, property class, split, source project and license, fingerprints |
| `DATASET.md` | task format, scoring, anti-cheating, splits, metadata |
| `validation-v1.0.json` | per-task validation results |
| `sample-trajectories/` | 6 agent runs by GLM 5.3 Flash (5 solved, 1 failed): full conversation, tool calls, submitted proofs, verifier verdict |

Each task has a **verified reference proof** (hidden from the agent) and ships
with train/evaluation splits (76 / 24). A task runs fully offline. One
verification takes about 19 s and 0.6 GiB (median).

## Anti-cheating, validated on all 100 tasks

- The reference proof scores 1.
- These submissions all score 0: an empty proof, `sorry` or `admit`, an extra
  `axiom`, a forbidden import, a weakened theorem statement, and a redefined
  specification. Only Lean's standard axioms are accepted.
- The agent cannot see the solution, the grader or any hidden material.
- Grading happens in a **separate, pristine container**. An agent that edits
  the specification inside its own environment, so that a fake proof compiles
  there, still scores 0. This was tested end to end.
- Infrastructure failures give no reward, never a false 0.

## Quick start

Requirements: Docker, Python ≥ 3.12, x86_64 Linux, about 20 GB of disk.

Your access to this repository also lets you pull the shared Lean image
(`ghcr.io/lfglabs-dev/rvb-lean-deps`, private, 3.6 GB). Log in to `ghcr.io`
with your GitHub user and a personal access token with the `read:packages`
scope.

```bash
git clone https://github.com/lfglabs-dev/rust-verification-benchmark-harbor.git
cd rust-verification-benchmark-harbor
pip install harbor==0.9.0
echo <TOKEN> | docker login ghcr.io -u <GITHUB_USER> --password-stdin
docker pull ghcr.io/lfglabs-dev/rvb-lean-deps@sha256:a31dc0e4b707a3f419cdfa34af1ba5c5f7d147a401caad720e2e5b17cc3293e2
tar --zstd -xf rvb-tasks-v1.0.tar.zst
harbor run -p tasks/rvb-uint--u64--associative-add -a oracle -e docker   # reference proof: 1.0
harbor run -p tasks/rvb-uint--u64--associative-add -a nop -e docker      # empty submission: 0.0
harbor run -p tasks -a <your-agent> -m <model> -e docker -n 4            # full run
```

Every task Dockerfile builds `FROM` that exact digest, so the image is pulled
once and reused by all 200 task and verifier images.

## Coming next

- The full trajectory set (one agent attempt on each of the 100 tasks) and the
  final validation report with checksums.
- On request: larger volumes at the same quality, **prove-or-refute** tasks
  (false statements the model must disprove with a counterexample), and more
  source languages.
