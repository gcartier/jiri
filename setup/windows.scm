;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Windows
;;;


(include "syntax.scm")
(include "foreign.scm")


(c-declare "#include <Shlobj.h>")


;;;
;;;; Types
;;;


(c-type VOID         void)
(c-type VOID*        (pointer VOID))
(c-type BOOL         bool)
(c-type WORD         unsigned-int16)
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
(c-type HPEN         (pointer (struct "HPEN__") handle))
(c-type HFONT        (pointer (struct "HFONT__") handle))
(c-type HRGN         (pointer (struct "HRGN__") handle))
(c-type HICON        (pointer (struct "HICON__") handle))
(c-type HCURSOR      HICON)
(c-type HGDIOBJ      (pointer VOID handle))
(c-type COLORREF     DWORD)


;;;
;;;; Structures
;;;


(c-structure PAINTSTRUCT)
(c-structure BITMAP)
(c-structure POINT)
(c-structure RECT)


;;;
;;;; Constants
;;;


(c-constant NULL  #f)
(c-constant FALSE 0)
(c-constant TRUE  1)

(c-constant IDC_ARROW   32512)
(c-constant IDC_WAIT    32514)
(c-constant IDC_SIZEALL 32646)

(c-enumerant SRCCOPY)

(c-enumerant OPAQUE)
(c-enumerant TRANSPARENT)

(c-enumerant PS_SOLID)

(c-enumerant FW_BOLD)
(c-enumerant FW_DONTCARE)
(c-enumerant DEFAULT_CHARSET)
(c-enumerant OUT_DEFAULT_PRECIS)
(c-enumerant CLIP_DEFAULT_PRECIS)
(c-enumerant ANTIALIASED_QUALITY)
(c-enumerant FF_DONTCARE)

(c-enumerant DT_LEFT)
(c-enumerant DT_RIGHT)
(c-enumerant DT_CENTER)
(c-enumerant DT_NOCLIP)

(c-enumerant SW_SHOWNORMAL)
(c-enumerant SW_MINIMIZE)

(c-enumerant RDW_INVALIDATE)
(c-enumerant RDW_ERASENOW)
(c-enumerant RDW_UPDATENOW)

(c-enumerant WM_ERASEBKGND)
(c-enumerant WM_PAINT)
(c-enumerant WM_KEYDOWN)
(c-enumerant WM_MOUSEMOVE)
(c-enumerant WM_LBUTTONDOWN)
(c-enumerant WM_LBUTTONUP)
(c-enumerant WM_CAPTURECHANGED)
(c-enumerant WM_CLOSE)
(c-enumerant WM_DESTROY)
(c-enumerant WM_USER)

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

(c-enumerant INFINITE)

(c-enumerant FILE_ATTRIBUTE_READONLY)


;;;
;;;; External
;;;


(c-external (DefWindowProc            HWND UINT WPARAM LPARAM) LRESULT "DefWindowProcW")
(c-external (ShowWindow               HWND INT) BOOL)
(c-external (UpdateWindow             HWND) BOOL)
(c-external (RedrawWindow             HWND RECT* HRGN UINT) BOOL)
(c-external (InvalidateRect           HWND RECT* BOOL) BOOL)
(c-external (DestroyWindow            HWND) BOOL)
(c-external (GetWindowRect            HWND RECT*) BOOL)
(c-external (MoveWindow               HWND INT INT INT INT BOOL) BOOL)
(c-external (PostMessage              HWND UINT WPARAM LPARAM) BOOL)
(c-external (PostQuitMessage          INT) VOID)
(c-external (BeginPaint               HWND PAINTSTRUCT*) HDC)
(c-external (EndPaint                 HWND PAINTSTRUCT*) BOOL)
(c-external (CreateCompatibleBitmap   HDC INT INT) HBITMAP)
(c-external (CreateCompatibleDC       HDC) HDC)
(c-external (DeleteDC                 HDC) BOOL)
(c-external (LoadBitmap               HINSTANCE LPCWSTR) HANDLE "LoadBitmapW")
(c-external (GetBitmap                HGDIOBJ INT BITMAP*) INT "GetObjectW")
(c-external (SelectObject             HDC HANDLE) HANDLE)
(c-external (DeleteObject             HGDIOBJ) BOOL)
(c-external (BitBlt                   HDC INT INT INT INT HDC INT INT DWORD) BOOL)
(c-external (MoveToEx                 HDC INT INT POINT*) BOOL)
(c-external (LineTo                   HDC INT INT) BOOL)
(c-external (FillRect                 HDC RECT* HBRUSH) INT)
(c-external (DrawText                 HDC LPCWSTR INT RECT* UINT) INT "DrawTextW")
(c-external (CreateSolidBrush         COLORREF) HBRUSH)
(c-external (CreatePen                INT INT COLORREF) HPEN)
(c-external (CreateFont               INT INT INT INT INT DWORD DWORD DWORD DWORD DWORD DWORD DWORD DWORD LPCWSTR) HFONT "CreateFontW")
(c-external (SetBkMode                HDC INT) INT)
(c-external (SetTextColor             HDC COLORREF) COLORREF)
(c-external (SetCursor                HCURSOR) HCURSOR)
(c-external (GetCursorPos             POINT*) BOOL)
(c-external (SetCapture               HWND) HWND)
(c-external (ReleaseCapture           ) BOOL)
(c-external (RGB                      INT INT INT) INT)
(c-external (GetRValue                INT) INT)
(c-external (GetGValue                INT) INT)
(c-external (GetBValue                INT) INT)
(c-external (MessageBox               HWND LPCWSTR LPCWSTR INT) INT "MessageBoxW")
(c-external (GetFileAttributes        CWSTR) DWORD "GetFileAttributesW")
(c-external (SetFileAttributes        CWSTR DWORD) BOOL "SetFileAttributesW")


(define make-POINT
  (c-lambda (int int int int) POINT*
    #<<end-of-c-code
    POINT* point = malloc(sizeof(POINT));
    point->x = ___arg1;
    point->y = ___arg2;
    ___result_voidstar = point;
end-of-c-code
))

(define POINT-free
  (c-lambda (POINT*) void
    "free(___arg1);"))

(define POINT-x
  (c-lambda (POINT*) int
    "___result = ___arg1->x;"))

(define POINT-y
  (c-lambda (POINT*) int
    "___result = ___arg1->y;"))


(define make-RECT
  (c-lambda (int int int int) RECT*
    #<<end-of-c-code
    RECT* rect = malloc(sizeof(RECT));
    SetRect(rect, ___arg1, ___arg2, ___arg3, ___arg4);
    ___result_voidstar = rect;
end-of-c-code
))

(define RECT-free
  (c-lambda (RECT*) void
    "free(___arg1);"))

(define RECT-left
  (c-lambda (RECT*) int
    "___result = ___arg1->left;"))

(define RECT-top
  (c-lambda (RECT*) int
    "___result = ___arg1->top;"))

(define RECT-right
  (c-lambda (RECT*) int
    "___result = ___arg1->right;"))

(define RECT-bottom
  (c-lambda (RECT*) int
    "___result = ___arg1->bottom;"))


(define LoadCursorInt
  (c-lambda (WORD) HCURSOR
    "___result_voidstar = LoadImage(NULL, MAKEINTRESOURCE(___arg1), IMAGE_CURSOR, 0, 0, LR_SHARED);"))


(define default-cursor
  IDC_ARROW)

(define (set-default-cursor cursor)
  (set! default-cursor cursor)
  (update-cursor))


(define (set-cursor cursor)
  (SetCursor (LoadCursorInt cursor)))


(define (update-cursor)
  (let ((proc (window-update-cursor current-window)))
    (when proc
      (proc current-window))))


(define (cursor-position)
  (let ((point (POINT-make)))
    (GetCursorPos point)
    (let ((pos (make-point (POINT-x point) (POINT-y point))))
      (POINT-free point)
      pos)))


(define (window-cursor-position window)
  (point- (cursor-position) (get-window-position window)))


(define (get-window-position window)
  (let ((handle (window-handle window))
        (rect (RECT-make)))
    (GetWindowRect handle rect)
    (let ((pos (make-point (RECT-left rect) (RECT-top rect))))
      (RECT-free rect)
      pos)))


(define (get-window-size window)
  (let ((handle (window-handle window))
        (rect (RECT-make)))
    (GetWindowRect handle rect)
    (let ((size (make-point (- (RECT-right rect) (RECT-left rect)) (- (RECT-bottom rect) (RECT-top rect)))))
      (RECT-free rect)
      size)))


(define (move-window window pos size)
  (let ((handle (window-handle window)))
    (MoveWindow handle (point-h pos) (point-v pos) (point-h size) (point-v size) #f)))


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
  
  (cond ((= msg WM_ERASEBKGND) processed)
        ((= msg WM_PAINT) (process-paint hwnd))
        ((= msg WM_KEYDOWN) (process-key-down wparam))
        ((= msg WM_MOUSEMOVE) (process-mouse-move (get-lparam-x lparam) (get-lparam-y lparam)))
        ((= msg WM_LBUTTONDOWN) (process-mouse-down (get-lparam-x lparam) (get-lparam-y lparam)))
        ((= msg WM_LBUTTONUP) (process-mouse-up (get-lparam-x lparam) (get-lparam-y lparam)))
        ((= msg WM_CAPTURECHANGED) (process-capture-changed lparam))
        ((= msg WM_CLOSE) (process-close hwnd))
        ((= msg WM_DESTROY) (process-destroy))
        ((= msg WM_USER) (process-user wparam lparam))
        (else unprocessed)))


(define (process-paint hwnd)
  (let ((ps (PAINTSTRUCT-make)))
    (let ((hdc (BeginPaint hwnd ps)))
      (let ((draw (window-draw current-window)))
        (when draw
          (draw hdc)))
      (EndPaint hdc ps))
    (PAINTSTRUCT-free ps))
  processed)


(define (process-key-down wparam)
  (let ((key-down (window-key-down current-window)))
    (when key-down
      (key-down wparam))))


(define (process-mouse-move x y)
  (let ((mouse-move (window-mouse-move current-window)))
    (when mouse-move
      (mouse-move x y))))


(define (process-mouse-down x y)
  (let ((mouse-down (window-mouse-down current-window)))
    (when mouse-down
      (mouse-down x y))))


(define (process-mouse-up x y)
  (let ((mouse-up (window-mouse-up current-window)))
    (when mouse-up
      (mouse-up x y))))


(define lose-capture-callback
  #f)

(define (set-lose-capture-callback callback)
  (set! lose-capture-callback callback))


(define (process-capture-changed hwnd)
  (when lose-capture-callback
    (let ((callback lose-capture-callback))
      (set! lose-capture-callback #f)
      (callback))))


(define (process-close hwnd)
  (DestroyWindow hwnd))


(define (process-destroy)
  (PostQuitMessage 0))


(define user-callback
  #f)

(define (set-user-callback callback)
  (set! user-callback callback))


(define (process-user wparam lparam)
  (when user-callback
    (user-callback wparam lparam)))


(define current-instance
  (c-lambda () HINSTANCE
    "___result_voidstar = ___EXT(___get_program_startup_info)()->hInstance;"))


(define BITMAP-width
  (c-lambda (BITMAP*) int
    "___result = ___arg1->bmWidth;"))

(define BITMAP-height
  (c-lambda (BITMAP*) int
    "___result = ___arg1->bmHeight;"))


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


(define choose-directory
  (c-lambda (HWND) wchar_t-string
    #<<end-of-c-code
    BROWSEINFOW  bi = {0};
    LPITEMIDLIST pidl;
    wchar_t      szDisplay[MAX_PATH];
    wchar_t      szDir[MAX_PATH];

    bi.hwndOwner      = ___arg1;
    bi.pszDisplayName = szDisplay;
    bi.lpszTitle      = L"Please select installation folder";
    bi.ulFlags        = BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE;

    pidl = SHBrowseForFolderW(&bi);
    
    SHGetPathFromIDListW(pidl, szDir);
    
    ___result = szDir;
end-of-c-code
))


(c-declare #<<end-of-c-code
const LPCWSTR g_szClassName = L"JiriWindowClass";
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
  (c-lambda (HINSTANCE LPCWSTR int int) HWND
    #<<end-of-c-code
    HINSTANCE hInstance = ___arg1;
    LPCWSTR title = ___arg2;
    int width = ___arg3;
    int height = ___arg4;
    
    WNDCLASSEXW wc;
    HWND hwnd;
    
    // Register the Window Class
    wc.cbSize        = sizeof(WNDCLASSEX);
    wc.style         = 0;
    wc.lpfnWndProc   = WndProc;
    wc.cbClsExtra    = 0;
    wc.cbWndExtra    = 0;
    wc.hInstance     = hInstance;
    wc.hIcon         = LoadImage(hInstance, "app", IMAGE_ICON, 32, 32, LR_SHARED);
    wc.hCursor       = NULL;
    wc.hbrBackground = NULL;
    wc.lpszMenuName  = NULL;
    wc.lpszClassName = g_szClassName;
    wc.hIconSm       = LoadImage(hInstance, "app", IMAGE_ICON, 16, 16, LR_SHARED);

    RegisterClassExW(&wc);

    // Create the Window
    int screenX = GetSystemMetrics(SM_CXSCREEN);
    int screenY = GetSystemMetrics(SM_CYSCREEN);
    int xCtr = (screenX / 2) - (width / 2);
    int yCtr = (screenY / 2) - (height / 2);
    hwnd = CreateWindowExW(
        0,
        g_szClassName,
        title,
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
