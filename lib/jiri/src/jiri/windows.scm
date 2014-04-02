;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Windows
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


(unit jiri.windows


(include "syntax.scm")
(include "foreign.scm")


(c-declare "#include <ole2.h>")
(c-declare "#include <objidl.h>")
(c-declare "#include <shlobj.h>")
(c-declare "#include <accctrl.h>")
(c-declare "#include <aclapi.h>")


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
(c-type HRESULT      unsigned-long)
(c-type HKEY         (pointer (struct "HKEY__") handle))


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

(c-enumerant VK_RETURN)
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

(c-enumerant CSIDL_STARTMENU)
(c-enumerant CSIDL_DESKTOPDIRECTORY)
(c-enumerant CSIDL_PROGRAM_FILESX86)


;;;
;;;; External
;;;


(c-external (DefWindowProc            HWND UINT WPARAM LPARAM) LRESULT "DefWindowProcW")
(c-external (ShowWindow               HWND INT) BOOL)
(c-external (UpdateWindow             HWND) BOOL)
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
(c-external (OleInitialize            VOID*) HRESULT)
(c-external (OleUninitialize          ) VOID)


;;;
;;;; Information
;;;


(define get-local-date
  (c-lambda () char-string
    #<<end-of-c-code
    SYSTEMTIME time;
    char str[256];
    GetLocalTime(&time);
    sprintf(str, "%.4d%.2d%.2d", time.wYear, time.wMonth, time.wDay);
    ___result = str;
end-of-c-code
))


(define get-local-time
  (c-lambda () char-string
    #<<end-of-c-code
    SYSTEMTIME time;
    char str[256];
    GetLocalTime(&time);
    sprintf(str, "%.4d/%.2d/%.2d %.2d:%.2d:%.2d", time.wYear, time.wMonth, time.wDay, time.wHour, time.wMinute, time.wSecond);
    ___result = str;
end-of-c-code
))


(define get-processor-type
  (c-lambda () DWORD
    #<<end-of-c-code
    SYSTEM_INFO info;
    GetSystemInfo(&info);
    ___result = info.dwProcessorType;
end-of-c-code
))


(define get-platform-name
  (lambda ()
    "Windows"))


(define get-platform-version
  (c-lambda () scheme-object
    #<<end-of-c-code
    OSVERSIONINFO info;
    info.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
    GetVersionEx(&info);
    ___SCMOBJ version = ___EXT(___make_pair) (___FIX(info.dwMajorVersion), ___FIX(info.dwMinorVersion), ___STILL);
    ___result = version;
end-of-c-code
))


;;;
;;;; Initialize
;;;


(define windows-initialized?
  #f)


(define (initialize-windows)
  (unless windows-initialized?
    (OleInitialize NULL)
    (set! windows-initialized? #t)))


(define (uninitialize-windows)
  (when windows-initialized?
    (OleUninitialize)
    (set! windows-initialized? #f)))


;;;
;;;; Geometry
;;;


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


;;;
;;;; Bitmap
;;;


(define BITMAP-width
  (c-lambda (BITMAP*) int
    "___result = ___arg1->bmWidth;"))

(define BITMAP-height
  (c-lambda (BITMAP*) int
    "___result = ___arg1->bmHeight;"))


;;;
;;;; Cursor
;;;


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


;;;
;;;; Window
;;;


(define current-window
  #f)

(define (set-current-window window)
  (set! current-window window))


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


;;;
;;;; Message
;;;


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
      (EndPaint hwnd ps))
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
  (DestroyWindow hwnd)
  (when quit
    (quit)))


(define (process-destroy)
  (PostQuitMessage 0))


(define user-callback
  #f)

(define (set-user-callback callback)
  (set! user-callback callback))


(define (process-user wparam lparam)
  (when user-callback
    (user-callback wparam lparam)))


(define quit
  #f)

(define (set-quit callback)
  (set! quit callback))


;;;
;;;; Platform
;;;


(define eol-encoding
  'cr-lf)


(define pathname-separator
  #\\)


(define executable-extension
  "exe")


(define (message-box text #!key (type 'message) (title #f))
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
    (let ((code (with-modal
                  (lambda ()
                    (MessageBox (if window (window-handle window) #f) text title (bitwise-ior MB_TASKMODAL flags))))))
      (cond ((= code IDOK) 'yes)
            ((= code IDCANCEL) 'cancel)
            ((= code IDYES) 'yes)
            ((= code IDNO) 'no)
            (else #f)))))


(define get-special-folder
  (c-lambda (int) wchar_t-string
    #<<end-of-c-code
    wchar_t szDir[MAX_PATH];
    SHGetSpecialFolderPath(0, szDir, ___arg1, FALSE);
    ___result = szDir;
end-of-c-code
))


(define create-console-process
  (c-lambda (wchar_t-string) BOOL
    #<<end-of-c-code
    STARTUPINFOW siStartupInfo;
    PROCESS_INFORMATION piProcessInfo;
    memset(&siStartupInfo, 0, sizeof(siStartupInfo));
    memset(&piProcessInfo, 0, sizeof(piProcessInfo));
    siStartupInfo.cb = sizeof(siStartupInfo);
    siStartupInfo.dwFlags = STARTF_USESHOWWINDOW;
    siStartupInfo.wShowWindow = SW_HIDE;
    ___result = CreateProcess(
                  NULL,
                  ___arg1,
                  NULL,
                  NULL,
                  0,
                  CREATE_NEW_CONSOLE,
                  NULL,
                  NULL,
                  &siStartupInfo,
                  &piProcessInfo);
end-of-c-code
))


;;;
;;;; File
;;;


(define rewind-creation-time
  (c-lambda (wchar_t-string) BOOL
    #<<end-of-c-code
    HANDLE file = CreateFile(___arg1, GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    FILETIME ft, st;
    SYSTEMTIME systime;
    ULARGE_INTEGER fi, si;
    LONGLONG filetimeToSeconds, twoWeeks, fs, ss;
    BOOL rewinded = FALSE;
    
    filetimeToSeconds = 10 * 1000 * 1000;
    twoWeeks = 60 * 60 * 24 * 14;
    
    GetFileTime(file, &ft, NULL, NULL);
    fi.LowPart = ft.dwLowDateTime;
    fi.HighPart = ft.dwHighDateTime;
    fs = (fi.QuadPart / filetimeToSeconds);
    
    GetSystemTime(&systime);
    SystemTimeToFileTime(&systime, &st);
    si.LowPart = st.dwLowDateTime;
    si.HighPart = st.dwHighDateTime;
    ss = (si.QuadPart / filetimeToSeconds);
    
    if ((ss - fs) <= twoWeeks)
    {
        FileTimeToSystemTime(&ft, &systime);
        if (systime.wMonth == 1)
        {
            systime.wYear -= 1;
            systime.wMonth = 12;
        }
        else
            systime.wMonth -= 1;
        SystemTimeToFileTime(&systime, &ft);
        SetFileTime(file, &ft, &ft, &ft);
        rewinded = TRUE;
    }
    
    CloseHandle(file);
    
    ___result = rewinded;
end-of-c-code
))


;;;
;;;; Directory
;;;


(define create-directory-with-acl-internal
  (c-lambda (wchar_t-string) BOOL
    #<<end-of-c-code
    LPCTSTR lpPath = (LPCTSTR) ___arg1;
    BOOL result = TRUE;
    
    if (!CreateDirectory(lpPath, NULL))
    {
        result = FALSE;
        goto exit;
    }

    HANDLE hDir = CreateFile(lpPath, READ_CONTROL|WRITE_DAC, 0, NULL, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL);
    if (hDir == INVALID_HANDLE_VALUE)
    {
        result = FALSE;
        goto exit;
    }

    ACL* pOldDACL;
    SECURITY_DESCRIPTOR* pSD = NULL;
    GetSecurityInfo(hDir, SE_FILE_OBJECT, DACL_SECURITY_INFORMATION, NULL, NULL, &pOldDACL, NULL, &pSD);

    PSID pSid = NULL;
    SID_IDENTIFIER_AUTHORITY authNt = SECURITY_NT_AUTHORITY;
    AllocateAndInitializeSid(&authNt, 2, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_USERS, 0, 0, 0, 0, 0, 0, &pSid);

    EXPLICIT_ACCESS ea={0};
    ea.grfAccessMode = GRANT_ACCESS;
    ea.grfAccessPermissions = GENERIC_ALL;
    ea.grfInheritance = CONTAINER_INHERIT_ACE|OBJECT_INHERIT_ACE;
    ea.Trustee.TrusteeType = TRUSTEE_IS_GROUP;
    ea.Trustee.TrusteeForm = TRUSTEE_IS_SID;
    ea.Trustee.ptstrName = (LPTSTR)pSid;

    ACL* pNewDACL = 0;
    DWORD err = SetEntriesInAcl(1, &ea, pOldDACL, &pNewDACL);

    if (pNewDACL)
        SetSecurityInfo(hDir, SE_FILE_OBJECT, DACL_SECURITY_INFORMATION, NULL, NULL, pNewDACL, NULL);

    FreeSid(pSid);
    LocalFree(pNewDACL);
    LocalFree(pSD);
    // No clue why this will sometimes crash like on E:/Dawn
    // LocalFree(pOldDACL);
    CloseHandle(hDir);
    
exit:
    ___result = result;
end-of-c-code
))


(define create-directory-with-acl
  (lambda (dir)
    (when (not (create-directory-with-acl-internal dir))
      (error "Unable to create directory:" dir))))


(c-declare #<<end-of-c-code
static int CALLBACK BrowseCallbackProc(HWND hwnd,UINT uMsg, LPARAM lParam, LPARAM lpData)
{
    // If the BFFM_INITIALIZED message is received
    // set the path to the start path.
    switch (uMsg)
    {
        case BFFM_INITIALIZED:
        {
            if (lpData != 0)
            {
                SendMessage(hwnd, BFFM_SETSELECTION, TRUE, lpData);
            }
        }
    }

    return 0; // The function should always return 0.
}
end-of-c-code
)


(define choose-directory
  (c-lambda (HWND wchar_t-string wchar_t-string) wchar_t-string
    #<<end-of-c-code
    BROWSEINFO   bi = {0};
    LPITEMIDLIST pidl;
    wchar_t      szDisplay[MAX_PATH];
    wchar_t      szDir[MAX_PATH];

    bi.hwndOwner      = ___arg1;
    bi.pszDisplayName = szDisplay;
    bi.lpszTitle      = ___arg2;
    bi.ulFlags        = BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE;
    bi.lpfn           = BrowseCallbackProc;
    bi.lParam         = (LPARAM) ___arg3;

    pidl = SHBrowseForFolder(&bi);
    
    SHGetPathFromIDList(pidl, szDir);
    
    ___result = szDir;
end-of-c-code
))


(define remove-directory
  (c-lambda (wchar_t-string) int
    #<<end-of-c-code
    LPCWSTR lpszDir = ___arg1;
    int len = wcslen(lpszDir);
    wchar_t* pszFrom = (wchar_t*) malloc(sizeof(wchar_t) * (len+2));
    wcscpy(pszFrom, lpszDir);
    pszFrom[len] = 0;
    pszFrom[len+1] = 0;
    
    SHFILEOPSTRUCT fileop;
    fileop.hwnd   = NULL;    // no status display
    fileop.wFunc  = FO_DELETE;  // delete operation
    fileop.pFrom  = pszFrom;  // source file name as double null terminated string
    fileop.pTo    = NULL;    // no destination needed
    fileop.fFlags = FOF_NOCONFIRMATION | FOF_SILENT;  // do not prompt the user
    fileop.fAnyOperationsAborted = FALSE;
    fileop.lpszProgressTitle     = NULL;
    fileop.hNameMappings         = NULL;
    
    int ret = SHFileOperation(&fileop);
    free(pszFrom);
    
    ___result = ret;
end-of-c-code
))


(define executable-path
  (c-lambda () wchar_t-string
    #<<end-of-c-code
    wchar_t buf[MAX_PATH];
    GetModuleFileName(NULL, buf, MAX_PATH);
    ___result = buf;
end-of-c-code
))


(define get-temporary-dir
  (c-lambda () wchar_t-string
    #<<end-of-c-code
    wchar_t buf[MAX_PATH];
    GetTempPath(MAX_PATH, buf);
    ___result = buf;
end-of-c-code
))


;;;
;;;; Shortcut
;;;


(define create-shortcut
  (c-lambda (wchar_t-string wchar_t-string wchar_t-string wchar_t-string) int
    #<<end-of-c-code
    HRESULT hres;
    IShellLink* psl;
    
    hres = CoCreateInstance(&CLSID_ShellLink, NULL, CLSCTX_INPROC_SERVER, &IID_IShellLink, (void **) &psl);
    if (SUCCEEDED(hres))
    {
        IPersistFile* ppf;

        hres = psl->lpVtbl->QueryInterface(psl, &IID_IPersistFile, (void **) &ppf);
        if (SUCCEEDED(hres))
        {
            hres = psl->lpVtbl->SetPath(psl, ___arg1);
            if (___arg2)
                psl->lpVtbl->SetArguments(psl, ___arg2);
            psl->lpVtbl->SetDescription(psl, ___arg4);
            psl->lpVtbl->SetIconLocation(psl, ___arg1, 0);
            if (SUCCEEDED(hres))
            {
                hres=ppf->lpVtbl->Save(ppf, ___arg3, TRUE);
            }
            ppf->lpVtbl->Release(ppf);
        }
        psl->lpVtbl->Release(psl);
    }
    
    ___result = hres;
end-of-c-code
))


;;;
;;;; Registry
;;;


(define HKEY_CURRENT_USER
  (c-lambda () HKEY
    #<<end-of-c-code
    ___result = HKEY_CURRENT_USER;
end-of-c-code
))


(define registry-create-key
  (c-lambda (HKEY wchar_t-string) HKEY
    #<<end-of-c-code
    HKEY key;
    LONG code = RegCreateKey(___arg1, ___arg2, &key);
    if (code == ERROR_SUCCESS)
        ___result = key;
    else
        ___result = NULL;
end-of-c-code
))


(define registry-open-key
  (c-lambda (HKEY wchar_t-string) HKEY
    #<<end-of-c-code
    HKEY key;
    LONG code = RegOpenKeyEx(___arg1, ___arg2, 0, KEY_QUERY_VALUE, &key);
    if (code == ERROR_SUCCESS)
        ___result = key;
    else
        ___result = NULL;
end-of-c-code
))


(define registry-delete-key
  (c-lambda (HKEY wchar_t-string) bool
    #<<end-of-c-code
    LONG code = RegDeleteKey(___arg1, ___arg2);
    ___result = (code == ERROR_SUCCESS);
end-of-c-code
))


(define registry-close-key
  (c-lambda (HKEY) void
    #<<end-of-c-code
    RegCloseKey(___arg1);
end-of-c-code
))


(define registry-query-string
  (c-lambda (HKEY wchar_t-string) wchar_t-string
    #<<end-of-c-code
    DWORD size = 512;
    wchar_t str[size];
    LONG code = RegQueryValueEx(___arg1, ___arg2, 0, 0, (LPBYTE) str, &size);
    if (code == ERROR_SUCCESS)
        ___result = str;
    else
        ___result = NULL;
end-of-c-code
))


(define registry-set-int
  (c-lambda (HKEY wchar_t-string int) void
    #<<end-of-c-code
    DWORD value = ___arg3;
    RegSetValueEx(___arg1, ___arg2, 0, REG_DWORD, (LPBYTE) &value, sizeof(value));
end-of-c-code
))


(define registry-set-string
  (c-lambda (HKEY wchar_t-string wchar_t-string) void
    #<<end-of-c-code
    RegSetValueEx(___arg1, ___arg2, 0, REG_SZ, (LPBYTE) ___arg3, (wcslen(___arg3)+1)*sizeof(wchar_t));
end-of-c-code
))


;;;
;;;; Dialog
;;;


(c-declare #<<end-of-c-code
wchar_t szItemName[80];

BOOL CALLBACK DlgProc(HWND hwndDlg, UINT Message, WPARAM wParam, LPARAM lParam)
{
    HWND hwndOwner;
    RECT rc, rcDlg, rcOwner;
    
    switch(Message)
    {
        case WM_INITDIALOG:
            hwndOwner = GetParent(hwndDlg);
            GetWindowRect(hwndOwner, &rcOwner);
            GetWindowRect(hwndDlg, &rcDlg);
            CopyRect(&rc, &rcOwner);
            OffsetRect(&rcDlg, -rcDlg.left, -rcDlg.top);
            OffsetRect(&rc, -rc.left, -rc.top);
            OffsetRect(&rc, -rcDlg.right, -rcDlg.bottom);
            SetWindowPos(hwndDlg,
                 HWND_TOP,
                 rcOwner.left + (rc.right / 2),
                 rcOwner.top + (rc.bottom / 2),
                 0, 0,
                 SWP_NOSIZE);
            SetFocus(GetDlgItem(hwndDlg, 6));
            return TRUE;
        case WM_COMMAND:
            switch(LOWORD(wParam))
            {
                case IDOK:
                    GetDlgItemText(hwndDlg, 6, szItemName, 80);
                    EndDialog(hwndDlg, IDOK);
                break;
                case IDCANCEL:
                    EndDialog(hwndDlg, IDCANCEL);
                break;
            }
            break;
        default:
            return FALSE;
    }
    return TRUE;
}
end-of-c-code
)


(define dialog-box-internal
  (c-lambda (HWND) wchar_t-string
    #<<end-of-c-code
    int code = DialogBox(GetModuleHandle(NULL), MAKEINTRESOURCE(50), ___arg1, DlgProc);
    if (code == IDOK)
        ___result = szItemName;
    else
        ___result = NULL;
end-of-c-code
))


(define dialog-box
  (lambda (handle)
    (with-modal
      (lambda ()
        (dialog-box-internal handle)))))


;;;
;;;; Modal
;;;


(define in-modal?
  (make-parameter #f))


(define delayed-modal-user-event
  #f)

(define (delay-modal-user-event wparam lparam)
  (set! delayed-modal-user-event (cons wparam lparam)))


(define (with-modal thunk)
  (let ((code (parameterize ((in-modal? #t))
                (thunk))))
    (when delayed-modal-user-event
      (let ((wparam (car delayed-modal-user-event))
            (lparam (cdr delayed-modal-user-event)))
        (set! delayed-modal-user-event #f)
        (PostMessage (window-handle current-window) WM_USER wparam lparam)))
    code))


;;;
;;;; Setup
;;;


(define current-instance
  (c-lambda () HINSTANCE
    "___result_voidstar = ___EXT(___get_program_startup_info)()->hInstance;"))


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
  (c-lambda (HINSTANCE LPCWSTR int int int int) HWND
    #<<end-of-c-code
    HINSTANCE hInstance = ___arg1;
    LPCWSTR title = ___arg2;
    int x = ___arg3;
    int y = ___arg4;
    int width = ___arg5;
    int height = ___arg6;
    
    WNDCLASSEX wc;
    HWND hwnd;
    
    // Register the Window Class
    wc.cbSize        = sizeof(WNDCLASSEX);
    wc.style         = 0;
    wc.lpfnWndProc   = WndProc;
    wc.cbClsExtra    = 0;
    wc.cbWndExtra    = 0;
    wc.hInstance     = hInstance;
    wc.hIcon         = LoadImage(hInstance, L"app", IMAGE_ICON, 32, 32, LR_SHARED);
    wc.hCursor       = NULL;
    wc.hbrBackground = NULL;
    wc.lpszMenuName  = NULL;
    wc.lpszClassName = g_szClassName;
    wc.hIconSm       = LoadImage(hInstance, L"app", IMAGE_ICON, 16, 16, LR_SHARED);

    RegisterClassEx(&wc);

    // Create the Window
    int screenX = GetSystemMetrics(SM_CXSCREEN);
    int screenY = GetSystemMetrics(SM_CYSCREEN);
    int xCtr = (x != -1) ? x : (screenX / 2) - (width / 2);
    int yCtr = (y != -1) ? y : (screenY / 2) - (height / 2);
    hwnd = CreateWindowEx(
        0,
        g_szClassName,
        title,
        WS_POPUP | WS_MINIMIZEBOX,
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
)))
