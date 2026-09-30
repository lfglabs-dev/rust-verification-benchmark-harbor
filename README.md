# Rust Verification Benchmark v1.0

100 Harbor tasks. Each task gives the agent the code of an open-source Rust
crate, a Lean 4 model of that code, and a specification derived from a
property the crate's authors test. The agent must prove the target theorem by
editing one Lean file. The verifier kernel-checks the proof and writes a
binary reward (1 or 0).

## Tasks

- 100 tasks from 34 crates. Domains: integer and big-number arithmetic,
  encodings, bit manipulation, checksums, finite fields, containers, parsers.
- Difficulty: 21 easy, 47 medium, 32 hard. Splits: 76 train, 24 eval; related
  crates share a split.
- Every statement has a verified reference proof, hidden from the agent.
- Sources are MIT, Apache-2.0, Unlicense or CC0. Each task records its
  repository, commit and license.
- Runs offline. One verification takes about 19 s and 0.6 GiB (median),
  148 s and 2 GiB (max).

## Grading

A submission scores 1 only if all of these hold:

1. No `sorry`, `admit`, `axiom`, `native_decide`, `implemented_by`, `extern`,
   syntax extensions or forbidden imports, and the theorem statement is
   unchanged.
2. It compiles and is kernel-checked against a pristine copy of the code and
   specification.
3. An independent module that restates the canonical theorem accepts the proof.
4. Its axioms are a subset of `propext`, `Classical.choice`, `Quot.sound`.

Grading runs in a separate container built from `tests/`. Only the editable
proof file crosses over from the agent container, so edits to the
specification or the code inside the agent's environment have no effect.
Infrastructure failures write no reward and mark the attempt `invalid`.

Validated on all 100 tasks:
- the reference proof scores 1;
- each of these scores 0: an empty proof, `sorry`, an extra axiom, a forbidden
  import, a weakened statement, a redefined specification.

Also checked end to end with Harbor: an agent that rewrites the specification
to `True` in its own container scores 0.

## Contents

| file | contents |
|---|---|
| `rvb-tasks-v1.0.tar.zst` | the 100 Harbor tasks |
| `tasks-index.json` | per task: id, difficulty, property class, split, source project, license, fingerprints |
| `DATASET.md` | task format, scoring, splits, metadata, resources |
| `validation-v1.0.json` | per-task validation results |
| `sample-trajectories/` | 6 GLM 5.3 Flash runs (5 solved): conversation, tool calls, proofs, verdict |

## Usage

Requires Docker, Python ≥ 3.12, x86_64 Linux and about 20 GB of disk. The
shared Lean image (3.6 GB) is private: log in to `ghcr.io` with the
credentials we provide (`read:packages`).

```bash
pip install harbor==0.9.0
echo <TOKEN> | docker login ghcr.io -u <GITHUB_USER> --password-stdin
docker pull ghcr.io/lfglabs-dev/rvb-lean-deps@sha256:a31dc0e4b707a3f419cdfa34af1ba5c5f7d147a401caad720e2e5b17cc3293e2
tar --zstd -xf rvb-tasks-v1.0.tar.zst
harbor run -p tasks/rvb-uint--u64--associative-add -a oracle -e docker   # 1.0
harbor run -p tasks/rvb-uint--u64--associative-add -a nop -e docker      # 0.0
harbor run -p tasks -a <agent> -m <model> -e docker -n 4
```

All task and verifier images build `FROM` this digest.

## Planned

- Full trajectory set (one attempt per task) and the final validation report
  with checksums.
- Larger task sets, prove-or-refute tasks (disproof by counterexample), other
  source languages.
