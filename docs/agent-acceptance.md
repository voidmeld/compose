# Tiny fresh-agent check

Use one fresh agent, one Compose candidate and one small panel task. Allow one five-minute attempt.
The check measures whether the public documentation supports a correct small change.
It does not rank frameworks or models. Broader comparisons belong in research and are not required for an ordinary Compose change.

Give the agent a clean starter with the exact public core, Roblox adapter, emulated host, task contract and Compose documentation.
Start at `docs/quickstart.md`. Allow edits only in the solution directory. Do not allow network access or other agents.

The task has an always-present item summary and a conditional selected-item detail. Updates must
preserve the summary node. A selection-only change must not rewrite that node.
Disposal must preserve the borrowed container and release all created instances and connections.
Keep acceptance assertions outside the starter until the agent finishes. Run them once against the submitted solution.
A loading smoke check does not establish acceptance.

Before dispatch, record the source commit/tree, starter-file hashes, task and assertion hashes, prompt, model/harness configuration, deadline and stopping rule.
Stop at completion or the deadline. Do not grant another attempt silently after failure.
Retain every started attempt and its original output.
Record wall time, actual reported input/output/cache tokens, tool calls, visible failures, final
correctness and exact retention. Mark missing token or model metadata as unavailable. Do not estimate it.

Report acceptance before efficiency. Charge failed work and evaluator setup/checking separately
from agent execution. One passing trial proves this one task at these inputs; it does not establish
broad ergonomics, future autonomous delivery, or engine rendering performance.
