;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Install
;;;


(include "syntax.scm")


;;;
;;;; Install
;;;


(define (install)
  (set! current-root-dir (getenv-default "root-dir"))
  (set! closed-beta-password (getenv-default "closed-beta-password"))
  (set! called-from (getenv-default "called-from"))
  (cond ((and current-root-dir
              (equal? called-from "root"))
         (current-from-root-work))
        ((and current-root-dir
              (equal? called-from "setup"))
         (install-from-setup-work))
        ((and current-root-dir
              (equal? called-from "current"))
         (install-from-current-work))
        (else
         (system-message "It is incorrect to launch this application")
         (exit 1))))


;;;
;;;; Current From Root
;;;


(define (current-from-root-work)
  (if (setup-password #f)
      (clone/pull-repository "application" jiri-install-remote closed-beta-password (install-dir) 1 4 #f #f #f
        (lambda (new-content?)
          (if new-content?
              (delegate-install current-root-dir closed-beta-password "current")
            (install-application/world #f))))
    (exit)))


;;;
;;;; Install From Setup
;;;


(define (install-from-setup-work)
  ;; ideally should only allow cloning
  (install-application/world #t))


;;;
;;;; Install From Current
;;;


(define (install-from-current-work)
  (install-application/world #t))


;;;
;;;; Work
;;;


(define (install-application/world copy/shortcut?)
  (clone/pull-repository "application" jiri-app-remote closed-beta-password (app-dir) 1 4 0. .2 .4
    (lambda (new-content?)
      (clone/pull-repository "world" jiri-world-remote closed-beta-password (world-dir) 3 4 .4 .85 1.
        (lambda (new-content?)
          (install-done copy/shortcut?))))))


;;;
;;;; Done
;;;


(define (install-done copy/shortcut?)
  (when copy/shortcut?
    (install-current)
    (install-root)
    (install-shortcut))
  (set-label-title status-view "Done")
  (set-view-active? play-view #t)
  (set-default-cursor IDC_ARROW)
  (set! work-in-progress? #f)
  (set! work-done? #t))


(define (install-current)
  (let ((install-dir (install-dir))
        (current-dir (current-dir)))
    (define (copy filename)
      (let ((from (string-append install-dir "/" filename))
            (to (string-append current-dir "/" filename)))
        (copy-file from to)))
    
    ;; danger
    (delete-directory current-dir)
    (create-directory current-dir)
    
    (copy "Install.exe")
    (copy "libgit2.dll")
    (copy "libeay32.dll")
    (copy "ssleay32.dll")))


(define (install-root)
  (let ((from (launch-exe))
        (to (root-exe)))
    ;; danger
    (when (file-exists? to)
      (delete-file to))
    (copy-file from to)))


(define (install-shortcut)
  (let ((path (root-exe))
        (desktop (get-special-folder CSIDL_DESKTOPDIRECTORY)))
    (let ((hr (create-shortcut path (string-append desktop "/" jiri-title ".lnk") jiri-title)))
      (when (< hr 0)
        (error "Unable to create desktop shortcut (0x" (number->string hr 16) ")")))))


;;;
;;;; Layout
;;;


(define (layout)
  (add-view root-view)
  (add-view title-view)
  (add-view close-view)
  (add-view minimize-view)
  (add-view percentage-view)
  (add-view downloaded-view)
  (add-view remaining-view)
  (add-view status-view)
  (add-view progress-view)
  (add-view play-view)
  (set-label-title status-view (downloading-title "application" 1 4))
  (set! return-press
        (lambda ()
          (when work-done?
            (play)))))


;;;
;;;; Main
;;;


(main install)
