(in-package #:ws)

;;; Thin browser-shaped helpers (API.md facade layer).

(defun %backend (backend)
  (or backend
      *ws-backend*
      (error 'ws-error :message "*ws-backend* is not bound")))

(defun connect (url &key (backend nil) (client nil clientp)
                      headers protocols auth proxy (verify t))
  "Blocking WebSocket connect → WS-CONNECTION."
  (let* ((backend (%backend backend))
         (client (if clientp
                     client
                     (or *ws-client*
                         (make-ws-client backend
                                         :headers headers
                                         :protocols protocols
                                         :auth auth
                                         :proxy proxy
                                         :verify verify)))))
    (ws-protocol:connect backend client url)))

(defun connect-async (url &key (backend nil) (client nil clientp)
                            headers protocols auth proxy (verify t))
  "Async connect → Blackbird promise of WS-CONNECTION.
   Do not call blocking CONNECT on an event-protocol loop thread."
  (let* ((backend (%backend backend))
         (client (if clientp
                     client
                     (or *ws-client*
                         (make-ws-client backend
                                         :headers headers
                                         :protocols protocols
                                         :auth auth
                                         :proxy proxy
                                         :verify verify)))))
    (blackbird:with-promise (resolve reject)
      (ws-protocol:connect-async
       backend client url
       :callback (lambda (conn) (resolve conn))
       :error-callback (lambda (e) (reject e))))))

(defun send (connection message &key (type :text))
  "Send MESSAGE (:text string or :binary octets)."
  (ecase type
    (:text (send-text connection message))
    (:binary (send-binary connection message))))

(defun ping (connection &optional payload)
  (ws-protocol:ping connection payload))

(defun close (connection &key code reason)
  (close-connection connection :code code :reason reason))

(defun on (connection event handler)
  (on-event connection event handler))

(defmacro with-connection ((var url &rest keys) &body body)
  "Bind VAR to a connected client; CLOSE on exit."
  `(let ((,var (connect ,url ,@keys)))
     (unwind-protect (progn ,@body)
       (ignore-errors (close ,var)))))
