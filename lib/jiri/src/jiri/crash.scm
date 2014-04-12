;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Crash Handler
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


(unit jiri.crash


(define (call-with-bug-report proc)
  (let ((path (string-append (get-special-folder CSIDL_DESKTOPDIRECTORY) "/" jiri-title " Setup bug report.txt")))
    (call-with-output-file (list path: path eol-encoding: eol-encoding output-width: 256)
      (lambda (output)
        (display jiri-title output)
        (display " Setup " output)
        (display jiri-version output)
        (newline output)
        (newline output)
        (display "Date: " output)
        (display (get-local-time) output)
        (newline output)
        (newline output)
        (display "Platform: " output)
        (display (get-platform-name) output)
        (let ((version (get-platform-version)))
          (let ((major (car version))
                (minor (cdr version)))
            (display " " output)
            (display major output)
            (display "." output)
            (display minor output)))
        (newline output)
        (display "Processor: " output)
        (display (get-processor-type) output)
        (newline output)
        (newline output)
        (proc output)
        (force-output output))))
  (message-box (string-append "An unexpected problem occurred.\r\n\r\n"
                              "Please send the bug report that was generated on your desktop and any comments to gucartier@gmail.com.\r\n\r\n")
               title: "Problem"))


(define (log-backtrace ignore)
  (call-with-bug-report
    (lambda (output)
      (continuation-capture
        (lambda (cont)
          (display-continuation-backtrace cont output #t #t 1000 1000))))))


(define crash-reporter
  #f)

(define (set-crash-reporter proc)
  (set! crash-reporter proc))


(set-crash-reporter log-backtrace)


(cond-expand
  (windows
    
    (define SEM_FAILCRITICALERRORS #x0001)
    
    (define SEM_NOGPFAULTERRORBOX #x0002)
    
    (define SetErrorMode
      (c-lambda (unsigned-int) unsigned-int "SetErrorMode"))
    
    (define (disable-crash-window)
      (SetErrorMode (bitwise-ior SEM_FAILCRITICALERRORS SEM_NOGPFAULTERRORBOX)))
    
    (c-define (call_crash_reporter ignore) ((pointer void)) void "jazz_call_crash_reporter" ""
      (crash-reporter ignore))

    (c-declare #<<END-OF-DECLARES
      static LONG WINAPI unhandled_exception_filter(LPEXCEPTION_POINTERS info)
      {
        jazz_call_crash_reporter(info);
        return EXCEPTION_EXECUTE_HANDLER;
      }

      static void setup_low_level_windows_crash_handler()
      {
        SetUnhandledExceptionFilter(unhandled_exception_filter);
      }
END-OF-DECLARES
    )
    (c-initialize "setup_low_level_windows_crash_handler();")
    
    (c-declare "const DWORD CRASH_PROCESS = (DWORD) 0xE0000001L;")
    
    (define crash-process
      (c-lambda () void
        "RaiseException(CRASH_PROCESS, EXCEPTION_NONCONTINUABLE , 0, NULL);")))
  (else
   
   (define (disable-crash-window)
     #!void)
   
   (c-define (call_crash_reporter ignore) (int) void "jazz_call_crash_reporter" ""
     (crash-reporter ignore))

   (c-define (crash_call_exit) () void "crash_call_exit" ""
     (exit 1))

   (c-declare #<<END-OF-DECLARES
      #include <stdio.h>
      #include <unistd.h>
      #include <sys/types.h>
      #include <signal.h>

      static void error_signal_handler(int sig_num)
      {
        jazz_call_crash_reporter(sig_num);
        fflush(stdout);
        crash_call_exit();
      }

      static void setup_low_level_unix_crash_handler()
      {
        // core dumping signals
        signal(SIGQUIT, error_signal_handler);
        signal(SIGILL,  error_signal_handler);
        signal(SIGABRT, error_signal_handler);
        signal(SIGFPE,  error_signal_handler);
        signal(SIGBUS,  error_signal_handler);
        signal(SIGSEGV, error_signal_handler);
        signal(SIGSYS,  error_signal_handler);
      }
END-OF-DECLARES
   )

   (c-initialize "setup_low_level_unix_crash_handler();")

   (define crash-process
     (c-lambda () void
       "raise(SIGSEGV);")))))
