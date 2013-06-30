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
  (let ((args (command-arguments)))
    (cond ((equal? args '("-information"))
           (launch-information))
          ((equal? args '("-uninstall"))
           (launch-uninstall))
          ((equal? args '())
           (launch-current))
          (else
           (message-box (string-append "Invalid command arguments: " (->string args)))
           (exit 1)))))


;;;
;;;; Information
;;;


(define (launch-information)
  (cond ((file-exists? (app-exe))
         (delegate-process (app-exe) arguments: '("-glinformation" "true"))
         (exit))
        (else
         (message-box "Incorrect installation")
         (exit 1))))


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
