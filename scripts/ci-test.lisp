;;;; Phase 2: overlay OpenSSL on loader path, then test.
;;;; Expects ci-install.lisp + OPENSSL_NATIVE / LD_LIBRARY_PATH.

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

(let ((ok nil))
  (call-with-ci-muffles
   (lambda ()
     (asdf:load-system "cl+ssl")
     (asdf:load-system "cl-stack-ssl")
     (let ((sym (find-symbol "ENSURE-SSL" "CL-STACK-SSL")))
       (unless sym
         (error "cl-stack-ssl loaded but ENSURE-SSL missing"))
       (format t "~&; cl-stack-ssl => ~S~%"
               (multiple-value-list (funcall sym))))
     ;; Fresh SBCL: ql:quickload again so ASDF sees lack/clack/… from QL.
     (format t "~&; ci: ql:quickload WS stack~%")
     (ql:quickload '("rove" "blackbird" "event-emitter" "websocket-driver"
                     "clack" "clack-handler-hunchentoot" "hunchentoot")
                   :silent t)
     (asdf:test-system "ws-protocol")
     (setf ok t)))
  (format t "~&; ci: test phase ~A~%" (if ok "done" "FAILED"))
  #+sbcl (sb-ext:exit :code (if ok 0 1) :abort t)
  #-sbcl (uiop:quit (if ok 0 1)))
