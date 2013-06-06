;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Setup
;;;


(define NULL #f)


(c-define-type VOID void)
(c-define-type INT int)
(c-define-type UINT unsigned-int)
(c-define-type CWSTR wchar_t-string)
(c-define-type LPCWSTR CWSTR)
(c-define-type HANDLE (pointer VOID handle))
(c-define-type HINSTANCE (pointer (struct "HINSTANCE__") handle))
(c-define-type HBITMAP (pointer (struct "HBITMAP__") handle))


(define IMAGE_BITMAP 0)


(c-declare
    #<<end-of-c-code
#include <windows.h>

HBITMAP hbm = NULL;
BITMAP bm;
const char g_szClassName[] = "JiriWindowClass";

void DrawGradient(HDC hDC, RECT* rectClient, COLORREF from, COLORREF to, BOOL vert)
{
    RECT rectFill;          // Rectangle for filling band
    float fStep;            // How large is each band?
    float rStep, gStep, bStep;
    float r, g, b;
    HBRUSH hBrush;
    int iOnBand;

    // Determine how large each band should be in order to cover the
    // client with 256 bands (one for every color intensity level)
    if (vert)
        fStep = ((float)rectClient->bottom - (float)rectClient->top) / 256.0f;
    else
        fStep = ((float)rectClient->right - (float)rectClient->left) / 256.0f;

    rStep = ((float) GetRValue(to) - (float) GetRValue(from)) / 256.0f;
    gStep = ((float) GetGValue(to) - (float) GetGValue(from)) / 256.0f;
    bStep = ((float) GetBValue(to) - (float) GetBValue(from)) / 256.0f;
    
    for (iOnBand = 0; iOnBand < 256; iOnBand++) {
        if (vert)
            SetRect(&rectFill,
                rectClient->left,
                rectClient->top + (int)(iOnBand * fStep),
                rectClient->right+1,
                rectClient->top + (int)((iOnBand+1) * fStep));
        else
            SetRect(&rectFill,
                rectClient->left + (int)(iOnBand * fStep),
                rectClient->top,
                rectClient->left + (int)((iOnBand+1) * fStep),
                rectClient->bottom+1);

        r = GetRValue(from) + (int) (iOnBand * rStep);
        g = GetGValue(from) + (int) (iOnBand * gStep);
        b = GetBValue(from) + (int) (iOnBand * bStep);
        hBrush = CreateSolidBrush(RGB(r, g, b));
        FillRect(hDC, &rectFill, hBrush);

        DeleteObject(hBrush);
    };
}

static WindowPaint(HWND hwnd)
{
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hwnd, &ps);
        HDC hdcMem = CreateCompatibleDC(hdc);
        HBITMAP hbmOld = SelectObject(hdcMem, hbm);
        BitBlt(hdc, 0, 0, bm.bmWidth, bm.bmHeight, hdcMem, 0, 0, SRCCOPY);
        SelectObject(hdcMem, hbmOld);
        DeleteDC(hdcMem);
        RECT textRect;
        SetBkMode(hdc, TRANSPARENT);
        SetTextColor(hdc, RGB(255,255,255));
        HFONT font = CreateFont(
                72, 0, 0, 0, FW_DONTCARE, FALSE, FALSE, FALSE,
                DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                ANTIALIASED_QUALITY, FF_DONTCARE, "Tahoma");
        SelectObject(hdc, font);
        SetRect(&textRect, 130, 18, 330, 168);
        DrawText(hdc, TEXT("Dawn of Space"), -1, &textRect, DT_CENTER | DT_NOCLIP);
        font = CreateFont(
                24, 0, 0, 0, FW_DONTCARE, FALSE, FALSE, FALSE,
                DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                ANTIALIASED_QUALITY, FF_DONTCARE, "Tahoma");
        SelectObject(hdc, font);
        RECT rc;
        int left = 50;
        int top = 450;
        int right = 390;
        int bottom = 490;
        SetRect(&rc, left, top, right, bottom);
        DrawGradient(hdc, &rc, RGB(150,0,0), RGB(220,0,0), 0);
        SetRect(&textRect, left, top + 7, right, bottom + 7);
        DrawText(hdc, TEXT("Install Dawn of Space"), -1, &textRect, DT_CENTER | DT_NOCLIP);
        
        EndPaint(hwnd, &ps);
}

static WindowKeyUp(HWND hwnd, WPARAM wParam)
{
    switch(wParam)
    {
        case VK_ESCAPE:
            exit(0);
            SendMessage(hwnd, WM_CLOSE, 0, 0);
            break;
    }
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch(msg)
    {
        case WM_PAINT:
            WindowPaint(hwnd);
            break;
        
        case WM_CLOSE:
            DestroyWindow(hwnd);
            break;
        
        case WM_DESTROY:
            PostQuitMessage(0);
            break;
        
        case WM_KEYUP:
            WindowKeyUp(hwnd, wParam);
            break;
        
        case WM_LBUTTONDOWN :
            PostQuitMessage(0);
            exit(0);
        
        default:
            return DefWindowProc(hwnd, msg, wParam, lParam);
    }
    return 0;
}
end-of-c-code
)


