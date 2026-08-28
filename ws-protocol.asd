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

(defsystem "ws-protocol/tests"
  :depends-on ("ws-protocol" "rove")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "protocol-test")
               (:file "transport-test"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "tests failed for ~A" (component-name c)))))
