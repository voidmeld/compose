# Tiny fresh-agent check

The routine check is one fresh agent, one Compose candidate, one small panel task, and one
five-minute attempt. It measures whether the public documentation enables a correct small change.
It is exploratory evidence, not a framework or model ranking. Larger comparative fields remain
separate research and are not a prerequisite for an ordinary Compose change.

Give the agent a clean starter containing the exact public core and Roblox adapter, the emulated
host, the task contract, and Compose's own documentation. Start its documentation route at
`docs/quickstart.md`. The agent edits only its solution directory, without network or other agents.

The task has an always-present item summary and a conditional selected-item detail. Updates must
preserve the summary node and avoid rewriting it when only selection changes. Disposal must leave
the borrowed container alive and release all created instances and connections. Keep acceptance
assertions outside the starter until the agent has finished; run them once against its submitted
solution. A loading smoke check is not acceptance.

Before dispatch, record source commit/tree, starter-file hashes, task and assertion hashes, prompt,
model/harness configuration, deadline and stopping rule. Stop at completion or the deadline; do not
silently grant another attempt after failure. Retain every started attempt and its original output.
Record wall time, actual reported input/output/cache tokens, tool calls, visible failures, final
correctness and exact retention. Missing token or model metadata stays unavailable, never estimated.

Report acceptance before efficiency. Charge failed work and evaluator setup/checking separately
from agent execution. One passing trial proves this one task at these inputs; it does not establish
broad ergonomics, future autonomous delivery, or engine rendering performance.
