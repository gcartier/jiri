;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Structure
;;;


(include "syntax.scm")


;;;
;;;; Structure
;;;


(define current-root-dir
  #f)

(define closed-beta-password
  #f)

(define called-from
  #f)


(define (app-dir)
  (string-append current-root-dir (normalize-directory jiri-app-dir)))

(define (install-dir)
  (string-append current-root-dir (normalize-directory jiri-install-dir)))

(define (current-dir)
  (string-append current-root-dir (normalize-directory jiri-current-dir)))

(define (world-dir)
  (string-append current-root-dir (normalize-directory jiri-world-dir)))

(define (root-exe)
  (add-extension (string-append current-root-dir jiri-application) executable-extension))

(define (app-exe)
  (add-extension (string-append (app-dir) jiri-application) executable-extension))

(define (current-exe)
  (add-extension (string-append (current-dir) "Install") executable-extension))

(define (uninstall-exe)
  (add-extension (string-append (current-dir) "Uninstall") executable-extension))

(define (install-exe)
  (add-extension (string-append (install-dir) "Install") executable-extension))

(define (launcher-exe)
  (add-extension (string-append (install-dir) "Launcher") executable-extension))


;;;
;;;; Delegate
;;;


(define (delegate-current root-dir closed-beta-password called-from)
  (setenv "root-dir" root-dir)
  (setenv "closed-beta-password" (or closed-beta-password ""))
  (setenv "called-from" called-from)
  (delegate-process (current-exe))
  (exit))


(define (delegate-install root-dir closed-beta-password called-from)
  (setenv "root-dir" root-dir)
  (setenv "closed-beta-password" (or closed-beta-password ""))
  (setenv "called-from" called-from)
  (setenv "work-percentage" (number->string work-percentage))
  (setenv "work-downloaded" (number->string work-downloaded))
  (let ((pos (get-window-position current-window)))
    (setenv "window-h" (number->string (point-h pos)))
    (setenv "window-v" (number->string (point-v pos))))
  (delegate-process (install-exe))
  ;; wait for install window to cover our own window
  (thread-sleep! .5)
  (exit))
