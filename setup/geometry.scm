;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Geometry
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


;;;
;;;; Point
;;;


(define-type point
  h
  v)


(define (point+ p1 p2)
  (make-point
    (+ (point-h p1) (point-h p2))
    (+ (point-v p1) (point-v p2))))


(define (point- p1 p2)
  (make-point
    (- (point-h p1) (point-h p2))
    (- (point-v p1) (point-v p2))))


;;;
;;;; Rect
;;;


(define-type rect
  left
  top
  right
  bottom)


(define (rect->RECT rect)
  (make-RECT (rect-left rect)
             (rect-top rect)
             (rect-right rect)
             (rect-bottom rect)))


(define (rect-width rect)
  (- (rect-right rect) (rect-left rect)))


(define (in-rect? pt rect)
  (and (>= (point-h pt) (rect-left rect))
       (>= (point-v pt) (rect-top rect))
       (<  (point-h pt) (rect-right rect))
       (<  (point-v pt) (rect-bottom rect))))


;;;
;;;; Range
;;;


(define-type range
  start
  end)
