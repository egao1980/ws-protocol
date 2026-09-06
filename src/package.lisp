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
           #:ws-compression-not-available
           #:ws-compression-not-available-requested
           #:ws-compression-not-available-negotiated
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
           #:ws-client-compression
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
           #:extended-connect-request-p
           #:extended-connect-protocol
           #:feature-or-env-enabled-p
           ;; compression (RFC 7692)
           #:*valid-ws-compressions*
           #:normalize-ws-compression
           #:ws-compression-preference-p
           #:backend-ws-compressions
           #:backend-supports-ws-compression-p
           #:resolve-ws-compression
           #:permessage-deflate-offer
           #:permessage-deflate-response
           #:parse-sec-websocket-extensions
           #:permessage-deflate-accepted-p
           #:env-sec-websocket-extensions
           ;; protocol
           #:connect
           #:connect-async
           #:send-text
           #:send-binary
           #:ping
           #:close-connection
           #:on-event
           #:ready-state
           #:ws-server
           #:ws-server-host
           #:ws-server-port
           #:ws-server-path
           #:ws-server-running-p
           #:ws-server-on-connect
           #:ws-server-compression
           #:ws-server-impl
           #:accept
           #:make-ws-server
           #:start-ws-server
           #:stop-ws-server)
  (:documentation
   "WebSocket client protocol (RFC 6455 + RFC 8441 + RFC 7692 deflate)."))

(defpackage #:ws
  (:use #:cl #:ws-protocol)
  ;; Facade helpers share names with protocol generics — keep separate symbols.
  (:shadow #:connect #:connect-async #:ping #:close #:send #:accept)
  (:export #:connect
           #:connect-async
           #:send
           #:ping
           #:close
           #:on
           #:with-connection
           #:accept
           #:make-server
           #:*ws-backend*
           #:*ws-client*
           #:ws-message
           #:message-type
           #:message-data
           #:connection-ready-state
           #:ready-state))
