You are preparing a large document for parallel critique. Your job is to split it into reviewable chunks and wrap each chunk in a context envelope so the critic can focus without flagging gaps that are handled elsewhere.

## Step 1 — Read the document

Read the full document at `{path}`. Do not start chunking until you have read it entirely.

## Step 2 — Identify natural chunks

Decide how the document divides. The split strategy depends on content type:

- **Implementation plan** — one chunk per phase
- **PR / code change** — one chunk per logical module, feature area, or file group
- **Strategy or design doc** — one chunk per major section or argument
- **Writing / long-form** — one chunk per chapter or thematic block

Use the document's own structure (headings, phase markers, file lists) to guide the split. Do not invent boundaries that aren't there. If the document is genuinely flat with no internal structure, treat it as a single chunk and note that in your output — it does not need chunking.

## Step 3 — For each chunk, write a context envelope

Write one envelope file per chunk at:

```
docs/planning/discussions/{topic}/chunks/{chunk-id}-envelope.md
```

Use a short slug for `{chunk-id}` — e.g. `phase-0`, `phase-3`, `auth-module`, `chapter-2`.

Each envelope file must contain exactly three sections:

```markdown
## Chunk: {chunk name or title}

### Already in place (do not flag as missing)
{Extracted verbatim outcomes and deliverables from all preceding chunks.
 Do not infer or summarise — quote the stated outputs directly.
 If nothing precedes this chunk, write: "This is the first chunk. Nothing precedes it."}

### Coming later (not your concern)
{Extracted verbatim intentions and deliverables from all following chunks.
 Do not infer or summarise — quote the stated intentions directly.
 If nothing follows this chunk, write: "This is the last chunk. Nothing follows it."}

### Your scope — review this
{The full verbatim content of this chunk. Do not paraphrase or compress.}
```

## Step 4 — Write a manifest

Write a manifest file at:

```
docs/planning/discussions/{topic}/chunks/manifest.md
```

The manifest lists every chunk in order with its envelope path and a one-line description:

```markdown
# Chunk Manifest: {topic}

| Order | Chunk ID | Envelope path | Description |
|-------|----------|---------------|-------------|
| 1 | phase-0 | chunks/phase-0-envelope.md | Pre-conditions and tooling setup |
| 2 | phase-1 | chunks/phase-1-envelope.md | Core data model |
...
```

## Output

When done, print:

```
Chunking complete.
Chunks: {N}
Manifest: docs/planning/discussions/{topic}/chunks/manifest.md
```

Do not proceed further. The orchestrator reads the manifest and launches the critic stages.
