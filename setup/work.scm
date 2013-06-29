;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Work
;;;


;; TODO
;; * Handle all git and windows errors!?
;; - Add multiple background support
;;   - Change at 100% / nb of background!?
;; - Install could pass info to the app of what was the last head so that we could show
;;   only what changed since last time by having a what's new system indexed by commit!?
;; - When Marc has fixed the FFI error problem, replace the global error-handler by a catcher
;;   to ward against recursive errors
;; - A potential problem can occur when I push a new release because pushing to both app and
;;   world is not atomic. This can be alleviated a bit by a script to push a release pushing
;;   both repositories rapidly maybe even in parallel
;; * Do not forget about the --orphan branch as the multiple pushes of Install versions are starting to
;;   make even the clone of Install painfully long
;; * Even better than a message-box, I should do like modern installers and consider setup is done
;;   as soon as the install has been installed!
;;   - Surely quitting hard when git is doing a threaded operation could then be dangerous
;;     and leave a repo in a corrupted state (this can happen also during an install!)
;;   - Abort message-box for first part or make it modal!?
;; - Installer self-verification using a checksum!?
;; - Invoking app directly should error

;; DEVEL
;; - comment out (current-exception-handler jiri-exception-handler) and launch exe with -:dar

;; RELEASE
;; Install
;;   - b
;;   - cd release/install
;;   - commit and push changes
;; Setup
;;   - i
;;   - m
;;   - publish setup

;; SCENARIO
;; - Setup : clone install, delegate Install
;; - Root : delegate Current
;; - Current from Root : pull install, if newer delegate Install else pull app/world
;; - Current direct : incorrect
;; - Install from Setup : clone app/world
;; - Install from Current : pull app/world
;; - Install direct : incorrect
;; - App : incorrect but could be correct when version is validated with server

;; SPACE
;; - app
;;   - space
;;     - Space.exe
;;     - lib
;;   - space-debug
;; - install
;;   - current
;;     - Install.exe
;;     - libgit2.dll
;;   - space-install
;;     - Install.exe
;;     - Launcher.exe
;;     - Uninstall.exe
;;     - libgit2.dll
;; - worlds
;;   - space
;; Space.exe


(include "syntax.scm")


;;;
;;;; Window
;;;


