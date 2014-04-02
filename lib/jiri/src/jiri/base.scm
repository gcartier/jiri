;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Base Code
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


(unit jiri.base


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


(define (->string expr)
  (if (string? expr)
      expr
    (let ((output (open-output-string)))
      (display expr output)
      (get-output-string output))))


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
  (string-replace path pathname-separator #\/))


(define (pathname-platformize path)
  (string-replace path #\/ pathname-separator))


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


(define (get-temporary-file prefix extension)
  (let ((temporary-dir (get-temporary-dir)))
    (let loop ((n #f))
      (let ((suffix (if n (string-append " " (number->string n)) "")))
        (let ((file (add-extension (string-append temporary-dir prefix suffix) extension)))
          (if (not (file-exists? file))
              file
            (loop (+ (or n 0) 1))))))))


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
;;;; Process
;;;


(define (command-arguments)
  (cdr (command-line)))


(define (delegate-process path #!key (arguments '()))
  (open-process (list
                  path: path
                  arguments: arguments
                  stdin-redirection: #f
                  stdout-redirection: #f
                  stderr-redirection: #f
                  show-console: #f)))


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


(current-exception-handler jiri-exception-handler))
