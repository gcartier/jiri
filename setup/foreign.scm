;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Foreign Syntax
;;;


(define-macro (c-constant name value)
  `(define ,name ,value))


(define-macro (c-enumerant name)
  `(define ,name
     (let ()
       (declare (extended-bindings))
       (##c-code ,(string-append "___RESULT = ___U32BOX("
                                 (symbol->string name)
                                 ");")))))


(define-macro (c-type . rest)
  `(c-define-type ,@rest))


(define-macro (c-structure name . clauses)
  (define (parse-structure-name name proc)
    (if (symbol? name)
        (proc name (symbol->string name) '())
      (proc (car name) (cadr name) (cddr name))))
  
  (define (build-pointer-symbol type)
    (string->symbol (string-append (symbol->string type) "*")))
  
  (define (build-method-symbol struct . rest)
    (string->symbol (apply string-append (symbol->string struct) "-" (map symbol->string rest))))
  
  (parse-structure-name name
    (lambda (struct c-struct-string tag-rest)
      (let ((struct* (build-pointer-symbol struct))
            (sizeof (string-append "sizeof(" c-struct-string ")"))
            (tag*-rest (if (null? tag-rest) '() (cons (build-pointer-symbol (car tag-rest)) (cdr tag-rest)))))
        `(begin
           (c-type ,struct (type ,c-struct-string ,@tag-rest))
           (c-type ,struct* (pointer ,struct ,@tag*-rest))
           (define ,(build-method-symbol struct 'make)
             (c-lambda () ,struct* ,(string-append "___result_voidstar = calloc(1," sizeof ");")))
           (define ,(build-method-symbol struct 'free)
             (c-lambda (,struct*) void "free(___arg1);"))
           (define ,(build-method-symbol struct 'sizeof)
             (c-lambda () unsigned-int ,(string-append "___result = " sizeof ";"))))))))


(define-macro (c-external signature type . rest)
  (let* ((s-name (car signature))
         (params (cdr signature))
         (c-name-or-code (if (null? rest) (symbol->string s-name) (car rest))))
    `(define ,s-name
       (c-lambda ,params ,type ,c-name-or-code))))


;;;
;;;; Git
;;;


(define-macro (git-external signature type . rest)
  (define (out-parameter? obj)
    (and (pair? obj)
         (eq? (car obj) 'out)))
  
  (define (expand-args count initial-comma?)
    (let ((out ""))
      (let loop ((n 1))
        (if (<= n count)
            (begin
              (set! out (string-append out (if (or initial-comma? (not (= n 1))) ", " "") (string-append "___arg" (number->string n))))
              (loop (+ n 1)))))
      out))
  
  (let* ((s-name (car signature))
         (params (cdr signature))
         (c-name-or-code (if (null? rest) (symbol->string s-name) (car rest))))
    (if (or (null? params)
            (not (out-parameter? (car params))))
        (if (eq? type ':error)
            (let ((c-code
                    (string-append "int result = " c-name-or-code "(" (expand-args (length params) #f) ");\n"
                                   "if (result != 0) git_raise_error(result);\n")))
              `(define ,s-name
                 (c-lambda ,params void ,c-code)))
          `(define ,s-name
             (c-lambda ,params ,type ,c-name-or-code)))
      (let ((out-type (cadr (car params)))
            (parameters (cdr params)))
        (let ((c-code
                (string-append (symbol->string out-type) " out;\n"
                               "int result = " c-name-or-code "(&out" (expand-args (length parameters) #t) ");\n"
                               "if (result == 0) ___result_voidstar = out;\n"
                               (if (eq? type ':lookup)
                                   "else if (result == GIT_ENOTFOUND) ___result_voidstar = NULL;\n"
                                 "")
                               "else git_raise_error(result);")))
          `(define ,s-name
             (c-lambda ,parameters ,out-type ,c-code)))))))
