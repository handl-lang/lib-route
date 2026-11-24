# lib-route

`route` — transport-agnostic routing + middleware-pipeline library in
pure handl (proposal P-008 / task T-138). The generic half that
`http-route`/`http-router` and `http-middleware` build on: pattern
compilation, a segment trie for dispatch, and the `{ out, state }`
onion pipeline. No HTTP assumptions — the transport splits the path
into tokens and supplies whatever eligibility check it wants.

## Dispatch

`compile(entries)` folds a list of route entries — records with a
`"path"` or `"pattern"` string — into a segment trie once. `match` /
`dispatch` walk the trie over a token list (HTTP uses
`str.split(path, "/")`; other transports supply their own) and return
**all** reachable candidates, sorted best-first — transports use the
full list for 404/405-style decisions.

```handl
from "route" import * as rt

trie := rt.compile([
  { path: "/users/:id", handler: user_h },
  { path: "/files/*rest", handler: file_h },
  { path: "/status" }
])

r := rt.dispatch(trie, str.split(req.path, "/"),
  (cand) ~> method_ok(cand.entry, req.method))
-- r.hit   : best candidate passing accept, or null
-- r.cands : every path match, best-first
-- cand    := { i, entry, params, score }
```

Pattern grammar (v1/v2/v3 unified — the trie handles every pattern;
`compile_pat.use` only reports whether v3 productions were present, for
consumers like href generation):

- literal segments match exactly; `:name` binds one segment;
- `*`/` *name` as the last item matches any remaining segments —
  `*name` binds the `"/"`-joined remainder, bare `*` binds nothing;
- `(/seg)` optional groups (nestable to depth 4, ≤ 8 per pattern)
  expand present-branch-before-absent-branch;
- suffix/prefix vars inside a segment: `:file.:ext`, `v:version`;
- `?k=v&flag` search constraints compile into `constraints: [{k, v}]`
  and are merged onto each normalized entry's `constraints` — dispatch
  ignores them (they are eligibility data for the transport);
- malformed patterns raise at compile time; entries with a
  missing/non-string pattern or a `bad` compile are skipped.

Ranking is the original pattern score, lexicographic: static segment
(2) > `:param`/mixed (1 / 1.5) > optional group present (0.5) > splat
(0); a strict score-prefix wins; ties keep entry order. Candidates are
deduped by entry index, keeping the first-found params.

`match_path(pattern, path)` is the single-pattern convenience
(`params | null`); `compile_pat(pattern)` exposes the compiled record
`{ path, items, bad, use, constraints, score }`.

> `match` is a reserved keyword in the dialect, so the matcher export
> is named **`match_trie`**.

## Middleware pipeline

`pipeline(steps)` folds `[mw..., terminal]` right-to-left into
`(ctx) ~> { out, state }`; `chain(steps)` seeds
`ctx = { req, state: {} }` and returns the final `out`, so
`serve(chain([...]))` works directly. `end(h)` adapts a
`(req) ~> out` handler into a `(ctx) ~> out` terminal.

```text
ctx      := { req: Request, state: State, ... }
next     := (ctx) ~> { out, state }        -- the rest of the chain
mw       := (ctx, next) ~> { out, state }
terminal := (ctx) ~> out | { out, state }  -- LAST step
```

State merges **right-wins**; a step returning a bare value is
normalized to `{ out: value, state: <incoming ctx.state> }`.
Helpers: `state_get(ctx, k)`, `state_put(ctx, k, v)` (returns a new
ctx).

## Layout

```text
src/index.hnl        compiler + trie + pipeline (pure handl arrow dialect)
src/index.test.hnl   coverage: grammar, trie dispatch, ranking, pipeline
pkg.hnl              package manifest — modules, license
ci.sh                bupha entry → scripts/hnl-gate.sh
scripts/hnl-gate.sh  typecheck + lint + test over .hnl sources
workflows/gate.yaml  generated gate include (handl-gates@0.3.2)
```

## Gate

The sources use the arrow dialect (`~>`), which the canonical
typecheck/lint tools skip — the gate reports them as dialect-skipped.
The real check is `hnl test` over `src/index.test.hnl`:

```bash
HNL=../host-cli/target/debug/hnl scripts/hnl-gate.sh
# or directly:
~/.local/bin/hnl test src/index.test.hnl
```

## License

MIT.
