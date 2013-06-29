;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Devel Setup
;;;


(define setup-source
  (getenv "SETUPSOURCE"))


(define (load-source filename)
  (let ((file (string-append setup-source "/" filename ".scm")))
    (load file)))


(load-source "base")
(load-source "geometry")
(load-source "color")
(load-source "font")
(load-source "window")
(load-source "draw")
(load-source "view")
(load-source "structure")
(load-source "git-interface")
(load-source "work")
(load-source "setup")
