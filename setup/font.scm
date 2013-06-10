;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Font
;;;


(define (make-font name size)
  (CreateFont
    size 0 0 0 FW_DONTCARE FALSE FALSE FALSE
    DEFAULT_CHARSET OUT_DEFAULT_PRECIS CLIP_DEFAULT_PRECIS
    ANTIALIASED_QUALITY FF_DONTCARE name))


(define label-font
  (make-font "Tahoma" 72))

(define button-font
  (make-font "Tahoma" 24))
