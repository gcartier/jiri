;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Windows
;;;


(include "syntax.scm")


;;;
;;;; Types
;;;


(c-type VOID         void)
(c-type VOID*        (pointer VOID))
(c-type BOOL         bool)
(c-type INT          int)
(c-type UINT         unsigned-int)
(c-type UINT_PTR     UINT)
(c-type LONG         long)
(c-type LONG_PTR     LONG)
(c-type ULONG        unsigned-long)
(c-type ULONG_PTR    ULONG)
(c-type LRESULT      LONG_PTR)
(c-type WPARAM       UINT_PTR)
(c-type LPARAM       ULONG_PTR)
(c-type DWORD        ULONG)
(c-type CWSTR        wchar_t-string)
(c-type LPCWSTR      CWSTR)
(c-type HANDLE       (pointer VOID handle))
(c-type HWND         (pointer (struct "HWND__") handle))
(c-type HDC          (pointer (struct "HDC__") handle))
(c-type HINSTANCE    (pointer (struct "HINSTANCE__") handle))
(c-type HBITMAP      (pointer (struct "HBITMAP__") handle))
(c-type HBRUSH       (pointer (struct "HBRUSH__") handle))
(c-type HFONT        (pointer (struct "HFONT__") handle))
(c-type HGDIOBJ      (pointer VOID handle))
(c-type COLORREF     DWORD)


;;;
;;;; Structures
;;;


(c-structure PAINTSTRUCT)
(c-structure BITMAP)
(c-structure RECT)


;;;
;;;; Constants
;;;


