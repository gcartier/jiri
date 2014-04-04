;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Uninstall
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


(unit jiri.uninstall


(require jiri.settings
         jiri.windows
         jiri.git
         jiri.git-interface
         jiri.base
         jiri.geometry
         jiri.color
         jiri.font
         jiri.window
         jiri.draw
         jiri.view
         jiri.structure
         jiri.work)


(include "syntax.scm")


;;;
;;;; View
;;;


(define uninstall-view
  (new-button (make-rect 50 450 390 490)
              (string-append "Uninstall " jiri-title)
              (lambda (view)
                (uninstall))))


;;;
;;;; Uninstall
;;;


(define (uninstall)
  (define (not-found)
    (message-box (string-append jiri-title " was not found on this computer.")
                 title: (string-append jiri-title " Uninstall")
                 type: 'problem))
  
  (let ((key (registry-open-key (HKEY_CURRENT_USER) (uninstall-subkey))))
    (if (not key)
        (not-found)
      (let ((install-dir (registry-query-string key "InstallLocation")))
        (registry-close-key key)
        (if (not install-dir)
            (not-found)
          (let ((code (message-box (string-append "Remove " jiri-title " and all of its components?")
                                   title: (string-append jiri-title " Uninstall")
                                   type: 'question)))
            (when (eq? code 'yes)
              (set-default-cursor IDC_WAIT)
              (uninstall-desktop-shortcut)
              (uninstall-start-menu)
              (uninstall-uninstall)
              (uninstall-install install-dir)
              (set-default-cursor IDC_ARROW)
              (message-box (string-append jiri-title " was successfully removed from your computer.")
                           title: (string-append jiri-title " Uninstall"))
              (seppuku-exit))))))))


(define (uninstall-desktop-shortcut)
  (let ((shortcut (desktop-shortcut)))
    (when (file-exists? shortcut)
      ;; danger
      (delete-file shortcut))))


(define (uninstall-start-menu)
  (let ((appdir (start-menu-appdir)))
    (when (file-exists? appdir)
      ;; danger
      (remove-directory appdir))))


(define (uninstall-uninstall)
  (registry-delete-key (HKEY_CURRENT_USER) (uninstall-subkey)))


(define (uninstall-install install-dir)
  (when (file-exists? install-dir)
    ;; danger
    (let ((code (remove-directory install-dir)))
      (when (/= code 0)
        (message-box (string-append "Unable to delete installation folder (0x" (number->string code 16) "): " install-dir))))))


(define (seppuku-exit)
  (define (generate-remover uninstall remove)
    (call-with-output-file (list path: remove eol-encoding: eol-encoding)
      (lambda (output)
        (display ":Repeat" output)
        (newline output)
        (display (string-append "del \"" uninstall "\"") output)
        (newline output)
        (display (string-append "if exist \"" uninstall "\" goto Repeat") output)
        (newline output)
        (display (string-append "del \"" remove "\"") output)
        (newline output)
        (force-output output))))
  
  (let ((uninstall (executable-path))
        (remove (get-temporary-file (string-append jiri-title " remove") "bat")))
    (generate-remover uninstall remove)
    (create-console-process (string-append "cmd /c \"" remove "\""))
    (exit)))


;;;
;;;; Layout
;;;


(define (layout)
  (add-view root-view)
  (add-view invite-view)
  (add-view close-view)
  (add-view minimize-view)
  (add-view uninstall-view)
  (set-return-press
    (lambda ()
      (uninstall)))
  (set-quit
    (lambda ()
      (seppuku-exit))))


;;;
;;;; Main
;;;


(main))
