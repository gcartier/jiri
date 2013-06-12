;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Install
;;;


;; TODO
;; - Enter closed-beta password (accept license!?)
;; - Update installer


(include "syntax.scm")


;;;
;;;; Window
;;;


(define current-bitmap-handle
  #f)

(define current-bitmap
  #f)


(define (setup-bitmap)
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
      (when (= wparam VK_ESCAPE)
        (exit)))
    
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
;;;; Close
;;;


(define close-view
  (new-close (make-rect 823 13 837 27)))


;;;
;;;; Minimize
;;;


(define minimize-view
  (new-minimize (make-rect 796 13 810 27)))


;;;
;;;; Install
;;;


(define install-view
  (new-button (make-rect 50 450 390 490)
              (string-append "Install " jiri-title)
              (lambda (view)
                (setup))))


;;;
;;;; Percentage
;;;


(define percentage-view
  (new-label (make-rect 50 450 170 470)
             "0%"))


;;;
;;;; Downloaded
;;;


(define downloaded-view
  (new-label (make-rect 180 450 350 470)
             "Downloaded: "))


;;;
;;;; Remaining
;;;


(define remaining-view
  (new-label (make-rect 360 450 500 470)
             "Files remaining: "))


;;;
;;;; Status
;;;


(define status-view
  (new-label (make-rect 510 450 650 470)
             ""
             DT_RIGHT))


;;;
;;;; Download
;;;


(define download-view
  (new-progress (make-rect 50 470 650 490) 0 (make-range 0 10)))


;;;
;;;; Play
;;;


(define play-view
  (new-button (make-rect 680 450 815 490)
              "Play"
              (lambda (view)
                (open-process (string-append current-app-dir "/" jiri-application))
                (quit))
              active?: #f))


;;;
;;;; Setup
;;;


(define current-app-dir
  #f)

(define current-install-dir
  #f)

(define current-runtime-dir
  #f)


(define (quit)
  (exit))


(define (setup)
  (let ((root-dir (pathname-standardize (choose-directory (window-handle current-window) "Please select the installation folder" (get-special-folder CSIDL_PROGRAM_FILESX86)))))
    (when (not (equal? root-dir ""))
      (let ((app-dir (setup-app root-dir)))
        (when app-dir
          (remove-view install-view)
          (add-view percentage-view)
          (add-view downloaded-view)
          (add-view remaining-view)
          (add-view status-view)
          (add-view download-view)
          (add-view play-view)
          (update-window)
          (download app-dir))))))


(define (setup-app root-dir)
  (let ((app-dir (normalize-directory (string-append root-dir "/" jiri-title))))
    (if (not (file-exists? app-dir))
        app-dir
      (let ((code (system-message (string-append "Installation folder already exists: \"" app-dir "\".\n\nDo you want to replace?") type: 'confirmation)))
        (when (eq? code 'yes)
          (let ((code (delete-directory app-dir)))
            (if (= code 0)
                app-dir
              (begin
                (system-message (string-append "Unable to delete folder (" (number->string code) ")"))
                #f))))))))


(define (download app-dir)
  (set-default-cursor IDC_WAIT)
  (set-label-title status-view "Downloading application")
  (let ((repo (git-repository-init app-dir 0)))
    (let ((remote (git-remote-create repo "origin" jiri-remote-runtime)))
      (git-remote-check-cert remote 0)
      (git-remote-set-cred-acquire-cb remote
                                      (lambda ()
                                        (git-cred-userpass-plaintext-new jiri-username jiri-password)))
      (git-remote-connect remote GIT_DIRECTION_FETCH)
      (set-user-callback
        (lambda (wparam lparam)
          (case lparam
            ((0)
             (let ((total-objects (git-remote-download-total-objects))
                   (received-objects (git-remote-download-received-objects))
                   (received-bytes (git-remote-download-received-bytes)))
               (let ((percentage (fxround (percentage received-objects total-objects)))
                     (downloaded (fxfloor (/ (exact->inexact received-bytes) (* 1024. 1024.))))
                     (remaining (- total-objects received-objects)))
                 (set-label-title percentage-view (string-append (number->string percentage) "%"))
                 (set-label-title downloaded-view (string-append "Downloaded: " (number->string downloaded) "M"))
                 (set-label-title remaining-view (string-append "Files remaining: " (number->string remaining))))
               (if (= received-objects 0)
                   (set-progress-range download-view (make-range 0 total-objects))
                 (set-progress-pos download-view received-objects))))
            ((1)
             (set-label-title status-view "111")
             (git-remote-disconnect remote)
             (set-label-title status-view "222")
             (git-remote-update-tips remote)
             (set-label-title status-view "333")
             (git-remote-free remote)
             (set-label-title status-view "Installing application")
             (let ((upstream (git-reference-lookup repo "refs/remotes/origin/master")))
               (let ((commit (git-object-lookup repo (git-reference->id repo upstream) GIT_OBJ_COMMIT)))
                 (git-reset repo commit GIT_RESET_HARD)))
             (git-repository-free repo)
             (set! current-app-dir app-dir)
             (set-label-title status-view "Done")
             (set-view-active? play-view #t)
             (set-default-cursor IDC_ARROW)))))
      (git-remote-download-threaded remote (window-handle current-window)))))


;;;
;;;; Prepare
;;;


(define (prepare)
  (set-current-window window)
  (add-view root-view)
  (add-view title-view)
  (add-view close-view)
  (add-view minimize-view)
  (add-view install-view)
  (setup-bitmap))


;;;
;;;; Run
;;;


(define (run)
  (let ((hwnd (SetupWindow (current-instance) jiri-title (BITMAP-width current-bitmap) (BITMAP-height current-bitmap))))
    (window-handle-set! current-window hwnd)
    (ShowWindow hwnd SW_SHOWNORMAL)
    (UpdateWindow hwnd)
    (MessageLoop)))


;;;
;;;; Main
;;;


(define (main)
  ;(##repl)
  (prepare)
  (run))
