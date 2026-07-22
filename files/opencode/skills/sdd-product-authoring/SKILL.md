---
name: sdd-product-authoring
description: >-
  How to write up product vision into a product-vision.md — the four answers it
  must establish (consumer, value, definition of done, load-bearing bets), how to
  keep it minimal and free of strategy-theatre, where it is written, and the
  definition of done that gates the whole pipeline. Load when writing or auditing
  a product-vision.md.
---
# Product Vision Authoring

This skill governs the `product-vision.md` artefact — the output of the Product
stage and the floor the entire pipeline stands on. Every stage downstream reads
it, directly or inherited, as the reason it is allowed to exist. This skill covers
what the document contains, how to write each part, where it is written, and the
definition of done that lets building begin.

A product vision is a floor, not a manifesto. Its whole job is to make four
things impossible to leave unanswered — consumer, value, done, bets — and then
stop. It is minimal by design: measured by whether those answers are solid, never
by length. A vision that could describe any product describes none.

## Use the template

The skeleton for this document is the template at
`~/.config/opencode/skills/sdd-product-authoring/product-vision-template.md`. Read
it, fill every section, and delete the guidance comments as you go. Do not
restructure it, rename sections, or reorder them — the fixed shape is what lets
every downstream stage rely on it. The sections below explain how to fill each
part.

When the document is complete and passes the Definition of Done below, write it to
`sdd/product-vision.md` — at the root of the sdd tree, not inside a spec directory,
since it belongs to the whole project. It is written once per project; if it
already exists, refine it rather than replace it.

## Structure

The template's sections, in order. The first four are the floor; none may be
omitted or answered with a slogan.

1. **Consumer** — who concretely uses or depends on this. Name them: end users of
   a certain kind, another team, a downstream service, your future self. For
   infrastructure, the deployment is the product and its operators are the
   consumers — "who consumes this" always resolves to someone nameable, never
   "everyone."
2. **Value** — what it delivers them, and why it exists at all. State the need it
   serves, not the thing it is. "Learners stop freezing on strategy decisions at a
   real table," not "a blackjack trainer."
3. **Definition of done** — what "working" means, as an observable condition
   someone could actually check. Not "it's good" — a line with an edge: a state
   the product is either in or not.
4. **Load-bearing bets** — the beliefs the whole endeavour rests on, each tagged
   as an **assumption** (they are, by definition, unproven). Mark the single most
   load-bearing one — the belief that, if false, makes the whole thing pointless —
   and record whether it was pressure-tested and how it held. The "is this a real
   product or an exercise with a convenient domain" question, when it applies,
   lives here.
5. **Scope & non-goals** — the product-level boundary: what this product is, and
   what it is deliberately *not*. This is not a list of specs or features — it is
   the outer edge Discovery must stay inside ("not a real-money gambling app,"
   "not a multiplayer platform"). Keep it to boundaries, not contents.
6. **Open questions** — genuine unknowns, as `[NEEDS CLARIFICATION: <question>]`
   markers. A vision may ship with open questions; it may not ship with unknowns
   silently resolved by guessing.

## Writing the four answers

The four answers are the craft. Getting them concrete is the whole job.

- **Name a consumer, not an audience.** "Users" is not an answer. "A player who
  already knows basic strategy exists but freezes under pressure" is. The more
  specific the consumer, the sharper every downstream decision.
- **Value is a need, not a noun.** If your value statement names the artefact
  ("a trainer," "a dashboard"), you have described the thing, not why anyone wants
  it. Push to the need underneath.
- **Done must be checkable.** If you cannot imagine an observation that settles
  whether the product is "working," the definition is too soft. Sharpen it until
  it has an edge.
- **Bets are assumptions, and you tag them so.** Hold them in the shared epistemic
  ledger like any other claim. The point of naming them is that they are the
  things most expensive to be wrong about — surface them so downstream work does
  not silently inherit a false one.

## Minimal is the gate

The bar is *answered*, not *lengthy*. A crisp vision that nails the four answers
passes; pages that dodge "who is this for" fail. The test for every sentence: does
it help answer consumer, value, done, or bets, or set a genuine boundary? If not,
it is strategy-theatre — "delight users," "world-class," "seamless" — and it does
not belong. Cut it.

## Definition of Done

This is the gate for the whole pipeline: until it holds, nothing downstream may
begin. Before writing, verify:

- [ ] The consumer is named concretely — a specific who, not "users" or
      "everyone."
- [ ] Value states the need served and why it exists, not merely what the thing
      is.
- [ ] The definition of done is observable — a condition someone could check.
- [ ] Load-bearing bets are listed and tagged as assumptions; the single most
      load-bearing one is marked, with its test status.
- [ ] Scope & non-goals draw a product-level boundary and enumerate no specs.
- [ ] No solution, architecture, tech choice, or plan appears anywhere.
- [ ] Every line serves one of the four answers, a boundary, or an open question —
      no strategy-theatre.
- [ ] Open questions are captured as markers, not resolved by guessing.

The vision is done when every box holds. Only then does the pipeline open.

