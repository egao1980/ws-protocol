(defpackage #:ws-protocol
  (:use #:cl)
  (:export #:ws-error
           #:ws-protocol-error
           #:ws-handshake-error
           #:ws-connection-error
           #:ws-timeout-error
           #:unsupported-operation
           #:unsupported-operation-operation
           #:ws-transport-not-available
           #:ws-transport-not-available-requested
           #:ws-transport-not-available-negotiated
           #:ws-error-message
           ;; types
           #:ws-backend
           #:ws-backend-p
           #:backend-name
           #:ws-client
           #:ws-client-p
           #:ws-client-backend
           #:ws-client-headers
           #:ws-client-protocols
           #:ws-client-transport
           #:ws-client-auth
           #:ws-client-proxy
           #:ws-client-verify
           #:ws-client-ca-path
           #:make-ws-client
           #:ws-connection
           #:ws-connection-p
           #:connection-url
           #:connection-ready-state
           #:%connection-ready-state
           #:ws-message
           #:ws-message-p
           #:message-type
           #:message-data
           #:make-ws-message
           #:*ws-backend*
           #:*ws-client*
           #:with-ws-backend
           #:with-ws-client
           ;; auth
           #:authorization-header-value
           #:inject-auth-headers
           ;; transport (CLOS + RFC 8441)
           #:*valid-ws-transports*
           #:normalize-ws-transport
           #:ws-transport-preference-p
           #:effective-ws-transport
           #:resolve-ws-transport
           #:backend-ws-transports
           #:backend-supports-ws-transport-p
           #:make-http2-websocket-connect-headers
           #:http2-websocket-path
           #:http2-websocket-authority
           #:feature-or-env-enabled-p
           ;; protocol
           #:connect
           #:connect-async
           #:send-text
           #:send-binary
           #:ping
           #:close-connection
           #:on-event
           #:ready-state)
  (:documentation
   "WebSocket client protocol (RFC 6455 + RFC 8441 transport preference)."))

(defpackage #:ws
  (:use #:cl #:ws-protocol)
  ;; Facade helpers share names with protocol generics — keep separate symbols.
  (:shadow #:connect #:connect-async #:ping #:close #:send)
  (:export #:connect
           #:connect-async
           #:send
           #:ping
           #:close
           #:on
           #:with-connection
           #:*ws-backend*
           #:*ws-client*
           #:ws-message
           #:message-type
           #:message-data
           #:connection-ready-state
           #:ready-state))
