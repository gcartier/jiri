;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Launch
;;;


(include "syntax.scm")


;;;
;;;; Launch
;;;


(define (launch)
  (set! current-root-dir (executable-directory))
  (cond ((file-exists? (current-exe))
         (delegate-current current-root-dir closed-beta-password "root"))
        (else
         (system-message "Incorrect installation")
         (exit 1))))


;;;
;;;; Main
;;;


(launch)
