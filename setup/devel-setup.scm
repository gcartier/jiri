;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Devel Setup
;;;


(define setup-install
  (getenv "SETUPINSTALL"))

(define setup-source
  (getenv "SETUPSOURCE"))


(define (load-install filename)
  (let ((file (string-append setup-install "/" filename ".scm")))
    (load file)))

(define (load-source filename)
  (let ((file (string-append setup-source "/" filename ".scm")))
    (load file)))


;; reload settings
(load-install "settings")
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
