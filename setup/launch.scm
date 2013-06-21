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
  (let ((root-dir (executable-directory)))
    (let ((current-exe (string-append root-dir "install/current/Install.exe")))
      (cond ((file-exists? current-exe)
             (open-process current-exe)
             (exit))
            (else
             (system-message "Incorrect installation")
             (exit 1))))))


;;;
;;;; Main
;;;


(launch)
