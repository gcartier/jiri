;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Work
;;;


;; Pourquoi le shortcut sur le desktop a perdu son icone???


;; Ajouter un monde de minecraft


;; TODO
;; - Create start menu folder!? (others!?)
;; - Handle all git errors!?
;; - It is not user-friendly to not be able to change setup dir after clicking Setup and
;;   changing ones mind at password stage but I do not see any alternative
;; - Add multiple background support
;;   - Change at 100% / nb of background!?
;; - Install could pass info to the app of what was the last head so that we could show
;;   only what changed since last time by having a what's new system indexed by commit!?
;; - When Marc has fixed the FFI error problem, replace the global error-handler by a catcher
;;   to ward against recursive errors
;; - A potential problem can occur when I push a new release because pushing to both app and
;;   world is not atomic. This can be alleviated a bit by a script to push a release pushing
;;   both repositories rapidly maybe even in parallel
;; - Do not forget about the --orphan branch as the multiple pushes of Install versions are starting to
;;   make even the clone of Install painfully long
;; - Invoking app directly should error
;; - Uninstaller

;; DEVEL
;; - comment out (current-exception-handler jiri-exception-handler)
;; - test/Dawn/Dawn -:dar

;; RELEASE
;; Install
;;   - b
;;   - cd release/install
;;   - commit and push changes
;; Setup
;;   - i
;;   - m
;;   - publish Dawn of Space Setup

;; SCENARIO
;; - Setup : clone install, delegate Install
;; - Root : delegate Current
;; - Current from Root : pull install, if newer delegate Install else pull app/world
;; - Current direct : incorrect
;; - Install from Setup : clone app/world
;; - Install from Current : pull app/world
;; - Install direct : incorrect
;; - App : incorrect but could be correct when version is validated with server

;; SPACE
;; - app
;;   - space
;;     - Space.exe
;;     - lib
;;   - space-debug
;; - install
;;   - current
;;     - Install.exe
;;     - libgit2.dll
;;   - space-install
;;     - Install.exe
;;     - Launch.exe
;;     - libgit2.dll
;; - worlds
;;   - space
;; Space.exe


(include "syntax.scm")


;;;
;;;; Window
;;;


