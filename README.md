# ws-protocol

MIT WebSocket **client** protocol for [cl-stack](https://github.com/egao1980/cl-stack) (RFC 6455).

Brief: [`docs/capabilities/ws-protocol.md`](https://github.com/egao1980/cl-stack/blob/main/docs/capabilities/ws-protocol.md) · Tracks `#34` / `#35`.

## Systems

| ASDF | Role |
|------|------|
| `ws-protocol` | Generics, conditions, `ws` facade (promises via Blackbird) |
| `ws-backend-websocket-driver` | [`websocket-driver`](https://github.com/fukamachi/websocket-driver) backend |

```lisp
(asdf:load-system "ws-backend-websocket-driver")
(let ((*ws-backend* (ws-backend-websocket-driver:make-websocket-driver-backend)))
  (ws:with-connection (conn "ws://127.0.0.1:5000/echo")
    (ws:on conn :message (lambda (msg) (print msg)))
    (ws:send conn "hi")))
```

`wss://` uses cl+ssl (driver); production TLS = `cl-stack-ssl` overlay (`#35`).

## Test

```bash
qlot install
qlot exec ros -e '(asdf:test-system "ws-protocol")'

# WSS smoke (local self-signed Clack echo; needs OpenSSL for cl+ssl)
WS_PROTOCOL_WSS=1 qlot exec ros -e '(asdf:test-system "ws-protocol")'

# Clean-container OCI path (linux/amd64, no libssl-dev):
# ./scripts/smoke-wss-clean-container.sh
```

## License

MIT — see [LICENSE](LICENSE).
