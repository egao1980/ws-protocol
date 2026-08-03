;;;; Phase 1: install deps via cl-repository (GHCR).
;;;; OCI overlays first (no ASDF-load). QL fallback for unpublished WS stack
;;;; AFTER cl-stack-ssl is on disk — loading cffi/cl+ssl mid-flight before
;;;; remaining HTTPS pulls is unsafe (see LESSONS_LEARNED).

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

(cl-repo:add-registry "https://ghcr.io" :namespace "egao1980/cl-systems" :priority :prepend)

(defun ci-newest-tag (oci-name)
  "Newest version tag on ghcr.io/egao1980/cl-systems/NAME (excludes 'latest')."
  (let* ((token (or (uiop:getenv "GITHUB_TOKEN") (uiop:getenv "GH_TOKEN")))
         (auth (when token
                 (cl-oci-client/auth:make-auth-config
                  :username (or (uiop:getenv "GITHUB_ACTOR") "x-access-token")
                  :password token)))
         (reg (cl-oci-client/registry:make-registry "https://ghcr.io" :auth auth))
         (repo (format nil "egao1980/cl-systems/~a" oci-name))
         (tags (cl-oci-client/content-discovery:list-tags reg repo))
         (version-tags (remove "latest" tags :test #'string=)))
    (or (cl-repository-client/version-utils:select-preferred-version version-tags)
        (first tags)
        (error "ci-newest-tag: no tags for ~a" oci-name))))

(defun ci-install (oci-name &key version)
  "Install OCI package. VERSION nil -> newest published version tag."
  (let ((version (or version (ci-newest-tag oci-name))))
    (format t "~&; ci: install ~a:~a~%" oci-name version)
    (cl-repository-client/installer:install-system
     "https://ghcr.io" (format nil "egao1980/cl-systems/~a" oci-name) version)
    (cl-repository-client/asdf-integration:configure-asdf-source-registry)
    version))

(defun ci-patch-stack-ssl (&optional version)
  (let* ((root (cl-repository-client/installer:systems-root))
         (setup
           (or (when version
                 (probe-file
                  (merge-pathnames
                   (format nil "cl-stack-ssl/~a/src/setup.lisp" version) root)))
               (first (directory
                       (merge-pathnames "cl-stack-ssl/*/src/setup.lisp" root))))))
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
   (let ((cl-stack-ssl-version (uiop:getenv "CL_STACK_SSL_VERSION")))
     ;; All OCI installs before any ql:quickload that might load cffi/cl+ssl.
     (ci-install "cl-plus-ssl" :version "latest")
     (ci-install "cl-base64")
     ;; No :latest tag for cl-stack-ssl — resolve newest version tag.
     (let ((ssl-ver (ci-install "cl-stack-ssl" :version cl-stack-ssl-version)))
       (ci-patch-stack-ssl ssl-ver)
       (when (uiop:getenv "GITHUB_ENV")
         (with-open-file (out (uiop:getenv "GITHUB_ENV")
                              :direction :output
                              :if-exists :append
                              :if-does-not-exist :create)
           (format out "CL_STACK_SSL_VERSION=~a~%" ssl-ver))))
     ;; QL only for systems not in cl-systems yet. Do not ASDF-load
     ;; cl-stack-ssl here — phase 2 loads it with overlay on loader path.
     (format t "~&; ci: ql fallback WS stack (not yet in cl-systems)~%")
     (ql:quickload '("rove" "blackbird" "event-emitter" "websocket-driver"
                     "clack" "clack-handler-hunchentoot" "hunchentoot")
                   :silent t))))

(format t "~&; ci: install phase done~%")
(uiop:quit 0)
