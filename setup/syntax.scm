;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Syntax
;;;


(define-macro (when test . body)
  `(if ,test
       (begin
         ,@body)
     #f))


(define-macro (unless test . body)
  `(if (not ,test)
       (begin
         ,@body)
     #f))
