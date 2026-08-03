(in-package #:ws-protocol)

;;; Protocol generics. Backends specialize CONNECT / SEND-* / …

(defgeneric connect (backend client url &key)
  (:documentation "Blocking connect → WS-CONNECTION (open after handshake).")
  (:method ((backend ws-backend) client url &key)
    (declare (ignore client url))
    (error 'unsupported-operation :operation 'connect
           :message (format nil "backend ~A does not implement CONNECT"
                            (backend-name backend)))))

(defgeneric connect-async (backend client url &key callback error-callback)
  (:documentation
   "Start CONNECT off the calling thread.
    CALLBACK receives WS-CONNECTION; ERROR-CALLBACK a condition.
    Default: BT thread around CONNECT.")
  (:method ((backend ws-backend) client url &key callback error-callback)
    (bt:make-thread
     (lambda ()
       (handler-case
           (let ((conn (connect backend client url)))
             (when callback (funcall callback conn)))
         (error (e)
           (if error-callback
               (funcall error-callback e)
               (warn "ws connect-async error (no handler): ~A" e)))))
     :name "ws-protocol-connect-async")))

(defgeneric send-text (connection text &key)
  (:documentation "Send TEXT frame. TEXT is a string.")
  (:method ((connection ws-connection) text &key)
    (declare (ignore text))
    (error 'unsupported-operation :operation 'send-text)))

(defgeneric send-binary (connection octets &key)
  (:documentation "Send BINARY frame. OCTETS is a vector of (unsigned-byte 8).")
  (:method ((connection ws-connection) octets &key)
    (declare (ignore octets))
    (error 'unsupported-operation :operation 'send-binary)))

(defgeneric ping (connection &optional payload &key)
  (:documentation "Send ping; optional PAYLOAD octets.")
  (:method ((connection ws-connection) &optional payload &key)
    (declare (ignore payload))
    (error 'unsupported-operation :operation 'ping)))

(defgeneric close-connection (connection &key code reason)
  (:documentation "Close CONNECTION with optional CODE/REASON.")
  (:method ((connection ws-connection) &key code reason)
    (declare (ignore code reason))
    (error 'unsupported-operation :operation 'close-connection)))

(defgeneric on-event (connection event handler)
  (:documentation
   "Register HANDLER for EVENT (:open :message :close :error :pong).
    Handler arity matches websocket-driver / event-emitter conventions.")
  (:method ((connection ws-connection) event handler)
    (declare (ignore event handler))
    (error 'unsupported-operation :operation 'on-event)))
