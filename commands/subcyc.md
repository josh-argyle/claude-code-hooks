---
description: Run a cycle of /subrev 5 and amend the plan until it passes
argument-hint: [optional focus]
---

You must run repeated cycles of `/subrev 5` and plan amendments until the plan is ready to implement.

## Arguments

The argument string is: "$ARGUMENTS"

If provided, pass it as the focus to each `/subrev` round (e.g. `/subrev 5 $ARGUMENTS`). If empty, let `/subrev` choose its own angles each round (and vary them between rounds per the mix-angles feedback).

## Process

1. **Run `/subrev 5`** (or `/subrev 5 <focus>` if a focus was provided) by invoking the `subrev` skill with the appropriate arguments.

2. **Read the results.** If all 5 agents return PASS and the overall verdict is PASS, stop and tell the user the plan is ready to implement.

3. **If any issues were found**, amend the plan file to address them:
   - Fix all Critical issues
   - Fix all Warning issues
   - Consider Suggestion-level issues (apply if they genuinely improve the plan, skip if they're nitpicks or YAGNI)
   - Do NOT remove requirements that came from the GitHub issue — those are non-negotiable (per feedback memory)
   - Do NOT add features, abstractions, or scope beyond what the issue requires (per feedback memory)

4. **Run the next `/subrev 5` round.** Vary the review angles between rounds to avoid blind spots (per feedback memory).

5. **Repeat from step 2** until the plan passes. Do not ask the user between rounds — keep cycling automatically (per feedback memory).

6. **When the plan passes**, tell the user it's ready and remind them they can proceed with implementation.

## Model

Unless the user explicitly specifies a different model, default to using **sonnet** for the review agents.