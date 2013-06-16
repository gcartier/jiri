;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Install
;;;


;; TODO
;; - Enter closed-beta password (accept license!? and talk about private content)
;; - Add multiple background support
;;   - Change at 100% / nb of background!?
;; - Update installer and relaunch if more uptodate
;; - Implement 'in-game' installer behavior
;; - Confirmation on close if downloading


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
  (new-label (make-rect 50 450 165 470)
             "0%"))


;;;
;;;; Downloaded
;;;


(define downloaded-view
  (new-label (make-rect 175 450 340 470)
             "Downloaded: "))


;;;
;;;; Remaining
;;;


(define remaining-view
  (new-label (make-rect 350 450 490 470)
             "Remaining: "))


;;;
;;;; Status
;;;


(define status-view
  (new-label (make-rect 500 450 650 470)
             ""
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
                (open-process (string-append (app-dir current-root-dir) "/" jiri-application))
                (quit))
              active?: #f))


;;;
;;;; Setup
;;;


(define current-root-dir
  #f)


(define (app-dir root-dir)
  (string-append root-dir jiri-app-dir))

(define (install-dir root-dir)
  (string-append root-dir jiri-install-dir))

(define (world-dir root-dir)
  (string-append root-dir jiri-world-dir))


(define (setup)
  (let ((dir (pathname-standardize (choose-directory (window-handle current-window) "Please select the installation folder" (get-special-folder CSIDL_PROGRAM_FILESX86)))))
    (when (not (equal? dir ""))
      (let ((root-dir (setup-root dir)))
        (if (not root-dir)
            (set-default-cursor IDC_ARROW)
          (begin
            (remove-view install-view)
            (add-view percentage-view)
            (add-view downloaded-view)
            (add-view remaining-view)
            (add-view status-view)
            (add-view progress-view)
            (add-view play-view)
            (update-window)
            (download root-dir)))))))


(define (setup-root dir)
  (let ((root-dir (normalize-directory (string-append dir "/" jiri-title))))
    (if (not (file-exists? root-dir))
        root-dir
      (let ((code (system-message (string-append "Installation folder already exists: \"" root-dir "\".\n\nDo you want to replace?") type: 'confirmation)))
        (when (eq? code 'yes)
          (set-default-cursor IDC_WAIT)
          (let ((code (delete-directory root-dir)))
            (if (= code 0)
                root-dir
              (begin
                (system-message (string-append "Unable to delete folder (" (number->string code) ")"))
                #f))))))))


(define (download root-dir)
  (download-repository "install" jiri-install-remote (install-dir root-dir) 1 6 0. .05 .1
    (lambda ()
      (download-repository "application" jiri-app-remote (app-dir root-dir) 3 6 .1 .3 .5
        (lambda ()
          (download-repository "world" jiri-world-remote (world-dir root-dir) 5 6 .5 .75 1.
            (lambda ()
              (set! current-root-dir root-dir)
              (set-label-title status-view "Done")
              (set-view-active? play-view #t)
              (set-default-cursor IDC_ARROW))))))))


(define (download-repository title url dir step of head mid tail cont)
  (set-default-cursor IDC_WAIT)
  (set-label-title status-view (string-append "Downloading " title " (" (number->string step) "/" (number->string of) ")"))
  (update-window)
  (let ((repo (git-repository-init dir 0)))
    (let ((remote (git-remote-create repo "origin" url)))
      (git-remote-check-cert remote 0)
      (git-remote-set-cred-acquire-cb remote
                                      (lambda ()
                                        (git-cred-userpass-plaintext-new jiri-username jiri-password)))
      (git-remote-connect remote GIT_DIRECTION_FETCH)
      (set-download-progress
        (lambda (lparam)
          (let ((total-objects (git-remote-download-total-objects))
                (received-objects (git-remote-download-received-objects))
                (received-bytes (git-remote-download-received-bytes)))
            (let ((percentage (fxround (* (percentage received-objects total-objects) .5)))
                  (downloaded (fxfloor (/ (exact->inexact received-bytes) (* 1024. 1024.))))
                  (remaining (- total-objects received-objects)))
              (set-label-title percentage-view (string-append (number->string percentage) "%"))
              (set-label-title downloaded-view (string-append "Downloaded: " (number->string downloaded) "M"))
              (set-label-title remaining-view (string-append "Remaining: " (number->string remaining))))
            (if (= received-objects 0)
                (set-progress-info progress-view (make-range head mid) (make-range 0 total-objects))
              (set-progress-pos progress-view received-objects)))))
      (set-download-done
        (lambda (lparam)
          (git-check-error lparam)
          (set-label-title status-view (string-append "Installing " title " (" (number->string (+ step 1)) "/" (number->string of) ")"))
          (update-window)
          (git-remote-disconnect remote)
          (git-remote-update-tips remote)
          (git-remote-free remote)
          (let ((upstream (git-reference-lookup repo "refs/remotes/origin/master")))
            (let ((commit (git-object-lookup repo (git-reference->id repo upstream) GIT_OBJ_COMMIT)))
              ;; (git-reset repo commit GIT_RESET_HARD)
              ;; inlining of the previous command in order to add checkout progress callback
              (let ((index (git-repository-index repo))
                    (tree (git-commit-tree commit)))
                (git-reference__update_terminal repo "HEAD" commit)
                (set-checkout-progress
                  (lambda (lparam)
                    (let ((path (git-checkout-path))
                          (completed-steps (git-checkout-completed-steps))
                          (total-steps (git-checkout-total-steps)))
                      (let ((percentage (fxround (+ 50. (* (percentage completed-steps total-steps) .5))))
                            (remaining (- total-steps completed-steps)))
                        (set-label-title percentage-view (string-append (number->string percentage) "%"))
                        (set-label-title remaining-view (string-append "Remaining: " (number->string remaining))))
                      (if (not path)
                          (set-progress-info progress-view (make-range mid tail) (make-range 0 total-steps))
                        (set-progress-pos progress-view completed-steps)))))
                (set-checkout-done
                  (lambda (lparam)
                    (git-check-error lparam)
                    (git-index-read-tree index tree)
                    (git-index-write index)
                    (git-repository-merge-cleanup repo)
                    (git-reference-free upstream)
                    (git-object-free commit)
                    (git-index-free index)
                    (git-tree-free tree)
                    (git-repository-free repo)
                    (cont)))
                (git-checkout-tree-force-threaded repo tree (window-handle current-window)))))))
      (git-remote-download-threaded remote (window-handle current-window)))))


(define (quit)
  (exit))


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
