(in-package #:ws-protocol)

(define-condition ws-error (error)
  ((message :initarg :message :reader ws-error-message :initform nil))
  (:report (lambda (c s)
             (format s "~@[~A~]" (ws-error-message c)))))

(define-condition ws-protocol-error (ws-error) ())

(define-condition ws-handshake-error (ws-error) ())

(define-condition ws-connection-error (ws-error) ())

(define-condition ws-timeout-error (ws-error) ())

(define-condition unsupported-operation (ws-protocol-error)
  ((operation :initarg :operation :reader unsupported-operation-operation :initform nil))
  (:report (lambda (c s)
             (format s "Unsupported WebSocket operation~@[ ~S~]~@[ — ~A~]"
                     (unsupported-operation-operation c)
                     (ws-error-message c)))))
