;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Libgit2 Bindings
;;;


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
(c-type git_cred "git_cred")
(c-type git_cred* (pointer git_cred))
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

(define giterr-last
  (c-lambda () git_error*
    "___result_voidstar = (void*) giterr_last();"))

(define git-error-message
  (c-lambda (git_error*) char-string
    "___result = ___arg1->message;"))


;;;
;;;; Cred
;;;


(define git-cred-userpass-plaintext-new
  (c-lambda (char-string char-string) git_cred*
    #<<end-of-c-code
    git_cred* cred;
    git_check_error(git_cred_userpass_plaintext_new(&cred, ___arg1, ___arg2));
    ___result_voidstar = cred;
end-of-c-code
))


;;;
;;;; Object
;;;


(define git-object-lookup
  (c-lambda (git_repository* git_oid* git_otype) git_object*
    #<<end-of-c-code
    git_object* obj;
    git_check_error(git_object_lookup(&obj, ___arg1, ___arg2, ___arg3));
    ___result_voidstar = obj;
end-of-c-code
))


;;;
;;;; Reference
;;;


(define git-reference-lookup
  (c-lambda (git_repository* char-string) git_reference*
    #<<end-of-c-code
    git_reference* ref;
    git_check_error(git_reference_lookup(&ref, ___arg1, ___arg2));
    ___result_voidstar = ref;
end-of-c-code
))

(define git-reference-name
  (c-lambda (git_reference*) char-string
    #<<end-of-c-code
    ___result = (char*) git_reference_name(___arg1);
end-of-c-code
))

(define git-reference-name->id
  (c-lambda (git_repository* char-string) git_oid*
    #<<end-of-c-code
    git_oid* oid = calloc(1, sizeof(git_oid));
    git_check_error(git_reference_name_to_id(oid, ___arg1, ___arg2));
    ___result_voidstar = oid;
end-of-c-code
))

(define (git-reference->id repo ref)
  (git-reference-name->id repo (git-reference-name ref)))


;;;
;;;; Remote
;;;


(define git-remote-create
  (c-lambda (git_repository* char-string char-string) git_remote*
    #<<end-of-c-code
    git_remote* remote;
    git_check_error(git_remote_create(&remote, ___arg1, ___arg2, ___arg3));
    ___result_voidstar = remote;
end-of-c-code
))

(define git-remote-check-cert
  (c-lambda (git_remote* int) void
    #<<end-of-c-code
    git_remote_check_cert(___arg1, ___arg2);
end-of-c-code
))

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

(define git-remote-connect
  (c-lambda (git_remote* int) void
    #<<end-of-c-code
    git_check_error(git_remote_connect(___arg1, ___arg2));
end-of-c-code
))

(c-define (remote-download-procedure proc total_objects indexed_objects received_objects received_bytes) (scheme-object unsigned-int unsigned-int unsigned-int unsigned-int) void "remote_download_procedure" ""
  (when proc
    (proc total_objects indexed_objects received_objects received_bytes)))

(c-declare #<<end-of-c-code
    int remote_download_cb(const git_transfer_progress *stats, void *payload)
    {
        remote_download_procedure(___EXT(___data_rc)(payload), stats->total_objects, stats->indexed_objects, stats->received_objects, stats->received_bytes);
        return 0;
    }
end-of-c-code
)

(define git-remote-download
  (c-lambda (git_remote* scheme-object) void
    #<<end-of-c-code
    void* p = ___EXT(___alloc_rc)(0);
    ___EXT(___set_data_rc)(p, ___arg2);
    git_check_error(git_remote_download(___arg1, &remote_download_cb, p));
    ___EXT(___release_rc)(p);
end-of-c-code
))

(c-type HANDLE (pointer void handle))
(c-type HWND (pointer (struct "HWND__") handle))

(c-declare #<<end-of-c-declare
    HANDLE ghMutex = NULL;
    
    HWND remoteHwnd = NULL;
    
	unsigned int total_objects = 0;
	unsigned int received_objects = 0;
	size_t received_bytes = 0;
    
    int remote_download_callback(const git_transfer_progress *stats, void *payload)
    {
        WaitForSingleObject(ghMutex, INFINITE);
        total_objects = stats->total_objects;
        received_objects = stats->received_objects;
        received_bytes = stats->received_bytes;
        ReleaseMutex(ghMutex);
        PostMessage(remoteHwnd, WM_USER, 0, 0);
        return 0;
    }

    DWORD WINAPI remote_download_proc(LPVOID lpParam)
    {
        git_remote_download((git_remote*) lpParam, &remote_download_callback , NULL);
        PostMessage(remoteHwnd, WM_USER, 0, 1);
        return 0;
    }
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

(define git-remote-download-threaded
  (c-lambda (git_remote* HWND) HANDLE
    #<<end-of-c-code
    if (! ghMutex)
        ghMutex = CreateMutex(NULL, FALSE, NULL);
    remoteHwnd = ___arg2;
    ___result = CreateThread(NULL, 0, &remote_download_proc, ___arg1, 0, NULL);
end-of-c-code
))

(define git-remote-disconnect
  (c-lambda (git_remote*) void
    "git_remote_disconnect"))

(define git-remote-update-tips
  (c-lambda (git_remote*) void
    #<<end-of-c-code
    git_check_error(git_remote_update_tips(___arg1));
end-of-c-code
))

(define git-remote-free
  (c-lambda (git_remote*) void
    "git_remote_free"))


;;;
;;;; Repository
;;;


(define git-repository-init
  (c-lambda (char-string unsigned-int) git_repository*
    #<<end-of-c-code
    git_repository* repo;
    git_check_error(git_repository_init(&repo, ___arg1, ___arg2));
    ___result_voidstar = repo;
end-of-c-code
))

(define git-repository-free
  (c-lambda (git_repository*) void
    "git_repository_free"))


;;;
;;;; Reset
;;;


(define git-reset
  (c-lambda (git_repository* git_object* git_reset_t) void
    #<<end-of-c-code
    git_check_error(git_reset(___arg1, ___arg2, ___arg3));
end-of-c-code
))
