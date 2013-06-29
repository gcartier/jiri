;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Git Interface
;;;


(include "syntax.scm")


;;;
;;;; Pull
;;;


(define (pull-repository title url branch password dir step of head mid tail cont)
  (set-default-cursor IDC_WAIT)
  (set! work-in-progress? #t)
  (set-label-title status-view (downloading-title title step of))
  (let ((existing? (file-exists? dir)))
    (let ((repo (if existing?
                    (git-repository-open dir)
                  (git-repository-init dir 0))))
      (let ((remote (if existing?
                        (git-remote-load repo "origin")
                      (git-remote-create repo "origin" url)))
            (megabytes 0))
        (git-remote-connect-with-retries remote #f)
        (set-download-progress
          (let ((inited? #f))
            (lambda (lparam)
              (let ((total-objects (git-remote-download-total-objects))
                    (received-objects (git-remote-download-received-objects))
                    (received-bytes (git-remote-download-received-bytes)))
                (let ((percentage (* (percentage received-objects total-objects) (- mid head)))
                      (downloaded (fxfloor (/ (exact->inexact received-bytes) (* 1024. 1024.))))
                      (remaining (- total-objects received-objects)))
                  (let ((effective-percentage (fxround (+ work-percentage percentage))))
                    (set-label-title percentage-view (string-append (number->string effective-percentage) "%"))
                    (set-label-title downloaded-view (string-append "Downloaded: " (number->string (+ work-downloaded downloaded)) "M"))
                    (set-label-title remaining-view (string-append "Remaining: " (number->string remaining)))
                    (set! megabytes downloaded)))
                (when (not inited?)
                  (set-progress-info progress-view (make-range head mid) (make-range 0 total-objects))
                  (set! inited? #t))
                (set-progress-pos progress-view received-objects)))))
        (set-download-done
          (lambda (lparam)
            (git-check-error lparam)
            (set! work-percentage (* mid 100.))
            (set! work-downloaded (+ work-downloaded megabytes))
            (set-label-title status-view (installing-title title step of))
            (set-progress-info progress-view (make-range head mid) (make-range 0 10))
            (set-progress-pos progress-view 10)
            (git-remote-disconnect remote)
            (git-remote-update-tips remote)
            (git-remote-free remote)
            (git-repository-set-head repo (string-append "refs/heads/" branch))
            (let ((upstream (git-reference-lookup repo (string-append "refs/remotes/origin/" branch))))
              (let ((commit (git-object-lookup repo (git-reference->id repo upstream) GIT_OBJ_COMMIT)))
                (git-branch-create repo branch commit 1)
                (let ((new-content? #f))
                  (set-checkout-progress
                    (let ((inited? #f))
                      (lambda (lparam)
                        (let ((path (git-checkout-path))
                              (completed-steps (git-checkout-completed-steps))
                              (total-steps (git-checkout-total-steps)))
                          (when (> total-steps 0)
                            (set! new-content? #t)
                            (let ((percentage (* (percentage completed-steps total-steps) (- tail mid)))
                                  (remaining (- total-steps completed-steps)))
                              (let ((effective-percentage (fxround (+ work-percentage percentage))))
                                (set-label-title percentage-view (string-append (number->string effective-percentage) "%"))
                                (set-label-title remaining-view (string-append "Remaining: " (number->string remaining)))))
                            (when (not inited?)
                              (set-progress-info progress-view (make-range mid tail) (make-range 0 total-steps))
                              (set! inited? #t))
                            (set-progress-pos progress-view completed-steps))))))
                  (set-checkout-done
                    (lambda (lparam)
                      (git-check-error lparam)
                      (set! work-percentage (* tail 100.))
                      (set-progress-info progress-view (make-range mid tail) (make-range 0 10))
                      (set-progress-pos progress-view 10)
                      (git-reference-free upstream)
                      (git-object-free commit)
                      (git-repository-free repo)
                      (cont new-content?)))
                (git-checkout-head-force-threaded repo (window-handle current-window)))))))
        (git-remote-download-threaded remote (window-handle current-window))))))


(define (downloading-title title step of)
  (string-append "Downloading " title " (" (number->string step) "/" (number->string of) ")"))


(define (installing-title title step of)
  (string-append "Installing " title " (" (number->string (+ step 1)) "/" (number->string of) ")"))


;;;
;;;; Git
;;;


(define (git-remote-connect-with-retries remote cancel)
  (let ((password #f))
    (define (ask-password)
      (set! password (or closed-beta-password (dialog-box (window-handle current-window))))
      (or password
          (if cancel
              (begin
                (set-default-cursor IDC_ARROW)
                (set! work-in-progress? #f)
                (continuation-return cancel))
            (exit 1))))
    
    (git-remote-check-cert remote 0)
    (git-remote-set-cred-acquire-cb remote
                                    (lambda ()
                                      (git-cred-userpass-plaintext-new jiri-username (ask-password))))
    (let ((max-tries 3))
      (let loop ((try 1))
        (if (> try max-tries)
            (exit 1)
          (with-exception-catcher
            (lambda (exc)
              (if (and (error-exception? exc)
                       (let ((err (->string (car (error-exception-parameters exc)))))
                         (string-ends-with? err "401")))
                  (begin
                    (message-box "Incorrect password")
                    (loop (+ try 1)))
                (raise exc)))
            (lambda ()
              (git-remote-connect remote GIT_DIRECTION_FETCH)
              (set! closed-beta-password password))))))))


;;;
;;;; Callback
;;;


(set-user-callback
  (lambda (wparam lparam)
    (cond ((= wparam DOWNLOAD_PROGRESS) (download-progress lparam))
          ((= wparam DOWNLOAD_DONE)     (download-done     lparam))
          ((= wparam CHECKOUT_PROGRESS) (checkout-progress lparam))
          ((= wparam CHECKOUT_DONE)     (if (in-modal?)
                                            (delay-modal-user-event wparam lparam)
                                          (checkout-done lparam))))))