(define main
  (c-lambda (HINSTANCE) int
    #<<end-of-c-code
    WNDCLASSEX wc;
    HWND hwnd;
    MSG Msg;
    HINSTANCE hInstance = ___arg1;
    
    hbm = LoadBitmap(hInstance, "BACKGROUND");
    GetObject(hbm, sizeof(bm), &bm);
    
    // Register the Window Class
    wc.cbSize        = sizeof(WNDCLASSEX);
    wc.style         = 0;
    wc.lpfnWndProc   = WndProc;
    wc.cbClsExtra    = 0;
    wc.cbWndExtra    = 0;
    wc.hInstance     = hInstance;
    wc.hIcon         = LoadImage(hInstance, "app", IMAGE_ICON, 32, 32, LR_SHARED); // LoadIcon(NULL, IDI_APPLICATION);
    wc.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW+1);
    wc.lpszMenuName  = NULL;
    wc.lpszClassName = g_szClassName;
    wc.hIconSm       = LoadImage(hInstance, "app", IMAGE_ICON, 16, 16, LR_SHARED); // LoadIcon(NULL, IDI_APPLICATION);

    RegisterClassEx(&wc);

    // Create the Window
    int screenX = GetSystemMetrics(SM_CXSCREEN);
    int screenY = GetSystemMetrics(SM_CYSCREEN);
    int xCtr = (screenX / 2) - (bm.bmWidth / 2);
    int yCtr = (screenY/ 2) - (bm.bmHeight / 2);
    hwnd = CreateWindowEx(
        0,
        g_szClassName,
        "Dawn of Space",
        WS_POPUP,
        xCtr, yCtr, bm.bmWidth, bm.bmHeight,
        NULL, NULL, hInstance, NULL);

    ShowWindow(hwnd, SW_SHOWNORMAL);
    UpdateWindow(hwnd);

    // The Message Loop
    while(GetMessage(&Msg, NULL, 0, 0) > 0)
    {
        TranslateMessage(&Msg);
        DispatchMessage(&Msg);
    }
    return Msg.wParam;
end-of-c-code
))


(define current-instance
  (c-lambda () HINSTANCE
    "___result_voidstar = ___EXT(___get_program_startup_info)()->hInstance;"))


(define LoadBitmap
  (c-lambda (HINSTANCE LPCWSTR) HANDLE
    "LoadBitmapW"))


(define BitmapSize
  (c-lambda (HANDLE) scheme-object
    #<<end-of-c-code
    BITMAP bm;
    GetObject(___arg1, sizeof(bm), &bm);
    ___SCMOBJ version = ___EXT(___make_pair) (___FIX(bm.bmWidth), ___FIX(bm.bmHeight), ___STILL);
    ___result = version;
end-of-c-code
))


;; 850 x 550 ideal !?
(define (setup)
  (main (current-instance))
  #;
  (let ((repo (git-repository-init "zoo" 0)))
    (let ((remote (git-remote-create repo "origin" "git://github.com/jazzscheme/test.git")))
      (git-remote-connect remote GIT_DIRECTION_FETCH)
      (git-remote-download remote
        (lambda (total_objects indexed_objects received_objects stats->received_bytes)
          #f #;(display ".")))
      (git-remote-disconnect remote)
      (git-remote-update-tips remote)
      (git-remote-free remote)
      (let ((upstream (git-reference-lookup repo "refs/remotes/origin/master")))
        (let ((commit (git-object-lookup repo (git-reference->id repo upstream) GIT_OBJ_COMMIT)))
          (git-reset repo commit GIT_RESET_HARD)
          (display "done"))))
    (git-repository-free repo)))


(setup)
