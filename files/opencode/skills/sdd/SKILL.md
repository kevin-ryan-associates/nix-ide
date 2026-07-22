---
name: sdd
description: >-
  The shared Spec-Driven Development process. Every SDD stage agent loads this
  first to learn the pipeline it belongs to, the laws every stage obeys, and the
  shared vocabulary — before applying its own stage-specific skill. Currently
  documents the Product and Discovery stages; later stages are added here as they
  are built.
---
# Spec-Driven Development (SDD)

SDD turns a raw idea into working software through a fixed sequence of stages,
each producing one durable document that the next stage consumes. This skill is
the shared constitution: it defines the process every stage obeys. Your own
stage skill defines your craft — how to do your specific job. Read this first,
then defer to your stage skill for the how.

## The pipeline

SDD is a staged, artefact-driven, human-gated pipeline. Each stage reads the
artefact the previous stage produced and writes the next one. The chain is being
built incrementally; today it begins at Product.

**Nothing is built without a minimal product vision** — a stated consumer, the
value delivered, and a definition of done. Infrastructure is no exception: the
deployment is the product, its operators are the consumers. Every stage
downstream inherits that vision as the reason it is allowed to exist.

- **Stage 1 — Product** — establish the floor (consumer, value, done, and the
  load-bearing bets) below which building must not start. Produces
  `product-vision.md`, once per project. Blocks Discovery.
- **Stage 2 — Discovery** — understand the problem for one spec before it is
  designed or built. Produces `discovery.md`. Consumed by Specify.

Later stages — Specify, Plan, and onward — are documented here as they
are implemented. Until a stage appears in this skill, it is not part of the
process.

## Laws every stage obeys

These hold for all stages. They are what make the pipeline safe to run by hand.

**One spec, one directory.** All artefacts for a spec live under
`sdd/<spec-name>/` at the project root, `<spec-name>` in kebab-case. Project-level
artefacts that belong to no single spec — currently `product-vision.md` — live at
the `sdd/` root. No stage writes SDD artefacts anywhere else.

**The artefact is the interface.** A stage communicates with the next only
through the document it writes to disk — never through conversation, memory, or
assumption. Whatever the next stage needs must be in the file. Write for a
reader who was not in the room.

**Distilled, not transcribed.** An artefact is conclusions, not a log of how
they were reached. If a line only makes sense to someone who sat through the
session, it does not belong.

**Stay in your lane.** Each stage does its own job and never the next stage's.
Product does not enumerate or design specs; Discovery does not specify, plan, or
design; later stages do not re-open settled work. Doing downstream work early is
the most common way the pipeline goes wrong.

**The human holds the gate.** Every stage is human-in-the-loop. No stage writes
its artefact silently or decides on its own that it is finished. It proposes —
"here is what I would write; shall I?" — and waits for a go-ahead. Until
accepted, output is a proposal, not a decision.

## Shared vocabulary

Used identically across every stage, so artefacts read the same way regardless
of who wrote them.

**Epistemic tags.** Every claim carried between stages is tagged as one of:
**fact** (verified, verifiable), **assumption** (believed but unproven), or
**constraint** (a hard boundary any solution must respect). An untagged claim is
one whose status nobody has decided — the defect the tagging exists to prevent.

**`[NEEDS CLARIFICATION: <question>]`.** The marker for a genuine unknown that
must not be resolved by guessing. Any stage may leave one; it travels in the
artefact until answered. An artefact carrying open markers is not done — it is
surfaced to the human at the gate, never hidden.

## Stage 1 — Product

Product establishes the floor below which building must not start. It runs once,
at the start of a project, before any spec is discovered.

**Mandate.** Establish the product-level frame every spec inherits: who consumes
this, the value it delivers, what "done" means, and the load-bearing bets it
rests on. Stay at the level of the product — never enumerate, discover, or design
specs, and never plan.

**Input.** A raw brief, README, or idea — and existing code where relevant. Runs
once per project.

**Output.** `sdd/product-vision.md`, at the root of the sdd tree, not inside a
spec directory, since it belongs to the whole project.

**Gate.** Blocking. Nothing downstream — no discovery, no spec, no code — begins
until `sdd/product-vision.md` exists. The bar is minimal: the four answers
present and solid, not length.

**Craft.** How to structure and write `product-vision.md` — its sections, its
template, and the definition of done — lives in the `sdd-product-authoring`
skill. This skill governs what Product *is*; that one governs how its document is
*written*.

## Stage 2 — Discovery

Discovery is where a raw idea or problem is understood well enough that building
the wrong thing becomes hard. It runs after Product, once per spec, before any
specification, design, or code exists.

**Mandate.** Find the real problem behind the presented one; establish its
context, its constraints, and the cost of getting it wrong. Stay entirely in
problem space — what and why, never how.

**Input.** `sdd/product-vision.md` — required. Discovery reads the product vision
for context and does not begin until it exists. Beyond that it starts from an
open question, a topic, or a rough brief — and, when a system already exists,
from reading that codebase as evidence of what is true today.

**Output.** `sdd/<spec-name>/discovery.md`: the distilled understanding the
Specify stage will build on. Discovery names the spec, and that name
becomes its directory.

**Boundary.** Discovery never proposes solutions, architecture, tech choices, or
plans, and never writes files silently. When the problem is understood well
enough, it proposes both the write-up and the spec's name, then waits for the
go-ahead.

**Craft.** How to structure and write `discovery.md` — its sections, its
template, and the definition of done that gates handoff — lives in the
`sdd-discovery-authoring` skill. This skill governs what Discovery *is*; that one
governs how its document is *written*.

