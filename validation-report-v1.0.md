# Validation report: Rust Verification Benchmark v1.0

## Exported task packages (every task)

| check | result |
|---|---|
| tasks passing all checks | 100/100 |
| agent image isolated (no reference proof, reviews, `/tests`, git history) | 100/100 |
| blank skeleton elaborates offline in the agent image (only the deliberate hole) | 100/100 |
| reference proof graded reward 1 by the task's own verifier image | 100/100 |
| every negative submission rejected with reward 0 (blank_skeleton, extra_axiom, forbidden_import, sorry, spec_shadowing, weakened_statement) | 100/100 |
| simulated verifier infrastructure failure yields no reward (`invalid`) | 100/100 |

## Harbor end-to-end runs (task sample, `harbor run -e docker`)

Oracle installs the reference proof (expected reward 1); nop submits the blank skeleton (0); tamper rewrites the fixed specification to `True` inside the agent container and submits the then-trivial proof (0: the separate verifier grades against pristine inputs).

| agent | task | reward | expected |
|---|---|---|---|
| nop | `rvb-arxid--permute--round-trip-over-the-whole-domain` | 0 | 0 ✓ |
| nop | `rvb-blue--scrunch-binary-search--binary-search-finds-index` | 0 | 0 ✓ |
| nop | `rvb-openpql-prelude--util--mixed-radix-roundtrip` | 0 | 0 ✓ |
| nop | `rvb-succinct--broadword--count-ones-matches-std` | 0 | 0 ✓ |
| nop | `rvb-uint--u64--associative-add` | 0 | 0 ✓ |
| nop | `rvb-varing--packable--roundtrip-u64` | 0 | 0 ✓ |
| oracle | `rvb-arxid--permute--round-trip-over-the-whole-domain` | 1 | 1 ✓ |
| oracle | `rvb-blue--scrunch-binary-search--binary-search-finds-index` | 1 | 1 ✓ |
| oracle | `rvb-openpql-prelude--util--mixed-radix-roundtrip` | 1 | 1 ✓ |
| oracle | `rvb-succinct--broadword--count-ones-matches-std` | 1 | 1 ✓ |
| oracle | `rvb-uint--u64--associative-add` | 1 | 1 ✓ |
| oracle | `rvb-varing--packable--roundtrip-u64` | 1 | 1 ✓ |
| tamper | `rvb-arxid--permute--round-trip-over-the-whole-domain` | 0 | 0 ✓ |
| tamper | `rvb-blue--scrunch-binary-search--binary-search-finds-index` | 0 | 0 ✓ |
| tamper | `rvb-openpql-prelude--util--mixed-radix-roundtrip` | 0 | 0 ✓ |
| tamper | `rvb-succinct--broadword--count-ones-matches-std` | 0 | 0 ✓ |
| tamper | `rvb-uint--u64--associative-add` | 0 | 0 ✓ |
| tamper | `rvb-varing--packable--roundtrip-u64` | 0 | 0 ✓ |

## Resources

Reference-proof verification (verifier container, 2 CPUs / 8 GiB limit per `task.toml`): wall time min 15.2 s, median 18.8 s, p95 37.5 s, max 148.1 s; peak memory median 0.55 GiB, p95 0.79 GiB, max 1.99 GiB.

Images: every task image is `FROM rvb-lean-deps:1.0` (≈15 GB uncompressed, shared) plus ≈11 MB of task layers, so the dependency image plus all 200 task/verifier images take ≈17 GB.

## Trajectories

```json
{
 "schema": "rvb-trajectory-events/1",
 "benchmark_version": "1.0",
 "task_set_id": "sha256:a67bbf2739f2a8a1f86a662fd145a5dda1ba85230bb204d73bae4659f72aba12",
 "target_attempts_per_task": 1,
 "task_count": 100,
 "counted_attempts": 100,
 "per_config": {
  "glm-5.3-flash-extended": {
   "attempts_total": 120,
   "valid": 106,
   "invalid": 14,
   "counted": 100,
   "counted_passed": 37
  }
 },
 "tasks_complete_per_config": {
  "glm-5.3-flash-extended": 100
 },
 "artifact_mismatches": []
}
```

## Archives

| file | size | sha256 |
|---|---:|---|
| `rvb-tasks-v1.0.tar.zst` | 0.01 GiB | `429c5ba783082dd453fd8ce801cab21ff17dc2fff03378f567ece925e58fca22` |
| `rvb-trajectories-v1.0.tar.zst` | 0.01 GiB | `98b3cd5eb465f55008329f44c33bd8babbabbbba65bc9d43988203c9c4657166` |
