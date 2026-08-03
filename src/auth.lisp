(in-package #:ws-protocol)

;;; Handshake Authorization — same shapes as http-protocol :auth.

(defun authorization-header-value (auth)
  "Return Authorization header value, or NIL.
   AUTH: NIL | string | (:basic user password) | (:bearer token)."
  (cond
    ((null auth) nil)
    ((stringp auth) auth)
    ((not (consp auth))
     (error 'ws-protocol-error
            :message (format nil "Invalid :auth ~S" auth)))
    (t
     (ecase (first auth)
       (:basic
        (let ((user (second auth))
              (password (third auth)))
          (unless (and user password)
            (error 'ws-protocol-error
                   :message ":auth (:basic user password) needs two args"))
          (format nil "Basic ~A"
                  (cl-base64:string-to-base64-string
                   (format nil "~A:~A" user password)))))
       (:bearer
        (let ((token (second auth)))
          (unless token
            (error 'ws-protocol-error
                   :message ":auth (:bearer token) needs a token"))
          (format nil "Bearer ~A" token)))
       (:digest
        (error 'unsupported-operation
               :operation :auth-digest
               :message "Digest auth is P2"))))))

(defun inject-auth-headers (headers &key auth)
  "Alist HEADERS with Authorization applied. Existing key wins."
  (if (assoc "authorization" headers :test #'string-equal)
      headers
      (let ((v (authorization-header-value auth)))
        (if v
            (acons "authorization" v headers)
            headers))))
