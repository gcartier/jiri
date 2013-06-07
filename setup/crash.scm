;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Crash Handler
;;;


(include "features.scm")


(define (log-backtrace ignore)
  (call-with-output-file (list path: "crash.txt" eol-encoding: eol-encoding)
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
        return EXCEPTION_CONTINUE_SEARCH;
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
       "raise(SIGSEGV);"))))
