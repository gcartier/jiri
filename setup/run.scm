;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Run
;;;


;;;
;;;; Draw
;;;


(define (draw hdc)
  (let ((width (BITMAP-width current-bitmap))
        (height (BITMAP-height current-bitmap))
        (hdcMem (CreateCompatibleDC hdc)))
    (let ((hbmOld (SelectObject hdcMem current-hbitmap)))
      (BitBlt hdc 0 0 width height hdcMem 0 0 SRCCOPY)
      (SelectObject hdcMem hbmOld)
      (DeleteDC hdcMem)))
  (draw-views hdc))


;;;
;;;; Keyboard
;;;


(define (key-down wparam)
  (if (= wparam VK_ESCAPE)
      (exit)))


;;;
;;;; Mouse
;;;


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


;;;
;;;; Window
;;;


(define window
  (make-window #f draw key-down mouse-down))


;;;
;;;; Title
;;;


(define title-view
  (let ()
    (define (draw view hdc)
      (SetBkMode hdc TRANSPARENT)
      (SetTextColor hdc (RGB 255 255 255))
      (let ((font (CreateFont
                    72 0 0 0 FW_DONTCARE FALSE FALSE FALSE
                    DEFAULT_CHARSET OUT_DEFAULT_PRECIS CLIP_DEFAULT_PRECIS
                    ANTIALIASED_QUALITY FF_DONTCARE "Tahoma")))
        (SelectObject hdc font)
        (let ((rect (view-rect view)))
          (DrawText hdc "Dawn of Space" -1 (rect->RECT rect) (bitwise-ior DT_CENTER DT_NOCLIP)))))
    
    (make-view (make-rect 130 18 330 168)
               draw
               #f)))


;;;
;;;; Install
;;;


(define install-view
  (let ()
    (define (draw view hdc)
      (SetBkMode hdc TRANSPARENT)
      (SetTextColor hdc (RGB 255 255 255))
      (let ((font (CreateFont
                    24 0 0 0 FW_DONTCARE FALSE FALSE FALSE
                    DEFAULT_CHARSET OUT_DEFAULT_PRECIS CLIP_DEFAULT_PRECIS
                    ANTIALIASED_QUALITY FF_DONTCARE "Tahoma")))
        (SelectObject hdc font)
        (let ((rect (view-rect view)))
          (let ((left (rect-left rect))
                (top (rect-top rect))
                (right (rect-right rect))
                (bottom (rect-bottom rect)))
            (DrawGradient hdc left top right bottom (RGB 150 0 0) (RGB 220 0 0) #f)
            (let ((textRect (make-rect left (+ top 7) right (+ bottom 7))))
              (DrawText hdc "Install Dawn of Space" -1 (rect->RECT textRect) (bitwise-ior DT_CENTER DT_NOCLIP)))))))
    
    (define (mouse-down view x y)
      (with-handle-exception
        (lambda ()
          (setup))))
    
    (make-view (make-rect 50 450 390 490)
               draw
               mouse-down)))


;;;
;;;; Setup
;;;


(define (debug n)
  (system-message (number->string n)))


(define (setup)
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
;;;; Exception
;;;


(define (with-handle-exception thunk)
  (define (debug-exception exc console)
    (call-with-output-file (list path: "exception.txt" eol-encoding: eol-encoding)
      (lambda (output)
        (display-exception exc output)
        (continuation-capture
          (lambda (cont)
            (display-continuation-backtrace cont output #t #t 1000 1000))))))
  
  (with-exception-handler
    (lambda (exc)
      (system-message "An unexpected problem occurred")
      (debug-exception exc console)
      (exit 1))
    thunk))


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


;;;
;;;; Main
;;;


(prepare)
(run)
