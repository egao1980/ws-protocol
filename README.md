# ws-protocol

MIT WebSocket protocol for [cl-stack](https://github.com/egao1980/cl-stack) (RFC 6455 client + **H1 Upgrade accept**; RFC 8441 transport preference).

Brief: [`docs/capabilities/ws-protocol.md`](https://github.com/egao1980/cl-stack/blob/main/docs/capabilities/ws-protocol.md) · Tracks `#34` / `#35`.

**0.3.0** — `ws:accept` / `ws:make-server` / `start-ws-server` (H1 Upgrade). H2 Extended CONNECT server is follow-on.

## Systems

| ASDF | Role |
|------|------|
| `ws-protocol` | Generics, conditions, transport policy, `ws` facade (promises via Blackbird) |

H1 Upgrade: [`ws-backend-websocket-driver`](https://github.com/egao1980/ws-backend-websocket-driver). H2 Extended CONNECT: [`http-backend-async`](https://github.com/egao1980/http-backend-async). Windows H1: [`http-backend-winhttp`](https://github.com/egao1980/http-backend-winhttp).

```lisp
(asdf:load-system "ws-backend-websocket-driver")
(let ((backend (ws-backend-websocket-driver:make-websocket-driver-backend)))
  (ws:with-connection (conn "ws://127.0.0.1:5000/echo"
                            :backend backend :transport :http/1.1)
    (ws:on conn :message (lambda (msg) (print msg)))
    (ws:send conn "hi")))
```

Local echo demo: `ros -l scripts/demo.lisp` in the backend repo. Recipes: [cl-stack websocket cookbook](https://github.com/egao1980/cl-stack/blob/main/docs/cookbooks/websocket.md).

## Install / test

CI: canned [`cl-repository`](https://github.com/egao1980/cl-repository) (`test-system.yml` / `setup-client` + `ci`). Deps from `ghcr.io/egao1980/cl-systems`.

```bash
# Local: client on the ASDF registry, then
(asdf:test-system "ws-protocol")
```

Protocol tests use an in-tree mock backend. Driver echo / WSS smoke live in `ws-backend-websocket-driver`.

## Publish

Owning-repo canned [`publish-source.yml`](https://github.com/egao1980/cl-repository/blob/main/.github/workflows/publish-source.yml):

```bash
gh workflow run publish-checkout.yml -R egao1980/ws-protocol
```

H1 driver: `gh workflow run publish-checkout.yml -R egao1980/ws-backend-websocket-driver`

## License

MIT — see [LICENSE](LICENSE).
