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
  update-cursor
  mouse-move
  mouse-down
  mouse-up)


(define current-window
  #f)

(define (set-current-window window)
  (set! current-window window))
