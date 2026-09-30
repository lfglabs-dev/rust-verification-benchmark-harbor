# Rust Verification Benchmark v1.0: dataset documentation

100 proof tasks over real Rust code, packaged as self-contained
[Harbor](https://pypi.org/project/harbor/) tasks (Harbor 0.9.0, task schema
1.2).

**What a task is.** The agent receives the code of a Rust crate at a pinned
commit, a Lean 4 model of that code, and a specification capturing a property
the crate's authors care about. It edits one Lean file to prove the target
theorem. The implementation, specification and statement are fixed. Every
statement is true: each has a verified reference proof, hidden from the agent.

**Scope.** A proof certifies a property of the Lean model of the Rust code. It
is not a claim that an application is secure. v1.0 contains proof tasks only
(no prove-or-refute tasks).

## Task package

```
<task-id>/
  instruction.md            theorem, editable file, fixed files, rules, local check, success criterion
  task.toml                 Harbor task configuration and metadata
  environment/Dockerfile    agent image (shared Lean image + this task's public files)
  environment/workspace/    public files: Lean project, model of the code, specification,
                            editable proof file, the original Rust sources
  solution/solve.sh         installs the hidden reference proof (used by Harbor's `oracle` agent)
  tests/Dockerfile          verifier image (shared Lean image + pristine inputs + checker)
  tests/test.sh             grades the submitted file, writes /logs/verifier/{reward.txt,details.json}
```

`task.toml` sets `[verifier] environment_mode = "separate"`. Harbor collects
the editable proof file, the task's only artifact, from the agent container
and grades it in a fresh container built from `tests/`. Nothing else crosses
from the agent to the verifier. The agent image holds no reference proof and no
grader.

**Metadata** (`task.toml [metadata]`; the main fields are also in `tasks-index.json`): task id and
fingerprint, difficulty, property class, category, theorem name, editable
file, split, and the source repository, commit, crate and license.

## Scoring

`tests/test.sh` accepts a submission only if all of these hold:

1. Policy: no `sorry`, `admit`, `axiom`, `native_decide`, `implemented_by`,
   `extern`, `unsafe`, syntax extensions or debug options. Imports are limited
   to the task's specification and the standard libraries. The theorem
   statement must be unchanged.
2. The submission compiles, and is kernel-checked, against a pristine copy of
   the code and specification.
3. An independent check, which never sees the submission's source, restates
   the canonical theorem and accepts the submitted proof of it.
4. The proof depends only on `propext`, `Classical.choice` and `Quot.sound`.

Reward is `1` if every step passes and `0` otherwise; there is no partial
credit. An infrastructure failure writes no reward, exits with code 2 and
marks the attempt `invalid` in `details.json`. Such attempts must be retried
and excluded from scores.

## Resources

Each task's agent and verifier containers default to 2 CPUs and 8 GiB of RAM,
with no network access. Verifying a proof takes 19 s at the median and 148 s
at most, using 0.6 GiB of memory at the median and 2 GiB at most. All task
images share one Lean image (3.6 GB download), and each task adds about 11 MB.

## Splits

`split` in each task's metadata: 76 train, 24 evaluation. Related projects
(forks, the same author, the same implementation family) are always kept in
the same split.

## Contents

| | |
|---|---|
| Tasks | 100 |
| Source crates | 34 (MIT, Apache-2.0, Unlicense or CC0) |
| Difficulty | 21 easy, 47 medium, 32 hard |
| Property classes | equivalence with a reference implementation 33, round-trip 25, algebraic law 18, parse/serialize 7, container invariant 5, model equivalence 4, `Option`/`Result` behaviour 4, bounds 4 |
| Domains | integer and big-number arithmetic, encodings and serialization, bit manipulation, checksums, finite fields, containers, parsers |

## Limitations

- Proofs concern the Lean model of the code and the standard library models it
  relies on.
- Some tasks from the same crate share proof infrastructure. The splits keep
  related crates together.
- Difficulty labels are estimates.
