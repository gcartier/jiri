;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; View
;;;


(include "syntax.scm")


(define-type view
  extender: define-type-of-view
  rect
  draw
  update-cursor
  mouse-move
  mouse-enter
  mouse-leave
  mouse-down
  mouse-up
  active?)


(define views
  '())


(define (add-view view)
  (set! views (cons view views))
  (invalidate-view view))


(define (remove-view view)
  (set! views (remove! view views))
  (invalidate-view view))


(define (invalidate-view view)
  (let ((handle (window-handle current-window))
        (rect (rect->RECT (view-rect view))))
    (InvalidateRect handle rect #t)
    (RECT-free rect)))


(define (draw-views hdc)
  (for-each (lambda (view)
              (let ((draw (view-draw view)))
                (when draw
                  (draw view hdc))))
            views))


(define (set-view-active? view active?)
  (view-active?-set! view active?)
  (invalidate-view view))


(define (call-mouse-move view x y)
  (if (view-active? view)
      (begin
        (when (neq? view mouse-view)
          (let ((actual mouse-view))
            (set-mouse-view view)
            (when actual
              (let ((mouse-leave (view-mouse-leave actual)))
                (when mouse-leave
                  (mouse-leave actual x y))))
            (let ((mouse-enter (view-mouse-enter view)))
              (when mouse-enter
                (mouse-enter view x y)))))
        (let ((update-cursor (view-update-cursor view)))
          (if update-cursor
              (update-cursor view x y)
            (set-cursor default-cursor)))
        (let ((mouse-move (view-mouse-move view)))
          (if mouse-move
              (mouse-move view x y))))
    (set-cursor default-cursor)))


(define debug-views?
  #f)


(define (debug-background view hdc)
  (when debug-views?
    (let ((rect (rect->RECT (view-rect view)))
          (brush (CreateSolidBrush (RGB 100 100 100))))
      (FillRect hdc rect brush)
      (RECT-free rect)
      (DeleteObject brush))))


;;;
;;;; Mouse
;;;


(define mouse-view
  #f)


(define (get-mouse-view)
  mouse-view)

(define (set-mouse-view view)
  (set! mouse-view view))


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
  (when captured-view
    (set! captured-view #f)
    (ReleaseCapture)))


;;;
;;;; Root
;;;


(define-type-of-view root)


(define (root-update-cursor view x y)
  (set-cursor default-cursor))


(define (new-root rect)
  (make-root rect
             #f
             root-update-cursor
             #f
             #f
             #f
             #f
             #f
             #t))


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
  (debug-background view hdc)
  (SetBkMode hdc TRANSPARENT)
  (SetTextColor hdc white-color)
  (let ((font title-font))
    (SelectObject hdc font)
    (let ((rect (rect->RECT (view-rect view)))
          (title (title-title view)))
      (DrawText hdc title -1 rect (bitwise-ior DT_CENTER DT_NOCLIP))
      (RECT-free rect))))


(define (title-update-cursor view x y)
  (set-cursor IDC_SIZEALL))


(define (title-mouse-move view x y)
  (when (title-moving? view)
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
  (set-lose-capture-callback
    (lambda ()
      (title-moving?-set! view #f))))


(define (title-mouse-up view x y)
  (release-captured-view))


(define (new-title rect title)
  (make-title rect
              title-draw
              title-update-cursor
              title-mouse-move
              #f
              #f
              title-mouse-down
              title-mouse-up
              #t
              title
              #f
              #f
              #f
              #f))


;;;
;;;; Label
;;;


(define-type-of-view label
  title
  align)


(define (label-draw view hdc)
  (debug-background view hdc)
  (SetBkMode hdc TRANSPARENT)
  (SetTextColor hdc white-color)
  (let ((font label-font))
    (SelectObject hdc font)
    (let ((rect (rect->RECT (view-rect view)))
          (title (label-title view))
          (align (label-align view)))
      (DrawText hdc title -1 rect (bitwise-ior align DT_NOCLIP))
      (RECT-free rect))))


(define (set-label-title view title)
  (label-title-set! view title)
  (invalidate-view view))


(define (new-label rect title #!optional (align DT_LEFT))
  (make-label rect
              label-draw
              #f
              #f
              #f
              #f
              #f
              #f
              #t
              title
              align))


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
          (if (eq? view mouse-view)
              (let ((rect (rect->RECT rect))
                    (brush (CreateSolidBrush (RGB 230 0 0))))
                (FillRect hdc rect brush)
                (RECT-free rect)
                (DeleteObject brush))
            (DrawGradient hdc left top right bottom (if active? (RGB 150 0 0) white-color) (if active? (RGB 220 0 0) white-color) 'horizontal))
          (let ((textRect (rect->RECT (make-rect left (+ top 7) right (+ bottom 7))))
                (title (button-title view)))
            (DrawText hdc title -1 textRect (bitwise-ior DT_CENTER DT_NOCLIP))
            (RECT-free textRect)))))))


(define (button-update-cursor view x y)
  (set-cursor IDC_ARROW))


(define (button-mouse-enter view x y)
  (invalidate-view view))


(define (button-mouse-leave view x y)
  (invalidate-view view))


(define (button-mouse-down view x y)
  #f)


(define (button-mouse-up view x y)
  (let ((action (button-action view)))
    (action view)))


(define (set-button-title view title)
  (button-title-set! view title)
  (invalidate-view view))


(define (new-button rect title action #!key (active? #t))
  (make-button rect
               button-draw
               button-update-cursor
               #f
               button-mouse-enter
               button-mouse-leave
               button-mouse-down
               button-mouse-up
               active?
               title
               action))


;;;
;;;; Close
;;;


(define-type-of-button close)


(define (close-draw view hdc)
  (debug-background view hdc)
  (let ((rect (view-rect view))
        (gray (CreatePen PS_SOLID 4 (RGB 150 150 150)))
        (white (CreatePen PS_SOLID 2 (if (eq? view mouse-view) (RGB 200 0 0) (RGB 255 255 255)))))
    (let ((left (+ (rect-left rect) 2))
          (top (+ (rect-top rect) 2))
          (right (- (rect-right rect) 2))
          (bottom (- (rect-bottom rect) 2)))
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
  (make-close rect
              close-draw
              button-update-cursor
              #f
              button-mouse-enter
              button-mouse-leave
              button-mouse-down
              button-mouse-up
              #t
              #f
              close-action))


;;;
;;;; Minimize
;;;


(define-type-of-button minimize)


(define (minimize-draw view hdc)
  (debug-background view hdc)
  (let ((rect (view-rect view))
        (gray (CreatePen PS_SOLID 4 (RGB 150 150 150)))
        (white (CreatePen PS_SOLID 2 (if (eq? view mouse-view) (RGB 200 0 0) (RGB 255 255 255)))))
    (let ((left (+ (rect-left rect) 2))
          (top (+ (rect-top rect) 2))
          (right (- (rect-right rect) 2))
          (bottom (- (rect-bottom rect) 2)))
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
  (make-minimize rect
                 minimize-draw
                 button-update-cursor
                 #f
                 button-mouse-enter
                 button-mouse-leave
                 button-mouse-down
                 button-mouse-up
                 #t
                 #f
                 minimize-action))


;;;
;;;; Progress
;;;


(define-type-of-view progress
  bounds
  range
  pos)


(define (progress-draw view hdc)
  (let ((rect (view-rect view)))
    (let ((left (rect-left rect))
          (top (rect-top rect))
          (right (rect-right rect))
          (bottom (rect-bottom rect)))
      (let ((rect (rect->RECT rect))
            (brush (CreateSolidBrush white-color)))
        (FillRect hdc rect brush)
        (RECT-free rect)
        (DeleteObject brush))
      (let ((bounds (progress-bounds view))
            (range (progress-range view))
            (pos (progress-pos view)))
        (let ((start (range-start range))
              (end (range-end range))
              (width (rect-width rect)))
          (let ((head (if (not bounds) 0 (fxfloor (* (range-start bounds) width))))
                (tail (if (not bounds) width (fxceiling (* (range-end bounds) width))))
                (where (/ (fixnum->flonum (- pos start)) (fixnum->flonum (- end start)))))
            (let ((h (fxceiling (* (- tail head) where))))
              (DrawGradient hdc left top (+ left head h) bottom (RGB 150 0 0) (RGB 220 0 0) 'horizontal))))))))


(define (set-progress-info view bounds range)
  (progress-bounds-set! view bounds)
  (progress-range-set! view range)
  (progress-pos-set! view (range-start range))
  (invalidate-view view))


(define (set-progress-pos view pos)
  (progress-pos-set! view pos)
  (invalidate-view view))


(define (new-progress rect range pos)
  (make-progress rect
                 progress-draw
                 #f
                 #f
                 #f
                 #f
                 #f
                 #f
                 #t
                 #f
                 range
                 pos))
