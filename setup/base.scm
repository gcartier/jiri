;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Base Code
;;;


;;;
;;;; Boolean
;;;


(define (not-null? expr)
  (not (null? expr)))


;;;
;;;; List
;;;


(define (remove! target lst)
  (let loop ()
    (if (and (not-null? lst) (eqv? target (car lst)))
        (begin
          (set! lst (cdr lst))
          (loop))))
  (if (null? lst)
      '()
    (begin
      (let ((previous lst)
            (scan (cdr lst)))
        (let loop ()
          (if (not-null? scan)
              (begin
                (if (eqv? target (car scan))
                    (begin
                      (set! scan (cdr scan))
                      (set-cdr! previous scan))
                  (begin
                    (set! previous scan)
                    (set! scan (cdr scan))))
                (loop)))))
      lst)))


;;;
;;;; Debug
;;;


(define (debug n)
  (system-message (number->string n)))


;;;
;;;; Exception
;;;


(define (with-handle-exception thunk)
  (define (debug-exception exc console)
    (call-with-output-file (list path: "exception.txt" eol-encoding: eol-encoding)
      (lambda (output)
        (display-exception exc output)
        (continuation-capture
          (lambda (cont)
            (display-continuation-backtrace cont output #t #t 1000 1000))))))
  
  (with-exception-handler
    (lambda (exc)
      (system-message "An unexpected problem occurred")
      (debug-exception exc console)
      (exit 1))
    thunk))
