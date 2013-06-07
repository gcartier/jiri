;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Run
;;;


;;;
;;;; Draw
;;;


(define (window-draw hdc)
  (let ((width (BITMAP-width current-bitmap))
        (height (BITMAP-height current-bitmap))
        (hdcMem (CreateCompatibleDC hdc)))
    (let ((hbmOld (SelectObject hdcMem current-hbitmap)))
      (BitBlt hdc 0 0 width height hdcMem 0 0 SRCCOPY)
      (SelectObject hdcMem hbmOld)
      (DeleteDC hdcMem)))
  (SetBkMode hdc TRANSPARENT)
  (SetTextColor hdc (RGB 255 255 255))
  (let ((font (CreateFont
                72 0 0 0 FW_DONTCARE FALSE FALSE FALSE
                DEFAULT_CHARSET OUT_DEFAULT_PRECIS CLIP_DEFAULT_PRECIS
                ANTIALIASED_QUALITY FF_DONTCARE "Tahoma")))
    (SelectObject hdc font)
    (let ((textRect (new-rect 130 18 330 168)))
      (DrawText hdc "Dawn of Space" -1 textRect (bitwise-ior DT_CENTER DT_NOCLIP))))
  (let ((font (CreateFont
                24 0 0 0 FW_DONTCARE FALSE FALSE FALSE
                DEFAULT_CHARSET OUT_DEFAULT_PRECIS CLIP_DEFAULT_PRECIS
                ANTIALIASED_QUALITY FF_DONTCARE "Tahoma")))
    (SelectObject hdc font)
    (let ((left 50)
          (top 450)
          (right 390)
          (bottom 490))
      (DrawGradient hdc left top right bottom (RGB 150 0 0) (RGB 220 0 0) #f)
      (let ((textRect (new-rect left (+ top 7) right (+ bottom 7))))
        (DrawText hdc "Install Dawn of Space" -1 textRect (bitwise-ior DT_CENTER DT_NOCLIP))))))


;;;
;;;; Keyboard
;;;


(define (window-key-down wparam)
  (if (= wparam VK_ESCAPE)
      (exit)))


;;;
;;;; Mouse
;;;


(define (window-mouse-down x y)
  (exit))


;;;
;;;; Prepare
;;;


(define (prepare)
  (set-draw-callback window-draw)
  (set-key-down-callback window-key-down)
  (set-mouse-down-callback window-mouse-down)
  (let ((hbm (LoadBitmap (current-instance) "BACKGROUND")))
    (let ((bm (BITMAP-make)))
      (GetBitmap hbm (BITMAP-sizeof) bm)
      (set! current-hbitmap hbm)
      (set! current-bitmap bm))))


;;;
;;;; Setup
;;;


(define (setup)
  (SetupWindow (current-instance) current-bitmap)
  #;
  (let ((repo (git-repository-init "zoo" 0)))
    (let ((remote (git-remote-create repo "origin" "git://github.com/jazzscheme/test.git")))
      (git-remote-connect remote GIT_DIRECTION_FETCH)
      (git-remote-download remote
        (lambda (total_objects indexed_objects received_objects stats->received_bytes)
          #f #;(display ".")))
      (git-remote-disconnect remote)
      (git-remote-update-tips remote)
      (git-remote-free remote)
      (let ((upstream (git-reference-lookup repo "refs/remotes/origin/master")))
        (let ((commit (git-object-lookup repo (git-reference->id repo upstream) GIT_OBJ_COMMIT)))
          (git-reset repo commit GIT_RESET_HARD)
          (display "done"))))
    (git-repository-free repo)))


(prepare)
(setup)
