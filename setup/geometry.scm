;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Geometry
;;;


(define-type point
  h
  v)


(define-type rect
  left
  top
  right
  bottom)


(define (rect->RECT rect)
  (make-RECT (rect-left rect)
             (rect-top rect)
             (rect-right rect)
             (rect-bottom rect)))


(define (in-rect? pt rect)
  (and (>= (point-h pt) (rect-left rect))
       (>= (point-v pt) (rect-top rect))
       (<  (point-h pt) (rect-right rect))
       (<  (point-v pt) (rect-bottom rect))))
