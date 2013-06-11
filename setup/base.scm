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


(define (fxfloor/ n d)
  (fxfloor (/ n d)))


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
;;;; File
;;;


(define (file-readonly? file)
  (mask-bit-set? (GetFileAttributes file) FILE_ATTRIBUTE_READONLY))


(define (set-file-readonly? file flag)
  (SetFileAttributes file (mask-bit-set (GetFileAttributes file) FILE_ATTRIBUTE_READONLY flag)))


;;;
;;;; Directory
;;;


(define (empty/delete-directory directory #!key (overwrite-readonly? #f))
  (define (empty/delete dir)
    (empty-directory dir)
    (delete-directory dir))
  
  (define (empty-directory dir)
    (for-each (lambda (name)
                (let ((filename (string-append dir name)))
                  (case (file-type filename)
                    ((regular)
                     (when (and overwrite-readonly? (file-readonly? filename))
                       (set-file-readonly? filename #f))
                     (delete-file filename))
                    ((directory)
                     (empty/delete (string-append filename "/"))))))
              (directory-files (list path: dir ignore-hidden: 'dot-and-dot-dot))))
  
  (empty/delete directory)
  (wait-deleted-windows-workaround directory))


(define (wait-deleted-windows-workaround directory)
  (let ((max-tries 10))
    (let loop ((n 0))
         (when (file-exists? directory)
           (when (< n max-tries)
             (thread-sleep! .1)
             (loop (+ n 1))))))
  (thread-sleep! .1))


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
  (define (debug-exception exc)
    (call-with-output-file (list path: "exception.txt" eol-encoding: eol-encoding)
      (lambda (output)
        (display-exception exc output)
        (continuation-capture
          (lambda (cont)
            (display-continuation-backtrace cont output #t #t 1000 1000))))))
  
  (system-message "An unexpected problem occurred")
  (debug-exception exc)
  (exit 1))


(define (with-jiri-exception-handler thunk)
  (with-exception-handler
    jiri-exception-handler
    thunk))


(current-exception-handler jiri-exception-handler)
