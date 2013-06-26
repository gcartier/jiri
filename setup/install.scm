;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Install
;;;


(include "syntax.scm")


(define stage
  #f)


(define (prepare-stage)
  (set! current-root-dir (getenv-default "root-dir"))
  (set! closed-beta-password (getenv-default "closed-beta-password"))
  (set! called-from (getenv-default "called-from"))
  (set! stage (cond ((and current-root-dir
                          (equal? called-from "root"))
                     'current-from-root)
                    ((and current-root-dir
                          (equal? called-from "setup"))
                     'install-from-setup)
                    ((and current-root-dir
                          (equal? called-from "current"))
                     'install-from-current)
                    (else
                     (system-message "It is incorrect to launch this application")
                     (exit 1))))
  (when (neq? stage 'current-from-root)
    (set! work-percentage (string->number (getenv-default "work-percentage" "0.")))
    (set! work-downloaded (string->number (getenv-default "work-downloaded" "0")))))


;;;
;;;; Install
;;;


(define (install)
  (case stage
    ((current-from-root) (current-from-root-work))
    ((install-from-setup) (install-from-setup-work))
    ((install-from-current) (install-from-current-work))))


;;;
;;;; Current From Root
;;;


(define (current-from-root-work)
  (clone/pull-repository "launcher" jiri-install-remote closed-beta-password (install-dir) 1 6 0. .05 .1
    (lambda (new-content?)
      (if new-content?
          (delegate-install current-root-dir closed-beta-password "current")
        (install-application/world #f)))))


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


(define (install-application/world install?)
  (clone/pull-repository "application" jiri-app-remote closed-beta-password (app-dir) 3 6 .1 .2 .4
    (lambda (new-content?)
      (clone/pull-repository "world" jiri-world-remote closed-beta-password (world-dir) 5 6 .4 .85 1.
        (lambda (new-content?)
          (install-done install?))))))


;;;
;;;; Done
;;;


(define (install-done install?)
  (when install?
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
  (add-view status-view)
  (add-view remaining-view)
  (add-view progress-view)
  (add-view play-view)
  (when (neq? stage 'current-from-root)
    (set-label-title percentage-view (string-append (number->string (fxround work-percentage)) "%"))
    (set-label-title downloaded-view (string-append "Downloaded: " (number->string work-downloaded) "M"))
    (set-label-title status-view (downloading-title "application" 3 6))
    (set-progress-info progress-view (make-range .1 .4) (make-range 0 10)))
  (set! return-press
        (lambda ()
          (when work-done?
            (play)))))


;;;
;;;; Main
;;;


(prepare-stage)
(main install)
