;;;; Phase 1: install deps via cl-repository (GHCR). QL fallback only for
;;;; systems not yet published into egao1980/cl-systems (websocket-driver stack).
;;;; Install cl-stack-ssl LAST — do not ASDF-load it here (overlay natives need
;;;; LD_LIBRARY_PATH before the test process starts).

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&UNHANDLED: ~A~%" c)
        (uiop:quit 1)))

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

(defparameter *ci-ql-sources*
  '(("babel" :ql)
    ("trivial-features" :ql)
    ("cl-unicode" :ql))
  "QL pins for bootstrap / incomplete OCI imports.")

(cl-repo:add-registry "https://ghcr.io" :namespace "egao1980/cl-systems" :priority :prepend)

(defun ci-install (oci-name &key (version "latest"))
  (format t "~&; ci: install ~a:~a~%" oci-name version)
  (cl-repository-client/installer:install-system
   "https://ghcr.io" (format nil "egao1980/cl-systems/~a" oci-name) version)
  (cl-repository-client/asdf-integration:configure-asdf-source-registry))

(defun ci-load (name &key version)
  (format t "~&; ci: cl-repo load ~a~@[:~a~]~%" name version)
  (call-with-ci-muffles
   (lambda ()
     (if version
         (cl-repo:load-system name :version version :sources *ci-ql-sources*)
         (cl-repo:load-system name :sources *ci-ql-sources*))))
  (unless (asdf:find-system name nil)
    (error "ci-load: ~a not installed/findable" name)))

(defun ci-ql (name)
  (unless (asdf:find-system name nil)
    (format t "~&; ci: ql fallback ~a (not yet in cl-systems)~%" name)
    (ql:quickload name :silent t)))

(defun ci-patch-stack-ssl (&optional (version "3.4.1"))
  (let ((setup (probe-file
                (merge-pathnames
                 (format nil "cl-stack-ssl/~a/src/setup.lisp" version)
                 (cl-repository-client/installer:systems-root)))))
    (when setup
      (let* ((text (uiop:read-file-string setup))
             (fixed (search "(defconstant +openssl-version+" text :test #'char-equal)))
        (when fixed
          (setf text (concatenate 'string
                                  (subseq text 0 fixed)
                                  "(defparameter +openssl-version+"
                                  (subseq text (+ fixed (length "(defconstant +openssl-version+")))))
          (with-open-file (out setup :direction :output :if-exists :supersede)
            (write-string text out))
          (format t "~&; ci: patched ~a defconstant->defparameter~%" setup))))))

(call-with-ci-muffles
 (lambda ()
   (let ((cl-stack-ssl-version (or (uiop:getenv "CL_STACK_SSL_VERSION") "3.4.1")))
     (ci-install "cl-plus-ssl" :version "latest")
     (ci-install "cl-base64" :version "latest")
     ;; WS stack not yet imported into cl-stack-systems — QL until published.
     (dolist (n '("rove" "blackbird" "bordeaux-threads" "event-emitter"
                  "websocket-driver" "clack" "clack-handler-hunchentoot"
                  "hunchentoot"))
       (ci-ql n))
     (ci-install "cl-stack-ssl" :version cl-stack-ssl-version)
     (ci-patch-stack-ssl cl-stack-ssl-version))))

(format t "~&; ci: install phase done~%")
(uiop:quit 0)
