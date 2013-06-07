;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Window
;;;


(define-type window
  draw
  key-down
  mouse-down)


(define current-window
  #f)

(define (set-current-window window)
  (set! current-window window))
