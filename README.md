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

**Deps = [cl-repository](https://github.com/egao1980/cl-repository)** against `ghcr.io/egao1980/cl-systems` (same as http-backend-*). CI: `scripts/ci-install.lisp` + `scripts/ci-test.lisp`.

WS stack libs (`websocket-driver`, `clack`, …) are not OCI-published yet → temporary QL fallback in `ci-install.lisp` until `cl-stack-systems/imports/` grows them.

```bash
# CI-shaped local run (needs cl-repository checkout + GHCR read):
export CL_SOURCE_REGISTRY="$(pwd)//:/path/to/cl-repository//:"
ros -l scripts/ci-install.lisp -q
# stage cl-stack-ssl native/ onto LD_LIBRARY_PATH, then:
ros -l scripts/ci-test.lisp -q

# WSS smoke:
WS_PROTOCOL_WSS=1 WS_PROTOCOL_WSS_CHILD=1 ros -l scripts/ci-test.lisp -q

# Clean-container OCI path (linux/amd64, no libssl-dev):
# ./scripts/smoke-wss-clean-container.sh
```

## License

MIT — see [LICENSE](LICENSE).
