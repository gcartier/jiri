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
  (if (equal? (command-arguments) '("-uninstall"))
      (launch-uninstall)
    (launch-current)))


;;;
;;;; Current
;;;


(define (launch-current)
  (cond ((file-exists? (current-exe))
         (delegate-current current-root-dir closed-beta-password "root"))
        (else
         (message-box "Incorrect installation")
         (exit 1))))


;;;
;;;; Uninstall
;;;


(define (launch-uninstall)
  (let ((uninstall (uninstall-exe)))
    (cond ((file-exists? uninstall)
           (delegate-uninstall uninstall))
          (else
           (message-box "Incorrect installation")
           (exit 1)))))


(define (delegate-uninstall uninstall)
  (let ((uninstall-temp (get-temporary-file (string-append jiri-title " uninstall") "exe")))
    (copy-file uninstall uninstall-temp)
    (delegate-process uninstall-temp)))


;;;
;;;; Main
;;;


(launch)
