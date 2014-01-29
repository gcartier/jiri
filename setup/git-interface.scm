;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Git Interface
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
;;;; Pull
;;;


(define (pull-repository title url branch password dir step of head mid tail cont)
  (set-default-cursor IDC_WAIT)
  (set! work-in-progress? #t)
  (set-label-title status-view (downloading-title title step of))
  (let ((existing? (file-exists? dir)))
    (let ((repo (if existing?
                    (git-repository-open dir)
                  (git-repository-init dir 0))))
      (let ((remote (if existing?
                        (git-remote-load repo "origin")
                      (let ((remote (git-remote-create repo "origin" url)))
                        (git-remote-clear-refspecs remote)
                        (git-remote-add-fetch remote (string-append "+refs/heads/" branch ":refs/remotes/origin/" branch))
                        (git-remote-save remote)
                        remote)))
            (megabytes 0))
        (git-remote-connect-with-retries remote #f)
        (set-download-progress
          (let ((inited? #f))
            (lambda (lparam)
              (let ((total-objects (git-remote-download-total-objects))
                    (received-objects (git-remote-download-received-objects))
                    (received-bytes (git-remote-download-received-bytes)))
                (let ((percentage (* (percentage received-objects total-objects) (- mid head)))
                      (downloaded (fxfloor (/ (exact->inexact received-bytes) (* 1024. 1024.))))
                      (remaining (- total-objects received-objects)))
                  (let ((effective-percentage (fxround (+ work-percentage percentage))))
                    (set-label-title percentage-view (string-append (number->string effective-percentage) "%"))
                    (set-label-title downloaded-view (string-append "Downloaded: " (number->string (+ work-downloaded downloaded)) "M"))
                    (set-label-title remaining-view (string-append "Remaining: " (number->string remaining)))
                    (set! megabytes downloaded)))
                (when (not inited?)
                  (set-progress-info progress-view (make-range head mid) (make-range 0 total-objects))
                  (set! inited? #t))
                (set-progress-pos progress-view received-objects)))))
        (set-download-done
          (lambda (lparam)
            (safe-quit-point)
            (git-check-error lparam)
            (set! work-percentage (* mid 100.))
            (set! work-downloaded (+ work-downloaded megabytes))
            (set-label-title status-view (installing-title title step of))
            (set-progress-info progress-view (make-range head mid) (make-range 0 10))
            (set-progress-pos progress-view 10)
            (git-remote-disconnect remote)
            (git-remote-update-tips remote)
            (git-remote-free remote)
            (git-repository-set-head repo (string-append "refs/heads/" branch))
            (let ((upstream (git-reference-lookup repo (string-append "refs/remotes/origin/" branch))))
              (let ((commit (git-object-lookup repo (git-reference->id repo upstream) GIT_OBJ_COMMIT)))
                (git-branch-create repo branch commit 1)
                (let ((new-content? #f))
                  (set-checkout-progress
                    (let ((inited? #f))
                      (lambda (lparam)
                        ;; from a discusion on freenode, aborting a checkout could leave the worktree in an arbitrary
                        ;; state, but the next checkout force should overwrite whatever is present in the worktree...
                        (safe-quit-point)
                        (let ((path (git-checkout-path))
                              (completed-steps (git-checkout-completed-steps))
                              (total-steps (git-checkout-total-steps)))
                          (when (> total-steps 0)
                            (set! new-content? #t)
                            (let ((percentage (* (percentage completed-steps total-steps) (- tail mid)))
                                  (remaining (- total-steps completed-steps)))
                              (let ((effective-percentage (fxround (+ work-percentage percentage))))
                                (set-label-title percentage-view (string-append (number->string effective-percentage) "%"))
                                (set-label-title remaining-view (string-append "Remaining: " (number->string remaining)))))
                            (when (not inited?)
                              (set-progress-info progress-view (make-range mid tail) (make-range 0 total-steps))
                              (set! inited? #t))
                            (set-progress-pos progress-view completed-steps))))))
                  (set-checkout-done
                    (lambda (lparam)
                      (safe-quit-point)
                      (git-check-error lparam)
                      (set! work-percentage (* tail 100.))
                      (set-progress-info progress-view (make-range mid tail) (make-range 0 10))
                      (set-progress-pos progress-view 10)
                      (git-reference-free upstream)
                      (git-object-free commit)
                      (git-repository-free repo)
                      (cont new-content?)))
                (git-checkout-head-force-threaded repo (window-handle current-window)))))))
        (git-remote-download-threaded remote (window-handle current-window))))))


(define (downloading-title title step of)
  (string-append "Downloading " title " (" (number->string step) "/" (number->string of) ")"))


(define (installing-title title step of)
  (string-append "Installing " title " (" (number->string (+ step 1)) "/" (number->string of) ")"))


;;;
;;;; Remote
;;;


(define (git-remote-connect-with-retries remote cancel)
  (let ((password #f))
    (define (ask-password)
      (set! password (or closed-beta-password (dialog-box (window-handle current-window))))
      (or password
          (cancel-connection)))
    
    (define (cancel-connection)
      (if cancel
          (begin
            (set-default-cursor IDC_ARROW)
            (set! work-in-progress? #f)
            (continuation-return cancel))
        (exit 1)))
    
    (git-remote-check-cert remote 0)
    (git-remote-set-cred-acquire-cb remote
                                    (lambda ()
                                      (git-cred-userpass-plaintext-new jiri-username (ask-password))))
    (let ((max-tries 3))
      (let loop ((try 1))
        (if (> try max-tries)
            (exit 1)
          (with-exception-catcher
            (lambda (exc)
              (if (error-exception? exc)
                  (let ((err (->string (car (error-exception-parameters exc)))))
                    (cond ((string-ends-with? err "401")
                           (message-box "Incorrect password")
                           (loop (+ try 1)))
                          (else
                           (message-box (string-append "Unable to connect to server:\n\n" err))
                           (cancel-connection))))
                (raise exc)))
            (lambda ()
              (git-remote-connect remote GIT_DIRECTION_FETCH)
              (set! closed-beta-password password))))))))


;;;
;;;; Callback
;;;


(set-user-callback
  (lambda (wparam lparam)
    (cond ((= wparam DOWNLOAD_PROGRESS) (download-progress lparam))
          ((= wparam DOWNLOAD_DONE)     (download-done     lparam))
          ((= wparam CHECKOUT_PROGRESS) (checkout-progress lparam))
          ((= wparam CHECKOUT_DONE)     (if (in-modal?)
                                            (delay-modal-user-event wparam lparam)
                                          (checkout-done lparam)))
          ((= wparam UPDATING_GAME)     (unless work-done?
                                          (set-label-title stage-view "Updating game"))))))


;;;
;;;; Quit
;;;


(define quit-requested?
  #f)


(define (quit-confirm-abort title)
  (lambda ()
    (if (not work-in-progress?)
        (exit)
      (let ((code (message-box (string-append title " in progress.\n\nDo you want to abort?") type: 'question)))
        (when (eq? code 'yes)
          (request-quit "Aborting..."))))))


(define (quit-safely)
  (lambda ()
    (if (not work-in-progress?)
        (exit)
      (request-quit "Disconnecting..."))))


(define (request-quit title)
  (set! quit-requested? #t)
  (git-request-quit)
  (set-default-cursor IDC_WAIT)
  (set-label-title status-view title)
  (set-view-active? minimize-view #f)
  (set-view-active? close-view #f))


(define (safe-quit-point)
  (when quit-requested?
    (exit)))
