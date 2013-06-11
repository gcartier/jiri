;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; View
;;;


(define-type view
  extender: define-type-of-view
  rect
  draw
  mouse-move
  mouse-down
  mouse-up
  active?)


(define debug-views?
  #f)


(define views
  '())


(define (add-view view)
  (set! views (cons view views))
  (invalidate-view view))


(define (remove-view view)
  (set! views (remove! view views))
  (invalidate-view view))


(define (update-window)
  (UpdateWindow (window-handle current-window)))


(define (update-view view)
  (update-window))


(define (redraw-view view)
  (RedrawWindow (window-handle current-window) (rect->RECT (view-rect view)) NULL (bitwise-ior RDW_ERASENOW RDW_UPDATENOW RDW_INVALIDATE)))


(define (invalidate-view view)
  (InvalidateRect (window-handle current-window) (rect->RECT (view-rect view)) #t))


(define (draw-views hdc)
  (for-each (lambda (view)
              (let ((draw (view-draw view)))
                (if draw
                    (draw view hdc))))
            views))


(define (set-view-active? view active?)
  (view-active?-set! view active?)
  (invalidate-view view)
  (update-view view))


;;;
;;;; Capture
;;;


(define captured-view
  #f)


(define (get-captured-view)
  captured-view)

(define (set-captured-view view)
  (set! captured-view view))


(define (release-captured-view)
  (if captured-view
      (begin
        (set! captured-view #f)
        (ReleaseCapture))))


;;;
;;;; Title
;;;


(define-type-of-view title
  title
  moving?
  cursor-pos
  window-pos
  window-size)


(define (title-draw view hdc)
  (SetBkMode hdc TRANSPARENT)
  (SetTextColor hdc white-color)
  (let ((font title-font))
    (SelectObject hdc font)
    (let ((rect (view-rect view))
          (title (title-title view)))
      (if debug-views?
          (let ((brush (CreateSolidBrush (RGB 100 100 100))))
            (FillRect hdc (rect->RECT rect) brush)
            (DeleteObject brush)))
      (DrawText hdc title -1 (rect->RECT rect) (bitwise-ior DT_CENTER DT_NOCLIP)))))


(define (title-mouse-move view x y)
  (set-cursor IDC_SIZEALL)
  (if (title-moving? view)
      (let ((current (cursor-position)))
        (let ((delta (point- current (title-cursor-pos view))))
          (let ((pos (point+ (title-window-pos view) delta))
                (size (title-window-size view)))
            (move-window current-window pos size))))))


(define (title-mouse-down view x y)
  (title-cursor-pos-set! view (cursor-position))
  (title-window-pos-set! view (get-window-position current-window))
  (title-window-size-set! view (get-window-size current-window))
  (title-moving?-set! view #t)
  (SetCapture (window-handle current-window))
  (set-captured-view view)
  (set! lose-capture-callback
        (lambda ()
          (title-moving?-set! view #f))))


(define (title-mouse-up view x y)
  (release-captured-view))


(define (new-title rect title)
  (make-title rect title-draw title-mouse-move title-mouse-down title-mouse-up #t title #f #f #f #f))


;;;
;;;; Label
;;;


(define-type-of-view label
  title)


(define (label-draw view hdc)
  (SetBkMode hdc TRANSPARENT)
  (SetTextColor hdc white-color)
  (let ((font label-font))
    (SelectObject hdc font)
    (let ((rect (view-rect view))
          (title (label-title view)))
      (DrawText hdc title -1 (rect->RECT rect) DT_NOCLIP))))


(define (new-label rect title)
  (make-label rect label-draw #f #f #f #t title))


;;;
;;;; Button
;;;


(define-type-of-view button
  extender: define-type-of-button
  title
  action)


(define (button-draw view hdc)
  (let ((active? (view-active? view)))
    (SetBkMode hdc TRANSPARENT)
    (SetTextColor hdc (if active? white-color (RGB 160 160 160)))
    (let ((font button-font))
      (SelectObject hdc font)
      (let ((rect (view-rect view)))
        (let ((left (rect-left rect))
              (top (rect-top rect))
              (right (rect-right rect))
              (bottom (rect-bottom rect)))
          (DrawGradient hdc left top right bottom (if active? (RGB 150 0 0) white-color) (if active? (RGB 220 0 0) white-color) #f)
          (let ((textRect (make-rect left (+ top 7) right (+ bottom 7)))
                (title (button-title view)))
            (DrawText hdc title -1 (rect->RECT textRect) (bitwise-ior DT_CENTER DT_NOCLIP))))))))


(define (button-mouse-down view x y)
  (let ((action (button-action view)))
    (action view)))


(define (new-button rect title action #!key (active? #t))
  (make-button rect button-draw #f button-mouse-down #f active? title action))


;;;
;;;; Close
;;;


(define-type-of-button close)


(define (close-draw view hdc)
  (let ((rect (view-rect view))
        (gray (CreatePen PS_SOLID 4 (RGB 150 150 150)))
        (white (CreatePen PS_SOLID 2 (RGB 255 255 255))))
    (let ((left (rect-left rect))
          (top (rect-top rect))
          (right (rect-right rect))
          (bottom (rect-bottom rect)))
      (define (draw-x pen)
        (SelectObject hdc pen)
        (MoveToEx hdc left top #f)
        (LineTo hdc right bottom)
        (MoveToEx hdc right top #f)
        (LineTo hdc left bottom))
      
      (draw-x gray)
      (draw-x white))
    (DeleteObject gray)
    (DeleteObject white)))


(define (close-action view)
  (quit))


(define (new-close rect)
  (make-close rect close-draw #f button-mouse-down #f #t #f close-action))


;;;
;;;; Close
;;;


(define-type-of-button minimize)


(define (minimize-draw view hdc)
  (let ((rect (view-rect view))
        (gray (CreatePen PS_SOLID 4 (RGB 150 150 150)))
        (white (CreatePen PS_SOLID 2 (RGB 255 255 255))))
    (let ((left (rect-left rect))
          (top (rect-top rect))
          (right (rect-right rect))
          (bottom (rect-bottom rect)))
      (define (draw-line pen)
        (SelectObject hdc pen)
        (MoveToEx hdc left bottom #f)
        (LineTo hdc right bottom))
      
      (draw-line gray)
      (draw-line white))
    (DeleteObject gray)
    (DeleteObject white)))


(define (minimize-action view)
  (ShowWindow (window-handle current-window) SW_MINIMIZE))


(define (new-minimize rect)
  (make-close rect minimize-draw #f button-mouse-down #f #t #f minimize-action))


;;;
;;;; Progress
;;;


(define-type-of-view progress
  pos
  range)


(define (progress-draw view hdc)
  (let ((rect (view-rect view)))
    (let ((left (rect-left rect))
          (top (rect-top rect))
          (right (rect-right rect))
          (bottom (rect-bottom rect)))
      (let ((brush (CreateSolidBrush white-color)))
        (FillRect hdc (rect->RECT rect) brush)
        (DeleteObject brush))
      (let ((pos (progress-pos view))
            (range (progress-range view)))
        (let ((start (range-start range))
              (end (range-end range)))
          (let ((h (* (/ (rect-width rect) (fixnum->flonum (- end start))) (- pos start))))
            (DrawGradient hdc left top (+ left h) bottom (RGB 150 0 0) (RGB 220 0 0) #f)))))))


(define (set-progress-pos view pos)
  (progress-pos-set! view pos)
  (invalidate-view view)
  (update-view view))

(define (set-progress-range view range)
  (progress-range-set! view range)
  (invalidate-view view)
  (update-view view))


(define (new-progress rect pos range)
  (make-progress rect
                 progress-draw
                 #f
                 #f
                 #f
                 #t
                 pos
                 range))
