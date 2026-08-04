(in-package #:ws-protocol/tests)

(deftest normalize-ws-transport-keywords
  (ok (eq :auto (normalize-ws-transport nil)))
  (ok (eq :http/1.1 (normalize-ws-transport :http/1.1)))
  (ok (eq :http/2 (normalize-ws-transport "h2")))
  (ok (eq :http/1.1 (normalize-ws-transport "upgrade")))
  (ok (eq :http/2 (normalize-ws-transport "rfc8441"))))

(deftest backend-ws-transports-default-empty
  (let ((b (make-instance 'ws-backend :name "bare")))
    (ok (null (backend-ws-transports b)))
    (ok (not (backend-supports-ws-transport-p b :auto)))
    (ok (not (backend-supports-ws-transport-p b :http/1.1)))))

(deftest websocket-driver-transport-http11
  (let ((b (make-websocket-driver-backend)))
    (ok (equal '(:http/1.1) (backend-ws-transports b)))
    (ok (backend-supports-ws-transport-p b :auto))
    (ok (backend-supports-ws-transport-p b :http/1.1))
    (ok (not (backend-supports-ws-transport-p b :http/2)))
    (ok (eq :http/1.1 (resolve-ws-transport b (make-ws-client b))))
    (ok (signals (resolve-ws-transport b (make-ws-client b) :transport :http/2)
                 'ws-transport-not-available))))

(deftest make-http2-websocket-connect-headers-rfc8441
  (let* ((uri (quri:uri "wss://example.com:8443/chat?x=1"))
         (hdrs (make-http2-websocket-connect-headers
                uri '(("X-Token" . "a") ("Connection" . "upgrade"))
                :protocols '("chat" "superchat"))))
    (ok (equal "CONNECT" (cdr (assoc :method hdrs))))
    (ok (equal "websocket" (cdr (assoc :protocol hdrs))))
    (ok (equal "https" (cdr (assoc :scheme hdrs))))
    (ok (equal "/chat?x=1" (cdr (assoc :path hdrs))))
    (ok (equal "example.com:8443" (cdr (assoc :authority hdrs))))
    (ok (equal "chat, superchat"
               (cdr (assoc "sec-websocket-protocol" hdrs :test #'string=))))
    (ok (equal "a" (cdr (assoc "x-token" hdrs :test #'string=))))
    (ok (null (assoc "connection" hdrs :test #'string-equal)))))

(deftest connect-rejects-unsupported-transport
  (let ((*ws-backend* (make-websocket-driver-backend)))
    (ok (signals (ws:connect "ws://example/echo" :transport :http/2)
                 'ws-transport-not-available))))

(deftest feature-or-env-enabled-p-basic
  (ok (feature-or-env-enabled-p :common-lisp))
  (ok (not (feature-or-env-enabled-p :definitely-not-a-feature-xyzzy)))
  (let ((name "WS_PROTOCOL_FEATURE_OR_ENV_TEST"))
    (setf (uiop:getenv name) "1")
    (ok (feature-or-env-enabled-p nil name))
    (setf (uiop:getenv name) "0")
    (ok (not (feature-or-env-enabled-p nil name)))
    (setf (uiop:getenv name) "")))
