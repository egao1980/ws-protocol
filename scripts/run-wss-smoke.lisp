;;;; Isolated WSS smoke child — abort-exits after green assertions.
;;;; Expects cl-repo install already done (same CL_SOURCE_REGISTRY as CI).
(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&WSS-SMOKE FAIL: ~A~%" c)
        #+sbcl (sb-ext:exit :code 1 :abort t)
        #-sbcl (uiop:quit 1)))

(setf (uiop:getenv "WS_PROTOCOL_WSS") "1")
(setf (uiop:getenv "WS_PROTOCOL_WSS_CHILD") "1")

(asdf:load-system "cl-repository-client")
(cl-repository-client/asdf-integration:configure-asdf-source-registry)
(cl-repository-client/asdf-integration:load-system-init-files)
(ignore-errors (asdf:load-system "cl-stack-ssl"))

(asdf:load-system "ws-protocol/tests")

(unless (rove:run (asdf:find-system "ws-protocol/tests"))
  (format *error-output* "~&WSS-SMOKE: rove failed~%")
  #+sbcl (sb-ext:exit :code 1 :abort t)
  #-sbcl (uiop:quit 1))

(format *error-output* "~&WSS-SMOKE: did not abort from wss-echo-smoke~%")
#+sbcl (sb-ext:exit :code 1 :abort t)
#-sbcl (uiop:quit 1)
