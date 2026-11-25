# lib-route

`route` — transport-agnostic routing + middleware-pipeline library in
pure handl (proposal P-008 / task T-138). The generic half that
`http-route`/`http-router` and `http-middleware` build on: pattern
compilation, a segment trie for dispatch, and the `{ out, state }`
onion pipeline. No HTTP assumptions — the transport splits the path
into tokens and supplies whatever eligibility check it wants.

## Layout

| path | role |
| --- | --- |
| `src/index.hnl` | the library |
| `src/index.test.hnl` | the .hnl test suite |
| `pkg.hnl`, `ci.sh`, `scripts/hnl-gate.sh` | manifest / bupha entry / gate |

## Contract

- `compile(entries)` folds route entries (records with `"path"` or
  `"pattern"`) into a segment trie once; `match`/`dispatch` walk the
  trie over a token list and return **all** reachable candidates,
  sorted best-first (transports use the full list for 404/405-style
  decisions).
- v3 pattern compiler: literals, `:params`, `*splats`,
  `(/optional)` groups, `:suffix.vars`, `?k=v` constraints.
- `{out,state}` onion pipeline: `pipeline`/`chain`/`end`/
  `state_get`/`state_put`. Sibling adapters: `lib-msg-router`.
- Pure `.hnl`; no Rust crate.

## Verification

```bash
./ci.sh   # bupha entry → scripts/hnl-gate.sh
```

## License

MIT.

<!-- myco:agent-awareness -->

## Agent awareness

- Session start / any work discussion: run `myco status --prompt`
  before proposing next steps — know the board first.
- User describes new work → offer to capture it (`myco todo add`,
  `issue new`, `proposal new`). Don't wait to be asked.
- Picking up a task: `myco resume <ID>` is the briefing.
- Wrapping up: `myco handoff <ID>` anything resumable; keep statuses
  honest (claimed → in-progress → blocked/done).

<!-- /myco:agent-awareness -->
