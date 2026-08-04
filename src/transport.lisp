(in-package #:ws-protocol)

;;; WebSocket transport preference & RFC 8441 Extended CONNECT policy.
;;;
;;; Layering (CLOS split — mirrors http-protocol HTTP version):
;;;   ws-protocol  — preference keywords, capability query on BACKEND,
;;;                  RFC 8441 CONNECT header field shape.
;;;   backends     — RFC 6455 HTTP/1.1 Upgrade wire, or H2 Extended CONNECT
;;;                  + RFC 6455 framing on the stream.
;;;
;;; :http/1.1  = RFC 6455 Upgrade (websocket-driver, WinHTTP WebSocket API)
;;; :http/2    = RFC 8441 Extended CONNECT (:protocol = websocket)
;;; :auto      = prefer :http/2 when backend lists it, else :http/1.1

(defparameter *valid-ws-transports*
  '(:auto :http/1.1 :http/2)
  "Preference keywords. :auto is never a wire transport.")

(defun normalize-ws-transport (value &key (default :auto))
  "Coerce VALUE to :auto | :http/1.1 | :http/2."
  (cond
    ((null value) default)
    ((member value *valid-ws-transports* :test #'eq) value)
    ((stringp value)
     (let ((s (string-downcase (string-trim '(#\Space #\Tab) value))))
       (cond
         ((or (string= s "http/1.1") (string= s "1.1")
              (string= s "upgrade") (string= s "rfc6455"))
          :http/1.1)
         ((or (string= s "http/2") (string= s "2") (string= s "h2")
              (string= s "extended-connect") (string= s "rfc8441"))
          :http/2)
         ((or (string= s "auto") (string= s ""))
          :auto)
         (t (error 'ws-protocol-error
                   :message (format nil "Unknown WS transport ~S" value))))))
    (t (error 'ws-protocol-error
              :message (format nil "Unknown WS transport ~S" value)))))

(defun ws-transport-preference-p (value)
  (ignore-errors
    (member (normalize-ws-transport value) *valid-ws-transports* :test #'eq)))

(defun effective-ws-transport (client &key transport)
  "TRANSPORT kw override, else CLIENT :transport, else :auto."
  (normalize-ws-transport
   (or transport
       (and client (ws-client-transport client))
       :auto)))

(defun resolve-ws-transport (backend client &key transport)
  "Resolve preference against BACKEND capabilities.

   :auto → first of (:http/2 :http/1.1) that BACKEND supports.
   Forced preference → same keyword if supported, else WS-TRANSPORT-NOT-AVAILABLE."
  (let* ((pref (effective-ws-transport client :transport transport))
         (avail (backend-ws-transports backend)))
    (flet ((pick (v)
             (if (member v avail :test #'eq)
                 v
                 (error 'ws-transport-not-available
                        :requested pref
                        :negotiated nil
                        :message (format nil "backend ~A does not support ~A (has ~S)"
                                         (backend-name backend) v avail)))))
      (if (eq pref :auto)
          (or (find :http/2 avail :test #'eq)
              (find :http/1.1 avail :test #'eq)
              (error 'ws-transport-not-available
                     :requested :auto
                     :negotiated nil
                     :message (format nil "backend ~A supports no WS transports"
                                      (backend-name backend))))
          (pick pref)))))

;;; --- CLOS: what can this backend speak? -----------------------------------

(defgeneric backend-ws-transports (backend)
  (:documentation
   "List of WS transport keywords BACKEND can negotiate (:http/1.1 and/or :http/2).

    Default: empty — backends must specialize.
    :auto is never listed — it is a preference, not a wire transport.")
  (:method ((backend ws-backend))
    (declare (ignore backend))
    '()))

(defgeneric backend-supports-ws-transport-p (backend transport)
  (:documentation
   "True if BACKEND can satisfy TRANSPORT preference.

    :auto → T if backend supports any transport.
    :http/1.1 / :http/2 → membership in BACKEND-WS-TRANSPORTS.")
  (:method ((backend ws-backend) transport)
    (let ((v (normalize-ws-transport transport)))
      (if (eq v :auto)
          (not (null (backend-ws-transports backend)))
          (member v (backend-ws-transports backend) :test #'eq)))))

;;; --- RFC 8441 Extended CONNECT header policy ------------------------------

(defun http2-websocket-path (uri)
  "RFC 8441 :path — absolute path + optional ?query (same shape as RFC 9113)."
  (let* ((path (or (quri:uri-path uri) "/"))
         (query (quri:uri-query uri)))
    (if query
        (format nil "~A?~A" path query)
        path)))

(defun http2-websocket-authority (host port scheme)
  "RFC 9113 §8.3.1 :authority — host[:port] omitting default ports."
  (let* ((h (string host))
         (default (if (string-equal scheme "https") 443 80)))
    (if (or (null port) (= port default))
        h
        (format nil "~A:~A" h port))))

(defun %ws-scheme-for-connect (uri scheme)
  (string-downcase
   (or scheme
       (let ((s (quri:uri-scheme uri)))
         (cond ((null s) "https")
               ((member s '("ws" "http") :test #'string-equal) "http")
               ((member s '("wss" "https") :test #'string-equal) "https")
               (t s))))))

(defun %filter-headers-for-extended-connect (headers)
  (let ((drop '("connection" "upgrade" "sec-websocket-key"
                "sec-websocket-version" "host" "http2-settings"
                "transfer-encoding" "keep-alive" "proxy-connection" "te"
                ":protocol" "protocol")))
    (loop for pair in headers
          for name = (string-downcase (string (if (consp pair) (car pair) pair)))
          for value = (if (consp pair) (cdr pair) nil)
          when (and value (not (member name drop :test #'string=)))
            collect (cons name (if (stringp value)
                                   value
                                   (princ-to-string value))))))

(defun make-http2-websocket-connect-headers (uri headers &key scheme protocols)
  "Build RFC 8441 Extended CONNECT header fields for WebSocket.

   Returns (name . value) alist with pseudo-headers first:
     :method CONNECT, :protocol websocket, :scheme, :path, :authority
   then regular fields (connection-specific names are not added here —
   backends must not inject Upgrade/Connection on H2).

   PROTOCOLS → Sec-WebSocket-Protocol (comma-joined) when non-NIL.
   HEADERS alist is lowercased; :protocol / connection-specific keys dropped."
  (let* ((uri* (if (quri:uri-p uri) uri (quri:uri uri)))
         (scheme* (%ws-scheme-for-connect uri* scheme))
         (host (or (quri:uri-host uri*)
                   (error 'ws-protocol-error
                          :message "Extended CONNECT URL missing host")))
         (port (or (quri:uri-port uri*)
                   (if (string-equal scheme* "https") 443 80)))
         (regular (%filter-headers-for-extended-connect headers)))
    (when protocols
      (setf regular
            (acons "sec-websocket-protocol"
                   (if (listp protocols)
                       (format nil "~{~A~^, ~}" protocols)
                       (string protocols))
                   (remove "sec-websocket-protocol" regular
                           :key #'car :test #'string-equal))))
    (append
     (list (cons :method "CONNECT")
           (cons :protocol "websocket")
           (cons :scheme scheme*)
           (cons :path (http2-websocket-path uri*))
           (cons :authority (http2-websocket-authority host port scheme*)))
     regular)))

