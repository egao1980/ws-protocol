(defpackage #:ws-protocol/tests
  (:use #:cl #:rove #:ws-protocol #:ws)
  (:shadowing-import-from #:ws #:close #:connect #:connect-async #:ping #:send #:accept))

(in-package #:ws-protocol/tests)
