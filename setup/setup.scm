;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Install
;;;


;; TODO
;; - Need to implement with-cursor calling update-cursor


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
    
    (define (mouse-move x y)
      (let ((view (find-view x y)))
        (if view
            (call-mouse-move view x y)
          (set-cursor IDC_ARROW))))
    
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
    
    (make-window #f draw key-down mouse-move mouse-down mouse-up)))


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
             "Dawn of Space"))


;;;
;;;; Close
;;;


(define close-view
  (new-close (make-rect 825 15 835 25)))


;;;
;;;; Minimize
;;;


(define minimize-view
  (new-minimize (make-rect 798 15 808 25)))


;;;
;;;; Install
;;;


(define install-view
  (new-button (make-rect 50 450 390 490)
              "Install Dawn of Space"
              (lambda (view)
                (setup))))


;;;
;;;; Percentage
;;;


(define percentage-view
  (new-label (make-rect 50 450 150 470)
             "0%"))


;;;
;;;; Downloaded
;;;


(define downloaded-view
  (new-label (make-rect 200 450 300 470)
             "Downloaded: 72MB"))


;;;
;;;; Remaining
;;;


(define remaining-view
  (new-label (make-rect 400 450 500 470)
             "Files remaining: 272"))


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
                (exit))
              active?: #f))


;;;
;;;; Status
;;;


(define status-view
  (new-label (make-rect 10 530 850 540)
             ""))


;;;
;;;; Setup
;;;


(define (quit)
  (exit))


(define (setup)
  (remove-view install-view)
  (add-view percentage-view)
  (add-view downloaded-view)
  (add-view remaining-view)
  (add-view download-view)
  (add-view play-view)
  (update-window)
  (download)
  (set-view-active? play-view #t))


(define (download)
  (set-cursor IDC_WAIT)
  (let ((url "d:/space-media" #; "https://github.com/gcartier/space-media.git")
        (dir "aaa"))
    (let ((normalized-dir (string-append dir "/")))
      (when (file-exists? normalized-dir)
        (empty/delete-directory normalized-dir overwrite-readonly?: #t)))
    (let ((repo (git-repository-init dir 0)))
      (let ((remote (git-remote-create repo "origin" url)))
        (git-remote-check-cert remote 0)
        (git-remote-set-cred-acquire-cb remote
                                        (lambda ()
                                          #f #;
                                          (git-cred-userpass-plaintext-new "dawnofspacebeta" "gazoum123")))
        (git-remote-connect remote GIT_DIRECTION_FETCH)
        (let ((first-call? #t))
          (define (callback total-objects indexed-objects received-objects received-bytes)
            (if (= received-objects 0)
                (set-progress-range download-view (make-range 0 total-objects))
              (set-progress-pos download-view received-objects)))
          
          (git-remote-download remote callback))
        (git-remote-disconnect remote)
        (git-remote-update-tips remote)
        (git-remote-free remote)
        (let ((upstream (git-reference-lookup repo "refs/remotes/origin/master")))
          (let ((commit (git-object-lookup repo (git-reference->id repo upstream) GIT_OBJ_COMMIT)))
            (git-reset repo commit GIT_RESET_HARD))))
      (git-repository-free repo))))


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
  (add-view status-view)
  (setup-bitmap))


;;;
;;;; Run
;;;


(define (run)
  (let ((hwnd (SetupWindow (current-instance) (BITMAP-width current-bitmap) (BITMAP-height current-bitmap))))
    (window-handle-set! current-window hwnd)
    (ShowWindow hwnd SW_SHOWNORMAL)
    (UpdateWindow hwnd)
    (MessageLoop)))


;;;
;;;; Main
;;;


(define (t)
  (let ((dir "aaa/"))
    (when (file-exists? dir)
      (empty/delete-directory dir overwrite-readonly?: #t)
      (wait-deleted-workaround dir))))


(define (main)
  ;(##repl)
  (prepare)
  (run))
