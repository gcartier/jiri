;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Devel
;;;


(define (load-source filename)
  (let ((src (string-append "../devel/setup/" filename ".scm")))
    (load src)))


(load "settings.scm")
(load-source "base")
(load-source "geometry")
(load-source "color")
(load-source "font")
(load-source "window")
(load-source "draw")
(load-source "view")
(load-source "setup")
