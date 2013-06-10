;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Window
;;;


(define-type window
  handle
  draw
  key-down
  mouse-move
  mouse-down
  mouse-up)


(define current-window
  #f)

(define (set-current-window window)
  (set! current-window window))
