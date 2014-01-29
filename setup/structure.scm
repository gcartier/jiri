;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Structure
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
;;;; Structure
;;;


(define current-root-dir
  #f)

(define closed-beta-password
  #f)

(define called-from
  #f)


(define (app-dir)
  (string-append current-root-dir (normalize-directory jiri-app-dir)))

(define (install-dir)
  (string-append current-root-dir (normalize-directory jiri-install-dir)))

(define (current-dir)
  (string-append current-root-dir (normalize-directory jiri-current-dir)))

(define (world-dir)
  (string-append current-root-dir (normalize-directory jiri-world-dir)))

(define (root-exe)
  (add-extension (string-append current-root-dir jiri-application) executable-extension))

(define (app-exe)
  (add-extension (string-append (app-dir) jiri-application) executable-extension))

(define (current-exe)
  (add-extension (string-append (current-dir) "Install") executable-extension))

(define (uninstall-exe)
  (add-extension (string-append (current-dir) "Uninstall") executable-extension))

(define (install-exe)
  (add-extension (string-append (install-dir) "Install") executable-extension))

(define (launcher-exe)
  (add-extension (string-append (install-dir) "Launcher") executable-extension))


;;;
;;;; Delegate
;;;


(define (delegate-current root-dir closed-beta-password called-from)
  (setenv "root-dir" root-dir)
  (setenv "closed-beta-password" (or closed-beta-password ""))
  (setenv "called-from" called-from)
  (delegate-process (current-exe))
  (exit))


(define (delegate-install root-dir closed-beta-password called-from)
  (setenv "root-dir" root-dir)
  (setenv "closed-beta-password" (or closed-beta-password ""))
  (setenv "called-from" called-from)
  (setenv "work-percentage" (number->string work-percentage))
  (setenv "work-downloaded" (number->string work-downloaded))
  (let ((pos (get-window-position current-window)))
    (setenv "window-h" (number->string (point-h pos)))
    (setenv "window-v" (number->string (point-v pos))))
  (delegate-process (install-exe))
  ;; wait for install window to cover our own window
  (thread-sleep! .5)
  (exit))
