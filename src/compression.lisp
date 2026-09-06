(in-package #:ws-protocol)

;;; RFC 7692 permessage-deflate negotiation (header policy only).
;;; Backends perform RSV1 + inflate/deflate on the wire.

(defparameter *valid-ws-compressions*
  '(nil :deflate)
  "Compression knobs. NIL is identity (no Sec-WebSocket-Extensions).")

(defun normalize-ws-compression (value)
  "Coerce VALUE to NIL or :deflate."
  (cond
    ((null value) nil)
    ((eq value :deflate) :deflate)
    ((eq value :permessage-deflate) :deflate)
    ((stringp value)
     (let ((s (string-downcase (string-trim '(#\Space #\Tab) value))))
       (cond
         ((or (string= s "deflate")
              (string= s "permessage-deflate"))
          :deflate)
         ((or (string= s "") (string= s "none")
              (string= s "off") (string= s "identity"))
          nil)
         (t (error 'ws-protocol-error
                   :message (format nil "Unknown WS compression ~S" value))))))
    (t (error 'ws-protocol-error
              :message (format nil "Unknown WS compression ~S" value)))))

(defun ws-compression-preference-p (value)
  (ignore-errors
    (member (normalize-ws-compression value) *valid-ws-compressions* :test #'eq)))

(defgeneric backend-ws-compressions (backend)
  (:documentation
   "List of compression keywords BACKEND can negotiate (currently :deflate).
    Default: empty — backends must specialize.")
  (:method ((backend ws-backend))
    (declare (ignore backend))
    '()))

(defgeneric backend-supports-ws-compression-p (backend compression)
  (:documentation
   "True if BACKEND can satisfy COMPRESSION. NIL (identity) is always ok.")
  (:method ((backend ws-backend) compression)
    (let ((v (normalize-ws-compression compression)))
      (or (null v)
          (member v (backend-ws-compressions backend) :test #'eq)))))

(defun resolve-ws-compression (backend client)
  "Resolve CLIENT :compression against BACKEND capabilities.
   NIL → identity. :deflate → :deflate if supported, else WS-COMPRESSION-NOT-AVAILABLE."
  (let ((want (normalize-ws-compression
               (and client (ws-client-compression client)))))
    (cond
      ((null want) nil)
      ((member want (backend-ws-compressions backend) :test #'eq) want)
      (t (error 'ws-compression-not-available
                :requested want
                :negotiated nil
                :message (format nil "backend ~A does not support ~A (has ~S)"
                                 (backend-name backend) want
                                 (backend-ws-compressions backend)))))))

(defun permessage-deflate-offer ()
  "Client Sec-WebSocket-Extensions value. no_context_takeover keeps inflate
   honest without a sliding window (first-message echo still matches takeover)."
  "permessage-deflate; client_no_context_takeover; server_no_context_takeover")

(defun permessage-deflate-response ()
  "Server Sec-WebSocket-Extensions value when accepting an offer."
  "permessage-deflate; server_no_context_takeover; client_no_context_takeover")

(defun %split-extension-list (value)
  (cond
    ((null value) '())
    ((listp value)
     (mapcan #'%split-extension-list value))
    ((stringp value)
     (loop for start = 0 then (1+ pos)
           for pos = (position #\, value :start start)
           for token = (string-trim '(#\Space #\Tab) (subseq value start pos))
           when (plusp (length token))
             collect token
           while pos))
    (t (list (princ-to-string value)))))

(defun %parse-extension-token (token)
  (let* ((parts (loop for start = 0 then (1+ pos)
                      for pos = (position #\; token :start start)
                      for piece = (string-trim '(#\Space #\Tab)
                                               (subseq token start pos))
                      when (plusp (length piece))
                        collect piece
                      while pos))
         (name (first parts))
         (params (loop for p in (rest parts)
                       for eq = (position #\= p)
                       collect (if eq
                                   (cons (string-downcase
                                          (string-trim '(#\Space #\Tab)
                                                       (subseq p 0 eq)))
                                         (string-trim '(#\Space #\Tab #\")
                                                      (subseq p (1+ eq))))
                                   (cons (string-downcase p) t)))))
    (when name
      (cons (string-downcase name) params))))

(defun parse-sec-websocket-extensions (value)
  "Parse Sec-WebSocket-Extensions into ((name . params-alist) ...)."
  (loop for token in (%split-extension-list value)
        for parsed = (%parse-extension-token token)
        when parsed collect parsed))

(defun permessage-deflate-accepted-p (value)
  "True if VALUE (header string or list) includes permessage-deflate."
  (find "permessage-deflate" (parse-sec-websocket-extensions value)
        :key #'car :test #'string-equal))

(defun header-map-get-ci (headers name)
  (or (header-map-get headers name)
      (header-map-get headers (string-downcase name))
      (when (hash-table-p headers)
        (loop for k being the hash-keys of headers using (hash-value v)
              when (string-equal (string k) name)
                return v))))

(defun env-sec-websocket-extensions (env)
  "Sec-WebSocket-Extensions from a Clack ENV plist."
  (or (getf env :sec-websocket-extensions)
      (header-map-get-ci (getf env :headers) "sec-websocket-extensions")))
