(defpackage #:ws-protocol/tests
  (:use #:cl #:rove #:ws-protocol #:ws #:ws-backend-websocket-driver)
  (:shadowing-import-from #:ws #:close #:connect #:connect-async #:ping #:send))

(in-package #:ws-protocol/tests)
