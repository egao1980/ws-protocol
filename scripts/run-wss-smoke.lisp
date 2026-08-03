;;;; Isolated WSS smoke child — sets CHILD=1 so the deftest runs in-process
;;;; and abort-exits after green assertions.
(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&WSS-SMOKE FAIL: ~A~%" c)
        #+sbcl (sb-ext:exit :code 1 :abort t)
        #-sbcl (uiop:quit 1)))

(setf (uiop:getenv "WS_PROTOCOL_WSS") "1")
(setf (uiop:getenv "WS_PROTOCOL_WSS_CHILD") "1")

(when (uiop:getenv "CL_STACK_SSL_ROOT")
  (asdf:load-system "cl+ssl")
  (ignore-errors (asdf:load-system "cl-stack-ssl")))

(asdf:load-system "ws-protocol/tests")

;; Run only the WSS deftest via rove (suite still loads all; skip others via env).
;; Cleartext tests also run; that's fine — CHILD abort happens inside wss-echo-smoke.
(unless (rove:run (asdf:find-system "ws-protocol/tests"))
  (format *error-output* "~&WSS-SMOKE: rove failed~%")
  #+sbcl (sb-ext:exit :code 1 :abort t)
  #-sbcl (uiop:quit 1))

;; If WSS was skipped somehow, fail.
(format *error-output* "~&WSS-SMOKE: did not abort from wss-echo-smoke~%")
#+sbcl (sb-ext:exit :code 1 :abort t)
#-sbcl (uiop:quit 1)
