;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Base Code
;;;


(include "syntax.scm")


;;;
;;;; Boolean
;;;


(define (not-null? expr)
  (not (null? expr)))


(define (neq? x y)
  (not (eq? x y)))


(define (/= x y)
  (not (= x y)))


(define (mask-bit-set? num msk)
  (/= (bitwise-and num msk) 0))


(define (mask-bit-set num msk bit)
  (if bit
      (bitwise-ior num msk)
    (bitwise-and num (bitwise-not msk))))


;;;
;;;; Number
;;;


(define (fxround r)
  (if (fixnum? r)
      r
    (inexact->exact (round r))))


(define (fxfloor r)
  (if (fixnum? r)
      r
    (inexact->exact (floor r))))


(define (fxceiling r)
  (if (fixnum? r)
      r
    (inexact->exact (ceiling r))))


(define (percentage part total)
  (* (/ (exact->inexact part) (exact->inexact total)) 100))


;;;
;;;; List
;;;


(define (remove! target lst)
  (let loop ()
    (when (and (not-null? lst) (eqv? target (car lst)))
      (set! lst (cdr lst))
      (loop)))
  (if (null? lst)
      '()
    (begin
      (let ((previous lst)
            (scan (cdr lst)))
        (let loop ()
          (when (not-null? scan)
            (if (eqv? target (car scan))
                (begin
                  (set! scan (cdr scan))
                  (set-cdr! previous scan))
              (begin
                (set! previous scan)
                (set! scan (cdr scan))))
            (loop))))
      lst)))


(define (collect-if predicate lst)
  (let iter ((scan lst))
    (if (not-null? scan)
        (let ((value (car scan)))
          (if (predicate value)
              (cons value (iter (cdr scan)))
            (iter (cdr scan))))
      '())))


;;;
;;;; String
;;;


(define (string-ends-with? str target)
  (let ((sl (string-length str))
        (tl (string-length target)))
    (and (>= sl tl)
         (string=? (substring str (- sl tl) sl) target))))


(define (string-find-reversed str c)
  (let iter ((n (- (string-length str) 1)))
    (cond ((< n 0)
           #f)
          ((char=? (string-ref str n) c)
           n)
          (else
           (iter (- n 1))))))


(define (string-replace str old new)
  (let ((cpy (string-copy str)))
    (let iter ((n (- (string-length cpy) 1)))
      (if (>= n 0)
          (begin
            (if (eqv? (string-ref cpy n) old)
                (string-set! cpy n new))
            (iter (- n 1)))))
    cpy))


;;;
;;;; Environment
;;;


(define (getenv-default name #!optional (default #f))
  (with-exception-catcher
    (lambda (exc)
      (if (unbound-os-environment-variable-exception? exc)
          default
        (raise exc)))
    (lambda ()
      (getenv name))))


;;;
;;;; Pathname
;;;


(define (pathname-standardize path)
  (string-replace path #\\ #\/))


(define (pathname-dir pathname)
  (let ((pos (string-find-reversed pathname #\/)))
    (if (not pos)
        #f
      (substring pathname 0 (+ pos 1)))))


(define (add-extension filename extension)
  (if (not extension)
      filename
    (string-append filename "." extension)))


;;;
;;;; File
;;;


(define (file-readonly? file)
  (mask-bit-set? (GetFileAttributes file) FILE_ATTRIBUTE_READONLY))


(define (set-file-readonly? file flag)
  (SetFileAttributes file (mask-bit-set (GetFileAttributes file) FILE_ATTRIBUTE_READONLY flag)))


;;;
;;;; Directory
;;;


(define (normalize-directory directory)
  (if (string-ends-with? directory "/")
      directory
    (string-append directory "/")))


(define (executable-directory)
  (pathname-dir (pathname-standardize (executable-path))))


;;;
;;;; Debug
;;;


(define (debug n)
  (system-message (->string n)))


(define (->string expr)
  (if (string? expr)
      expr
    (let ((output (open-output-string)))
      (display expr output)
      (get-output-string output))))


;;;
;;;; Exception
;;;


(define (jiri-exception-handler exc)
  (call-with-bug-report
    (lambda (output)
      (display-exception exc output)
      (newline output)
      (continuation-capture
        (lambda (cont)
          (display-continuation-backtrace cont output #t #t 1000 1000)))))
  (exit 1))


(define (with-jiri-exception-handler thunk)
  (with-exception-handler
    jiri-exception-handler
    thunk))


(current-exception-handler jiri-exception-handler)
