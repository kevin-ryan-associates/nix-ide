---
name: sdd-discovery-authoring
description: >-
  How to write up discovery conclusions into a discovery.md — the required
  sections, how to keep facts, assumptions, and constraints distinct from one
  another and current-state findings distinct from desired outcomes, how to
  phrase solution-agnostic success criteria, and the definition of done that
  gates handoff to Specify. Load when writing or auditing a discovery.md.
---
# Discovery Authoring

This skill governs the `discovery.md` artefact — the output of the Discover
stage and the input to Specify. It covers what the document contains, how to
write each part, and the definition of done that gates the handoff. It does not
govern how to conduct discovery; that is the Discover agent's job.

A discovery document is distilled conclusions, never a transcript. If a sentence
only makes sense to someone who sat in the conversation, it does not belong.
Specify must be able to work from this document alone, with nothing left in
anyone's head.

This document is one spec's discovery, and it sits beneath the product vision.
Before writing it, the Discover agent has read `sdd/product-vision.md` and named
the spec; the finished document lands at `sdd/<spec-name>/discovery.md`, per the
directory law in the `sdd` skill. Inherit the product-level frame the vision sets
— who the product is for, its value, its definition of done — and situate this
spec within it. Do not re-derive or restate product-level context: your job is the
problem for this one spec, in the frame the vision already established.

## Use the template

The skeleton for this document is the template at
`~/.config/opencode/skills/sdd-discovery-authoring/discovery-template.md`. Read it,
fill every section, and delete the guidance comments as you go. Do not restructure
it, rename sections, or reorder them — the fixed shape is what lets Specify and
Evaluate rely on the document. The sections below explain how to fill each part.

When the document is complete and passes the Definition of Done below, write it to
`sdd/<spec-name>/discovery.md` — the spec directory named during discovery,
creating it if it does not exist. This is the only place the discovery document
belongs.

## Structure

The template's sections, in order. Omit "Current state" only when no relevant
system yet exists (pure greenfield); never omit the rest.

1. **Problem** — the real problem, in one or two sentences of plain language. If
   it differs from what was first asked for, say so in a line: what was
   presented, and what turned out to be underneath it.
2. **Why it matters** — the stakes for *this spec*, connected to the value the
   product vision already establishes rather than re-deriving it. What it costs to
   leave this problem unsolved, and why now. Product-level justification lives in
   `product-vision.md`; here, keep it to what bears on acting on this spec.
3. **Epistemic ledger** — everything discovery established, each item tagged.
   Three groups, kept separate:
   - **Facts** — verifiable and verified. Things known, not believed.
   - **Assumptions** — believed but unproven. Mark the **load-bearing** one —
     the belief the whole problem framing rests on — and record whether it was
     pressure-tested and how it held up.
   - **Constraints** — hard boundaries any solution must live within
     (regulatory, contractual, technical, organisational). Only genuine
     constraints, not preferences wearing a constraint's clothes.
4. **Current state** *(when a system exists)* — what the existing code or system
   actually does, as observed. Findings only: what *is*. This section never
   contains what *should* change — that separation is the whole point of keeping
   it apart. If you catch a "should" here, it belongs in Success criteria or
   Open questions instead.
5. **Success criteria** — how anyone will know the problem is solved, stated as
   observable outcomes and completely solution-agnostic. No mechanism, no
   design: "a support agent can find a customer's last order in under ten
   seconds," not "add a search index." These become the seed of Specify's
   requirements, so they must be about results, never means.
6. **Scope & boundaries** — what this problem does and does not include. State
   the out-of-scope explicitly; it stops the plan stage over-reaching. Flag any
   **one-way doors** — decisions expensive or impossible to reverse — so
   downstream stages spend their care where it counts.
7. **Open questions** — everything still unresolved that Specify will need, each
   written as a `[NEEDS CLARIFICATION: <question>]` marker (the shared marker
   defined in the `sdd` skill). Unanswered is honest; silently resolved by
   assumption is not.

## Writing the epistemic ledger

The ledger is the signature of this pipeline. Getting it right is most of the
job.

- Tag every claim. A statement with no tag is a statement no one has decided the
  status of — which is exactly the failure this section exists to prevent.
- Facts must be verifiable, ideally verified during discovery. "The API returns
  40k rows" is a fact if you saw it; an assumption if someone told you.
- Watch for assumptions dressed as facts — the most common defect. If it was
  asserted rather than observed, it is an assumption until proven.
- Name exactly one load-bearing assumption. If two feel load-bearing, the
  framing is probably still too broad; keep digging until one dominates.

## Keeping *is* separate from *should*

Current-state findings and desired outcomes live in different sections for a
reason: Specify must be able to tell an observation about today's system from a
goal for tomorrow's. Mixing them lets a description of how things happen to work
today masquerade as a requirement. Current state answers "what is true now?"
Success criteria answer "what must be true when we're done?" Never let one leak
into the other.

## Definition of Done

Before the document is handed to Specify, verify:

- [ ] The stated problem is the root problem, not the presenting symptom — or
      the gap between the two is spelled out.
- [ ] Every claim in the ledger is tagged fact, assumption, or constraint.
- [ ] Exactly one load-bearing assumption is named, with its test status.
- [ ] Current-state findings, if present, describe only what *is* — no desired
      outcomes have leaked in.
- [ ] Every success criterion is observable and names no mechanism.
- [ ] Scope is explicit on both sides: what's in and what's out.
- [ ] No solution, architecture, tech choice, or plan appears anywhere in the
      document.
- [ ] The document situates the spec within the product vision and does not
      restate or contradict product-level context.
- [ ] Open questions are captured as `[NEEDS CLARIFICATION]` markers, not
      silently resolved.

The document is done when every box holds. Any that fail send it back into
discovery, not forward into Specify.

