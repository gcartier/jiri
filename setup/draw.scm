;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Draw
;;;


(include "syntax.scm")


;;;
;;;; Gradient
;;;


(define (DrawGradient hdc left top right bottom from to vertical?)
  (let ((fStep (if vertical?
                   (/ (- bottom top 1) 256.)
                 (/ (- right left 1) 256.)))
        (rStep (/ (- (GetRValue to) (GetRValue from)) 256.))
        (gStep (/ (- (GetGValue to) (GetGValue from)) 256.))
        (bStep (/ (- (GetBValue to) (GetBValue from)) 256.)))
    (let loop ((i 0))
      (let ((rectFill (if vertical?
                          (make-RECT left
                                     (+ top (fxround (* i fStep)))
                                     right
                                     (+ top (fxround (* (+ i 1) fStep))))
                        (make-RECT (+ left (fxround (* i fStep)))
                                   top
                                   (+ left (fxround (* (+ i 1) fStep)))
                                   bottom))))
        (let ((r (+ (GetRValue from) (fxround (* i rStep))))
              (g (+ (GetGValue from) (fxround (* i gStep))))
              (b (+ (GetBValue from) (fxround (* i bStep)))))
          (let ((brush (CreateSolidBrush (RGB r g b))))
            (FillRect hdc rectFill brush)
            (RECT-free rectFill)
            (DeleteObject brush))))
      (when (< i 256)
        (loop (+ i 1))))))
