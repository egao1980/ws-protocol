(defpackage #:ws-protocol
  (:use #:cl)
  (:export #:ws-error
           #:ws-protocol-error
           #:ws-handshake-error
           #:ws-connection-error
           #:ws-timeout-error
           #:unsupported-operation
           #:unsupported-operation-operation
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
           ;; protocol
           #:connect
           #:connect-async
           #:send-text
           #:send-binary
           #:ping
           #:close-connection
           #:on-event
           #:ready-state)
  (:documentation "WebSocket client protocol (RFC 6455)."))

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
