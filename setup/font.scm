;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Font
;;;


(define (make-font name size #!key (bold? #f))
  (CreateFont
    size 0 0 0 (if bold? FW_BOLD FW_DONTCARE) FALSE FALSE FALSE
    DEFAULT_CHARSET OUT_DEFAULT_PRECIS CLIP_DEFAULT_PRECIS
    ANTIALIASED_QUALITY FF_DONTCARE name))


(define default-title-font
  (make-font "Tahoma" 72))

(define default-label-font
  (make-font "Tahoma" 12))

(define default-button-font
  (make-font "Tahoma" 24))
