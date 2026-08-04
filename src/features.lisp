(in-package #:ws-protocol)

;;; Compile-time *features* ∪ runtime env gates (live/smoke tests).

(defun feature-or-env-enabled-p (feature &optional env-name)
  "True if FEATURE is on *FEATURES*, or ENV-NAME is a truthy environment value.

   ENV truthy: non-empty and not in {\"0\" \"false\" \"no\" \"off\"} (case-insensitive).
   FEATURE may be NIL to check env only. ENV-NAME may be NIL to check feature only."
  (or (and feature (find feature *features* :test #'string-equal))
      (and env-name
           (let ((v (uiop:getenv env-name)))
             (and v
                  (plusp (length (string-trim '(#\Space #\Tab) v)))
                  (not (member (string-downcase (string-trim '(#\Space #\Tab) v))
                               '("0" "false" "no" "off")
                               :test #'string=)))))))
