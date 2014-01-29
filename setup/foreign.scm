;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Foreign Syntax
;;;
;;;  The contents of this file are subject to the Mozilla Public License Version
;;;  1.1 (the "License"); you may not use this file except in compliance with
;;;  the License. You may obtain a copy of the License at
;;;  http://www.mozilla.org/MPL/
;;;
;;;  Software distributed under the License is distributed on an "AS IS" basis,
;;;  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
;;;  for the specific language governing rights and limitations under the
;;;  License.
;;;
;;;  The Original Code is JazzScheme.
;;;
;;;  The Initial Developer of the Original Code is Guillaume Cartier.
;;;  Portions created by the Initial Developer are Copyright (C) 1996-2014
;;;  the Initial Developer. All Rights Reserved.
;;;
;;;  Contributor(s):
;;;
;;;  Alternatively, the contents of this file may be used under the terms of
;;;  the GNU General Public License Version 2 or later (the "GPL"), in which
;;;  case the provisions of the GPL are applicable instead of those above. If
;;;  you wish to allow use of your version of this file only under the terms of
;;;  the GPL, and not to allow others to use your version of this file under the
;;;  terms of the MPL, indicate your decision by deleting the provisions above
;;;  and replace them with the notice and other provisions required by the GPL.
;;;  If you do not delete the provisions above, a recipient may use your version
;;;  of this file under the terms of any one of the MPL or the GPL.
;;;
;;;  See www.jazzscheme.org for details.


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
                                   "if (result != 0)\n"
                                   "    ___result = ___FIX(result);\n"
                                   "else\n"
                                   "    ___result = ___FAL;")))
              `(define ,s-name
                 (git-validate
                   (c-lambda ,params scheme-object ,c-code))))
          `(define ,s-name
             (c-lambda ,params ,type ,c-name-or-code)))
      (let ((out-type (cadr (car params)))
            (parameters (cdr params)))
        (let ((c-code
                (string-append (symbol->string out-type) " out;\n"
                               "int result = " c-name-or-code "(&out" (expand-args (length parameters) #t) ");\n"
                               "if (result == 0)\n"
                               "{\n"
                               "    ___SCMOBJ foreign;\n"
                               "    ___EXT(___POINTER_to_SCMOBJ)(out, ___FAL, NULL, &foreign, ___RETURN_POS);\n"
                               "    ___result = foreign;\n"
                               "}\n"
                               (if (eq? type ':lookup)
                                   "else if (result == GIT_ENOTFOUND) ___result = ___FAL;\n"
                                 "")
                               "else ___result = ___FIX(result);")))
          `(define ,s-name
             (git-validate
               (c-lambda ,parameters scheme-object ,c-code))))))))


#; ;; wait for Marc to fix issue #37
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
