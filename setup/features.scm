;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Features
;;;


(define-macro (install-features)
  (let ((features '(windows)))
    (for-each (lambda (feature)
                (if feature
                    (set! ##cond-expand-features (append ##cond-expand-features (list feature)))))
              features)
    `(for-each (lambda (feature)
                 (if feature
                     (set! ##cond-expand-features (append ##cond-expand-features (list feature)))))
               ',features)))


(install-features)
