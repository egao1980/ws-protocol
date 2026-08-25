# ws-protocol

MIT WebSocket **client** protocol for [cl-stack](https://github.com/egao1980/cl-stack) (RFC 6455 + RFC 8441 transport preference).

Brief: [`docs/capabilities/ws-protocol.md`](https://github.com/egao1980/cl-stack/blob/main/docs/capabilities/ws-protocol.md) · Tracks `#34` / `#35`.

**0.2.2** — CLOS transport preference + `feature-or-env-enabled-p`; cookbook/demo. Wire for `:http/2` lives in HTTP backends (`http-backend-async`).

## Systems

| ASDF | Role |
|------|------|
| `ws-protocol` | Generics, conditions, transport policy, `ws` facade (promises via Blackbird) |
| `ws-backend-websocket-driver` | [`websocket-driver`](https://github.com/fukamachi/websocket-driver) — `:http/1.1` Upgrade |

```lisp
(asdf:load-system "ws-backend-websocket-driver")
(let ((backend (ws-backend-websocket-driver:make-websocket-driver-backend)))
  (ws:with-connection (conn "ws://127.0.0.1:5000/echo"
                            :backend backend :transport :http/1.1)
    (ws:on conn :message (lambda (msg) (print msg)))
    (ws:send conn "hi")))
```

Local echo demo: `ros -l scripts/demo.lisp`. Recipes: [cl-stack websocket cookbook](https://github.com/egao1980/cl-stack/blob/main/docs/cookbooks/websocket.md).

`wss://` uses cl+ssl (driver); production TLS = `cl-stack-ssl` overlay (`#35`).

## Install / test

CI: canned [`cl-repository`](https://github.com/egao1980/cl-repository) (`test-system.yml` / `setup-client` + `ci`). Deps from `ghcr.io/egao1980/cl-systems`.

```bash
# Local: client on the ASDF registry, then
(asdf:test-system "ws-protocol")

# WSS smoke (env still honored by the test system):
WS_PROTOCOL_WSS=1 WS_PROTOCOL_WSS_CHILD=1 ros -e '(asdf:test-system "ws-protocol")'

# Clean-container OCI path (linux/amd64, no libssl-dev):
# ./scripts/smoke-wss-clean-container.sh
```

## Publish

Owning-repo canned [`publish-source.yml`](https://github.com/egao1980/cl-repository/blob/main/.github/workflows/publish-source.yml):

```bash
gh workflow run publish-checkout.yml -R egao1980/ws-protocol
```

## License

MIT — see [LICENSE](LICENSE).
