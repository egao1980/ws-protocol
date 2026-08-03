;;;; Phase 2: overlay OpenSSL on loader path, then test.
;;;; Expects ci-install.lisp + OPENSSL_NATIVE / LD_LIBRARY_PATH.
;;;; Set WS_PROTOCOL_WSS=1 (+ CHILD=1) for the wss-openssl job.

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&UNHANDLED: ~A~%" c)
        #+sbcl (sb-ext:exit :code 1 :abort t)
        #-sbcl (uiop:quit 1)))

(setf asdf:*compile-file-failure-behaviour* :warn)

(defun call-with-ci-muffles (fn)
  #+sbcl
  (handler-bind ((sb-ext:defconstant-uneql
                  (lambda (c)
                    (declare (ignore c))
                    (let ((r (find-restart 'continue)))
                      (when r (invoke-restart r))))))
    (funcall fn))
  #-sbcl
  (funcall fn))

(call-with-ci-muffles (lambda () (asdf:load-system "cl-repository-client")))

(cl-repository-client/asdf-integration:configure-asdf-source-registry)
(cl-repository-client/asdf-integration:load-system-init-files)

(call-with-ci-muffles
 (lambda ()
   (asdf:load-system "cl+ssl")
   (asdf:load-system "cl-stack-ssl")
   (let ((sym (find-symbol "ENSURE-SSL" "CL-STACK-SSL")))
     (format t "~&; cl-stack-ssl => ~S~%"
             (when sym (multiple-value-list (funcall sym)))))
   (asdf:test-system "ws-protocol")))

(format t "~&; ci: test phase done~%")
#+sbcl (sb-ext:exit :code 0 :abort t)
#-sbcl (uiop:quit 0)
