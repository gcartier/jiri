;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Setup
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


(unit jiri.setup


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


(define setup-view
  (new-button (make-rect 50 450 390 490)
              (string-append "Install " jiri-title)
              (lambda (view)
                (setup))))


;;;
;;;; Setup
;;;


(define (setup)
  (when (setup-root)
    (continuation-capture
      (lambda (cancel)
        (validate-password cancel)
        (remove-view setup-view)
        (add-view percentage-view)
        (add-view downloaded-view)
        (add-view status-view)
        (add-view remaining-view)
        (add-view progress-view)
        (add-view play-view)
        (add-stage-view "Setup in progress" stage-setup-color)
        (setup-work)))))


;;;
;;;; Root
;;;


(define choosen-dir
  #f)


(define (setup-root)
  (define (choose-dir)
    (let ((dir (choose-directory (window-handle current-window) "Please select the installation folder" (or choosen-dir (get-special-folder CSIDL_PROGRAM_FILESX86)))))
      (unless (equal? dir "")
        (set! choosen-dir dir)
        (normalize-directory (pathname-standardize dir)))))
  
  (let ((dir (choose-dir)))
    (when dir
      (let ((root-dir (normalize-directory (string-append dir jiri-title))))
        (if (not (file-exists? root-dir))
            (begin
              (create-directory-with-acl root-dir)
              (set! current-root-dir root-dir)
              root-dir)
          (let ((code (if current-root-dir
                          'yes
                        (message-box (string-append "Installation folder already exists: " root-dir "\n\nDo you want to replace?") type: 'confirmation))))
            (when (eq? code 'yes)
              (set-default-cursor IDC_WAIT)
              (set! work-in-progress? #t)
              ;; danger
              (let ((code (remove-directory root-dir)))
                (if (= code 0)
                    (begin
                      (create-directory-with-acl root-dir)
                      (set! current-root-dir root-dir)
                      root-dir)
                  (begin
                    (set-default-cursor IDC_ARROW)
                    (set! work-in-progress? #f)
                    (message-box (string-append "Unable to delete folder (0x" (number->string code 16) ")"))
                    #f))))))))))


;;;
;;;; Password
;;;


(define (validate-password cancel)
  (or closed-beta-password
      (let ((repo #f)
            (remote #f)
            (successful? #f)
            (dir (install-dir)))
        (dynamic-wind
          (lambda ()
            (set! repo (git-repository-init dir 0))
            (set! remote (git-remote-create repo "origin" jiri-install-remote)))
          (lambda ()
            (git-remote-connect-with-retries remote cancel))
          (lambda ()
            (when remote
              (when successful?
                (git-remote-disconnect remote))
              (git-remote-free remote))
            (when repo
              (git-repository-free repo)))))))


;;;
;;;; Work
;;;


(define (setup-work)
  (pull-repository "launch" jiri-install-remote jiri-install-branch closed-beta-password (install-dir) 1 6 0. .05 .1
    (lambda (new-content?)
      (setup-done))))


;;;
;;;; Done
;;;


(define (setup-done)
  (set-label-title stage-view "Setup successful!")
  (set-label-color stage-view stage-install-color)
  (set-default-cursor IDC_ARROW)
  (set! work-in-progress? #f)
  (set! work-done? #t)
  (delegate-install current-root-dir closed-beta-password "setup"))


;;;
;;;; Layout
;;;


(define (layout)
  (add-view root-view)
  (add-view invite-view)
  (add-view close-view)
  (add-view minimize-view)
  (add-view setup-view)
  (set-return-press
    (lambda ()
      (unless work-done?
        (setup))))
  (set-quit (quit-confirm-abort "Setup")))


;;;
;;;; Main
;;;


(main))
