(in-package #:ws-protocol)

(defclass ws-backend ()
  ((name :initarg :name :reader backend-name :initform "unknown")))

(defun ws-backend-p (x) (typep x 'ws-backend))

(defclass ws-client ()
  ((backend :initarg :backend :reader ws-client-backend)
   (headers :initarg :headers :accessor ws-client-headers :initform nil
            :documentation "Alist of extra handshake headers.")
   (protocols :initarg :protocols :accessor ws-client-protocols :initform nil
              :documentation "Sec-WebSocket-Protocol list (strings).")
   (transport :initarg :transport :accessor ws-client-transport :initform :auto
              :documentation
              "WS transport preference: :auto | :http/1.1 (RFC 6455 Upgrade) |
               :http/2 (RFC 8441 Extended CONNECT).")
   (auth :initarg :auth :accessor ws-client-auth :initform nil
         :documentation "(:basic u p) | (:bearer tok) | Authorization string.")
   (proxy :initarg :proxy :accessor ws-client-proxy :initform nil)
   (verify :initarg :verify :accessor ws-client-verify :initform t
           :documentation "TLS verify for wss:// (passed to backend).")
   (ca-path :initarg :ca-path :accessor ws-client-ca-path :initform nil
            :documentation "Optional CA file/dir for wss:// verify (cl+ssl).")))

(defun ws-client-p (x) (typep x 'ws-client))

(defun make-ws-client (backend &rest keys &key &allow-other-keys)
  (apply #'make-instance 'ws-client :backend backend keys))

(defclass ws-connection ()
  ((url :initarg :url :reader connection-url)
   (ready-state :initarg :ready-state :accessor %connection-ready-state
                :initform :connecting)))

(defun ws-connection-p (x) (typep x 'ws-connection))

(defgeneric ready-state (connection)
  (:documentation "Keyword: :connecting :open :closing :closed.")
  (:method ((connection ws-connection))
    (%connection-ready-state connection)))

(defclass ws-message ()
  ((type :initarg :type :reader message-type :initform :text
         :documentation ":text or :binary")
   (data :initarg :data :reader message-data)))

(defun ws-message-p (x) (typep x 'ws-message))

(defun make-ws-message (data &key (type :text))
  (make-instance 'ws-message :data data :type type))

(defvar *ws-backend* nil
  "Current WS-BACKEND for facade one-shots.")

(defvar *ws-client* nil
  "Optional default WS-CLIENT for facade one-shots.")

(defmacro with-ws-backend ((backend) &body body)
  `(let ((*ws-backend* ,backend))
     ,@body))

(defmacro with-ws-client ((client) &body body)
  `(let ((*ws-client* ,client))
     ,@body))
