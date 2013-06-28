;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Launcher
;;;


(include "syntax.scm")


;;;
;;;; Launch
;;;


(define (launch)
  (set! current-root-dir (executable-directory))
  (launch-current))


(define (launch-current)
  (cond ((file-exists? (current-exe))
         (delegate-current current-root-dir closed-beta-password "root"))
        (else
         (message-box "Incorrect installation")
         (exit 1))))


;;;
;;;; Main
;;;


(launch)
