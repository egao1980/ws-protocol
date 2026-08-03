;;;; WSS smoke with cl-stack-ssl overlay already on LD_LIBRARY_PATH.
;;;; Expects OPENSSL_NATIVE / staged package on CL_SOURCE_REGISTRY.

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&UNHANDLED: ~A~%" c)
        #+sbcl (sb-ext:exit :code 1 :abort t)
        #-sbcl (uiop:quit 1)))

(setf asdf:*compile-file-failure-behaviour* :warn)
(setf (uiop:getenv "WS_PROTOCOL_WSS") "1")
(setf (uiop:getenv "WS_PROTOCOL_WSS_CHILD") "1")

(defun %load-ssl ()
  (asdf:load-system "cl+ssl")
  (asdf:load-system "cl-stack-ssl")
  (format t "~&; cl-stack-ssl => ~S~%"
          (multiple-value-list (cl-stack-ssl:ensure-ssl))))

#+sbcl
(handler-bind ((sb-ext:defconstant-uneql
                (lambda (c)
                  (declare (ignore c))
                  (let ((r (find-restart 'continue)))
                    (when r (invoke-restart r))))))
  (%load-ssl)
  (asdf:test-system "ws-protocol"))

#-sbcl
(progn
  (%load-ssl)
  (asdf:test-system "ws-protocol"))

(format t "~&WSS CI OK~%")
#+sbcl (sb-ext:exit :code 0 :abort t)
#-sbcl (uiop:quit 0)
