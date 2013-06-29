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
                     (message-box "It is incorrect to launch this application")
                     (exit 1))))
  (when (neq? stage 'current-from-root)
    (set! work-percentage (string->number (getenv-default "work-percentage" "0.")))
    (set! work-downloaded (string->number (getenv-default "work-downloaded" "0")))
    (set! window-h (string->number (getenv-default "window-h" "-1")))
    (set! window-v (string->number (getenv-default "window-v" "-1")))))


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
  (pull-repository "launcher" jiri-install-remote closed-beta-password (install-dir) 1 6 0. .05 .1
    (lambda (new-content?)
      (if new-content?
          (delegate-install current-root-dir closed-beta-password "current")
        (install-application/world
          (lambda (new-content?)
            (rewind-start-menu)
            (install-done)))))))


;;;
;;;; Install From Setup
;;;


(define (install-from-setup-work)
  (install-application/world
    (lambda (new-content?)
      (install-current)
      (install-root)
      (install-desktop-shortcut)
      (install-start-menu)
      (install-uninstall)
      (install-done))))


;;;
;;;; Install From Current
;;;


(define (install-from-current-work)
  (install-application/world
    (lambda (new-content?)
      (install-current)
      (install-root)
      (rewind-start-menu)
      (install-done))))


;;;
;;;; Work
;;;


(define (install-application/world cont)
  (pull-repository "application" jiri-app-remote closed-beta-password (app-dir) 3 6 .1 .2 .4
    (lambda (new-content?)
      (pull-repository "world" jiri-world-remote closed-beta-password (world-dir) 5 6 .4 .85 1.
        cont))))


;;;
;;;; Done
;;;


(define (install-done)
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
    (remove-directory current-dir)
    (create-directory current-dir)
    
    (copy "Install.exe")
    (copy "Uninstall.exe")
    (copy "libgit2.dll")
    (copy "libeay32.dll")
    (copy "ssleay32.dll")))


(define (install-root)
  (let ((from (launcher-exe))
        (to (root-exe)))
    ;; danger
    (when (file-exists? to)
      (delete-file to))
    (copy-file from to)))


(define (install-desktop-shortcut)
  (let ((path (root-exe))
        (shortcut (desktop-shortcut)))
    (let ((hr (create-shortcut path shortcut jiri-title)))
      (when (< hr 0)
        (error "Unable to create desktop shortcut (0x" (number->string hr 16) ")")))))


(define (install-start-menu)
  (let ((root (root-exe))
        (appdir (start-menu-appdir)))
    (when (file-exists? appdir)
      ;; danger
      (remove-directory appdir))
    (create-directory appdir)
    (let ((shortcut (start-menu-shortcut appdir)))
      (let ((hr (create-shortcut root shortcut jiri-title)))
        (when (< hr 0)
          (error "Unable to create start menu shortcut (0x" (number->string hr 16) ")"))))))


;; hack around windows taking forever to remove newly installed highlight
(define (rewind-start-menu)
  (let ((shortcut (start-menu-shortcut (start-menu-appdir))))
    (when (file-exists? shortcut)
      (rewind-creation-time shortcut))))


(define (install-uninstall)
  (let ((key (registry-create-key (HKEY_CURRENT_USER) (uninstall-subkey))))
    (registry-set-string key "DisplayName" jiri-title)
    (registry-set-string key "DisplayIcon" (pathname-platformize (root-exe)))
    (registry-set-string key "DisplayVersion" jiri-version)
    (registry-set-string key "Publisher" jiri-company)
    (registry-set-string key "InstallDate" (get-local-date))
    (registry-set-string key "InstallLocation" (pathname-platformize current-root-dir))
    (registry-set-string key "UninstallString" (string-append (pathname-platformize (root-exe)) " -uninstall"))
    (registry-set-int key "EstimatedSize" jiri-size)
    (registry-set-int key "NoModify" 1)
    (registry-set-int key "NoRepair" 1)
    (registry-close-key key)))


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
  (set-return-press
    (lambda ()
      (when work-done?
        (play))))
  (set-quit (quit-confirm-abort "Install")))


;;;
;;;; Main
;;;


(prepare-stage)
(main install)
