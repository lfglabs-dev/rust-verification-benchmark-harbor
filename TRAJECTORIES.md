# Trajectories v1.0

`rvb-trajectories-v1.0.tar.zst` holds one agent attempt for each of the 100
tasks. The attempts come from GLM 5.3 Flash (`glm-5.3-flash`, temperature 0.7,
16k max completion tokens per turn) driven by a tool-calling agent. Each
attempt is graded by the task's own verifier in a separate container.

| | |
|---|---|
| attempts | 100 (one per task) |
| solved (reward 1) | 37: 18/21 easy, 19/47 medium, 0/32 hard |
| by split | train 25/76, eval 12/24 |
| unsolved, by termination | 47 budget exhausted, 16 stopped calling tools |
| agent budget | up to 200 turns, 300 tool calls, 40 proof submissions, 100 min |

Only valid attempts are included. A valid attempt has a verifier reward and an
agent that stopped for a model-driven reason. Attempts lost to infrastructure
failures (provider rate limits, interrupted runs) were discarded and rerun, and
are never counted as failures.

## Layout

```
index.ndjson                     one row per attempt
summary.json                     counts
<task-id>/glm-5.3-flash-extended/attempt-1/
    events.ndjson                normalized event stream (below)
    final.lean                   the file the verifier graded
    agent/agent-config.json      model, endpoint, sampling, budget, system prompt
    agent/conversation.jsonl     every message sent to and received from the model
    agent/tool-calls.jsonl       every tool call: arguments, duration, full result
    agent/attempts/NN.lean       every proof submitted for checking
    agent/agent-result.json      termination reason, counters, token usage
    verifier/reward.txt          1 or 0
    verifier/details.json        verifier status, axioms, hash of the graded file
    verifier/test-stdout.txt     verifier output
```

**`index.ndjson` fields:** `attempt_id`, `task_id`, `task_ref`, `config_id`,
`attempt_number`, `split`, `task_fingerprint`, `task_set_id`,
`benchmark_version`, `valid`, `invalid_reason`, `counted`, `reward`, `verifier_status`,
`termination_reason`, `final_sha256`, `graded_sha256`,
`artifact_matches_graded`, `turns`, `tool_calls`, `usage`, `duration_seconds`,
`path`.

`final_sha256` and `graded_sha256` are equal for every attempt.

## Events (`events.ndjson`, schema `rvb-trajectory-events/1`)

Each line has `schema`, `attempt_id`, `seq` and `type`:

| type | fields |
|---|---|
| `attempt_start` | task identity, model, endpoint, sampling, budget, fingerprints, start time |
| `system_message` | `content` |
| `user_message` | `content` (task instruction and editable file, or a harness nudge) |
| `assistant_message` | `content`, `tool_calls` (OpenAI format), `provider_reasoning`, `finish_reason`, `usage` |
| `tool_result` | `tool_call_id`, `tool`, `arguments`, `content` (exactly what the model saw), `turn`, `seconds` |
| `proof_submission` | `number`, `sha256`, `text` |
| `agent_end` | `termination_reason`, `turns`, `tool_calls`, `check_proof_attempts`, `usage`, `duration_seconds`, `error` |
| `verification` | `reward`, `status`, `outcome`, `axioms`, `graded_sha256`, `detail` |
| `harness_event` | other harness records (for example context compaction) |

`provider_reasoning` is the reasoning text returned by the provider API, or
`null` if it returned none. `usage` is what the provider reported. Tool
results are recorded exactly as the model received them, including any
truncation.
