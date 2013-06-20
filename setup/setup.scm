;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Setup
;;;


(include "syntax.scm")


;;;
;;;; View
;;;


(define setup-view
  (new-button (make-rect 50 450 390 490)
              (string-append "Setup " jiri-title)
              (lambda (view)
                (setup))))


;;;
;;;; Setup
;;;


(define (setup)
  (when (setup-root)
    (when (setup-password)
      (remove-view setup-view)
      (add-view percentage-view)
      (add-view downloaded-view)
      (add-view remaining-view)
      (add-view status-view)
      (add-view progress-view)
      (add-view play-view)
      (setup-work))))


(define (setup-root)
  (define (determine-root-dir)
    (let ((dir (pathname-standardize (choose-directory (window-handle current-window) "Please select the installation folder" (get-special-folder CSIDL_PROGRAM_FILESX86)))))
      (when (not (equal? dir ""))
        (normalize-directory (string-append dir "/" jiri-title)))))
  
  (let ((root-dir (or current-root-dir (determine-root-dir))))
    (when root-dir
      (if (not (file-exists? root-dir))
          (begin
            (set! current-root-dir root-dir)
            root-dir)
        (let ((code (if current-root-dir
                        'yes
                      (system-message (string-append "Installation folder already exists: " root-dir "\n\nDo you want to replace?") type: 'confirmation))))
          (when (eq? code 'yes)
            (set-default-cursor IDC_WAIT)
            (set! work-in-progress? #t)
            ;; danger
            (let ((code (delete-directory root-dir)))
              (if (= code 0)
                  (begin
                    (set! current-root-dir root-dir)
                    root-dir)
                (begin
                  (set-default-cursor IDC_ARROW)
                  (set! work-in-progress? #f)
                  (system-message (string-append "Unable to delete folder (0x" (number->string code 16) ")"))
                  #f)))))))))


(define (setup-work)
  (clone/pull-repository "application" jiri-install-remote closed-beta-password (install-dir) 1 4 #f #f #f
    (lambda (new-content?)
      (setup-done))))


(define (setup-done)
  (set-default-cursor IDC_ARROW)
  (set! work-in-progress? #f)
  (set! work-done? #t)
  (delegate-install current-root-dir closed-beta-password "setup"))


;;;
;;;; Layout
;;;


(define (layout)
  (add-view root-view)
  (add-view title-view)
  (add-view close-view)
  (add-view minimize-view)
  (add-view setup-view)
  (set! return-press
        (lambda ()
          (when (not work-done?)
            (setup)))))


;;;
;;;; Main
;;;


(main)
