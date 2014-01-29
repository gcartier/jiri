;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Draw
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


(include "syntax.scm")


;;;
;;;; Gradient
;;;


(define (DrawGradient hdc left top right bottom from to direction)
  (when (or (and (eq? direction 'vertical) (> bottom top))
            (and (eq? direction 'horizontal) (> right left)))
    (let ((fStep (case direction
                   ((vertical) (/ (- bottom top 1) 256.))
                   ((horizontal) (/ (- right left 1) 256.))))
          (rStep (/ (- (GetRValue to) (GetRValue from)) 256.))
          (gStep (/ (- (GetGValue to) (GetGValue from)) 256.))
          (bStep (/ (- (GetBValue to) (GetBValue from)) 256.)))
      (let loop ((i 0))
           (let ((rectFill (case direction
                             ((vertical)
                              (make-RECT left
                                         (+ top (fxround (* i fStep)))
                                         right
                                         (+ top (fxround (* (+ i 1) fStep)))))
                             ((horizontal)
                              (make-RECT (+ left (fxround (* i fStep)))
                                         top
                                         (+ left (fxround (* (+ i 1) fStep)))
                                         bottom)))))
             (let ((r (+ (GetRValue from) (fxround (* i rStep))))
                   (g (+ (GetGValue from) (fxround (* i gStep))))
                   (b (+ (GetBValue from) (fxround (* i bStep)))))
               (let ((brush (CreateSolidBrush (RGB r g b))))
                 (FillRect hdc rectFill brush)
                 (RECT-free rectFill)
                 (DeleteObject brush))))
           (when (< i 256)
             (loop (+ i 1)))))))