(define current-bitmap-handle
  #f)

(define current-bitmap
  #f)


(define (prepare-bitmap)
  (let ((hbm (LoadBitmap (current-instance) "BACKGROUND")))
    (let ((bm (BITMAP-make)))
      (GetBitmap hbm (BITMAP-sizeof) bm)
      (set! current-bitmap-handle hbm)
      (set! current-bitmap bm))))


(define window
  (let ()
    (define (draw hdc)
      (let ((width (BITMAP-width current-bitmap))
            (height (BITMAP-height current-bitmap))
            (hdcBitmap (CreateCompatibleDC hdc))
            (hdcMem (CreateCompatibleDC hdc)))
        (let ((bmMem (CreateCompatibleBitmap hdc width height)))
          (SelectObject hdcBitmap current-bitmap-handle)
          (SelectObject hdcMem bmMem)
          (BitBlt hdcMem 0 0 width height hdcBitmap 0 0 SRCCOPY)
          (draw-views hdcMem)
          (BitBlt hdc 0 0 width height hdcMem 0 0 SRCCOPY)
          (DeleteObject bmMem)
          (DeleteDC hdcBitmap)
          (DeleteDC hdcMem))))
    
    (define (key-down wparam)
      (cond ((= wparam VK_RETURN)
             (when (and return-press (not work-in-progress?))
               (return-press)))
            ((= wparam VK_ESCAPE)
             (quit))))
    
    (define (update-cursor window)
      (let ((pos (window-cursor-position window)))
        (let ((x (point-h pos))
              (y (point-v pos)))
          (let ((view (find-view x y)))
            (if view
                (let ((update-cursor (view-update-cursor view)))
                  (if update-cursor
                      (update-cursor view x y)
                    (set-cursor default-cursor)))
              (set-cursor default-cursor))))))
    
    (define (mouse-move x y)
      (let ((view (find-view x y)))
        (if view
            (call-mouse-move view x y)
          (set-cursor default-cursor))))
    
    (define (mouse-down x y)
      (let ((view (find-view x y)))
        (when (and view (view-active? view))
          (let ((mouse-down (view-mouse-down view)))
            (when mouse-down
              (mouse-down view x y))))))
    
    (define (mouse-up x y)
      (let ((view (find-view x y)))
        (when (and view (view-active? view))
          (let ((mouse-up (view-mouse-up view)))
            (when mouse-up
              (mouse-up view x y))))))
    
    (define (find-view x y)
      (or captured-view
          (let ((pt (make-point x y)))
            (continuation-capture
              (lambda (return)
                (for-each (lambda (view)
                            (when (in-rect? pt (view-rect view))
                              (continuation-return return view)))
                          views)
                #f)))))
    
    (make-window #f draw key-down update-cursor mouse-move mouse-down mouse-up)))


(define return-press
  #f)

(define (set-return-press callback)
  (set! return-press callback))


;;;
;;;; Root
;;;


(define root-view
  (new-root (make-rect 0 0 850 550)))


;;;
;;;; Title
;;;


(define title-view
  (new-title (make-rect 20 18 440 100)
             jiri-title))


;;;
;;;; Minimize
;;;


(define minimize-view
  (new-minimize (make-rect 796 13 810 27)))


;;;
;;;; Close
;;;


(define close-view
  (new-close (make-rect 823 13 837 27)))


;;;
;;;; Percentage
;;;


(define percentage-view
  (new-label (make-rect 50 450 165 470)
             "0%"))


;;;
;;;; Downloaded
;;;


(define downloaded-view
  (new-label (make-rect 175 450 340 470)
             "Downloaded: "))


;;;
;;;; Status
;;;


(define status-view
  (new-label (make-rect 350 450 490 470)
             ""
             DT_RIGHT))


;;;
;;;; Remaining
;;;


(define remaining-view
  (new-label (make-rect 500 450 650 470)
             "Remaining: "
             DT_RIGHT))


;;;
;;;; Progress
;;;


(define progress-view
  (new-progress (make-rect 50 470 650 490) (make-range 0 10) 0))


;;;
;;;; Play
;;;


(define play-view
  (new-button (make-rect 680 450 815 490)
              "Play"
              (lambda (view)
                (play))
              active?: #f))


;;;
;;;; Work
;;;


(define work-in-progress?
  #f)

(define work-done?
  #f)

(define work-percentage
  0.)

(define work-downloaded
  0)


;;;
;;;; Installation
;;;


(define (uninstall-subkey)
  (string-append "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\" jiri-title))


(define (desktop-shortcut)
  (let ((desktop (get-special-folder CSIDL_DESKTOPDIRECTORY)))
    (string-append desktop "/" jiri-title ".lnk")))


(define (start-menu-appdir)
  (let ((startdir (get-special-folder CSIDL_STARTMENU)))
    (string-append startdir "/Programs/" jiri-title)))


(define (start-menu-shortcut appdir)
  (string-append appdir "/" jiri-title ".lnk"))


;;;
;;;; Play
;;;


(define (play)
  (set-default-cursor IDC_WAIT)
  (delegate-process (app-exe))
  (quit))


;;;
;;;; Quit
;;;


(define (quit-confirm-abort title)
  (lambda ()
    (if (not work-in-progress?)
        (exit)
      (let ((code (message-box (string-append title " in progress.\n\nDo you want to abort?") type: 'question)))
        (when (eq? code 'yes)
          (exit))))))


;;;
;;;; Callback
;;;


(define download-progress
  #f)

(define (set-download-progress proc)
  (set! download-progress proc))


(define download-done
  #f)

(define (set-download-done proc)
  (set! download-done proc))


(define checkout-progress
  #f)

(define (set-checkout-progress proc)
  (set! checkout-progress proc))


(define checkout-done
  #f)

(define (set-checkout-done proc)
  (set! checkout-done proc))


;;;
;;;; Prepare
;;;


(define (prepare)
  (initialize-windows)
  (prepare-bitmap)
  (set-current-window window))


;;;
;;;; Run
;;;


(define window-h
  -1)

(define window-v
  -1)


(define (run #!optional (start #f))
  (let ((hwnd (SetupWindow (current-instance) jiri-title window-h window-v (BITMAP-width current-bitmap) (BITMAP-height current-bitmap))))
    (window-handle-set! current-window hwnd)
    (ShowWindow hwnd SW_SHOWNORMAL)
    (UpdateWindow hwnd)
    (when start
      (start))
    (MessageLoop)))


;;;
;;;; Main
;;;


(define (main #!optional (start #f))
  (prepare)
  (layout)
  (run start))
