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
  mouse-down)


(define views
  '())


(define (add-view view)
  (set! views (cons view views))
  (invalidate-view view))


(define (remove-view view)
  (set! views (remove! view views))
  (invalidate-view view))


(define (invalidate-view view)
  (InvalidateRect (window-handle current-window) (rect->RECT (view-rect view)) #t))


(define (redraw-view view)
  (RedrawWindow (window-handle current-window) (rect->RECT (view-rect view)) NULL (bitwise-ior RDW_ERASENOW RDW_UPDATENOW RDW_INVALIDATE)))


(define (draw-views hdc)
  (for-each (lambda (view)
              (let ((draw (view-draw view)))
                (if draw
                    (draw view hdc))))
            views))


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
      (DrawText hdc title -1 (rect->RECT rect) (bitwise-ior DT_CENTER DT_NOCLIP)))))


(define (new-label rect title)
  (make-label rect label-draw #f title))


;;;
;;;; Button
;;;


(define-type-of-view button
  title
  action)


(define (button-draw view hdc)
  (SetBkMode hdc TRANSPARENT)
  (SetTextColor hdc white-color)
  (let ((font button-font))
    (SelectObject hdc font)
    (let ((rect (view-rect view)))
      (let ((left (rect-left rect))
            (top (rect-top rect))
            (right (rect-right rect))
            (bottom (rect-bottom rect)))
        (DrawGradient hdc left top right bottom (RGB 150 0 0) (RGB 220 0 0) #f)
        (let ((textRect (make-rect left (+ top 7) right (+ bottom 7)))
              (title (button-title view)))
          (DrawText hdc title -1 (rect->RECT textRect) (bitwise-ior DT_CENTER DT_NOCLIP)))))))


(define (button-mouse-down view x y)
  (let ((action (button-action view)))
    (with-handle-exception
      (lambda ()
        (action view)))))


(define (new-button rect title action)
  (make-button rect button-draw button-mouse-down title action))


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
          (let ((right (* (/ (rect-width rect) (fixnum->flonum (- end start))) (+ (- pos start) 1))))
            (DrawGradient hdc left top right bottom (RGB 150 0 0) (RGB 220 0 0) #f)))))))


(define (progress-mouse-down view x y)
  #f)


(define (set-progress-pos view pos)
  (progress-pos-set! view pos)
  (invalidate-view view))


(define (new-progress rect)
  (make-progress rect
                 progress-draw
                 progress-mouse-down
                 0
                 (make-range 0 10)))
