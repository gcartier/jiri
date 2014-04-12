;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Libgit2 Bindings
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


(unit jiri.git


(include "syntax.scm")
(include "foreign.scm")


(c-declare "#include <git2.h>")


;;;
;;;; Enumerations
;;;


(c-enumerant GIT_DIRECTION_FETCH)
(c-enumerant GIT_DIRECTION_PUSH)

(c-enumerant GIT_OBJ_COMMIT)
(c-enumerant GIT_OBJ_TREE)
(c-enumerant GIT_OBJ_BLOB)
(c-enumerant GIT_OBJ_TAG)

(c-enumerant GIT_RESET_SOFT)
(c-enumerant GIT_RESET_MIXED)
(c-enumerant GIT_RESET_HARD)


;;;
;;;; Types
;;;


(c-type git_otype int)
(c-type git_reset_t int)
(c-type git_error "git_error")
(c-type git_error* (pointer git_error))
(c-type git_commit "git_commit")
(c-type git_commit* (pointer git_commit))
(c-type git_cred "git_cred")
(c-type git_cred* (pointer git_cred))
(c-type git_index "git_index")
(c-type git_index* (pointer git_index))
(c-type git_object "git_object")
(c-type git_object* (pointer git_object))
(c-type git_oid "git_oid")
(c-type git_oid* (pointer git_oid))
(c-type git_reference "git_reference")
(c-type git_reference* (pointer git_reference))
(c-type git_remote "git_remote")
(c-type git_remote* (pointer git_remote))
(c-type git_repository "git_repository")
(c-type git_repository* (pointer git_repository))
(c-type git_tree "git_tree")
(c-type git_tree* (pointer git_tree))

(c-type HANDLE (pointer void handle))
(c-type HWND (pointer (struct "HWND__") handle))


;;;
;;;; Error
;;;


(c-define (git-check-error code) (int) void "git_check_error" ""
  (when (not (= code 0))
    (error "Libgit2 error:"
           (let ((err (giterr-last)))
             (if err
                 (git-error-message err)
               code)))))

(c-define (git-raise-error code) (int) void "git_raise_error" ""
  (error "Libgit2 error:"
         (let ((err (giterr-last)))
           (if err
               (git-error-message err)
             code))))

(define giterr-last
  (c-lambda () git_error*
    "___result_voidstar = (void*) giterr_last();"))

(define git-error-message
  (c-lambda (git_error*) char-string
    "___result = ___arg1->message;"))


;;;
;;;; Validate
;;;


(define (git-validate c-lambda)
  (lambda rest
    (let ((result (apply c-lambda rest)))
      (if (integer? result)
          (git-raise-error result)
        result))))


;;;
;;;; Version
;;;


(define git-version
  (c-lambda () scheme-object
    #<<end-of-c-code
    int major, minor, rev;
    git_libgit2_version(&major, &minor, &rev);
    ___SCMOBJ version = ___EXT(___make_pair) (___ps, ___FIX(major), ___FIX(minor));
    ___result = version;
end-of-c-code
))


;;;
;;;; Thread
;;;


(c-declare #<<end-of-c-declare
    HANDLE ghMutex = NULL;
    HWND remoteHwnd = NULL;
    BOOL quitRequested = FALSE;
    
    #define DOWNLOAD_PROGRESS 0
    #define DOWNLOAD_DONE     1
    #define CHECKOUT_PROGRESS 2
    #define CHECKOUT_DONE     3
    #define UPDATING_GAME     5
end-of-c-declare
)


(c-enumerant DOWNLOAD_PROGRESS)
(c-enumerant DOWNLOAD_DONE)
(c-enumerant CHECKOUT_PROGRESS)
(c-enumerant CHECKOUT_DONE)
(c-enumerant UPDATING_GAME)


(define git-request-quit
  (c-lambda () void
    #<<end-of-c-code
    if (! ghMutex)
        ghMutex = CreateMutex(NULL, FALSE, NULL);
    WaitForSingleObject(ghMutex, INFINITE);
    quitRequested = TRUE;
    ReleaseMutex(ghMutex);
end-of-c-code
))


;;;
;;;; Branch
;;;


(git-external (git-branch-create (out git_reference*) git_repository* char-string git_commit* int) int "git_branch_create")


;;;
;;;; Checkout
;;;


(c-declare #<<end-of-c-declare
    git_repository* checkout_repository = NULL;
    git_tree* checkout_tree = NULL;
    
    char* checkout_path = NULL;
    size_t checkout_completed_steps = 0;
    size_t checkout_total_steps = 0;
end-of-c-declare
)

(define git-checkout-path
  (c-lambda () char-string
    #<<end-of-c-code
    WaitForSingleObject(ghMutex, INFINITE);
    ___result = checkout_path;
    ReleaseMutex(ghMutex);
end-of-c-code
))

(define git-checkout-completed-steps
  (c-lambda () int
    #<<end-of-c-code
    WaitForSingleObject(ghMutex, INFINITE);
    ___result = checkout_completed_steps;
    ReleaseMutex(ghMutex);
end-of-c-code
))

(define git-checkout-total-steps
  (c-lambda () int
    #<<end-of-c-code
    WaitForSingleObject(ghMutex, INFINITE);
    ___result = checkout_total_steps;
    ReleaseMutex(ghMutex);
end-of-c-code
))

(c-declare #<<end-of-c-declare
    void checkout_callback(const char *path, size_t completed_steps, size_t total_steps, void *payload)
    {
        WaitForSingleObject(ghMutex, INFINITE);
        checkout_path = (char*) path;
        checkout_completed_steps = completed_steps;
        checkout_total_steps = total_steps;
        ReleaseMutex(ghMutex);
        PostMessage(remoteHwnd, WM_USER, CHECKOUT_PROGRESS, 0);
    }

    DWORD WINAPI checkout_head_proc(LPVOID lpParam)
    {
        git_checkout_opts options = GIT_CHECKOUT_OPTS_INIT;
        options.checkout_strategy = GIT_CHECKOUT_FORCE;
        options.progress_cb = checkout_callback;
        int result = git_checkout_head(checkout_repository, &options);
        PostMessage(remoteHwnd, WM_USER, CHECKOUT_DONE, result);
        return 0;
    }
end-of-c-declare
)

(define git-checkout-head-force-threaded
  (c-lambda (git_repository* HWND) HANDLE
    #<<end-of-c-code
    if (! ghMutex)
        ghMutex = CreateMutex(NULL, FALSE, NULL);
    remoteHwnd = ___arg2;
    checkout_repository = ___arg1;
    ___result = CreateThread(NULL, 0, &checkout_head_proc, 0, 0, NULL);
end-of-c-code
))


;;;
;;;; Cred
;;;


(git-external (git-cred-userpass-plaintext-new (out git_cred*) char-string char-string) :error "git_cred_userpass_plaintext_new")


;;;
;;;; Object
;;;


(git-external (git-object-lookup (out git_object*) git_repository* git_oid* git_otype) :lookup "git_object_lookup")
(git-external (git-object-free git_object*) void "git_object_free")


;;;
;;;; Reference
;;;


(git-external (git-reference-free git_reference*) void "git_reference_free")
(git-external (git-reference-lookup (out git_reference*) git_repository* char-string) :lookup "git_reference_lookup")


(define git-reference-name
  (c-lambda (git_reference*) char-string
    #<<end-of-c-code
    ___result = (char*) git_reference_name(___arg1);
end-of-c-code
))


(define git-reference-name->id
  (c-lambda (git_repository* char-string) scheme-object ;; git_oid*
    #<<end-of-c-code
    git_oid* oid = calloc(1, sizeof(git_oid));
    // git_check_error(git_reference_name_to_id(oid, ___arg1, ___arg2));
    // ___result_voidstar = oid;
    int result = git_reference_name_to_id(oid, ___arg1, ___arg2);
    if (result != 0)
        ___result = ___FIX(result);
    else
    {
        ___SCMOBJ foreign;
        ___EXT(___POINTER_to_SCMOBJ)(___ps, oid, ___FAL, NULL, &foreign, ___RETURN_POS);
        ___result = foreign;
    }
end-of-c-code
))


(define (git-reference->id repo ref)
  (git-reference-name->id repo (git-reference-name ref)))


;;;
;;;; Remote
;;;


(git-external (git-remote-create (out git_remote*) git_repository* char-string char-string) :error "git_remote_create")
(git-external (git-remote-clear-refspecs git_remote*) void "git_remote_clear_refspecs")
(git-external (git-remote-add-fetch git_remote* char-string) :error "git_remote_add_fetch")
(git-external (git-remote-connect git_remote* int) :error "git_remote_connect")
(git-external (git-remote-load (out git_remote*) git_repository* char-string) :error "git_remote_load")
(git-external (git-remote-save git_remote*) :error "git_remote_save")
(git-external (git-remote-check-cert git_remote* int) void "git_remote_check_cert")
(git-external (git-remote-name git_remote*) char-string "git_remote_name")
(git-external (git-remote-url git_remote*) char-string "git_remote_url")


(c-define (cred-acquire-procedure proc) (scheme-object) git_cred* "cred_acquire_procedure" ""
  (proc))

(c-declare #<<end-of-c-declare
    int cred_acquire_cb(git_cred **out, const char * url, const char * username_from_url, unsigned int allowed_types, void * payload)
    {
        *out = cred_acquire_procedure(___EXT(___data_rc)(payload));
        return 0;
    }
end-of-c-declare
)

(define git-remote-set-cred-acquire-cb
  (c-lambda (git_remote* scheme-object) void
    #<<end-of-c-code
    void* p = ___EXT(___alloc_rc)(0);
    ___EXT(___set_data_rc)(p, ___arg2);
    git_remote_set_cred_acquire_cb(___arg1, &cred_acquire_cb, p);
end-of-c-code
))


(c-declare #<<end-of-c-declare
    unsigned int total_objects = 0;
    unsigned int received_objects = 0;
    size_t received_bytes = 0;
end-of-c-declare
)

(define git-remote-download-total-objects
  (c-lambda () int
    #<<end-of-c-code
    WaitForSingleObject(ghMutex, INFINITE);
    ___result = total_objects;
    ReleaseMutex(ghMutex);
end-of-c-code
))

(define git-remote-download-received-objects
  (c-lambda () int
    #<<end-of-c-code
    WaitForSingleObject(ghMutex, INFINITE);
    ___result = received_objects;
    ReleaseMutex(ghMutex);
end-of-c-code
))

(define git-remote-download-received-bytes
  (c-lambda () int
    #<<end-of-c-code
    WaitForSingleObject(ghMutex, INFINITE);
    ___result = received_bytes;
    ReleaseMutex(ghMutex);
end-of-c-code
))

(c-declare #<<end-of-c-declare
    int remote_download_callback(const git_transfer_progress *stats, void *payload)
    {
        BOOL quit;
      
        WaitForSingleObject(ghMutex, INFINITE);
        quit = quitRequested;
        total_objects = stats->total_objects;
        received_objects = stats->received_objects;
        received_bytes = stats->received_bytes;
        ReleaseMutex(ghMutex);
        if (! quit)
        {
            PostMessage(remoteHwnd, WM_USER, DOWNLOAD_PROGRESS, 0);
            return 0;
        }
        else
            return -1;
    }

    DWORD WINAPI remote_download_proc(LPVOID lpParam)
    {
        int result = git_remote_download((git_remote*) lpParam, &remote_download_callback , NULL);
        PostMessage(remoteHwnd, WM_USER, DOWNLOAD_DONE, result);
        return 0;
    }
end-of-c-declare
)

(define git-remote-download-threaded
  (c-lambda (git_remote* HWND) HANDLE
    #<<end-of-c-code
    if (! ghMutex)
        ghMutex = CreateMutex(NULL, FALSE, NULL);
    remoteHwnd = ___arg2;
    ___result = CreateThread(NULL, 0, &remote_download_proc, ___arg1, 0, NULL);
end-of-c-code
))


(git-external (git-remote-disconnect git_remote*) void "git_remote_disconnect")
(git-external (git-remote-update-tips git_remote*) :error "git_remote_update_tips")
(git-external (git-remote-free git_remote*) void "git_remote_free")


;;;
;;;; Repository
;;;


(git-external (git-repository-init (out git_repository*) char-string unsigned-int) :error "git_repository_init")
(git-external (git-repository-open (out git_repository*) char-string) :error "git_repository_open")
(git-external (git-repository-free git_repository*) void "git_repository_free")
(git-external (git-repository-set-head git_repository* char-string) :error "git_repository_set_head"))
