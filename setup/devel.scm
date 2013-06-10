;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Devel
;;;


(define (load-source filename)
  (let ((src (string-append "../devel/setup/" filename ".scm")))
    (load src)))


(load-source "base")
(load-source "geometry")
(load-source "color")
(load-source "font")
(load-source "window")
(load-source "view")
(load-source "setup")
