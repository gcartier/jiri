;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Syntax
;;;


(define-macro (when test . body)
  `(if ,test
       (begin
         ,@body)))
