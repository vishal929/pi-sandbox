---
name: websearch
description: Web search, page scrape, and library docs retrieval via the ketch CLI. Use when you need up-to-date information, external documentation, or the full content of a web page.
---

# Websearch (ketch)

Use the `ketch` CLI for web search, page scraping, and docs retrieval.

## Subagent Routing (if `subagent` tool is available)
- 1-2 queries: run `ketch` yourself inline (below). 3+ topics, large scrapes, or library-docs sweeps: fan out to `researcher` (read-only, `bash: ketch * allow`, cheapest model via `/subagent-model researcher ...`):
  `subagent({tasks: [{agent:"researcher", task:"ketch search '<q1>' --max-chars 4000, return Top Sources + 5-bullet Synthesis"}, {agent:"researcher", task:"ketch docs '<topic>' --library <id>, return API signatures"}]})`
- Researcher returns compressed `Query + Top Sources + Synthesis + Start Here`. You own final synthesis into the plan/answer. Pre-approve domains (`pi-add-domain`) before fan-out; forwarded proxy 403s are not auth errors — surface the domain to the user once, don't have workers retry.

## Search

```bash
ketch search "query"
ketch search "query" --scrape   # include full content of each result
```

## Scrape

```bash
ketch scrape <url>              # one URL to clean markdown
ketch scrape <url1> <url2>      # multiple URLs concurrently
```

## Library docs

```bash
ketch docs --resolve "react"                 # find the library ID first
ketch docs "hooks" --library /org/repo    # search within a known library
```

## Code search

```bash
ketch code "query" --lang ts   # real OSS snippets, optional --lang filter
```

Notes:
- Poor results? Retry once with `ketch search "query" --multi` (federated, slower).
- To save tokens: `--minimal` (url/title only) or `--max-chars 4000`.
- JS-rendered pages are handled automatically (headless browser fallback).
- Add `--json` for structured output, `-l N` to change result limit.
- Backends and browser are already configured. Do not override unless asked.