(c-constant NULL  #f)
(c-constant FALSE 0)
(c-constant TRUE  1)

(c-enumerant SRCCOPY)

(c-enumerant OPAQUE)
(c-enumerant TRANSPARENT)

(c-enumerant FW_DONTCARE)
(c-enumerant DEFAULT_CHARSET)
(c-enumerant OUT_DEFAULT_PRECIS)
(c-enumerant CLIP_DEFAULT_PRECIS)
(c-enumerant ANTIALIASED_QUALITY)
(c-enumerant FF_DONTCARE)

(c-enumerant DT_CENTER)
(c-enumerant DT_NOCLIP)

(c-enumerant SW_SHOWNORMAL)

(c-enumerant WM_PAINT)
(c-enumerant WM_KEYDOWN)
(c-enumerant WM_LBUTTONDOWN)
(c-enumerant WM_CLOSE)
(c-enumerant WM_DESTROY)

(c-enumerant VK_ESCAPE)

(c-enumerant MB_ICONWARNING)
(c-enumerant MB_ICONERROR)
(c-enumerant MB_OK)
(c-enumerant MB_ICONINFORMATION)
(c-enumerant MB_OKCANCEL)
(c-enumerant MB_YESNO)
(c-enumerant MB_YESNOCANCEL)
(c-enumerant MB_TASKMODAL)

(c-enumerant IDOK)
(c-enumerant IDCANCEL)
(c-enumerant IDABORT)
(c-enumerant IDRETRY)
(c-enumerant IDIGNORE)
(c-enumerant IDYES)
(c-enumerant IDNO)


;;;
;;;; External
;;;


(c-external (DefWindowProc      HWND UINT WPARAM LPARAM) LRESULT "DefWindowProcW")
(c-external (ShowWindow         HWND INT) BOOL)
(c-external (UpdateWindow       HWND) BOOL)
(c-external (DestroyWindow      HWND) BOOL)
(c-external (PostQuitMessage    INT) VOID)
(c-external (BeginPaint         HWND PAINTSTRUCT*) HDC)
(c-external (EndPaint           HWND PAINTSTRUCT*) BOOL)
(c-external (CreateCompatibleDC HDC) HDC)
(c-external (DeleteDC           HDC) BOOL)
(c-external (LoadBitmap         HINSTANCE LPCWSTR) HANDLE "LoadBitmapW")
(c-external (GetBitmap          HGDIOBJ INT BITMAP*) INT "GetObjectW")
(c-external (SelectObject       HDC HANDLE) HANDLE)
(c-external (DeleteObject       HGDIOBJ) BOOL)
(c-external (BitBlt             HDC INT INT INT INT HDC INT INT DWORD) BOOL)
(c-external (FillRect           HDC RECT* HBRUSH) INT)
(c-external (DrawText           HDC LPCWSTR INT RECT* UINT) INT "DrawTextW")
(c-external (CreateSolidBrush   COLORREF) HBRUSH)
(c-external (CreateFont         INT INT INT INT INT DWORD DWORD DWORD DWORD DWORD DWORD DWORD DWORD LPCWSTR) HFONT "CreateFontW")
(c-external (SetBkMode          HDC INT) INT)
(c-external (SetTextColor       HDC COLORREF) COLORREF)
(c-external (RGB                INT INT INT) INT)
(c-external (GetRValue          INT) INT)
(c-external (GetGValue          INT) INT)
(c-external (GetBValue          INT) INT)
(c-external (MessageBox         HWND LPCWSTR LPCWSTR INT) INT "MessageBoxW")


(define make-RECT
  (c-lambda (int int int int) RECT*
    #<<end-of-c-code
    RECT* rect = malloc(sizeof(RECT));
    SetRect(rect, ___arg1, ___arg2, ___arg3, ___arg4);
    ___result_voidstar = rect;
end-of-c-code
))


(define (signed-loword dword)
  (- (bitwise-and (+ dword #x8000) #xFFFF) #x8000))

(define (signed-hiword dword)
  (signed-loword (arithmetic-shift dword -16)))


(define unprocessed '(unprocessed))
(define processed '(processed))


(define (processed-result return)
  (if (and (pair? return) (eq? (car return) 'processed))
      (if (null? (cdr return))
          0
        (cadr return))
    0))


(c-define (call-process-hwnd-message hwnd umsg wparam lparam) (HWND UINT WPARAM LPARAM) LRESULT "call_process_hwnd_message" "static"
  (dispatch-message hwnd umsg wparam lparam))


(define (dispatch-message hwnd msg wparam lparam)
  (let ((return (process-window-message hwnd msg wparam lparam)))
    (if (eq? return unprocessed)
        (DefWindowProc hwnd msg wparam lparam)
      (processed-result return))))


(define (process-window-message hwnd msg wparam lparam)
  (define get-lparam-x signed-loword)
  (define get-lparam-y signed-hiword)
  
  (cond ((= msg WM_PAINT) (process-paint hwnd))
        ((= msg WM_KEYDOWN) (process-key-down wparam))
        ((= msg WM_LBUTTONDOWN) (process-mouse-down (get-lparam-x lparam) (get-lparam-y lparam)))
        ((= msg WM_CLOSE) (process-close hwnd))
        ((= msg WM_DESTROY) (process-destroy))
        (else unprocessed)))


(define (process-paint hwnd)
  (let ((ps (PAINTSTRUCT-make)))
    (let ((hdc (BeginPaint hwnd ps)))
      (let ((draw (window-draw current-window)))
        (if draw
            (draw hdc)))
      (EndPaint hdc ps))
    (PAINTSTRUCT-free ps)))


(define (process-key-down wparam)
  (let ((key-down (window-key-down current-window)))
    (if key-down
        (key-down wparam))))


(define (process-mouse-down x y)
  (let ((mouse-down (window-mouse-down current-window)))
    (if mouse-down
        (mouse-down x y))))


(define (process-close hwnd)
  (DestroyWindow hwnd))


(define (process-destroy)
  (PostQuitMessage 0))


(define current-instance
  (c-lambda () HINSTANCE
    "___result_voidstar = ___EXT(___get_program_startup_info)()->hInstance;"))


(define current-hbitmap
  #f)

(define current-bitmap
  #f)


(define BITMAP-width
  (c-lambda (BITMAP*) int
    "___result = ___arg1->bmWidth;"))

(define BITMAP-height
  (c-lambda (BITMAP*) int
    "___result = ___arg1->bmHeight;"))


(define (DrawGradient hdc left top right bottom from to vertical?)
  (let ((fStep (if vertical?
                   (/ (- bottom top) 256.)
                 (/ (- right left) 256.)))
        (rStep (/ (- (GetRValue to) (GetRValue from)) 256.))
        (gStep (/ (- (GetGValue to) (GetGValue from)) 256.))
        (bStep (/ (- (GetBValue to) (GetBValue from)) 256.)))
    (let loop ((i 0))
      (let ((rectFill (if vertical?
                          (make-RECT left
                                     (+ top (fxround (* i fStep)))
                                     (+ right 1)
                                     (+ top (fxround (* (+ i 1) fStep))))
                        (make-RECT (+ left (fxround (* i fStep)))
                                   top
                                   (+ left (fxround (* (+ i 1) fStep)))
                                   (+ bottom 1)))))
        (let ((r (+ (GetRValue from) (fxround (* i rStep))))
              (g (+ (GetGValue from) (fxround (* i gStep))))
              (b (+ (GetBValue from) (fxround (* i bStep)))))
          (let ((brush (CreateSolidBrush (RGB r g b))))
            (FillRect hdc rectFill brush)
            (DeleteObject brush))))
      (if (< i 256)
          (loop (+ i 1))))))


(define (fxround r)
  (if (##fixnum? r)
      r
    (##flonum->fixnum (##round r))))


(define eol-encoding
  'cr-lf)


(define (system-message text #!key (type 'message) (title #f))
  (let ((window current-window)
        (title
          (or title (case type
                      ((message) "Message")
                      ((question) "Question")
                      ((confirmation) "Confirmation")
                      ((problem) "Problem")
                      ((error) "Error"))))
        (flags
          (case type
            ((message) (bitwise-ior MB_OK MB_ICONINFORMATION))
            ((question) (bitwise-ior MB_YESNO MB_ICONWARNING))
            ((confirmation) (bitwise-ior MB_YESNOCANCEL MB_ICONWARNING))
            ((problem) (bitwise-ior MB_OK MB_ICONERROR))
            ((error) (bitwise-ior MB_OKCANCEL MB_ICONERROR)))))
    (let ((code (MessageBox (if window (window-handle window) #f) text title (bitwise-ior MB_TASKMODAL flags))))
      (cond ((= code IDOK) 'yes)
            ((= code IDCANCEL) 'cancel)
            ((= code IDYES) 'yes)
            ((= code IDNO) 'no)
            (else #f)))))


(c-declare #<<end-of-c-code
const char g_szClassName[] = "JiriWindowClass";
end-of-c-code
)


(c-declare #<<end-of-c-code
LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    return call_process_hwnd_message(hwnd, msg, wParam, lParam);
}
end-of-c-code
)


(define SetupWindow
  (c-lambda (HINSTANCE int int) HWND
    #<<end-of-c-code
    HINSTANCE hInstance = ___arg1;
    int width = ___arg2;
    int height = ___arg3;
    
    WNDCLASSEX wc;
    HWND hwnd;
    
    // Register the Window Class
    wc.cbSize        = sizeof(WNDCLASSEX);
    wc.style         = 0;
    wc.lpfnWndProc   = WndProc;
    wc.cbClsExtra    = 0;
    wc.cbWndExtra    = 0;
    wc.hInstance     = hInstance;
    wc.hIcon         = LoadImage(hInstance, "app", IMAGE_ICON, 32, 32, LR_SHARED);
    wc.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW+1);
    wc.lpszMenuName  = NULL;
    wc.lpszClassName = g_szClassName;
    wc.hIconSm       = LoadImage(hInstance, "app", IMAGE_ICON, 16, 16, LR_SHARED);

    RegisterClassEx(&wc);

    // Create the Window
    int screenX = GetSystemMetrics(SM_CXSCREEN);
    int screenY = GetSystemMetrics(SM_CYSCREEN);
    int xCtr = (screenX / 2) - (width / 2);
    int yCtr = (screenY/ 2) - (height / 2);
    hwnd = CreateWindowEx(
        0,
        g_szClassName,
        "Dawn of Space",
        WS_POPUP,
        xCtr, yCtr, width, height,
        NULL, NULL, hInstance, NULL);
    
    ___result = hwnd;
end-of-c-code
))


(define MessageLoop
  (c-lambda () int
    #<<end-of-c-code
    MSG Msg;
    
    while(GetMessage(&Msg, NULL, 0, 0) > 0)
    {
        TranslateMessage(&Msg);
        DispatchMessage(&Msg);
    }
    
    ___result = Msg.wParam;
end-of-c-code
))
