(in-package #:ws-protocol/tests)

;;; Local cleartext echo via websocket-driver-server + Clack/Hunchentoot.

(defvar *echo-handler* nil)
(defvar *echo-port* nil)

(defun %echo-app (env)
  (let ((path (or (getf env :path-info)
                  (getf env :request-uri)
                  "")))
    (if (or (string= path "/echo")
            (and (stringp path) (search "/echo" path)))
        (let ((ws (websocket-driver:make-server env)))
          (websocket-driver:on :message ws
                               (lambda (message)
                                 (websocket-driver:send ws message)))
          (lambda (responder)
            (declare (ignore responder))
            (websocket-driver:start-connection ws)))
        '(404 (:content-type "text/plain") ("nope")))))

(defun start-echo-server (&key (host "127.0.0.1"))
  (when *echo-handler*
    (stop-echo-server))
  (loop for attempt from 1 to 8
        for port = (+ 18000 (random 4000))
        do (handler-case
               (let ((handler (clack:clackup #'%echo-app
                                             :server :hunchentoot
                                             :address host
                                             :port port
                                             :use-thread t
                                             :debug nil
                                             :silent t)))
                 (setf *echo-handler* handler
                       *echo-port* port)
                 (sleep 0.2)
                 (return port))
             (error (e)
               (when (= attempt 8)
                 (error "echo server failed to bind: ~A" e))))))

(defun stop-echo-server ()
  (when *echo-handler*
    (ignore-errors (clack:stop *echo-handler*))
    (setf *echo-handler* nil
          *echo-port* nil)))

(defun echo-url (&optional (path "/echo"))
  (format nil "ws://127.0.0.1:~A~A" *echo-port* path))

(defmacro with-echo-server (() &body body)
  `(progn
     (start-echo-server)
     (unwind-protect (progn ,@body)
       (stop-echo-server))))
