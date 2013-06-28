;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Uninstaller
;;;


(include "syntax.scm")


;;;
;;;; Launch
;;;


(define (launch)
  (launch-uninstall))


(define (launch-uninstall)
  (let ((executable-dir (executable-directory)))
    (let ((uninstall (add-extension (string-append executable-dir "Uninstall") executable-extension)))
      (cond ((file-exists? uninstall)
             (delegate-uninstall uninstall))
            (else
             (message-box "Incorrect installation")
             (exit 1))))))


(define (delegate-uninstall uninstall)
  (let ((uninstall-temp (get-temporary-file (string-append jiri-title " uninstall") "exe")))
    (copy-file uninstall uninstall-temp)
    (delegate-process uninstall-temp)))


;;;
;;;; Main
;;;


(launch)
