;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Devel
;;;


(define setup-source
  (getenv "MS"))


(define (load-source filename)
  (let ((src (string-append setup-source "/" filename ".scm")))
    (load src)))


(load "settings.scm")
(load-source "base")
(load-source "geometry")
(load-source "color")
(load-source "font")
(load-source "window")
(load-source "draw")
(load-source "view")
(load-source "work")

(set! devel-testing? #t)
(load-source "setup")
