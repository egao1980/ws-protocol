(defsystem "ws-protocol"
  :version "0.1.0"
  :description "CLOS WebSocket client protocol for cl-stack (generics + facade)"
  :author "egao1980"
  :license "MIT"
  :depends-on ("blackbird" "cl-base64" "bordeaux-threads")
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "conditions")
               (:file "types")
               (:file "auth")
               (:file "protocol")
               (:file "facade"))
  :in-order-to ((test-op (test-op "ws-protocol/tests"))))

(defsystem "ws-backend-websocket-driver"
  :version "0.1.0"
  :description "websocket-driver backend for ws-protocol"
  :author "egao1980"
  :license "MIT"
  :depends-on ("ws-protocol" "websocket-driver-client" "event-emitter")
  :serial t
  :pathname "backend"
  :components ((:file "package")
               (:file "websocket-driver"))
  :in-order-to ((test-op (test-op "ws-protocol/tests"))))

(defsystem "ws-protocol/tests"
  :depends-on ("ws-protocol" "ws-backend-websocket-driver" "rove"
               "websocket-driver" "clack" "hunchentoot"
               "bordeaux-threads")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "echo-fixture")
               (:file "protocol-test")
               (:file "backend-test"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "tests failed for ~A" (component-name c)))))
