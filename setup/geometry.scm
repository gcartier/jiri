;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Geometry
;;;


;;;
;;;; Point
;;;


(define-type point
  h
  v)


(define (point+ p1 p2)
  (make-point
    (+ (point-h p1) (point-h p2))
    (+ (point-v p1) (point-v p2))))


(define (point- p1 p2)
  (make-point
    (- (point-h p1) (point-h p2))
    (- (point-v p1) (point-v p2))))


;;;
;;;; Rect
;;;


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


(define (rect-width rect)
  (- (rect-right rect) (rect-left rect)))


(define (in-rect? pt rect)
  (and (>= (point-h pt) (rect-left rect))
       (>= (point-v pt) (rect-top rect))
       (<  (point-h pt) (rect-right rect))
       (<  (point-v pt) (rect-bottom rect))))


;;;
;;;; Range
;;;


(define-type range
  start
  end)
