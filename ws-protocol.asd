(defsystem "ws-protocol"
  :version "0.2.2"
  :description "CLOS WebSocket client protocol for cl-stack (generics + facade)"
  :author "egao1980"
  :license "MIT"
  :depends-on ("blackbird" "cl-base64" "bordeaux-threads" "quri" "uiop")
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "conditions")
               (:file "types")
               (:file "auth")
               (:file "features")
               (:file "transport")
               (:file "protocol")
               (:file "facade"))
  :in-order-to ((test-op (test-op "ws-protocol/tests"))))

(defsystem "ws-backend-websocket-driver"
  :version "0.2.2"
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
               "websocket-driver" "clack" "clack-handler-hunchentoot"
               "hunchentoot" "bordeaux-threads")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "echo-fixture")
               (:file "protocol-test")
               (:file "transport-test")
               (:file "backend-test")
               (:file "wss-test"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "tests failed for ~A" (component-name c)))))
