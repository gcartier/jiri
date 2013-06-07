;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; View
;;;


(define-type view
  rect
  draw
  mouse-down)


(define views
  '())

(define (add-view view)
  (set! views (cons view views)))


(define (draw-views hdc)
  (for-each (lambda (view)
              (let ((draw (view-draw view)))
                (if draw
                    (draw view hdc))))
            views))
