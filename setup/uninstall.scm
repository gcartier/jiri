;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Uninstall
;;;


(include "syntax.scm")


;;;
;;;; View
;;;


(define uninstall-view
  (new-button (make-rect 50 450 390 490)
              (string-append "Uninstall " jiri-title)
              (lambda (view)
                (uninstall))))


;;;
;;;; Uninstall
;;;


(define (uninstall)
  (define (not-found)
    (message-box (string-append jiri-title " was not found on this computer.")
                 title: (string-append jiri-title " Uninstall")
                 type: 'problem))
  
  (let ((key (registry-open-key (HKEY_CURRENT_USER) (uninstall-subkey))))
    (if (not key)
        (not-found)
      (let ((install-dir (registry-query-string key "InstallLocation")))
        (registry-close-key key)
        (if (not install-dir)
            (not-found)
          (let ((code (message-box (string-append "Remove " jiri-title " and all of its components?")
                                   title: (string-append jiri-title " Uninstall")
                                   type: 'question)))
            (when (eq? code 'yes)
              (uninstall-desktop-shortcut)
              (uninstall-start-menu)
              (uninstall-uninstall)
              (uninstall-install install-dir)
              (message-box (string-append jiri-title " was successfully removed from your computer.")
                           title: (string-append jiri-title " Uninstall"))
              (seppuku-exit))))))))


(define (uninstall-desktop-shortcut)
  (let ((shortcut (desktop-shortcut)))
    (when (file-exists? shortcut)
      ;; danger
      (delete-file shortcut))))


(define (uninstall-start-menu)
  (let ((appdir (start-menu-appdir)))
    (when (file-exists? appdir)
      ;; danger
      (delete-directory appdir))))


(define (uninstall-uninstall)
  (registry-delete-key (HKEY_CURRENT_USER) (uninstall-subkey)))


(define (uninstall-install install-dir)
  (when (file-exists? install-dir)
    ;; danger
    (let ((code (delete-directory install-dir)))
      (when (/= code 0)
        (message-box (string-append "Unable to delete installation folder (0x" (number->string code 16) "): " install-dir))))))


(define (seppuku-exit)
  (define (generate-remover uninstall remove)
    (call-with-output-file (list path: remove eol-encoding: eol-encoding)
      (lambda (output)
        (display ":Repeat" output)
        (newline output)
        (display (string-append "del \"" uninstall "\"") output)
        (newline output)
        (display (string-append "if exist \"" uninstall "\" goto Repeat") output)
        (newline output)
        (display (string-append "del \"" remove "\"") output)
        (newline output)
        (force-output output))))
  
  (let ((uninstall (executable-path))
        (remove (get-temporary-file (string-append jiri-title " remove") "bat")))
    (generate-remover uninstall remove)
    (create-console-process (string-append "cmd /c \"" remove "\""))
    (exit)))


;;;
;;;; Layout
;;;


(define (layout)
  (add-view root-view)
  (add-view title-view)
  (add-view close-view)
  (add-view minimize-view)
  (add-view uninstall-view)
  (set-return-press
    (lambda ()
      (uninstall)))
  (set-quit
    (lambda ()
      (seppuku-exit))))


;;;
;;;; Main
;;;


(main)
