;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Install
;;;


;;;
;;;; Window
;;;


(define window
  (let ()
    (define (draw hdc)
      (let ((width (BITMAP-width current-bitmap))
            (height (BITMAP-height current-bitmap))
            (hdcMem (CreateCompatibleDC hdc)))
        (let ((hbmOld (SelectObject hdcMem current-hbitmap)))
          (BitBlt hdc 0 0 width height hdcMem 0 0 SRCCOPY)
          (SelectObject hdcMem hbmOld)
          (DeleteDC hdcMem)))
      (draw-views hdc))
    
    (define (key-down wparam)
      (if (= wparam VK_ESCAPE)
          (exit)))
    
    (define (mouse-down x y)
      (continuation-capture
        (lambda (return)
          (for-each (lambda (view)
                      (if (in-rect? (make-point x y) (view-rect view))
                          (let ((mouse-down (view-mouse-down view)))
                            (if mouse-down
                                (begin
                                  (mouse-down view x y)
                                  (continuation-return return))))))
                    views)
          (exit))))
    
    (make-window #f draw key-down mouse-down)))


;;;
;;;; Title
;;;


(define title-view
  (new-label (make-rect 130 18 330 168)
             "Dawn of Space"))


;;;
;;;; Install
;;;


(define install-view
  (new-button (make-rect 50 450 390 490)
              "Install Dawn of Space"
              (lambda (view)
                (setup))))


;;;
;;;; Download
;;;


(define download-view
  (new-progress (make-rect 50 470 690 490)))


;;;
;;;; Play
;;;


(define play-view
  (new-button (make-rect 720 450 800 490)
              "Play"
              (lambda (view)
                #f)))


;;;
;;;; Setup
;;;


(define (setup)
  (remove-view install-view)
  (add-view download-view)
  (add-view play-view)
  (for-each (lambda (n)
              (set-progress-pos download-view n)
              (redraw-view download-view)
              (thread-sleep! .1))
            '(1 2 3 4 5 6 7 8 9 10))
  #;
  (download))


(define (download)
  (let ((url "https://github.com/gcartier/space-media.git")
        (dir "aaa/space-media"))
    (let ((repo (git-repository-init dir 0)))
      (let ((remote (git-remote-create repo "origin" url)))
        (git-remote-check-cert remote 0)
        (git-remote-set-cred-acquire-cb remote
                                        (lambda ()
                                          #f #;
                                          (git-cred-userpass-plaintext-new "dawnofspacebeta" "gazoum123")))
        (git-remote-connect remote GIT_DIRECTION_FETCH)
        (git-remote-download remote
                             (lambda (total_objects indexed_objects received_objects stats->received_bytes)
                               (pp (list total_objects indexed_objects received_objects stats->received_bytes))))
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
  (add-view title-view)
  (add-view install-view)
  (let ((hbm (LoadBitmap (current-instance) "BACKGROUND")))
    (let ((bm (BITMAP-make)))
      (GetBitmap hbm (BITMAP-sizeof) bm)
      (set! current-hbitmap hbm)
      (set! current-bitmap bm))))


;;;
;;;; Run
;;;


(define (run)
  (let ((hwnd (SetupWindow (current-instance) (BITMAP-width current-bitmap) (BITMAP-height current-bitmap))))
    (window-handle-set! current-window hwnd)
    (ShowWindow hwnd SW_SHOWNORMAL)
    (UpdateWindow hwnd)
    (MessageLoop)))
