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
  (cond ((at-root-heuristic?)
         (root-work))
        ((and current-root-dir
              (equal? called-from "setup"))
         (from-setup-work))
        ((and current-root-dir
              (equal? called-from "current"))
         (from-current-work))
        (else
         (system-message "It is incorrect to launch this application explicitly")
         (exit 1))))


(define (at-root-heuristic?)
  (and (not current-root-dir)
       (not closed-beta-password)
       (not called-from)
       (let ((root-dir (executable-directory)))
         (file-exists? (string-append root-dir "install/dawn-install/Install.exe")))))


;;;
;;;; Root
;;;


(define (root-work)
  (set! current-root-dir (executable-directory))
  (when (setup-password #f)
    (clone/pull-repository "application" jiri-install-remote closed-beta-password (install-dir) 1 4 #f #f #f
      (lambda (new-content?)
        (if new-content?
            (delegate-install current-root-dir closed-beta-password "root")
          (install-application/world #f))))))


;;;
;;;; Current
;;;


(define (current-work)
  (set! current-root-dir (executable-directory))
  (when (setup-password #f)
    (clone/pull-repository "application" jiri-install-remote closed-beta-password (install-dir) 1 4 #f #f #f
      (lambda (new-content?)
        (if new-content?
            (delegate-install current-root-dir closed-beta-password "root")
          (install-application/world #f))))))


;;;
;;;; From Setup
;;;


(define (from-setup-work)
  ;; ideally should only allow clone
  (install-application/world #t))


;;;
;;;; From Current
;;;


(define (from-current-work)
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
    ;; for testing
    (thread-sleep! 1.)
    (install-copy)
    (install-shortcut))
  (set-label-title status-view "Done")
  (set-view-active? play-view #t)
  (set-default-cursor IDC_ARROW)
  (set! work-in-progress? #f)
  (set! work-done? #t))


(define (install-copy)
  (let ((dir (install-dir)))
    (define (copy from to)
      (let ((from (string-append dir "/" from))
            (to (string-append current-root-dir "/" to)))
        (when (file-exists? to)
          ;; danger
          (delete-file to))
        (copy-file from to)))
    
    (define (copy-dll name)
      (copy name name))
    
    (pp dir)
    (pp current-root-dir)
    (copy "Install.exe" (string-append jiri-application ".exe"))
    (copy-dll "libgit2.dll")
    (copy-dll "libeay32.dll")
    (copy-dll "ssleay32.dll")))


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
