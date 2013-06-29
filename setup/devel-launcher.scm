;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Devel Launcher
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
(load-source "structure")
(load-source "launcher")
