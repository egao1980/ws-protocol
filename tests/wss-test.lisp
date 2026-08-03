(in-package #:ws-protocol/tests)

;;; WSS smoke (#35). Gated by WS_PROTOCOL_WSS=1.
;;; Child process abort-exits after assertions — cl+ssl teardown SIGSEGVs
;;; if we close SSL streams / destroy Clack SSL threads in-process.

(defun %wss-enabled-p ()
  (let ((v (uiop:getenv "WS_PROTOCOL_WSS")))
    (and v (not (member v '("0" "false" "no" "") :test #'string-equal)))))

(defun %wss-child-p ()
  (let ((v (uiop:getenv "WS_PROTOCOL_WSS_CHILD")))
    (and v (not (member v '("0" "false" "no" "") :test #'string-equal)))))

(defun %run-wss-in-child ()
  "Spawn scripts/run-wss-smoke.lisp via ros (not nested qlot); return T on 0."
  (let* ((script (namestring
                  (truename
                   (asdf:system-relative-pathname
                    "ws-protocol" "scripts/run-wss-smoke.lisp"))))
         (root (namestring
                (truename (asdf:system-relative-pathname "ws-protocol" ""))))
         (cmd (format nil "cd ~A && WS_PROTOCOL_WSS=1 WS_PROTOCOL_WSS_CHILD=1 ros -S . -l ~A"
                      (uiop:escape-sh-token root)
                      (uiop:escape-sh-token script)))
         (code (nth-value
                2
                (uiop:run-program
                 cmd
                 :output *standard-output*
                 :error-output *error-output*
                 :ignore-error-status t
                 :shell t))))
    (zerop code)))

(defun %wss-abort (code)
  #+sbcl (sb-ext:exit :code code :abort t)
  #-sbcl (uiop:quit code))

(deftest wss-echo-smoke
  "Local wss:// echo with self-signed cert (#35)."
  (if (not (%wss-enabled-p))
      (skip "set WS_PROTOCOL_WSS=1 to run WSS smoke")
      (if (%wss-child-p)
          (let ((ca (test-cert-path "server.crt"))
                (*ws-backend* (make-websocket-driver-backend)))
            (ok (probe-file ca))
            (start-echo-server :ssl t)
            (let ((got nil))
              (let ((conn (ws:connect (echo-url :path "/echo" :host "localhost")
                                      :verify t
                                      :ca-path (namestring (truename ca)))))
                (ws:on conn :message (lambda (msg) (setf got msg)))
                (ws:send conn "wss-ping")
                (ok (%wait (lambda () (equal got "wss-ping")) :timeout 5.0))
                (ok (equal "wss-ping" got)))
              (setf got nil)
              (let ((conn (ws:connect (echo-url) :verify nil)))
                (ws:on conn :message (lambda (msg) (setf got msg)))
                (ws:send conn "insecure-ok")
                (ok (%wait (lambda () (equal got "insecure-ok")) :timeout 5.0))
                (ok (equal "insecure-ok" got))))
            (format t "~&WSS-SMOKE assertions ok~%")
            ;; Skip SSL close/stop — abort reaps the process.
            (%wss-abort 0))
          (ok (%run-wss-in-child) "WSS child smoke exited 0"))))