(define current-bitmap-handle
  #f)

(define current-bitmap
  #f)


(define (prepare-bitmap)
  (let ((hbm (LoadBitmap (current-instance) "BACKGROUND")))
    (let ((bm (BITMAP-make)))
      (GetBitmap hbm (BITMAP-sizeof) bm)
      (set! current-bitmap-handle hbm)
      (set! current-bitmap bm))))


(define window
  (let ()
    (define (draw hdc)
      (let ((width (BITMAP-width current-bitmap))
            (height (BITMAP-height current-bitmap))
            (hdcBitmap (CreateCompatibleDC hdc))
            (hdcMem (CreateCompatibleDC hdc)))
        (let ((bmMem (CreateCompatibleBitmap hdc width height)))
          (SelectObject hdcBitmap current-bitmap-handle)
          (SelectObject hdcMem bmMem)
          (BitBlt hdcMem 0 0 width height hdcBitmap 0 0 SRCCOPY)
          (draw-views hdcMem)
          (BitBlt hdc 0 0 width height hdcMem 0 0 SRCCOPY)
          (DeleteObject bmMem)
          (DeleteDC hdcBitmap)
          (DeleteDC hdcMem))))
    
    (define (key-down wparam)
      (cond ((= wparam VK_RETURN)
             (when (and return-press (not work-in-progress?))
               (return-press)))
            ((= wparam VK_ESCAPE)
             (quit))))
    
    (define (update-cursor window)
      (let ((pos (window-cursor-position window)))
        (let ((x (point-h pos))
              (y (point-v pos)))
          (let ((view (find-view x y)))
            (if view
                (let ((update-cursor (view-update-cursor view)))
                  (if update-cursor
                      (update-cursor view x y)
                    (set-cursor default-cursor)))
              (set-cursor default-cursor))))))
    
    (define (mouse-move x y)
      (let ((view (find-view x y)))
        (if view
            (call-mouse-move view x y)
          (set-cursor default-cursor))))
    
    (define (mouse-down x y)
      (let ((view (find-view x y)))
        (when (and view (view-active? view))
          (let ((mouse-down (view-mouse-down view)))
            (when mouse-down
              (mouse-down view x y))))))
    
    (define (mouse-up x y)
      (let ((view (find-view x y)))
        (when (and view (view-active? view))
          (let ((mouse-up (view-mouse-up view)))
            (when mouse-up
              (mouse-up view x y))))))
    
    (define (find-view x y)
      (or captured-view
          (let ((pt (make-point x y)))
            (continuation-capture
              (lambda (return)
                (for-each (lambda (view)
                            (when (in-rect? pt (view-rect view))
                              (continuation-return return view)))
                          views)
                #f)))))
    
    (make-window #f draw key-down update-cursor mouse-move mouse-down mouse-up)))


(define return-press
  #f)


;;;
;;;; Root
;;;


(define root-view
  (new-root (make-rect 0 0 850 550)))


;;;
;;;; Title
;;;


(define title-view
  (new-title (make-rect 20 18 440 100)
             jiri-title))


;;;
;;;; Minimize
;;;


(define minimize-view
  (new-minimize (make-rect 796 13 810 27)))


;;;
;;;; Close
;;;


(define close-view
  (new-close (make-rect 823 13 837 27)))


;;;
;;;; Percentage
;;;


(define percentage-view
  (new-label (make-rect 50 450 165 470)
             "0%"))


;;;
;;;; Downloaded
;;;


(define downloaded-view
  (new-label (make-rect 175 450 340 470)
             "Downloaded: "))


;;;
;;;; Status
;;;


(define status-view
  (new-label (make-rect 350 450 490 470)
             ""
             DT_RIGHT))


;;;
;;;; Remaining
;;;


(define remaining-view
  (new-label (make-rect 500 450 650 470)
             "Remaining: "
             DT_RIGHT))


;;;
;;;; Progress
;;;


(define progress-view
  (new-progress (make-rect 50 470 650 490) (make-range 0 10) 0))


;;;
;;;; Play
;;;


(define play-view
  (new-button (make-rect 680 450 815 490)
              "Play"
              (lambda (view)
                (play))
              active?: #f))


;;;
;;;; Work
;;;


(define work-in-progress?
  #f)

(define work-done?
  #f)

(define work-percentage
  0.)

(define work-downloaded
  0)


;;;
;;;; Pull
;;;


(define (clone/pull-repository title url password dir step of head mid tail cont)
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
            (let ((upstream (git-reference-lookup repo "refs/remotes/origin/master")))
              (let ((commit (git-object-lookup repo (git-reference->id repo upstream) GIT_OBJ_COMMIT)))
                ;; (git-reset repo commit GIT_RESET_HARD)
                ;; inlining of the previous command in order to add checkout progress callback
                (let ((index (git-repository-index repo))
                      (tree (git-commit-tree commit))
                      (new-content? #f))
                  (git-reference__update_terminal repo "HEAD" commit)
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
                      (git-index-read-tree index tree)
                      (git-index-write index)
                      (git-repository-merge-cleanup repo)
                      (git-reference-free upstream)
                      (git-object-free commit)
                      (git-index-free index)
                      (git-tree-free tree)
                      (git-repository-free repo)
                      (cont new-content?)))
                  (git-checkout-tree-force-threaded repo tree (window-handle current-window)))))))
        (git-remote-download-threaded remote (window-handle current-window))))))


(define (downloading-title title step of)
  (string-append "Downloading " title " (" (number->string step) "/" (number->string of) ")"))


(define (installing-title title step of)
  (string-append "Installing " title " (" (number->string (+ step 1)) "/" (number->string of) ")"))


;;;
;;;; Play
;;;


(define (play)
  (delegate-process (app-exe))
  (quit))


;;;
;;;; Quit
;;;


(define (quit)
  (if (not work-in-progress?)
      (exit)
    (let ((code (system-message (string-append "Setup in progress.\n\nDo you want to abort?") type: 'confirmation)))
      (when (eq? code 'yes)
        (exit)))))


;;;
;;;; Callback
;;;


(define download-progress
  #f)

(define (set-download-progress proc)
  (set! download-progress proc))


(define download-done
  #f)

(define (set-download-done proc)
  (set! download-done proc))


(define checkout-progress
  #f)

(define (set-checkout-progress proc)
  (set! checkout-progress proc))


(define checkout-done
  #f)

(define (set-checkout-done proc)
  (set! checkout-done proc))


(define (user-callback wparam lparam)
  (cond ((= wparam DOWNLOAD_PROGRESS) (download-progress lparam))
        ((= wparam DOWNLOAD_DONE)     (download-done     lparam))
        ((= wparam CHECKOUT_PROGRESS) (checkout-progress lparam))
        ((= wparam CHECKOUT_DONE)     (checkout-done     lparam))))


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
                    (system-message "Incorrect password")
                    (loop (+ try 1)))
                (raise exc)))
            (lambda ()
              (git-remote-connect remote GIT_DIRECTION_FETCH)
              (set! closed-beta-password password))))))))


;;;
;;;; Prepare
;;;


(define (prepare)
  (initialize-windows)
  (prepare-bitmap)
  (set-current-window window))


;;;
;;;; Run
;;;


(define (run #!optional (start #f))
  (let ((hwnd (SetupWindow (current-instance) jiri-title (BITMAP-width current-bitmap) (BITMAP-height current-bitmap))))
    (window-handle-set! current-window hwnd)
    (ShowWindow hwnd SW_SHOWNORMAL)
    (UpdateWindow hwnd)
    (when start
      (start))
    (MessageLoop)))


;;;
;;;; Main
;;;


(define (main #!optional (start #f))
  (prepare)
  (layout)
  (run start))
