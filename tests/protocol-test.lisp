(in-package #:ws-protocol/tests)

(deftest auth-basic-header
  (ok (string= "Basic dXNlcjpwYXNz"
               (authorization-header-value '(:basic "user" "pass")))))

(deftest auth-bearer-header
  (ok (string= "Bearer tok"
               (authorization-header-value '(:bearer "tok")))))

(defclass mock-backend (ws-backend)
  ((last-url :initform nil :accessor mock-last-url)
   (handlers :initform (make-hash-table) :accessor mock-handlers))
  (:default-initargs :name "mock"))

(defmethod backend-ws-transports ((backend mock-backend))
  (declare (ignore backend))
  '(:http/1.1))

(defclass mock-connection (ws-connection)
  ((backend :initarg :backend :reader mock-connection-backend)
   (inbox :initform nil :accessor mock-inbox)))

(defmethod ws-protocol:connect ((backend mock-backend) client url &key transport)
  (declare (ignore client transport))
  (setf (mock-last-url backend) url)
  (make-instance 'mock-connection :backend backend :url url :ready-state :open))

(defmethod ws-protocol:send-text ((connection mock-connection) text &key)
  (push text (mock-inbox connection)))

(defmethod ws-protocol:send-binary ((connection mock-connection) octets &key)
  (push octets (mock-inbox connection)))

(defmethod ws-protocol:ping ((connection mock-connection) &optional payload &key)
  (push (list :ping payload) (mock-inbox connection)))

(defmethod ws-protocol:close-connection ((connection mock-connection) &key code reason)
  (declare (ignore code reason))
  (setf (ws-protocol:%connection-ready-state connection) :closed)
  t)

(defmethod ws-protocol:on-event ((connection mock-connection) event handler)
  (setf (gethash event (mock-handlers (mock-connection-backend connection)))
        handler))

(deftest facade-connect-send-close
  (let* ((*ws-backend* (make-instance 'mock-backend))
         (conn (ws:connect "ws://example/echo")))
    (ok (eq :open (ready-state conn)))
    (ws:send conn "hi")
    (ok (equal "hi" (first (mock-inbox conn))))
    (ws:close conn)
    (ok (eq :closed (ready-state conn)))))

(deftest facade-connect-async
  (let* ((*ws-backend* (make-instance 'mock-backend))
         (done nil)
         (conn nil))
    (blackbird:attach
     (ws:connect-async "ws://example/a")
     (lambda (c)
       (setf conn c done t)))
    (loop repeat 50 until done do (sleep 0.02))
    (ok done)
    (ok (ws-connection-p conn))
    (ignore-errors (ws:close conn))))
